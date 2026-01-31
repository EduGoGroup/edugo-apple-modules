import Foundation
import SwiftUI
import CQRS
import Models
import EduGoCommon
import Roles
import UseCases

/// ViewModel para asignar materiales a unidades académicas usando CQRS Mediator.
///
/// Este ViewModel gestiona la asignación de materiales con verificación de permisos
/// y selección de unidades destino.
///
/// ## Responsabilidades
/// - Verificar permisos de asignación de materiales (profesor/admin)
/// - Gestionar selección múltiple de unidades destino
/// - Ejecutar AssignMaterialCommand via Mediator
/// - Gestionar fecha límite opcional
///
/// ## Integración con CQRS
/// - **Commands**: AssignMaterialCommand (con validación pre-ejecución)
/// - **Events**: MaterialAssignedEvent (publicado automáticamente por handler)
///
/// ## Verificación de Permisos
/// Utiliza RoleManager para verificar que el usuario tenga permisos
/// de edición de materiales antes de permitir la asignación.
///
/// ## Ejemplo de uso
/// ```swift
/// let viewModel = await MaterialAssignmentViewModel(
///     mediator: mediator,
///     roleManager: roleManager,
///     materialId: materialId,
///     assignedBy: currentUserId
/// )
///
/// // Seleccionar unidades
/// await viewModel.toggleUnit(unitId1)
/// await viewModel.toggleUnit(unitId2)
///
/// // Asignar material
/// await viewModel.assignMaterial()
/// ```
@MainActor
@Observable
public final class MaterialAssignmentViewModel {

    // MARK: - Published State

    /// IDs de las unidades seleccionadas para asignación
    public var selectedUnitIds: Set<UUID> = []

    /// Fecha límite opcional para la asignación
    public var assignmentDeadline: Date?

    /// Indica si está procesando la asignación
    public var isAssigning: Bool = false

    /// Error actual si lo hay
    public var error: Error?

    /// Indica si la asignación fue exitosa
    public var assignmentSuccess: Bool = false

    /// Si el material debe ser visible para estudiantes
    public var isVisible: Bool = true

    /// Si se debe notificar a los estudiantes
    public var notifyStudents: Bool = true

    /// Resultados de asignaciones exitosas
    public var assignmentResults: [MaterialAssignment] = []

    // MARK: - Dependencies

    /// Mediator CQRS para dispatch de commands
    private let mediator: Mediator

    /// Gestor de roles para verificación de permisos
    private let roleManager: RoleManager

    /// ID del material a asignar
    private let materialId: UUID

    /// ID del usuario que realiza la asignación
    private let assignedBy: UUID

    // MARK: - Cached Permission State

    /// Cache del estado de permisos
    private var cachedCanAssign: Bool = false

    // MARK: - Initialization

    /// Crea un nuevo MaterialAssignmentViewModel.
    ///
    /// - Parameters:
    ///   - mediator: Mediator CQRS para ejecutar commands
    ///   - roleManager: Gestor de roles para verificar permisos
    ///   - materialId: ID del material a asignar
    ///   - assignedBy: ID del usuario que realiza la asignación
    public init(
        mediator: Mediator,
        roleManager: RoleManager,
        materialId: UUID,
        assignedBy: UUID
    ) {
        self.mediator = mediator
        self.roleManager = roleManager
        self.materialId = materialId
        self.assignedBy = assignedBy

        // Cargar permisos de forma asíncrona
        Task {
            await loadPermissions()
        }
    }

    // MARK: - Permission Loading

    /// Carga los permisos desde RoleManager.
    public func loadPermissions() async {
        cachedCanAssign = await roleManager.hasPermission(.editMaterials)
    }

    // MARK: - Authorization

    /// Indica si el usuario puede asignar materiales.
    ///
    /// Verifica que el usuario tenga el permiso `.editMaterials`.
    public var canAssignMaterials: Bool {
        cachedCanAssign
    }

    // MARK: - Selection Methods

    /// Alterna la selección de una unidad.
    ///
    /// - Parameter unitId: ID de la unidad a alternar
    public func toggleUnit(_ unitId: UUID) {
        if selectedUnitIds.contains(unitId) {
            selectedUnitIds.remove(unitId)
        } else {
            selectedUnitIds.insert(unitId)
        }
    }

    /// Selecciona todas las unidades proporcionadas.
    ///
    /// - Parameter unitIds: Lista de IDs de unidades a seleccionar
    public func selectAll(_ unitIds: [UUID]) {
        selectedUnitIds = Set(unitIds)
    }

    /// Deselecciona todas las unidades.
    public func deselectAll() {
        selectedUnitIds.removeAll()
    }

