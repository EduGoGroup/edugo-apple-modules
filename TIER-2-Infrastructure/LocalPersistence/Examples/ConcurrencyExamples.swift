import Foundation
@testable import LocalPersistence

// MARK: - Concurrency Examples
// Ejemplos ejecutables de patrones de concurrencia con TaskGroupCoordinator

/// Este archivo contiene ejemplos de código que demuestran el uso correcto
/// de TaskGroupCoordinator y patrones de concurrencia relacionados.
///
/// Para ejecutar estos ejemplos, importa este archivo en un playground
/// o incluye en un test target.

// MARK: - Example 1: Basic Batch Operations

/// Ejemplo básico de operaciones batch
enum BasicBatchExample {

    /// Ejecuta múltiples operaciones en paralelo y retorna todos los resultados
    static func fetchAllUsers(ids: [UUID], repository: LocalUserRepository) async throws -> [User] {
        let coordinator = TaskGroupCoordinator<User>()

        // Crear operaciones @Sendable para cada ID
        let operations: [@Sendable () async throws -> User] = ids.map { id in
            {
                guard let user = try await repository.get(id: id) else {
                    throw ExampleError.userNotFound(id: id)
                }
                return user
            }
        }

        // Ejecutar todas en paralelo
        return try await coordinator.executeBatch(operations)
    }

    /// Ejemplo de uso
    static func demo() async {
        print("=== Basic Batch Example ===")

        // Simular IDs de usuarios
        let userIDs = (0..<10).map { _ in UUID() }

        print("Fetching \(userIDs.count) users...")
        // let users = try await fetchAllUsers(ids: userIDs, repository: repository)
        // print("Fetched \(users.count) users")
    }
}

// MARK: - Example 2: Partial Failure Handling

/// Ejemplo de manejo de fallos parciales
enum PartialFailureExample {

    /// Ejecuta operaciones y captura tanto éxitos como fallos
    static func syncDocuments(
        documents: [Document],
        repository: LocalDocumentRepository
    ) async -> SyncResult {
        let coordinator = TaskGroupCoordinator<UUID>()

        let operations: [@Sendable () async throws -> UUID] = documents.map { document in
            {
                try await repository.save(document)
                return document.id
            }
        }

        let result = await coordinator.executeBatchCollecting(operations)

        return SyncResult(
            syncedIDs: result.values,
            failedCount: result.failures.count,
            errors: result.errors.map { $0.description }
        )
    }

    struct SyncResult {
        let syncedIDs: [UUID]
        let failedCount: Int
        let errors: [String]

        var successRate: Double {
            let total = syncedIDs.count + failedCount
            guard total > 0 else { return 0 }
            return Double(syncedIDs.count) / Double(total)
        }
    }

    /// Ejemplo de uso
    static func demo() async {
        print("\n=== Partial Failure Example ===")
        print("Syncing documents with potential failures...")

        // Simular resultado
        let mockResult = SyncResult(
            syncedIDs: [UUID(), UUID(), UUID()],
            failedCount: 1,
            errors: ["Network timeout"]
        )

        print("Success rate: \(mockResult.successRate * 100)%")
        print("Synced: \(mockResult.syncedIDs.count)")
        print("Failed: \(mockResult.failedCount)")
    }
}

// MARK: - Example 3: Rate Limited Operations

/// Ejemplo de operaciones con límite de concurrencia
enum RateLimitedExample {

    /// Ejecuta operaciones con un máximo de operaciones concurrentes
    static func downloadFiles(
        urls: [URL],
        maxConcurrent: Int = 5
    ) async throws -> [Data] {
        let coordinator = TaskGroupCoordinator<Data>()

        let operations: [@Sendable () async throws -> Data] = urls.map { url in
            {
                // Simular descarga
                try await Task.sleep(for: .milliseconds(100))
                return Data() // En producción: URLSession.shared.data(from: url)
            }
        }

        // Máximo 5 descargas simultáneas
        return try await coordinator.executeBatch(
            operations,
            maxConcurrency: maxConcurrent
        )
    }

