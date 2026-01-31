import Testing
import Foundation
@testable import CQRS
import UseCases
import Models
import EduGoCommon

// MARK: - Suite de Tests de Concurrencia

@Suite("Concurrency Tests with DI")
struct ConcurrencyTests {

    // MARK: - Tests de Concurrencia en Commands

    @Test("Multiple concurrent login commands don't interfere")
    func testConcurrentLogins() async throws {
        // Arrange
        let mockUseCase = MockLoginUseCase()
        let handler = LoginCommandHandler(useCase: mockUseCase)

        // Act: Ejecutar 5 logins concurrentes con TaskGroup
        try await withThrowingTaskGroup(of: CommandResult<LoginOutput>.self) { group in
            for i in 0..<5 {
                let command = LoginCommand(
                    email: "user\(i)@edugo.com",
                    password: "password\(i)123"
                )
                group.addTask {
                    try await handler.handle(command)
                }
            }

            // Verificar que todos completan exitosamente
            var results: [LoginOutput] = []
            for try await commandResult in group {
                // Extraer el LoginOutput del CommandResult
                let output = try commandResult.result.get()
                results.append(output)
            }

            #expect(results.count == 5)
        }

        // Assert: Verificar executionCount
        let executionCount = await mockUseCase.getExecutionCount()
        #expect(executionCount == 5)
    }

    @Test("Concurrent uploads don't corrupt state")
    func testConcurrentUploads() async throws {
        // Arrange
        let mockUseCase = MockUploadMaterialUseCase()
        let handler = UploadMaterialCommandHandler(useCase: mockUseCase)
        let subjectId = UUID()
        let unitId = UUID()

        // Act: Subir 10 materiales concurrentemente
        try await withThrowingTaskGroup(of: CommandResult<Material>.self) { group in
            for i in 0..<10 {
                let command = UploadMaterialCommand(
                    fileURL: URL(string: "file:///tmp/file\(i).pdf")!,
                    title: "Material \(i)",
                    subjectId: subjectId,
                    unitId: unitId
                )
                group.addTask {
                    try await handler.handle(command)
                }
            }

            // Recolectar resultados
            var uploadedMaterials: [Material] = []
            for try await commandResult in group {
                // Extraer el Material del CommandResult
                let material = try commandResult.result.get()
                uploadedMaterials.append(material)
            }

            // Assert: Verificar que todos tienen IDs únicos
            let uniqueIDs = Set(uploadedMaterials.map { $0.id })
            #expect(uniqueIDs.count == 10)

            // Assert: Verificar que todos tienen títulos correctos
            let titles = Set(uploadedMaterials.map { $0.title })
            #expect(titles.count == 10)
        }

        // Assert: Verificar uploadedCount
        let uploadedCount = await mockUseCase.getUploadedCount()
        #expect(uploadedCount == 10)
    }

    // MARK: - Tests de Concurrencia en Queries con Cache

    @Test("Concurrent dashboard queries use cache efficiently")
    func testConcurrentDashboardQueries() async throws {
        // Arrange
        let mockUseCase = MockLoadStudentDashboardUseCase()
        let handler = GetStudentDashboardQueryHandler(useCase: mockUseCase)
        let userId = UUID()

        // Act PASO 1: Primera query para llenar el cache
        let initialQuery = GetStudentDashboardQuery(userId: userId)
        _ = try await handler.handle(initialQuery)

        // Esperar un poco para asegurar que el cache se estableció
        try await Task.sleep(for: .milliseconds(30))

        // Act PASO 2: 20 queries concurrentes que deberían usar el cache
        try await withThrowingTaskGroup(of: StudentDashboard.self) { group in
            for _ in 0..<20 {
                let query = GetStudentDashboardQuery(userId: userId)
                group.addTask {
                    try await handler.handle(query)
                }
            }

            // Recolectar resultados
            var dashboards: [StudentDashboard] = []
            for try await dashboard in group {
                dashboards.append(dashboard)
            }

            // Assert: Todos los dashboards deben ser iguales (mismo userId)
            #expect(dashboards.count == 20)
            let uniqueLoadedAt = Set(dashboards.map { $0.loadedAt })
            // Con cache, todos deberían tener el mismo loadedAt
            #expect(uniqueLoadedAt.count == 1)
        }

        // Assert: Verificar que useCase.executionCount == 1 (solo la query inicial, las demás usaron cache)
        let executionCount = await mockUseCase.getExecutionCount()
        #expect(executionCount == 1)
    }

