import Testing
import Foundation
@testable import UseCases

// MARK: - Test Fixtures

/// Request de prueba para UseCase genérico
struct TestInput: Sendable {
    let id: String
    let value: Int
}

/// Response de prueba para UseCase genérico
struct TestOutput: Sendable, Equatable {
    let result: String
}

// MARK: - UseCase Tests

@Suite("UseCase Protocol Tests")
struct UseCaseTests {

    /// Actor de prueba que implementa UseCase
    actor MockUseCase: UseCase {
        typealias Input = TestInput
        typealias Output = TestOutput

        var executionCount = 0
        var shouldThrow = false

        func execute(input: TestInput) async throws -> TestOutput {
            executionCount += 1
            if shouldThrow {
                throw UseCaseError.executionFailed(reason: "Test error")
            }
            return TestOutput(result: "Processed: \(input.id)")
        }
    }

    @Test("execute returns expected output")
    func executeReturnsOutput() async throws {
        let useCase = MockUseCase()
        let input = TestInput(id: "test-123", value: 42)

        let output = try await useCase.execute(input: input)

        #expect(output.result == "Processed: test-123")
    }

    @Test("execute increments execution count")
    func executeIncrementsCount() async throws {
        let useCase = MockUseCase()
        let input = TestInput(id: "test", value: 1)

        _ = try await useCase.execute(input: input)
        _ = try await useCase.execute(input: input)
        let count = await useCase.executionCount

        #expect(count == 2)
    }

    @Test("execute throws UseCaseError when configured")
    func executeThrowsError() async {
        let useCase = MockUseCase()
        await useCase.setShouldThrow(true)
        let input = TestInput(id: "test", value: 1)

        await #expect(throws: UseCaseError.self) {
            try await useCase.execute(input: input)
        }
    }

    @Test("executeAsResult returns success on success")
    func executeAsResultSuccess() async throws {
        let useCase = MockUseCase()
        let input = TestInput(id: "test-456", value: 10)

        let result = await useCase.executeAsResult(input: input)

        switch result {
        case .success(let output):
            #expect(output.result == "Processed: test-456")
        case .failure:
            Issue.record("Expected success but got failure")
        }
    }

    @Test("executeAsResult returns failure on error")
    func executeAsResultFailure() async {
        let useCase = MockUseCase()
        await useCase.setShouldThrow(true)
        let input = TestInput(id: "test", value: 1)

        let result = await useCase.executeAsResult(input: input)

        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error is UseCaseError)
        }
    }
}

// MARK: - MockUseCase Helper

extension UseCaseTests.MockUseCase {
    func setShouldThrow(_ value: Bool) {
        shouldThrow = value
    }
}

// MARK: - SimpleUseCase Tests

@Suite("SimpleUseCase Protocol Tests")
struct SimpleUseCaseTests {

    /// Actor de prueba que implementa SimpleUseCase
    actor MockSimpleUseCase: SimpleUseCase {
        typealias Output = Int

        var returnValue = 42
        var shouldThrow = false

        func execute() async throws -> Int {
            if shouldThrow {
                throw UseCaseError.preconditionFailed(
                    description: "Test precondition"
                )
            }
            return returnValue
        }

        func setReturnValue(_ value: Int) {
            returnValue = value
        }

        func setShouldThrow(_ value: Bool) {
            shouldThrow = value
        }
    }

    @Test("execute returns expected value")
    func executeReturnsValue() async throws {
        let useCase = MockSimpleUseCase()

        let result = try await useCase.execute()

        #expect(result == 42)
    }

    @Test("execute with custom return value")
    func executeWithCustomValue() async throws {
        let useCase = MockSimpleUseCase()
        await useCase.setReturnValue(100)

        let result = try await useCase.execute()

        #expect(result == 100)
    }