    /// Ejemplo de uso
    static func demo() async {
        print("\n=== Rate Limited Example ===")

        let urls = (0..<20).map { URL(string: "https://example.com/file\($0)")! }
        print("Downloading \(urls.count) files with max 5 concurrent...")

        do {
            let startTime = ContinuousClock.now
            let data = try await downloadFiles(urls: urls, maxConcurrent: 5)
            let elapsed = ContinuousClock.now - startTime

            print("Downloaded \(data.count) files in \(elapsed)")
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - Example 4: Timeout Handling

/// Ejemplo de manejo de timeouts
enum TimeoutExample {

    /// Ejecuta operación con timeout y cleanup
    static func fetchWithTimeout<T: Sendable>(
        timeout: Duration,
        cleanup: @escaping @Sendable () async -> Void,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let handler = CancellationHandler()

        return try await handler.withTimeout(
            timeout,
            onCancellation: cleanup
        ) {
            try await operation()
        }
    }

    /// Ejemplo de operación larga con timeout
    static func processLargeDataset(data: [Int]) async throws -> [Int] {
        try await fetchWithTimeout(
            timeout: .seconds(30),
            cleanup: {
                print("Cleanup: Removing temporary files...")
            }
        ) {
            // Procesamiento largo
            var results: [Int] = []
            for item in data {
                try Task.checkCancellation()
                results.append(item * 2)
            }
            return results
        }
    }

    /// Ejemplo de uso
    static func demo() async {
        print("\n=== Timeout Example ===")

        do {
            let result = try await processLargeDataset(data: Array(0..<100))
            print("Processed \(result.count) items")
        } catch let error as CancellationReason {
            switch error {
            case .timeout(let duration):
                print("Timeout after \(duration)s")
            default:
                print("Cancelled: \(error)")
            }
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - Example 5: Retry with Exponential Backoff

/// Ejemplo de reintentos con backoff exponencial
enum RetryExample {

    /// Ejecuta operación con reintentos automáticos
    static func fetchWithRetry<T: Sendable>(
        maxAttempts: Int = 3,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let coordinator = TaskGroupCoordinator<T>()

        return try await coordinator.executeWithRetry(
            maxAttempts: maxAttempts,
            strategy: .exponential(
                baseDelay: .seconds(1),
                maxDelay: .seconds(30),
                maxAttempts: maxAttempts
            ),
            operation: operation
        )
    }

    /// Simula una operación que puede fallar temporalmente
    static func unreliableAPICall() async throws -> String {
        // Simular 70% de probabilidad de éxito
        let random = Int.random(in: 0..<10)
        if random < 3 {
            throw ExampleError.temporaryFailure
        }
        return "Success!"
    }

    /// Ejemplo de uso
    static func demo() async {
        print("\n=== Retry Example ===")

        do {
            let result = try await fetchWithRetry(maxAttempts: 5) {
                try await unreliableAPICall()
            }
            print("Result: \(result)")
        } catch let error as TaskGroupError {
            if case .maxRetriesExceeded(let attempts, _) = error {
                print("Failed after \(attempts) attempts")
            }
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - Example 6: Cancellation Handling

/// Ejemplo de manejo de cancelación
enum CancellationExample {

    actor DownloadManager {
        private var currentTask: Task<[Data], Error>?

        func startDownloads(urls: [URL]) async throws -> [Data] {
            let coordinator = TaskGroupCoordinator<Data>()

            let operations: [@Sendable () async throws -> Data] = urls.map { url in
                {
                    // Verificar cancelación antes de cada operación
                    try Task.checkCancellation()

                    // Simular descarga
                    try await Task.sleep(for: .milliseconds(500))

                    // Verificar cancelación después
                    try Task.checkCancellation()

                    return Data()
                }
            }

            currentTask = Task {
                try await coordinator.executeBatch(operations)
            }

            return try await currentTask!.value
        }

        func cancelDownloads() {
            currentTask?.cancel()
            currentTask = nil
        }
    }

    /// Ejemplo de uso
    static func demo() async {
        print("\n=== Cancellation Example ===")

        let manager = DownloadManager()
        let urls = (0..<10).map { URL(string: "https://example.com/\($0)")! }

        // Iniciar descargas en background
        let downloadTask = Task {
            try await manager.startDownloads(urls: urls)
        }

        // Cancelar después de un momento
        try? await Task.sleep(for: .milliseconds(200))
        await manager.cancelDownloads()

        do {
            let results = try await downloadTask.value
            print("Downloaded \(results.count) files")
        } catch is CancellationError {
            print("Downloads were cancelled")
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - Example 7: Mixed Success/Failure Processing

/// Ejemplo de procesamiento con resultados mixtos
enum MixedResultsExample {

    struct ProcessingResult {
        let processed: [String]
        let failed: [(index: Int, reason: String)]

        var summary: String {
            """
            Processing Summary:
            - Successful: \(processed.count)
            - Failed: \(failed.count)
            - Success Rate: \(String(format: "%.1f", successRate * 100))%
            """
        }

        var successRate: Double {
            let total = processed.count + failed.count
            guard total > 0 else { return 0 }
            return Double(processed.count) / Double(total)
        }
    }

    /// Procesa items y retorna resultados detallados
    static func processItems(_ items: [String]) async -> ProcessingResult {
        let coordinator = TaskGroupCoordinator<String>()

        let operations: [@Sendable () async throws -> String] = items.enumerated().map { index, item in
            {
                // Simular procesamiento con algunos fallos
                if index % 5 == 0 {
                    throw ExampleError.processingFailed(item: item)
                }

                try await Task.sleep(for: .milliseconds(10))
                return "Processed: \(item)"
            }
        }

        let result = await coordinator.executeBatchCollecting(operations)

        return ProcessingResult(
            processed: result.values,
            failed: result.failures.map { ($0.index, $0.error.description) }
        )
    }

    /// Ejemplo de uso
    static func demo() async {
        print("\n=== Mixed Results Example ===")

        let items = (0..<20).map { "Item-\($0)" }
        let result = await processItems(items)

        print(result.summary)

        if !result.failed.isEmpty {
            print("\nFailed items:")
            for (index, reason) in result.failed.prefix(3) {
                print("  [\(index)]: \(reason)")
            }
            if result.failed.count > 3 {
                print("  ... and \(result.failed.count - 3) more")
            }
        }
    }
}

// MARK: - Example 8: Batch with Dependencies

/// Ejemplo de batch con dependencias entre operaciones
enum DependentBatchExample {

    /// Ejecuta operaciones en fases, donde cada fase depende de la anterior
    static func processInPhases<T: Sendable>(
        phases: [[() async throws -> T]]
    ) async throws -> [[T]] {
        let coordinator = TaskGroupCoordinator<T>()
        var allResults: [[T]] = []

        for (phaseIndex, phaseOperations) in phases.enumerated() {
            print("Executing phase \(phaseIndex + 1)...")

            let operations: [@Sendable () async throws -> T] = phaseOperations.map { op in
                { try await op() }
            }

            let phaseResults = try await coordinator.executeBatch(operations)
            allResults.append(phaseResults)
        }

        return allResults
    }

    /// Ejemplo de uso
    static func demo() async {
        print("\n=== Dependent Batch Example ===")

        // Definir fases de procesamiento
        let phases: [[() async throws -> String]] = [
            // Fase 1: Preparación
            [
                { "Prepared A" },
                { "Prepared B" },
                { "Prepared C" }
            ],
            // Fase 2: Procesamiento (depende de fase 1)
            [
                { "Processed A" },
                { "Processed B" }
            ],
            // Fase 3: Finalización (depende de fase 2)
            [
                { "Finalized" }
            ]
        ]

        do {
            let results = try await processInPhases(phases: phases)
            for (index, phaseResults) in results.enumerated() {
                print("Phase \(index + 1) results: \(phaseResults)")
            }
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum ExampleError: Error, LocalizedError {
    case userNotFound(id: UUID)
    case temporaryFailure
    case processingFailed(item: String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .userNotFound(let id):
            return "User not found: \(id)"
        case .temporaryFailure:
            return "Temporary failure, please retry"
        case .processingFailed(let item):
            return "Failed to process: \(item)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Run All Examples

/// Ejecuta todos los ejemplos en secuencia
@main
struct ConcurrencyExamplesRunner {
    static func main() async {
        print("╔════════════════════════════════════════════╗")
        print("║  LocalPersistence Concurrency Examples     ║")
        print("╚════════════════════════════════════════════╝")

        await BasicBatchExample.demo()
        await PartialFailureExample.demo()
        await RateLimitedExample.demo()
        await TimeoutExample.demo()
        await RetryExample.demo()
        await CancellationExample.demo()
        await MixedResultsExample.demo()
        await DependentBatchExample.demo()

        print("\n✅ All examples completed!")
    }
}
