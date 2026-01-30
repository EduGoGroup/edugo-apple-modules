import Testing
@testable import StateManagement

@Suite("UploadStateMachine")
struct UploadStateMachineTests {

    // MARK: - Initial State Tests

    @Test("Initial state is validating")
    func initialStateIsValidating() async {
        let machine = UploadStateMachine()
        let state = await machine.currentState
        #expect(state == .validating)
    }

    // MARK: - Happy Path Tests

    @Test("Complete upload flow succeeds")
    func completeUploadFlowSucceeds() async throws {
        let machine = UploadStateMachine()

        try await machine.startValidation()
        #expect(await machine.currentState == .validating)

        try await machine.transitionToCreating()
        #expect(await machine.currentState == .creating)

        try await machine.startUploading()
        #expect(await machine.currentState == .uploading(progress: 0.0))

        try await machine.updateProgress(0.5)

        try await machine.updateProgress(1.0)

        try await machine.transitionToProcessing()
        #expect(await machine.currentState == .processing)

        try await machine.transitionToReady()
        #expect(await machine.currentState == .ready)
    }

    // MARK: - Invalid Transition Tests

    @Test("Cannot transition from validating to processing")
    func cannotTransitionFromValidatingToProcessing() async {
        let machine = UploadStateMachine()

        await #expect(throws: InvalidTransitionError.self) {
            try await machine.transitionToProcessing()
        }
    }

    @Test("Cannot transition from validating to ready")
    func cannotTransitionFromValidatingToReady() async {
        let machine = UploadStateMachine()

        await #expect(throws: InvalidTransitionError.self) {
            try await machine.transitionToReady()
        }
    }

    @Test("Cannot transition from ready to validating")
    func cannotTransitionFromReadyToValidating() async throws {
        let machine = UploadStateMachine()

        // Complete full flow
        try await machine.startValidation()
        try await machine.transitionToCreating()
        try await machine.startUploading()
        try await machine.transitionToProcessing()
        try await machine.transitionToReady()

        await #expect(throws: InvalidTransitionError.self) {
            try await machine.startValidation()
        }
    }

    @Test("Cannot transition from creating to processing")
    func cannotTransitionFromCreatingToProcessing() async throws {
        let machine = UploadStateMachine()

        try await machine.transitionToCreating()

        await #expect(throws: InvalidTransitionError.self) {
            try await machine.transitionToProcessing()
        }
    }

    // MARK: - Error Transition Tests

    @Test("Can transition to error from any active state")
    func canTransitionToErrorFromAnyActiveState() async throws {
        // From validating
        let machine1 = UploadStateMachine()
        try await machine1.transitionToError(.validationFailed(reason: "Too large"))
        #expect(await machine1.currentState == .error(.validationFailed(reason: "Too large")))

        // From creating
        let machine2 = UploadStateMachine()
        try await machine2.transitionToCreating()
        try await machine2.transitionToError(.sessionCreationFailed(reason: "Server error"))
        #expect(await machine2.currentState == .error(.sessionCreationFailed(reason: "Server error")))

        // From uploading
        let machine3 = UploadStateMachine()
        try await machine3.transitionToCreating()
        try await machine3.startUploading()
        try await machine3.transitionToError(.networkError(reason: "Timeout"))
        #expect(await machine3.currentState == .error(.networkError(reason: "Timeout")))

        // From processing
        let machine4 = UploadStateMachine()
        try await machine4.transitionToCreating()
        try await machine4.startUploading()
        try await machine4.transitionToProcessing()
        try await machine4.transitionToError(.processingFailed(reason: "Invalid format"))
        #expect(await machine4.currentState == .error(.processingFailed(reason: "Invalid format")))
    }

    @Test("Cannot transition to error from ready state")
    func cannotTransitionToErrorFromReadyState() async throws {
        let machine = UploadStateMachine()

        try await machine.transitionToCreating()
        try await machine.startUploading()
        try await machine.transitionToProcessing()
        try await machine.transitionToReady()

        await #expect(throws: InvalidTransitionError.self) {
            try await machine.transitionToError(.unknown(reason: "Test"))
        }
    }

    // MARK: - Retry Tests

    @Test("Can retry from error state")
    func canRetryFromErrorState() async throws {
        let machine = UploadStateMachine()

        try await machine.transitionToError(.networkError(reason: "Timeout"))
        #expect(await machine.currentState == .error(.networkError(reason: "Timeout")))

        // Retry
        try await machine.startValidation()
        #expect(await machine.currentState == .validating)

        // Should be able to continue normal flow
        try await machine.transitionToCreating()
        #expect(await machine.currentState == .creating)
    }

    // MARK: - Cancel Tests

    @Test("Cancel transitions to error with cancelled")
    func cancelTransitionsToErrorWithCancelled() async throws {
        let machine = UploadStateMachine()

        try await machine.transitionToCreating()
        try await machine.startUploading()
        try await machine.updateProgress(0.5)

        try await machine.cancel()

        let state = await machine.currentState
        #expect(state == .error(.cancelled))
    }

    // MARK: - Progress Tests

    @Test("Progress updates are emitted")
    func progressUpdatesAreEmitted() async throws {
        let machine = UploadStateMachine()

        try await machine.transitionToCreating()
        try await machine.startUploading()

        try await machine.updateProgress(0.25)
        try await machine.updateProgress(0.50)
        try await machine.updateProgress(0.75)
        try await machine.updateProgress(1.0)

        // Final state should be uploading at 100%
        let state = await machine.currentState
        #expect(state == .uploading(progress: 1.0))
    }

    @Test("Progress decrements are ignored")
    func progressDecrementsAreIgnored() async throws {
        let machine = UploadStateMachine()

        try await machine.transitionToCreating()
        try await machine.startUploading()

        try await machine.updateProgress(0.5)
        try await machine.updateProgress(0.3) // Should be ignored

        let state = await machine.currentState
        if case .uploading(let progress) = state {
            #expect(progress >= 0.5)
        } else {
            Issue.record("Expected uploading state")
        }
    }

    @Test("Progress is clamped to valid range")
    func progressIsClampedToValidRange() async throws {
        let machine = UploadStateMachine()

        try await machine.transitionToCreating()
        try await machine.startUploading()

        try await machine.updateProgress(1.5) // Should be clamped to 1.0

        let state = await machine.currentState
        if case .uploading(let progress) = state {
            #expect(progress == 1.0)
        } else {
            Issue.record("Expected uploading state")
        }
    }

    @Test("Progress below zero is clamped")
    func progressBelowZeroIsClamped() async throws {
        let machine = UploadStateMachine()

        try await machine.transitionToCreating()
        try await machine.startUploading()

        try await machine.updateProgress(-0.5) // Should be clamped to 0.0 and ignored (not > lastEmitted)

        let state = await machine.currentState
        if case .uploading(let progress) = state {
            #expect(progress == 0.0)
        } else {
            Issue.record("Expected uploading state")
        }
    }

    // MARK: - Transition Validation Tests

    @Test("isValidTransition returns correct values")
    func isValidTransitionReturnsCorrectValues() async {
        let machine = UploadStateMachine()

        // Valid transitions
        #expect(machine.isValidTransition(from: .validating, to: .creating) == true)
        #expect(machine.isValidTransition(from: .validating, to: .error(.cancelled)) == true)
        #expect(machine.isValidTransition(from: .creating, to: .uploading(progress: 0.0)) == true)
        #expect(machine.isValidTransition(from: .uploading(progress: 0.5), to: .uploading(progress: 0.75)) == true)
        #expect(machine.isValidTransition(from: .uploading(progress: 1.0), to: .processing) == true)
        #expect(machine.isValidTransition(from: .processing, to: .ready) == true)
        #expect(machine.isValidTransition(from: .error(.cancelled), to: .validating) == true)

        // Invalid transitions
        #expect(machine.isValidTransition(from: .validating, to: .ready) == false)
        #expect(machine.isValidTransition(from: .validating, to: .processing) == false)
        #expect(machine.isValidTransition(from: .ready, to: .validating) == false)
        #expect(machine.isValidTransition(from: .ready, to: .error(.cancelled)) == false)
        #expect(machine.isValidTransition(from: .creating, to: .processing) == false)
    }
}

