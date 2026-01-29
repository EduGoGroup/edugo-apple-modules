# EduGo Apple Modules - Swift Package

> **Versión**: 2.0.0  
> **Stack**: iOS 26+ | macOS 26+ | Swift 6.2 | Xcode 26+  
> **Status**: 🚧 En Planificación

---

## 📋 Resumen Ejecutivo

Este proyecto define e implementa un **Swift Package Manager (SPM)** modular con 10 módulos base para las aplicaciones Apple de EduGo. La arquitectura está diseñada para máxima reutilización entre iOS, macOS, watchOS, tvOS y visionOS.



## Fase 0

Nivel del proyecto
Enterprite



### Objetivo Principal

Crear una biblioteca compartida de módulos Swift que:

- ✅ **Elimine duplicación** de código entre apps iOS/macOS
- ✅ **Establezca estándares** de arquitectura y buenas prácticas
- ✅ **Aproveche iOS 26+** para usar APIs nativas sin dependencias externas
- ✅ **Garantice type-safety** con Swift 6.2 strict concurrency
- ✅ **Facilite testing** con módulos independientes y testables

### Arquitectura de 4 Capas

**TIER 0**: EduGoCommon (Base sin dependencias)  
**TIER 1**: EduGoLogger, EduGoModels (Core)  
**TIER 2**: EduGoNetwork, EduGoStorage (Infraestructura)  
**TIER 3**: EduGoAuth, EduGoRoles (Dominio)  
**TIER 4**: EduGoAPI, EduGoAnalytics, EduGoAI (Aplicación)

---

## 🎯 Reglas Clave

### Versiones NO Negociables
- **Swift 6.2**: Strict concurrency, `@MainActor` default, `@concurrent`
- **iOS/macOS 26.0**: Foundation Models, Network.framework con async/await
- **Xcode 26+**: Toolchain completo para Swift 6.2
- **NO hay soporte** para versiones anteriores

### CERO Dependencias Externas
Solo APIs nativas de Apple: Network.framework, os.Logger, Keychain, Codable, Foundation Models.

### Orden Estricto: TIER 0 → 1 → 2 → 3 → 4
Nunca implementar un tier sin tener completo el anterior.

### Alineación Backend
Los roles DEBEN coincidir exactamente: `admin`, `teacher`, `student`, `guardian`.

---

## 🔧 Flujo de Desarrollo

**Estructura de commits**: `[TIER-X] Módulo: Descripción`

**Definición de Done**: Código + tests (80%+) + docs + SwiftLint + build exitoso en 5 plataformas

**Branching**: `main` (release) → `develop` (integración) → `feature/tierX-modulo` (desarrollo)

**Code Review**: Verificar tier dependencies, APIs iOS 26+, Sendable, @MainActor/@concurrent, tests, DocC comments

---

## 🏗️ Estándares de Desarrollo Swift

### 1. Arquitectura Limpia (Clean Architecture)

**Estructura por módulo**:

```
ModuleName/
├── Public/           # APIs públicas
│   ├── Models/       # DTOs y domain models
│   ├── Managers/     # Facades públicas
│   └── Protocols/    # Interfaces públicas
├── Internal/         # Implementación interna
│   ├── Services/     # Servicios concretos
│   ├── Repositories/ # Acceso a datos
│   ├── Mappers/      # Transformación de datos
│   └── Extensions/   # Extensiones privadas
└── Tests/            # Tests unitarios e integración
```

**Principios**:
- Separación clara entre interfaces (protocols) e implementación
- Las clases public solo exponen lo necesario
- Inversión de dependencias: dependencias inyectadas, no creadas
- Sin referencias circulares entre módulos

### 2. Test-First con Stubs

**Workflow obligatorio**:

```swift
// PASO 1: Definir protocol (interfaz)
protocol UserRepositoryProtocol {
    func fetchUser(id: UUID) async throws -> User
}

// PASO 2: Crear stub para testing
class UserRepositoryStub: UserRepositoryProtocol {
    var mockUser: User?
    var mockError: Error?
    
    func fetchUser(id: UUID) async throws -> User {
        if let error = mockError { throw error }
        return mockUser ?? User.stub()
    }
}

// PASO 3: Escribir tests con stubs
class AuthManagerTests: XCTestCase {
    var sut: AuthManager!
    var repositoryStub: UserRepositoryStub!
    
    override func setUp() {
        repositoryStub = UserRepositoryStub()
        sut = AuthManager(repository: repositoryStub)
    }
    
    func testLoginSucceeds() async throws {
        repositoryStub.mockUser = User.stub()
        let result = try await sut.login(email: "test@test.com", password: "pass")
        XCTAssertNotNil(result.token)
    }
}

// PASO 4: Implementar repositorio real
class UserRepository: UserRepositoryProtocol {
    // Implementación con Network.framework
}
```

**Modelos stub para testing**:

```swift
// En cada módulo
extension User {
    static func stub(
        id: UUID = UUID(),
        name: String = "Test User"
    ) -> User {
        User(id: id, name: name, email: "test@test.com")
    }
}

extension AuthTokens {
    static func stub() -> AuthTokens {
        AuthTokens(accessToken: "mock_token", refreshToken: "mock_refresh")
    }
}
```

### 3. Swift 6.2 Concurrency Standards

**Reglas obligatorias**:

```swift
// ✅ SIEMPRE usar @MainActor para código UI
@MainActor
class ViewController: UIViewController {
    func updateUI() { }
}

// ✅ Operaciones de red: @concurrent (explícitamente en background)
@concurrent
func fetchDataInBackground() async -> Data {
    // Red, I/O, heavy computations
}

// ✅ Sendable: todos los tipos compartidos entre hilos
public struct User: Codable, Sendable {
    let id: UUID
    let name: String
}

// ✅ Evitar nonisolated(unsafe) a menos que sea absolutamente necesario
actor DataStore {
    private var cache: [String: Data] = [:]
    
    func get(_ key: String) -> Data? {
        cache[key]
    }
}

// ❌ NUNCA usar DispatchQueue.main ni .global()
// ❌ NUNCA usar completion handlers
// ❌ NUNCA compartir estado mutable sin sincronización
```

### 4. Protocols Primero

**Patrón obligatorio**: Protocol-Oriented Design

```swift
// 1. Definir protocol primero (contrato)
public protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod
    ) async throws -> T
}

// 2. Implementar para testing (stub)
class NetworkClientStub: NetworkClientProtocol {
    var mockResponse: Any?
    func request<T>(_ endpoint: String, method: HTTPMethod) async throws -> T {
        mockResponse as? T ?? T()  // Requiere default init en tests
    }
}

// 3. Implementar real
actor NetworkClient: NetworkClientProtocol {
    // Network.framework implementation
}

// 4. Inyectar en dependencias
class AuthManager {
    let networkClient: NetworkClientProtocol  // Protocol, no implementación
    
    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }
}
```

### 5. Manejo de Errores Estandarizado

```swift
// Siempre usar ErrorCode + AppError
public enum ErrorCode: Int, Sendable {
    case networkTimeout = 1002
    case authTokenExpired = 2001
    case storageWriteFailed = 4002
}

public struct AppError: Error, Sendable {
    let code: ErrorCode
    let message: String
    let underlyingError: String?
}

// En funciones
func login(email: String, password: String) async throws -> AuthTokens {
    do {
        let tokens = try await httpClient.post("/login", body: credentials)
        return tokens
    } catch let error as AppError {
        throw error  // Re-throw conocido
    } catch {
        throw AppError(
            code: .networkTimeout,
            message: "Failed to login",
            underlyingError: error
        )
    }
}
```

### 6. Documentación con DocC

**Obligatorio para APIs públicas**:

```swift
/// Obtiene un usuario por su ID.
///
/// Esta función realiza una llamada a la API para obtener
/// los detalles del usuario.
///
/// - Parameter id: El identificador único del usuario
/// - Returns: El usuario solicitado
/// - Throws: `AppError` con código `.networkTimeout` si la red falla
/// - Important: Requiere token de autenticación válido
///
/// ```swift
/// let user = try await apiClient.getUser(id: userId)
/// print(user.name)
/// ```
public func getUser(id: UUID) async throws -> User {
    // Implementation
}
```

### 7. Naming Conventions

```swift
// ✅ Clases/Structs: PascalCase
class AuthManager { }
struct User { }