    @Test("execute throws error when configured")
    func executeThrowsError() async {
        let useCase = MockSimpleUseCase()
        await useCase.setShouldThrow(true)

        await #expect(throws: UseCaseError.self) {
            try await useCase.execute()
        }
    }

    @Test("executeAsResult returns success")
    func executeAsResultSuccess() async {
        let useCase = MockSimpleUseCase()

        let result = await useCase.executeAsResult()

        switch result {
        case .success(let value):
            #expect(value == 42)
        case .failure:
            Issue.record("Expected success")
        }
    }

    @Test("execute(input:) bridge works with Void input")
    func executeInputBridge() async throws {
        let useCase = MockSimpleUseCase()

        let result = try await useCase.execute(input: ())

        #expect(result == 42)
    }
}

// MARK: - CommandUseCase Tests

@Suite("CommandUseCase Protocol Tests")
struct CommandUseCaseTests {

    /// Request de prueba para CommandUseCase
    struct DeleteRequest: Sendable {
        let resourceId: String
    }

    /// Actor de prueba que implementa CommandUseCase
    actor MockCommandUseCase: CommandUseCase {
        typealias Input = DeleteRequest

        var executedIds: [String] = []
        var shouldThrow = false

        func execute(input: DeleteRequest) async throws {
            if shouldThrow {
                throw UseCaseError.unauthorized(action: "Delete")
            }
            executedIds.append(input.resourceId)
        }

        func setShouldThrow(_ value: Bool) {
            shouldThrow = value
        }

        func getExecutedIds() -> [String] {
            executedIds
        }
    }

    @Test("execute processes input correctly")
    func executeProcessesInput() async throws {
        let useCase = MockCommandUseCase()
        let request = DeleteRequest(resourceId: "doc-123")

        try await useCase.execute(input: request)

        let ids = await useCase.getExecutedIds()
        #expect(ids == ["doc-123"])
    }

    @Test("execute throws error when configured")
    func executeThrowsError() async {
        let useCase = MockCommandUseCase()
        await useCase.setShouldThrow(true)
        let request = DeleteRequest(resourceId: "doc-456")

        await #expect(throws: UseCaseError.self) {
            try await useCase.execute(input: request)
        }
    }

    @Test("executeAsResult returns success")
    func executeAsResultSuccess() async {
        let useCase = MockCommandUseCase()
        let request = DeleteRequest(resourceId: "doc-789")

        let result = await useCase.executeAsResult(input: request)

        switch result {
        case .success:
            let ids = await useCase.getExecutedIds()
            #expect(ids.contains("doc-789"))
        case .failure:
            Issue.record("Expected success")
        }
    }

    @Test("executeAsResult returns failure on error")
    func executeAsResultFailure() async {
        let useCase = MockCommandUseCase()
        await useCase.setShouldThrow(true)
        let request = DeleteRequest(resourceId: "doc-000")

        let result = await useCase.executeAsResult(input: request)

        switch result {
        case .success:
            Issue.record("Expected failure")
        case .failure(let error):
            #expect(error is UseCaseError)
        }
    }

    @Test("multiple executions accumulate")
    func multipleExecutions() async throws {
        let useCase = MockCommandUseCase()

        try await useCase.execute(input: DeleteRequest(resourceId: "a"))
        try await useCase.execute(input: DeleteRequest(resourceId: "b"))
        try await useCase.execute(input: DeleteRequest(resourceId: "c"))

        let ids = await useCase.getExecutedIds()
        #expect(ids == ["a", "b", "c"])
    }
}

// MARK: - UseCaseError Integration Tests

@Suite("UseCaseError Integration Tests")
struct UseCaseErrorIntegrationTests {

    @Test("UseCaseError.preconditionFailed has correct description")
    func preconditionFailedDescription() {
        let error = UseCaseError.preconditionFailed(
            description: "El estudiante debe estar activo"
        )

        #expect(error.errorDescription?.contains("Precondición") == true)
        #expect(error.errorDescription?.contains("El estudiante") == true)
    }

    @Test("UseCaseError.unauthorized has correct description")
    func unauthorizedDescription() {
        let error = UseCaseError.unauthorized(action: "Eliminar documentos")

        #expect(error.errorDescription?.contains("No autorizado") == true)
        #expect(error.errorDescription?.contains("Eliminar") == true)
    }

    @Test("UseCaseError.timeout has correct description")
    func timeoutDescription() {
        let error = UseCaseError.timeout

        #expect(error.errorDescription?.contains("tiempo límite") == true)
    }
}