    @Test("Concurrent different user queries don't share cache")
    func testConcurrentDifferentUserQueries() async throws {
        // Arrange
        let mockUseCase = MockLoadStudentDashboardUseCase()
        let handler = GetStudentDashboardQueryHandler(useCase: mockUseCase)

        // Crear 5 usuarios diferentes
        let userIds = (0..<5).map { _ in UUID() }

        // Act: Queries para 5 usuarios diferentes
        try await withThrowingTaskGroup(of: StudentDashboard.self) { group in
            for userId in userIds {
                let query = GetStudentDashboardQuery(userId: userId)
                group.addTask {
                    try await handler.handle(query)
                }
            }

            // Recolectar resultados
            var dashboards: [StudentDashboard] = []
            for try await dashboard in group {
                dashboards.append(dashboard)
            }

            // Assert: Deben haberse ejecutado 5 queries (sin cache compartido)
            #expect(dashboards.count == 5)
        }

        // Assert: Verificar executionCount == 5 (sin cache compartido)
        let executionCount = await mockUseCase.getExecutionCount()
        #expect(executionCount == 5)
    }

    @Test("Cache invalidation during concurrent reads is safe")
    func testCacheInvalidationDuringConcurrentReads() async throws {
        // Arrange
        let mockUseCase = MockLoadStudentDashboardUseCase()
        let handler = GetStudentDashboardQueryHandler(useCase: mockUseCase)
        let userId = UUID()

        // Act: Queries concurrentes + invalidación de cache en paralelo
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Task 1-10: Queries concurrentes
            for _ in 0..<10 {
                let query = GetStudentDashboardQuery(userId: userId)
                group.addTask {
                    _ = try await handler.handle(query)
                }
            }

            // Task 11: Invalidar cache durante las queries
            group.addTask {
                try await Task.sleep(for: .milliseconds(5))
                await mockUseCase.invalidateCache(for: userId)
            }

            // Esperar a que todas completen sin crashes
            try await group.waitForAll()
        }

        // Assert: No debe haber race conditions ni crashes
        // Si llegamos aquí, el test pasó (no hubo crashes)
        let executionCount = await mockUseCase.getExecutionCount()
        #expect(executionCount > 0)
    }
}

// MARK: - Mock UseCases