// ✅ Funciones/variables: camelCase
func fetchUserData() { }
var isAuthenticated: Bool

// ✅ Constantes: camelCase (NO UPPER_CASE excepto enums)
let defaultTimeout: Duration = .seconds(30)

// ✅ Protocols: terminan en -Protocol o -ing
protocol AuthenticableProtocol { }
protocol Sendable { }

// ✅ Funciones async sin sufijo "Async"
func fetchUser() async -> User  // ✅ Bien
func fetchUserAsync() -> User  // ❌ Redundante

// ✅ Booleans: predicados is/has/should
var isLoading: Bool
var hasError: Bool
var shouldRetry: Bool
```

### 8. Tests Mínimos por Módulo

```
TIER 0 (EduGoCommon)          → 100% cobertura
TIER 1 (Logger, Models)        → 80% cobertura
TIER 2 (Network, Storage)      → 85% cobertura (incluyendo integration)
TIER 3 (Auth, Roles)           → 85% cobertura (incluyendo integration)
TIER 4 (API, Analytics, AI)    → 80% cobertura
```

**Estructura de test file**:

```swift
import XCTest
@testable import EduGoAuth

final class AuthManagerTests: XCTestCase {
    var sut: AuthManager!  // System Under Test
    var repositoryStub: UserRepositoryStub!
    
    override func setUp() async throws {
        try await super.setUp()
        repositoryStub = UserRepositoryStub()
        sut = AuthManager(repository: repositoryStub)
    }
    
    override func tearDown() async throws {
        sut = nil
        repositoryStub = nil
        try await super.tearDown()
    }
    
    // Arrange-Act-Assert (AAA pattern)
    func testLoginWithValidCredentials() async throws {
        // Arrange
        let validEmail = "user@test.com"
        repositoryStub.mockUser = User.stub(email: validEmail)
        
        // Act
        let tokens = try await sut.login(email: validEmail, password: "password")
        
        // Assert
        XCTAssertNotNil(tokens.accessToken)
    }
    
    func testLoginWithInvalidEmailThrowsError() async throws {
        // Arrange
        repositoryStub.mockError = AppError(
            code: .authInvalidCredentials,
            message: "Invalid email"
        )
        
        // Act & Assert
        await XCTAssertThrowsError {
            try await sut.login(email: "invalid", password: "pass")
        }
    }
}
```

### 9. Build Performance

```swift
// ✅ Minimizar imports
import EduGoCommon  // Solo lo necesario

// ❌ Evitar imports circulares
// En EduGoAuth no importar EduGoAPI
// En EduGoAPI puedes importar EduGoAuth

// ✅ Usar type aliases para APIs complejas
typealias APIResponse = (success: Bool, data: Data)

// ✅ Lazy computed properties para valores costosos
lazy var sortedUsers: [User] = {
    return users.sorted { $0.name < $1.name }
}()
```

### 10. Uso de Actor vs Class

```swift
// ✅ Use Actor para state compartido multi-thread
actor AuthManager {
    private var tokens: AuthTokens?
    
    func setTokens(_ tokens: AuthTokens) {
        self.tokens = tokens  // Automáticamente sincronizado
    }
}

// ✅ Use Class con @MainActor para UI
@MainActor
class ViewController: UIViewController {
    func updateUI() { }  // Garantizado en main thread
}

// ✅ Use Struct para tipos inmutables
public struct User: Sendable {
    let id: UUID
    let name: String
    // Inmutable, thread-safe automáticamente
}

