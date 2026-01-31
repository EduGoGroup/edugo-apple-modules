import Foundation
import Testing
@testable import CQRS
import UseCases
import Models
import EduGoCommon

/// Tests de integración para validar escenarios de error.
///
/// Este test suite valida:
/// 1. Command con validación fallida
/// 2. Query con handler no encontrado
/// 3. Command execution failure + rollback
/// 4. Manejo de errores de dominio
@Suite("Error Scenarios Tests")
struct ErrorScenariosTests {

    // MARK: - Test: Validación de command fallida

    @Test("Command validation failure is properly handled")
    func testCommandValidationFailure() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        let loginHandler = MockLoginCommandHandlerForValidation()

        try await mediator.registerCommandHandler(loginHandler)

        // Execute: Command con email inválido
        let command = LoginCommand(
            email: "",  // Email vacío - falla validación
            password: "password123"
        )

        // Verify: Lanza ValidationError
        do {
            let _ = try await mediator.execute(command)
            Issue.record("Expected validation error but command succeeded")
        } catch let error as MediatorError {
            switch error {
            case .validationError:
                // Expected
                break
            default:
                Issue.record("Expected validation error, got: \(error)")
            }
        }
    }

    // MARK: - Test: Handler no encontrado

    @Test("Query without registered handler throws proper error")
    func testQueryHandlerNotFound() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        // NO registrar handler

        // Execute: Query sin handler
        let query = GetStudentDashboardQuery(userId: UUID())

        // Verify: Lanza HandlerNotFoundError
        do {
            let _ = try await mediator.send(query)
            Issue.record("Expected handler not found error")
        } catch let error as MediatorError {
            switch error {
            case .handlerNotFound:
                // Expected
                break
            default:
                Issue.record("Expected handler not found error, got: \(error)")
            }
        }
    }

    // MARK: - Test: Command execution failure

    @Test("Command execution failure is properly handled")
    func testCommandExecutionFailure() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        let uploadHandler = MockUploadMaterialCommandHandlerFailure()

        try await mediator.registerCommandHandler(uploadHandler)

        // Execute: Upload que falla en ejecución
        let fileURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let command = UploadMaterialCommand(
            fileURL: fileURL,
            title: "Test",
            subjectId: UUID(),
            unitId: UUID()
        )

        let result = try await mediator.execute(command)

        // Verify: Result marca como failure
        #expect(!result.isSuccess)
        #expect(result.getError() != nil)
    }

    // MARK: - Test: Errores de dominio (UseCaseError)

    @Test("Domain errors are properly propagated")
    func testDomainErrorPropagation() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        let loginHandler = MockLoginCommandHandlerAuthFailure()

        try await mediator.registerCommandHandler(loginHandler)

        // Execute: Login que falla (credenciales incorrectas)
        let command = LoginCommand(
            email: "wrong@edugo.com",
            password: "wrongpassword"
        )

        let result = try await mediator.execute(command)

        // Verify: Error de autenticación propagado
        #expect(!result.isSuccess)

        if let error = result.getError() as? UseCaseError {
            switch error {
            case .authenticationFailed:
                // Expected
                break
            default:
                Issue.record("Expected authentication failed error, got: \(error)")
            }
        } else {
            Issue.record("Expected UseCaseError")
        }
    }

    // MARK: - Test: Rollback en caso de error

    @Test("Failed command does not affect cache state")
    func testRollbackOnCommandFailure() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        let materialsHandler = MockListMaterialsQueryHandlerSimple()
        let uploadHandler = MockUploadMaterialCommandHandlerFailure()

        try await mediator.registerQueryHandler(materialsHandler)
        try await mediator.registerCommandHandler(uploadHandler)

        // Execute: Cargar materiales iniciales
        let query = ListMaterialsQuery(limit: 20)
        let materials1 = try await mediator.send(query)
        let initialCount = materials1.items.count

        // Execute: Upload que falla
        let fileURL = URL(fileURLWithPath: "/tmp/fail.pdf")
        let command = UploadMaterialCommand(
            fileURL: fileURL,
            title: "Failing Upload",
            subjectId: UUID(),
            unitId: UUID()
        )

        let result = try await mediator.execute(command)
        #expect(!result.isSuccess)

        // Verify: Cache no fue modificado
        let materials2 = try await mediator.send(query)
        #expect(materials2.items.count == initialCount)
    }

    // MARK: - Test: Errores de validación específicos

    @Test("Validation errors provide detailed messages")
    func testValidationErrorMessages() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        let uploadHandler = MockUploadMaterialCommandHandlerWithMimeValidation()

        try await mediator.registerCommandHandler(uploadHandler)

        // Execute: Upload con extensión no soportada
        let fileURL = URL(fileURLWithPath: "/tmp/test.exe")
        let command = UploadMaterialCommand(
            fileURL: fileURL,
            title: "Test",
            subjectId: UUID(),
            unitId: UUID()
        )

        // Verify: Error específico de extensión
        let result = try await mediator.execute(command)
        #expect(!result.isSuccess)

        if let error = result.getError() as? UseCaseError {
            if case .preconditionFailed(let description) = error {
                #expect(description.contains("exe"))
            } else {
                Issue.record("Expected precondition failed error, got: \(error)")
            }
        }
    }

    // MARK: - Test: Manejo de excepciones inesperadas

    @Test("Unexpected errors are wrapped in ExecutionError")
    func testUnexpectedErrorWrapping() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        let handler = MockCommandHandlerWithUnexpectedError()

        try await mediator.registerCommandHandler(handler)

        // Execute
        let command = MockCommand()

        do {
            let result = try await mediator.execute(command)

            // Verify: Envuelto en ExecutionError
            #expect(!result.isSuccess)
        } catch let error as MediatorError {
            switch error {
            case .executionError:
                // Expected
                break
            default:
                Issue.record("Expected execution error, got: \(error)")
            }
        }
    }
}

