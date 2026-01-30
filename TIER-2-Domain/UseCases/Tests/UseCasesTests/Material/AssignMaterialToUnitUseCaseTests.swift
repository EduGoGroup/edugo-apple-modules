import XCTest
@testable import UseCases
import Models

// MARK: - Mock Repositories

actor MockAssignMaterialsRepository: AssignMaterialsRepositoryProtocol {
    var mockMaterial: Material?
    var mockError: Error?
    var existingAssignment: MaterialAssignmentDTO?
    var createdAssignment: MaterialAssignmentDTO?
    var createCallCount = 0

    func setMaterial(_ material: Material?) {
        self.mockMaterial = material
    }

    func setError(_ error: Error?) {
        self.mockError = error
    }

    func setExistingAssignment(_ assignment: MaterialAssignmentDTO?) {
        self.existingAssignment = assignment
    }

    func get(id: UUID) async throws -> Material {
        if let error = mockError {
            throw error
        }
        guard let material = mockMaterial else {
            throw AssignMaterialTestError.notFound
        }
        return material
    }

    func createAssignment(
        materialId: UUID,
        unitId: UUID,
        assignedBy: UUID,
        dueDate: Date?,
        visible: Bool
    ) async throws -> MaterialAssignmentDTO {
        createCallCount += 1
        let assignment = MaterialAssignmentDTO(
            id: UUID(),
            materialId: materialId,
            unitId: unitId,
            assignedBy: assignedBy,
            assignedAt: Date(),
            dueDate: dueDate,
            visible: visible
        )
        createdAssignment = assignment
        return assignment
    }

    func getExistingAssignment(materialId: UUID, unitId: UUID) async -> MaterialAssignmentDTO? {
        existingAssignment
    }
}

actor MockAssignUnitsRepository: AssignUnitsRepositoryProtocol {
    var mockUnit: UnitInfo?
    var mockStudents: [UUID] = []
    var mockError: Error?

    func setUnit(_ unit: UnitInfo?) {
        self.mockUnit = unit
    }

    func setStudents(_ students: [UUID]) {
        self.mockStudents = students
    }

    func setError(_ error: Error?) {
        self.mockError = error
    }

    func get(id: UUID) async throws -> UnitInfo {
        if let error = mockError {
            throw error
        }
        guard let unit = mockUnit else {
            throw AssignMaterialTestError.notFound
        }
        return unit
    }

    func listStudents(unitId: UUID) async throws -> [UUID] {
        mockStudents
    }
}

actor MockAssignMembershipsRepository: AssignMembershipsRepositoryProtocol {
    var hasPermission = true
    var mockUser: AssignerInfo?
    var mockError: Error?

    func setHasPermission(_ has: Bool) {
        self.hasPermission = has
    }

    func setUser(_ user: AssignerInfo?) {
        self.mockUser = user
    }

    func hasTeacherOrAdminRole(userId: UUID, unitId: UUID) async throws -> Bool {
        hasPermission
    }

    func getUserInfo(userId: UUID) async throws -> AssignerInfo {
        if let error = mockError {
            throw error
        }
        guard let user = mockUser else {
            throw AssignMaterialTestError.notFound
        }
        return user
    }
}

actor MockNotificationService: NotificationServiceProtocol {
    var shouldFail = false
    var delay: TimeInterval = 0
    var notifiedStudents: [UUID] = []

    func setShouldFail(_ fail: Bool) {
        self.shouldFail = fail
    }

    func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }

    func notifyStudent(
        studentId: UUID,
        materialTitle: String,
        unitName: String,
        dueDate: Date?
    ) async throws {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if shouldFail {
            throw AssignMaterialTestError.notificationFailed
        }
        notifiedStudents.append(studentId)
    }
}

enum AssignMaterialTestError: Error {
    case notFound
    case notificationFailed
}

// MARK: - Test Fixtures