/// Mock del LoginUseCase con tracking de ejecuciones.
actor MockLoginUseCase: LoginUseCaseProtocol {

    // Estado interno
    private var _executionCount = 0

    // Método público para obtener el contador desde tests
    func getExecutionCount() -> Int {
        _executionCount
    }

    func execute(input: LoginInput) async throws -> LoginOutput {
        _executionCount += 1

        // Simular delay realista de red
        try await Task.sleep(for: .milliseconds(10))

        // Crear User usando constructor real
        let user = try User(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: input.email,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Crear LoginOutput con campos reales
        return LoginOutput(
            user: user,
            accessToken: "mock_access_token_\(_executionCount)",
            refreshToken: "mock_refresh_token_\(_executionCount)"
        )
    }
}

/// Mock del UploadMaterialUseCase con tracking de subidas.
actor MockUploadMaterialUseCase: UploadMaterialUseCaseProtocol {

    // Estado interno
    private var _uploadedCount = 0

    // Método público para obtener el contador desde tests
    func getUploadedCount() -> Int {
        _uploadedCount
    }

    func execute(input: UploadMaterialInput) async throws -> Material {
        _uploadedCount += 1

        // Simular delay de upload
        try await Task.sleep(for: .milliseconds(15))

        // Crear Material usando constructor real
        // Nota: Como input no tiene schoolID directamente, usamos un mock ID
        let mockSchoolID = UUID()
        return try Material(
            id: UUID(),
            title: input.title,
            description: input.description,
            status: .uploaded,
            fileURL: input.fileURL,
            fileType: "application/pdf",
            fileSizeBytes: 1024,
            schoolID: mockSchoolID,
            academicUnitID: input.unitId,
            uploadedByTeacherID: nil,
            subject: nil,
            grade: nil,
            isPublic: false,
            processingStartedAt: nil,
            processingCompletedAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )
    }

    func executeWithProgress(input: UploadMaterialInput) async throws -> (material: Material, progress: AsyncStream<UploadProgress>) {
        // Para simplificar, delegamos a execute()
        let material = try await execute(input: input)

        // Stream de progreso simulado
        let stream = AsyncStream<UploadProgress> { continuation in
            Task {
                continuation.yield(.validating)
                continuation.yield(.creating)
                continuation.yield(.uploading(progress: 50))
                continuation.yield(.uploading(progress: 100))
                continuation.yield(.processing)
                continuation.yield(.ready)
                continuation.finish()
            }
        }

        return (material, stream)
    }
}

/// Mock del LoadStudentDashboardUseCase con cache y tracking.
actor MockLoadStudentDashboardUseCase: LoadStudentDashboardUseCaseProtocol {

    // Estado interno
    private var _executionCount = 0
    private var _cache: [UUID: CacheEntry] = [:]
    private let _cacheDuration: TimeInterval = 120 // 2 minutos

    // Método público para obtener el contador desde tests
    func getExecutionCount() -> Int {
        _executionCount
    }

    // Método público para invalidar cache desde tests
    func invalidateCache(for userId: UUID) {
        _cache.removeValue(forKey: userId)
    }

    func execute(input: LoadDashboardInput) async throws -> StudentDashboard {
        // Verificar cache primero
        if let cached = _cache[input.userId],
           Date().timeIntervalSince(cached.timestamp) < _cacheDuration {
            return cached.dashboard
        }

        _executionCount += 1

        // Simular delay de carga
        try await Task.sleep(for: .milliseconds(20))

        // Crear componentes del dashboard usando constructores reales
        let schoolID = UUID()

        // Crear material de ejemplo
        let material = try Material(
            id: UUID(),
            title: "Example Material",
            description: "Test material",
            status: .ready,
            fileURL: URL(string: "https://example.com/file.pdf"),
            fileType: "application/pdf",
            fileSizeBytes: 2048,
            schoolID: schoolID,
            academicUnitID: nil,
            uploadedByTeacherID: nil,
            subject: "Mathematics",
            grade: "10th Grade",
            isPublic: false,
            processingStartedAt: nil,
            processingCompletedAt: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )

        // Crear ProgressSummary
        let progressSummary = ProgressSummary(
            completed: 5,
            inProgress: 3,
            pending: 2,
            averagePercentage: 0.75
        )

        // Crear DashboardMetadata
        let metadata = DashboardMetadata(
            materialsLoadTimeMs: 50,
            progressLoadTimeMs: 30,
            attemptsLoadTimeMs: 20,
            totalLoadTimeMs: 100,
            partialFailures: []
        )

        // Crear StudentDashboard
        let dashboard = StudentDashboard(
            recentMaterials: [material],
            progressSummary: progressSummary,
            recentAttempts: [],
            loadedAt: Date(),
            metadata: metadata
        )

        // Cachear resultado
        _cache[input.userId] = CacheEntry(dashboard: dashboard, timestamp: Date())

        return dashboard
    }

    // MARK: - Helper Types

    private struct CacheEntry {
        let dashboard: StudentDashboard
        let timestamp: Date
    }
}
