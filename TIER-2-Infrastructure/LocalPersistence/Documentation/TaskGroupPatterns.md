# Task Group Patterns

> Patrones de uso de TaskGroupCoordinator para operaciones batch en LocalPersistence.

## Tabla de Contenidos

1. [Patrones Básicos](#patrones-básicos)
2. [Patrones de Error Handling](#patrones-de-error-handling)
3. [Patrones de Timeout y Cancelación](#patrones-de-timeout-y-cancelación)
4. [Patrones de Rate Limiting](#patrones-de-rate-limiting)
5. [Patrones de Retry](#patrones-de-retry)
6. [Patrones de Testing](#patrones-de-testing)
7. [Anti-Patrones](#anti-patrones)

---

## Patrones Básicos

### Patrón: Batch Simple

**Cuándo usar**: Cuando necesitas ejecutar múltiples operaciones y todas deben tener éxito.

```swift
let coordinator = TaskGroupCoordinator<User>()

let userIDs: [UUID] = [/* ... */]
let operations: [@Sendable () async throws -> User] = userIDs.map { id in
    { try await userRepository.get(id: id) }
}

// Todas las operaciones deben tener éxito
let users = try await coordinator.executeBatch(operations)
```

### Patrón: Batch con Transformación

**Cuándo usar**: Cuando necesitas transformar los resultados después de la ejecución.

```swift
let coordinator = TaskGroupCoordinator<Data>()

let urls = [/* ... */]
let operations: [@Sendable () async throws -> Data] = urls.map { url in
    { try await downloadData(from: url) }
}

// Ejecutar y transformar
let images = try await coordinator.executeBatchAndMap(operations) { data in
    UIImage(data: data)
}
```

### Patrón: Batch Compacto

**Cuándo usar**: Cuando las operaciones pueden retornar nil y quieres filtrarlos.

```swift
let coordinator = TaskGroupCoordinator<User?>()

let operations: [@Sendable () async throws -> User?] = userIDs.map { id in
    { try? await userRepository.get(id: id) }
}

// Solo usuarios que existen
let existingUsers = try await coordinator.executeBatchCompact(operations)
```

### Patrón: Fire and Forget

**Cuándo usar**: Cuando no necesitas los resultados pero quieres esperar a que terminen.

```swift
let coordinator = TaskGroupCoordinator<Void>()

let operations: [@Sendable () async throws -> Void] = items.map { item in
    { try await process(item) }
}

// Esperar a que todas completen
try await coordinator.executeBatch(operations)
```

---

## Patrones de Error Handling

### Patrón: Resultados Parciales

**Cuándo usar**: Cuando algunos fallos son aceptables y quieres los resultados exitosos.

```swift
let coordinator = TaskGroupCoordinator<Document>()

let result = await coordinator.executeBatchCollecting(operations)

// Procesar exitosos
for (index, document) in result.successes {
    await saveToCache(document, index: index)
}

// Reportar fallos
for (index, error) in result.failures {
    log.error("Documento \(index) falló: \(error.description)")
}

// Verificar tasa de éxito
if result.successRate < 0.8 {
    alertAdministrator("Tasa de éxito baja: \(result.successRate)")
}
```

### Patrón: Fail Fast

**Cuándo usar**: Cuando cualquier fallo debe detener todo el proceso.

```swift
let options = TaskBatchOptions(
    configuration: TaskGroupConfiguration(cancelOnFirstError: true),
    throwOnAnyFailure: true
)

do {
    let results = try await coordinator.executeBatch(operations, options: options)
} catch let error as TaskGroupError {
    switch error {
    case .partialFailure(_, let errors):
        // El primer error que ocurrió
        handleCriticalError(errors.first!)
    default:
        throw error
    }
}
```

### Patrón: Error Classification

**Cuándo usar**: Cuando necesitas manejar diferentes tipos de errores de forma diferente.

```swift
let result = await coordinator.executeBatchCollecting(operations)

var retriableErrors: [WrappedError] = []
var permanentErrors: [WrappedError] = []

for failure in result.failures {
    if failure.error.errorType.contains("NetworkError") {
        retriableErrors.append(failure.error)
    } else {
        permanentErrors.append(failure.error)
    }
}

// Reintentar los retriable
if !retriableErrors.isEmpty {
    await retryFailedOperations(retriableErrors)
}

// Reportar los permanentes
if !permanentErrors.isEmpty {
    await reportPermanentFailures(permanentErrors)
}
```

---

## Patrones de Timeout y Cancelación

### Patrón: Timeout Global

**Cuándo usar**: Cuando todo el batch debe completar en un tiempo límite.

```swift
let options = TaskBatchOptions(
    configuration: TaskGroupConfiguration(timeout: .seconds(30))
)

do {
    let results = try await coordinator.executeBatch(operations, options: options)
} catch let error as TaskGroupError {
    if case .timeout(let duration) = error {
        log.warning("Batch timeout después de \(duration)s")
        // Manejar timeout (quizás con resultados parciales)
    }
}
```

### Patrón: Timeout con Cleanup

**Cuándo usar**: Cuando necesitas limpiar recursos si hay timeout.

```swift
let handler = CancellationHandler()

do {
    let result = try await handler.withTimeout(
        .seconds(60),
        onCancellation: {
            await cleanupTemporaryFiles()
            await releaseNetworkConnections()
        }
    ) {
        try await performLongRunningBatch()
    }
} catch {
    // Cleanup ya fue ejecutado
    throw error
}
```

### Patrón: Cancellation Cooperative

**Cuándo usar**: Cuando tus operaciones deben verificar cancelación periódicamente.

```swift
let operations: [@Sendable () async throws -> Data] = files.map { file in
    {
        var processedChunks: [Data] = []
        
        for chunk in file.chunks {
            // Verificar cancelación antes de cada chunk
            try Task.checkCancellation()
            
            let processed = try await processChunk(chunk)
            processedChunks.append(processed)
        }
        
        return Data(processedChunks.joined())
    }
}
```

### Patrón: User-Initiated Cancellation

**Cuándo usar**: Cuando el usuario puede cancelar la operación.

```swift
class DownloadManager {
    private var currentTask: Task<[Data], Error>?
    
    func startBatchDownload(_ urls: [URL]) async throws -> [Data] {
        let coordinator = TaskGroupCoordinator<Data>()
        let operations = urls.map { url in
            { try await self.download(url) }
        }
        
        currentTask = Task {
            try await coordinator.executeBatch(operations)
        }
        
        return try await currentTask!.value
    }
    
    func cancelDownload() {
        currentTask?.cancel()
        currentTask = nil
    }
}
```

---

## Patrones de Rate Limiting

### Patrón: Concurrencia Fija

**Cuándo usar**: Cuando conoces el límite óptimo de concurrencia.

```swift
// Máximo 5 requests simultáneas al API
let results = try await coordinator.executeBatch(
    operations,
    maxConcurrency: 5
)
```

### Patrón: Concurrencia Dinámica

**Cuándo usar**: Cuando el límite depende de condiciones runtime.

```swift
let maxConcurrency: Int
switch NetworkMonitor.shared.connectionType {
case .wifi:
    maxConcurrency = 10
case .cellular:
    maxConcurrency = 3
case .unknown:
    maxConcurrency = 1
}

let results = try await coordinator.executeBatch(
    operations,
    maxConcurrency: maxConcurrency
)
```

### Patrón: Rate Limiting con Delay

**Cuándo usar**: Cuando necesitas espaciar las operaciones (API rate limits).

```swift
let operations: [@Sendable () async throws -> Response] = requests.enumerated().map { index, request in
    {
        // Delay progresivo para evitar rate limiting
        if index > 0 {
            try await Task.sleep(for: .milliseconds(100))
        }
        return try await executeRequest(request)
    }
}

let results = try await coordinator.executeBatch(
    operations,
    maxConcurrency: 5
)
```

---

## Patrones de Retry

### Patrón: Retry Simple

**Cuándo usar**: Para operaciones que pueden fallar temporalmente.

```swift
let result = try await coordinator.executeWithRetry(maxAttempts: 3) {
    try await unstableNetworkCall()
}
```

### Patrón: Retry con Backoff Exponencial

**Cuándo usar**: Para APIs que necesitan tiempo para recuperarse.

```swift
let result = try await coordinator.executeWithRetry(
    maxAttempts: 5,
    strategy: .exponential(
        baseDelay: .seconds(1),    // 1s, 2s, 4s, 8s...
        maxDelay: .seconds(30),    // Cap en 30s
        maxAttempts: 5
    )
) {
    try await callRateLimitedAPI()
}
```

### Patrón: Retry Selectivo

**Cuándo usar**: Cuando solo ciertos errores son retriable.

```swift
func executeWithSelectiveRetry<T>(
    maxAttempts: Int,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
        } catch let error as NetworkError where error.isRetriable {
            lastError = error
            try await Task.sleep(for: .seconds(Double(attempt)))
        } catch {
            // Error no retriable, fallar inmediatamente
            throw error
        }
    }
    
    throw lastError!
}
```

### Patrón: Retry de Operaciones Fallidas en Batch

**Cuándo usar**: Cuando quieres reintentar solo las operaciones que fallaron.

```swift
var allSuccesses: [(index: Int, value: T)] = []
var pendingOperations = operations.enumerated().map { ($0, $1) }

for attempt in 1...maxAttempts {
    let result = await coordinator.executeBatchCollecting(
        pendingOperations.map { $0.1 }
    )
    
    allSuccesses.append(contentsOf: result.successes)
    
    if result.allSucceeded {
        break
    }
    
    // Preparar solo las fallidas para reintento
    let failedIndices = Set(result.failures.map { $0.index })
    pendingOperations = pendingOperations.filter { 
        failedIndices.contains($0.0) 
    }
    
    try await Task.sleep(for: .seconds(Double(attempt)))
}
```

---

## Patrones de Testing

### Patrón: Mock de Operaciones Lentas

```swift
@Test("Batch handles slow operations")
func testSlowOperations() async throws {
    let helper = ConcurrencyTestHelpers()
    
    let operations = await helper.makeSuccessfulOperations(
        count: 10,
        delay: .milliseconds(100),
        value: "success"
    )
    
    let coordinator = TaskGroupCoordinator<String>()
    let results = try await coordinator.executeBatch(operations)
    
    #expect(results.count == 10)
}
```

### Patrón: Test de Fallos Parciales

```swift
@Test("Batch collects partial failures")
func testPartialFailures() async throws {
    let helper = ConcurrencyTestHelpers()
    
    // 30% de fallos
    let operations = await helper.makeOperationsWithFailureRate(
        count: 100,
        failureRate: 0.3,
        value: 42
    )
    
    let coordinator = TaskGroupCoordinator<Int>()
    let result = await coordinator.executeBatchCollecting(operations)
    
    #expect(result.hasPartialSuccess)
    #expect(result.failures.count > 0)
    #expect(result.successes.count > 0)
}
```

### Patrón: Test de Rate Limiting

```swift
@Test("Max concurrency is respected")
func testMaxConcurrency() async throws {
    let helper = ConcurrencyTestHelpers()
    let maxConcurrency = 5
    
    let operations = await helper.makeSuccessfulOperations(
        count: 50,
        delay: .milliseconds(50),
        value: true
    )
    
    let coordinator = TaskGroupCoordinator<Bool>()
    _ = try await coordinator.executeBatch(
        operations,
        maxConcurrency: maxConcurrency
    )
    
    let metrics = await helper.metrics
    #expect(metrics.maxConcurrent <= maxConcurrency)
}
```

### Patrón: Test de Cancellation

```swift
@Test("Cancellation propagates correctly")
func testCancellation() async throws {
    let helper = ConcurrencyTestHelpers()
    
    let operations = await helper.makeCancellationAwareOperations(
        count: 50,
        totalDuration: .seconds(5),
        value: true
    )
    
    let task = Task {
        await withTaskGroupCollectingResults(
            configuration: .default,
            operations: operations
        )
    }
    
    try await Task.sleep(for: .milliseconds(100))
    task.cancel()
    
    let result = await task.value
    #expect(result.failures.count > 0)
}
```

---

## Anti-Patrones

### Anti-Patrón: Capturar Variables Mutables

```swift
// MAL - Captura de variable mutable
var results: [Int] = []
await withTaskGroup(of: Int.self) { group in
    for i in 0..<10 {
        group.addTask {
            results.append(i) // Data race!
            return i
        }
    }
}

// BIEN - Usar el resultado del task group
let results = await withTaskGroup(of: Int.self, returning: [Int].self) { group in
    for i in 0..<10 {
        group.addTask { i }
    }
    var collected: [Int] = []
    for await result in group {
        collected.append(result)
    }
    return collected
}
```

### Anti-Patrón: Ignorar Cancelación

```swift
// MAL - No verificar cancelación
let operations = items.map { item in
    {
        // Operación larga sin verificar cancelación
        for _ in 0..<1000000 {
            heavyComputation()
        }
    }
}

// BIEN - Verificar cancelación periódicamente
let operations = items.map { item in
    {
        for i in 0..<1000000 {
            if i % 1000 == 0 {
                try Task.checkCancellation()
            }
            heavyComputation()
        }
    }
}
```

### Anti-Patrón: Timeout con Sleep

```swift
// MAL - Race condition entre timeout y operación
func badTimeout<T>(_ operation: () async throws -> T) async throws -> T {
    async let result = operation()
    async let timeout: Void = Task.sleep(for: .seconds(30))
    
    // Esto no funciona como esperarías
    return try await result
}

// BIEN - Usar structured concurrency
func goodTimeout<T>(_ operation: () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T?.self) { group in
        group.addTask {
            try await Task.sleep(for: .seconds(30))
            return nil
        }
        group.addTask {
            try await operation()
        }
        
        if let first = try await group.next(), let result = first {
            group.cancelAll()
            return result
        }
        throw TimeoutError()
    }
}
```

### Anti-Patrón: Batch Sin Límite de Concurrencia

```swift
// MAL - Sin límite puede sobrecargar el sistema
let operations = (0..<10000).map { i in
    { try await networkRequest(i) }
}
let results = try await coordinator.executeBatch(operations)

// BIEN - Limitar concurrencia
let results = try await coordinator.executeBatch(
    operations,
    maxConcurrency: 50
)
```

---

## Checklist de Implementación

- [ ] Usar `TaskGroupCoordinator` para operaciones batch
- [ ] Definir `@Sendable` en todos los closures
- [ ] Configurar `maxConcurrency` apropiado
- [ ] Implementar timeout para operaciones largas
- [ ] Verificar cancelación en operaciones de larga duración
- [ ] Manejar errores parciales cuando sea apropiado
- [ ] Agregar retry para operaciones que pueden fallar temporalmente
- [ ] Escribir tests para escenarios de concurrencia
