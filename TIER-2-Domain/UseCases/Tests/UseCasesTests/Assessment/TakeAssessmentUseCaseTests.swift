import XCTest
@testable import UseCases

// MARK: - Mock Repositories

actor MockAssessmentsRepository: AssessmentsRepositoryProtocol {
    var mockAssessment: Assessment?
    var cachedAssessment: Assessment?
    var mockError: Error?
    var getCallCount = 0

    func setAssessment(_ assessment: Assessment?) {
        self.mockAssessment = assessment
    }

    func setCachedAssessment(_ assessment: Assessment?) {
        self.cachedAssessment = assessment
    }

    func setError(_ error: Error?) {
        self.mockError = error
    }

    func get(id: UUID) async throws -> Assessment {
        getCallCount += 1
        if let error = mockError {
            throw error
        }
        guard let assessment = mockAssessment else {
            throw TestAssessmentError.notFound
        }
        return assessment
    }

    func getCached(id: UUID) async -> Assessment? {
        cachedAssessment
    }

    func cache(_ assessment: Assessment) async {
        cachedAssessment = assessment
    }
}

actor MockAttemptsRepository: AttemptsRepositoryProtocol {
    var mockAttemptId: UUID = UUID()
    var mockResult: AttemptResult?
    var startError: Error?
    var submitError: Error?
    var startCallCount = 0
    var submitCallCount = 0
    var lastIdempotencyKey: String?

    func setAttemptId(_ id: UUID) {
        self.mockAttemptId = id
    }

    func setResult(_ result: AttemptResult?) {
        self.mockResult = result
    }

    func setStartError(_ error: Error?) {
        self.startError = error
    }

    func setSubmitError(_ error: Error?) {
        self.submitError = error
    }

    func startAttempt(assessmentId: UUID, userId: UUID) async throws -> UUID {
        startCallCount += 1
        if let error = startError {
            throw error
        }
        return mockAttemptId
    }

    func submitAttempt(
        attemptId: UUID,
        answers: [UserAnswer],
        timeSpentSeconds: Int,
        idempotencyKey: String
    ) async throws -> AttemptResult {
        submitCallCount += 1
        lastIdempotencyKey = idempotencyKey
        if let error = submitError {
            throw error
        }
        guard let result = mockResult else {
            throw TestAssessmentError.noResult
        }
        return result
    }
}

actor MockLocalStorageService: LocalStorageServiceProtocol {
    var states: [UUID: AssessmentState] = [:]
    var inProgressAttempts: [UUID: InProgressAttempt] = [:]
    var pendingSubmissions: [PendingSubmission] = []

    func saveState(_ state: AssessmentState, for assessmentId: UUID) async {
        states[assessmentId] = state
    }

    func getState(for assessmentId: UUID) async -> AssessmentState? {
        states[assessmentId]
    }

    func saveInProgressAttempt(_ attempt: InProgressAttempt) async {
        inProgressAttempts[attempt.assessmentId] = attempt
    }

    func getInProgressAttempt(for assessmentId: UUID) async -> InProgressAttempt? {
        inProgressAttempts[assessmentId]
    }

    func removeInProgressAttempt(for assessmentId: UUID) async {
        inProgressAttempts.removeValue(forKey: assessmentId)
    }

    func addPendingSubmission(_ submission: PendingSubmission) async {
        pendingSubmissions.append(submission)
    }

    func getPendingSubmissions() async -> [PendingSubmission] {
        pendingSubmissions
    }

    func removePendingSubmission(id: UUID) async {
        pendingSubmissions.removeAll { $0.id == id }
    }

    func updatePendingSubmissionRetryCount(id: UUID, retryCount: Int) async {
        if let index = pendingSubmissions.firstIndex(where: { $0.id == id }) {
            var submission = pendingSubmissions[index]
            submission = PendingSubmission(
                id: submission.id,
                attemptId: submission.attemptId,
                assessmentId: submission.assessmentId,
                userId: submission.userId,
                answers: submission.answers,
                timeSpentSeconds: submission.timeSpentSeconds,
                idempotencyKey: submission.idempotencyKey,
                createdAt: submission.createdAt,
                retryCount: retryCount
            )
            pendingSubmissions[index] = submission
        }
    }

    // Helper methods for testing
    func setInProgressAttempt(_ attempt: InProgressAttempt) {
        inProgressAttempts[attempt.assessmentId] = attempt
    }
}

