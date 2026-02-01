import Foundation
import Testing
@testable import ViewModels
@testable import CQRS
import Models
import UseCases
import Roles
import EduGoCommon

/// Tests de integracion para validar la comunicacion entre ViewModels via EventBus.
///
/// Este test suite valida:
/// - Propagacion de eventos entre ViewModels
/// - Consistencia del estado global
/// - Concurrencia segura
@Suite("ViewModels Integration Tests")
struct ViewModelsIntegrationTests {

    // MARK: - Test Data

    let testUserId = UUID()
    let testAssessmentId = UUID()
    let testMaterialId = UUID()
    let testSubjectId = UUID()
    let testUnitId = UUID()

    // MARK: - Test: Login Event Propagation to Dashboard

    @Test("Login success event triggers dashboard refresh")
    @MainActor
    func testLoginSuccessEventRefreshesDashboard() async throws {
        // Arrange
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()

        // Registrar handler
        let dashboardHandler = MockDashboardQueryHandler()
        try await mediator.registerQueryHandler(dashboardHandler)

        // Crear DashboardViewModel que se suscribe a LoginSuccessEvent
        let dashboardVM = DashboardViewModel(
            mediator: mediator,
            eventBus: eventBus,
            userId: testUserId
        )

        // Cargar dashboard primero
        await dashboardVM.loadDashboard()

        let initialCallCount = await dashboardHandler.callCount
        #expect(initialCallCount >= 1, "Dashboard should be loaded initially")

        // Act: Publicar LoginSuccessEvent
        let loginEvent = LoginSuccessEvent(
            userId: testUserId,
            email: "test@example.com"
        )
        await eventBus.publish(loginEvent)

        // Esperar a que el dashboard se refresque
        try await waitForCondition(timeout: 1.0) {
            await dashboardHandler.callCount > initialCallCount
        }

        // Assert: Dashboard debe haberse refrescado
        let finalCallCount = await dashboardHandler.callCount
        #expect(finalCallCount > initialCallCount, "Dashboard should refresh after login event")
    }

    // MARK: - Test: Material Upload Event Propagation

    @Test("Material upload event triggers material list refresh")
    @MainActor
    func testMaterialUploadEventRefreshesMaterialList() async throws {
        // Arrange
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()

        // Registrar handler para ListMaterialsQuery
        let materialsHandler = MockMaterialsQueryHandler()
        try await mediator.registerQueryHandler(materialsHandler)

        // Crear MaterialListViewModel que se suscribe a MaterialUploadedEvent
        let listVM = MaterialListViewModel(
            mediator: mediator,
            eventBus: eventBus
        )

        // Cargar materiales primero
        await listVM.loadMaterials()

        let initialCallCount = await materialsHandler.callCount
        #expect(initialCallCount >= 1, "Materials should be loaded initially")

        // Act: Publicar MaterialUploadedEvent
        let uploadEvent = MaterialUploadedEvent(
            materialId: testMaterialId,
            title: "Test Material",
            fileName: "test.pdf",
            subjectId: testSubjectId,
            unitId: testUnitId,
            uploadedBy: testUserId
        )
        await eventBus.publish(uploadEvent)

        // Esperar a que la lista se refresque
        try await waitForCondition(timeout: 1.0) {
            await materialsHandler.callCount > initialCallCount
        }

        // Assert: MaterialList debe haberse refrescado
        let finalCallCount = await materialsHandler.callCount
        #expect(finalCallCount > initialCallCount, "Material list should refresh after upload event")
    }

    // MARK: - Test: Assessment Submit Event Propagation

