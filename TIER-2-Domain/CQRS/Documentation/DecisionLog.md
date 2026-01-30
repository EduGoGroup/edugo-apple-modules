# CQRS Decision Log

Registro de decisiones arquitectónicas (ADRs - Architecture Decision Records) para el módulo CQRS.

## Formato

Cada decisión sigue este formato:

- **Fecha**: Cuándo se tomó la decisión
- **Estado**: Aceptada | Rechazada | Superseded | Propuesta
- **Contexto**: Por qué necesitamos tomar esta decisión
- **Decisión**: Qué decidimos hacer
- **Consecuencias**: Qué implica esta decisión (trade-offs)
- **Alternativas Consideradas**: Qué otras opciones evaluamos

---

## ADR-001: Usar Mediator Pattern en lugar de llamadas directas

**Fecha**: 2026-01-15  
**Estado**: Aceptada

### Contexto

Los ViewModels necesitan ejecutar queries y commands. Tenemos dos opciones:
1. ViewModels conocen y llaman directamente a QueryHandlers/CommandHandlers
2. ViewModels usan un Mediator que despacha a los handlers

### Decisión

Implementar un Mediator centralizado que actúa como dispatcher entre ViewModels y handlers.

### Consecuencias

**Positivas**:
- ✅ Desacoplamiento: ViewModels no conocen implementaciones específicas
- ✅ Testabilidad: Mock del Mediator es más simple que N handlers
- ✅ Centralización: Logging, métricas y políticas en un solo lugar
- ✅ Flexibilidad: Cambiar handlers sin tocar ViewModels

**Negativas**:
- ❌ Indirección adicional (overhead mínimo por el actor dispatch)
- ❌ Complejidad: Un componente más en la arquitectura

### Alternativas Consideradas

**Opción 1: Inyección directa de handlers**
```swift
class ViewModel {
    let dashboardHandler: GetDashboardHandler
    let materialsHandler: GetMaterialsHandler
    // ... N handlers
}
```
- ❌ Tight coupling
- ❌ Constructor bloat (muchas dependencias)
- ❌ Difícil de mockear en tests

**Opción 2: Service Locator**
```swift
class ViewModel {
    func load() {
        let handler = ServiceLocator.resolve(GetDashboardHandler.self)
    }
}
```
- ❌ Anti-pattern: dependencias ocultas
- ❌ No compile-time safety
- ❌ Difícil de rastrear dependencias

---

## ADR-002: Mediator y Handlers como Actors

**Fecha**: 2026-01-15  
**Estado**: Aceptada

### Contexto

Swift 6 introduce strict concurrency. Necesitamos garantizar thread-safety en:
- Mediator (dispatch centralizado)
- MediatorRegistry (almacena handlers)
- Handlers (pueden tener estado mutable como cache)

### Decisión

Implementar Mediator, MediatorRegistry y todos los handlers como actors.

### Consecuencias

**Positivas**:
- ✅ No data races garantizados en compile-time
- ✅ Actor isolation automática
- ✅ Sendable checked por el compilador
- ✅ Elimina necesidad de locks manuales

**Negativas**:
- ❌ Overhead de dispatch a actor (microsegundos)
- ❌ Todo método es async (propagación de async)
- ❌ Curva de aprendizaje de actors para el equipo

### Alternativas Consideradas

**Opción 1: GCD con DispatchQueue**
```swift
class Mediator {
    private let queue = DispatchQueue(label: "mediator")
    func send() { queue.async { ... } }
}
```
- ❌ Data races posibles si se olvida queue.async
- ❌ No compile-time checking
- ❌ Difícil de razonar sobre thread-safety

**Opción 2: NSLock / os_unfair_lock**
```swift
class Mediator {
    private let lock = NSLock()
    func send() { lock.lock(); defer { lock.unlock() }; ... }
}
```
- ❌ Locks manuales propensos a errores
- ❌ Posibles deadlocks
- ❌ No compile-time checking

---

## ADR-003: Type Erasure en MediatorRegistry

**Fecha**: 2026-01-16  
**Estado**: Aceptada

### Contexto

El MediatorRegistry necesita almacenar handlers de diferentes tipos (heterogéneos) en un diccionario. Swift no permite `[ObjectIdentifier: QueryHandler]` porque QueryHandler tiene associated types.

### Decisión

Usar type erasure para almacenar handlers como `Any` y hacer runtime cast al recuperarlos.

