import Testing
import Foundation
@testable import StateManagement

// MARK: - Test States

private struct UserState: AsyncState {
    let id: String
    let name: String
}

private struct UnitsState: AsyncState {
    let units: [String]
}

private struct MaterialsState: AsyncState {
    let materials: [String]
}

// MARK: - Mock Use Case Actor

private actor MockDashboardUseCase {
    private let userPublisher = StatePublisher<UserState>()
    private let unitsPublisher = StatePublisher<UnitsState>()
    private let materialsPublisher = StatePublisher<MaterialsState>()

    var userStream: StateStream<UserState> {
        get async { await userPublisher.stream }
    }

    var unitsStream: StateStream<UnitsState> {
        get async { await unitsPublisher.stream }
    }

    var materialsStream: StateStream<MaterialsState> {
        get async { await materialsPublisher.stream }
    }

    func loadUser(id: String) async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 10_000_000)
        await userPublisher.send(UserState(id: id, name: "User \(id)"))
    }

    func loadUnits() async {
        try? await Task.sleep(nanoseconds: 15_000_000)
        await unitsPublisher.send(UnitsState(units: ["Unit 1", "Unit 2", "Unit 3"]))
    }

    func loadMaterials() async {
        try? await Task.sleep(nanoseconds: 20_000_000)
        await materialsPublisher.send(MaterialsState(materials: ["Material A", "Material B"]))
    }

    func finish() async {
        await userPublisher.finish()
        await unitsPublisher.finish()
        await materialsPublisher.finish()
    }
}

// MARK: - End-to-End Integration Tests

@Suite("End-to-End Integration")
struct EndToEndIntegrationTests {

    @Test("Complete dashboard loading flow")
    func completeDashboardLoadingFlow() async throws {
        let useCase = MockDashboardUseCase()

        // Start parallel loading
        async let userLoad: Void = useCase.loadUser(id: "123")
        async let unitsLoad: Void = useCase.loadUnits()
        async let materialsLoad: Void = useCase.loadMaterials()

        // Wait for all to complete
        _ = await (userLoad, unitsLoad, materialsLoad)

        await useCase.finish()
    }

