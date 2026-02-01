import Foundation
import Testing
@testable import ViewModels
@testable import CQRS
import Models
import UseCases
import EduGoCommon
import Roles

/// Tests unitarios para MaterialAssignmentViewModel.
///
/// Este test suite valida:
/// - Verificación de permisos
/// - Selección/deselección de unidades
/// - Asignación exitosa
/// - Validación de selección vacía
/// - Manejo de errores de autorización
@Suite("MaterialAssignmentViewModel Tests")
struct MaterialAssignmentViewModelTests {

    // MARK: - Test: Verificación de permisos (profesor)

    @Test("Teacher has permission to assign materials")
    @MainActor
    func testTeacherHasPermission() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        await roleManager.setRole(.teacher)

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        // Esperar a que se carguen los permisos
        await viewModel.loadPermissions()

        // Verify
        #expect(viewModel.canAssignMaterials)
    }

    // MARK: - Test: Verificación de permisos (estudiante)

    @Test("Student does not have permission to assign materials")
    @MainActor
    func testStudentDoesNotHavePermission() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        await roleManager.setRole(.student)

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        // Esperar a que se carguen los permisos
        await viewModel.loadPermissions()

        // Verify
        #expect(!viewModel.canAssignMaterials)
    }

    // MARK: - Test: Verificación de permisos (admin)

    @Test("Admin has permission to assign materials")
    @MainActor
    func testAdminHasPermission() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        await roleManager.setRole(.admin)

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        // Esperar a que se carguen los permisos
        await viewModel.loadPermissions()

        // Verify
        #expect(viewModel.canAssignMaterials)
    }

    // MARK: - Test: Selección de unidades

    @Test("Toggle unit selection works correctly")
    @MainActor
    func testToggleUnitSelection() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        let unitId1 = UUID()
        let unitId2 = UUID()

        // Verify: Estado inicial
        #expect(!viewModel.hasSelection)
        #expect(viewModel.selectedCount == 0)

        // Execute: Seleccionar primera unidad
        viewModel.toggleUnit(unitId1)

        // Verify
        #expect(viewModel.hasSelection)
        #expect(viewModel.selectedCount == 1)
        #expect(viewModel.isSelected(unitId1))
        #expect(!viewModel.isSelected(unitId2))

        // Execute: Seleccionar segunda unidad
        viewModel.toggleUnit(unitId2)

        // Verify
        #expect(viewModel.selectedCount == 2)
        #expect(viewModel.isSelected(unitId1))
        #expect(viewModel.isSelected(unitId2))

        // Execute: Deseleccionar primera unidad
        viewModel.toggleUnit(unitId1)

        // Verify
        #expect(viewModel.selectedCount == 1)
        #expect(!viewModel.isSelected(unitId1))
        #expect(viewModel.isSelected(unitId2))
    }

    // MARK: - Test: Select All y Deselect All

    @Test("Select all and deselect all work correctly")
    @MainActor
    func testSelectAllAndDeselectAll() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        let unitIds = [UUID(), UUID(), UUID()]

        // Execute: Select all
        viewModel.selectAll(unitIds)

        // Verify
        #expect(viewModel.selectedCount == 3)
        for unitId in unitIds {
            #expect(viewModel.isSelected(unitId))
        }

        // Execute: Deselect all
        viewModel.deselectAll()

        // Verify
        #expect(!viewModel.hasSelection)
        #expect(viewModel.selectedCount == 0)
    }

    // MARK: - Test: Asignación exitosa

    @Test("Assigns material successfully")
    @MainActor
    func testAssignsMaterialSuccessfully() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        await roleManager.setRole(.teacher)

        let mockHandler = MockAssignMaterialCommandHandler()
        try await mediator.registerCommandHandler(mockHandler)

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        await viewModel.loadPermissions()

        // Seleccionar unidades
        let unitId = UUID()
        viewModel.toggleUnit(unitId)

        // Execute
        await viewModel.assignMaterial()

        // Verify
        #expect(!viewModel.isAssigning)
        #expect(viewModel.assignmentSuccess)
        #expect(viewModel.error == nil)
        #expect(viewModel.successfulAssignmentsCount == 1)
    }

    // MARK: - Test: Error cuando no hay unidades seleccionadas

    @Test("Shows error when no units selected")
    @MainActor
    func testShowsErrorWhenNoUnitsSelected() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        await roleManager.setRole(.teacher)

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        await viewModel.loadPermissions()

        // Execute: Intentar asignar sin selección
        await viewModel.assignMaterial()

        // Verify
        #expect(!viewModel.isAssigning)
        #expect(!viewModel.assignmentSuccess)
        #expect(viewModel.error != nil)
    }

    // MARK: - Test: Error de autorización

    @Test("Shows error when user lacks permission")
    @MainActor
    func testShowsErrorWhenUserLacksPermission() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        await roleManager.setRole(.student) // Sin permisos

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        await viewModel.loadPermissions()

        // Seleccionar unidad
        viewModel.toggleUnit(UUID())

        // Execute
        await viewModel.assignMaterial()

        // Verify
        #expect(!viewModel.assignmentSuccess)
        #expect(viewModel.error != nil)
        #expect(viewModel.errorMessage?.contains("permisos") == true)
    }

    // MARK: - Test: Reset de estado

    @Test("Resets state correctly")
    @MainActor
    func testResetsStateCorrectly() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        await roleManager.setRole(.teacher)

        let mockHandler = MockAssignMaterialCommandHandler()
        try await mediator.registerCommandHandler(mockHandler)

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        await viewModel.loadPermissions()

        // Configurar estado
        viewModel.toggleUnit(UUID())
        viewModel.assignmentDeadline = Date().addingTimeInterval(86400)
        viewModel.isVisible = false
        viewModel.notifyStudents = false

        await viewModel.assignMaterial()

        // Verify estado después de asignar
        #expect(viewModel.assignmentSuccess)

        // Execute: Reset
        viewModel.reset()

        // Verify
        #expect(!viewModel.hasSelection)
        #expect(viewModel.assignmentDeadline == nil)
        #expect(!viewModel.isAssigning)
        #expect(viewModel.error == nil)
        #expect(!viewModel.assignmentSuccess)
        #expect(viewModel.isVisible == true)
        #expect(viewModel.notifyStudents == true)
        #expect(viewModel.assignmentResults.isEmpty)
    }

    // MARK: - Test: Computed properties

    @Test("Computed properties work correctly")
    @MainActor
    func testComputedPropertiesWork() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        await roleManager.setRole(.teacher)

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        await viewModel.loadPermissions()

        // Verify: Estado inicial (sin selección)
        #expect(!viewModel.hasSelection)
        #expect(!viewModel.canProceed)
        #expect(viewModel.isAssignButtonDisabled)

        // Seleccionar unidad
        viewModel.toggleUnit(UUID())

        // Verify: Con selección
        #expect(viewModel.hasSelection)
        #expect(viewModel.canProceed)
        #expect(!viewModel.isAssignButtonDisabled)
    }

    // MARK: - Test: Clear error

    @Test("Clear error works correctly")
    @MainActor
    func testClearErrorWorks() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        await roleManager.setRole(.student)

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        await viewModel.loadPermissions()

        // Provocar error
        viewModel.toggleUnit(UUID())
        await viewModel.assignMaterial()

        #expect(viewModel.hasError)

        // Execute
        viewModel.clearError()

        // Verify
        #expect(!viewModel.hasError)
        #expect(viewModel.error == nil)
    }

    // MARK: - Test: Asignación múltiple

    @Test("Assigns to multiple units successfully")
    @MainActor
    func testAssignsToMultipleUnitsSuccessfully() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        await roleManager.setRole(.teacher)

        let mockHandler = MockAssignMaterialCommandHandler()
        try await mediator.registerCommandHandler(mockHandler)

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        await viewModel.loadPermissions()

        // Seleccionar múltiples unidades
        let unitIds = [UUID(), UUID(), UUID()]
        viewModel.selectAll(unitIds)

        // Execute
        await viewModel.assignMaterial()

        // Verify
        #expect(viewModel.assignmentSuccess)
        #expect(viewModel.successfulAssignmentsCount == 3)
        #expect(!viewModel.isPartialSuccess)
    }

    // MARK: - Test: Configuración de deadline y visibilidad

    @Test("Deadline and visibility settings are preserved")
    @MainActor
    func testDeadlineAndVisibilitySettings() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        // Configurar opciones
        let deadline = Date().addingTimeInterval(86400 * 7) // Una semana
        viewModel.assignmentDeadline = deadline
        viewModel.isVisible = false
        viewModel.notifyStudents = false

        // Verify
        #expect(viewModel.assignmentDeadline == deadline)
        #expect(viewModel.isVisible == false)
        #expect(viewModel.notifyStudents == false)
    }

    // MARK: - Test: Mensajes de error no exponen UUIDs

    @Test("Error messages do not expose UUIDs")
    @MainActor
    func testErrorMessagesDoNotExposeUUIDs() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        await roleManager.setRole(.teacher)

        // Registrar handler que simula falla en algunas unidades
        let mockHandler = MockAssignMaterialCommandHandlerWithPartialFailure()
        try await mediator.registerCommandHandler(mockHandler)

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        await viewModel.loadPermissions()

        // Seleccionar 5 unidades (handler fallará 3)
        let unit1 = UUID()
        let unit2 = UUID()
        let unit3 = UUID()
        let unit4 = UUID()
        let unit5 = UUID()

        viewModel.toggleUnit(unit1)
        viewModel.toggleUnit(unit2)
        viewModel.toggleUnit(unit3)
        viewModel.toggleUnit(unit4)
        viewModel.toggleUnit(unit5)

        // Execute: Asignar material (fallará parcialmente)
        await viewModel.assignMaterial()

        // Verify: El mensaje de error no debe contener UUIDs
        #expect(viewModel.error != nil)

        if let error = viewModel.error {
            let errorMessage = error.localizedDescription

            // Verificar que NO contiene formato de UUID (8-4-4-4-12 caracteres hexadecimales)
            let uuidPattern = "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
            let uuidRegex = try! NSRegularExpression(pattern: uuidPattern)
            let matches = uuidRegex.matches(in: errorMessage, range: NSRange(errorMessage.startIndex..., in: errorMessage))

            #expect(matches.isEmpty, "El mensaje de error no debe contener UUIDs: \(errorMessage)")

            // Verificar que contiene información útil
            #expect(errorMessage.contains("asignaciones") || errorMessage.contains("asignación"), "El mensaje debe mencionar asignaciones")
            #expect(errorMessage.contains("completadas") || errorMessage.contains("fallaron") || errorMessage.contains("falló"), "El mensaje debe indicar resultado")
        }
    }

    @Test("All failed error message does not expose UUIDs")
    @MainActor
    func testAllFailedErrorDoesNotExposeUUIDs() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        await roleManager.setRole(.teacher)

        // Registrar handler que simula falla total
        let mockHandler = MockAssignMaterialCommandHandlerWithAllFailures()
        try await mediator.registerCommandHandler(mockHandler)

        let viewModel = MaterialAssignmentViewModel(
            mediator: mediator,
            roleManager: roleManager,
            materialId: UUID(),
            assignedBy: UUID()
        )

        await viewModel.loadPermissions()

        // Seleccionar 3 unidades (todas fallarán)
        viewModel.toggleUnit(UUID())
        viewModel.toggleUnit(UUID())
        viewModel.toggleUnit(UUID())

        // Execute: Asignar material (todas fallarán)
        await viewModel.assignMaterial()

        // Verify: El mensaje de error no debe contener UUIDs ni detalles técnicos
        #expect(viewModel.error != nil)

        if let error = viewModel.error {
            let errorMessage = error.localizedDescription

            // Verificar que NO contiene formato de UUID
            let uuidPattern = "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
            let uuidRegex = try! NSRegularExpression(pattern: uuidPattern)
            let matches = uuidRegex.matches(in: errorMessage, range: NSRange(errorMessage.startIndex..., in: errorMessage))

            #expect(matches.isEmpty, "El mensaje de error no debe contener UUIDs: \(errorMessage)")

            // Verificar mensaje amigable
            #expect(errorMessage.contains("No se pudo completar"))
            #expect(errorMessage.contains("unidad") || errorMessage.contains("unidades"))
        }
    }
}

