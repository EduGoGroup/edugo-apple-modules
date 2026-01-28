# Guía de Concurrencia - EduGo Apple Modules

Esta guía documenta los patrones de concurrencia utilizados en el proyecto y las mejores prácticas para mantener **Sendable compliance** con Swift 6 strict concurrency.

## Visión General

El proyecto está diseñado para cumplir con Swift 6 strict concurrency. Todas las entidades de dominio son `Sendable` y los servicios con estado utilizan `actor` para garantizar thread-safety.

### Estado del Proyecto

| Métrica | Valor |
|---------|-------|
| Total de entidades analizadas | 54 |
| Entidades Sendable | 54 (100%) |
| Actors | 10 |
| Structs inmutables | 20+ |
| Protocolos con Sendable | 8+ |

---

## Principios Fundamentales

### 1. Entidades de Dominio Inmutables

Todas las structs de dominio usan propiedades `let` exclusivamente:

```swift
public struct User: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let email: String
    public let name: String
    // ✅ Solo propiedades inmutables
}
```

### 2. Servicios como Actors

Los servicios que mantienen estado mutable usan `actor`:

```swift
public actor NetworkClient: Sendable {
    private let session: URLSession
    
    public func fetch(_ url: URL) async throws -> Data {
        // Actor isolation garantiza thread-safety
    }
}
```

### 3. Protocolos con Sendable

Los protocolos que cruzan boundaries de concurrencia requieren `: Sendable`:

```swift
public protocol UserContextProtocol: Sendable {
    var currentUserId: UUID? { get async }
    func hasPermission(_ permission: String) async -> Bool
}
```

### 4. Errores Sendable

Los errores solo usan tipos Sendable en sus associated values:

```swift
public enum RepositoryError: Error, Sendable {
    case fetchFailed(reason: String)           // ✅ String es Sendable
    case connectionError(reason: String)       // ✅ No usar Error directamente
    case serializationError(type: String)      // ✅ String es Sendable
}
```

---

## Patrones Aprobados

### Entidades de Dominio

```swift
/// Entidad de dominio inmutable y Sendable
public struct Document: Sendable, Equatable, Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let type: DocumentType
    public let state: DocumentState
    public let metadata: DocumentMetadata
    public let assignedRoleIds: Set<UUID>
    
    // ✅ Todas las propiedades son let
    // ✅ Todos los tipos son Sendable (UUID, String, Set, enums)
}
```

### Servicios con Estado (Actors)

```swift
/// Actor que mantiene estado de forma thread-safe
public actor AuthManager: UserContextProtocol {
    private var currentUser: User?
    private var accessToken: String?
    
    public var currentUserId: UUID? {
        currentUser?.id
    }
    
    public func login(email: String, password: String) async throws -> User {
        // La mutación de currentUser es segura dentro del actor
        let user = try await authenticate(email: email, password: password)
        self.currentUser = user
        return user
    }
}
```

### Enums con Sendable

```swift
/// Enum automáticamente Sendable (todos los cases usan tipos Sendable)
public enum LogLevel: Int, Sendable, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
}
```

### Builder Pattern Inmutable

```swift
/// Builder Sendable usando patrón inmutable
public struct LoggerBuilder: Sendable {
    private let globalLevel: LogLevel
    private let environment: Environment
    
    public init() {
        self.globalLevel = .info
        self.environment = .development
    }
    
    private init(globalLevel: LogLevel, environment: Environment) {
        self.globalLevel = globalLevel
        self.environment = environment
    }
    
    /// Cada método retorna una NUEVA instancia
    public func globalLevel(_ level: LogLevel) -> LoggerBuilder {
        LoggerBuilder(globalLevel: level, environment: self.environment)
    }
    
    public func environment(_ env: Environment) -> LoggerBuilder {
        LoggerBuilder(globalLevel: self.globalLevel, environment: env)
    }
    
    public func build() -> Logger {
        Logger(level: globalLevel, environment: environment)
    }
}
```

### Protocolos de Repositorio

```swift
/// Protocolo Sendable para repositorios
public protocol UserRepositoryProtocol: Sendable {
    func findById(_ id: UUID) async throws -> User?
    func save(_ user: User) async throws -> User
    func delete(_ id: UUID) async throws
}
```

---

## Anti-patrones a Evitar

### ❌ NO usar @unchecked Sendable con estado mutable

```swift
// ❌ INCORRECTO - Data race potencial
class Builder: @unchecked Sendable {
    var value: Int = 0  // Estado mutable en clase "Sendable"
    
    func setValue(_ v: Int) -> Builder {
        self.value = v  // Mutación no segura
        return self
    }
}

// ✅ CORRECTO - Struct inmutable
struct Builder: Sendable {
    let value: Int
    
    func setValue(_ v: Int) -> Builder {
        Builder(value: v)  // Nueva instancia
    }
}
```

### ❌ NO usar Error como associated value

```swift
// ❌ INCORRECTO - Error no es Sendable
enum MyError: Error, Sendable {
    case failure(error: Error)  // ⚠️ Viola Sendable
}

// ✅ CORRECTO - Usar String
enum MyError: Error, Sendable {
    case failure(reason: String)  // ✅ String es Sendable
}

// Uso al capturar errores:
do {
    try await someOperation()
} catch {
    throw MyError.failure(reason: error.localizedDescription)
}
```

### ❌ NO compartir referencias mutables entre threads