enum TestAssessmentError: Error {
    case notFound
    case noResult
    case networkError
}

// MARK: - Test Fixtures

enum AssessmentTestFixtures {
    static func createAssessment(
        id: UUID = UUID(),
        questions: [AssessmentQuestion]? = nil,
        timeLimitSeconds: Int? = nil,
        maxAttempts: Int = 3,
        attemptsUsed: Int = 0,
        expiresAt: Date? = nil
    ) -> Assessment {
        Assessment(
            id: id,
            materialId: UUID(),
            title: "Test Assessment",
            description: "A test assessment",
            questions: questions ?? [
                createQuestion(orderIndex: 0),
                createQuestion(orderIndex: 1),
                createQuestion(orderIndex: 2)
            ],
            timeLimitSeconds: timeLimitSeconds,
            maxAttempts: maxAttempts,
            passThreshold: 70,
            attemptsUsed: attemptsUsed,
            expiresAt: expiresAt
        )
    }

    static func createQuestion(
        id: UUID = UUID(),
        text: String = "Test question",
        isRequired: Bool = true,
        orderIndex: Int = 0
    ) -> AssessmentQuestion {
        AssessmentQuestion(
            id: id,
            text: text,
            options: [
                QuestionOption(id: UUID(), text: "Option A", orderIndex: 0),
                QuestionOption(id: UUID(), text: "Option B", orderIndex: 1),
                QuestionOption(id: UUID(), text: "Option C", orderIndex: 2)
            ],
            isRequired: isRequired,
            orderIndex: orderIndex
        )
    }

    static func createAttemptResult(
        attemptId: UUID = UUID(),
        assessmentId: UUID = UUID(),
        userId: UUID = UUID(),
        score: Int = 80,
        passed: Bool = true
    ) -> AttemptResult {
        AttemptResult(
            attemptId: attemptId,
            assessmentId: assessmentId,
            userId: userId,
            score: score,
            maxScore: 100,
            passed: passed,
            correctAnswers: 8,
            totalQuestions: 10,
            timeSpentSeconds: 300,
            feedback: [],
            startedAt: Date().addingTimeInterval(-300),
            completedAt: Date(),
            canRetake: true
        )
    }
}

// MARK: - Tests

final class TakeAssessmentUseCaseTests: XCTestCase {

    var assessmentsRepo: MockAssessmentsRepository!
    var attemptsRepo: MockAttemptsRepository!
    var localStorage: MockLocalStorageService!
    var sut: TakeAssessmentUseCase!

    override func setUp() async throws {
        try await super.setUp()
        assessmentsRepo = MockAssessmentsRepository()
        attemptsRepo = MockAttemptsRepository()
        localStorage = MockLocalStorageService()
        sut = TakeAssessmentUseCase(
            assessmentsRepository: assessmentsRepo,
            attemptsRepository: attemptsRepo,
            localStorage: localStorage
        )
    }

