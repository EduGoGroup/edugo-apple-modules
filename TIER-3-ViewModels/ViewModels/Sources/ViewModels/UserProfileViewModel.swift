import Foundation
import OSLog
import SwiftUI
import CQRS
import Models
import EduGoCommon
import UseCases

/// ViewModel para visualizar y gestionar el perfil del usuario usando CQRS Mediator.
///
/// Este ViewModel gestiona la carga del perfil con estrategia cache-first,
/// modo de edición y sincronización con eventos de dominio.
///
/// ## Responsabilidades
/// - Cargar perfil de usuario con cache-first strategy
/// - Gestionar modo de edición del perfil
/// - Suscribirse a eventos de login para refrescar
/// - Sincronizar con cache local
///
/// ## Integración con CQRS
/// - **Queries**: GetUserContextQuery (con cache de sesión)
/// - **Events**: LoginSuccessEvent (refrescar perfil después de login)
///
/// ## Estrategia Cache-First
/// 1. Intentar cargar desde cache local primero
/// 2. Cargar desde servidor en background
/// 3. Actualizar cache con datos frescos
///
/// ## Ejemplo de uso
/// ```swift
/// let viewModel = UserProfileViewModel(
///     mediator: mediator,
///     eventBus: eventBus,
///     localRepository: localUserRepository
/// )
///
/// // Cargar perfil
/// await viewModel.loadProfile()
///
/// // Entrar a modo edición
/// viewModel.enterEditMode()
///
/// // Cancelar edición
/// viewModel.cancelEdit()
/// ```
@MainActor
@Observable
public final class UserProfileViewModel {

    // MARK: - Published State

    /// Usuario cargado
    public var user: User?

    /// Indica si está cargando el perfil
    public var isLoading: Bool = false

    /// Indica si está guardando cambios
    public var isSaving: Bool = false

    /// Error actual si lo hay
    public var error: Error?

    // MARK: - Edit State

    /// Indica si está en modo edición
    public var editMode: Bool = false

    /// Nombre editado (firstName)
    public var editedFirstName: String = ""

    /// Apellido editado (lastName)
    public var editedLastName: String = ""

    /// Email editado
    public var editedEmail: String = ""

    // MARK: - Dependencies

    /// Mediator CQRS para dispatch de queries
    private let mediator: Mediator

    /// EventBus para suscripción a eventos
    private let eventBus: EventBus

    /// Repositorio local para cache (usa protocolo para testability)
    private let localRepository: any UserRepositoryProtocol

    /// IDs de suscripciones a eventos (para cleanup)
    private var subscriptionIds: [UUID] = []

    /// Logger para debugging y monitoreo
    private let logger = Logger(subsystem: "com.edugo.viewmodels", category: "UserProfile")

    // MARK: - Initialization

    /// Crea un nuevo UserProfileViewModel.
    ///
    /// - Parameters:
    ///   - mediator: Mediator CQRS para ejecutar queries
    ///   - eventBus: EventBus para suscribirse a eventos de dominio
    ///   - localRepository: Repositorio local para cache de usuario (protocolo para testability)
    public init(
        mediator: Mediator,
        eventBus: EventBus,
        localRepository: any UserRepositoryProtocol
    ) {
        self.mediator = mediator
        self.eventBus = eventBus
        self.localRepository = localRepository

        // Suscribirse a eventos y cargar perfil
        Task {
            await subscribeToEvents()
            await loadProfile()
        }
    }

    // MARK: - Public Methods