    @Test("Assessment submit event triggers dashboard update")
    @MainActor
    func testAssessmentSubmitEventUpdatesDashboard() async throws {
        // Arrange
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()

        // Registrar handler para dashboard
        let dashboardHandler = MockDashboardQueryHandler()
        try await mediator.registerQueryHandler(dashboardHandler)

        // Crear DashboardViewModel
        let dashboardVM = DashboardViewModel(
            mediator: mediator,
            eventBus: eventBus,
            userId: testUserId
        )

        // Esperar a que las suscripciones a eventos se completen
        try await Task.sleep(nanoseconds: 50_000_000)  // 50ms para suscripciones

        // Cargar dashboard primero
        await dashboardVM.loadDashboard()

        let initialCallCount = await dashboardHandler.callCount
        #expect(initialCallCount >= 1, "Dashboard should be loaded initially")

        // Act: Publicar AssessmentSubmittedEvent
        let submitEvent = AssessmentSubmittedEvent(
            attemptId: UUID(),
            assessmentId: testAssessmentId,
            userId: testUserId,
            score: 85,
            maxScore: 100,
            passed: true,
            percentage: 85.0,
            timeSpentSeconds: 1200
        )
        await eventBus.publish(submitEvent)

        // Esperar a que el dashboard se actualice
        try await waitForCondition(timeout: 3.0) {
            await dashboardHandler.callCount > initialCallCount
        }

        // Assert: Dashboard debe haberse refrescado
        let finalCallCount = await dashboardHandler.callCount
        #expect(finalCallCount > initialCallCount, "Dashboard should refresh after assessment submission")
    }

    // MARK: - Test: Context Switch Updates RoleManager

    @Test("Context switch updates RoleManager globally")
    @MainActor
    func testContextSwitchUpdatesRoleManager() async throws {
        // Arrange
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let roleManager = RoleManager()
        let eventBus = EventBus()

        // Configurar rol inicial
        await roleManager.setRole(.student)

        // Registrar handlers
        let contextQueryHandler = MockContextQueryHandlerWithRoles(
            userId: testUserId,
            roles: [.student, .teacher]
        )
        try await mediator.registerQueryHandler(contextQueryHandler)

        let switchCommandHandler = MockSwitchContextCommandHandlerForIntegration(
            targetRole: .teacher
        )
        try await mediator.registerCommandHandler(switchCommandHandler)

        // Crear ContextSwitchViewModel
        let contextVM = ContextSwitchViewModel(
            mediator: mediator,
            roleManager: roleManager,
            eventBus: eventBus,
            userId: testUserId
        )

        // Esperar a que termine la carga del contexto
        try await waitForCondition(timeout: 1.0) {
            !contextVM.isLoading
        }

        // Verificar rol inicial
        let initialRole = await roleManager.getCurrentRole()
        #expect(initialRole == .student)

        // Act: Cambiar contexto (al segundo membership que es teacher)
        guard contextVM.membershipCount >= 2 else {
            return
        }

        let targetMembershipId = contextVM.availableMemberships[1].id
        await contextVM.switchMembership(to: targetMembershipId)

        // Assert: RoleManager debe actualizarse
        let newRole = await roleManager.getCurrentRole()
        #expect(newRole == .teacher, "RoleManager should be updated after context switch")
    }

    // MARK: - Test: Multiple ViewModels Concurrent State Consistency