    /// Verifica si una unidad está seleccionada.
    ///
    /// - Parameter unitId: ID de la unidad a verificar
    /// - Returns: `true` si la unidad está seleccionada
    public func isSelected(_ unitId: UUID) -> Bool {
        selectedUnitIds.contains(unitId)
    }

    // MARK: - Assignment

    /// Asigna el material a las unidades seleccionadas.
    ///
    /// Ejecuta AssignMaterialCommand para cada unidad seleccionada.
    /// Si alguna falla, continúa con las demás y reporta errores parciales.
    public func assignMaterial() async {
        // Verificar permisos
        guard canAssignMaterials else {
            error = MediatorError.validationError(
                message: "No tiene permisos para asignar materiales",
                underlyingError: nil
            )
            return
        }

        // Validar selección
        guard !selectedUnitIds.isEmpty else {
            error = ValidationError.emptyField(fieldName: "units")
            return
        }

        isAssigning = true
        error = nil
        assignmentSuccess = false
        assignmentResults = []

        var successCount = 0
        var lastError: Error?

        // Asignar a cada unidad seleccionada
        for unitId in selectedUnitIds {
            do {
                let command = AssignMaterialCommand(
                    materialId: materialId,
                    unitId: unitId,
                    assignedBy: assignedBy,
                    dueDate: assignmentDeadline,
                    visible: isVisible,
                    notifyStudents: notifyStudents,
                    metadata: [
                        "source": "MaterialAssignmentViewModel",
                        "timestamp": ISO8601DateFormatter().string(from: Date())
                    ]
                )

                let result = try await mediator.execute(command)

                if result.isSuccess, let assignment = result.getValue() {
                    assignmentResults.append(assignment)
                    successCount += 1
                    print("✅ Material asignado a unidad: \(unitId)")
                } else if let resultError = result.getError() {
                    lastError = resultError
                    print("❌ Error asignando a unidad \(unitId): \(resultError.localizedDescription)")
                }

            } catch {
                lastError = error
                print("❌ Error ejecutando command para unidad \(unitId): \(error.localizedDescription)")
            }
        }

        isAssigning = false

        // Determinar resultado final
        if successCount == selectedUnitIds.count {
            assignmentSuccess = true
            print("✅ Todas las asignaciones completadas exitosamente")
        } else if successCount > 0 {
            // Éxito parcial
            assignmentSuccess = true
            self.error = lastError
            print("⚠️ Asignación parcial: \(successCount)/\(selectedUnitIds.count)")
        } else {
            // Todas fallaron
            self.error = lastError
            print("❌ Todas las asignaciones fallaron")
        }
    }

    // MARK: - Reset

    /// Limpia el estado del ViewModel.
    public func reset() {
        selectedUnitIds.removeAll()
        assignmentDeadline = nil
        isAssigning = false
        error = nil
        assignmentSuccess = false
        isVisible = true
        notifyStudents = true
        assignmentResults = []
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }
}

// MARK: - Convenience Computed Properties

extension MaterialAssignmentViewModel {
    /// Indica si hay unidades seleccionadas
    public var hasSelection: Bool {
        !selectedUnitIds.isEmpty
    }

    /// Número de unidades seleccionadas
    public var selectedCount: Int {
        selectedUnitIds.count
    }

    /// Indica si se puede proceder con la asignación
    public var canProceed: Bool {
        canAssignMaterials && hasSelection && !isAssigning
    }

    /// Indica si hay un error
    public var hasError: Bool {
        error != nil
    }

    /// Indica si el botón de asignar debe estar deshabilitado
    public var isAssignButtonDisabled: Bool {
        isAssigning || !canProceed
    }

    /// Número de asignaciones exitosas
    public var successfulAssignmentsCount: Int {
        assignmentResults.count
    }

    /// Indica si hubo éxito parcial
    public var isPartialSuccess: Bool {
        assignmentSuccess && error != nil
    }

    /// Mensaje de error legible
    public var errorMessage: String? {
        guard let error = error else { return nil }

        if let validationError = error as? ValidationError {
            return validationError.localizedDescription
        }

        if let mediatorError = error as? MediatorError {
            switch mediatorError {
            case .handlerNotFound:
                return "Error de configuración del sistema. Contacte soporte."
            case .validationError(let message, _):
                return message
            case .executionError(let message, _):
                return "Error al asignar: \(message)"
            case .registrationError:
                return "Error de configuración del sistema."
            }
        }

        if let assignError = error as? AssignMaterialError {
            return assignError.localizedDescription
        }

        return error.localizedDescription
    }

    /// Mensaje de resultado de la asignación
    public var resultMessage: String {
        if assignmentSuccess {
            if isPartialSuccess {
                return "Asignación parcial: \(successfulAssignmentsCount) de \(selectedCount) unidades"
            } else {
                return "Material asignado exitosamente a \(successfulAssignmentsCount) unidad(es)"
            }
        }
        return ""
    }
}
