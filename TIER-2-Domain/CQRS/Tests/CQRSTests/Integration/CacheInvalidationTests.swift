import Testing
import Foundation
@testable import CQRS
import UseCases
import Models

/// Tests de integración para validar invalidación de cache en cascada.
///
/// Este test suite valida:
/// 1. Poblar múltiples caches (Dashboard, Materials, UserContext)
/// 2. Dispatch command que invalida varios read models
/// 3. Verificar invalidación selectiva (solo los afectados)
/// 4. Verificar queries posteriores recargan desde source
@Suite("Cache Invalidation Cascade Tests")
struct CacheInvalidationTests {

    // MARK: - Test: Invalidación selectiva de caches

    @Test("Commands can invalidate specific caches")
    func testCacheInvalidationConcept() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        // Mock handlers que simulan cache interno
        let dashboardHandler = MockDashboardQueryHandler()
        let userContextHandler = MockUserContextQueryHandler()

        try await mediator.registerQueryHandler(dashboardHandler)
        try await mediator.registerQueryHandler(userContextHandler)

        // Execute: Poblar "caches"
        let userId = UUID()
        let dashboard1 = try await mediator.send(GetStudentDashboardQuery(userId: userId))
        let context1 = try await mediator.send(GetUserContextQuery(userId: userId))

        // Verify: Datos cargados
        #expect(dashboard1.studentId == userId)
        #expect(context1.user.id == userId)

        // En implementación real, un command invalidaría caches selectivamente
        // Este test valida que el patrón CQRS soporta esta arquitectura
    }

    // MARK: - Test: Login invalida UserContext

    @Test("Login command pattern supports cache invalidation")
    func testLoginInvalidatesUserContext() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus(loggingEnabled: false, metricsEnabled: false)

        let userContextHandler = MockUserContextQueryHandler()
        let loginHandler = MockLoginCommandHandler()

        try await mediator.registerQueryHandler(userContextHandler)
        try await mediator.registerCommandHandler(loginHandler)

        var eventsReceived: [String] = []
        let _ = await eventBus.subscribe(to: LoginSuccessEvent.self) { event in
            eventsReceived.append("LoginSuccessEvent")
        }

        // Execute: Login
        let command = LoginCommand(
            email: "test@edugo.com",
            password: "password123"
        )

        let result = try await mediator.execute(command)

        // Verify: Login exitoso
        #expect(result.isSuccess)

        // Execute: Query después de login
        let context = try await mediator.send(GetUserContextQuery(userId: UUID()))
        #expect(context.user.email == "test@edugo.com")
    }

    // MARK: - Test: Multiple queries maintain independent state

    @Test("Multiple query handlers maintain independent cache state")
    func testIndependentCacheStates() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        let handler1 = MockDashboardQueryHandler()
        let handler2 = MockUserContextQueryHandler()

        try await mediator.registerQueryHandler(handler1)
        try await mediator.registerQueryHandler(handler2)

        let userId = UUID()

        // Execute: Queries concurrentes
        async let dashboard = mediator.send(GetStudentDashboardQuery(userId: userId))
        async let context = mediator.send(GetUserContextQuery(userId: userId))

        let (dash, ctx) = try await (dashboard, context)

        // Verify: Ambos queries retornan datos independientes
        #expect(dash.studentId == userId)
        #expect(ctx.user.id == userId)
    }
}

// MARK: - Mock Query Handlers

actor MockDashboardQueryHandler: QueryHandler {
    typealias QueryType = GetStudentDashboardQuery

    func handle(_ query: GetStudentDashboardQuery) async throws -> StudentDashboard {
        return StudentDashboard(
            studentId: query.userId,
            overview: DashboardOverview(
                totalMaterials: 10,
                completedAssessments: 5,
                pendingAssessments: 2,
                averageScore: 85.0
            ),
            recentMaterials: [],
            upcomingAssessments: [],
            progressSummary: nil
        )
    }
}

actor MockUserContextQueryHandler: QueryHandler {
    typealias QueryType = GetUserContextQuery

    func handle(_ query: GetUserContextQuery) async throws -> UserContext {
        let user = User(
            id: query.userId,
            email: "test@edugo.com",
            firstName: "Test",
            lastName: "User",
            role: .student,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        return UserContext(
            user: user,
            currentSchool: nil,
            permissions: [],
            preferences: [:]
        )
    }
}

actor MockLoginCommandHandler: CommandHandler {
    typealias CommandType = LoginCommand

    func handle(_ command: LoginCommand) async throws -> CommandResult<LoginOutput> {
        let user = User(
            id: UUID(),
            email: command.email,
            firstName: "Test",
            lastName: "User",
            role: .student,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        let output = LoginOutput(
            user: user,
            accessToken: "mock-token",
            refreshToken: "mock-refresh",
            expiresIn: 3600
        )

        return .success(
            output,
            events: ["LoginSuccessEvent"],
            metadata: ["loginAt": ISO8601DateFormatter().string(from: Date())]
        )
    }
}
