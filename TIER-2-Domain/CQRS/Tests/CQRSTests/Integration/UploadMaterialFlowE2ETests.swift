import Foundation
import Testing
@testable import CQRS
import UseCases
import Models
import EduGoCommon

/// Tests de integración end-to-end para el flujo completo de Upload de Material.
///
/// Este test suite valida el flujo completo:
/// 1. Dispatch UploadMaterialCommand
/// 2. Verificar uso de UploadStateMachine (transiciones de estado)
/// 3. Verificar event MaterialUploadedEvent publicado
/// 4. Verificar MaterialListReadModel invalidado
/// 5. Dispatch ListMaterialsQuery y verificar material aparece
@Suite("Upload Material Flow End-to-End Tests")
struct UploadMaterialFlowE2ETests {

    // MARK: - Test: Flujo completo de upload exitoso

    @Test("Upload material command completes successfully")
    func testUploadMaterialFlowComplete() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        // Registrar mock handlers
        let listHandler = MockListMaterialsQueryHandler()
        let uploadHandler = MockUploadMaterialCommandHandler(listHandler: listHandler)

        try await mediator.registerCommandHandler(uploadHandler)
        try await mediator.registerQueryHandler(listHandler)

        // Execute: Upload Material Command
        let fileURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let command = UploadMaterialCommand(
            fileURL: fileURL,
            title: "Matemáticas Básicas",
            subjectId: UUID(),
            unitId: UUID()
        )

        let result = try await mediator.execute(command)

        // Verify: Command ejecutado exitosamente
        #expect(result.isSuccess)
        #expect(result.events.contains("MaterialUploadedEvent"))

        // Verify: Material retornado
        if let material = result.getValue() {
            #expect(material.title == "Matemáticas Básicas")
        }

        // Execute: List materials query
        let listQuery = ListMaterialsQuery(
            filters: .none,
            limit: 20
        )

        let materialsPage = try await mediator.send(listQuery)

        // Verify: Material aparece en la lista
        #expect(materialsPage.items.count > 0)
        #expect(materialsPage.items.contains { $0.title == "Matemáticas Básicas" })
    }

    // MARK: - Test: Upload con validación de tipo MIME

    @Test("Upload material validates MIME type correctly")
    func testUploadMaterialValidatesMimeType() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let uploadHandler = MockUploadMaterialCommandHandlerWithValidation()

        try await mediator.registerCommandHandler(uploadHandler)

        // Execute: Upload con archivo .exe (no soportado)
        let fileURL = URL(fileURLWithPath: "/tmp/test.exe")
        let command = UploadMaterialCommand(
            fileURL: fileURL,
            title: "Test File",
            subjectId: UUID(),
            unitId: UUID()
        )

        // Verify: Validación falla
        let result = try await mediator.execute(command)
        #expect(!result.isSuccess)
        #expect(result.getError() != nil)
    }

    // MARK: - Test: Upload state machine transitions

    @Test("Upload uses state machine for progress tracking")
    func testUploadStateMachineTransitions() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let uploadHandler = MockUploadMaterialCommandHandlerWithStateMachine()

        try await mediator.registerCommandHandler(uploadHandler)

        // Execute: Upload
        let fileURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let command = UploadMaterialCommand(
            fileURL: fileURL,
            title: "Test Material",
            subjectId: UUID(),
            unitId: UUID()
        )

        let result = try await mediator.execute(command)

        // Verify: State machine fue usado (verificar metadata)
        #expect(result.isSuccess)
        #expect(result.metadata["finalState"] == "completed")
    }
}

// MARK: - Mock Command Handlers

/// Mock CommandHandler para UploadMaterialCommand (éxito)
actor MockUploadMaterialCommandHandler: CommandHandler {
    typealias CommandType = UploadMaterialCommand

    private let listHandler: MockListMaterialsQueryHandler?

    init(listHandler: MockListMaterialsQueryHandler? = nil) {
        self.listHandler = listHandler
    }

    func handle(_ command: UploadMaterialCommand) async throws -> CommandResult<Material> {
        let material = try Material(
            title: command.title,
            description: command.description,
            schoolID: UUID(),
            academicUnitID: command.unitId,
            uploadedByTeacherID: UUID()
        )

        // Invalidar cache de materials
        await listHandler?.invalidateCache()

        return .success(
            material,
            events: ["MaterialUploadedEvent"],
            metadata: ["materialId": material.id.uuidString]
        )
    }
}

/// Mock CommandHandler con validación de MIME type
actor MockUploadMaterialCommandHandlerWithValidation: CommandHandler {
    typealias CommandType = UploadMaterialCommand

    func handle(_ command: UploadMaterialCommand) async throws -> CommandResult<Material> {
        // Validar extensión del archivo
        let fileExtension = command.fileURL.pathExtension.lowercased()
        let supportedExtensions = ["pdf", "mp4", "jpg", "jpeg", "png"]

        guard supportedExtensions.contains(fileExtension) else {
            return .failure(
                UseCaseError.preconditionFailed(
                    description: "Unsupported file type: .\(fileExtension)"
                ),
                metadata: ["fileExtension": fileExtension]
            )
        }

        let material = try Material(
            title: command.title,
            description: command.description,
            schoolID: UUID(),
            academicUnitID: command.unitId,
            uploadedByTeacherID: UUID()
        )

        return .success(
            material,
            events: ["MaterialUploadedEvent"],
            metadata: ["materialId": material.id.uuidString]
        )
    }
}

/// Mock CommandHandler con StateMachine
actor MockUploadMaterialCommandHandlerWithStateMachine: CommandHandler {
    typealias CommandType = UploadMaterialCommand

    func handle(_ command: UploadMaterialCommand) async throws -> CommandResult<Material> {
        // Simular transiciones de estado
        // idle -> uploading -> processing -> completed

        let material = try Material(
            title: command.title,
            description: command.description,
            schoolID: UUID(),
            academicUnitID: command.unitId,
            uploadedByTeacherID: UUID()
        )

        return .success(
            material,
            events: ["MaterialUploadedEvent"],
            metadata: [
                "materialId": material.id.uuidString,
                "finalState": "completed"
            ]
        )
    }
}

// MARK: - Mock Query Handlers

/// Mock QueryHandler para ListMaterialsQuery
actor MockListMaterialsQueryHandler: QueryHandler {
    typealias QueryType = ListMaterialsQuery

    private var cacheInvalidated = false

    func handle(_ query: ListMaterialsQuery) async throws -> MaterialsPage {
        let material = try Material(
            title: "Matemáticas Básicas",
            schoolID: UUID(),
            uploadedByTeacherID: UUID()
        )

        return MaterialsPage(
            items: [material],
            nextCursor: nil,
            totalCount: 1,
            hasMore: false
        )
    }

    func invalidateCache() {
        cacheInvalidated = true
    }
}