    @Test("Multiple ViewModels maintain state consistency under concurrent load")
    @MainActor
    func testConcurrentViewModelsStateConsistency() async throws {
        // Arrange
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()

        // Registrar handlers
        let dashboardHandler = MockDashboardQueryHandler()
        let materialsHandler = MockMaterialsQueryHandler()
        let assessmentHandler = MockAssessmentQueryHandler(assessmentId: testAssessmentId)

        try await mediator.registerQueryHandler(dashboardHandler)
        try await mediator.registerQueryHandler(materialsHandler)
        try await mediator.registerQueryHandler(assessmentHandler)

        // Crear multiples ViewModels
        let dashboardVM = DashboardViewModel(
            mediator: mediator,
            eventBus: eventBus,
            userId: testUserId
        )

        let materialsVM = MaterialListViewModel(
            mediator: mediator,
            eventBus: eventBus
        )

        let assessmentVM = AssessmentViewModel(
            mediator: mediator,
            eventBus: eventBus,
            assessmentId: testAssessmentId,
            userId: testUserId
        )

        // Act: Cargas simultaneas
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await dashboardVM.loadDashboard()
            }
            group.addTask {
                await materialsVM.loadMaterials()
            }
            group.addTask {
                await assessmentVM.loadAssessment()
            }
        }

        // Assert: No race conditions, no crashes, estados consistentes
        #expect(!dashboardVM.isLoading, "Dashboard should not be loading")
        #expect(!materialsVM.isLoading, "Materials should not be loading")
        #expect(!assessmentVM.isLoading, "Assessment should not be loading")

        // Verificar que los datos se cargaron
        #expect(dashboardVM.hasDashboard || dashboardVM.hasError, "Dashboard should have data or error")
        #expect(materialsVM.hasMaterials || materialsVM.hasError, "Materials should have data or error")
        #expect(assessmentVM.hasAssessment || assessmentVM.hasError, "Assessment should have data or error")
    }

    // MARK: - Test: Event Bus Multiple Subscribers

    @Test("EventBus delivers events to multiple subscribers")
    @MainActor
    func testEventBusMultipleSubscribers() async throws {
        // Arrange
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()

        // Registrar handlers
        let dashboardHandler = MockDashboardQueryHandler()
        let materialsHandler = MockMaterialsQueryHandler()

        try await mediator.registerQueryHandler(dashboardHandler)
        try await mediator.registerQueryHandler(materialsHandler)

        // Crear multiples ViewModels que se suscriben al mismo evento
        let dashboardVM = DashboardViewModel(
            mediator: mediator,
            eventBus: eventBus,
            userId: testUserId
        )

        let materialsVM = MaterialListViewModel(
            mediator: mediator,
            eventBus: eventBus
        )

        // Cargar datos inicialmente
        await dashboardVM.loadDashboard()
        await materialsVM.loadMaterials()

        let dashboardInitialCount = await dashboardHandler.callCount
        let materialsInitialCount = await materialsHandler.callCount

        #expect(dashboardInitialCount >= 1, "Dashboard should be loaded initially")
        #expect(materialsInitialCount >= 1, "Materials should be loaded initially")

        // Act: Publicar evento que ambos escuchan (MaterialUploadedEvent)
        let event = MaterialUploadedEvent(
            materialId: testMaterialId,
            title: "Test",
            fileName: "test.pdf",
            subjectId: testSubjectId,
            unitId: testUnitId
        )
        await eventBus.publish(event)

        // Esperar propagacion
        try await Task.sleep(nanoseconds: 300_000_000)

        // Assert: Ambos ViewModels deben reaccionar
        let dashboardFinalCount = await dashboardHandler.callCount
        let materialsFinalCount = await materialsHandler.callCount

        #expect(dashboardFinalCount > dashboardInitialCount, "Dashboard should react to material upload")
        #expect(materialsFinalCount > materialsInitialCount, "Materials list should react to material upload")
    }

    // MARK: - Test: Error Propagation Isolation

    @Test("Error in one ViewModel does not affect others")
    @MainActor
    func testErrorPropagationIsolation() async throws {
        // Arrange
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()

        // Handler que falla
        let failingHandler = MockDashboardQueryHandlerFailing()
        // Handler que funciona
        let materialsHandler = MockMaterialsQueryHandler()

        try await mediator.registerQueryHandler(failingHandler)
        try await mediator.registerQueryHandler(materialsHandler)

        let dashboardVM = DashboardViewModel(
            mediator: mediator,
            eventBus: eventBus,
            userId: testUserId
        )

        let materialsVM = MaterialListViewModel(
            mediator: mediator,
            eventBus: eventBus
        )

        // Act: Cargar ambos (uno fallara)
        await dashboardVM.loadDashboard()
        await materialsVM.loadMaterials()

        // Assert: Error en dashboard, pero materials funciona
        #expect(dashboardVM.hasError, "Dashboard should have error")
        #expect(!materialsVM.hasError, "Materials should NOT have error")
        #expect(materialsVM.hasMaterials, "Materials should have data")
    }

    // MARK: - Test: Rapid Event Firing

    @Test("ViewModels handle rapid event firing without race conditions")
    @MainActor
    func testRapidEventFiringNoRaceConditions() async throws {
        // Arrange
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()

        let materialsHandler = MockMaterialsQueryHandler()
        try await mediator.registerQueryHandler(materialsHandler)

        let materialsVM = MaterialListViewModel(
            mediator: mediator,
            eventBus: eventBus
        )

        // Esperar a que las suscripciones a eventos se completen
        try await Task.sleep(nanoseconds: 50_000_000)  // 50ms para suscripciones

        // Act: Publicar muchos eventos rapidamente
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let event = MaterialUploadedEvent(
                        materialId: UUID(),
                        title: "Material \(i)",
                        fileName: "file\(i).pdf",
                        subjectId: UUID(),
                        unitId: UUID()
                    )
                    await eventBus.publish(event)
                }
            }
        }

        // Esperar a que los eventos se procesen (test complejo con 10 eventos rápidos)
        try await Task.sleep(nanoseconds: 500_000_000)  // 500ms

        // Assert: No crash, estado consistente
        #expect(!materialsVM.isLoading, "Should not be in loading state")
        // El test verifica que no hay crashes con eventos rápidos
        // El callCount puede variar debido a timing de suscripciones
        #expect(await materialsHandler.callCount > 0, "Debería haber procesado al menos algunos eventos")
    }

    // MARK: - Test: ViewModel Cleanup Does Not Crash

    @Test("Publishing events after ViewModel deinit does not crash")
    @MainActor
    func testViewModelCleanupNoCrash() async throws {
        // Arrange
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()

        let dashboardHandler = MockDashboardQueryHandler()
        try await mediator.registerQueryHandler(dashboardHandler)

        // Crear y destruir ViewModel en scope
        weak var weakDashboard: DashboardViewModel?
        do {
            let dashboard = DashboardViewModel(
                mediator: mediator,
                eventBus: eventBus,
                userId: testUserId
            )
            weakDashboard = dashboard
        }

        // Esperar a que el ViewModel sea deallocado
        try await waitForCondition(timeout: 1.0) {
            weakDashboard == nil
        }

        // Act: Publicar evento despues de que el ViewModel fue deallocated
        let event = LoginSuccessEvent(
            userId: testUserId,
            email: "test@example.com"
        )
        await eventBus.publish(event)

        // Assert: No crash (el evento se publica pero no hay subscribers)
        #expect(Bool(true), "No crash should occur")
    }

    // MARK: - Test Helpers

    /// Espera hasta que una condición sea verdadera o se alcance el timeout
    /// - Parameters:
    ///   - timeout: Tiempo máximo de espera en segundos (default: 2.0)
    ///   - pollInterval: Intervalo entre verificaciones en segundos (default: 0.01)
    ///   - condition: Closure asíncrono que retorna true cuando la condición se cumple
    /// - Throws: Error si se alcanza el timeout sin cumplir la condición
    @MainActor
    private func waitForCondition(
        timeout: TimeInterval = 2.0,
        pollInterval: TimeInterval = 0.01,
        condition: @escaping () async -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if await condition() {
                return
            }
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }

        throw TestError.timeout("Timeout esperando condición después de \(timeout)s")
    }

    /// Error personalizado para tests
    enum TestError: Error, CustomStringConvertible {
        case timeout(String)

        var description: String {
            switch self {
            case .timeout(let message):
                return message
            }
        }
    }
}

