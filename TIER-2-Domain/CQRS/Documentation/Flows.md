# CQRS Flow Diagrams

Diagramas de flujo de los principales procesos en el módulo CQRS.

## Tabla de Contenidos

1. [Query Flow](#query-flow)
2. [Command Flow](#command-flow)
3. [Handler Registration Flow](#handler-registration-flow)
4. [Cache Invalidation Flow (Actual)](#cache-invalidation-flow-actual)
5. [Cache Invalidation Flow (Futuro con EventBus)](#cache-invalidation-flow-futuro-con-eventbus)
6. [Error Handling Flow](#error-handling-flow)

---

## Query Flow

Flujo completo de una Query desde el ViewModel hasta el Repository.

```mermaid
sequenceDiagram
    actor User
    participant VM as ViewModel
    participant M as Mediator (Actor)
    participant R as Registry
    participant QH as QueryHandler (Actor)
    participant UC as UseCase
    participant Repo as Repository

    User->>VM: Trigger action (e.g., load dashboard)
    VM->>M: send(GetDashboardQuery)
    
    M->>M: Log: "Dispatching query: GetDashboardQuery"
    
    M->>R: getQueryHandler(for: GetDashboardQuery.self)
    R-->>M: QueryHandler instance
    
    M->>QH: handle(query)
    
    QH->>QH: Check cache
    
    alt Cache Hit
        QH-->>M: Cached result
    else Cache Miss
        QH->>UC: execute(params)
        UC->>Repo: fetch data
        Repo-->>UC: data
        UC-->>QH: result
        QH->>QH: Store in cache
        QH-->>M: result
    end
    
    M->>M: Type-cast result to Q.Result
    M->>M: Log: "Query executed successfully"
    M-->>VM: StudentDashboard
    VM->>VM: Update @Published properties
    VM-->>User: Display data
```

**Puntos Clave**:
1. Mediator serializa el dispatch (actor isolation)
2. QueryHandler puede usar cache internamente
3. Type safety garantizada por Swift generics
4. Logging estructurado en cada paso

---

## Command Flow

Flujo completo de un Command con validación y generación de eventos.

```mermaid
sequenceDiagram
    actor User
    participant VM as ViewModel
    participant M as Mediator (Actor)
    participant C as Command
    participant R as Registry
    participant CH as CommandHandler (Actor)
    participant UC as UseCase
    participant Repo as Repository
    participant Cache as Query Handlers (Cache)

    User->>VM: Trigger action (e.g., submit assessment)
    VM->>M: execute(SubmitAssessmentCommand)
    
    M->>M: Log: "Executing command: SubmitAssessmentCommand"
    
    M->>C: validate()
    
    alt Validation Fails
        C-->>M: throw ValidationError
        M->>M: Log: "Validation failed"
        M-->>VM: throw MediatorError.validationError
        VM-->>User: Show error message
    else Validation Success
        M->>R: getCommandHandler(for: SubmitAssessmentCommand.self)
        R-->>M: CommandHandler instance
        
        M->>CH: handle(command)
        
        CH->>UC: execute(command)
        UC->>Repo: persist data
        Repo-->>UC: success
        UC-->>CH: result
        
        CH->>Cache: invalidateCache() (weak ref)
        
        CH->>CH: Generate events
        CH-->>M: CommandResult(result, events)
        
        M->>M: Type-cast result
        M->>M: Log: "Command executed successfully"
        M-->>VM: CommandResult
        VM->>VM: Update UI
        VM-->>User: Show success
    end
```

**Puntos Clave**:
1. Validación pre-ejecución obligatoria
2. CommandHandler genera eventos
3. Cache invalidation manual (temporal)
4. CommandResult encapsula resultado + eventos

---

## Handler Registration Flow

Flujo de registro de handlers en el Mediator.

```mermaid
sequenceDiagram
    participant App as Application
    participant M as Mediator
    participant R as MediatorRegistry (Actor)
    participant H as Handler (Actor)

    App->>M: registerQueryHandler(handler)
    
    M->>R: registerQueryHandler(handler)
    
    R->>R: Get ObjectIdentifier(QueryType.self)
    
    alt Handler Already Exists
        R-->>M: throw MediatorError.registrationError
        M-->>App: throw error
    else Handler Not Exists
        R->>R: Store handler with type erasure (Any)
        R->>R: queryHandlers[id] = handler
        R-->>M: success
        M->>M: Log: "Registered query handler"
        M-->>App: success
    end
```

**Type Erasure**:
```swift
// Registry almacena handlers heterogéneos
var queryHandlers: [ObjectIdentifier: Any] = [:]

// Registro con type erasure
let key = ObjectIdentifier(H.QueryType.self)
queryHandlers[key] = handler  // Any

// Recuperación con runtime cast
let handler = queryHandlers[key] as! any QueryHandler
```

---

## Cache Invalidation Flow (Actual)

Estrategia actual usando weak references entre handlers.

```mermaid
sequenceDiagram
    participant VM as ViewModel
    participant M as Mediator
    participant CH as CommandHandler
    participant QH1 as QueryHandler 1 (Dashboard)
    participant QH2 as QueryHandler 2 (Materials)

    VM->>M: execute(SubmitAssessmentCommand)
    M->>CH: handle(command)
    
    CH->>CH: Execute business logic
    
    Note over CH: Manual cache invalidation
    
    CH->>QH1: invalidateCache() (weak ref)
    QH1->>QH1: cachedResult = nil
    
    CH->>QH2: invalidateCache() (weak ref)
    QH2->>QH2: cachedResult = nil
    
    CH-->>M: CommandResult
    M-->>VM: Success
    
    Note over VM: Next query fetch will<br/>bypass cache
```

**Limitaciones**:
- ❌ Tight coupling: CommandHandler conoce QueryHandlers específicos
- ❌ No escala: N commands × M queries
- ❌ Weak references pueden ser nil inesperadamente
- ❌ Difícil de testear

---

## Cache Invalidation Flow (Futuro con EventBus)

Estrategia futura usando Domain Events para desacoplar.

```mermaid
sequenceDiagram
    participant VM as ViewModel
    participant M as Mediator
    participant CH as CommandHandler
    participant EB as EventBus
    participant CIS as CacheInvalidationSubscriber
    participant QH1 as QueryHandler 1
    participant QH2 as QueryHandler 2
    participant QH3 as QueryHandler 3

    VM->>M: execute(SubmitAssessmentCommand)
    M->>CH: handle(command)
    
    CH->>CH: Execute business logic
    
    Note over CH: Publish domain event
    CH->>EB: publish(AssessmentSubmittedEvent)
    
    CH-->>M: CommandResult
    M-->>VM: Success
    
    Note over EB: Event distribution
    
    EB->>CIS: handle(AssessmentSubmittedEvent)
    
    CIS->>CIS: Determine affected queries
    
    par Invalidate Multiple Caches
        CIS->>QH1: invalidateCache()
        QH1->>QH1: Clear cache
        and
        CIS->>QH2: invalidateCache()
        QH2->>QH2: Clear cache
        and
        CIS->>QH3: invalidateCache()
        QH3->>QH3: Clear cache
    end
    
    CIS-->>EB: Invalidation complete
```

**Beneficios**:
- ✅ Desacoplamiento total: CommandHandler no conoce QueryHandlers
- ✅ Escala: agregar queries no requiere modificar commands
- ✅ Extensible: agregar subscribers sin cambiar código existente
- ✅ Testeable: mock del EventBus es trivial

**Implementación en Sprint 4**:
```swift
// Domain Event
struct AssessmentSubmittedEvent: DomainEvent {
    let assessmentId: String
    let studentId: String
    let timestamp: Date
}

// CommandHandler publica evento
actor SubmitAssessmentHandler: CommandHandler {
    let eventBus: EventBus
    
    func handle(_ command: SubmitAssessmentCommand) async throws -> CommandResult {
        let result = try await useCase.execute(command)
        
        // Publicar evento - desacoplado
        await eventBus.publish(AssessmentSubmittedEvent(
            assessmentId: command.assessmentId,
            studentId: command.studentId,
            timestamp: Date()
        ))
        
        return CommandResult(result: result, events: ["AssessmentSubmitted"])
    }
}

// Subscriber maneja invalidación
actor CacheInvalidationSubscriber: EventSubscriber {
    let mediator: Mediator
    
    func handle(_ event: AssessmentSubmittedEvent) async {
        // Estrategia: invalidar queries que dependan de assessments del student
        await invalidateDashboard(studentId: event.studentId)
        await invalidateAssessmentsList(studentId: event.studentId)
    }
}
```

---

## Error Handling Flow

Flujo de propagación y manejo de errores en el sistema.

```mermaid
sequenceDiagram
    participant VM as ViewModel
    participant M as Mediator
    participant C as Command
    participant CH as CommandHandler
    participant UC as UseCase

    VM->>M: execute(command)
    
    M->>C: validate()
    
    alt Validation Error
        C-->>M: throw ValidationError
        M->>M: Wrap in MediatorError.validationError
        M->>M: Log error
        M-->>VM: throw MediatorError
        VM->>VM: Handle validation error
        VM-->>VM: Show user-friendly message
    else Validation Success
        M->>CH: handle(command)
        
        CH->>UC: execute()
        
        alt Business Logic Error
            UC-->>CH: throw DomainError
            CH-->>M: throw DomainError
            M->>M: Wrap in MediatorError.executionError
            M->>M: Log error with underlying
            M-->>VM: throw MediatorError
            VM->>VM: Handle execution error
            VM-->>VM: Show error with context
        else Success
            UC-->>CH: result
            CH-->>M: CommandResult
            M-->>VM: Success
        end
    end
```

**Error Hierarchy**:
```
MediatorError (top-level)
├── handlerNotFound
│   └── Cuando no hay handler registrado
├── registrationError
│   └── Cuando falla registro de handler
├── validationError
│   └── Cuando Command.validate() falla
│       └── underlyingError: ValidationError (del dominio)
└── executionError
    └── Cuando Handler.handle() falla
        └── underlyingError: DomainError (del caso de uso)
```

---

## Handler Lifecycle

Diagrama de estados de un handler durante su ciclo de vida.

```mermaid
stateDiagram-v2
    [*] --> Created: new Handler()
    
    Created --> Registered: Mediator.registerHandler()
    
    Registered --> Idle: Waiting for dispatch
    
    Idle --> Executing: Mediator.send/execute()
    
    Executing --> Idle: Successful execution
    Executing --> Error: Execution fails
    
    Error --> Idle: Error handled
    
    Idle --> Unregistered: Mediator.unregisterHandler()
    
    Unregistered --> [*]
    
    note right of Registered
        Handler stored in Registry
        with type erasure (Any)
    end note
    
    note right of Executing
        Actor serializes access
        Only one execution at a time
    end note
```

---

## Concurrent Dispatch Flow

Cómo el Mediator maneja múltiples dispatches concurrentes.

```mermaid
sequenceDiagram
    participant VM1 as ViewModel 1
    participant VM2 as ViewModel 2
    participant VM3 as ViewModel 3
    participant M as Mediator (Actor)
    participant QH as QueryHandler (Actor)

    Note over M: Actor serializes all access
    
    par Concurrent Calls
        VM1->>M: send(Query1)
        and
        VM2->>M: send(Query2)
        and
        VM3->>M: send(Query3)
    end
    
    Note over M: Actor processes one at a time
    
    M->>QH: handle(Query1)
    QH-->>M: Result1
    M-->>VM1: Result1
    
    M->>QH: handle(Query2)
    QH-->>M: Result2
    M-->>VM2: Result2
    
    M->>QH: handle(Query3)
    QH-->>M: Result3
    M-->>VM3: Result3
    
    Note over M,QH: No data races:<br/>Actor isolation guarantees<br/>sequential processing
```

**Garantías de Concurrencia**:
1. Mediator (actor) serializa dispatches
2. QueryHandler (actor) serializa ejecuciones
3. No data races por diseño (Swift 6 strict concurrency)
4. Sendable checked en compile-time

---

## Performance Considerations

### Query con Cache Hit

```
ViewModel → Mediator → QueryHandler (cache hit)
   ↓           ↓              ↓
  1ms        2ms           0.1ms (memoria)
                          ↓
                       Total: ~3ms
```

### Query con Cache Miss

```
ViewModel → Mediator → QueryHandler → UseCase → Repository → Network
   ↓           ↓            ↓           ↓           ↓           ↓
  1ms        2ms         0.5ms       5ms        50ms       200ms
                                                              ↓
                                                         Total: ~258ms
```

### Command con Cache Invalidation

```
ViewModel → Mediator → CommandHandler → UseCase → Repository
   ↓           ↓            ↓              ↓           ↓
  1ms        2ms         0.5ms          5ms        100ms
                            ↓
                    invalidateCache() × 3 handlers
                            ↓
                          3ms
                            ↓
                       Total: ~111ms
```

---

**Última actualización**: 2026-01-30  
**Versión**: 1.0.0
