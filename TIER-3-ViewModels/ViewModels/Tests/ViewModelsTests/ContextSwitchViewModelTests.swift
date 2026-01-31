import Foundation
import Testing
@testable import ViewModels
@testable import CQRS
import Models
import UseCases
import Roles
import EduGoCommon

/// Tests unitarios para ContextSwitchViewModel.
///
/// Este test suite valida:
/// - Carga de contextos disponibles
/// - Cambio de membership exitoso
/// - Cambio de escuela exitoso
/// - Validacion de membership disponible
/// - Actualizacion de RoleManager
/// - Computed properties
@Suite("ContextSwitchViewModel Tests")
struct ContextSwitchViewModelTests {

    // MARK: - Test Data

    let userId = UUID()
    let schoolId1 = UUID()
    let schoolId2 = UUID()
    let unitId1 = UUID()
    let unitId2 = UUID()
    let membershipId1 = UUID()
    let membershipId2 = UUID()

    // MARK: - Test: Carga de contextos exitosa

    @Test("Loads available contexts successfully")
    @MainActor
    func testLoadsContextsSuccessfully() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        let mockHandler = MockContextQueryHandler(
            userId: userId,
            schoolId: schoolId1,
            unitId: unitId1,
            membershipId: membershipId1
        )
        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        // Esperar a que cargue
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify
        #expect(viewModel.hasContexts)
        #expect(viewModel.membershipCount == 1)
        #expect(viewModel.currentContext != nil)
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
    }

    // MARK: - Test: Multiples memberships

    @Test("Loads multiple memberships correctly")
    @MainActor
    func testLoadsMultipleMemberships() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        let mockHandler = MockContextQueryHandlerMultiple(
            userId: userId,
            schoolIds: [schoolId1, schoolId2],
            unitIds: [unitId1, unitId2],
            membershipIds: [membershipId1, membershipId2]
        )
        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        // Esperar a que cargue
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify
        #expect(viewModel.membershipCount == 2)
        #expect(viewModel.canSwitchContext)
        #expect(viewModel.schoolCount == 2)
        #expect(viewModel.canSwitchSchool)
    }

    // MARK: - Test: Cambio de membership exitoso

    @Test("Switches membership successfully")
    @MainActor
    func testSwitchesMembershipSuccessfully() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        let mockQueryHandler = MockContextQueryHandlerMultiple(
            userId: userId,
            schoolIds: [schoolId1, schoolId2],
            unitIds: [unitId1, unitId2],
            membershipIds: [membershipId1, membershipId2]
        )
        try await mediator.registerQueryHandler(mockQueryHandler)

        let mockCommandHandler = MockSwitchContextCommandHandler(
            schoolId: schoolId2,
            unitId: unitId2,
            membershipId: membershipId2
        )
        try await mediator.registerCommandHandler(mockCommandHandler)

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        // Esperar carga inicial
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verificar estado inicial
        #expect(viewModel.currentMembershipId == membershipId1)

        // Execute: cambiar al segundo membership
        await viewModel.switchMembership(to: membershipId2)

        // Verify
        #expect(viewModel.switchSuccess)
        #expect(viewModel.currentMembershipId == membershipId2)
        #expect(!viewModel.isSwitching)
        #expect(viewModel.error == nil)
    }

    // MARK: - Test: Validacion de membership no disponible

    @Test("Validates unavailable membership")
    @MainActor
    func testValidatesUnavailableMembership() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        let mockHandler = MockContextQueryHandler(
            userId: userId,
            schoolId: schoolId1,
            unitId: unitId1,
            membershipId: membershipId1
        )
        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        // Esperar carga inicial
        try await Task.sleep(nanoseconds: 100_000_000)

        // Execute: intentar cambiar a un membership que no existe
        let unknownMembershipId = UUID()
        await viewModel.switchMembership(to: unknownMembershipId)

        // Verify
        #expect(viewModel.hasError)
        #expect(!viewModel.switchSuccess)
        #expect(viewModel.currentMembershipId == membershipId1) // No cambio
    }

    // MARK: - Test: No cambiar al mismo membership

    @Test("Does not switch to same membership")
    @MainActor
    func testDoesNotSwitchToSameMembership() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        let mockHandler = MockContextQueryHandler(
            userId: userId,
            schoolId: schoolId1,
            unitId: unitId1,
            membershipId: membershipId1
        )
        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        // Esperar carga inicial
        try await Task.sleep(nanoseconds: 100_000_000)

        // Execute: intentar cambiar al mismo membership
        await viewModel.switchMembership(to: membershipId1)

        // Verify: no error, pero tampoco isSwitching o switchSuccess
        #expect(!viewModel.hasError)
        #expect(!viewModel.switchSuccess) // No hubo cambio real
        #expect(!viewModel.isSwitching)
    }

    // MARK: - Test: Actualizacion de RoleManager

    @Test("Updates RoleManager on switch")
    @MainActor
    func testUpdatesRoleManagerOnSwitch() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        // Configurar rol inicial
        await roleManager.setRole(.student)
        let initialRole = await roleManager.getCurrentRole()
        #expect(initialRole == .student)

        let mockQueryHandler = MockContextQueryHandlerMultiple(
            userId: userId,
            schoolIds: [schoolId1, schoolId2],
            unitIds: [unitId1, unitId2],
            membershipIds: [membershipId1, membershipId2],
            roles: [.student, .teacher] // Segundo membership es teacher
        )
        try await mediator.registerQueryHandler(mockQueryHandler)

        let mockCommandHandler = MockSwitchContextCommandHandler(
            schoolId: schoolId2,
            unitId: unitId2,
            membershipId: membershipId2
        )
        try await mediator.registerCommandHandler(mockCommandHandler)

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        // Esperar carga inicial
        try await Task.sleep(nanoseconds: 100_000_000)

        // Execute: cambiar al membership de teacher
        await viewModel.switchMembership(to: membershipId2)

        // Verify: RoleManager fue actualizado
        let newRole = await roleManager.getCurrentRole()
        #expect(newRole == .teacher)
    }

    // MARK: - Test: Computed properties

    @Test("Computed properties work correctly")
    @MainActor
    func testComputedPropertiesWork() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        let mockHandler = MockContextQueryHandler(
            userId: userId,
            schoolId: schoolId1,
            unitId: unitId1,
            membershipId: membershipId1
        )
        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        // Esperar carga
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify
        #expect(viewModel.hasContexts)
        #expect(!viewModel.currentSchoolName.isEmpty)
        #expect(!viewModel.currentUnitName.isEmpty)
        #expect(!viewModel.currentRoleName.isEmpty)
        #expect(viewModel.currentMembership != nil)
        #expect(!viewModel.isBusy)
    }

    // MARK: - Test: Clear error

    @Test("Clear error works correctly")
    @MainActor
    func testClearErrorWorks() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        let mockHandler = MockContextQueryHandler(
            userId: userId,
            schoolId: schoolId1,
            unitId: unitId1,
            membershipId: membershipId1
        )
        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        // Esperar carga y provocar error
        try await Task.sleep(nanoseconds: 100_000_000)
        await viewModel.switchMembership(to: UUID()) // Membership no existente

        #expect(viewModel.hasError)

        // Execute
        viewModel.clearError()

        // Verify
        #expect(!viewModel.hasError)
    }

    // MARK: - Test: Reset state

    @Test("Reset clears all state")
    @MainActor
    func testResetClearsState() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        let mockHandler = MockContextQueryHandler(
            userId: userId,
            schoolId: schoolId1,
            unitId: unitId1,
            membershipId: membershipId1
        )
        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        // Esperar carga
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.hasContexts)

        // Execute
        viewModel.reset()

        // Verify
        #expect(!viewModel.hasContexts)
        #expect(viewModel.membershipCount == 0)
        #expect(viewModel.currentMembershipId == nil)
        #expect(viewModel.currentContext == nil)
    }

    // MARK: - Test: Refresh contexts

    @Test("Refresh forces reload from server")
    @MainActor
    func testRefreshForcesReload() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        let mockHandler = MockContextQueryHandler(
            userId: userId,
            schoolId: schoolId1,
            unitId: unitId1,
            membershipId: membershipId1
        )
        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        // Esperar carga inicial
        try await Task.sleep(nanoseconds: 100_000_000)

        let initialCallCount = await mockHandler.callCount

        // Execute refresh
        await viewModel.refresh()

        // Verify: Handler fue llamado de nuevo
        let newCallCount = await mockHandler.callCount
        #expect(newCallCount > initialCallCount)
    }

    // MARK: - Test: Switch school

    @Test("Switches school successfully")
    @MainActor
    func testSwitchesSchoolSuccessfully() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        let mockQueryHandler = MockContextQueryHandlerMultiple(
            userId: userId,
            schoolIds: [schoolId1, schoolId2],
            unitIds: [unitId1, unitId2],
            membershipIds: [membershipId1, membershipId2]
        )
        try await mediator.registerQueryHandler(mockQueryHandler)

        let mockCommandHandler = MockSwitchContextCommandHandler(
            schoolId: schoolId2,
            unitId: unitId2,
            membershipId: membershipId2
        )
        try await mediator.registerCommandHandler(mockCommandHandler)

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        // Esperar carga inicial
        try await Task.sleep(nanoseconds: 100_000_000)

        // Execute: cambiar de escuela
        await viewModel.switchSchool(to: schoolId2)

        // Verify
        #expect(viewModel.switchSuccess)
        #expect(viewModel.currentMembershipId == membershipId2)
    }

    // MARK: - Test: canSwitchContext when single membership

    @Test("Cannot switch context with single membership")
    @MainActor
    func testCannotSwitchWithSingleMembership() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        let mockHandler = MockContextQueryHandler(
            userId: userId,
            schoolId: schoolId1,
            unitId: unitId1,
            membershipId: membershipId1
        )
        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: userId
        )

        // Esperar carga
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify
        #expect(viewModel.membershipCount == 1)
        #expect(!viewModel.canSwitchContext) // Solo un membership
    }
}