```swift
var queryHandlers: [ObjectIdentifier: Any] = [:]

func register<H: QueryHandler>(_ handler: H) {
    let key = ObjectIdentifier(H.QueryType.self)
    queryHandlers[key] = handler  // Type erasure
}

func getHandler<Q: Query>(for: Q.Type) -> any QueryHandler {
    let key = ObjectIdentifier(Q.self)
    return queryHandlers[key] as! any QueryHandler  // Runtime cast
}
```

### Consecuencias

**Positivas**:
- ✅ Permite almacenar handlers heterogéneos en un diccionario
- ✅ API público del Mediator sigue siendo type-safe
- ✅ Runtime cast es seguro (key matching garantiza tipo correcto)

**Negativas**:
- ❌ Runtime cast en lugar de compile-time safety
- ❌ Force cast (`as!`) puede crashear si hay bug en el key matching

### Alternativas Consideradas

**Opción 1: Diccionario por tipo específico**
```swift
var getDashboardHandlers: [ObjectIdentifier: GetDashboardQueryHandler] = [:]
var getUserHandlers: [ObjectIdentifier: GetUserQueryHandler] = [:]
// ... N diccionarios
```
- ❌ No escala (un diccionario por tipo)
- ❌ Imposible implementar genéricamente

**Opción 2: Protocol Wrapper con type erasure manual**
```swift
struct AnyQueryHandler: QueryHandler {
    private let _handle: (Any) async throws -> Any
    func handle<Q>(_ query: Q) async throws -> Q.Result {
        try await _handle(query) as! Q.Result
    }
}
```
- ❌ Más complejidad sin beneficio claro
- ❌ Sigue requiriendo runtime cast

---

## ADR-004: Weak References para Cache Invalidation (Temporal)

**Fecha**: 2026-01-16  
**Estado**: Aceptada (temporal hasta Sprint 4)

### Contexto

Los Commands necesitan invalidar cache de Queries relacionadas. Sin EventBus (planificado para Sprint 4), necesitamos una solución temporal.

### Decisión

Usar weak references desde CommandHandlers a QueryHandlers para invalidar cache directamente.

```swift
actor SubmitAssessmentHandler: CommandHandler {
    weak var dashboardHandler: GetDashboardQueryHandler?
    
    func handle(_ command: SubmitAssessmentCommand) async throws -> CommandResult {
        let result = try await useCase.execute(command)
        await dashboardHandler?.invalidateCache()  // Weak ref
        return CommandResult(result: result)
    }
}
```

### Consecuencias

**Positivas**:
- ✅ Solución simple que funciona para MVP
- ✅ No requiere EventBus (que no está implementado aún)
- ✅ Cache invalidation funcional

**Negativas**:
- ❌ Tight coupling entre handlers
- ❌ No escala (N commands × M queries)
- ❌ Weak refs pueden ser nil inesperadamente
- ❌ Difícil de mantener

### Alternativas Consideradas

**Opción 1: Sin cache invalidation**
- ❌ Datos stale en UI
- ❌ Usuarios ven información desactualizada

**Opción 2: TTL-based cache**
```swift
private var cachedResult: (data: Result, expiry: Date)?
```
- ⚠️ Usuarios pueden ver datos stale hasta que expire el TTL
- ⚠️ TTL corto = muchas fetches, TTL largo = datos stale

**Decisión Final**: Usar weak refs temporalmente y migrar a EventBus en Sprint 4.

---

## ADR-005: EventBus como Solución Final para Cache Invalidation

**Fecha**: 2026-01-16  
**Estado**: Propuesta (implementación Sprint 4)

### Contexto

La solución actual de weak refs (ADR-004) no escala. Necesitamos desacoplar completamente Commands de Queries.

### Decisión

Implementar un EventBus con Domain Events para notificar cambios en el sistema.

```swift
// Command publica evento
await eventBus.publish(AssessmentSubmittedEvent(
    assessmentId: command.assessmentId,
    studentId: command.studentId
))

// Subscriber invalida cache
actor CacheInvalidationSubscriber: EventSubscriber {
    func handle(_ event: AssessmentSubmittedEvent) async {
        await invalidateDashboard(studentId: event.studentId)
        await invalidateAssessments(studentId: event.studentId)
    }
}
```

### Consecuencias