// MARK: - Mock Handlers

/// Mock CommandHandler para AssignMaterialCommand (éxito)
actor MockAssignMaterialCommandHandler: CommandHandler {
    typealias CommandType = AssignMaterialCommand

    func handle(_ command: AssignMaterialCommand) async throws -> CommandResult<MaterialAssignment> {
        let material = try Material(
            title: "Test Material",
            description: "A test material",
            schoolID: UUID(),
            academicUnitID: command.unitId,
            uploadedByTeacherID: command.assignedBy
        )

        let unit = UnitInfo(
            id: command.unitId,
            name: "Test Unit",
            schoolId: UUID()
        )

        let assigner = AssignerInfo(
            id: command.assignedBy,
            fullName: "Test Teacher",
            email: "teacher@test.com"
        )

        let assignment = MaterialAssignment(
            id: UUID(),
            material: material,
            unit: unit,
            assignedAt: Date(),
            dueDate: command.dueDate,
            assignedBy: assigner,
            isVisible: command.visible,
            wasAlreadyAssigned: false
        )

        return .success(
            assignment,
            events: ["MaterialAssignedEvent"],
            metadata: ["assignmentId": assignment.id.uuidString]
        )
    }
}

/// Mock CommandHandler que simula error
actor MockAssignMaterialCommandHandlerWithError: CommandHandler {
    typealias CommandType = AssignMaterialCommand

    func handle(_ command: AssignMaterialCommand) async throws -> CommandResult<MaterialAssignment> {
        return .failure(
            UseCaseError.executionFailed(reason: "Assignment failed"),
            metadata: ["reason": "test_error"]
        )
    }
}

