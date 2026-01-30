import Testing
import Foundation
@testable import StateManagement

@Suite("AssessmentState")
struct AssessmentStateTests {

    // MARK: - Equality Tests

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        #expect(AssessmentState.idle == AssessmentState.idle)
        #expect(AssessmentState.loading == AssessmentState.loading)
        #expect(AssessmentState.ready == AssessmentState.ready)
        #expect(AssessmentState.submitting == AssessmentState.submitting)
    }

    @Test("InProgress states with same values are equal")
    func inProgressStatesWithSameValuesAreEqual() {
        #expect(AssessmentState.inProgress(answeredCount: 5, totalQuestions: 10) ==
                AssessmentState.inProgress(answeredCount: 5, totalQuestions: 10))
    }

    @Test("InProgress states with different values are not equal")
    func inProgressStatesWithDifferentValuesAreNotEqual() {
        #expect(AssessmentState.inProgress(answeredCount: 5, totalQuestions: 10) !=
                AssessmentState.inProgress(answeredCount: 6, totalQuestions: 10))
        #expect(AssessmentState.inProgress(answeredCount: 5, totalQuestions: 10) !=
                AssessmentState.inProgress(answeredCount: 5, totalQuestions: 15))
    }

    @Test("Completed states with same score are equal")
    func completedStatesWithSameScoreAreEqual() {
        #expect(AssessmentState.completed(score: 0.85) == AssessmentState.completed(score: 0.85))
    }

    @Test("Completed states with different scores are not equal")
    func completedStatesWithDifferentScoresAreNotEqual() {
        #expect(AssessmentState.completed(score: 0.85) != AssessmentState.completed(score: 0.90))
    }

    @Test("Error states with same error are equal")
    func errorStatesWithSameErrorAreEqual() {
        #expect(AssessmentState.error(.timeout) == AssessmentState.error(.timeout))
        #expect(AssessmentState.error(.cancelled) == AssessmentState.error(.cancelled))
    }

    // MARK: - Property Tests

    @Test("AnsweredCount returns value for inProgress state")
    func answeredCountReturnsValueForInProgressState() {
        let state = AssessmentState.inProgress(answeredCount: 7, totalQuestions: 15)
        #expect(state.answeredCount == 7)
        #expect(state.totalQuestions == 15)
    }

    @Test("AnsweredCount returns nil for other states")
    func answeredCountReturnsNilForOtherStates() {
        #expect(AssessmentState.idle.answeredCount == nil)
        #expect(AssessmentState.loading.answeredCount == nil)
        #expect(AssessmentState.ready.answeredCount == nil)
        #expect(AssessmentState.submitting.answeredCount == nil)
        #expect(AssessmentState.completed(score: 0.9).answeredCount == nil)
    }

    @Test("Progress returns correct percentage")
    func progressReturnsCorrectPercentage() {
        let state = AssessmentState.inProgress(answeredCount: 5, totalQuestions: 10)
        #expect(state.progress == 0.5)
    }

    @Test("Score returns value for completed state")
    func scoreReturnsValueForCompletedState() {
        let state = AssessmentState.completed(score: 0.92)
        #expect(state.score == 0.92)
    }

    @Test("Score returns nil for non-completed states")
    func scoreReturnsNilForNonCompletedStates() {
        #expect(AssessmentState.idle.score == nil)
        #expect(AssessmentState.inProgress(answeredCount: 5, totalQuestions: 10).score == nil)
    }

    @Test("Terminal states return true for isTerminal")
    func terminalStatesReturnTrueForIsTerminal() {
        #expect(AssessmentState.completed(score: 0.8).isTerminal == true)
        #expect(AssessmentState.error(.timeout).isTerminal == true)
    }

    @Test("Active states return true for isActive")
    func activeStatesReturnTrueForIsActive() {
        #expect(AssessmentState.loading.isActive == true)
        #expect(AssessmentState.ready.isActive == true)
        #expect(AssessmentState.inProgress(answeredCount: 0, totalQuestions: 10).isActive == true)
        #expect(AssessmentState.submitting.isActive == true)
    }

    @Test("CanAnswerQuestions returns true for ready and inProgress")
    func canAnswerQuestionsReturnsCorrectly() {
        #expect(AssessmentState.ready.canAnswerQuestions == true)
        #expect(AssessmentState.inProgress(answeredCount: 3, totalQuestions: 10).canAnswerQuestions == true)
        #expect(AssessmentState.idle.canAnswerQuestions == false)
        #expect(AssessmentState.submitting.canAnswerQuestions == false)
    }

    // MARK: - Description Tests

    @Test("Description provides human-readable text")
    func descriptionProvidesHumanReadableText() {
        #expect(AssessmentState.idle.description == "No assessment loaded")
        #expect(AssessmentState.loading.description == "Loading assessment...")
        #expect(AssessmentState.ready.description == "Assessment ready to start")
        #expect(AssessmentState.inProgress(answeredCount: 3, totalQuestions: 10).description == "Question 3 of 10")
        #expect(AssessmentState.submitting.description == "Submitting answers...")
        #expect(AssessmentState.completed(score: 0.85).description == "Completed with score: 85%")
    }
}

