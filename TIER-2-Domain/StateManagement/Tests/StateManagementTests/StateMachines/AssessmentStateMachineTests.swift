import Testing
import Foundation
@testable import StateManagement

@Suite("AssessmentStateMachine")
struct AssessmentStateMachineTests {

    // MARK: - Initial State Tests

    @Test("Initial state is idle")
    func initialStateIsIdle() async {
        let machine = AssessmentStateMachine(assessmentId: "test_123")
        let state = await machine.currentState
        #expect(state == .idle)
    }

    // MARK: - Happy Path Tests

    @Test("Complete assessment flow succeeds")
    func completeAssessmentFlowSucceeds() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()
        #expect(await machine.currentState == .loading)

        try await machine.transitionToReady()
        #expect(await machine.currentState == .ready)

        try await machine.startAssessment(totalQuestions: 10)
        #expect(await machine.currentState == .inProgress(answeredCount: 0, totalQuestions: 10))

        try await machine.answerQuestion()
        #expect(await machine.currentState == .inProgress(answeredCount: 1, totalQuestions: 10))

        try await machine.answerQuestion()
        try await machine.answerQuestion()
        #expect(await machine.currentState == .inProgress(answeredCount: 3, totalQuestions: 10))

        try await machine.submit()
        #expect(await machine.currentState == .submitting)

        try await machine.complete(score: 0.85)
        #expect(await machine.currentState == .completed(score: 0.85))
    }

    // MARK: - Invalid Transition Tests

    @Test("Cannot transition from idle to ready")
    func cannotTransitionFromIdleToReady() async {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        await #expect(throws: AssessmentTransitionError.self) {
            try await machine.transitionToReady()
        }
    }

    @Test("Cannot transition from idle to inProgress")
    func cannotTransitionFromIdleToInProgress() async {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        await #expect(throws: AssessmentTransitionError.self) {
            try await machine.startAssessment(totalQuestions: 10)
        }
    }

    @Test("Cannot answer question when not in progress")
    func cannotAnswerQuestionWhenNotInProgress() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()

        await #expect(throws: AssessmentTransitionError.self) {
            try await machine.answerQuestion()
        }
    }

    @Test("Cannot submit when not in progress")
    func cannotSubmitWhenNotInProgress() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()
        try await machine.transitionToReady()

        await #expect(throws: AssessmentTransitionError.self) {
            try await machine.submit()
        }
    }

    @Test("Cannot complete when not submitting")
    func cannotCompleteWhenNotSubmitting() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 5)

        await #expect(throws: AssessmentTransitionError.self) {
            try await machine.complete(score: 0.9)
        }
    }

    // MARK: - Error Transition Tests

    @Test("Can transition to error from any active state")
    func canTransitionToErrorFromAnyActiveState() async throws {
        // From idle
        let machine1 = AssessmentStateMachine(assessmentId: "test_1")
        try await machine1.transitionToError(.loadingFailed(reason: "Test"))
        #expect(await machine1.currentState == .error(.loadingFailed(reason: "Test")))

        // From loading
        let machine2 = AssessmentStateMachine(assessmentId: "test_2")
        try await machine2.startLoading()
        try await machine2.transitionToError(.networkError(reason: "Timeout"))
        #expect(await machine2.currentState == .error(.networkError(reason: "Timeout")))

        // From ready
        let machine3 = AssessmentStateMachine(assessmentId: "test_3")
        try await machine3.startLoading()
        try await machine3.transitionToReady()
        try await machine3.transitionToError(.sessionExpired)
        #expect(await machine3.currentState == .error(.sessionExpired))

        // From inProgress
        let machine4 = AssessmentStateMachine(assessmentId: "test_4")
        try await machine4.startLoading()
        try await machine4.transitionToReady()
        try await machine4.startAssessment(totalQuestions: 10)
        try await machine4.transitionToError(.timeout)
        #expect(await machine4.currentState == .error(.timeout))

        // From submitting
        let machine5 = AssessmentStateMachine(assessmentId: "test_5")
        try await machine5.startLoading()
        try await machine5.transitionToReady()
        try await machine5.startAssessment(totalQuestions: 5)
        try await machine5.submit()
        try await machine5.transitionToError(.submissionFailed(reason: "Server error"))
        #expect(await machine5.currentState == .error(.submissionFailed(reason: "Server error")))
    }

    @Test("Cannot transition to error from completed state")
    func cannotTransitionToErrorFromCompletedState() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 5)
        try await machine.submit()
        try await machine.complete(score: 0.9)

        await #expect(throws: AssessmentTransitionError.self) {
            try await machine.transitionToError(.unknown(reason: "Test"))
        }
    }

    // MARK: - Reset Tests

    @Test("Can reset to idle from error state")
    func canResetToIdleFromErrorState() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.transitionToError(.timeout)
        #expect(await machine.currentState == .error(.timeout))

        try await machine.resetToIdle()
        #expect(await machine.currentState == .idle)

        // Should be able to start new assessment
        try await machine.startLoading()
        #expect(await machine.currentState == .loading)
    }

    @Test("Cannot reset to idle from active states")
    func cannotResetToIdleFromActiveStates() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()

        await #expect(throws: AssessmentTransitionError.self) {
            try await machine.resetToIdle()
        }
    }

    // MARK: - Cancel Tests

    @Test("Cancel transitions to error with cancelled")
    func cancelTransitionsToErrorWithCancelled() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 10)
        try await machine.answerQuestion()

        try await machine.cancel()

        let state = await machine.currentState
        #expect(state == .error(.cancelled))
    }

    // MARK: - Progress Update Tests

    @Test("UpdateAnsweredCount updates correctly")
    func updateAnsweredCountUpdatesCorrectly() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 10)

        try await machine.updateAnsweredCount(5)
        #expect(await machine.currentState == .inProgress(answeredCount: 5, totalQuestions: 10))

        try await machine.updateAnsweredCount(8)
        #expect(await machine.currentState == .inProgress(answeredCount: 8, totalQuestions: 10))
    }

    @Test("UpdateAnsweredCount clamps to valid range")
    func updateAnsweredCountClampsToValidRange() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 10)

        // Clamp to max
        try await machine.updateAnsweredCount(15)
        #expect(await machine.currentState == .inProgress(answeredCount: 10, totalQuestions: 10))

        // Clamp to min
        try await machine.updateAnsweredCount(-5)
        #expect(await machine.currentState == .inProgress(answeredCount: 0, totalQuestions: 10))
    }

    @Test("AnswerQuestion does not exceed total")
    func answerQuestionDoesNotExceedTotal() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 3)

        try await machine.answerQuestion() // 1
        try await machine.answerQuestion() // 2
        try await machine.answerQuestion() // 3
        try await machine.answerQuestion() // Should stay at 3

        #expect(await machine.currentState == .inProgress(answeredCount: 3, totalQuestions: 3))
    }

    // MARK: - Score Clamping Tests

    @Test("Score is clamped to valid range")
    func scoreIsClampedToValidRange() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 5)
        try await machine.submit()

        try await machine.complete(score: 1.5) // Should clamp to 1.0

        let state = await machine.currentState
        if case .completed(let score) = state {
            #expect(score == 1.0)
        } else {
            Issue.record("Expected completed state")
        }
    }

    // MARK: - Transition Validation Tests

    @Test("isValidTransition returns correct values")
    func isValidTransitionReturnsCorrectValues() async {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        // Valid transitions
        #expect(machine.isValidTransition(from: .idle, to: .loading) == true)
        #expect(machine.isValidTransition(from: .loading, to: .ready) == true)
        #expect(machine.isValidTransition(from: .ready, to: .inProgress(answeredCount: 0, totalQuestions: 10)) == true)
        #expect(machine.isValidTransition(from: .inProgress(answeredCount: 5, totalQuestions: 10), to: .submitting) == true)
        #expect(machine.isValidTransition(from: .submitting, to: .completed(score: 0.9)) == true)
        #expect(machine.isValidTransition(from: .error(.timeout), to: .idle) == true)

        // Invalid transitions
        #expect(machine.isValidTransition(from: .idle, to: .ready) == false)
        #expect(machine.isValidTransition(from: .idle, to: .completed(score: 0.9)) == false)
        #expect(machine.isValidTransition(from: .completed(score: 0.9), to: .idle) == false)
        #expect(machine.isValidTransition(from: .ready, to: .submitting) == false)
    }
}