    override func tearDown() async throws {
        assessmentsRepo = nil
        attemptsRepo = nil
        localStorage = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - State Machine Tests

    func testInitialState_IsIdle() async {
        let state = await sut.state
        XCTAssertEqual(state, .idle)
    }

    func testLoadAssessment_TransitionsToReady() async throws {
        // Arrange
        let assessment = AssessmentTestFixtures.createAssessment()
        await assessmentsRepo.setAssessment(assessment)
        let input = TakeAssessmentInput(assessmentId: assessment.id, userId: UUID())

        // Act
        _ = try await sut.loadAssessment(input: input)

        // Assert
        let state = await sut.state
        XCTAssertEqual(state, .ready)
    }

    func testStartAttempt_TransitionsToInProgress() async throws {
        // Arrange
        let assessment = AssessmentTestFixtures.createAssessment()
        await assessmentsRepo.setAssessment(assessment)
        let input = TakeAssessmentInput(assessmentId: assessment.id, userId: UUID())
        _ = try await sut.loadAssessment(input: input)

        // Act
        _ = try await sut.startAttempt()

        // Assert
        let state = await sut.state
        XCTAssertEqual(state, .inProgress)
    }

    func testSubmitAttempt_TransitionsToCompleted() async throws {
        // Arrange
        let assessment = AssessmentTestFixtures.createAssessment()
        await assessmentsRepo.setAssessment(assessment)
        let result = AssessmentTestFixtures.createAttemptResult(assessmentId: assessment.id)
        await attemptsRepo.setResult(result)

        let input = TakeAssessmentInput(assessmentId: assessment.id, userId: UUID())
        _ = try await sut.loadAssessment(input: input)
        _ = try await sut.startAttempt()

        // Answer all questions
        for question in assessment.questions {
            try await sut.saveAnswer(
                questionId: question.id,
                selectedOptionId: question.options[0].id,
                timeSpentSeconds: 10
            )
        }

        // Act
        _ = try await sut.submitAttempt()

        // Assert
        let state = await sut.state
        XCTAssertEqual(state, .completed)
    }

    // MARK: - Invalid State Transition Tests

    func testStartAttempt_FromIdle_ThrowsError() async throws {
        // Act & Assert
        do {
            _ = try await sut.startAttempt()
            XCTFail("Expected error")
        } catch let error as AssessmentStateError {
            if case .cannotStartFromState(let state) = error {
                XCTAssertEqual(state, .idle)
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testSubmitAttempt_FromReady_ThrowsError() async throws {
        // Arrange
        let assessment = AssessmentTestFixtures.createAssessment()
        await assessmentsRepo.setAssessment(assessment)
        let input = TakeAssessmentInput(assessmentId: assessment.id, userId: UUID())
        _ = try await sut.loadAssessment(input: input)

        // Act & Assert
        do {
            _ = try await sut.submitAttempt()
            XCTFail("Expected error")
        } catch let error as AssessmentStateError {
            if case .cannotSubmitFromState(let state) = error {
                XCTAssertEqual(state, .ready)
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    // MARK: - Load Assessment Tests

    func testLoadAssessment_UsesCacheOnNetworkError() async throws {
        // Arrange
        let assessment = AssessmentTestFixtures.createAssessment()
        await assessmentsRepo.setCachedAssessment(assessment)
        await assessmentsRepo.setError(TestAssessmentError.networkError)
        let input = TakeAssessmentInput(assessmentId: assessment.id, userId: UUID())

        // Act
        let loaded = try await sut.loadAssessment(input: input)

        // Assert
        XCTAssertEqual(loaded.id, assessment.id)
        let state = await sut.state
        XCTAssertEqual(state, .ready)
    }

    func testLoadAssessment_ThrowsWhenNoCache() async throws {
        // Arrange
        await assessmentsRepo.setError(TestAssessmentError.networkError)
        let input = TakeAssessmentInput(assessmentId: UUID(), userId: UUID())

        // Act & Assert
        do {
            _ = try await sut.loadAssessment(input: input)
            XCTFail("Expected error")
        } catch {
            let state = await sut.state
            XCTAssertEqual(state, .idle)
        }
    }

    func testLoadAssessment_RecoversSavedAttempt() async throws {
        // Arrange
        let assessmentId = UUID()
        let userId = UUID()
        let assessment = AssessmentTestFixtures.createAssessment(id: assessmentId)
        await assessmentsRepo.setAssessment(assessment)

        let savedAttempt = InProgressAttempt(
            attemptId: UUID(),
            assessmentId: assessmentId,
            userId: userId
        )
        await localStorage.setInProgressAttempt(savedAttempt)

        let input = TakeAssessmentInput(assessmentId: assessmentId, userId: userId)

        // Act
        _ = try await sut.loadAssessment(input: input)

        // Assert
        let state = await sut.state
        XCTAssertEqual(state, .inProgress)

        let attempt = await sut.inProgressAttempt
        XCTAssertNotNil(attempt)
        XCTAssertEqual(attempt?.attemptId, savedAttempt.attemptId)
    }

    // MARK: - Validation Tests

    func testStartAttempt_FailsWhenNoAttemptsLeft() async throws {
        // Arrange
        let assessment = AssessmentTestFixtures.createAssessment(
            maxAttempts: 3,
            attemptsUsed: 3
        )
        await assessmentsRepo.setAssessment(assessment)
        let input = TakeAssessmentInput(assessmentId: assessment.id, userId: UUID())
        _ = try await sut.loadAssessment(input: input)

        // Act & Assert
        do {
            _ = try await sut.startAttempt()
            XCTFail("Expected error")
        } catch let error as UseCaseError {
            if case .preconditionFailed(let description) = error {
                XCTAssertTrue(description.contains("intentos"))
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testStartAttempt_FailsWhenExpired() async throws {
        // Arrange
        let assessment = AssessmentTestFixtures.createAssessment(
            expiresAt: Date().addingTimeInterval(-3600) // Expired 1 hour ago
        )
        await assessmentsRepo.setAssessment(assessment)
        let input = TakeAssessmentInput(assessmentId: assessment.id, userId: UUID())
        _ = try await sut.loadAssessment(input: input)

        // Act & Assert
        do {
            _ = try await sut.startAttempt()
            XCTFail("Expected error")
        } catch let error as UseCaseError {
            if case .preconditionFailed(let description) = error {
                XCTAssertTrue(description.contains("expirado"))
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testSubmitAttempt_FailsWithIncompleteAnswers() async throws {
        // Arrange
        let assessment = AssessmentTestFixtures.createAssessment()
        await assessmentsRepo.setAssessment(assessment)
        await attemptsRepo.setResult(AssessmentTestFixtures.createAttemptResult())

        let input = TakeAssessmentInput(assessmentId: assessment.id, userId: UUID())
        _ = try await sut.loadAssessment(input: input)
        _ = try await sut.startAttempt()

        // Only answer 1 of 3 questions
        try await sut.saveAnswer(
            questionId: assessment.questions[0].id,
            selectedOptionId: assessment.questions[0].options[0].id,
            timeSpentSeconds: 10
        )

        // Act & Assert
        do {
            _ = try await sut.submitAttempt()
            XCTFail("Expected error")
        } catch let error as AssessmentStateError {
            if case .incompleteAnswers(let missing) = error {
                XCTAssertEqual(missing, 2)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Answer Saving Tests

    func testSaveAnswer_PersistsLocally() async throws {
        // Arrange
        let assessment = AssessmentTestFixtures.createAssessment()
        await assessmentsRepo.setAssessment(assessment)
        let input = TakeAssessmentInput(assessmentId: assessment.id, userId: UUID())
        _ = try await sut.loadAssessment(input: input)
        _ = try await sut.startAttempt()

        let questionId = assessment.questions[0].id
        let optionId = assessment.questions[0].options[0].id

        // Act
        try await sut.saveAnswer(
            questionId: questionId,
            selectedOptionId: optionId,
            timeSpentSeconds: 15
        )

        // Assert
        let attempt = await sut.inProgressAttempt
        XCTAssertEqual(attempt?.answers.count, 1)
        XCTAssertEqual(attempt?.answers.first?.questionId, questionId)
        XCTAssertEqual(attempt?.answers.first?.selectedOptionId, optionId)

        let savedAttempt = await localStorage.getInProgressAttempt(for: assessment.id)
        XCTAssertNotNil(savedAttempt)
        XCTAssertEqual(savedAttempt?.answers.count, 1)
    }

    func testSaveAnswer_UpdatesExistingAnswer() async throws {
        // Arrange
        let assessment = AssessmentTestFixtures.createAssessment()
        await assessmentsRepo.setAssessment(assessment)
        let input = TakeAssessmentInput(assessmentId: assessment.id, userId: UUID())
        _ = try await sut.loadAssessment(input: input)
        _ = try await sut.startAttempt()

        let questionId = assessment.questions[0].id
        let optionA = assessment.questions[0].options[0].id
        let optionB = assessment.questions[0].options[1].id

        // Act - answer with option A, then change to B
        try await sut.saveAnswer(questionId: questionId, selectedOptionId: optionA, timeSpentSeconds: 10)
        try await sut.saveAnswer(questionId: questionId, selectedOptionId: optionB, timeSpentSeconds: 15)

        // Assert
        let attempt = await sut.inProgressAttempt
        XCTAssertEqual(attempt?.answers.count, 1)
        XCTAssertEqual(attempt?.answers.first?.selectedOptionId, optionB)
    }

    // MARK: - Offline Support Tests

    func testSubmitAttempt_SavesPendingOnError() async throws {
        // Arrange
        let assessment = AssessmentTestFixtures.createAssessment()
        await assessmentsRepo.setAssessment(assessment)
        await attemptsRepo.setSubmitError(TestAssessmentError.networkError)

        let input = TakeAssessmentInput(assessmentId: assessment.id, userId: UUID())
        _ = try await sut.loadAssessment(input: input)
        _ = try await sut.startAttempt()

        for question in assessment.questions {
            try await sut.saveAnswer(
                questionId: question.id,
                selectedOptionId: question.options[0].id,
                timeSpentSeconds: 10
            )
        }

        // Act
        do {
            _ = try await sut.submitAttempt()
            XCTFail("Expected error")
        } catch {
            // Expected
        }

        // Assert
        let pending = await localStorage.getPendingSubmissions()
        XCTAssertEqual(pending.count, 1)

        let state = await sut.state
        XCTAssertEqual(state, .inProgress) // Allows retry
    }

    func testSyncPendingSubmissions_SuccessfullySubmits() async throws {
        // Arrange
        let pending = PendingSubmission(
            attemptId: UUID(),
            assessmentId: UUID(),
            userId: UUID(),
            answers: [],
            timeSpentSeconds: 100,
            idempotencyKey: UUID().uuidString
        )
        await localStorage.addPendingSubmission(pending)
        await attemptsRepo.setResult(AssessmentTestFixtures.createAttemptResult())

        // Act
        let synced = await sut.syncPendingSubmissions()

        // Assert
        XCTAssertEqual(synced, 1)
        let remaining = await localStorage.getPendingSubmissions()
        XCTAssertTrue(remaining.isEmpty)
    }

    // MARK: - Reset Tests

    func testReset_ClearsState() async throws {
        // Arrange
        let assessment = AssessmentTestFixtures.createAssessment()
        await assessmentsRepo.setAssessment(assessment)
        let input = TakeAssessmentInput(assessmentId: assessment.id, userId: UUID())
        _ = try await sut.loadAssessment(input: input)
        _ = try await sut.startAttempt()

        // Act
        await sut.reset()

        // Assert
        let state = await sut.state
        XCTAssertEqual(state, .idle)

        let loadedAssessment = await sut.assessment
        XCTAssertNil(loadedAssessment)

        let attempt = await sut.inProgressAttempt
        XCTAssertNil(attempt)
    }

    // MARK: - Model Tests

    func testAssessment_CanTake_WithAttemptsLeft() {
        let assessment = AssessmentTestFixtures.createAssessment(
            maxAttempts: 3,
            attemptsUsed: 2
        )
        XCTAssertTrue(assessment.canTake)
        XCTAssertEqual(assessment.attemptsLeft, 1)
    }

    func testAssessment_CannotTake_NoAttemptsLeft() {
        let assessment = AssessmentTestFixtures.createAssessment(
            maxAttempts: 3,
            attemptsUsed: 3
        )
        XCTAssertFalse(assessment.canTake)
        XCTAssertEqual(assessment.attemptsLeft, 0)
    }

    func testAssessment_CannotTake_Expired() {
        let assessment = AssessmentTestFixtures.createAssessment(
            expiresAt: Date().addingTimeInterval(-3600)
        )
        XCTAssertFalse(assessment.canTake)
    }

    func testAttemptResult_Percentage() {
        let result = AttemptResult(
            attemptId: UUID(),
            assessmentId: UUID(),
            userId: UUID(),
            score: 75,
            maxScore: 100,
            passed: true,
            correctAnswers: 3,
            totalQuestions: 4,
            timeSpentSeconds: 100,
            feedback: [],
            startedAt: Date(),
            completedAt: Date(),
            canRetake: true
        )
        XCTAssertEqual(result.percentage, 75.0)
    }

    func testInProgressAttempt_WithAnswer() {
        let attempt = InProgressAttempt(
            attemptId: UUID(),
            assessmentId: UUID(),
            userId: UUID()
        )

        let answer = UserAnswer(
            questionId: UUID(),
            selectedOptionId: UUID(),
            timeSpentSeconds: 10
        )

        let updated = attempt.withAnswer(answer)

        XCTAssertEqual(updated.answers.count, 1)
        XCTAssertEqual(updated.answers.first?.questionId, answer.questionId)
    }

    func testAssessmentStateError_LocalizedDescriptions() {
        let errors: [AssessmentStateError] = [
            .invalidTransition(from: .idle, to: .completed),
            .cannotSubmitFromState(.idle),
            .cannotStartFromState(.completed),
            .attemptExpired,
            .incompleteAnswers(missing: 3),
            .duplicateSubmission,
            .assessmentNotLoaded,
            .noAttemptInProgress
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}