/// Mock CommandHandler que simula fallo parcial (falla cada 3 de 5 llamadas)
actor MockAssignMaterialCommandHandlerWithPartialFailure: CommandHandler {
    typealias CommandType = AssignMaterialCommand

    private var callCount = 0

    func handle(_ command: AssignMaterialCommand) async throws -> CommandResult<MaterialAssignment> {
        callCount += 1

        // Fallar en las llamadas 2, 3, y 5 (3 de 5)
        if callCount == 2 || callCount == 3 || callCount == 5 {
            return .failure(
                UseCaseError.executionFailed(reason: "Simulated partial failure"),
                metadata: ["callNumber": "\(callCount)"]
            )
        }

        // Éxito en las demás
        let material = try Material(
            title: "Test Material",
            description: "A test material",
            schoolID: UUID(),
            academicUnitID: command.unitId,
            uploadedByTeacherID: command.assignedBy
        )

        let unit = UnitInfo(
            id: command.unitId,
            name: "Test Unit \(callCount)",
            schoolId: UUID()
        )

        let assigner = AssignerInfo(
            id: command.assignedBy,
            fullName: "Test Teacher",
            email: "teacher@test.com"
        )

        let assignment = MaterialAssignment(
            id: UUID(),
            material: material,
            unit: unit,
            assignedAt: Date(),
            dueDate: command.dueDate,
            assignedBy: assigner,
            isVisible: command.visible,
            wasAlreadyAssigned: false
        )

        return .success(
            assignment,
            events: ["MaterialAssignedEvent"],
            metadata: ["assignmentId": assignment.id.uuidString]
        )
    }
}

/// Mock CommandHandler que simula fallo total (todas las llamadas fallan)
actor MockAssignMaterialCommandHandlerWithAllFailures: CommandHandler {
    typealias CommandType = AssignMaterialCommand

    func handle(_ command: AssignMaterialCommand) async throws -> CommandResult<MaterialAssignment> {
        return .failure(
            UseCaseError.executionFailed(reason: "Simulated total failure"),
            metadata: ["reason": "all_failed"]
        )
    }
}