**Positivas**:
- ✅ Desacoplamiento total: Commands no conocen Queries
- ✅ Escala: agregar queries no requiere modificar commands
- ✅ Extensible: agregar subscribers sin cambiar código existente
- ✅ Audit trail: eventos se pueden persistir para auditoría
- ✅ Testeable: mock del EventBus es trivial

**Negativas**:
- ❌ Complejidad adicional: un componente más (EventBus)
- ❌ Event processing puede fallar silenciosamente si no hay monitoring
- ❌ Debugging más difícil (flujo indirecto)

### Alternativas Consideradas

**Opción 1: Observer Pattern directo**
```swift
class Command {
    var observers: [QueryHandler] = []
    func notifyObservers() { ... }
}
```
- ❌ Sigue teniendo coupling (commands conocen handlers)
- ❌ No proporciona audit trail

**Opción 2: Notification Center**
```swift
NotificationCenter.default.post(name: "AssessmentSubmitted", ...)
```
- ❌ Stringly-typed (no type safety)
- ❌ Payload sin tipo (Any)

---

## ADR-006: CommandResult Wrapper para Encapsular Eventos

**Fecha**: 2026-01-17  
**Estado**: Aceptada

### Contexto

Los Commands deben retornar tanto el resultado de la operación como los eventos generados. Necesitamos un wrapper type-safe.

### Decisión

Implementar `CommandResult<T>` que encapsula resultado + eventos.

```swift
public struct CommandResult<T: Sendable>: Sendable {
    public let result: T
    public let events: [String]
    public let metadata: [String: String]
    public var isSuccess: Bool { !events.isEmpty }
}
```

### Consecuencias

**Positivas**:
- ✅ Type-safe: `CommandResult<AuthResult>` garantiza tipo correcto
- ✅ Eventos explícitos en la firma del método
- ✅ Metadata adicional para contexto

**Negativas**:
- ❌ Overhead mínimo (wrapper struct)
- ❌ Queries no usan wrapper (asimetría con Commands)

### Alternativas Consideradas

**Opción 1: Tupla (Result, [String])**
```swift
func handle() async throws -> (AuthResult, [String])
```
- ❌ Menos expresivo
- ❌ No semántica de "success" explícita

**Opción 2: Resultado directo + side effect de eventos**
```swift
func handle() async throws -> AuthResult {
    // Eventos se publican vía EventBus directamente
}
```
- ❌ Eventos no visibles en la firma
- ❌ Requiere EventBus (no disponible en Sprint 1-3)

---

## ADR-007: Metadata como [String: String] en lugar de Typed

**Fecha**: 2026-01-17  
**Estado**: Aceptada

### Contexto

Queries y Commands necesitan llevar metadata opcional (trace IDs, user context, correlation IDs). ¿Debe ser typed o stringly?

### Decisión

Usar `[String: String]?` para metadata.

```swift
protocol Query {
    var metadata: [String: String]? { get }
}
```

### Consecuencias

**Positivas**:
- ✅ Flexibilidad: agregar metadata sin cambiar protocolos
- ✅ Interoperabilidad: fácil de serializar/deserializar
- ✅ Simplicidad: no requiere tipos complejos

**Negativas**:
- ❌ No type-safe: `metadata["userId"]` puede retornar nil
- ❌ Stringly-typed: typos en keys no se detectan en compile-time
- ❌ No autocomplete para keys conocidas

### Alternativas Consideradas

**Opción 1: Struct typed**
```swift
struct Metadata {
    let traceId: String?
    let userId: String?
    let correlationId: String?
}
```
- ❌ No extensible: agregar fields requiere cambiar struct
- ❌ Overhead de tipos adicionales

**Opción 2: Protocol**
```swift
protocol QueryMetadata {
    var traceId: String? { get }
}
```
- ❌ Complejidad innecesaria para metadata opcional

**Decisión Final**: Usar `[String: String]?` con convención de keys documentadas.

---

## ADR-008: OSLog para Structured Logging

**Fecha**: 2026-01-18  
**Estado**: Aceptada

### Contexto

El Mediator necesita logging para debugging y observabilidad. Opciones: print(), OSLog, third-party logger.

### Decisión

Usar OSLog con structured logging para todas las operaciones del Mediator.

```swift
import OSLog

let logger = Logger(subsystem: "com.edugo.cqrs", category: "Mediator")
logger.debug("Dispatching query: \(queryType, privacy: .public)")
```

### Consecuencias

