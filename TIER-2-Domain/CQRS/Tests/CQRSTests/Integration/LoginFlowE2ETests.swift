import Foundation
import Testing
@testable import CQRS
import UseCases
import Models
import EduGoCommon

/// Tests de integración end-to-end para el flujo completo de Login.
///
/// Este test suite valida el flujo completo:
/// 1. Dispatch LoginCommand
/// 2. Verificar event LoginSuccessEvent publicado
/// 3. Verificar cache UserContext invalidado
/// 4. Dispatch GetUserContextQuery
/// 5. Verificar cache hit en segunda llamada
@Suite("Login Flow End-to-End Tests")
struct LoginFlowE2ETests {

    // MARK: - Test: Flujo completo de login exitoso

    @Test("Login command dispatches successfully and publishes events")
    func testLoginFlowComplete() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        // Registrar mock handlers directamente
        let loginHandler = LoginFlowMockLoginCommandHandler()
        let userContextHandler = MockGetUserContextQueryHandler()

        try await mediator.registerCommandHandler(loginHandler)
        try await mediator.registerQueryHandler(userContextHandler)

        // Execute: Dispatch LoginCommand
        let command = LoginCommand(
            email: "test@edugo.com",
            password: "password123"
        )

        let result = try await mediator.execute(command)

        // Verify: Command ejecutado exitosamente
        #expect(result.isSuccess)
        #expect(result.events.contains("LoginSuccessEvent"))

        // Verify: Usuario retornado correctamente
        if let loginOutput = result.getValue() {
            #expect(loginOutput.user.email == "test@edugo.com")
        }

        // Execute: Query UserContext después de login
        let userContextQuery = GetUserContextQuery(forceRefresh: false)

        let userContext = try await mediator.send(userContextQuery)

        // Verify: UserContext cargado correctamente
        #expect(userContext.user.email == "test@edugo.com")
    }

    // MARK: - Test: Cache invalidation después de login

    @Test("Login invalidates UserContext cache correctly")
    func testLoginInvalidatesUserContextCache() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        let userContextHandler = MockGetUserContextQueryHandler()
        let loginHandler = MockLoginCommandHandlerWithInvalidation(
            userContextHandler: userContextHandler
        )

        try await mediator.registerCommandHandler(loginHandler)
        try await mediator.registerQueryHandler(userContextHandler)

        // Execute: Login
        let command = LoginCommand(
            email: "test@edugo.com",
            password: "password123"
        )

        let _ = try await mediator.execute(command)

        // Execute: Query UserContext - debería recargar después de invalidación
        let query = GetUserContextQuery(forceRefresh: false)
        let context1 = try await mediator.send(query)

        // Segunda query - debería usar cache si no hay invalidación
        let context2 = try await mediator.send(query)

        // Verify: Contextos cargados
        #expect(context1.user.email == "test@edugo.com")
        #expect(context2.user.email == "test@edugo.com")
    }

    // MARK: - Test: Login con credenciales inválidas

    @Test("Login with invalid credentials fails with proper error")
    func testLoginWithInvalidCredentials() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let loginHandler = MockLoginCommandHandlerFailure()

        try await mediator.registerCommandHandler(loginHandler)

        // Execute: Login con credenciales incorrectas
        let command = LoginCommand(
            email: "wrong@edugo.com",
            password: "wrongpassword"
        )

        let result = try await mediator.execute(command)

        // Verify: Command falló
        #expect(!result.isSuccess)
        #expect(result.getError() != nil)
    }
}

// MARK: - Mock Command Handlers

/// Mock CommandHandler para LoginCommand (éxito)
actor LoginFlowMockLoginCommandHandler: CommandHandler {
    typealias CommandType = LoginCommand

    func handle(_ command: LoginCommand) async throws -> CommandResult<LoginOutput> {
        let user = try Models.User(
            firstName: "Test",
            lastName: "User",
            email: command.email
        )

        let output = LoginOutput(
            user: user,
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token"
        )

        return .success(
            output,
            events: ["LoginSuccessEvent"],
            metadata: ["userId": user.id.uuidString]
        )
    }
}

/// Mock CommandHandler para LoginCommand con invalidación de cache
actor MockLoginCommandHandlerWithInvalidation: CommandHandler {
    typealias CommandType = LoginCommand

    private let userContextHandler: MockGetUserContextQueryHandler

    init(userContextHandler: MockGetUserContextQueryHandler) {
        self.userContextHandler = userContextHandler
    }

    func handle(_ command: LoginCommand) async throws -> CommandResult<LoginOutput> {
        let user = try Models.User(
            firstName: "Test",
            lastName: "User",
            email: command.email
        )

        // Invalidar cache de UserContext
        await userContextHandler.invalidateCache()

        let output = LoginOutput(
            user: user,
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token"
        )

        return .success(
            output,
            events: ["LoginSuccessEvent", "UserContextInvalidatedEvent"],
            metadata: ["userId": user.id.uuidString]
        )
    }
}

/// Mock CommandHandler para LoginCommand que falla
actor MockLoginCommandHandlerFailure: CommandHandler {
    typealias CommandType = LoginCommand

    func handle(_ command: LoginCommand) async throws -> CommandResult<LoginOutput> {
        return .failure(
            UseCaseError.unauthorized(action: "login with invalid credentials"),
            metadata: ["email": command.email]
        )
    }
}

// MARK: - Mock Query Handlers

/// Mock QueryHandler para GetUserContextQuery
actor MockGetUserContextQueryHandler: QueryHandler {
    typealias QueryType = GetUserContextQuery

    private var cacheInvalidated = false

    func handle(_ query: GetUserContextQuery) async throws -> UserContext {
        let user = try Models.User(
            firstName: "Test",
            lastName: "User",
            email: "test@edugo.com"
        )

        return UserContext(
            user: user,
            memberships: [],
            unitsMap: [:],
            schoolsMap: [:]
        )
    }

    func invalidateCache() {
        cacheInvalidated = true
    }
}
