# CQRS Module

Implementación del patrón CQRS (Command Query Responsibility Segregation) para la aplicación EduGo Apple. Este módulo proporciona una separación clara entre operaciones de lectura (Queries) y escritura (Commands), con un Mediator centralizado para el dispatch type-safe.

## Características

- **Separación CQRS**: Queries inmutables vs Commands con side effects
- **Mediator Pattern**: Dispatch centralizado con type erasure
- **Swift 6 Strict Concurrency**: Actor-based isolation con garantías Sendable
- **Structured Logging**: Integración con OSLog para debugging y observabilidad
- **Type-Safe**: El sistema de tipos de Swift garantiza correctitud en compile-time
- **Validación**: Commands con hooks de validación pre-ejecución
- **Event-Driven Ready**: Arquitectura preparada para Domain Events (próximamente)

## Requisitos

- Swift 6.2+
- iOS 26+ / macOS 26+
- Strict Concurrency habilitado

## Instalación

Este módulo es parte del workspace de EduGo Apple y depende de:
- `EduGoCommon` (TIER-0)
- `Models` (TIER-1)
- `UseCases` (TIER-2)

```swift
dependencies: [
    .package(path: "../../TIER-2-Domain/CQRS")
]
```

## Quick Start

### 1. Definir una Query

```swift
import CQRS

struct GetUserContextQuery: Query {
    typealias Result = UserContext
    
    let userId: String
    var metadata: [String: String]?
}
```

### 2. Implementar el QueryHandler

```swift
actor GetUserContextQueryHandler: QueryHandler {
    typealias QueryType = GetUserContextQuery
    
    private let useCase: GetUserContextUseCase
    
    init(useCase: GetUserContextUseCase) {
        self.useCase = useCase
    }
    
    func handle(_ query: GetUserContextQuery) async throws -> UserContext {
        try await useCase.execute(userId: query.userId)
    }
}
```

### 3. Registrar y Ejecutar

```swift
// Setup (en AppDelegate o inicio de la app)
let mediator = Mediator()
try await mediator.registerQueryHandler(
    GetUserContextQueryHandler(useCase: getUserContextUseCase)
)

// Uso desde ViewModel
let userContext = try await mediator.send(
    GetUserContextQuery(userId: "user-123")
)
```

### Ejemplo con Command

```swift
// 1. Definir Command
struct LoginCommand: Command {
    typealias Result = AuthResult
    
    let username: String
    let password: String
    
    func validate() throws {
        guard !username.isEmpty else {
            throw ValidationError.emptyUsername
        }
        guard password.count >= 8 else {
            throw ValidationError.passwordTooShort
        }
    }
}

// 2. Implementar Handler
actor LoginCommandHandler: CommandHandler {
    typealias CommandType = LoginCommand
    
    private let authUseCase: AuthenticateUserUseCase
    
    func handle(_ command: LoginCommand) async throws -> CommandResult<AuthResult> {
        let authResult = try await authUseCase.execute(
            username: command.username,
            password: command.password
        )
        
        return CommandResult(
            result: authResult,
            events: ["UserLoggedIn"],
            metadata: ["userId": authResult.userId]
        )
    }
}

// 3. Ejecutar
let result = try await mediator.execute(
    LoginCommand(username: "john", password: "secure123")
)

if result.isSuccess {
    print("Login exitoso: \(result.result)")
    print("Eventos generados: \(result.events)")
}
```

## Estructura del Módulo

