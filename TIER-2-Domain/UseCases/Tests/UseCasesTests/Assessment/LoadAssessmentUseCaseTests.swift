import XCTest
@testable import UseCases

// MARK: - Mock Eligibility Service

actor MockEligibilityService: EligibilityServiceProtocol {
    var mockEligibility: AssessmentEligibility?
    var mockError: Error?
    var checkCallCount = 0
    var lastAssessmentId: UUID?
    var lastUserId: UUID?

    func setEligibility(_ eligibility: AssessmentEligibility?) {
        self.mockEligibility = eligibility
    }

    func setError(_ error: Error?) {
        self.mockError = error
    }

    func checkEligibility(
        assessmentId: UUID,
        userId: UUID
    ) async throws -> AssessmentEligibility {
        checkCallCount += 1
        lastAssessmentId = assessmentId
        lastUserId = userId

        if let error = mockError {
            throw error
        }

        guard let eligibility = mockEligibility else {
            throw LoadAssessmentTestError.noMockEligibility
        }

        return eligibility
    }
}

// MARK: - Mock Assessment Cache Service

actor MockAssessmentCacheService: AssessmentCacheServiceProtocol {
    var cachedEntries: [UUID: AssessmentCacheEntry] = [:]
    var getCallCount = 0
    var saveCallCount = 0
    var removeCallCount = 0

    func get(assessmentId: UUID) async -> AssessmentCacheEntry? {
        getCallCount += 1
        return cachedEntries[assessmentId]
    }

    func save(_ entry: AssessmentCacheEntry, for assessmentId: UUID) async {
        saveCallCount += 1
        cachedEntries[assessmentId] = entry
    }

    func remove(assessmentId: UUID) async {
        removeCallCount += 1
        cachedEntries.removeValue(forKey: assessmentId)
    }

    // Helper methods for testing
    func setCachedEntry(_ entry: AssessmentCacheEntry?, for assessmentId: UUID) {
        if let entry = entry {
            cachedEntries[assessmentId] = entry
        } else {
            cachedEntries.removeValue(forKey: assessmentId)
        }
    }

    func setFreshEntry(assessment: Assessment, eligibility: AssessmentEligibility) {
        let entry = AssessmentCacheEntry(
            assessment: assessment,
            eligibility: eligibility
        )
        cachedEntries[assessment.id] = entry
    }

    func setStaleEntry(
        assessment: Assessment,
        eligibility: AssessmentEligibility,
        ageMinutes: Int = 30
    ) {
        let entry = AssessmentCacheEntry(
            assessment: assessment,
            eligibility: eligibility,
            cachedAt: Date().addingTimeInterval(-TimeInterval(ageMinutes * 60))
        )
        cachedEntries[assessment.id] = entry
    }

    func setExpiredEntry(
        assessment: Assessment,
        eligibility: AssessmentEligibility,
        ageMinutes: Int = 90
    ) {
        let entry = AssessmentCacheEntry(
            assessment: assessment,
            eligibility: eligibility,
            cachedAt: Date().addingTimeInterval(-TimeInterval(ageMinutes * 60))
        )
        cachedEntries[assessment.id] = entry
    }
}



// MARK: - Test Errors

enum LoadAssessmentTestError: Error {
    case noMockEligibility
    case networkError
    case serverError
}

// MARK: - Test Fixtures

enum LoadAssessmentTestFixtures {
    static func createAssessment(
        id: UUID = UUID(),
        title: String = "Test Assessment",
        questions: [AssessmentQuestion]? = nil,
        maxAttempts: Int = 3,
        attemptsUsed: Int = 0,
        expiresAt: Date? = nil
    ) -> Assessment {
        Assessment(
            id: id,
            materialId: UUID(),
            title: title,
            description: "Test description",
            questions: questions ?? [
                createQuestion(orderIndex: 0),
                createQuestion(orderIndex: 1),
                createQuestion(orderIndex: 2)
            ],
            timeLimitSeconds: 3600,
            maxAttempts: maxAttempts,
            passThreshold: 70,
            attemptsUsed: attemptsUsed,
            expiresAt: expiresAt
        )
    }

