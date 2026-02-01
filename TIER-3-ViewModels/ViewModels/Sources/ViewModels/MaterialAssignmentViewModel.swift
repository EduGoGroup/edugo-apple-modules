import Foundation
import SwiftUI
import OSLog
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

    /// Logger para debugging y monitoreo
    private let logger = Logger(subsystem: "com.edugo.viewmodels", category: "MaterialAssignment")

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
        // SEGURIDAD: Refresh permissions antes de validar para evitar race conditions
        // Los permisos pueden haber cambiado desde que se cargaron en init
        await loadPermissions()

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

        // Capturar propiedades antes del TaskGroup para evitar acceso async
        let materialId = self.materialId
        let assignedBy = self.assignedBy
        let deadline = self.assignmentDeadline
        let isVisible = self.isVisible
        let notifyStudents = self.notifyStudents
        let mediator = self.mediator

        // Procesar asignaciones en paralelo usando TaskGroup
        let results = await withTaskGroup(of: (UUID, Result<MaterialAssignment, Error>).self) { group in
            for unitId in selectedUnitIds {
                group.addTask {
                    do {
                        let command = AssignMaterialCommand(
                            materialId: materialId,
                            unitId: unitId,
                            assignedBy: assignedBy,
                            dueDate: deadline,
                            visible: isVisible,
                            notifyStudents: notifyStudents,
                            metadata: [
                                "source": "MaterialAssignmentViewModel",
                                "timestamp": ISO8601DateFormatter().string(from: Date())
                            ]
                        )

                        let result = try await mediator.execute(command)
                        guard let assignment = try result.getValue() else {
                            throw MediatorError.executionError(
                                message: "No se pudo obtener el resultado de la asignación",
                                underlyingError: nil
                            )
                        }
                        return (unitId, .success(assignment))
                    } catch {
                        return (unitId, .failure(error))
                    }
                }
            }

            // Recolectar resultados
            var taskResults: [(UUID, Result<MaterialAssignment, Error>)] = []
            for await result in group {
                taskResults.append(result)
            }
            return taskResults
        }

        // Procesar resultados
        var successfulAssignments: [MaterialAssignment] = []
        var failuresByUnit: [UUID: Error] = [:]

        for (unitId, result) in results {
            switch result {
            case .success(let assignment):
                successfulAssignments.append(assignment)
                logger.info("Material asignado a unidad: \(unitId)")
            case .failure(let error):
                failuresByUnit[unitId] = error
                logger.error("Error asignando material a unidad \(unitId): \(error.localizedDescription)")
            }
        }

        // Actualizar array de resultados (successfulAssignmentsCount se calcula automáticamente)
        self.assignmentResults = successfulAssignments

        isAssigning = false

        // Determinar resultado final con información detallada
        if successfulAssignments.count == selectedUnitIds.count {
            // Todas exitosas
            assignmentSuccess = true
            logger.info("Todas las asignaciones completadas exitosamente")
        } else if successfulAssignments.count > 0 {
            // Éxito parcial - crear error con detalles
            assignmentSuccess = true
            self.error = createPartialSuccessError(
                successCount: successfulAssignments.count,
                totalCount: selectedUnitIds.count,
                failures: failuresByUnit
            )
            logger.warning("Asignación parcial: \(successfulAssignments.count)/\(self.selectedUnitIds.count)")
        } else {
            // Todas fallaron
            assignmentSuccess = false
            self.error = createAllFailedError(failures: failuresByUnit)
            logger.error("Todas las asignaciones fallaron")
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

    // MARK: - Error Helpers

    /// Crea un error descriptivo para éxito parcial
    private func createPartialSuccessError(
        successCount: Int,
        totalCount: Int,
        failures: [UUID: Error]
    ) -> Error {
        let failureCount = totalCount - successCount

        // SEGURIDAD: No exponer UUIDs internos al usuario
        // Los UUIDs completos se registran en logs del sistema para debugging
        logger.error("Asignaciones fallidas - UUIDs: \(failures.keys.map { $0.uuidString }.joined(separator: ", "))")

        // Mensaje amigable sin UUIDs
        return MediatorError.executionError(
            message: "\(successCount) de \(totalCount) asignaciones completadas. \(failureCount) \(failureCount == 1 ? "asignación falló" : "asignaciones fallaron"). Por favor, verifique los permisos e intente nuevamente.",
            underlyingError: nil
        )
    }

    /// Crea un error descriptivo cuando todas las asignaciones fallan
    private func createAllFailedError(failures: [UUID: Error]) -> Error {
        let failureCount = failures.count

        // SEGURIDAD: No exponer UUIDs internos ni detalles técnicos al usuario
        // Los errores completos se registran en logs del sistema para debugging
        for (unitId, error) in failures {
            logger.error("Asignación fallida - Unidad: \(unitId.uuidString), Error: \(error.localizedDescription)")
        }

        // Mensaje genérico sin información técnica sensible
        return MediatorError.executionError(
            message: "No se pudo completar la asignación en \(failureCount) \(failureCount == 1 ? "unidad" : "unidades"). Por favor, verifique los permisos e intente nuevamente.",
            underlyingError: nil
        )
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