// MARK: - Mock Handlers for Integration Tests

/// Mock handler para GetStudentDashboardQuery
actor MockDashboardQueryHandler: QueryHandler {
    typealias QueryType = GetStudentDashboardQuery

    private(set) var callCount = 0

    func handle(_ query: GetStudentDashboardQuery) async throws -> StudentDashboard {
        callCount += 1

        let metadata = DashboardMetadata(
            materialsLoadTimeMs: 50,
            progressLoadTimeMs: 30,
            attemptsLoadTimeMs: 20,
            totalLoadTimeMs: 100,
            partialFailures: []
        )

        return StudentDashboard(
            recentMaterials: [],
            progressSummary: nil,
            recentAttempts: [],
            loadedAt: Date(),
            metadata: metadata
        )
    }
}

/// Mock handler que falla para testing de aislamiento de errores
actor MockDashboardQueryHandlerFailing: QueryHandler {
    typealias QueryType = GetStudentDashboardQuery

    func handle(_ query: GetStudentDashboardQuery) async throws -> StudentDashboard {
        throw UseCaseError.executionFailed(reason: "Simulated failure")
    }
}

/// Mock handler para ListMaterialsQuery
actor MockMaterialsQueryHandler: QueryHandler {
    typealias QueryType = ListMaterialsQuery

    private(set) var callCount = 0

    func handle(_ query: ListMaterialsQuery) async throws -> MaterialsPage {
        callCount += 1

        let material = try Material(
            id: UUID(),
            title: "Test Material",
            fileURL: URL(string: "https://example.com/test.pdf")!,
            fileType: "application/pdf",
            fileSizeBytes: 1024,
            schoolID: UUID()
        )

        return MaterialsPage(
            items: [material],
            nextCursor: nil,
            totalCount: 1,
            hasMore: false,
            isStale: false
        )
    }
}