// MARK: - State Stream Tests

@Suite("UploadStateMachine Stream")
struct UploadStateMachineStreamTests {

    @Test("State stream emits all transitions")
    func stateStreamEmitsAllTransitions() async throws {
        let machine = UploadStateMachine()
        let stream = await machine.stateStream

        // Drive transitions
        try await machine.startValidation()
        try await machine.transitionToCreating()
        try await machine.startUploading()
        try await machine.updateProgress(0.5)
        try await machine.updateProgress(1.0)
        try await machine.transitionToProcessing()
        try await machine.transitionToReady()

        // Collect emitted states
        var states: [UploadState] = []
        for await state in stream {
            states.append(state)
        }

        // Verify key states were emitted
        #expect(states.contains(.validating))
        #expect(states.contains(.creating))
        #expect(states.contains(.processing))
        #expect(states.contains(.ready))
    }
}

// MARK: - Concurrency Tests

@Suite("UploadStateMachine Concurrency")
struct UploadStateMachineConcurrencyTests {

    @Test("Concurrent progress updates are thread-safe")
    func concurrentProgressUpdatesAreThreadSafe() async throws {
        let machine = UploadStateMachine()

        try await machine.transitionToCreating()
        try await machine.startUploading()

        // Simulate concurrent progress updates
        await withTaskGroup(of: Void.self) { group in
            for i in 1...100 {
                group.addTask {
                    let progress = Double(i) / 100.0
                    try? await machine.updateProgress(progress)
                }
            }
        }

        // Should complete without crashing
        let state = await machine.currentState
        if case .uploading = state {
            // Success - still in uploading state
        } else {
            Issue.record("Expected uploading state")
        }
    }

    @Test("Concurrent state reads are safe")
    func concurrentStateReadsAreSafe() async throws {
        let machine = UploadStateMachine()

        try await machine.transitionToCreating()

        let results = await withTaskGroup(of: UploadState.self, returning: [UploadState].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    await machine.currentState
                }
            }

            var collected: [UploadState] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        #expect(results.count == 50)
        #expect(results.allSatisfy { $0 == .creating })
    }
}

// MARK: - InvalidTransitionError Tests

@Suite("InvalidTransitionError")
struct InvalidTransitionErrorTests {

    @Test("InvalidTransitionError stores from and to states")
    func invalidTransitionErrorStoresStates() {
        let error = InvalidTransitionError(from: .validating, to: .ready)
        #expect(error.from == .validating)
        #expect(error.to == .ready)
    }

    @Test("InvalidTransitionError description is human-readable")
    func invalidTransitionErrorDescriptionIsReadable() {
        let error = InvalidTransitionError(from: .validating, to: .ready)
        #expect(error.description.contains("Invalid transition"))
    }

    @Test("InvalidTransitionError is Equatable")
    func invalidTransitionErrorIsEquatable() {
        let error1 = InvalidTransitionError(from: .validating, to: .ready)
        let error2 = InvalidTransitionError(from: .validating, to: .ready)
        let error3 = InvalidTransitionError(from: .creating, to: .ready)

        #expect(error1 == error2)
        #expect(error1 != error3)
    }
}