// MARK: - Persistence Tests

@Suite("AssessmentStateMachine Persistence")
struct AssessmentStateMachinePersistenceTests {

    @Test("State is persisted during inProgress")
    func stateIsPersistedDuringInProgress() async throws {
        let persistence = InMemoryStatePersistence()
        let machine = AssessmentStateMachine(
            assessmentId: "test_123",
            persistence: persistence
        )

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 10)
        try await machine.answerQuestion()

        // Check that state was persisted
        let exists = await persistence.exists(forKey: "assessment_test_123")
        #expect(exists == true)
    }

    @Test("Can recover from inProgress state")
    func canRecoverFromInProgressState() async throws {
        let persistence = InMemoryStatePersistence()

        // First machine: start assessment
        let machine1 = AssessmentStateMachine(
            assessmentId: "test_123",
            persistence: persistence
        )
        try await machine1.startLoading()
        try await machine1.transitionToReady()
        try await machine1.startAssessment(totalQuestions: 10)
        try await machine1.updateAnsweredCount(5)

        // Second machine: recover
        let machine2 = AssessmentStateMachine(
            assessmentId: "test_123",
            persistence: persistence
        )

        let recovered = try await machine2.recoverState()
        #expect(recovered == .inProgress(answeredCount: 5, totalQuestions: 10))
        #expect(await machine2.currentState == .inProgress(answeredCount: 5, totalQuestions: 10))
    }

    @Test("Can recover from ready state")
    func canRecoverFromReadyState() async throws {
        let persistence = InMemoryStatePersistence()

        // First machine: get to ready
        let machine1 = AssessmentStateMachine(
            assessmentId: "test_123",
            persistence: persistence
        )
        try await machine1.startLoading()
        try await machine1.transitionToReady()

        // Second machine: recover
        let machine2 = AssessmentStateMachine(
            assessmentId: "test_123",
            persistence: persistence
        )

        let recovered = try await machine2.recoverState()
        #expect(recovered == .ready)
    }

    @Test("Does not recover from idle state")
    func doesNotRecoverFromIdleState() async throws {
        let persistence = InMemoryStatePersistence()

        // Manually persist idle state
        try await persistence.save(AssessmentState.idle, forKey: "assessment_test_123")

        let machine = AssessmentStateMachine(
            assessmentId: "test_123",
            persistence: persistence
        )

        let recovered = try await machine.recoverState()
        #expect(recovered == nil)
    }

    @Test("Persisted state is cleared on completion")
    func persistedStateIsClearedOnCompletion() async throws {
        let persistence = InMemoryStatePersistence()
        let machine = AssessmentStateMachine(
            assessmentId: "test_123",
            persistence: persistence
        )

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 5)

        // Verify state is persisted
        #expect(await persistence.exists(forKey: "assessment_test_123") == true)

        try await machine.submit()
        try await machine.complete(score: 0.9)

        // Verify state is cleared
        #expect(await persistence.exists(forKey: "assessment_test_123") == false)
    }

    @Test("Persisted state is cleared on reset")
    func persistedStateIsClearedOnReset() async throws {
        let persistence = InMemoryStatePersistence()
        let machine = AssessmentStateMachine(
            assessmentId: "test_123",
            persistence: persistence
        )

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 5)

        // Transition to error and reset
        try await machine.transitionToError(.timeout)
        try await machine.resetToIdle()

        // Verify state is cleared
        #expect(await persistence.exists(forKey: "assessment_test_123") == false)
    }
}

