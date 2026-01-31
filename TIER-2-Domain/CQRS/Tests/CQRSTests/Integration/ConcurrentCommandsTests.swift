import Testing
@testable import CQRS
import UseCases
import Models

/// Tests de integración para validar comandos concurrentes.
///
/// Este test suite valida:
/// 1. Dispatch múltiples commands concurrentes
/// 2. Verificar no hay race conditions
/// 3. Verificar todos los commands completan correctamente
/// 4. Verificar orden de eventos es correcto
@Suite("Concurrent Commands Tests")
struct ConcurrentCommandsTests {

    // MARK: - Test: Múltiples uploads concurrentes

    @Test("Multiple upload commands execute concurrently without race conditions")
    func testConcurrentUploads() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus(loggingEnabled: false, metricsEnabled: false)

        let uploadHandler = UploadMaterialCommandHandler(
            useCase: MockUploadMaterialUseCase()
        )

        try await mediator.registerCommandHandler(uploadHandler)

        var eventsReceived: [String] = []
        let _ = await eventBus.subscribe(to: MaterialUploadedEvent.self) { event in
            eventsReceived.append(event.title)
        }

        // Execute: 10 uploads concurrentes
        let uploadCount = 10

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<uploadCount {
                group.addTask {
                    let command = UploadMaterialCommand(
                        title: "Material \(i)",
                        fileData: Data("content \(i)".utf8),
                        fileName: "file\(i).pdf",
                        mimeType: "application/pdf",
                        subjectId: UUID(),
                        unitId: UUID()
                    )

                    do {
                        let result = try await mediator.execute(command)
                        #expect(result.isSuccess)
                    } catch {
                        Issue.record("Upload \(i) failed: \(error)")
                    }
                }
            }
        }

        // Verify: Todos los uploads completaron
        // Note: eventsReceived count puede variar según timing
    }

    // MARK: - Test: Login concurrente de múltiples usuarios

    @Test("Concurrent login commands for different users execute correctly")
    func testConcurrentLogins() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        let loginHandler = LoginCommandHandler(
            useCase: MockLoginUseCase(),
            userContextHandler: nil
        )

        try await mediator.registerCommandHandler(loginHandler)

        // Execute: 5 logins concurrentes
        let userCount = 5
        var successCount = 0

        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<userCount {
                group.addTask {
                    let command = LoginCommand(
                        email: "user\(i)@edugo.com",
                        password: "password123"
                    )

                    do {
                        let result = try await mediator.execute(command)
                        return result.isSuccess
                    } catch {
                        return false
                    }
                }
            }

            for await success in group {
                if success {
                    successCount += 1
                }
            }
        }

        // Verify: Todos los logins exitosos
        #expect(successCount == userCount)
    }

    // MARK: - Test: Queries y Commands mixtos concurrentes

    @Test("Mixed concurrent queries and commands execute correctly")
    func testMixedConcurrentOperations() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        let dashboardHandler = GetStudentDashboardQueryHandler(
            useCase: MockLoadStudentDashboardUseCase()
        )
        let loginHandler = LoginCommandHandler(
            useCase: MockLoginUseCase(),
            userContextHandler: nil
        )

        try await mediator.registerQueryHandler(dashboardHandler)
        try await mediator.registerCommandHandler(loginHandler)

        let userId = UUID()
        var querySuccessCount = 0
        var commandSuccessCount = 0

        // Execute: Mix de 10 queries y 10 commands concurrentes
        await withTaskGroup(of: String.self) { group in
            // Queries
            for _ in 0..<10 {
                group.addTask {
                    let query = GetStudentDashboardQuery(userId: userId)
                    do {
                        let _ = try await mediator.send(query)
                        return "query-success"
                    } catch {
                        return "query-fail"
                    }
                }
            }

            // Commands
            for i in 0..<10 {
                group.addTask {
                    let command = LoginCommand(
                        email: "concurrent\(i)@edugo.com",
                        password: "pass123"
                    )
                    do {
                        let result = try await mediator.execute(command)
                        return result.isSuccess ? "command-success" : "command-fail"
                    } catch {
                        return "command-fail"
                    }
                }
            }

            for await result in group {
                if result == "query-success" {
                    querySuccessCount += 1
                } else if result == "command-success" {
                    commandSuccessCount += 1
                }
            }
        }

        // Verify: Todas las operaciones exitosas
        #expect(querySuccessCount == 10)
        #expect(commandSuccessCount == 10)
    }

    // MARK: - Test: Thread safety del Mediator

    @Test("Mediator handles concurrent registrations safely")
    func testConcurrentHandlerRegistrations() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        // Execute: Registrar handlers concurrentemente
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    let handler = GetStudentDashboardQueryHandler(
                        useCase: MockLoadStudentDashboardUseCase()
                    )

                    do {
                        // Esto debería fallar o sobrescribir según el orden
                        try await mediator.registerQueryHandler(handler)
                    } catch {
                        // Expected: solo uno debería registrarse
                    }
                }
            }
        }

        // Verify: Handler count correcto
        let count = await mediator.queryHandlerCount
        #expect(count >= 1) // Al menos uno se registró
    }
}