// MARK: - Mock Handlers

/// Mock QueryHandler para GetUserContextQuery con un solo membership (para ContextSwitch)
actor MockContextQueryHandler: QueryHandler {
    typealias QueryType = GetUserContextQuery

    private(set) var callCount = 0
    private let userId: UUID
    private let schoolId: UUID
    private let unitId: UUID
    private let membershipId: UUID

    init(userId: UUID, schoolId: UUID, unitId: UUID, membershipId: UUID) {
        self.userId = userId
        self.schoolId = schoolId
        self.unitId = unitId
        self.membershipId = membershipId
    }

    func handle(_ query: GetUserContextQuery) async throws -> UserContext {
        callCount += 1

        let user = try User(
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@test.com",
            isActive: true
        )

        let membership = Membership(
            id: membershipId,
            userID: userId,
            unitID: unitId,
            role: .student,
            isActive: true
        )

        let unit = try AcademicUnit(
            id: unitId,
            displayName: "10th Grade",
            type: .grade,
            schoolID: schoolId
        )

        let school = try School(
            id: schoolId,
            name: "Test School",
            code: "TST-001",
            isActive: true
        )

        return UserContext(
            user: user,
            memberships: [membership],
            unitsMap: [unitId: unit],
            schoolsMap: [schoolId: school],
            partialErrors: []
        )
    }
}

