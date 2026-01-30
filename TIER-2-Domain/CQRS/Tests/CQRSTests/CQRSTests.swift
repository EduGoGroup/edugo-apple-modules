import Testing
@testable import CQRS

// MARK: - Test Query Implementation

struct TestQuery: Query {
    typealias Result = String
    let value: String
}

// MARK: - Test Command Implementation

struct TestCommand: Command {
    typealias Result = Int
    let value: Int

    func validate() throws {
        guard value > 0 else {
            throw TestError.invalidValue
        }
    }
}

enum TestError: Error {
    case invalidValue
}

// MARK: - Test Handlers

actor TestQueryHandler: QueryHandler {
    typealias QueryType = TestQuery

    func handle(_ query: TestQuery) async throws -> String {
        return "Result: \(query.value)"
    }
}

actor TestCommandHandler: CommandHandler {
    typealias CommandType = TestCommand

    func handle(_ command: TestCommand) async throws -> CommandResult<Int> {
        try command.validate()
        return .success(
            command.value * 2,
            events: ["ValueDoubledEvent"],
            metadata: ["operation": "multiply"]
        )
    }
}

// MARK: - Tests

@Suite("CQRS Core Tests")
struct CQRSTests {

    @Test("Query protocol works correctly")
    func testQuery() async throws {
        let query = TestQuery(value: "test")
        let handler = TestQueryHandler()

        let result = try await handler.handle(query)
        #expect(result == "Result: test")
    }

    @Test("Command protocol works correctly with validation")
    func testCommandSuccess() async throws {
        let command = TestCommand(value: 5)
        let handler = TestCommandHandler()

        let result = try await handler.handle(command)
        #expect(result.isSuccess == true)
        #expect(result.getValue() == 10)
        #expect(result.events.contains("ValueDoubledEvent"))
        #expect(result.metadata["operation"] == "multiply")
    }

    @Test("Command validation fails for invalid input")
    func testCommandValidationFailure() async throws {
        let command = TestCommand(value: -1)
        let handler = TestCommandHandler()

        await #expect(throws: TestError.self) {
            try await handler.handle(command)
        }
    }

    @Test("CommandResult success creation")
    func testCommandResultSuccess() {
        let result = CommandResult.success(
            42,
            events: ["TestEvent"],
            metadata: ["key": "value"]
        )

        #expect(result.isSuccess == true)
        #expect(result.isFailure == false)
        #expect(result.getValue() == 42)
        #expect(result.events.count == 1)
        #expect(result.metadata["key"] == "value")
    }

    @Test("CommandResult failure creation")
    func testCommandResultFailure() {
        let result = CommandResult<Int>.failure(
            TestError.invalidValue,
            metadata: ["reason": "negative"]
        )

        #expect(result.isFailure == true)
        #expect(result.isSuccess == false)
        #expect(result.getValue() == nil)
        #expect(result.getError() != nil)
    }

    @Test("CommandResult map transformation")
    func testCommandResultMap() {
        let result = CommandResult.success(5, events: ["Event"])
        let mapped = result.map { $0 * 2 }

        #expect(mapped.isSuccess == true)
        #expect(mapped.getValue() == 10)
        #expect(mapped.events.count == 1)
    }
}
