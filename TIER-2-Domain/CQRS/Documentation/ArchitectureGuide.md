# CQRS Architecture Guide

Guía arquitectónica completa del módulo CQRS para EduGo Apple.

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Patrones CQRS](#patrones-cqrs)
3. [Componentes Core](#componentes-core)
4. [Mediator Pattern](#mediator-pattern)
5. [Event-Driven Architecture](#event-driven-architecture)
6. [Cache Invalidation Strategy](#cache-invalidation-strategy)
7. [Error Handling Patterns](#error-handling-patterns)
8. [Concurrency Guarantees](#concurrency-guarantees)
9. [Testing Strategy](#testing-strategy)

---

## Introducción

El módulo CQRS implementa el patrón Command Query Responsibility Segregation para separar operaciones de lectura y escritura en la arquitectura de EduGo. Esta separación permite optimizaciones específicas, escalabilidad independiente y mayor claridad en el flujo de datos.

### ¿Por qué CQRS en EduGo?

1. **Separación de Concerns**: ViewModels no conocen los detalles de implementación de UseCases
2. **Optimización Independiente**: Queries pueden usar cache, Commands invalidan cache
3. **Escalabilidad**: Lectura y escritura pueden escalar independientemente
4. **Auditabilidad**: Commands generan eventos para audit trail
5. **Testing**: Handlers aislados son más fáciles de testear

### Principios de Diseño

- **Inmutabilidad**: Queries son inmutables y no tienen side effects
- **Validación Temprana**: Commands validan antes de ejecutar
- **Type Safety**: Swift generics garantizan correctitud en compile-time
- **Actor Isolation**: Toda concurrencia se maneja vía actors
- **Explicit Over Implicit**: No hay magia, todo flujo es explícito

---

## Patrones CQRS

### Query: Solo Lectura

Una Query representa una solicitud de lectura que:
- NO modifica estado del sistema
- Es idempotente (múltiples llamadas = mismo resultado)
- Puede ser cacheada
- Retorna datos directamente

```swift
struct GetStudentDashboardQuery: Query {
    typealias Result = StudentDashboard
    
    let studentId: String
    let includeAssessments: Bool
    var metadata: [String: String]?
}
```

**Características**:
- Conforman `Sendable` para concurrencia segura
- Definen un `Result` type asociado
- Pueden llevar metadata (trace IDs, user context)

### Command: Modifica Estado

Un Command representa una solicitud de escritura que:
- Modifica estado del sistema
- Tiene side effects (DB writes, notificaciones)
- NO es idempotente (ejecutar 2 veces ≠ ejecutar 1 vez)
- Genera eventos para notificar cambios

```swift
struct SubmitAssessmentCommand: Command {
    typealias Result = AssessmentResult
    
    let assessmentId: String
    let answers: [Answer]
    let submittedAt: Date
    
    func validate() throws {
        guard !answers.isEmpty else {
            throw ValidationError.emptyAnswers
        }
        guard submittedAt <= Date() else {
            throw ValidationError.futureSubmission
        }
    }
}
```

**Características**:
- Conforman `Sendable`
- Implementan `validate()` para validación pre-ejecución
- Retornan `CommandResult<T>` con eventos generados

### Separación de Responsabilidades

| Aspecto | Query | Command |
|---------|-------|---------|
| **Propósito** | Leer datos | Modificar estado |
| **Side Effects** | No | Sí |
| **Validación** | No requerida | Pre-ejecución |
| **Cache** | Sí, agresivamente | Invalida cache |
| **Idempotencia** | Sí | No |
| **Resultado** | `Result` directo | `CommandResult<Result>` |
| **Eventos** | No genera | Genera eventos |

---

## Componentes Core

### 1. Query Protocol

```swift
public protocol Query: Sendable {
    associatedtype Result: Sendable
    var metadata: [String: String]? { get }
}
```

**Responsabilidades**:
- Definir contrato de lectura
- Declarar tipo de resultado esperado
- Llevar metadata opcional

### 2. QueryHandler Protocol

```swift
public protocol QueryHandler: Actor {
    associatedtype QueryType: Query
    func handle(_ query: QueryType) async throws -> QueryType.Result
}
```

**Responsabilidades**:
- Implementar lógica de lectura
- Acceder a repositorios/UseCases
- Manejar cache internamente
- Ser thread-safe vía actor isolation

### 3. Command Protocol

```swift
public protocol Command: Sendable {
    associatedtype Result: Sendable
    var metadata: [String: String]? { get }
    func validate() throws
}
```

**Responsabilidades**:
- Definir contrato de escritura
- Validar datos antes de ejecución
- Llevar metadata de contexto

### 4. CommandHandler Protocol

```swift
public protocol CommandHandler: Actor {
    associatedtype CommandType: Command
    func handle(_ command: CommandType) async throws -> CommandResult<CommandType.Result>
}
```

**Responsabilidades**:
- Implementar lógica de escritura
- Generar Domain Events
- Invalidar cache relacionado
- Retornar resultado + eventos

### 5. CommandResult Wrapper

```swift
public struct CommandResult<T: Sendable>: Sendable {
    public let result: T
    public let events: [String]
    public let metadata: [String: String]
    public var isSuccess: Bool { !events.isEmpty }
}
```

**Responsabilidades**:
- Envolver resultado de commands
- Llevar eventos generados
- Proporcionar metadata de ejecución

---

## Mediator Pattern

El Mediator es el dispatcher central que coordina el flujo entre queries/commands y sus handlers.

### Arquitectura del Mediator

```
┌─────────────────────────────────────────────────────┐
│                    Mediator (Actor)                 │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │         MediatorRegistry (Actor)              │ │
│  │                                               │ │
│  │  queryHandlers: [ObjectIdentifier: Any]      │ │
│  │  commandHandlers: [ObjectIdentifier: Any]    │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  send<Q: Query>(_ query: Q) -> Q.Result            │
│  execute<C: Command>(_ command: C) -> CommandResult│
│                                                     │
└─────────────────────────────────────────────────────┘
         │                           │
         │ type-safe dispatch        │
         ▼                           ▼
┌──────────────────┐        ┌──────────────────┐
│  QueryHandler    │        │ CommandHandler   │
│     (Actor)      │        │     (Actor)      │
└──────────────────┘        └──────────────────┘
```

### ¿Por qué Mediator?

**Antes (sin Mediator)**:
```swift
// ViewModel conoce handlers específicos - tight coupling
class DashboardViewModel {
    let dashboardHandler: GetDashboardQueryHandler
    let materialsHandler: GetMaterialsQueryHandler
    
    func loadData() async {
        dashboard = try await dashboardHandler.handle(query1)
        materials = try await materialsHandler.handle(query2)
    }
}
```

**Después (con Mediator)**:
```swift
// ViewModel solo conoce el Mediator - loose coupling
class DashboardViewModel {
    let mediator: Mediator
    
    func loadData() async {
        dashboard = try await mediator.send(GetDashboardQuery())
        materials = try await mediator.send(GetMaterialsQuery())
    }
}
```

**Beneficios**:
1. **Desacoplamiento**: ViewModels no conocen handlers específicos
2. **Testabilidad**: Mock del Mediator es más simple que mockear N handlers
3. **Centralización**: Logging, métricas y políticas en un solo lugar
4. **Flexibilidad**: Cambiar implementación de handlers sin tocar ViewModels

### Type Erasure en Registry

El `MediatorRegistry` usa type erasure para almacenar handlers de diferentes tipos:

```swift
actor MediatorRegistry {
    private var queryHandlers: [ObjectIdentifier: Any] = [:]
    
    func registerQueryHandler<H: QueryHandler>(_ handler: H) {
        let key = ObjectIdentifier(H.QueryType.self)
        queryHandlers[key] = handler  // Type erasure: Any
    }
    
    func getQueryHandler<Q: Query>(for queryType: Q.Type) throws -> any QueryHandler {
        let key = ObjectIdentifier(queryType)
        guard let handler = queryHandlers[key] else {
            throw MediatorError.handlerNotFound(...)
        }
        return handler as! any QueryHandler  // Runtime cast
    }
}
```

**Trade-offs**:
- ✅ Permite almacenar handlers heterogéneos en un diccionario
- ✅ Type-safe en el API público del Mediator
- ❌ Runtime cast interno (pero seguro por el key matching)

---

## Event-Driven Architecture

### Estado Actual: Preparatorio

El módulo está diseñado para soportar eventos, pero la implementación completa del EventBus está planificada para Sprint 4.

**Actualmente**:
```swift
// Commands retornan eventos como strings
let result = try await mediator.execute(command)
print(result.events)  // ["UserLoggedIn", "SessionCreated"]
```

**Futuro (Sprint 4)**:
```swift
// EventBus procesa eventos tipados
struct UserLoggedInEvent: DomainEvent {
    let userId: String
    let timestamp: Date
}

// CommandHandler publica evento
let event = UserLoggedInEvent(userId: user.id, timestamp: Date())
await eventBus.publish(event)

// Subscribers reaccionan
actor CacheInvalidationSubscriber: EventSubscriber {
    func handle(_ event: UserLoggedInEvent) async {
        await invalidateUserCache(userId: event.userId)
    }
}
```

### Domain Events Pattern

Los Domain Events permiten:
1. **Desacoplamiento**: Commands no conocen quién necesita notificarse
2. **Extensibilidad**: Agregar subscribers sin modificar Commands
3. **Audit Trail**: Todos los eventos se pueden persistir para auditoría
4. **Cache Invalidation**: Subscribers invalidan cache automáticamente

---

## Cache Invalidation Strategy

### Estrategia Actual: Weak References

**Implementación Temporal** (hasta Sprint 4):
```swift
actor GetDashboardQueryHandler: QueryHandler {
    private var cachedResult: StudentDashboard?
    
    func handle(_ query: GetDashboardQuery) async throws -> StudentDashboard {
        if let cached = cachedResult {
            return cached
        }
        
        let result = try await useCase.execute()
        cachedResult = result
        return result
    }
    
    func invalidateCache() async {
        cachedResult = nil
    }
}

// Command invalida cache directamente (weak ref)
actor SubmitAssessmentHandler: CommandHandler {
    weak var dashboardHandler: GetDashboardQueryHandler?
    
    func handle(_ command: SubmitAssessmentCommand) async throws -> CommandResult {
        let result = try await useCase.submit(command)
        
        // Invalidar cache relacionado
        await dashboardHandler?.invalidateCache()
        
        return CommandResult(result: result, events: ["AssessmentSubmitted"])
    }
}
```

**Limitaciones**:
- ❌ Tight coupling entre handlers
- ❌ No escala (N commands × M queries afectadas)
- ❌ Difícil de mantener y testear

### Estrategia Futura: EventBus (Sprint 4)

```swift
// Command publica evento
actor SubmitAssessmentHandler: CommandHandler {
    let eventBus: EventBus
    
    func handle(_ command: SubmitAssessmentCommand) async throws -> CommandResult {
        let result = try await useCase.submit(command)
        
        // Publicar evento - desacoplado
        await eventBus.publish(AssessmentSubmittedEvent(
            assessmentId: command.assessmentId,
            studentId: command.studentId
        ))
        
        return CommandResult(result: result, events: ["AssessmentSubmitted"])
    }
}

// Subscriber se encarga de invalidación
actor CacheInvalidationSubscriber: EventSubscriber {
    let mediator: Mediator
    
    func handle(_ event: AssessmentSubmittedEvent) async {
        // Invalidar todas las queries afectadas
        let queries = affectedQueries(for: event)
        for query in queries {
            await invalidateCache(for: query)
        }
    }
}
```

**Beneficios**:
- ✅ Desacoplamiento total
- ✅ Escala a N commands y M queries sin coupling
- ✅ Fácil de testear y mantener
- ✅ Extensible: agregar subscribers sin modificar commands

### Otras Estrategias de Cache

#### TTL (Time-To-Live)
```swift
actor QueryHandlerWithTTL {
    private var cachedResult: (data: Result, expiry: Date)?
    
    func handle(_ query: Query) async throws -> Result {
        if let cached = cachedResult, cached.expiry > Date() {
            return cached.data
        }
        
        let result = try await fetch()
        cachedResult = (result, Date().addingTimeInterval(300)) // 5 min TTL
        return result
    }
}
```

#### Stale-While-Revalidate
```swift
actor QueryHandlerWithSWR {
    private var cachedResult: Result?
    private var isFetching = false
    
    func handle(_ query: Query) async throws -> Result {
        if let cached = cachedResult {
            // Retornar cached inmediatamente
            if !isFetching {
                // Refrescar en background
                Task { await refresh() }
            }
            return cached
        }
        
        return try await fetch()
    }
}
```

---

## Error Handling Patterns

### Jerarquía de Errores

```swift
public enum MediatorError: Error, CustomStringConvertible {
    case handlerNotFound(queryOrCommandType: String)
    case registrationError(message: String, underlyingError: Error?)
    case validationError(message: String, underlyingError: Error?)
    case executionError(message: String, underlyingError: Error?)
    
    public var description: String {
        switch self {
        case .handlerNotFound(let type):
            return "No handler registered for: \(type)"
        case .registrationError(let msg, let error):
            return "Registration failed: \(msg). Underlying: \(error?.localizedDescription ?? "none")"
        case .validationError(let msg, let error):
            return "Validation failed: \(msg). Underlying: \(error?.localizedDescription ?? "none")"
        case .executionError(let msg, let error):
            return "Execution failed: \(msg). Underlying: \(error?.localizedDescription ?? "none")"
        }
    }
}
```

### Propagación de Errores

```
Command/Query
    │
    ├─> validate() throws ValidationError
    │       │
    │       └─> Mediator captura y envuelve en MediatorError.validationError
    │
    ├─> Handler.handle() throws DomainError
    │       │
    │       └─> Mediator captura y envuelve en MediatorError.executionError
    │
    └─> ViewModel captura MediatorError y muestra al usuario
```

### Ejemplo de Manejo en ViewModel

```swift
class LoginViewModel {
    let mediator: Mediator
    @Published var errorMessage: String?
    
    func login(username: String, password: String) async {
        do {
            let result = try await mediator.execute(
                LoginCommand(username: username, password: password)
            )
            
            if result.isSuccess {
                // Navigate to home
            }
            
        } catch MediatorError.validationError(let msg, _) {
            errorMessage = "Datos inválidos: \(msg)"
            
        } catch MediatorError.executionError(let msg, let underlying) {
            if let authError = underlying as? AuthError {
                errorMessage = handleAuthError(authError)
            } else {
                errorMessage = "Error al iniciar sesión: \(msg)"
            }
            
        } catch {
            errorMessage = "Error inesperado: \(error.localizedDescription)"
        }
    }
}
```

---

## Concurrency Guarantees

### Swift 6 Strict Concurrency

El módulo está compilado con:
```swift
.enableExperimentalFeature("StrictConcurrency=complete")
```

Esto garantiza:
- ✅ No data races en compile-time
- ✅ Sendable checked exhaustivamente
- ✅ Actor isolation verificada

### Actor Isolation

#### Mediator como Actor

```swift
public actor Mediator {
    // Todo el estado es aislado al actor
    private let registry: MediatorRegistry
    private let logger: Logger
    
    // Dispatch serializado
    public func send<Q: Query>(_ query: Q) async throws -> Q.Result {
        // Solo un dispatch a la vez por actor
    }
}
```

**Garantías**:
- Un dispatch a la vez (serialización)
- No hay data races en el registry
- Logging thread-safe

#### Handlers como Actors

```swift
actor GetDashboardQueryHandler: QueryHandler {
    // Estado mutable aislado
    private var cachedResult: Dashboard?
    private let useCase: GetDashboardUseCase
    
    // Acceso serializado
    func handle(_ query: GetDashboardQuery) async throws -> Dashboard {
        // Solo una ejecución a la vez
        if let cached = cachedResult { return cached }
        let result = try await useCase.execute()
        cachedResult = result
        return result
    }
}
```

**Garantías**:
- Cache mutations son thread-safe
- No hay concurrent access al estado mutable

### Sendable Requirements

Todos los tipos que cruzan boundaries deben ser `Sendable`:

```swift
// ✅ Query es Sendable
struct GetUserQuery: Query, Sendable {
    let userId: String  // String es Sendable
}

// ❌ Query con tipo no-Sendable falla en compile-time
struct BadQuery: Query {
    let callback: () -> Void  // ❌ Closures no son Sendable por defecto
}
```

---

## Testing Strategy

### Unit Tests: Componentes Core

Testear protocolos y lógica aislada:

```swift
func testQueryProtocolConformance() {
    struct TestQuery: Query {
        typealias Result = Int
        let value: Int
    }
    
    let query = TestQuery(value: 42)
    XCTAssertEqual(query.value, 42)
}
```

### Integration Tests: Mediator Dispatch

Testear flujo completo con handlers reales:

```swift
func testMediatorQueryDispatch() async throws {
    // Setup
    let mediator = Mediator(loggingEnabled: false)
    try await mediator.registerQueryHandler(MockQueryHandler())
    
    // Execute
    let result = try await mediator.send(MockQuery(value: 42))
    
    // Assert
    XCTAssertEqual(result, 42)
}
```

### Testing con Mocks

```swift
actor MockQueryHandler: QueryHandler {
    typealias QueryType = MockQuery
    var handleCallCount = 0
    
    func handle(_ query: MockQuery) async throws -> Int {
        handleCallCount += 1
        return query.value * 2
    }
}

func testHandlerCalled() async throws {
    let handler = MockQueryHandler()
    let mediator = Mediator()
    try await mediator.registerQueryHandler(handler)
    
    _ = try await mediator.send(MockQuery(value: 10))
    
    let count = await handler.handleCallCount
    XCTAssertEqual(count, 1)
}
```

### Testing Concurrencia

```swift
func testConcurrentDispatch() async throws {
    let mediator = Mediator()
    try await mediator.registerQueryHandler(MockQueryHandler())
    
    // Dispatch 100 queries concurrentemente
    await withTaskGroup(of: Int.self) { group in
        for i in 0..<100 {
            group.addTask {
                try! await mediator.send(MockQuery(value: i))
            }
        }
    }
    
    // Sin crashes = actor isolation funciona
}
```

---

## Decisiones Arquitectónicas

Para un log completo de decisiones técnicas, ver [DecisionLog.md](DecisionLog.md).

## Próximos Pasos

1. **Sprint 4**: Implementar EventBus con Domain Events
2. **Sprint 5**: Read Models optimizados con cache strategies avanzadas
3. **Sprint 6**: Event Sourcing para audit trail completo

---

**Última actualización**: 2026-01-30  
**Versión**: 1.0.0  
**Autores**: Equipo de Arquitectura EduGo