/// Mock QueryHandler para GetUserContextQuery con multiples memberships (para ContextSwitch)
actor MockContextQueryHandlerMultiple: QueryHandler {
    typealias QueryType = GetUserContextQuery

    private(set) var callCount = 0
    private let userId: UUID
    private let schoolIds: [UUID]
    private let unitIds: [UUID]
    private let membershipIds: [UUID]
    private let roles: [MembershipRole]

    init(
        userId: UUID,
        schoolIds: [UUID],
        unitIds: [UUID],
        membershipIds: [UUID],
        roles: [MembershipRole] = [.student, .student]
    ) {
        self.userId = userId
        self.schoolIds = schoolIds
        self.unitIds = unitIds
        self.membershipIds = membershipIds
        self.roles = roles
    }

    func handle(_ query: GetUserContextQuery) async throws -> UserContext {
        callCount += 1

        let user = try User(
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@test.com",
            isActive: true
        )

        var memberships: [Membership] = []
        var unitsMap: [UUID: AcademicUnit] = [:]
        var schoolsMap: [UUID: School] = [:]

        for i in 0..<min(schoolIds.count, unitIds.count, membershipIds.count) {
            let membership = Membership(
                id: membershipIds[i],
                userID: userId,
                unitID: unitIds[i],
                role: i < roles.count ? roles[i] : .student,
                isActive: true
            )
            memberships.append(membership)

            let unit = try AcademicUnit(
                id: unitIds[i],
                displayName: "Unit \(i + 1)",
                type: .grade,
                schoolID: schoolIds[i]
            )
            unitsMap[unitIds[i]] = unit

            let school = try School(
                id: schoolIds[i],
                name: "School \(i + 1)",
                code: "SCH-00\(i + 1)",
                isActive: true
            )
            schoolsMap[schoolIds[i]] = school
        }

        return UserContext(
            user: user,
            memberships: memberships,
            unitsMap: unitsMap,
            schoolsMap: schoolsMap,
            partialErrors: []
        )
    }
}

/// Mock CommandHandler para SwitchContextCommand
actor MockSwitchContextCommandHandler: CommandHandler {
    typealias CommandType = SwitchContextCommand

    private(set) var callCount = 0
    private let schoolId: UUID
    private let unitId: UUID
    private let membershipId: UUID

    init(schoolId: UUID, unitId: UUID, membershipId: UUID) {
        self.schoolId = schoolId
        self.unitId = unitId
        self.membershipId = membershipId
    }

    func handle(_ command: SwitchContextCommand) async throws -> CommandResult<SwitchSchoolOutput> {
        callCount += 1

        let membership = Membership(
            id: membershipId,
            userID: command.userId,
            unitID: unitId,
            role: .teacher,
            isActive: true
        )

        let unit = try AcademicUnit(
            id: unitId,
            displayName: "Test Unit",
            type: .grade,
            schoolID: schoolId
        )

        let school = try School(
            id: schoolId,
            name: "New School",
            code: "NEW-001",
            isActive: true
        )

        let context = SwitchSchoolContext(
            activeMembership: membership,
            unit: unit,
            school: school
        )

        let output = SwitchSchoolOutput(
            newContext: context,
            previousMembershipId: UUID()
        )

        return .success(output, events: ["ContextSwitchedEvent"])
    }
}