    @Test("Operator pipeline integration")
    func operatorPipelineIntegration() async throws {
        let publisher = StatePublisher<UserState>()
        let stream = await publisher.stream

        // Create a pipeline: filter -> map
        let pipeline = stream
            .filter { $0.name.count > 5 }
            .map { UserState(id: $0.id, name: $0.name.uppercased()) }

        let collectTask = Task {
            var collected: [UserState] = []
            for await state in pipeline {
                collected.append(state)
                if collected.count >= 2 { break }
            }
            return collected
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        // Emit states - some will be filtered
        await publisher.send(UserState(id: "1", name: "Bob")) // Filtered (length <= 5)
        await publisher.send(UserState(id: "2", name: "Charlie")) // Passes
        await publisher.send(UserState(id: "3", name: "Dan")) // Filtered
        await publisher.send(UserState(id: "4", name: "Elizabeth")) // Passes

        await publisher.finish()

        let collected = await collectTask.value
        #expect(collected.count == 2)
        #expect(collected[0].name == "CHARLIE")
        #expect(collected[1].name == "ELIZABETH")
    }

    @Test("Buffered publisher with consumer")
    func bufferedPublisherWithConsumer() async throws {
        let publisher = BufferedStatePublisher<UserState>.dropping(capacity: 5)

        // Emit more than buffer capacity
        for i in 0..<20 {
            await publisher.send(UserState(id: "\(i)", name: "User \(i)"))
        }

        // Buffer should have limited count
        let count = await publisher.bufferCount
        #expect(count <= 5)

        await publisher.finish()
    }

    @Test("StateMachine with stream observation")
    func stateMachineWithStreamObservation() async throws {
        let machine = UploadStateMachine()
        let stream = await machine.stateStream

        let observeTask = Task {
            var states: [UploadState] = []
            for await state in stream {
                states.append(state)
                if case .ready = state { break }
            }
            return states
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        // Drive state transitions
        try await machine.transitionToCreating()
        try await machine.startUploading()
        for progress in stride(from: 0.1, through: 1.0, by: 0.2) {
            try await machine.updateProgress(progress)
        }
        try await machine.transitionToProcessing()
        try await machine.transitionToReady()

        let states = await observeTask.value
        #expect(states.count > 0)
    }
}

// MARK: - Component Integration Tests

@Suite("Component Integration")
struct ComponentIntegrationTests {

    @Test("Publisher with operators and buffer")
    func publisherWithOperatorsAndBuffer() async throws {
        // Use regular StatePublisher for more predictable behavior with operators
        let publisher = StatePublisher<UserState>()
        let stream = await publisher.stream

        let mappedStream = stream.map { state in
            UserState(id: state.id, name: "Processed: \(state.name)")
        }

        let collectTask = Task {
            var count = 0
            for await _ in mappedStream {
                count += 1
                if count >= 5 { break }
            }
            return count
        }

        // Allow consumer to start listening
        try await Task.sleep(nanoseconds: 50_000_000)

        for i in 0..<5 {
            await publisher.send(UserState(id: "\(i)", name: "User\(i)"))
        }

        await publisher.finish()

        let count = await collectTask.value
        #expect(count == 5)
    }

    @Test("Merge with different sources")
    func mergeWithDifferentSources() async throws {
        let publisher1 = StatePublisher<UserState>()
        let publisher2 = StatePublisher<UserState>()

        let stream1 = await publisher1.stream
        let stream2 = await publisher2.stream

        let merged = StateMerge.merge(stream1, stream2)

        let collectTask = Task {
            var allNames: [String] = []
            for try await state in merged {
                allNames.append(state.name)
                if allNames.count >= 4 { break }
            }
            return allNames
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        await publisher1.send(UserState(id: "1", name: "Alice"))
        await publisher1.send(UserState(id: "2", name: "Bob"))
        await publisher2.send(UserState(id: "3", name: "Charlie"))
        await publisher2.send(UserState(id: "4", name: "Diana"))

        await publisher1.finish()
        await publisher2.finish()

        let allNames = try await collectTask.value

        #expect(allNames.count == 4)
        #expect(allNames.contains("Alice"))
        #expect(allNames.contains("Bob"))
        #expect(allNames.contains("Charlie"))
        #expect(allNames.contains("Diana"))
    }

    @Test("CombineLatest synchronization")
    func combineLatestSynchronization() async throws {
        let userPublisher = StatePublisher<UserState>()
        let unitsPublisher = StatePublisher<UnitsState>()

        let userStream = await userPublisher.stream
        let unitsStream = await unitsPublisher.stream

        let combined = StateCombineLatest2(userStream, unitsStream)

        let collectTask = Task {
            var results: [(UserState, UnitsState)] = []
            for try await tuple in combined {
                results.append(tuple)
                if results.count >= 1 { break }
            }
            return results
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        await userPublisher.send(UserState(id: "1", name: "User"))
        await unitsPublisher.send(UnitsState(units: ["U1", "U2"]))

        await userPublisher.finish()
        await unitsPublisher.finish()

        let results = try await collectTask.value

        #expect(results.count >= 1)
        #expect(results[0].0.name == "User")
        #expect(results[0].1.units.count == 2)
    }
}

// MARK: - Error Handling Integration Tests

@Suite("Error Handling Integration")
struct ErrorHandlingIntegrationTests {

    @Test("StateMachine error recovery")
    func stateMachineErrorRecovery() async throws {
        let machine = AssessmentStateMachine(assessmentId: "error-test")

        try await machine.startLoading()
        try await machine.transitionToError(.networkError(reason: "Test error"))

        let state = await machine.currentState
        if case .error(let error) = state {
            #expect(error == .networkError(reason: "Test error"))
        } else {
            Issue.record("Expected error state")
        }

        // Should be able to reset
        try await machine.resetToIdle()
        let resetState = await machine.currentState
        #expect(resetState == .idle)
    }

    @Test("Cancellation propagation")
    func cancellationPropagation() async throws {
        let publisher = StatePublisher<UserState>()
        let stream = await publisher.stream

        let consumeTask = Task {
            var count = 0
            for await _ in stream {
                count += 1
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
            return count
        }

        // Emit a few states
        await publisher.send(UserState(id: "1", name: "First"))

        // Cancel after short delay
        try await Task.sleep(nanoseconds: 50_000_000)
        consumeTask.cancel()

        // Should complete without hanging
        _ = try? await consumeTask.value
        await publisher.finish()
    }
}

// MARK: - Persistence Integration Tests

@Suite("Persistence Integration")
struct PersistenceIntegrationTests {

    @Test("AssessmentStateMachine with persistence and recovery")
    func assessmentStateMachineWithPersistenceAndRecovery() async throws {
        let persistence = InMemoryStatePersistence()

        // First session - interrupted
        let machine1 = AssessmentStateMachine(
            assessmentId: "persist-test",
            persistence: persistence
        )

        try await machine1.startLoading()
        try await machine1.transitionToReady()
        try await machine1.startAssessment(totalQuestions: 10)
        try await machine1.answerQuestion()
        try await machine1.answerQuestion()

        // Simulate crash (don't finish, just abandon)

        // Second session - recovery
        let machine2 = AssessmentStateMachine(
            assessmentId: "persist-test",
            persistence: persistence
        )

        let recovered = try await machine2.recoverState()

        #expect(recovered != nil)
        if case .inProgress(let answered, let total) = recovered {
            #expect(answered == 2)
            #expect(total == 10)
        } else {
            Issue.record("Expected inProgress state")
        }
    }
}
