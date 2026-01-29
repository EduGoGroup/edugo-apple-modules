# Migration Guide

> Guía para migrar código existente a la arquitectura de concurrencia con TaskGroupCoordinator.

## Tabla de Contenidos

1. [Overview de Migración](#overview-de-migración)
2. [Migración desde DispatchQueue](#migración-desde-dispatchqueue)
3. [Migración desde async let](#migración-desde-async-let)
4. [Migración desde withTaskGroup manual](#migración-desde-withtaskgroup-manual)
5. [Migración desde OperationQueue](#migración-desde-operationqueue)
6. [Checklist de Adopción](#checklist-de-adopción)
7. [Ejemplos Completos](#ejemplos-completos)

---

## Overview de Migración

### Beneficios de Migrar

| Antes | Después |
|-------|---------|
| Manejo manual de errores | Error aggregation automático |
| Race conditions posibles | Actor isolation garantizado |
| Timeout con race conditions | Timeout estructurado |
| Cancelación manual | Cooperative cancellation |
| Métricas manuales | Métricas integradas |

### Pasos Generales

1. Identificar código con operaciones batch
2. Refactorizar a operaciones `@Sendable`
3. Crear `TaskGroupCoordinator` apropiado
4. Configurar opciones (timeout, retry, etc.)
5. Actualizar manejo de errores
6. Agregar tests de concurrencia

---

## Migración desde DispatchQueue

### Antes: DispatchQueue.concurrentPerform

```swift
// ANTES
func processItemsOld(_ items: [Item]) -> [Result] {
    var results = Array<Result?>(repeating: nil, count: items.count)
    let lock = NSLock()
    
    DispatchQueue.concurrentPerform(iterations: items.count) { index in
        let result = processItem(items[index])
        lock.lock()
        results[index] = result
        lock.unlock()
    }
    
    return results.compactMap { $0 }
}
```

### Después: TaskGroupCoordinator

```swift
// DESPUÉS
func processItems(_ items: [Item]) async throws -> [Result] {
    let coordinator = TaskGroupCoordinator<Result>()
    
    let operations: [@Sendable () async throws -> Result] = items.map { item in
        { try await processItem(item) }
    }
    
    return try await coordinator.executeBatch(operations)
}
```

### Antes: DispatchGroup

```swift
// ANTES
func fetchAllDataOld(ids: [UUID], completion: @escaping ([Data]) -> Void) {
    let group = DispatchGroup()
    var results: [Data] = []
    let lock = NSLock()
    
    for id in ids {
        group.enter()
        fetchData(id: id) { data in
            lock.lock()
            results.append(data)
            lock.unlock()
            group.leave()
        }
    }
    
    group.notify(queue: .main) {
        completion(results)
    }
}
```

### Después: TaskGroupCoordinator

```swift
// DESPUÉS
func fetchAllData(ids: [UUID]) async throws -> [Data] {
    let coordinator = TaskGroupCoordinator<Data>()
    
    let operations = ids.map { id in
        { try await self.fetchData(id: id) }
    }
    
    return try await coordinator.executeBatch(operations)
}
```

---

## Migración desde async let

### Antes: async let para número fijo

```swift
// ANTES - Solo funciona con número conocido en compile time
func fetchUserDataOld(userId: UUID) async throws -> UserData {
    async let profile = fetchProfile(userId)
    async let posts = fetchPosts(userId)
    async let friends = fetchFriends(userId)
    
    return try await UserData(
        profile: profile,
        posts: posts,
        friends: friends
    )
}
```

### Después: TaskGroupCoordinator para número dinámico

```swift
// DESPUÉS - Funciona con cualquier número de operaciones
func fetchUserData(userId: UUID, sections: [Section]) async throws -> UserData {
    let coordinator = TaskGroupCoordinator<SectionData>()
    
    let operations: [@Sendable () async throws -> SectionData] = sections.map { section in
        { try await self.fetchSection(userId: userId, section: section) }
    }
    
    let results = try await coordinator.executeBatch(operations)
    return UserData(sections: results)
}
```

### Cuándo mantener async let

Usa `async let` cuando:
- Tienes un número fijo y pequeño de operaciones
- Todas las operaciones son independientes
- No necesitas error aggregation

```swift
// async let sigue siendo apropiado aquí
func fetchPageData() async throws -> PageData {
    async let header = fetchHeader()
    async let content = fetchContent()
    async let footer = fetchFooter()
    
    return try await PageData(
        header: header,
        content: content,
        footer: footer
    )
}
```

---

## Migración desde withTaskGroup manual

### Antes: withTaskGroup directo

```swift
// ANTES
func processItemsOld(_ items: [Item]) async throws -> [Result] {
    try await withThrowingTaskGroup(of: (Int, Result).self) { group in
        for (index, item) in items.enumerated() {
            group.addTask {
                let result = try await process(item)
                return (index, result)
            }
        }
        
        var results: [(Int, Result)] = []
        for try await result in group {
            results.append(result)
        }
        
        return results.sorted { $0.0 < $1.0 }.map { $0.1 }
    }
}
```

### Después: TaskGroupCoordinator

```swift
// DESPUÉS
func processItems(_ items: [Item]) async throws -> [Result] {
    let coordinator = TaskGroupCoordinator<Result>()
    
    let operations = items.map { item in
        { try await process(item) }
    }
    
    // Resultados ya vienen en orden
    return try await coordinator.executeBatch(operations)
}
```

### Antes: withTaskGroup con error handling manual

```swift
// ANTES
func processWithErrorsOld(_ items: [Item]) async -> (successes: [Result], errors: [Error]) {
    await withTaskGroup(of: Swift.Result<Result, Error>.self) { group in
        for item in items {
            group.addTask {
                do {
                    return .success(try await process(item))
                } catch {
                    return .failure(error)
                }
            }
        }
        
        var successes: [Result] = []
        var errors: [Error] = []
        
        for await result in group {
            switch result {
            case .success(let value):
                successes.append(value)
            case .failure(let error):
                errors.append(error)
            }
        }
        
        return (successes, errors)
    }
}
```

### Después: executeBatchCollecting

```swift
// DESPUÉS
func processWithErrors(_ items: [Item]) async -> BatchResult<Result> {
    let coordinator = TaskGroupCoordinator<Result>()
    
    let operations = items.map { item in
        { try await process(item) }
    }
    
    // BatchResult incluye successes, failures, y métricas
    return await coordinator.executeBatchCollecting(operations)
}
```

---

## Migración desde OperationQueue

### Antes: OperationQueue con dependencias

```swift
// ANTES
class BatchProcessor {
    private let queue = OperationQueue()
    
    func process(_ items: [Item], completion: @escaping ([Result]) -> Void) {
        queue.maxConcurrentOperationCount = 5
        
        var results: [Result] = []
        let lock = NSLock()
        
        let operations = items.map { item -> BlockOperation in
            BlockOperation {
                let result = self.processSync(item)
                lock.lock()
                results.append(result)
                lock.unlock()
            }
        }
        
        let completionOp = BlockOperation {
            DispatchQueue.main.async {
                completion(results)
            }
        }
        
        operations.forEach { completionOp.addDependency($0) }
        queue.addOperations(operations + [completionOp], waitUntilFinished: false)
    }
}
```

### Después: TaskGroupCoordinator con maxConcurrency

```swift
// DESPUÉS
actor BatchProcessor {
    func process(_ items: [Item]) async throws -> [Result] {
        let coordinator = TaskGroupCoordinator<Result>()
        
        let operations = items.map { item in
            { try await self.processAsync(item) }
        }
        
        return try await coordinator.executeBatch(
            operations,
            maxConcurrency: 5
        )
    }
}
```

### Antes: OperationQueue con cancelación

```swift
// ANTES
class CancellableProcessor {
    private let queue = OperationQueue()
    
    func process(_ items: [Item]) {
        let operations = items.map { item in
            BlockOperation { [weak self] in
                guard let self = self else { return }
                self.processSync(item)
            }
        }
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    func cancel() {
        queue.cancelAllOperations()
    }
}
```

### Después: Task con cancelación

```swift
// DESPUÉS
actor CancellableProcessor {
    private var currentTask: Task<[Result], Error>?
    
    func process(_ items: [Item]) async throws -> [Result] {
        let coordinator = TaskGroupCoordinator<Result>()
        
        let operations = items.map { item in
            { 
                try Task.checkCancellation()
                return try await self.processAsync(item) 
            }
        }
        
        currentTask = Task {
            try await coordinator.executeBatch(operations)
        }
        
        return try await currentTask!.value
    }
    
    func cancel() {
        currentTask?.cancel()
    }
}
```

---

## Checklist de Adopción

### Pre-Migración

- [ ] Identificar todas las operaciones batch existentes
- [ ] Documentar patrones de error handling actuales
- [ ] Listar dependencias de threading (locks, semaphores)
- [ ] Identificar timeouts existentes
- [ ] Revisar tests de concurrencia existentes

### Durante Migración

- [ ] Convertir callbacks a async/await
- [ ] Reemplazar locks con actor isolation
- [ ] Crear operaciones `@Sendable`
- [ ] Configurar `TaskGroupCoordinator`
- [ ] Implementar error handling con `TaskGroupError`
- [ ] Agregar timeouts con `TaskGroupConfiguration`
- [ ] Configurar retry si es necesario

### Post-Migración

- [ ] Verificar que todos los tests pasan
- [ ] Agregar tests de concurrencia específicos
- [ ] Documentar nuevos patrones de uso
- [ ] Remover código legacy (locks, dispatch queues)
- [ ] Actualizar documentación de API

### Tests a Agregar

```swift
@Suite("Migration Validation Tests")
struct MigrationTests {
    
    @Test("Batch operations maintain order")
    func testOrder() async throws {
        // Verificar que resultados mantienen orden
    }
    
    @Test("Partial failures are captured")
    func testPartialFailures() async throws {
        // Verificar error aggregation
    }
    
    @Test("Cancellation propagates")
    func testCancellation() async throws {
        // Verificar cooperative cancellation
    }
    
    @Test("Timeout triggers correctly")
    func testTimeout() async throws {
        // Verificar timeout behavior
    }
    
    @Test("Max concurrency is respected")
    func testMaxConcurrency() async throws {
        // Verificar rate limiting
    }
}
```

---

## Ejemplos Completos

### Ejemplo 1: API Client Migration

**Antes:**

```swift
class APIClient {
    func fetchUsers(ids: [UUID], completion: @escaping (Result<[User], Error>) -> Void) {
        let group = DispatchGroup()
        var users: [User] = []
        var firstError: Error?
        let lock = NSLock()
        
        for id in ids {
            group.enter()
            fetchUser(id: id) { result in
                lock.lock()
                defer { 
                    lock.unlock()
                    group.leave()
                }
                
                switch result {
                case .success(let user):
                    users.append(user)
                case .failure(let error):
                    if firstError == nil {
                        firstError = error
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if let error = firstError {
                completion(.failure(error))
            } else {
                completion(.success(users))
            }
        }
    }
}
```

**Después:**

```swift
actor APIClient {
    private let coordinator = TaskGroupCoordinator<User>()
    
    func fetchUsers(ids: [UUID]) async throws -> [User] {
        let operations = ids.map { id in
            { try await self.fetchUser(id: id) }
        }
        
        return try await coordinator.executeBatch(
            operations,
            maxConcurrency: 10
        )
    }
    
    func fetchUsersWithPartialResults(ids: [UUID]) async -> BatchResult<User> {
        let operations = ids.map { id in
            { try await self.fetchUser(id: id) }
        }
        
        return await coordinator.executeBatchCollecting(operations)
    }
}
```

### Ejemplo 2: Image Processor Migration

**Antes:**

```swift
class ImageProcessor {
    private let processingQueue = OperationQueue()
    
    init() {
        processingQueue.maxConcurrentOperationCount = 4
    }
    
    func processImages(_ images: [UIImage], completion: @escaping ([UIImage]) -> Void) {
        var results = [UIImage?](repeating: nil, count: images.count)
        let lock = NSLock()
        
        let operations = images.enumerated().map { index, image -> BlockOperation in
            BlockOperation {
                let processed = self.applyFilters(to: image)
                lock.lock()
                results[index] = processed
                lock.unlock()
            }
        }
        
        let completionOp = BlockOperation {
            let finalResults = results.compactMap { $0 }
            DispatchQueue.main.async {
                completion(finalResults)
            }
        }
        
        operations.forEach { completionOp.addDependency($0) }
        processingQueue.addOperations(operations + [completionOp], waitUntilFinished: false)
    }
}
```

**Después:**

```swift
actor ImageProcessor {
    private let coordinator = TaskGroupCoordinator<UIImage>()
    
    func processImages(_ images: [UIImage]) async throws -> [UIImage] {
        let operations = images.map { image in
            { await self.applyFilters(to: image) }
        }
        
        let options = TaskBatchOptions(
            configuration: TaskGroupConfiguration(
                timeout: .seconds(60),
                maxConcurrency: 4
            )
        )
        
        return try await coordinator.executeBatch(operations, options: options)
    }
}
```

### Ejemplo 3: Database Sync Migration

**Antes:**

```swift
class DatabaseSync {
    func syncRecords(_ records: [Record], completion: @escaping (SyncResult) -> Void) {
        var synced = 0
        var failed = 0
        let semaphore = DispatchSemaphore(value: 5)
        let group = DispatchGroup()
        let lock = NSLock()
        
        for record in records {
            group.enter()
            DispatchQueue.global().async {
                semaphore.wait()
                defer { semaphore.signal() }
                
                do {
                    try self.syncRecord(record)
                    lock.lock()
                    synced += 1
                    lock.unlock()
                } catch {
                    lock.lock()
                    failed += 1
                    lock.unlock()
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(SyncResult(synced: synced, failed: failed))
        }
    }
}
```

**Después:**

```swift
actor DatabaseSync {
    private let coordinator = TaskGroupCoordinator<Void>()
    
    func syncRecords(_ records: [Record]) async -> SyncResult {
        let operations = records.map { record in
            { try await self.syncRecord(record) }
        }
        
        let result = await coordinator.executeBatchCollecting(operations)
        
        return SyncResult(
            synced: result.successes.count,
            failed: result.failures.count,
            errors: result.errors
        )
    }
}
```

---

## Recursos Adicionales

- [Concurrency Architecture](./ConcurrencyArchitecture.md)
- [Task Group Patterns](./TaskGroupPatterns.md)
- [Error Handling Guide](./ErrorHandlingGuide.md)
- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