```swift
// ❌ INCORRECTO - Estado compartido mutable
class SharedState {
    var counter = 0
    
    func increment() {
        counter += 1  // Data race si se llama desde múltiples threads
    }
}

// ✅ CORRECTO - Usar actor
actor SharedState {
    var counter = 0
    
    func increment() {
        counter += 1  // Seguro - actor isolation
    }
}
```

### ❌ NO usar closures no-Sendable en contextos async

```swift
// ❌ INCORRECTO
func process(completion: @escaping () -> Void) async {
    // completion no es Sendable, puede capturar estado mutable
}

// ✅ CORRECTO
func process(completion: @escaping @Sendable () -> Void) async {
    // @Sendable garantiza que el closure es thread-safe
}
```

---

## Inventario de Entidades Sendable

### TIER-0: Foundation (EduGoCommon)

| Entidad | Tipo | Sendable | Notas |
|---------|------|----------|-------|
| `Entity` | protocol | ✅ | Requiere Sendable en conformidades |
| `DomainError` | enum | ✅ | Associated values son String |
| `RepositoryError` | enum | ✅ | connectionError usa String (no Error) |
| `UseCaseError` | enum | ✅ | Wrappea otros errores Sendable |
| `UserContextProtocol` | protocol | ✅ | Métodos async-only |

### TIER-1: Core (Logger, Models)

| Entidad | Tipo | Sendable | Notas |
|---------|------|----------|-------|
| `Logger` | actor | ✅ | Singleton thread-safe |
| `LoggerProtocol` | protocol | ✅ | Métodos async |
| `LogLevel` | enum | ✅ | Valores Int |
| `LogConfiguration` | struct | ✅ | Propiedades inmutables |
| `LoggerBuilder` | struct | ✅ | Builder inmutable |
| `User` | struct | ✅ | Entidad de dominio |
| `Document` | struct | ✅ | Entidad de dominio |
| `Role` | struct | ✅ | Entidad de dominio |
| `Permission` | struct | ✅ | Entidad de dominio |
| `UserRepositoryProtocol` | protocol | ✅ | Métodos async |

### TIER-2: Infrastructure (Network, Storage)

| Entidad | Tipo | Sendable | Notas |
|---------|------|----------|-------|
| `NetworkClient` | actor | ✅ | URLSession es Sendable |
| `StorageManager` | actor | ✅ | UserDefaults es Sendable |
| `HTTPMethod` | enum | ✅ | Enum String |

### TIER-3: Domain (Auth, Roles)

| Entidad | Tipo | Sendable | Notas |
|---------|------|----------|-------|
| `AuthManager` | actor | ✅ | Implementa UserContextProtocol |
| `RoleManager` | actor | ✅ | Gestión de permisos |
| `SystemRole` | enum | ✅ | Enum String |
| `Permission` (OptionSet) | struct | ✅ | OptionSet con UInt64 |

### TIER-4: Features (API, Analytics, AI)

| Entidad | Tipo | Sendable | Notas |
|---------|------|----------|-------|
| `APIClient` | actor | ✅ | Usa NetworkClient |
| `AnalyticsManager` | actor | ✅ | Mantiene eventos |
| `AnalyticsEvent` | struct | ✅ | String + Date |
| `AIService` | actor | ✅ | Métodos async |
| `AIPrompt` | struct | ✅ | Solo Strings |
| `AIResponse` | struct | ✅ | Solo Strings |

---

## Verificación

### Script de Verificación

El proyecto incluye un script para verificar Sendable compliance:

```bash
# Verificar todo el proyecto
./scripts/verify-sendable.sh

# Verificar solo un tier específico
./scripts/verify-sendable.sh TIER-0-Foundation/EduGoCommon
./scripts/verify-sendable.sh TIER-1-Core/Logger
```

### Compilación con Strict Concurrency (Manual)

```bash
# Desde la raíz del proyecto
swift build -Xswiftc -strict-concurrency=complete
```

### Verificación por Módulo

```bash
# Verificar un módulo específico
cd TIER-0-Foundation/EduGoCommon
swift build -Xswiftc -strict-concurrency=complete

cd TIER-1-Core/Logger
swift build -Xswiftc -strict-concurrency=complete
```

### CI/CD

El proyecto tiene un workflow de GitHub Actions (`.github/workflows/ci.yml`) que:
1. Compila el proyecto
2. Ejecuta todos los tests
3. Verifica strict concurrency compliance
4. Verifica cada tier individualmente

La verificación de strict concurrency se ejecuta automáticamente en cada PR a `main`.

---

## Migración a Swift 6

### Checklist de Migración

- [x] Todas las entidades de dominio son structs inmutables con `Sendable`
- [x] Todos los servicios con estado son `actor`
- [x] Todos los errores usan tipos Sendable en associated values
- [x] Todos los protocolos que cruzan boundaries tienen `: Sendable`
- [x] No hay uso de `@unchecked Sendable` con estado mutable
- [x] Todos los closures en contextos async son `@Sendable`
- [x] LoggerBuilder refactorizado a struct inmutable
- [x] RepositoryError.connectionError usa String en lugar de Error

### Pasos Futuros

1. Habilitar `-strict-concurrency=complete` en Package.swift para desarrollo
2. Agregar verificación de strict concurrency al pipeline de CI
3. Documentar cualquier nuevo tipo agregado

---

## Referencias

- [Swift Concurrency Manifesto](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)
- [Sendable and @Sendable](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/#Sendable-Types)
- [SE-0302: Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)
- [WWDC 2021: Swift Concurrency](https://developer.apple.com/videos/play/wwdc2021/10134/)

---

**Última actualización**: 2026-01-28  
**Versión**: 1.0