// MARK: - Mock Command Handlers

/// Mock LoginCommandHandler para validación (siempre éxito si válido)
actor MockLoginCommandHandlerForValidation: CommandHandler {
    typealias CommandType = LoginCommand

    func handle(_ command: LoginCommand) async throws -> CommandResult<LoginOutput> {
        let user = try Models.User(
            firstName: "Test",
            lastName: "User",
            email: command.email
        )

        let output = LoginOutput(
            user: user,
            accessToken: "mock-token",
            refreshToken: "mock-refresh"
        )

        return .success(output, events: [], metadata: [:])
    }
}

/// Mock LoginCommandHandler que falla con error de autenticación
actor MockLoginCommandHandlerAuthFailure: CommandHandler {
    typealias CommandType = LoginCommand

    func handle(_ command: LoginCommand) async throws -> CommandResult<LoginOutput> {
        return .failure(
            UseCaseError.unauthorized(action: "login with invalid credentials"),
            metadata: ["email": command.email]
        )
    }
}

/// Mock UploadMaterialCommandHandler que falla
actor MockUploadMaterialCommandHandlerFailure: CommandHandler {
    typealias CommandType = UploadMaterialCommand

    func handle(_ command: UploadMaterialCommand) async throws -> CommandResult<Material> {
        return .failure(
            UseCaseError.serverError(reason: "Upload service unavailable"),
            metadata: ["fileName": command.fileName]
        )
    }
}

/// Mock UploadMaterialCommandHandler con validación de MIME type
actor MockUploadMaterialCommandHandlerWithMimeValidation: CommandHandler {
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

        return .success(material, events: [], metadata: [:])
    }
}

// MARK: - Mock Query Handlers

/// Mock ListMaterialsQueryHandler simple
actor MockListMaterialsQueryHandlerSimple: QueryHandler {
    typealias QueryType = ListMaterialsQuery

    func handle(_ query: ListMaterialsQuery) async throws -> MaterialsPage {
        return MaterialsPage(
            items: [],
            nextCursor: nil,
            totalCount: 0,
            hasMore: false
        )
    }
}

// MARK: - Mock Command for unexpected error test

struct MockCommand: Command {
    typealias Result = String

    func validate() throws {
        // No validation
    }
}

actor MockCommandHandlerWithUnexpectedError: CommandHandler {
    typealias CommandType = MockCommand

    func handle(_ command: MockCommand) async throws -> CommandResult<String> {
        // Throw unexpected error
        throw NSError(domain: "UnexpectedError", code: 999, userInfo: nil)
    }
}