**Positivas**:
- ✅ Integración nativa con Instruments
- ✅ Performance: OSLog es extremadamente rápido
- ✅ Structured logging con privacy annotations
- ✅ No dependencias externas

**Negativas**:
- ❌ Solo funciona en plataformas Apple
- ❌ Menos features que loggers de terceros (ej: file output)

### Alternativas Consideradas

**Opción 1: print() / NSLog**
- ❌ No structured
- ❌ No privacy controls
- ❌ Performance pobre

**Opción 2: Third-party logger (SwiftLog, CocoaLumberjack)**
- ❌ Dependencia externa
- ❌ Overhead adicional

---

## ADR-009: Handlers como Actors (no Structs)

**Fecha**: 2026-01-18  
**Estado**: Aceptada

### Contexto

Los handlers necesitan almacenar estado mutable (cache, conexiones, etc.). ¿Deben ser actors, structs o classes?

### Decisión

Todos los handlers DEBEN ser actors.

```swift
actor GetDashboardQueryHandler: QueryHandler {
    private var cachedResult: Dashboard?
    // ...
}
```

### Consecuencias

**Positivas**:
- ✅ Thread-safety garantizada
- ✅ Sendable implícito (actors son Sendable)
- ✅ No data races posibles

**Negativas**:
- ❌ Todo acceso es async
- ❌ No se pueden usar structs stateless (aunque serían más performantes)

### Alternativas Consideradas

**Opción 1: Structs stateless**
```swift
struct GetDashboardQueryHandler: QueryHandler {
    func handle() async throws -> Dashboard { ... }
}
```
- ✅ Más performantes (no actor dispatch)
- ❌ No pueden tener cache (estado mutable)

**Opción 2: Classes con locks**
```swift
class GetDashboardQueryHandler: QueryHandler {
    private let lock = NSLock()
    private var cachedResult: Dashboard?
}
```
- ❌ Data races posibles
- ❌ Deadlocks posibles

---

## ADR-010: Swift 6 Language Mode Obligatorio

**Fecha**: 2026-01-18  
**Estado**: Aceptada

### Contexto

Swift 6 introduce strict concurrency checking. ¿Deberíamos usarlo o quedarnos en Swift 5 mode?

### Decisión

Compilar el módulo con Swift 6 language mode y strict concurrency habilitado.

```swift
.swiftLanguageMode(.v6),
.enableExperimentalFeature("StrictConcurrency=complete")
```

### Consecuencias

**Positivas**:
- ✅ No data races garantizados en compile-time
- ✅ Sendable checking exhaustivo
- ✅ Future-proof (Swift 6 es el futuro)

**Negativas**:
- ❌ Curva de aprendizaje para el equipo
- ❌ Más errores de compilación iniciales
- ❌ Algunas APIs de third-party pueden no ser compatibles

### Alternativas Consideradas

**Opción 1: Swift 5 mode**
- ❌ No compile-time checking de concurrency
- ❌ Technical debt futuro

**Opción 2: Swift 6 sin strict concurrency**
- ⚠️ Algunos checks pero no todos

---

## Decisiones Pendientes

### PEN-001: Read Models Optimizados

**Contexto**: Algunas queries son pesadas y requieren joins complejos. ¿Deberíamos crear read models optimizados?

**Opciones**:
1. Materializar vistas denormalizadas
2. CQRS con bases de datos separadas (read/write)
3. Cache agresivo con TTL

**Estado**: Pendiente de evaluación en Sprint 5

---

### PEN-002: Event Sourcing para Audit Trail

**Contexto**: Necesitamos audit trail completo de todas las operaciones. ¿Implementar Event Sourcing?

**Opciones**:
1. Event Sourcing completo (todos los commands son eventos)
2. Event logging híbrido (solo eventos importantes)
3. Database audit trail tradicional

**Estado**: Pendiente de evaluación en Sprint 6+

---

## Decisiones Rechazadas

### REJ-001: CQRS con Bases de Datos Separadas

**Fecha**: 2026-01-19  
**Estado**: Rechazada (para MVP)

**Contexto**: CQRS purists sugieren bases de datos separadas para read/write.

**Decisión**: NO implementar por ahora.

**Razones**:
- ❌ Over-engineering para el MVP
- ❌ Complejidad operacional (sincronización)
- ❌ Latency de eventual consistency

**Posible Re-evaluación**: Sprint 8+ si la escala lo requiere

---

**Última actualización**: 2026-01-30  
**Versión**: 1.0.0
