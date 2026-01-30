import Testing
@testable import CQRS

// MARK: - Test Implementations

struct GetUserQuery: Query {
    typealias Result = User
    let userId: String
}

struct CreateUserCommand: Command {
    typealias Result = User
    let username: String
    let email: String

    func validate() throws {
        guard !username.isEmpty else {
            throw ValidationError.emptyUsername
        }
        guard email.contains("@") else {
            throw ValidationError.invalidEmail
        }
    }
}

struct InvalidCommand: Command {
    typealias Result = String

    func validate() throws {
        throw ValidationError.alwaysFails
    }
}

struct User: Sendable, Equatable {
    let id: String
    let username: String
    let email: String
}

enum ValidationError: Error {
    case emptyUsername
    case invalidEmail
    case alwaysFails
}

// MARK: - Test Handlers

actor GetUserQueryHandler: QueryHandler {
    typealias QueryType = GetUserQuery

    func handle(_ query: GetUserQuery) async throws -> User {
        return User(
            id: query.userId,
            username: "John Doe",
            email: "john@example.com"
        )
    }
}

actor CreateUserCommandHandler: CommandHandler {
    typealias CommandType = CreateUserCommand

    func handle(_ command: CreateUserCommand) async throws -> CommandResult<User> {
        try command.validate()

        let user = User(
            id: "new-id",
            username: command.username,
            email: command.email
        )

        return .success(
            user,
            events: ["UserCreatedEvent", "EmailVerificationSentEvent"],
            metadata: ["timestamp": "2024-01-30T12:00:00Z"]
        )
    }
}

actor InvalidCommandHandler: CommandHandler {
    typealias CommandType = InvalidCommand

    func handle(_ command: InvalidCommand) async throws -> CommandResult<String> {
        try command.validate()
        return .success("should not reach here")
    }
}

// MARK: - Tests

@Suite("Mediator Tests")
struct MediatorTests {

    @Test("Mediator dispatches query successfully")
    func testQueryDispatch() async throws {
        let mediator = Mediator(loggingEnabled: false)
        let handler = GetUserQueryHandler()

        try await mediator.registerQueryHandler(handler)

        let query = GetUserQuery(userId: "123")
        let result = try await mediator.send(query)

        #expect(result.id == "123")
        #expect(result.username == "John Doe")
        #expect(result.email == "john@example.com")
    }

    @Test("Mediator throws error when query handler not found")
    func testQueryHandlerNotFound() async throws {
        let mediator = Mediator(loggingEnabled: false)
        let query = GetUserQuery(userId: "123")

        await #expect(throws: MediatorError.self) {
            try await mediator.send(query)
        }
    }

    @Test("Mediator executes command successfully")
    func testCommandExecution() async throws {
        let mediator = Mediator(loggingEnabled: false)
        let handler = CreateUserCommandHandler()

        try await mediator.registerCommandHandler(handler)

        let command = CreateUserCommand(username: "john", email: "john@example.com")
        let result = try await mediator.execute(command)

        #expect(result.isSuccess == true)
        #expect(result.getValue()?.username == "john")
        #expect(result.events.count == 2)
        #expect(result.events.contains("UserCreatedEvent"))
        #expect(result.metadata["timestamp"] != nil)
    }

    @Test("Mediator throws error when command handler not found")
    func testCommandHandlerNotFound() async throws {
        let mediator = Mediator(loggingEnabled: false)
        let command = CreateUserCommand(username: "john", email: "john@example.com")

        await #expect(throws: MediatorError.self) {
            try await mediator.execute(command)
        }
    }

    @Test("Mediator validates command before execution")
    func testCommandValidation() async throws {
        let mediator = Mediator(loggingEnabled: false)
        let handler = CreateUserCommandHandler()

        try await mediator.registerCommandHandler(handler)

        let invalidCommand = CreateUserCommand(username: "", email: "john@example.com")

        await #expect(throws: MediatorError.self) {
            try await mediator.execute(invalidCommand)
        }
    }

    @Test("Mediator prevents duplicate handler registration")
    func testDuplicateRegistration() async throws {
        let mediator = Mediator(loggingEnabled: false)
        let handler1 = GetUserQueryHandler()
        let handler2 = GetUserQueryHandler()

        try await mediator.registerQueryHandler(handler1)

        await #expect(throws: MediatorError.self) {
            try await mediator.registerQueryHandler(handler2)
        }
    }

    @Test("Mediator allows handler replacement")
    func testHandlerReplacement() async throws {
        let mediator = Mediator(loggingEnabled: false)
        let handler1 = GetUserQueryHandler()
        let handler2 = GetUserQueryHandler()

        try await mediator.registerQueryHandler(handler1)
        await mediator.registerOrReplaceQueryHandler(handler2)

        let query = GetUserQuery(userId: "123")
        let result = try await mediator.send(query)

        #expect(result.id == "123")
    }

    @Test("Mediator unregisters handlers correctly")
    func testHandlerUnregistration() async throws {
        let mediator = Mediator(loggingEnabled: false)
        let handler = GetUserQueryHandler()

        try await mediator.registerQueryHandler(handler)
        await mediator.unregisterQueryHandler(for: GetUserQuery.self)

        let query = GetUserQuery(userId: "123")

        await #expect(throws: MediatorError.self) {
            try await mediator.send(query)
        }
    }

    @Test("Mediator tracks handler counts correctly")
    func testHandlerCounts() async throws {
        let mediator = Mediator(loggingEnabled: false)

        #expect(await mediator.queryHandlerCount == 0)
        #expect(await mediator.commandHandlerCount == 0)

        try await mediator.registerQueryHandler(GetUserQueryHandler())
        try await mediator.registerCommandHandler(CreateUserCommandHandler())

        #expect(await mediator.queryHandlerCount == 1)
        #expect(await mediator.commandHandlerCount == 1)

        await mediator.clearAllHandlers()

        #expect(await mediator.queryHandlerCount == 0)
        #expect(await mediator.commandHandlerCount == 0)
    }

    @Test("MediatorRegistry registers and retrieves handlers")
    func testRegistryBasicOperations() async throws {
        let registry = MediatorRegistry()
        let handler = GetUserQueryHandler()

        try await registry.registerQueryHandler(handler)

        // Verify handler can be retrieved (will throw if not found)
        _ = try await registry.getQueryHandler(for: GetUserQuery.self)

        // Verify count
        #expect(await registry.queryHandlerCount == 1)
    }

    @Test("MediatorError descriptions are correct")
    func testErrorDescriptions() {
        let handlerNotFound = MediatorError.handlerNotFound(type: "TestQuery")
        #expect(handlerNotFound.description.contains("Handler not found"))

        let validationError = MediatorError.validationError(message: "Invalid", underlyingError: nil)
        #expect(validationError.description.contains("Validation error"))

        let executionError = MediatorError.executionError(message: "Failed", underlyingError: nil)
        #expect(executionError.description.contains("Execution error"))

        let registrationError = MediatorError.registrationError(message: "Duplicate")
        #expect(registrationError.description.contains("Registration error"))
    }
}