enum AssignMaterialTestFixtures {
    static func createMaterial(
        id: UUID = UUID(),
        status: MaterialStatus = .ready
    ) -> Material {
        // swiftlint:disable:next force_try
        try! Material(
            id: id,
            title: "Test Material",
            description: "Test description",
            status: status,
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

    static func createUnit(id: UUID = UUID()) -> UnitInfo {
        UnitInfo(id: id, name: "Test Unit", schoolId: UUID())
    }

    static func createUser(id: UUID = UUID()) -> AssignerInfo {
        AssignerInfo(id: id, fullName: "John Teacher", email: "john@school.com")
    }

    static func createInput(
        materialId: UUID = UUID(),
        unitId: UUID = UUID(),
        assignedBy: UUID = UUID(),
        dueDate: Date? = nil,
        notifyStudents: Bool = false
    ) -> AssignMaterialInput {
        AssignMaterialInput(
            materialId: materialId,
            unitId: unitId,
            assignedBy: assignedBy,
            dueDate: dueDate,
            metadata: AssignmentMetadata(visible: true, notifyStudents: notifyStudents)
        )
    }
}

// MARK: - Tests

final class AssignMaterialToUnitUseCaseTests: XCTestCase {

    var materialsRepo: MockAssignMaterialsRepository!
    var unitsRepo: MockAssignUnitsRepository!
    var membershipsRepo: MockAssignMembershipsRepository!
    var notificationService: MockNotificationService!
    var sut: AssignMaterialToUnitUseCase!

    override func setUp() async throws {
        try await super.setUp()
        materialsRepo = MockAssignMaterialsRepository()
        unitsRepo = MockAssignUnitsRepository()
        membershipsRepo = MockAssignMembershipsRepository()
        notificationService = MockNotificationService()
        sut = AssignMaterialToUnitUseCase(
            materialsRepository: materialsRepo,
            unitsRepository: unitsRepo,
            membershipsRepository: membershipsRepo,
            notificationService: notificationService
        )
    }

    override func tearDown() async throws {
        materialsRepo = nil
        unitsRepo = nil
        membershipsRepo = nil
        notificationService = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Happy Path Tests

    func testExecute_CreatesAssignment() async throws {
        // Arrange
        let materialId = UUID()
        let unitId = UUID()
        let userId = UUID()

        await materialsRepo.setMaterial(
            AssignMaterialTestFixtures.createMaterial(id: materialId)
        )
        await unitsRepo.setUnit(AssignMaterialTestFixtures.createUnit(id: unitId))
        await membershipsRepo.setUser(AssignMaterialTestFixtures.createUser(id: userId))
        await membershipsRepo.setHasPermission(true)

        let input = AssignMaterialTestFixtures.createInput(
            materialId: materialId,
            unitId: unitId,
            assignedBy: userId
        )

        // Act
        let assignment = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(assignment.material.id, materialId)
        XCTAssertEqual(assignment.unit.id, unitId)
        XCTAssertEqual(assignment.assignedBy.id, userId)
        XCTAssertTrue(assignment.isVisible)
        XCTAssertFalse(assignment.wasAlreadyAssigned)
    }

    func testExecute_WithDueDate_SetsDate() async throws {
        // Arrange
        let dueDate = Date().addingTimeInterval(86400 * 7) // 1 week from now

        await materialsRepo.setMaterial(AssignMaterialTestFixtures.createMaterial())
        await unitsRepo.setUnit(AssignMaterialTestFixtures.createUnit())
        await membershipsRepo.setUser(AssignMaterialTestFixtures.createUser())

        let input = AssignMaterialTestFixtures.createInput(dueDate: dueDate)

        // Act
        let assignment = try await sut.execute(input: input)

        // Assert
        XCTAssertNotNil(assignment.dueDate)
    }

    // MARK: - Idempotency Tests

    func testExecute_WhenAlreadyAssigned_ReturnsExisting() async throws {
        // Arrange
        let materialId = UUID()
        let unitId = UUID()
        let existingId = UUID()

        await materialsRepo.setMaterial(
            AssignMaterialTestFixtures.createMaterial(id: materialId)
        )
        await unitsRepo.setUnit(AssignMaterialTestFixtures.createUnit(id: unitId))
        await membershipsRepo.setUser(AssignMaterialTestFixtures.createUser())

        let existingAssignment = MaterialAssignmentDTO(
            id: existingId,
            materialId: materialId,
            unitId: unitId,
            assignedBy: UUID(),
            assignedAt: Date().addingTimeInterval(-3600),
            dueDate: nil,
            visible: true
        )
        await materialsRepo.setExistingAssignment(existingAssignment)

        let input = AssignMaterialTestFixtures.createInput(
            materialId: materialId,
            unitId: unitId
        )

        // Act
        let assignment = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(assignment.id, existingId)
        XCTAssertTrue(assignment.wasAlreadyAssigned)

        let createCount = await materialsRepo.createCallCount
        XCTAssertEqual(createCount, 0) // Should not create new
    }

    // MARK: - Permission Tests

    func testExecute_WithoutPermission_ThrowsError() async throws {
        // Arrange
        await materialsRepo.setMaterial(AssignMaterialTestFixtures.createMaterial())
        await unitsRepo.setUnit(AssignMaterialTestFixtures.createUnit())
        await membershipsRepo.setUser(AssignMaterialTestFixtures.createUser())
        await membershipsRepo.setHasPermission(false)

        let unitId = UUID()
        let userId = UUID()
        let input = AssignMaterialTestFixtures.createInput(
            unitId: unitId,
            assignedBy: userId
        )

        // Act & Assert
        do {
            _ = try await sut.execute(input: input)
            XCTFail("Expected error")
        } catch let error as AssignMaterialError {
            if case .insufficientPermissions(let uId, let unId) = error {
                XCTAssertEqual(uId, userId)
                XCTAssertEqual(unId, unitId)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Material Validation Tests

    func testExecute_MaterialNotFound_ThrowsError() async throws {
        // Arrange
        await materialsRepo.setError(AssignMaterialTestError.notFound)
        await unitsRepo.setUnit(AssignMaterialTestFixtures.createUnit())
        await membershipsRepo.setUser(AssignMaterialTestFixtures.createUser())

        let materialId = UUID()
        let input = AssignMaterialTestFixtures.createInput(materialId: materialId)

        // Act & Assert
        do {
            _ = try await sut.execute(input: input)
            XCTFail("Expected error")
        } catch let error as AssignMaterialError {
            if case .materialNotFound(let id) = error {
                XCTAssertEqual(id, materialId)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testExecute_MaterialNotReady_ThrowsError() async throws {
        // Arrange
        let materialId = UUID()
        await materialsRepo.setMaterial(
            AssignMaterialTestFixtures.createMaterial(id: materialId, status: .processing)
        )
        await unitsRepo.setUnit(AssignMaterialTestFixtures.createUnit())
        await membershipsRepo.setUser(AssignMaterialTestFixtures.createUser())

        let input = AssignMaterialTestFixtures.createInput(materialId: materialId)

        // Act & Assert
        do {
            _ = try await sut.execute(input: input)
            XCTFail("Expected error")
        } catch let error as AssignMaterialError {
            if case .materialNotReady(let id, let status) = error {
                XCTAssertEqual(id, materialId)
                XCTAssertEqual(status, "processing")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Unit Validation Tests

    func testExecute_UnitNotFound_ThrowsError() async throws {
        // Arrange
        await materialsRepo.setMaterial(AssignMaterialTestFixtures.createMaterial())
        await unitsRepo.setError(AssignMaterialTestError.notFound)
        await membershipsRepo.setUser(AssignMaterialTestFixtures.createUser())

        let unitId = UUID()
        let input = AssignMaterialTestFixtures.createInput(unitId: unitId)

        // Act & Assert
        do {
            _ = try await sut.execute(input: input)
            XCTFail("Expected error")
        } catch let error as AssignMaterialError {
            if case .unitNotFound(let id) = error {
                XCTAssertEqual(id, unitId)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Due Date Validation Tests

    func testExecute_DueDateInPast_ThrowsError() async throws {
        // Arrange
        await materialsRepo.setMaterial(AssignMaterialTestFixtures.createMaterial())
        await unitsRepo.setUnit(AssignMaterialTestFixtures.createUnit())
        await membershipsRepo.setUser(AssignMaterialTestFixtures.createUser())

        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let input = AssignMaterialTestFixtures.createInput(dueDate: pastDate)

        // Act & Assert
        do {
            _ = try await sut.execute(input: input)
            XCTFail("Expected error")
        } catch let error as AssignMaterialError {
            if case .dueDateInPast = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Notification Tests

    func testExecute_WithNotifications_SendsToStudents() async throws {
        // Arrange
        let students = [UUID(), UUID(), UUID()]
        await materialsRepo.setMaterial(AssignMaterialTestFixtures.createMaterial())
        await unitsRepo.setUnit(AssignMaterialTestFixtures.createUnit())
        await unitsRepo.setStudents(students)
        await membershipsRepo.setUser(AssignMaterialTestFixtures.createUser())

        let input = AssignMaterialTestFixtures.createInput(notifyStudents: true)

        // Act
        _ = try await sut.execute(input: input)

        // Assert
        let notified = await notificationService.notifiedStudents
        XCTAssertEqual(notified.count, 3)

        let result = await sut.notificationResult
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalStudents, 3)
        XCTAssertEqual(result?.successCount, 3)
        XCTAssertEqual(result?.failedCount, 0)
    }

    func testExecute_NotificationFailures_DoNotBlockAssignment() async throws {
        // Arrange
        let students = [UUID(), UUID()]
        await materialsRepo.setMaterial(AssignMaterialTestFixtures.createMaterial())
        await unitsRepo.setUnit(AssignMaterialTestFixtures.createUnit())
        await unitsRepo.setStudents(students)
        await membershipsRepo.setUser(AssignMaterialTestFixtures.createUser())
        await notificationService.setShouldFail(true)

        let input = AssignMaterialTestFixtures.createInput(notifyStudents: true)

        // Act - Should NOT throw despite notification failures
        let assignment = try await sut.execute(input: input)

        // Assert - Assignment succeeded
        XCTAssertNotNil(assignment)

        let result = await sut.notificationResult
        XCTAssertEqual(result?.failedCount, 2)
        XCTAssertEqual(result?.failures.count, 2)
    }

    func testExecute_NotificationsDisabled_SkipsNotifications() async throws {
        // Arrange
        let students = [UUID(), UUID()]
        await materialsRepo.setMaterial(AssignMaterialTestFixtures.createMaterial())
        await unitsRepo.setUnit(AssignMaterialTestFixtures.createUnit())
        await unitsRepo.setStudents(students)
        await membershipsRepo.setUser(AssignMaterialTestFixtures.createUser())

        let input = AssignMaterialTestFixtures.createInput(notifyStudents: false)

        // Act
        _ = try await sut.execute(input: input)

        // Assert
        let notified = await notificationService.notifiedStudents
        XCTAssertTrue(notified.isEmpty)
    }

    // MARK: - Model Tests

    func testAssignmentMetadata_Default() {
        let metadata = AssignmentMetadata.default
        XCTAssertTrue(metadata.visible)
        XCTAssertTrue(metadata.notifyStudents)
    }

    func testMaterialAssignment_Properties() {
        let material = AssignMaterialTestFixtures.createMaterial()
        let unit = AssignMaterialTestFixtures.createUnit()
        let assigner = AssignMaterialTestFixtures.createUser()
        let dueDate = Date().addingTimeInterval(86400)

        let assignment = MaterialAssignment(
            id: UUID(),
            material: material,
            unit: unit,
            assignedAt: Date(),
            dueDate: dueDate,
            assignedBy: assigner,
            isVisible: true,
            wasAlreadyAssigned: false
        )

        XCTAssertEqual(assignment.material.id, material.id)
        XCTAssertEqual(assignment.unit.id, unit.id)
        XCTAssertEqual(assignment.assignedBy.id, assigner.id)
        XCTAssertNotNil(assignment.dueDate)
    }

    func testAssignMaterialError_LocalizedDescriptions() {
        let errors: [AssignMaterialError] = [
            .materialNotFound(UUID()),
            .materialNotReady(UUID(), currentStatus: "processing"),
            .unitNotFound(UUID()),
            .userNotFound(UUID()),
            .insufficientPermissions(userId: UUID(), unitId: UUID()),
            .dueDateInPast(Date()),
            .assignmentFailed("Test reason")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testNotificationResult_Skipped() {
        let result = NotificationResult.skipped
        XCTAssertEqual(result.totalStudents, 0)
        XCTAssertEqual(result.successCount, 0)
        XCTAssertEqual(result.failedCount, 0)
    }
}