```
CQRS/
├── Sources/CQRS/
│   ├── Core/                      # Protocolos base
│   │   ├── Query.swift            # Protocol Query
│   │   ├── QueryHandler.swift    # Protocol QueryHandler
│   │   ├── Command.swift          # Protocol Command
│   │   ├── CommandHandler.swift  # Protocol CommandHandler
│   │   └── CommandResult.swift   # Wrapper de resultados
│   │
│   ├── Mediator/                  # Dispatcher central
│   │   ├── Mediator.swift         # Actor principal
│   │   ├── MediatorRegistry.swift # Registry interno
│   │   └── MediatorError.swift    # Jerarquía de errores
│   │
│   ├── Queries/                   # Queries implementadas
│   │   ├── GetUserContextQuery.swift
│   │   ├── GetStudentDashboardQuery.swift
│   │   ├── GetAssessmentQuery.swift
│   │   └── ListMaterialsQuery.swift
│   │
│   └── Commands/                  # Commands implementados
│       ├── LoginCommand.swift
│       ├── UploadMaterialCommand.swift
│       └── SubmitAssessmentCommand.swift
│
├── Tests/CQRSTests/
│   ├── CQRSTests.swift            # Tests de protocolos core
│   └── MediatorTests.swift        # Tests del Mediator
│
├── Documentation/
│   ├── ArchitectureGuide.md       # Guía arquitectónica completa
│   ├── Flows.md                   # Diagramas de flujo
│   ├── DecisionLog.md             # Log de decisiones
│   └── Examples.md                # Ejemplos avanzados
│
└── Package.swift
```

## Conceptos Clave

### Query vs Command

| Query | Command |
|-------|---------|
| Solo lectura | Modifica estado |
| Idempotente | Side effects |
| Sin validación | Validación pre-ejecución |
| Retorna datos | Retorna CommandResult |
| Cacheable | Invalida cache |

### Mediator Pattern

El Mediator actúa como dispatcher central:
- Desacopla ViewModels de handlers específicos
- Maneja registro dinámico de handlers
- Proporciona logging estructurado
- Type-safe dispatch con Swift generics

### Actor-Based Concurrency

Todo el sistema usa Swift 6 strict concurrency:
- `Mediator` es un actor para serializar dispatch
- Handlers son actors para aislar estado mutable
- Protocolos requieren `Sendable` para seguridad

## Manejo de Errores

El módulo define una jerarquía clara de errores:

```swift
public enum MediatorError: Error {
    case handlerNotFound(queryOrCommandType: String)
    case registrationError(message: String)
    case validationError(message: String, underlyingError: Error?)
    case executionError(message: String, underlyingError: Error?)
}
```

Uso:

```swift
do {
    let result = try await mediator.send(query)
} catch MediatorError.handlerNotFound(let type) {
    print("No handler registrado para: \(type)")
} catch MediatorError.validationError(let msg, _) {
    print("Validación falló: \(msg)")
} catch {
    print("Error inesperado: \(error)")
}
```

## Testing

El módulo incluye 17 tests unitarios con cobertura del 85%:

```bash
cd TIER-2-Domain/CQRS
swift test
```

Ejemplo de test:

```swift
func testQueryDispatch() async throws {
    let mediator = Mediator(loggingEnabled: false)
    try await mediator.registerQueryHandler(MockQueryHandler())
    
    let result = try await mediator.send(MockQuery(value: 42))
    
    XCTAssertEqual(result, 42)
}
```

## Roadmap

### Sprint 4 (Próximo)
- [ ] EventBus con Domain Events pattern
- [ ] Cache invalidation automática vía eventos
- [ ] Tests de integración E2E
- [ ] Métricas de observabilidad (latencias, cache hit/miss)

### Sprint 5
- [ ] Read Models optimizados para queries
- [ ] Transaction boundaries explícitos
- [ ] Saga pattern para workflows largos

### Sprint 6+
- [ ] Event Sourcing para audit trail
- [ ] CQRS con bases de datos separadas (read/write)
- [ ] Snapshot strategy para queries pesadas

## Documentación Adicional

- [Architecture Guide](Documentation/ArchitectureGuide.md) - Guía arquitectónica detallada
- [Flow Diagrams](Documentation/Flows.md) - Diagramas Mermaid de flujos
- [Decision Log](Documentation/DecisionLog.md) - ADRs y decisiones técnicas
- [Examples](Documentation/Examples.md) - Ejemplos avanzados de uso

## Soporte

Para preguntas o issues, consulta:
- El equipo de arquitectura de EduGo
- La documentación en `Documentation/`
- Los tests en `Tests/CQRSTests/`

## Licencia

Propiedad de EduGo. Uso interno únicamente.