// MARK: - AssessmentError Tests

@Suite("AssessmentError")
struct AssessmentErrorTests {

    @Test("AssessmentError cases are Equatable")
    func assessmentErrorCasesAreEquatable() {
        #expect(AssessmentError.timeout == AssessmentError.timeout)
        #expect(AssessmentError.cancelled == AssessmentError.cancelled)
        #expect(AssessmentError.loadingFailed(reason: "Network") == AssessmentError.loadingFailed(reason: "Network"))
        #expect(AssessmentError.loadingFailed(reason: "Network") != AssessmentError.loadingFailed(reason: "Server"))
    }

    @Test("AssessmentError is Sendable")
    func assessmentErrorIsSendable() async {
        let error = AssessmentError.timeout

        let result = await Task {
            error
        }.value

        #expect(result == error)
    }
}

// MARK: - Codable Tests

@Suite("AssessmentState Codable")
struct AssessmentStateCodableTests {

    @Test("Idle state encodes and decodes")
    func idleStateEncodesAndDecodes() throws {
        let original = AssessmentState.idle
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AssessmentState.self, from: data)
        #expect(decoded == original)
    }

    @Test("Loading state encodes and decodes")
    func loadingStateEncodesAndDecodes() throws {
        let original = AssessmentState.loading
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AssessmentState.self, from: data)
        #expect(decoded == original)
    }

    @Test("Ready state encodes and decodes")
    func readyStateEncodesAndDecodes() throws {
        let original = AssessmentState.ready
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AssessmentState.self, from: data)
        #expect(decoded == original)
    }

    @Test("InProgress state encodes and decodes")
    func inProgressStateEncodesAndDecodes() throws {
        let original = AssessmentState.inProgress(answeredCount: 5, totalQuestions: 10)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AssessmentState.self, from: data)
        #expect(decoded == original)
    }

    @Test("Submitting state encodes and decodes")
    func submittingStateEncodesAndDecodes() throws {
        let original = AssessmentState.submitting
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AssessmentState.self, from: data)
        #expect(decoded == original)
    }

    @Test("Completed state encodes and decodes")
    func completedStateEncodesAndDecodes() throws {
        let original = AssessmentState.completed(score: 0.875)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AssessmentState.self, from: data)
        #expect(decoded == original)
    }

    @Test("Error state with reason encodes and decodes")
    func errorStateWithReasonEncodesAndDecodes() throws {
        let original = AssessmentState.error(.networkError(reason: "Connection lost"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AssessmentState.self, from: data)
        #expect(decoded == original)
    }

    @Test("Error state without reason encodes and decodes")
    func errorStateWithoutReasonEncodesAndDecodes() throws {
        let original = AssessmentState.error(.timeout)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AssessmentState.self, from: data)
        #expect(decoded == original)
    }
}