    static func createQuestion(
        id: UUID = UUID(),
        orderIndex: Int = 0
    ) -> AssessmentQuestion {
        AssessmentQuestion(
            id: id,
            text: "Question \(orderIndex + 1)",
            options: [
                QuestionOption(id: UUID(), text: "Option A", orderIndex: 0),
                QuestionOption(id: UUID(), text: "Option B", orderIndex: 1),
                QuestionOption(id: UUID(), text: "Option C", orderIndex: 2)
            ],
            isRequired: true,
            orderIndex: orderIndex
        )
    }

    static func createEligibility(
        canTake: Bool = true,
        reason: EligibilityReason? = nil,
        attemptsLeft: Int = 3,
        expiresAt: Date? = nil
    ) -> AssessmentEligibility {
        AssessmentEligibility(
            canTake: canTake,
            reason: reason,
            attemptsLeft: attemptsLeft,
            expiresAt: expiresAt
        )
    }

    static func createCacheEntry(
        assessment: Assessment,
        eligibility: AssessmentEligibility
    ) -> AssessmentCacheEntry {
        AssessmentCacheEntry(
            assessment: assessment,
            eligibility: eligibility
        )
    }
}

// MARK: - Tests

final class LoadAssessmentUseCaseTests: XCTestCase {

    var assessmentsRepo: MockAssessmentsRepository!
    var eligibilityService: MockEligibilityService!
    var cacheService: MockAssessmentCacheService!
    var sut: LoadAssessmentUseCase!

    override func setUp() async throws {
        try await super.setUp()
        assessmentsRepo = MockAssessmentsRepository()
        eligibilityService = MockEligibilityService()
        cacheService = MockAssessmentCacheService()
        sut = LoadAssessmentUseCase(
            assessmentsRepository: assessmentsRepo,
            eligibilityService: eligibilityService,
            cacheService: cacheService
        )
    }

