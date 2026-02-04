# EduGo Apple Modules

**Workspace multi-módulo SPM para plataformas Apple (iOS, macOS, watchOS, tvOS)**

![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)
![iOS 26+](https://img.shields.io/badge/iOS-26%2B-blue.svg)
![Strict Concurrency](https://img.shields.io/badge/Concurrency-Strict-green.svg)
![Test Coverage](https://img.shields.io/badge/Coverage-80%25%2B-success.svg)

---

## 📋 Descripción

Sistema modular de componentes iOS implementado con **arquitectura de 4 tiers** (TIER-0 a TIER-3), diseñado para:

- **Separación de responsabilidades** por capas
- **Reutilización** de componentes entre features
- **Testing exhaustivo** con inversión de dependencias
- **Concurrencia segura** con Swift 6.2 strict concurrency
- **Cero dependencias externas** (solo frameworks del sistema)

### Tecnologías

| Categoría | Stack |
|-----------|-------|
| **Lenguaje** | Swift 6.2 |
| **Plataforma** | iOS 26+, macOS 15+, watchOS 11+, tvOS 18+ |
| **Arquitectura** | Clean Architecture + Protocol-Oriented Programming |
| **Concurrencia** | Strict concurrency (`actor`, `@MainActor`, `Sendable`) |
| **Testing** | XCTest + Protocol Mocks + Test-First |
| **Documentación** | DocC (comentarios obligatorios en APIs públicas) |
| **Networking** | `Network.framework` + `URLSession` |
| **Persistencia** | `Keychain` + `UserDefaults` + `FileManager` |
| **Logging** | `os.Logger` |

---

## 🏗️ Arquitectura de 4 Tiers

```
┌──────────────────────────────────────────────────────────┐
│ TIER-3: Feature Modules (UI + Lógica de negocio)        │
│  AuthFeature, DashboardFeature, CourseListFeature       │
│  ↓ Depende de: TIER-2, TIER-1, TIER-0                   │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ TIER-2: Domain Services (Orquestación + casos de uso)   │
│  AuthService, CourseService, UserProfileService         │
│  ↓ Depende de: TIER-1, TIER-0                           │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ TIER-1: Data Layer (Repositorios + clientes)            │
│  NetworkClient, KeychainManager, UserRepository         │
│  ↓ Depende de: TIER-0                                   │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ TIER-0: Foundation (Modelos + Utilidades)               │
│  Models, Extensions, ErrorTypes, Protocols              │
│  ↓ Sin dependencias internas                            │
└──────────────────────────────────────────────────────────┘
```

**Diagrama detallado**: Ver [docs/tier-architecture-diagram.md](docs/tier-architecture-diagram.md)
**Decisiones de diseño**: Ver [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 📦 Estructura del Proyecto

```
EduUI/Modules/Apple/
├── Package.swift                    # Workspace SPM (define todos los módulos)
│
├── Sources/
│   ├── TIER-0/
│   │   ├── EduFoundation/           # Modelos base, extensiones, protocolos
│   │   │   ├── Public/
│   │   │   │   ├── Models/          # User, AuthToken, Course (Sendable)
│   │   │   │   ├── Protocols/       # Repository interfaces
│   │   │   │   └── Extensions/      # String+Validation, Date+Format
│   │   │   └── Internal/
│   │   │       └── Utilities/       # Helpers privados
│   │   │
│   ├── TIER-1/
│   │   ├── EduNetworking/           # NetworkClient, HTTP calls
│   │   ├── EduPersistence/          # KeychainManager, UserDefaults wrapper
│   │   └── EduRepositories/         # UserRepository, CourseRepository
│   │
│   ├── TIER-2/
│   │   ├── EduAuthService/          # AuthService (login, logout, refresh)
│   │   └── EduCourseService/        # CourseService (listado, búsqueda)
│   │
│   └── TIER-3/
│       ├── EduAuthFeature/          # LoginView, LoginViewModel
│       └── EduDashboardFeature/     # DashboardView, DashboardViewModel
│
├── Tests/
│   ├── TIER-0/
│   │   └── EduFoundationTests/
│   ├── TIER-1/
│   │   ├── EduNetworkingTests/
│   │   ├── EduPersistenceTests/
│   │   └── EduRepositoriesTests/
│   ├── TIER-2/
│   │   ├── EduAuthServiceTests/
│   │   └── EduCourseServiceTests/
│   └── TIER-3/
│       ├── EduAuthFeatureTests/
│       └── EduDashboardFeatureTests/
│
├── docs/
│   ├── tier-architecture-diagram.md
│   └── ...
│
├── README.md                        # Este archivo
├── ARCHITECTURE.md                  # Decisiones de diseño
└── DEVELOPMENT_GUIDE.md             # Guía práctica de desarrollo
```

---

## 🚀 Quick Start

### Requisitos

- **Xcode 16.0+** (Swift 6.2 incluido)
- **macOS 15.0+**
- **Git**

### Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/edugo/eduui-modules-apple.git
cd eduui-modules-apple

# 2. Abrir workspace en Xcode
open EduGoAppleModules.xcworkspace

# 3. Resolver dependencias (automático en Xcode)
# Product → Build (⌘B)

# 4. Ejecutar tests
# Product → Test (⌘U)
```

### Ejecutar Demo App

```bash
# Si existe una app de ejemplo en el workspace
open DemoApp/DemoApp.xcodeproj
# Product → Run (⌘R)
```

---

## 🔧 Navegación en Xcode 26

### Abrir el Workspace

```bash
open EduGoAppleModules.xcworkspace
```

### Estructura del Workspace

El workspace organiza **21 módulos SPM** en **7 grupos funcionales**:

| Grupo | Módulos | Descripción |
|-------|---------|-------------|
| **TIER-0-Foundation** | 1 módulo | EduGoCommon - Base común del sistema |
| **TIER-1-Core** | 3 módulos | Logger, Models, Utilities |
| **TIER-2-Infrastructure** | 3 módulos | Network, Storage, LocalPersistence |
| **TIER-2-Domain** | 3 módulos | CQRS, StateManagement, UseCases |
| **TIER-3-Domain** | 2 módulos | Auth, Roles |
| **TIER-3-Presentation** | 5 módulos | Accessibility, Binding, Navigation, Theme, UI |
| **TIER-3-ViewModels** | 1 módulo | ViewModels |
| **TIER-4-Features** | 3 módulos | AI, Analytics, API |

**Total:** 21 módulos con cobertura 100% en el workspace

### Compilar Módulos Individuales

Cada módulo tiene su propio scheme compartido para compilación independiente:

1. **Product → Scheme** → Seleccionar módulo (ej. `Logger`, `Network`, `UI`)
2. **Product → Build** (⌘B)

**Tip:** Los schemes compartidos permiten compilar y testear módulos de forma aislada sin compilar todo el workspace.

### Ejecutar Tests por TIER

Utiliza test plans organizados por TIER para ejecutar tests de forma focalizada:

| Test Plan | Módulos Incluidos | Uso Recomendado |
|-----------|-------------------|-----------------|
| `TIER-0-Foundation.xctestplan` | EduGoCommon | Tests de modelos base |
| `TIER-1-Core-Infrastructure.xctestplan` | Logger, Models, Utilities, Network, Storage, LocalPersistence | Tests de data layer |
| `TIER-2-Domain.xctestplan` | CQRS, StateManagement, UseCases | Tests de lógica de negocio |
| `TIER-3-Presentation.xctestplan` | Auth, Roles, Accessibility, Binding, Navigation, Theme, UI, ViewModels | Tests de presentación |
| `TIER-4-Features.xctestplan` | AI, Analytics, API | Tests de features |

**Ejecutar test plan:**
1. **Product → Test Plan** → Seleccionar plan (ej. `TIER-1-Core-Infrastructure`)
2. **Product → Test** (⌘U)

### Navegación Rápida - Atajos de Teclado

| Atajo | Función | Descripción |
|-------|---------|-------------|
| **⌘⇧O** | Open Quickly | Buscar archivos, símbolos, clases en todo el workspace |
| **⌃6** | Document Items | Ver símbolos del archivo actual |
| **⌘⌃J** | Jump to Definition | Saltar a definición (funciona entre módulos SPM) |
| **⌘⌃↑/↓** | Jump to Counterpart | Alternar entre header/implementation (archivos relacionados) |
| **⌘⇧J** | Reveal in Navigator | Mostrar archivo actual en navegador de proyectos |
| **⌘1** | Project Navigator | Mostrar navegador de archivos |
| **⌘⌃⇧F** | Find Navigator | Buscar en todo el workspace |

### Optimizaciones de Xcode 26

El workspace está configurado para aprovechar las nuevas capacidades de Xcode 26:

- **✅ Compilation Caching** - Habilitado para builds incrementales más rápidos
- **✅ Swift Explicit Modules** - Mejora tiempo de compilación con módulos explícitos
- **✅ Previews Enabled** - SwiftUI previews habilitados para desarrollo rápido
- **✅ Latest Build System** - Usando el sistema de build más reciente de Apple

**Verificar configuración:**
- Workspace Settings → Build System: "Latest"
- Workspace Settings → Enable Compilation Caching: ✓

### Generar Schemes Compartidos

Si necesitas regenerar schemes compartidos para módulos:

```bash
# Ejecutar script de generación
./Scripts/generate-schemes.sh

# Luego en Xcode:
# Product → Scheme → Manage Schemes
# Marcar checkbox "Shared" para cada scheme
```

### Troubleshooting

**Problema:** No veo todos los módulos en el Project Navigator
- **Solución:** File → Workspace Settings → Derived Data → Delete... → Reabrir workspace

**Problema:** Jump to Definition (⌘⌃J) no funciona entre módulos
- **Solución:** Product → Clean Build Folder (⌘⇧K) → Product → Build (⌘B)

**Problema:** Tests no aparecen en el Test Navigator
- **Solución:** Seleccionar test plan apropiado → Product → Test (⌘U)

**Problema:** Compilación lenta
- **Solución:** Verificar que Compilation Caching esté habilitado en Workspace Settings

### Documentación Adicional

Ver [XCODE_NAVIGATION_GUIDE.md](XCODE_NAVIGATION_GUIDE.md) para guía detallada de navegación y mejores prácticas en Xcode 26.

---

## 🧪 Testing

### Cobertura Mínima: 80%

```bash
# Ejecutar todos los tests
xcodebuild test -scheme EduGoModules-Package

# Ver reporte de cobertura
open DerivedData/.../Logs/Test/*.xcresult
```

### Estrategia de Testing

| Tier | Estrategia | Herramientas |
|------|-----------|--------------|
| **TIER-0** | Unit tests de modelos y extensiones | `XCTest` |
| **TIER-1** | Protocol mocks para NetworkClient/Keychain | `XCTest` + Stubs |
| **TIER-2** | Inject repository mocks, verificar lógica de negocio | `XCTest` + Stubs |
| **TIER-3** | ViewModels con service mocks, verificar estados UI | `XCTest` + Stubs |

**Ejemplo de test con mock**:

```swift
// Tests/TIER-2/EduAuthServiceTests/AuthServiceTests.swift
final class AuthServiceTests: XCTestCase {
    func testLoginSuccess() async throws {
        let mockRepo = MockUserRepository()
        mockRepo.loginResult = .success(User(id: UUID(), name: "Test"))

        let service = DefaultAuthService(userRepository: mockRepo)
        let user = try await service.login(email: "test@edu.go", password: "pass")

        XCTAssertEqual(user.name, "Test")
        XCTAssertEqual(mockRepo.loginCallCount, 1)
    }
}
```

---

## 📖 Documentación

| Documento | Propósito |
|-----------|-----------|
| [README.md](README.md) | Este archivo (overview del proyecto) |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Decisiones de diseño, justificación de 4 tiers, trade-offs |
| [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md) | Cómo agregar módulo, modificar dependencias, convenciones |
| [docs/tier-architecture-diagram.md](docs/tier-architecture-diagram.md) | Diagrama ASCII/Mermaid de tiers + reglas de dependencias |
| [docs/architecture/error-handling-guide.md](docs/architecture/error-handling-guide.md) | Guía completa de manejo de errores tipados por capa |
| [docs/CONCURRENCY.md](docs/CONCURRENCY.md) | Guía de Thread-Safety y Sendable compliance |

---

## 🛠️ Convenciones de Desarrollo

### Branching

| Tipo de cambio | Branch pattern | Ejemplo |
|----------------|----------------|---------|
| Nueva feature | `feature/tierX-modulo` | `feature/tier3-profile-feature` |
| Bugfix | `fix/tierX-modulo` | `fix/tier1-networking-timeout` |
| Refactor | `refactor/tierX-modulo` | `refactor/tier0-models-sendable` |
| Docs | `docs/tema` | `docs/tier-architecture-update` |

### Commits

**Formato**: `[TIER-X] Modulo: Description`

**Ejemplos**:
```bash
git commit -m "[TIER-0] EduFoundation: Add User model with Sendable conformance"
git commit -m "[TIER-2] AuthService: Implement refresh token logic"
git commit -m "[TIER-3] DashboardFeature: Fix loading state handling"
git commit -m "[TIER-1] Networking: Add retry mechanism for 5xx errors"
```

### Código

- **Naming**: `PascalCase` para tipos, `camelCase` para funciones/variables
- **Access Control**: Explícito en APIs públicas (`public`, `internal`, `private`)
- **Concurrency**: `actor` para estado compartido, `@MainActor` para ViewModels
- **DocC**: Obligatorio en APIs públicas (`///` con parámetros, returns, throws)
- **SwiftLint**: Habilitar `force_try`, `force_unwrapping`, `implicitly_unwrapped_optional`

**Ejemplo de código conforme**:

```swift
/// Servicio de autenticación que gestiona login, logout y refresh de tokens.
///
/// Este servicio coordina operaciones de autenticación utilizando un repositorio
/// de usuarios y un gestor de Keychain para almacenar tokens de forma segura.
@MainActor
public final class DefaultAuthService: AuthService {
    private let userRepository: UserRepository
    private let keychainManager: KeychainManager

    @Published private(set) public var currentUser: User?

    /// Inicializa el servicio de autenticación.
    ///
    /// - Parameters:
    ///   - userRepository: Repositorio para operaciones de usuario
    ///   - keychainManager: Gestor de Keychain para almacenar tokens
    public init(
        userRepository: UserRepository,
        keychainManager: KeychainManager
    ) {
        self.userRepository = userRepository
        self.keychainManager = keychainManager
    }

    /// Autentica un usuario con email y contraseña.
    ///
    /// - Parameters:
    ///   - email: Email del usuario
    ///   - password: Contraseña del usuario
    /// - Returns: Usuario autenticado
    /// - Throws: `AuthError` si las credenciales son inválidas
    public func login(email: String, password: String) async throws -> User {
        let user = try await userRepository.login(email: email, password: password)
        currentUser = user
        return user
    }
}
```

---

## 🔒 Reglas de Dependencias

### Principio de Flujo Unidireccional

```
TIER-3 → TIER-2 → TIER-1 → TIER-0
  ↓       ↓       ↓       ↓
  ✓       ✓       ✓       ✗ (sin dependencias internas)
```

**Permitido**:
- ✅ TIER-3 puede importar TIER-2, TIER-1, TIER-0
- ✅ TIER-2 puede importar TIER-1, TIER-0
- ✅ TIER-1 puede importar TIER-0

**Prohibido**:
- ❌ TIER-0 NO puede importar ningún tier superior
- ❌ TIER-1 NO puede importar TIER-2 o TIER-3
- ❌ TIER-2 NO puede importar TIER-3
- ❌ Dependencias circulares entre módulos del mismo tier

**Validación**: Ver [DEVELOPMENT_GUIDE.md - Validar Dependencias](DEVELOPMENT_GUIDE.md#validar-dependencias)

---

## 🎯 Roadmap

### Fase 1: Foundation (Completado)
- [x] Configurar workspace SPM multi-módulo
- [x] Implementar TIER-0 (Models, Extensions, Protocols)
- [x] Configurar Swift 6.2 strict concurrency
- [x] Documentar arquitectura

### Fase 2: Data Layer (En progreso)
- [ ] Implementar NetworkClient (TIER-1)
- [ ] Implementar KeychainManager (TIER-1)
- [ ] Implementar UserRepository (TIER-1)
- [ ] Implementar CourseRepository (TIER-1)
- [ ] Tests de integración para data layer

### Fase 3: Domain Services (Planeado)
- [ ] Implementar AuthService (TIER-2)
- [ ] Implementar CourseService (TIER-2)
- [ ] Tests de lógica de negocio

### Fase 4: Features (Planeado)
- [ ] Implementar AuthFeature (TIER-3)
- [ ] Implementar DashboardFeature (TIER-3)
- [ ] Demo App de integración

---

## 📄 Licencia

Este proyecto es propiedad de EduGo. Todos los derechos reservados.

---

## 👥 Contribución

### Flujo de Trabajo

1. Crear branch desde `main` siguiendo convención `feature/tierX-modulo`
2. Implementar código siguiendo [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md)
3. Escribir tests (cobertura mínima 80%)
4. Ejecutar `swift build` y `swift test` localmente
5. Crear Pull Request con descripción detallada
6. Code review (thresholds: CR 35%, QA 35%)
7. Merge a `main` tras aprobación

### Contacto

- **Equipo iOS**: ios-team@edugo.com
- **Slack**: #edugo-apple-modules
- **Jira**: [EduGo Apple Modules Board](https://edugo.atlassian.net)

---

**Versión**: 1.0.0
**Última actualización**: 2026-01-23
**Mantenedor**: @edugo-ios-team
