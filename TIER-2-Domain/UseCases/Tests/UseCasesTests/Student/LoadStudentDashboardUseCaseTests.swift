import XCTest
@testable import UseCases
import Models

// MARK: - Mock Repositories

/// Mock del repositorio de materiales para testing.
actor MockDashboardMaterialsRepository: DashboardMaterialsRepositoryProtocol {
    var mockMaterials: [Material] = []
    var mockError: Error?
    var callCount = 0
    var lastLimit: Int?
    var delay: TimeInterval = 0

    func setMaterials(_ materials: [Material]) {
        self.mockMaterials = materials
    }

    func setError(_ error: Error?) {
        self.mockError = error
    }

    func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }

    func listRecent(limit: Int) async throws -> [Material] {
        callCount += 1
        lastLimit = limit

        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if let error = mockError {
            throw error
        }
        return mockMaterials
    }
}

/// Mock del repositorio de progreso para testing.
actor MockDashboardProgressRepository: DashboardProgressRepositoryProtocol {
    var mockProgress: ProgressSummary?
    var mockError: Error?
    var callCount = 0
    var lastUserId: UUID?
    var delay: TimeInterval = 0

    func setProgress(_ progress: ProgressSummary?) {
        self.mockProgress = progress
    }

    func setError(_ error: Error?) {
        self.mockError = error
    }

    func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }

    func getSummary(userId: UUID) async throws -> ProgressSummary {
        callCount += 1
        lastUserId = userId

        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if let error = mockError {
            throw error
        }
        guard let progress = mockProgress else {
            throw TestError.noMockData
        }
        return progress
    }
}

/// Mock del repositorio de intentos para testing.
actor MockDashboardAttemptsRepository: DashboardAttemptsRepositoryProtocol {
    var mockAttempts: [AssessmentAttempt] = []
    var mockError: Error?
    var callCount = 0
    var lastUserId: UUID?
    var lastLimit: Int?
    var delay: TimeInterval = 0

    func setAttempts(_ attempts: [AssessmentAttempt]) {
        self.mockAttempts = attempts
    }

    func setError(_ error: Error?) {
        self.mockError = error
    }

    func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }

    func listRecent(userId: UUID, limit: Int) async throws -> [AssessmentAttempt] {
        callCount += 1
        lastUserId = userId
        lastLimit = limit

        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if let error = mockError {
            throw error
        }
        return mockAttempts
    }
}

/// Error para testing.
enum TestError: Error, LocalizedError {
    case noMockData
    case networkError
    case serverError

    var errorDescription: String? {
        switch self {
        case .noMockData:
            return "No mock data configured"
        case .networkError:
            return "Network error"
        case .serverError:
            return "Server error"
        }
    }
}

// MARK: - Test Fixtures

