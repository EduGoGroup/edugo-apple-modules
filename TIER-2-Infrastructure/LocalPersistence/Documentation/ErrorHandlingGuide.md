# Error Handling Guide

> Guía completa para manejo de errores en operaciones concurrentes con TaskGroupCoordinator.

## Tabla de Contenidos

1. [Jerarquía de Errores](#jerarquía-de-errores)
2. [TaskGroupError](#taskgrouperror)
3. [CancellationReason](#cancellationreason)
4. [WrappedError](#wrappederror)
5. [Patrones de Manejo](#patrones-de-manejo)
6. [Troubleshooting](#troubleshooting)

---

## Jerarquía de Errores

```
Error (Swift.Error)
├── TaskGroupError
│   ├── partialFailure(successCount:errors:)
│   ├── cancelled
│   ├── timeout(duration:)
│   ├── allFailed(errors:)
│   ├── emptyBatch
│   └── maxRetriesExceeded(attempts:lastError:)
│
├── CancellationReason
│   ├── timeout(duration:)
│   ├── userCancelled
│   ├── systemCancelled(reason:)
│   ├── parentTaskCancelled
│   ├── batchCancelled(completed:total:)
│   └── resourceUnavailable(resource:)
│
└── WrappedError (wrapper para cualquier Error)
```

---

## TaskGroupError

Errores específicos de operaciones batch en task groups.

### partialFailure

Algunas operaciones fallaron pero otras tuvieron éxito.

```swift
case partialFailure(successCount: Int, errors: [WrappedError])
```

**Cuándo ocurre**: 
- Al usar `executeBatch` con `throwOnAnyFailure: true`
- Cuando hay mezcla de éxitos y fallos

**Cómo manejar**:

```swift
do {
    let results = try await coordinator.executeBatch(operations, options: .strict)
} catch let error as TaskGroupError {
    if case .partialFailure(let successCount, let errors) = error {
        print("Completados: \(successCount)")
        print("Errores: \(errors.count)")
        
        // Obtener detalles de cada error
        for wrappedError in errors {
            print("Op \(wrappedError.operationIndex ?? -1): \(wrappedError.description)")
        }
    }
}
```

### cancelled

La operación fue cancelada explícitamente.

```swift
case cancelled
```

**Cuándo ocurre**:
- `Task.cancel()` fue llamado
- `Task.isCancelled` es true
- Una child task lanzó `CancellationError`

**Cómo manejar**:

```swift
do {
    let results = try await coordinator.executeBatch(operations)
} catch let error as TaskGroupError {
    if case .cancelled = error {
        // Cleanup y notificar al usuario
        await cleanupPartialWork()
        showCancelledMessage()
    }
}
```

### timeout

La operación excedió el tiempo límite.

```swift
case timeout(duration: TimeInterval)
```

**Cuándo ocurre**:
- El timeout configurado expiró antes de completar todas las operaciones

**Cómo manejar**:

```swift
do {
    let options = TaskBatchOptions(
        configuration: TaskGroupConfiguration(timeout: .seconds(30))
    )
    let results = try await coordinator.executeBatch(operations, options: options)
} catch let error as TaskGroupError {
    if case .timeout(let duration) = error {
        log.warning("Timeout después de \(duration)s")
        
        // Opción 1: Reintentar con timeout más largo
        // Opción 2: Usar resultados parciales si están disponibles
        // Opción 3: Notificar al usuario
    }
}
```

### allFailed

Todas las operaciones fallaron.

```swift
case allFailed(errors: [WrappedError])
```

**Cuándo ocurre**:
- Ninguna operación del batch tuvo éxito

**Cómo manejar**:

```swift
do {
    let results = try await coordinator.executeBatch(operations)
} catch let error as TaskGroupError {
    if case .allFailed(let errors) = error {
        // Analizar errores para determinar causa raíz
        let errorTypes = Dictionary(grouping: errors) { $0.errorType }
        
        if let mostCommon = errorTypes.max(by: { $0.value.count < $1.value.count }) {
            log.error("Error más común: \(mostCommon.key) (\(mostCommon.value.count) ocurrencias)")
        }
        
        // Decidir si reintentar o fallar permanentemente
        if errors.allSatisfy({ $0.errorType.contains("NetworkError") }) {
            throw NetworkUnavailableError()
        }
    }
}
```

### emptyBatch

No se proporcionaron operaciones.

```swift
case emptyBatch
```

**Cuándo ocurre**:
- Se llamó `executeBatch` con un array vacío

**Cómo manejar**:

```swift
func processBatch(_ items: [Item]) async throws -> [Result] {
    guard !items.isEmpty else {
        // Opción 1: Retornar vacío
        return []
        // Opción 2: Lanzar error específico
        // throw ValidationError.emptyInput
    }
    
    let operations = items.map { item in
        { try await process(item) }
    }
    
    return try await coordinator.executeBatch(operations)
}
```

### maxRetriesExceeded

Se agotaron los reintentos sin éxito.

```swift
case maxRetriesExceeded(attempts: Int, lastError: WrappedError)
```

**Cuándo ocurre**:
- `executeWithRetry` falló en todos los intentos

**Cómo manejar**:

```swift
do {
    let result = try await coordinator.executeWithRetry(maxAttempts: 3) {
        try await riskyOperation()
    }
} catch let error as TaskGroupError {
    if case .maxRetriesExceeded(let attempts, let lastError) = error {
        log.error("Falló después de \(attempts) intentos")
        log.error("Último error: \(lastError.description)")
        
        // Escalar a intervención manual
        await notifySupport(lastError)
    }
}
```

---

## CancellationReason

Errores específicos que indican por qué una operación fue cancelada.

### Propiedades Útiles

```swift
let reason: CancellationReason = .timeout(duration: 30)

// Verificar tipo
reason.isTimeout        // true
reason.isUserInitiated  // false
reason.isSystemInitiated // false
reason.isRetriable      // true
```

### Manejo Completo

```swift
do {
    let result = try await handler.withTimeout(.seconds(30)) {
        try await longOperation()
    }
} catch let reason as CancellationReason {
    switch reason {
    case .timeout(let duration):
        log.warning("Timeout: \(duration)s")
        // Reintentar con más tiempo
        
    case .userCancelled:
        // Limpiar y salir silenciosamente
        await cleanup()
        
    case .systemCancelled(let systemReason):
        log.error("Sistema canceló: \(systemReason ?? "desconocido")")
        // Guardar estado para reanudar después
        
    case .parentTaskCancelled:
        // Propagar cancelación
        throw reason
        
    case .batchCancelled(let completed, let total):
        log.info("Batch cancelado: \(completed)/\(total) completados")
        // Procesar resultados parciales
        
    case .resourceUnavailable(let resource):
        log.error("Recurso no disponible: \(resource)")
        // Esperar y reintentar
    }
}
```

---

## WrappedError

Wrapper thread-safe para errores capturados en operaciones concurrentes.

### Estructura

```swift
public struct WrappedError: Error, Sendable, Equatable {
    public let description: String      // Descripción del error
    public let errorType: String        // Tipo del error como String
    public let operationIndex: Int?     // Índice de la operación (si aplica)
}
```

### Uso

```swift
let result = await coordinator.executeBatchCollecting(operations)

for failure in result.failures {
    print("Operación \(failure.index):")
    print("  Tipo: \(failure.error.errorType)")
    print("  Descripción: \(failure.error.description)")
}
```

### Crear WrappedError

```swift
// Desde cualquier Error
let wrapped = WrappedError(someError, operationIndex: 5)

// Desde descripción
let wrapped = WrappedError(
    description: "Connection refused",
    errorType: "NetworkError",
    operationIndex: 3
)
```

---

## Patrones de Manejo

### Patrón: Error Cascade

Maneja errores en orden de especificidad:

```swift
do {
    let results = try await coordinator.executeBatch(operations)
} catch let error as TaskGroupError {
    switch error {
    case .emptyBatch:
        return []
        
    case .cancelled:
        throw UserCancelledError()
        
    case .timeout(let duration):
        throw OperationTimeoutError(duration: duration)
        
    case .partialFailure(let successCount, let errors):
        if successCount > 0 {
            log.warning("Partial success: \(successCount) ok, \(errors.count) failed")
            // Continuar con resultados parciales
        } else {
            throw errors.first!
        }
        
    case .allFailed(let errors):
        throw BatchFailedError(errors: errors)
        
    case .maxRetriesExceeded(_, let lastError):
        throw lastError
    }
} catch is CancellationError {
    throw UserCancelledError()
} catch {
    throw UnexpectedError(underlying: error)
}
```

### Patrón: Error Recovery

Intenta recuperarse de errores recuperables:

```swift
func executeWithRecovery<T>(
    _ operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    do {
        return try await coordinator.executeWithRetry(maxAttempts: 3) {
            try await operation()
        }
    } catch let error as TaskGroupError {
        switch error {
        case .timeout:
            // Reintentar con timeout más largo
            return try await executeWithLongerTimeout(operation)
            
        case .maxRetriesExceeded(_, let lastError):
            if lastError.errorType.contains("RateLimit") {
                // Esperar y reintentar
                try await Task.sleep(for: .seconds(60))
                return try await operation()
            }
            throw error
            
        default:
            throw error
        }
    }
}
```

### Patrón: Error Logging Estructurado

```swift
func logBatchError(_ error: TaskGroupError, context: String) {
    let logData: [String: Any] = [
        "context": context,
        "errorType": String(describing: type(of: error)),
        "timestamp": Date()
    ]
    
    switch error {
    case .partialFailure(let successCount, let errors):
        log.error("Partial failure", metadata: logData.merging([
            "successCount": successCount,
            "failureCount": errors.count,
            "errorTypes": Dictionary(grouping: errors) { $0.errorType }.mapValues { $0.count }
        ]))
        
    case .timeout(let duration):
        log.error("Timeout", metadata: logData.merging([
            "duration": duration
        ]))
        
    case .allFailed(let errors):
        log.error("All failed", metadata: logData.merging([
            "errorCount": errors.count,
            "firstError": errors.first?.description ?? "unknown"
        ]))
        
    default:
        log.error("Batch error: \(error)", metadata: logData)
    }
}
```

---

## Troubleshooting

### Problema: "All operations timeout but some should succeed"

**Síntoma**: Todas las operaciones fallan con timeout aunque algunas son rápidas.

**Causa**: El timeout es para todo el batch, no por operación.

**Solución**:

```swift
// Usar timeout por operación
let operations = items.map { item in
    {
        try await withTimeout(.seconds(5)) {
            try await process(item)
        }
    }
}

// O aumentar el timeout global
let options = TaskBatchOptions(
    configuration: TaskGroupConfiguration(timeout: .seconds(120))
)
```

### Problema: "Partial failures not captured"

**Síntoma**: `executeBatch` lanza error pero no ves qué operaciones fallaron.

**Causa**: `executeBatch` no retorna resultados parciales por defecto.

**Solución**:

```swift
// Usar executeBatchCollecting para ver todo
let result = await coordinator.executeBatchCollecting(operations)
print("Éxitos: \(result.successes.count)")
print("Fallos: \(result.failures)")
```

### Problema: "Cancellation not propagating"

**Síntoma**: Al cancelar la Task, las operaciones siguen ejecutándose.

**Causa**: Las operaciones no verifican cancelación.

**Solución**:

```swift
let operations = items.map { item in
    {
        // Agregar verificación de cancelación
        try Task.checkCancellation()
        
        let result = try await longOperation(item)
        
        // Verificar de nuevo si la operación es larga
        try Task.checkCancellation()
        
        return result
    }
}
```

### Problema: "Memory grows during large batch"

**Síntoma**: El uso de memoria crece mucho durante batches grandes.

**Causa**: Todos los resultados se mantienen en memoria.

**Solución**:

```swift
// Procesar en chunks más pequeños
let chunkSize = 100
var allResults: [T] = []

for chunk in items.chunked(into: chunkSize) {
    let operations = chunk.map { item in
        { try await process(item) }
    }
    
    let results = try await coordinator.executeBatch(operations)
    allResults.append(contentsOf: results)
    
    // Opcionalmente, persistir resultados intermedios
    await saveIntermediate(results)
}
```

### Problema: "Retry causes duplicate operations"

**Síntoma**: Al reintentar un batch, algunas operaciones se ejecutan múltiples veces.

**Causa**: No se está rastreando qué operaciones ya tuvieron éxito.

**Solución**:

```swift
var completed: Set<Int> = []
var pendingIndices = Set(0..<operations.count)

for attempt in 1...maxAttempts {
    let pending = pendingIndices.map { operations[$0] }
    let result = await coordinator.executeBatchCollecting(pending)
    
    // Marcar exitosas
    for success in result.successes {
        let originalIndex = Array(pendingIndices)[success.index]
        completed.insert(originalIndex)
    }
    
    // Actualizar pendientes
    pendingIndices = pendingIndices.subtracting(completed)
    
    if pendingIndices.isEmpty {
        break
    }
    
    try await Task.sleep(for: .seconds(Double(attempt)))
}
```

---

## Checklist de Error Handling

- [ ] Capturar `TaskGroupError` específicamente
- [ ] Manejar cada caso de `TaskGroupError`
- [ ] Propagar `CancellationError` correctamente
- [ ] Usar `WrappedError` para logging estructurado
- [ ] Implementar recovery para errores retriables
- [ ] Configurar timeouts apropiados
- [ ] Verificar cancelación en operaciones largas
- [ ] Documentar errores esperados en la API