// MARK: - Timeout Tests

@Suite("AssessmentStateMachine Timeout")
struct AssessmentStateMachineTimeoutTests {

    @Test("HasTimedOut returns false initially")
    func hasTimedOutReturnsFalseInitially() async throws {
        let machine = AssessmentStateMachine(
            assessmentId: "test_123",
            timeoutDuration: 60 // 1 minute
        )

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 10)

        #expect(await machine.hasTimedOut() == false)
    }

    @Test("RemainingTime returns correct value")
    func remainingTimeReturnsCorrectValue() async throws {
        let machine = AssessmentStateMachine(
            assessmentId: "test_123",
            timeoutDuration: 60
        )

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 10)

        let remaining = await machine.remainingTime()
        #expect(remaining != nil)
        #expect(remaining! > 55 && remaining! <= 60)
    }

    @Test("RemainingTime returns nil when not in progress")
    func remainingTimeReturnsNilWhenNotInProgress() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        let remaining = await machine.remainingTime()
        #expect(remaining == nil)
    }
}

// MARK: - Concurrency Tests

@Suite("AssessmentStateMachine Concurrency")
struct AssessmentStateMachineConcurrencyTests {

    @Test("Concurrent answer updates are thread-safe")
    func concurrentAnswerUpdatesAreThreadSafe() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 100)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    try? await machine.answerQuestion()
                }
            }
        }

        // Should have answered some questions
        let state = await machine.currentState
        if case .inProgress(let answered, _) = state {
            #expect(answered > 0 && answered <= 50)
        } else {
            Issue.record("Expected inProgress state")
        }
    }

    @Test("Concurrent state reads are safe")
    func concurrentStateReadsAreSafe() async throws {
        let machine = AssessmentStateMachine(assessmentId: "test_123")

        try await machine.startLoading()
        try await machine.transitionToReady()

        let results = await withTaskGroup(of: AssessmentState.self, returning: [AssessmentState].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    await machine.currentState
                }
            }

            var collected: [AssessmentState] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        #expect(results.count == 50)
        #expect(results.allSatisfy { $0 == .ready })
    }
}

// MARK: - AssessmentTransitionError Tests

@Suite("AssessmentTransitionError")
struct AssessmentTransitionErrorTests {

    @Test("AssessmentTransitionError stores from and to states")
    func assessmentTransitionErrorStoresStates() {
        let error = AssessmentTransitionError(from: .idle, to: .ready)
        #expect(error.from == .idle)
        #expect(error.to == .ready)
    }

    @Test("AssessmentTransitionError description is human-readable")
    func assessmentTransitionErrorDescriptionIsReadable() {
        let error = AssessmentTransitionError(from: .idle, to: .ready)
        #expect(error.description.contains("Invalid"))
    }

    @Test("AssessmentTransitionError is Equatable")
    func assessmentTransitionErrorIsEquatable() {
        let error1 = AssessmentTransitionError(from: .idle, to: .ready)
        let error2 = AssessmentTransitionError(from: .idle, to: .ready)
        let error3 = AssessmentTransitionError(from: .loading, to: .ready)

        #expect(error1 == error2)
        #expect(error1 != error3)
    }
}