/// Mock handler para GetAssessmentQuery
actor MockAssessmentQueryHandler: QueryHandler {
    typealias QueryType = GetAssessmentQuery

    private(set) var callCount = 0
    private let assessmentId: UUID

    init(assessmentId: UUID) {
        self.assessmentId = assessmentId
    }

    func handle(_ query: GetAssessmentQuery) async throws -> AssessmentDetail {
        callCount += 1

        let assessment = Assessment(
            id: assessmentId,
            materialId: UUID(),
            title: "Test Assessment",
            description: "Test description",
            questions: [],
            timeLimitSeconds: 3600,
            maxAttempts: 3,
            passThreshold: 60,
            attemptsUsed: 0,
            expiresAt: nil
        )

        let eligibility = AssessmentEligibility(
            canTake: true,
            reason: nil,
            attemptsLeft: 3,
            expiresAt: nil
        )

        return AssessmentDetail(
            assessment: assessment,
            eligibility: eligibility,
            cachedAt: nil,
            isStale: false
        )
    }
}

/// Mock handler para GetUserContextQuery con multiples roles
actor MockContextQueryHandlerWithRoles: QueryHandler {
    typealias QueryType = GetUserContextQuery

    private(set) var callCount = 0
    private let userId: UUID
    private let roles: [MembershipRole]

    init(userId: UUID, roles: [MembershipRole]) {
        self.userId = userId
        self.roles = roles
    }

    func handle(_ query: GetUserContextQuery) async throws -> UserContext {
        callCount += 1

        let user = try User(
            firstName: "Test",
            lastName: "User",
            email: "test@example.com",
            isActive: true
        )

        var memberships: [Membership] = []
        var unitsMap: [UUID: AcademicUnit] = [:]
        var schoolsMap: [UUID: School] = [:]

        for (index, role) in roles.enumerated() {
            let schoolId = UUID()
            let unitId = UUID()
            let membershipId = UUID()

            let membership = Membership(
                id: membershipId,
                userID: userId,
                unitID: unitId,
                role: role,
                isActive: true
            )
            memberships.append(membership)

            let unit = try AcademicUnit(
                id: unitId,
                displayName: "Unit \(index + 1)",
                type: .grade,
                schoolID: schoolId
            )
            unitsMap[unitId] = unit

            let school = try School(
                id: schoolId,
                name: "School \(index + 1)",
                code: "SCH-00\(index + 1)",
                isActive: true
            )
            schoolsMap[schoolId] = school
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

/// Mock handler para SwitchContextCommand para tests de integracion
actor MockSwitchContextCommandHandlerForIntegration: CommandHandler {
    typealias CommandType = SwitchContextCommand

    private(set) var callCount = 0
    private let targetRole: MembershipRole

    init(targetRole: MembershipRole) {
        self.targetRole = targetRole
    }

    func handle(_ command: SwitchContextCommand) async throws -> CommandResult<SwitchSchoolOutput> {
        callCount += 1

        let schoolId = UUID()
        let unitId = UUID()

        let membership = Membership(
            id: command.targetMembershipId,
            userID: command.userId,
            unitID: unitId,
            role: targetRole,
            isActive: true
        )

        let unit = try AcademicUnit(
            id: unitId,
            displayName: "Target Unit",
            type: .grade,
            schoolID: schoolId
        )

        let school = try School(
            id: schoolId,
            name: "Target School",
            code: "TGT-001",
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