    /// Carga el perfil del usuario con estrategia cache-first.
    ///
    /// Si `forceRefresh` es false, intenta cargar desde cache primero.
    /// Siempre intenta obtener datos frescos del servidor después.
    ///
    /// - Parameter forceRefresh: Si es true, ignora el cache y carga directamente del servidor
    public func loadProfile(forceRefresh: Bool = false) async {
        isLoading = true
        error = nil

        do {
            // Cache-first strategy
            if !forceRefresh {
                if let cachedUser = try await loadFromCache() {
                    user = cachedUser
                }
            }

            // Fetch from remote via CQRS
            let query = GetUserContextQuery(
                forceRefresh: forceRefresh,
                metadata: [
                    "source": "UserProfileViewModel",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )

            let context = try await mediator.send(query)

            // Update state first
            user = context.user

            // Update cache (non-blocking, errors don't affect UI)
            do {
                try await localRepository.save(context.user)
            } catch {
                // Cache update failed, but we still have fresh data
                logger.warning("Error actualizando cache: \(error.localizedDescription)")
            }

            logger.info("Perfil cargado: \(context.user.fullName)")

        } catch {
            self.error = error
            logger.error("Error cargando perfil: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Refresca el perfil forzando recarga desde el servidor.
    public func refresh() async {
        await loadProfile(forceRefresh: true)
    }

    // MARK: - Edit Mode

    /// Entra al modo edición, copiando los valores actuales del usuario.
    public func enterEditMode() {
        guard let user = user else { return }

        editedFirstName = user.firstName
        editedLastName = user.lastName
        editedEmail = user.email
        editMode = true
    }

    /// Cancela la edición y descarta los cambios.
    public func cancelEdit() {
        editMode = false
        editedFirstName = ""
        editedLastName = ""
        editedEmail = ""
    }

    /// Guarda los cambios del perfil.
    ///
    /// - Note: Esta implementación actualiza el usuario localmente.
    ///   Para persistir en el servidor, se requiere implementar `UpdateUserProfileCommand`.
    public func saveChanges() async {
        guard let currentUser = user else { return }

        // Validar campos con trim completo (espacios, tabs, newlines, etc.)
        let trimmedFirstName = editedFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = editedLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = editedEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFirstName.isEmpty else {
            error = ValidationError.emptyField(fieldName: "firstName")
            return
        }

        guard !trimmedLastName.isEmpty else {
            error = ValidationError.emptyField(fieldName: "lastName")
            return
        }

        guard !trimmedEmail.isEmpty else {
            error = ValidationError.emptyField(fieldName: "email")
            return
        }

        // SEGURIDAD: Validar formato de email
        guard isValidEmail(trimmedEmail) else {
            error = ValidationError.invalidFormat(
                fieldName: "email",
                reason: "Formato de email inválido. Use: usuario@dominio.com"
            )
            return
        }

        isSaving = true
        error = nil

        do {
            // Crear usuario actualizado usando copy methods
            var updatedUser = currentUser
            if trimmedFirstName != currentUser.firstName {
                updatedUser = try updatedUser.with(firstName: trimmedFirstName)
            }
            if trimmedLastName != currentUser.lastName {
                updatedUser = try updatedUser.with(lastName: trimmedLastName)
            }
            if trimmedEmail != currentUser.email {
                updatedUser = try updatedUser.with(email: trimmedEmail)
            }

            // Actualizar estado
            user = updatedUser
            editMode = false

            // Guardar en cache local (non-blocking)
            do {
                try await localRepository.save(updatedUser)
            } catch {
                logger.warning("Error guardando en cache: \(error.localizedDescription)")
            }

            logger.info("Perfil actualizado localmente: \(updatedUser.fullName)")

            // Nota: Para persistir en el servidor, se debe implementar
            // UpdateUserProfileCommand y ejecutarlo via mediator

        } catch {
            self.error = error
            logger.error("Error guardando perfil: \(error.localizedDescription)")
        }

        isSaving = false
    }

    // MARK: - Error Handling

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    /// Carga el usuario desde el cache local.
    private func loadFromCache() async throws -> User? {
        // Intentar obtener el primer usuario de la lista local
        // En una implementación real, se usaría el ID del usuario actual
        do {
            let users = try await localRepository.list()
            return users.first
        } catch {
            // Cache unavailable, will load from remote
            logger.warning("Cache no disponible: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Email Validation

    /// Valida el formato de un email usando expresión regular estándar RFC 5322
    /// - Parameter email: Email a validar
    /// - Returns: true si el formato es válido
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // MARK: - Event Subscriptions

    /// Suscribe el ViewModel a eventos relevantes.
    private func subscribeToEvents() async {
        // Suscribirse a LoginSuccessEvent para refrescar después del login
        let loginSubscriptionId = await eventBus.subscribe(to: LoginSuccessEvent.self) { [weak self] event in
            guard let self = self else { return }

            Task { @MainActor in
                self.logger.debug("Login detectado, refrescando perfil...")
                await self.loadProfile(forceRefresh: true)
            }
        }
        subscriptionIds.append(loginSubscriptionId)
    }
}

// MARK: - Convenience Computed Properties

extension UserProfileViewModel {
    /// Indica si hay un usuario cargado
    public var hasUser: Bool {
        user != nil
    }

    /// Indica si hay un error
    public var hasError: Bool {
        error != nil
    }

    /// Nombre completo del usuario
    public var fullName: String {
        user?.fullName ?? ""
    }

    /// Email del usuario
    public var email: String {
        user?.email ?? ""
    }

    /// Indica si los campos editados son diferentes a los originales
    public var isEdited: Bool {
        guard let user = user else { return false }
        return editedFirstName != user.firstName ||
               editedLastName != user.lastName ||
               editedEmail != user.email
    }

    /// Indica si se pueden guardar los cambios
    public var canSave: Bool {
        !editedFirstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !editedLastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !editedEmail.trimmingCharacters(in: .whitespaces).isEmpty &&
        isEdited &&
        !isSaving
    }

    /// Indica si el botón de guardar debe estar deshabilitado
    public var isSaveButtonDisabled: Bool {
        isSaving || !canSave
    }

    /// Mensaje de error legible
    public var errorMessage: String? {
        guard let error = error else { return nil }

        if let validationError = error as? ValidationError {
            return validationError.localizedDescription
        }

        if let domainError = error as? DomainError {
            return domainError.localizedDescription
        }

        if let mediatorError = error as? MediatorError {
            switch mediatorError {
            case .handlerNotFound:
                return "Error de configuración del sistema. Contacte soporte."
            case .validationError(let message, _):
                return message
            case .executionError(let message, _):
                return "Error al cargar perfil: \(message)"
            case .registrationError:
                return "Error de configuración del sistema."
            }
        }

        return error.localizedDescription
    }

    /// Iniciales del usuario para avatar
    public var initials: String {
        guard let user = user else { return "" }
        let firstInitial = user.firstName.prefix(1).uppercased()
        let lastInitial = user.lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }

    /// Indica si la cuenta del usuario está activa
    public var isUserActive: Bool {
        user?.isActive ?? false
    }
}