enum TestFixtures {
    static func createMaterial(
        id: UUID = UUID(),
        title: String = "Test Material"
    ) -> Material {
        // swiftlint:disable:next force_try
        try! Material(
            id: id,
            title: title,
            description: "Test description",
            status: .ready,
            fileURL: URL(string: "https://example.com/file.pdf"),
            fileType: "application/pdf",
            fileSizeBytes: 1024,
            schoolID: UUID(),
            academicUnitID: UUID(),
            uploadedByTeacherID: UUID(),
            subject: "Mathematics",
            grade: "10th",
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static func createProgressSummary(
        completed: Int = 5,
        inProgress: Int = 3,
        pending: Int = 2,
        averagePercentage: Double = 75.0
    ) -> ProgressSummary {
        ProgressSummary(
            completed: completed,
            inProgress: inProgress,
            pending: pending,
            averagePercentage: averagePercentage
        )
    }

    static func createAttempt(
        id: UUID = UUID(),
        materialId: UUID = UUID(),
        materialTitle: String = "Test Assessment",
        score: Int = 80,
        maxScore: Int = 100,
        passed: Bool = true
    ) -> AssessmentAttempt {
        AssessmentAttempt(
            id: id,
            materialId: materialId,
            materialTitle: materialTitle,
            score: score,
            maxScore: maxScore,
            passed: passed,
            completedAt: Date()
        )
    }
}

// MARK: - Tests

final class LoadStudentDashboardUseCaseTests: XCTestCase {

    var materialsRepo: MockDashboardMaterialsRepository!
    var progressRepo: MockDashboardProgressRepository!
    var attemptsRepo: MockDashboardAttemptsRepository!
    var sut: LoadStudentDashboardUseCase!

    override func setUp() async throws {
        try await super.setUp()
        materialsRepo = MockDashboardMaterialsRepository()
        progressRepo = MockDashboardProgressRepository()
        attemptsRepo = MockDashboardAttemptsRepository()
        sut = LoadStudentDashboardUseCase(
            materialsRepository: materialsRepo,
            progressRepository: progressRepo,
            attemptsRepository: attemptsRepo
        )
    }

    override func tearDown() async throws {
        materialsRepo = nil
        progressRepo = nil
        attemptsRepo = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Happy Path Tests

    func testExecute_WithAllDataAvailable_ReturnsDashboard() async throws {
        // Arrange
        let userId = UUID()
        let materials = [TestFixtures.createMaterial(), TestFixtures.createMaterial()]
        let progress = TestFixtures.createProgressSummary()
        let attempts = [TestFixtures.createAttempt(), TestFixtures.createAttempt()]

        await materialsRepo.setMaterials(materials)
        await progressRepo.setProgress(progress)
        await attemptsRepo.setAttempts(attempts)

        let input = LoadDashboardInput(userId: userId)

        // Act
        let dashboard = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(dashboard.recentMaterials.count, 2)
        XCTAssertNotNil(dashboard.progressSummary)
        XCTAssertEqual(dashboard.progressSummary?.completed, 5)
        XCTAssertEqual(dashboard.recentAttempts.count, 2)
        XCTAssertTrue(dashboard.metadata.partialFailures.isEmpty)
        XCTAssertGreaterThanOrEqual(dashboard.metadata.totalLoadTimeMs, 0)
    }

    func testExecute_WithoutProgress_ReturnsPartialDashboard() async throws {
        // Arrange
        let userId = UUID()
        let materials = [TestFixtures.createMaterial()]
        let attempts = [TestFixtures.createAttempt()]

        await materialsRepo.setMaterials(materials)
        await attemptsRepo.setAttempts(attempts)

        let input = LoadDashboardInput(userId: userId, includeProgress: false)

        // Act
        let dashboard = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(dashboard.recentMaterials.count, 1)
        XCTAssertNil(dashboard.progressSummary)
        XCTAssertEqual(dashboard.recentAttempts.count, 1)

        // Verify progress was not called
        let progressCallCount = await progressRepo.callCount
        XCTAssertEqual(progressCallCount, 0)
    }

    // MARK: - Graceful Degradation Tests

    func testExecute_WhenMaterialsFails_ReturnsDashboardWithEmptyMaterials() async throws {
        // Arrange
        let userId = UUID()
        let progress = TestFixtures.createProgressSummary()
        let attempts = [TestFixtures.createAttempt()]

        await materialsRepo.setError(TestError.networkError)
        await progressRepo.setProgress(progress)
        await attemptsRepo.setAttempts(attempts)

        let input = LoadDashboardInput(userId: userId)

        // Act
        let dashboard = try await sut.execute(input: input)

        // Assert
        XCTAssertTrue(dashboard.recentMaterials.isEmpty)
        XCTAssertNotNil(dashboard.progressSummary)
        XCTAssertEqual(dashboard.recentAttempts.count, 1)
        XCTAssertEqual(dashboard.metadata.partialFailures.count, 1)
        XCTAssertEqual(dashboard.metadata.partialFailures.first?.resourceType, .materials)
    }

    func testExecute_WhenProgressFails_ReturnsDashboardWithNilProgress() async throws {
        // Arrange
        let userId = UUID()
        let materials = [TestFixtures.createMaterial()]
        let attempts = [TestFixtures.createAttempt()]

        await materialsRepo.setMaterials(materials)
        await progressRepo.setError(TestError.serverError)
        await attemptsRepo.setAttempts(attempts)

        let input = LoadDashboardInput(userId: userId)

        // Act
        let dashboard = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(dashboard.recentMaterials.count, 1)
        XCTAssertNil(dashboard.progressSummary)
        XCTAssertEqual(dashboard.recentAttempts.count, 1)
        XCTAssertEqual(dashboard.metadata.partialFailures.count, 1)
        XCTAssertEqual(dashboard.metadata.partialFailures.first?.resourceType, .progress)
    }

    func testExecute_WhenAttemptsFails_ReturnsDashboardWithEmptyAttempts() async throws {
        // Arrange
        let userId = UUID()
        let materials = [TestFixtures.createMaterial()]
        let progress = TestFixtures.createProgressSummary()

        await materialsRepo.setMaterials(materials)
        await progressRepo.setProgress(progress)
        await attemptsRepo.setError(TestError.networkError)

        let input = LoadDashboardInput(userId: userId)

        // Act
        let dashboard = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(dashboard.recentMaterials.count, 1)
        XCTAssertNotNil(dashboard.progressSummary)
        XCTAssertTrue(dashboard.recentAttempts.isEmpty)
        XCTAssertEqual(dashboard.metadata.partialFailures.count, 1)
        XCTAssertEqual(dashboard.metadata.partialFailures.first?.resourceType, .attempts)
    }

    func testExecute_WhenTwoFetchesFail_StillReturnsDashboard() async throws {
        // Arrange
        let userId = UUID()
        let materials = [TestFixtures.createMaterial()]

        await materialsRepo.setMaterials(materials)
        await progressRepo.setError(TestError.networkError)
        await attemptsRepo.setError(TestError.serverError)

        let input = LoadDashboardInput(userId: userId)

        // Act
        let dashboard = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(dashboard.recentMaterials.count, 1)
        XCTAssertNil(dashboard.progressSummary)
        XCTAssertTrue(dashboard.recentAttempts.isEmpty)
        XCTAssertEqual(dashboard.metadata.partialFailures.count, 2)
    }

    func testExecute_WhenAllFetchesFail_ThrowsError() async throws {
        // Arrange
        let userId = UUID()

        await materialsRepo.setError(TestError.networkError)
        await progressRepo.setError(TestError.serverError)
        await attemptsRepo.setError(TestError.networkError)

        let input = LoadDashboardInput(userId: userId)

        // Act & Assert
        do {
            _ = try await sut.execute(input: input)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is UseCaseError)
        }
    }

    // MARK: - Cache Tests

    func testExecute_UsesCachedDashboard() async throws {
        // Arrange
        let userId = UUID()
        let materials = [TestFixtures.createMaterial()]
        let progress = TestFixtures.createProgressSummary()
        let attempts = [TestFixtures.createAttempt()]

        await materialsRepo.setMaterials(materials)
        await progressRepo.setProgress(progress)
        await attemptsRepo.setAttempts(attempts)

        let input = LoadDashboardInput(userId: userId)

        // Act - First call
        let dashboard1 = try await sut.execute(input: input)

        // Clear mocks to verify cache is used
        await materialsRepo.setMaterials([])
        await progressRepo.setProgress(nil)
        await attemptsRepo.setAttempts([])

        // Act - Second call (should use cache)
        let dashboard2 = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(dashboard1.recentMaterials.count, dashboard2.recentMaterials.count)
        XCTAssertEqual(dashboard1.progressSummary?.completed, dashboard2.progressSummary?.completed)

        // Verify repos were only called once
        let materialsCallCount = await materialsRepo.callCount
        let progressCallCount = await progressRepo.callCount
        let attemptsCallCount = await attemptsRepo.callCount

        XCTAssertEqual(materialsCallCount, 1)
        XCTAssertEqual(progressCallCount, 1)
        XCTAssertEqual(attemptsCallCount, 1)
    }

    func testInvalidateCache_ClearsUserCache() async throws {
        // Arrange
        let userId = UUID()
        let materials = [TestFixtures.createMaterial()]
        let progress = TestFixtures.createProgressSummary()
        let attempts = [TestFixtures.createAttempt()]

        await materialsRepo.setMaterials(materials)
        await progressRepo.setProgress(progress)
        await attemptsRepo.setAttempts(attempts)

        let input = LoadDashboardInput(userId: userId)

        // First call to populate cache
        _ = try await sut.execute(input: input)

        // Invalidate cache
        await sut.invalidateCache(for: userId)

        // Update mocks
        let newMaterials = [TestFixtures.createMaterial(), TestFixtures.createMaterial(), TestFixtures.createMaterial()]
        await materialsRepo.setMaterials(newMaterials)

        // Act - Should fetch fresh data
        let dashboard = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(dashboard.recentMaterials.count, 3)

        // Verify repos were called twice
        let materialsCallCount = await materialsRepo.callCount
        XCTAssertEqual(materialsCallCount, 2)
    }

    // MARK: - Parallel Execution Tests

    func testExecute_RunsFetchesInParallel() async throws {
        // Arrange
        let userId = UUID()
        let materials = [TestFixtures.createMaterial()]
        let progress = TestFixtures.createProgressSummary()
        let attempts = [TestFixtures.createAttempt()]

        // Set delays to verify parallel execution
        await materialsRepo.setMaterials(materials)
        await materialsRepo.setDelay(0.1)
        await progressRepo.setProgress(progress)
        await progressRepo.setDelay(0.1)
        await attemptsRepo.setAttempts(attempts)
        await attemptsRepo.setDelay(0.1)

        let input = LoadDashboardInput(userId: userId)

        // Act
        let startTime = Date()
        let dashboard = try await sut.execute(input: input)
        let elapsed = Date().timeIntervalSince(startTime)

        // Assert - If parallel, should take ~0.1s not ~0.3s
        XCTAssertLessThan(elapsed, 0.25, "Fetches should run in parallel")
        XCTAssertEqual(dashboard.recentMaterials.count, 1)
        XCTAssertNotNil(dashboard.progressSummary)
        XCTAssertEqual(dashboard.recentAttempts.count, 1)
    }

    // MARK: - Metadata Tests

    func testExecute_RecordsTimingMetadata() async throws {
        // Arrange
        let userId = UUID()
        let materials = [TestFixtures.createMaterial()]
        let progress = TestFixtures.createProgressSummary()
        let attempts = [TestFixtures.createAttempt()]

        await materialsRepo.setMaterials(materials)
        await progressRepo.setProgress(progress)
        await attemptsRepo.setAttempts(attempts)

        let input = LoadDashboardInput(userId: userId)

        // Act
        let dashboard = try await sut.execute(input: input)

        // Assert
        XCTAssertNotNil(dashboard.metadata.materialsLoadTimeMs)
        XCTAssertNotNil(dashboard.metadata.progressLoadTimeMs)
        XCTAssertNotNil(dashboard.metadata.attemptsLoadTimeMs)
        XCTAssertGreaterThanOrEqual(dashboard.metadata.totalLoadTimeMs, 0)
    }

    // MARK: - Input Validation Tests

    func testLoadDashboardInput_DefaultValues() {
        // Arrange & Act
        let userId = UUID()
        let input = LoadDashboardInput(userId: userId)

        // Assert
        XCTAssertEqual(input.userId, userId)
        XCTAssertTrue(input.includeProgress)
    }

    func testLoadDashboardInput_WithCustomValues() {
        // Arrange & Act
        let userId = UUID()
        let input = LoadDashboardInput(userId: userId, includeProgress: false)

        // Assert
        XCTAssertEqual(input.userId, userId)
        XCTAssertFalse(input.includeProgress)
    }

    // MARK: - Model Tests

    func testProgressSummary_Equality() {
        // Arrange
        let progress1 = ProgressSummary(completed: 5, inProgress: 3, pending: 2, averagePercentage: 75.0)
        let progress2 = ProgressSummary(completed: 5, inProgress: 3, pending: 2, averagePercentage: 75.0)
        let progress3 = ProgressSummary(completed: 10, inProgress: 3, pending: 2, averagePercentage: 75.0)

        // Assert
        XCTAssertEqual(progress1, progress2)
        XCTAssertNotEqual(progress1, progress3)
    }

    func testAssessmentAttempt_Identifiable() {
        // Arrange
        let id = UUID()
        let attempt = AssessmentAttempt(
            id: id,
            materialId: UUID(),
            materialTitle: "Test",
            score: 80,
            maxScore: 100,
            passed: true,
            completedAt: Date()
        )

        // Assert
        XCTAssertEqual(attempt.id, id)
    }

    func testDashboardMetadata_WithPartialFailures() {
        // Arrange
        let errors = [
            DashboardPartialError(resourceType: .materials, message: "Network error"),
            DashboardPartialError(resourceType: .progress, message: "Server error")
        ]

        let metadata = DashboardMetadata(
            materialsLoadTimeMs: nil,
            progressLoadTimeMs: nil,
            attemptsLoadTimeMs: 50,
            totalLoadTimeMs: 100,
            partialFailures: errors
        )

        // Assert
        XCTAssertNil(metadata.materialsLoadTimeMs)
        XCTAssertNil(metadata.progressLoadTimeMs)
        XCTAssertEqual(metadata.attemptsLoadTimeMs, 50)
        XCTAssertEqual(metadata.totalLoadTimeMs, 100)
        XCTAssertEqual(metadata.partialFailures.count, 2)
    }

    func testDashboardResourceType_RawValues() {
        // Assert
        XCTAssertEqual(DashboardResourceType.materials.rawValue, "materials")
        XCTAssertEqual(DashboardResourceType.progress.rawValue, "progress")
        XCTAssertEqual(DashboardResourceType.attempts.rawValue, "attempts")
    }
}