    override func tearDown() async throws {
        assessmentsRepo = nil
        eligibilityService = nil
        cacheService = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Basic Fetch Tests

    func testExecute_FetchesFromServer_WhenNoCacheExists() async throws {
        // Arrange
        let assessment = LoadAssessmentTestFixtures.createAssessment()
        let eligibility = LoadAssessmentTestFixtures.createEligibility()
        await assessmentsRepo.setAssessment(assessment)
        await eligibilityService.setEligibility(eligibility)

        let input = LoadAssessmentInput(
            assessmentId: assessment.id,
            userId: UUID()
        )

        // Act
        let result = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(result.assessment.id, assessment.id)
        XCTAssertEqual(result.eligibility.canTake, true)
        XCTAssertNil(result.cachedAt)
        XCTAssertFalse(result.isStale)
    }

    func testExecute_SavesInCache_AfterFetch() async throws {
        // Arrange
        let assessment = LoadAssessmentTestFixtures.createAssessment()
        let eligibility = LoadAssessmentTestFixtures.createEligibility()
        await assessmentsRepo.setAssessment(assessment)
        await eligibilityService.setEligibility(eligibility)

        let input = LoadAssessmentInput(
            assessmentId: assessment.id,
            userId: UUID()
        )

        // Act
        _ = try await sut.execute(input: input)

        // Assert
        let saveCount = await cacheService.saveCallCount
        XCTAssertEqual(saveCount, 1)

        let cachedEntry = await cacheService.get(assessmentId: assessment.id)
        XCTAssertNotNil(cachedEntry)
        XCTAssertEqual(cachedEntry?.assessment.id, assessment.id)
    }

    func testExecute_FetchesInParallel_AssessmentAndEligibility() async throws {
        // Arrange
        let assessment = LoadAssessmentTestFixtures.createAssessment()
        let eligibility = LoadAssessmentTestFixtures.createEligibility(attemptsLeft: 2)
        await assessmentsRepo.setAssessment(assessment)
        await eligibilityService.setEligibility(eligibility)

        let userId = UUID()
        let input = LoadAssessmentInput(
            assessmentId: assessment.id,
            userId: userId
        )

        // Act
        let result = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(result.assessment.id, assessment.id)
        XCTAssertEqual(result.eligibility.attemptsLeft, 2)

        let repoCallCount = await assessmentsRepo.getCallCount
        XCTAssertEqual(repoCallCount, 1)

        let eligibilityCallCount = await eligibilityService.checkCallCount
        XCTAssertEqual(eligibilityCallCount, 1)

        let lastUserId = await eligibilityService.lastUserId
        XCTAssertEqual(lastUserId, userId)
    }

    // MARK: - Cache Hit Tests (Fresh)

    func testExecute_ReturnsCachedData_WhenCacheIsFresh() async throws {
        // Arrange
        let assessment = LoadAssessmentTestFixtures.createAssessment()
        let eligibility = LoadAssessmentTestFixtures.createEligibility()
        await cacheService.setFreshEntry(assessment: assessment, eligibility: eligibility)

        let input = LoadAssessmentInput(
            assessmentId: assessment.id,
            userId: UUID()
        )

        // Act
        let result = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(result.assessment.id, assessment.id)
        XCTAssertNotNil(result.cachedAt)
        XCTAssertFalse(result.isStale)

        // Should NOT fetch from server
        let repoCallCount = await assessmentsRepo.getCallCount
        XCTAssertEqual(repoCallCount, 0)
    }

    // MARK: - Force Refresh Tests

    func testExecute_IgnoresCache_WhenForceRefreshIsTrue() async throws {
        // Arrange
        let cachedAssessment = LoadAssessmentTestFixtures.createAssessment(title: "Cached")
        let serverAssessment = LoadAssessmentTestFixtures.createAssessment(
            id: cachedAssessment.id,
            title: "Server"
        )
        let eligibility = LoadAssessmentTestFixtures.createEligibility()

        await cacheService.setFreshEntry(assessment: cachedAssessment, eligibility: eligibility)
        await assessmentsRepo.setAssessment(serverAssessment)
        await eligibilityService.setEligibility(eligibility)

        let input = LoadAssessmentInput(
            assessmentId: cachedAssessment.id,
            userId: UUID(),
            forceRefresh: true
        )

        // Act
        let result = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(result.assessment.title, "Server")
        XCTAssertNil(result.cachedAt)
        XCTAssertFalse(result.isStale)

        // Should fetch from server
        let repoCallCount = await assessmentsRepo.getCallCount
        XCTAssertEqual(repoCallCount, 1)
    }

    // MARK: - Error Handling Tests

    func testExecute_ReturnsCachedData_OnNetworkError_WhenCacheExists() async throws {
        // Arrange
        let assessment = LoadAssessmentTestFixtures.createAssessment()
        let eligibility = LoadAssessmentTestFixtures.createEligibility()
        await cacheService.setFreshEntry(assessment: assessment, eligibility: eligibility)
        await assessmentsRepo.setError(LoadAssessmentTestError.networkError)

        let input = LoadAssessmentInput(
            assessmentId: assessment.id,
            userId: UUID(),
            forceRefresh: true // Force fetch attempt
        )

        // Act
        let result = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(result.assessment.id, assessment.id)
        XCTAssertTrue(result.isStale) // Marked as stale due to network error
    }

    func testExecute_ThrowsError_OnNetworkError_WhenNoCacheExists() async throws {
        // Arrange
        await assessmentsRepo.setError(LoadAssessmentTestError.networkError)

        let input = LoadAssessmentInput(
            assessmentId: UUID(),
            userId: UUID()
        )

        // Act & Assert
        do {
            _ = try await sut.execute(input: input)
            XCTFail("Expected error")
        } catch {
            // Expected
            XCTAssertTrue(error is LoadAssessmentTestError)
        }
    }

    func testExecute_FallsBackToUnknownReason_OnEligibilityError() async throws {
        // Arrange
        let assessment = LoadAssessmentTestFixtures.createAssessment()
        await assessmentsRepo.setAssessment(assessment)
        await eligibilityService.setError(LoadAssessmentTestError.serverError)

        let input = LoadAssessmentInput(
            assessmentId: assessment.id,
            userId: UUID()
        )

        // Act
        let result = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(result.assessment.id, assessment.id)
        XCTAssertFalse(result.eligibility.canTake)
        XCTAssertEqual(result.eligibility.reason, .unknown)
        XCTAssertEqual(result.eligibility.attemptsLeft, 0)
    }

    // MARK: - Eligibility Restriction Tests

    func testExecute_HidesQuestions_WhenNoAttemptsLeft() async throws {
        // Arrange
        let assessment = LoadAssessmentTestFixtures.createAssessment()
        let eligibility = LoadAssessmentTestFixtures.createEligibility(
            canTake: false,
            reason: .noAttemptsLeft,
            attemptsLeft: 0
        )
        await assessmentsRepo.setAssessment(assessment)
        await eligibilityService.setEligibility(eligibility)

        let input = LoadAssessmentInput(
            assessmentId: assessment.id,
            userId: UUID()
        )

        // Act
        let result = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(result.assessment.id, assessment.id)
        XCTAssertTrue(result.assessment.questions.isEmpty) // Questions hidden
        XCTAssertFalse(result.eligibility.canTake)
        XCTAssertEqual(result.eligibility.reason, .noAttemptsLeft)
    }

    func testExecute_ShowsQuestions_WhenAttemptsRemaining() async throws {
        // Arrange
        let assessment = LoadAssessmentTestFixtures.createAssessment()
        let eligibility = LoadAssessmentTestFixtures.createEligibility(
            canTake: true,
            attemptsLeft: 2
        )
        await assessmentsRepo.setAssessment(assessment)
        await eligibilityService.setEligibility(eligibility)

        let input = LoadAssessmentInput(
            assessmentId: assessment.id,
            userId: UUID()
        )

        // Act
        let result = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(result.assessment.questions.count, 3) // Questions visible
        XCTAssertTrue(result.eligibility.canTake)
    }

    func testExecute_AllowsViewingAssessment_WhenExpired() async throws {
        // Arrange
        let assessment = LoadAssessmentTestFixtures.createAssessment()
        let eligibility = LoadAssessmentTestFixtures.createEligibility(
            canTake: false,
            reason: .expired,
            attemptsLeft: 2 // Still has attempts but expired
        )
        await assessmentsRepo.setAssessment(assessment)
        await eligibilityService.setEligibility(eligibility)

        let input = LoadAssessmentInput(
            assessmentId: assessment.id,
            userId: UUID()
        )

        // Act
        let result = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(result.assessment.questions.count, 3) // Can still view questions
        XCTAssertFalse(result.eligibility.canTake)
        XCTAssertEqual(result.eligibility.reason, .expired)
    }

    // MARK: - Model Tests

    func testLoadAssessmentInput_Equatable() {
        let id1 = UUID()
        let id2 = UUID()

        let input1 = LoadAssessmentInput(assessmentId: id1, userId: id2)
        let input2 = LoadAssessmentInput(assessmentId: id1, userId: id2)
        let input3 = LoadAssessmentInput(assessmentId: id1, userId: id2, forceRefresh: true)

        XCTAssertEqual(input1, input2)
        XCTAssertNotEqual(input1, input3)
    }

    func testAssessmentEligibility_Codable() throws {
        let eligibility = AssessmentEligibility(
            canTake: false,
            reason: .noAttemptsLeft,
            attemptsLeft: 0,
            expiresAt: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(eligibility)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AssessmentEligibility.self, from: data)

        XCTAssertEqual(eligibility.canTake, decoded.canTake)
        XCTAssertEqual(eligibility.reason, decoded.reason)
        XCTAssertEqual(eligibility.attemptsLeft, decoded.attemptsLeft)
    }

    func testAssessmentDetail_Equatable() {
        let assessment = LoadAssessmentTestFixtures.createAssessment()
        let eligibility = LoadAssessmentTestFixtures.createEligibility()

        let detail1 = AssessmentDetail(
            assessment: assessment,
            eligibility: eligibility,
            cachedAt: nil,
            isStale: false
        )
        let detail2 = AssessmentDetail(
            assessment: assessment,
            eligibility: eligibility,
            cachedAt: nil,
            isStale: false
        )
        let detail3 = AssessmentDetail(
            assessment: assessment,
            eligibility: eligibility,
            cachedAt: nil,
            isStale: true
        )

        XCTAssertEqual(detail1, detail2)
        XCTAssertNotEqual(detail1, detail3)
    }

    func testEligibilityReason_RawValues() {
        XCTAssertEqual(EligibilityReason.noAttemptsLeft.rawValue, "no_attempts_left")
        XCTAssertEqual(EligibilityReason.expired.rawValue, "expired")
        XCTAssertEqual(EligibilityReason.notEnrolled.rawValue, "not_enrolled")
        XCTAssertEqual(EligibilityReason.unknown.rawValue, "unknown")
    }
}