// ❌ NO use unsafeSendable sin justificación documentada
```

---

## 📚 Documentación Completa

Para detalles de implementación, consultar:

- **[01-SWIFT-SETUP-PLAN.md](01-SWIFT-SETUP-PLAN.md)**: Plan técnico completo
  - Stack definitivo y APIs nativas
  - Código de los 10 módulos
  - CI/CD y dependencias

---

## ⚙️ Consideraciones LLM - Configuración Manual en Xcode

> **CRÍTICO**: Este proyecto será ejecutado por LLMs vía CLI. Algunas tareas requieren configuración manual en Xcode GUI que NO es accesible por línea de comandos.

### Requisito para Sprints y Tareas

**En TODOS los sprints/historias/tareas**, especificar:

1. **¿Requiere configuración manual en Xcode?** SÍ / NO

2. **Si es SÍ**, como PRIMERA actividad (antes de código) debe crearse:
   - Documento: `CONFIGURACION_XCODE_[MODULO].md`
   - Con pasos DETALLADOS y VERIFICABLES:
     - Qué targets crear/modificar
     - Qué frameworks añadir
     - Qué build settings configurar
     - Qué schemes crear
     - Screenshots si es necesario
     - Paso de verificación (cómo confirmar que está correcto)

### Ejemplos de Configuración Manual Requerida

```
❌ NO accesible vía CLI → Requiere documento Xcode:
  • Añadir frameworks (Network.framework, Security.framework)
  • Configurar code signing
  • Configurar build phases (run scripts)
  • Crear schemes de test para múltiples plataformas
  • Configurar target dependencies
  • Configurar platform-specific build settings

✅ Accesible vía CLI → Sin documento Xcode:
  • Crear archivos Swift
  • Modificar Package.swift
  • Escribir tests
  • Ejecutar tests
  • Crear commits/PRs
```

### Estructura de Documentación Xcode

Ejemplo formato:

```markdown
# CONFIGURACION_XCODE_EduGoNetwork.md

## Paso 1: Crear Target Principal
1. En Xcode, New → Target → Swift Package
2. Name: `EduGoNetwork`
3. Verificar: Build settings → Product Name = EduGoNetwork

## Paso 2: Añadir Framework Network
1. Target → Build Phases → Link Binary With Libraries
2. Click + → Network.framework
3. Verificar: grep -r "import Network" Sources/

## Paso 3: Configurar Build Settings
1. Target → Build Settings
2. Search: "Swift Compiler"
3. Set: Language Mode → C99 Strict
4. Verificar: xcodebuild -showBuildSettings | grep Language

## Verificación Final
Ejecutar en CLI:
\`\`\`bash
xcodebuild build -scheme EduGoNetwork -destination 'platform=iOS Simulator,name=iPhone 15'
\`\`\`
```

### Flujo: Análisis → Sprint → Historia → Tarea

Este documento debe consultarse en CADA desglose:

**Análisis General**: Identificar módulos que requieren configuración Xcode  
**Sprint**: Especificar "Tareas Xcode" como bloqueadores  
**Historia de Usuario**: Detallar si requiere setup previo  
**Tarea**: Incluir link a documento `CONFIGURACION_XCODE_[X].md` en descripción  

---

```

---

## 🎯 Estado Actual del Proyecto

| TIER | Módulo | Status | Cobertura | Docs |
|------|--------|--------|-----------|------|
| 0 | EduGoCommon | 🔴 Pendiente | - | - |
| 1 | EduGoLogger | 🔴 Pendiente | - | - |
| 1 | EduGoModels | 🔴 Pendiente | - | - |
| 2 | EduGoNetwork | 🔴 Pendiente | - | - |
| 2 | EduGoStorage | 🔴 Pendiente | - | - |
| 3 | EduGoRoles | 🔴 Pendiente | - | - |
| 3 | EduGoAuth | 🔴 Pendiente | - | - |
| 4 | EduGoAPI | 🔴 Pendiente | - | - |
| 4 | EduGoAnalytics | 🔴 Pendiente | - | - |
| 4 | EduGoAI | 🔴 Pendiente | - | - |

**Leyenda**: 🔴 Pendiente | 🟡 En Progreso | 🟢 Completo

---

## 📞 Contacto y Soporte

- **Team**: EduGo Mobile Team
- **Repo**: https://github.com/edugo/EduGoAppleModules
- **Issues**: https://github.com/edugo/EduGoAppleModules/issues
- **Slack**: #mobile-swift-modules

---

**Última actualización**: Enero 2026  
**Versión del README**: 1.0.0
