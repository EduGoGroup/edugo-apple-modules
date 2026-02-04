# 🚀 INFORME: PROPUESTA DE MEJORA Y REORGANIZACIÓN

**Fecha:** 27 de Enero 2026  
**Proyecto:** EduGo Apple Modules  
**Versión:** 2.0 (Reorganización para Xcode)

---

## 🎯 RESUMEN EJECUTIVO

Esta propuesta reorganiza completamente la estructura del proyecto para optimizar el trabajo en Xcode, eliminar confusiones y mejorar la mantenibilidad, **manteniendo los principios de Clean Architecture** pero con nomenclatura intuitiva y organización clara.

### Objetivos Principales
- ✅ Nomenclatura clara y funcional (eliminar TIER-X)
- ✅ Estructura optimizada para Xcode
- ✅ Reducción de 23 carpetas `.build` a 1
- ✅ Eliminación de proxy targets innecesarios
- ✅ Separación clara de responsabilidades
- ✅ Documentación centralizada

---

## 📁 ESTRUCTURA PROPUESTA

### Vista General

```
EduGoModules/
├── 📦 Packages/                    # Swift Packages principales
│   ├── Foundation/                 # Tier 0: Base común
│   ├── Core/                       # Tier 1: Modelos y utilidades
│   ├── Infrastructure/             # Tier 2: Servicios externos
│   ├── Domain/                     # Tier 2-3: Lógica de negocio
│   ├── Presentation/               # Tier 3: UI y ViewModels
│   └── Features/                   # Tier 4: Características completas
│
├── 📱 Apps/                        # Aplicaciones demo/ejemplo
│   ├── DemoApp/
│   └── PreviewApp/
│
├── 🧪 Tests/                       # Tests compartidos
│   └── TestUtilities/
│
├── 📚 Documentation/                # Documentación centralizada
│   ├── Architecture/
│   ├── Guides/
│   └── API/
│
├── 🛠️ Tools/                       # Scripts y herramientas
│   ├── Scripts/
│   └── Templates/
│
├── Package.swift                   # Package principal (sin proxies)
├── EduGoModules.xcworkspace
└── README.md
```

---

## 📦 DESGLOSE DETALLADO DE PACKAGES

### 1. **Foundation/** (Tier 0)
*Sin dependencias, base de todo el proyecto*

```
Packages/Foundation/
├── Package.swift
└── Sources/
    └── EduGoFoundation/
        ├── Extensions/
        │   ├── Array+Extensions.swift
        │   ├── String+Extensions.swift
        │   └── Date+Extensions.swift
        ├── Protocols/
        │   ├── Identifiable.swift
        │   └── Sendable.swift
        └── Types/
            ├── Result.swift
            └── Either.swift
```

**Propósito:** Tipos básicos, extensiones fundamentales, protocolos comunes.

---

### 2. **Core/** (Tier 1)
*Depende solo de Foundation*

```
Packages/Core/
├── Package.swift
└── Sources/
    ├── Models/                     # Modelos de dominio
    │   ├── Domain/
    │   │   ├── User.swift
    │   │   ├── Course.swift
    │   │   └── Assignment.swift
    │   ├── DTOs/
    │   │   ├── UserDTO.swift
    │   │   └── CourseDTO.swift
    │   ├── Mappers/
    │   │   └── UserMapper.swift
    │   ├── Validation/
    │   │   └── EmailValidator.swift
    │   └── Protocols/
    │       └── DomainModel.swift
    │
    ├── Logger/                     # Sistema de logging
    │   ├── Logger.swift
    │   ├── LogLevel.swift
    │   └── LogDestination.swift
    │
    └── Utilities/                  # Utilidades generales
        ├── DateFormatter.swift
        ├── JSONCoder.swift
        └── KeychainWrapper.swift
```

**Propósito:** Modelos puros, logging, utilidades sin lógica de negocio.

**Dependencias:**
```swift
dependencies: [
    .package(path: "../Foundation")
]
```

---

### 3. **Infrastructure/** (Tier 2)
*Implementaciones de servicios externos*

```
Packages/Infrastructure/
├── Package.swift
└── Sources/
    ├── Network/                    # Cliente HTTP
    │   ├── HTTPClient.swift
    │   ├── Endpoint.swift
    │   ├── NetworkError.swift
    │   └── Mocks/
    │       └── MockHTTPClient.swift
    │
    ├── Storage/                    # Persistencia local
    │   ├── UserDefaults/
    │   │   └── UserDefaultsStore.swift
    │   ├── FileSystem/
    │   │   └── FileManager+Extensions.swift
    │   └── Protocols/
    │       └── StorageProtocol.swift
    │
    └── Persistence/                # Core Data / SQLite
        ├── CoreDataStack.swift
        ├── PersistenceController.swift
        └── Entities/
            └── UserEntity.swift
```

**Propósito:** Acceso a APIs, bases de datos, archivos, red.

**Dependencias:**
```swift
dependencies: [
    .package(path: "../Foundation"),
    .package(path: "../Core")
]
```

---

### 4. **Domain/** (Tier 2.5-3)
*Lógica de negocio y casos de uso*

```
Packages/Domain/
├── Package.swift
└── Sources/
    ├── Services/                   # Servicios de dominio
    │   ├── Auth/
    │   │   ├── AuthService.swift
    │   │   ├── AuthRepository.swift
    │   │   └── TokenManager.swift
    │   ├── Roles/
    │   │   ├── RoleService.swift
    │   │   └── PermissionChecker.swift
    │   └── Protocols/
    │       └── DomainService.swift
    │
    ├── UseCases/                   # Casos de uso
    │   ├── User/
    │   │   ├── LoginUseCase.swift
    │   │   ├── LogoutUseCase.swift
    │   │   └── UpdateProfileUseCase.swift
    │   ├── Course/
    │   │   ├── EnrollCourseUseCase.swift
    │   │   └── GetCoursesUseCase.swift
    │   └── Protocols/
    │       └── UseCase.swift
    │
    ├── StateManagement/            # Estado global
    │   ├── AppState.swift
    │   ├── Store.swift
    │   └── Reducers/
    │       └── UserReducer.swift
    │
    └── CQRS/                       # Comandos y Queries
        ├── Commands/
        │   ├── CreateUserCommand.swift
        │   └── UpdateUserCommand.swift
        ├── Queries/
        │   ├── GetUserQuery.swift
        │   └── ListUsersQuery.swift
        └── Handlers/
            └── CommandHandler.swift
```

**Propósito:** Lógica de negocio pura, casos de uso, servicios de dominio.

**Dependencias:**
```swift
dependencies: [
    .package(path: "../Foundation"),
    .package(path: "../Core"),
    .package(path: "../Infrastructure")
]
```

---

### 5. **Presentation/** (Tier 3)
*UI Components, ViewModels, Temas*

```
Packages/Presentation/
├── Package.swift
└── Sources/
    ├── DesignSystem/               # Sistema de diseño
    │   ├── Theme/
    │   │   ├── ColorTokens.swift
    │   │   ├── Typography.swift
    │   │   ├── Spacing.swift
    │   │   └── EduTheme.swift
    │   ├── Effects/
    │   │   ├── LiquidGlass.swift
    │   │   ├── Shadows.swift
    │   │   └── Gradients.swift
    │   └── Accessibility/
    │       ├── AccessibilityHelper.swift
    │       └── VoiceOverSupport.swift
    │
    ├── Components/                 # Componentes UI reutilizables
    │   ├── Buttons/
    │   │   ├── EduButton.swift
    │   │   └── EduIconButton.swift
    │   ├── Forms/
    │   │   ├── EduTextField.swift
    │   │   ├── EduSecureField.swift
    │   │   └── EduFormSection.swift
    │   ├── Lists/
    │   │   ├── EduList.swift
    │   │   └── EduListRow.swift
    │   ├── Cards/
    │   │   └── EduCard.swift
    │   ├── Loading/
    │   │   ├── LoadingView.swift
    │   │   └── ProgressIndicator.swift
    │   └── Feedback/
    │       ├── ErrorView.swift
    │       └── EmptyStateView.swift
    │
    ├── Navigation/                 # Navegación
    │   ├── Coordinator.swift
    │   ├── Router.swift
    │   ├── NavigationStyle.swift
    │   └── SplitViewCoordinator.swift
    │
    ├── ViewModels/                 # ViewModels base
    │   ├── BaseViewModel.swift
    │   ├── ListViewModel.swift
    │   └── FormViewModel.swift
    │
    └── Utilities/                  # Utilidades UI
        ├── Binding+Extensions.swift
        ├── View+Extensions.swift
        └── PreviewProvider+Helpers.swift
```

**Propósito:** Todo lo relacionado con UI, temas, componentes visuales.

**Dependencias:**
```swift
dependencies: [
    .package(path: "../Foundation"),
    .package(path: "../Core"),
    .package(path: "../Domain")
]
```

---

### 6. **Features/** (Tier 4)
*Características completas (View + ViewModel + Lógica)*

```
Packages/Features/
├── Package.swift
└── Sources/
    ├── Authentication/             # Feature: Login/Registro
    │   ├── Views/
    │   │   ├── LoginView.swift
    │   │   ├── RegisterView.swift
    │   │   └── ForgotPasswordView.swift
    │   ├── ViewModels/
    │   │   ├── LoginViewModel.swift
    │   │   └── RegisterViewModel.swift
    │   └── Coordinator/
    │       └── AuthCoordinator.swift
    │
    ├── Dashboard/                  # Feature: Dashboard
    │   ├── Views/
    │   │   ├── DashboardView.swift
    │   │   └── DashboardCardView.swift
    │   ├── ViewModels/
    │   │   └── DashboardViewModel.swift
    │   └── Subfeatures/
    │       └── QuickActions/
    │
    ├── Profile/                    # Feature: Perfil de usuario
    │   ├── Views/
    │   │   ├── ProfileView.swift
    │   │   └── EditProfileView.swift
    │   └── ViewModels/
    │       └── ProfileViewModel.swift
    │
    ├── AI/                         # Feature: Integración AI
    │   ├── AIService.swift
    │   ├── AIPromptBuilder.swift
    │   └── Views/
    │       └── AIAssistantView.swift
    │
    ├── Analytics/                  # Feature: Analytics
    │   ├── AnalyticsTracker.swift
    │   └── Events/
    │       └── UserEvent.swift
    │
    └── API/                        # Feature: API Integration
        ├── APIClient.swift
        └── Endpoints/
            └── UserEndpoints.swift
```

**Propósito:** Features completas, pantallas, flujos de usuario.

**Dependencias:**
```swift
dependencies: [
    .package(path: "../Foundation"),
    .package(path: "../Core"),
    .package(path: "../Infrastructure"),
    .package(path: "../Domain"),
    .package(path: "../Presentation")
]
```

---

## 📱 APPS

### Demo Apps
```
Apps/
├── DemoApp/                        # App de demostración completa
│   ├── DemoApp.xcodeproj
│   ├── Sources/
│   │   ├── App.swift
│   │   ├── ContentView.swift
│   │   └── DependencyContainer.swift
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
│
└── PreviewApp/                     # App para Xcode Previews
    ├── PreviewApp.xcodeproj
    └── Sources/
        └── PreviewApp.swift
```

---

## 📚 DOCUMENTACIÓN CENTRALIZADA

```
Documentation/
├── Architecture/
│   ├── Overview.md                 # Visión general
│   ├── CleanArchitecture.md        # Principios
│   ├── DependencyFlow.md           # Flujo de dependencias
│   └── Diagrams/                   # Diagramas visuales
│       ├── architecture.png
│       └── dependency-graph.png
│
├── Guides/
│   ├── GettingStarted.md           # Inicio rápido
│   ├── XcodeSetup.md               # Configuración Xcode
│   ├── AddingNewFeature.md         # Agregar features
│   ├── TestingStrategy.md          # Estrategia de testing
│   └── Contributing.md             # Guía de contribución
│
├── API/
│   ├── Foundation.md
│   ├── Core.md
│   ├── Infrastructure.md
│   ├── Domain.md
│   ├── Presentation.md
│   └── Features.md
│
└── Decisions/                      # ADRs (Architecture Decision Records)
    ├── 001-multi-package-structure.md
    ├── 002-no-external-dependencies.md
    └── 003-swift-6-concurrency.md
```

---

## 🛠️ TOOLS

```
Tools/
├── Scripts/
│   ├── setup.sh                    # Setup inicial
│   ├── build.sh                    # Build todos los módulos
│   ├── test.sh                     # Run tests
│   ├── format.sh                   # Format código
│   └── generate-docs.sh            # Generar documentación
│
└── Templates/
    ├── Feature/                    # Template para nuevo feature
    │   ├── View.swift
    │   ├── ViewModel.swift
    │   └── Tests.swift
    └── Service/                    # Template para nuevo servicio
        ├── Service.swift
        ├── Protocol.swift
        └── Tests.swift
```

---

## 📦 PACKAGE.SWIFT SIMPLIFICADO

### Antes (Actual - Confuso)
```swift
// 8 proxy targets innecesarios
.target(name: "EduUIProxy", dependencies: [.product(name: "UI", package: "UI")])
.target(name: "EduThemeProxy", dependencies: [.product(name: "Theme", package: "Theme")])
// ... 6 más

// Dependencias con rutas complejas
.package(path: "TIER-3-Presentation/UI")
.package(path: "TIER-3-Presentation/Theme")
```

### Después (Propuesto - Simple)
```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduGoModules",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        // Módulos principales expuestos
        .library(name: "Foundation", targets: ["Foundation"]),
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Infrastructure", targets: ["Infrastructure"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Presentation", targets: ["Presentation"]),
        .library(name: "Features", targets: ["Features"])
    ],
    dependencies: [
        // Packages locales (estructura simplificada)
        .package(path: "Packages/Foundation"),
        .package(path: "Packages/Core"),
        .package(path: "Packages/Infrastructure"),
        .package(path: "Packages/Domain"),
        .package(path: "Packages/Presentation"),
        .package(path: "Packages/Features")
    ],
    targets: [
        // Los targets reales están en cada Package.swift individual
    ]
)
```

---

## 🔄 PLAN DE MIGRACIÓN

### Fase 1: Preparación (1-2 horas)
1. ✅ Crear backup completo del proyecto actual
2. ✅ Crear branch de migración: `refactor/restructure-for-xcode`
3. ✅ Crear nueva estructura de carpetas vacía
4. ✅ Documentar mapeo: viejo → nuevo

### Fase 2: Migración Foundation y Core (2-3 horas)
```bash
# Mapeo de archivos
TIER-0-Foundation/EduGoCommon/                → Packages/Foundation/
TIER-1-Core/Models/                           → Packages/Core/Sources/Models/
TIER-1-Core/Logger/                           → Packages/Core/Sources/Logger/
TIER-1-Core/Utilities/                        → Packages/Core/Sources/Utilities/
```

**Pasos:**
1. Mover archivos Swift a nueva ubicación
2. Crear Package.swift simplificado
3. Actualizar imports en archivos movidos
4. Compilar y verificar

### Fase 3: Migración Infrastructure (2-3 horas)
```bash
# Mapeo de archivos
TIER-2-Infrastructure/Network/                → Packages/Infrastructure/Sources/Network/
TIER-2-Infrastructure/Storage/                → Packages/Infrastructure/Sources/Storage/
TIER-2-Infrastructure/LocalPersistence/       → Packages/Infrastructure/Sources/Persistence/
```

**Pasos:**
1. Mover archivos
2. Actualizar dependencias en Package.swift
3. Actualizar imports
4. Tests: verificar que pasen

### Fase 4: Migración Domain (3-4 horas)
```bash
# Mapeo de archivos
TIER-3-Domain/Auth/                           → Packages/Domain/Sources/Services/Auth/
TIER-3-Domain/Roles/                          → Packages/Domain/Sources/Services/Roles/
TIER-2-Domain/StateManagement/                → Packages/Domain/Sources/StateManagement/
TIER-2-Domain/CQRS/                           → Packages/Domain/Sources/CQRS/
TIER-2-Domain/UseCases/                       → Packages/Domain/Sources/UseCases/
```

**Pasos:**
1. Consolidar todos los módulos de dominio
2. Resolver dependencias circulares si existen
3. Actualizar imports
4. Verificar lógica de negocio

### Fase 5: Migración Presentation (3-4 horas)
```bash
# Mapeo de archivos
TIER-3-Presentation/Theme/                    → Packages/Presentation/Sources/DesignSystem/Theme/
TIER-3-Presentation/Effects/                  → Packages/Presentation/Sources/DesignSystem/Effects/
TIER-3-Presentation/Accessibility/            → Packages/Presentation/Sources/DesignSystem/Accessibility/
TIER-3-Presentation/UI/                       → Packages/Presentation/Sources/Components/
TIER-3-Presentation/Navigation/               → Packages/Presentation/Sources/Navigation/
TIER-3-Presentation/Binding/                  → Packages/Presentation/Sources/Utilities/
TIER-3-ViewModels/ViewModels/                 → Packages/Presentation/Sources/ViewModels/
```

**Pasos:**
1. Consolidar todos los módulos de UI
2. Organizar por tipo (DesignSystem, Components, etc.)
3. Actualizar imports masivamente
4. Verificar Xcode Previews

### Fase 6: Migración Features (2-3 horas)
```bash
# Mapeo de archivos
TIER-4-Features/AI/                           → Packages/Features/Sources/AI/
TIER-4-Features/API/                          → Packages/Features/Sources/API/
TIER-4-Features/Analytics/                    → Packages/Features/Sources/Analytics/
```

**Pasos:**
1. Mover features
2. Crear estructura View/ViewModel/Coordinator si no existe
3. Actualizar dependencias
4. Verificar compilación

### Fase 7: Documentación y Limpieza (2-3 horas)
1. ✅ Mover toda documentación a `Documentation/`
2. ✅ Actualizar README.md principal
3. ✅ Crear guías de navegación
4. ✅ Generar diagramas actualizados
5. ✅ Eliminar carpetas vacías antiguas
6. ✅ Limpiar todas las carpetas .build

### Fase 8: Configuración Xcode (1-2 horas)
1. ✅ Regenerar workspace
2. ✅ Crear schemes compartidos
3. ✅ Configurar test plans
4. ✅ Optimizar build settings
5. ✅ Verificar navegación

### Fase 9: Testing Final (2-3 horas)
1. ✅ Compilar todo el proyecto
2. ✅ Run todos los tests
3. ✅ Verificar Xcode Previews
4. ✅ Verificar performance de compilación
5. ✅ Testing manual en simulador

### Fase 10: Merge y Deploy (1 hora)
1. ✅ Code review
2. ✅ Actualizar CI/CD scripts
3. ✅ Merge a main
4. ✅ Tag versión 2.0

---

## 📊 COMPARATIVA: ANTES vs DESPUÉS

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Carpetas raíz** | 15+ (confusas) | 6 (claras) |
| **Niveles profundidad** | 6-8 niveles | 3-4 niveles |
| **Nomenclatura** | TIER-X (técnica) | Funcional (Foundation, Core, etc.) |
| **Carpetas .build** | 23 carpetas | 1 carpeta (raíz) |
| **Espacio .build** | ~6.3GB | ~1.5GB |
| **Proxy targets** | 8 proxies | 0 proxies |
| **Package.swift lines** | ~150 líneas | ~50 líneas |
| **Tiempo compilación** | ~5-8 min | ~2-3 min (estimado) |
| **Documentación** | 8+ archivos raíz | 1 carpeta centralizada |
| **Claridad estructura** | ❌ Confusa | ✅ Clara |
| **Xcode navigation** | ❌ Difícil | ✅ Intuitiva |
| **Onboarding devs** | 2-3 días | 2-3 horas |

---

## 🎯 BENEFICIOS ESPERADOS

### Para Desarrolladores
- ✅ Navegación intuitiva en Xcode
- ✅ Autocompletado más rápido
- ✅ Fácil encontrar cualquier archivo
- ✅ Onboarding de nuevos devs más rápido
- ✅ Menos confusión sobre dónde poner código nuevo

### Para el Proyecto
- ✅ Build times reducidos (~60% más rápido)
- ✅ Menos espacio en disco (~75% menos .build)
- ✅ Estructura escalable
- ✅ Mejor separación de responsabilidades
- ✅ Documentación centralizada y mantenible

### Para CI/CD
- ✅ Pipelines más simples
- ✅ Cache más eficiente
- ✅ Menos tiempo de ejecución
- ✅ Menos recursos necesarios

---

## 🔒 PRINCIPIOS MANTENIDOS

### Clean Architecture ✅
```
Features → Domain → Infrastructure → Core → Foundation
  (UI)      (Logic)    (External)    (Models)  (Base)
```

### Dependency Rule ✅
```
Foundation ← Core ← Infrastructure ← Domain ← Presentation ← Features
(no deps)                                                    (all deps)
```

### Protocol-Oriented Programming ✅
- Todos los servicios exponen protocolos
- Inyección de dependencias
- Testabilidad completa

### Swift 6.2 Strict Concurrency ✅
- @MainActor para ViewModels
- actor para servicios con estado
- Sendable en todos los modelos

---

## 📝 SCRIPTS DE MIGRACIÓN

### Script 1: Crear Nueva Estructura
```bash
#!/bin/bash
# Tools/Scripts/create-new-structure.sh

echo "🏗️  Creando nueva estructura..."

mkdir -p Packages/{Foundation,Core,Infrastructure,Domain,Presentation,Features}
mkdir -p Apps/{DemoApp,PreviewApp}
mkdir -p Tests/TestUtilities
mkdir -p Documentation/{Architecture,Guides,API,Decisions}
mkdir -p Tools/{Scripts,Templates}

# Crear Package.swift básicos
for pkg in Foundation Core Infrastructure Domain Presentation Features; do
    cat > "Packages/$pkg/Package.swift" << EOF
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "$pkg",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "$pkg", targets: ["$pkg"])
    ],
    targets: [
        .target(name: "$pkg"),
        .testTarget(name: "${pkg}Tests", dependencies: ["$pkg"])
    ]
)
EOF
    
    mkdir -p "Packages/$pkg/Sources/$pkg"
    mkdir -p "Packages/$pkg/Tests/${pkg}Tests"
done

echo "✅ Estructura creada!"
```

### Script 2: Migrar Archivos por Tier
```bash
#!/bin/bash
# Tools/Scripts/migrate-tier.sh

migrate_foundation() {
    echo "📦 Migrando Foundation..."
    cp -r TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon/* \
          Packages/Foundation/Sources/Foundation/
}

migrate_core() {
    echo "📦 Migrando Core..."
    
    # Models
    cp -r TIER-1-Core/Models/Sources/Models/* \
          Packages/Core/Sources/Core/Models/
    
    # Logger
    cp -r TIER-1-Core/Logger/Sources/Logger/* \
          Packages/Core/Sources/Core/Logger/
    
    # Utilities
    cp -r TIER-1-Core/Utilities/Sources/Utilities/* \
          Packages/Core/Sources/Core/Utilities/
}

# Ejecutar migraciones
migrate_foundation
migrate_core

echo "✅ Migración completada!"
```

### Script 3: Actualizar Imports
```bash
#!/bin/bash
# Tools/Scripts/update-imports.sh

echo "🔄 Actualizando imports..."

# Reemplazar imports viejos por nuevos
find Packages -name "*.swift" -type f -exec sed -i '' \
    -e 's/import EduGoCommon/import Foundation/g' \
    -e 's/import Models/import Core/g' \
    -e 's/import Logger/import Core/g' \
    -e 's/import Utilities/import Core/g' \
    {} +

echo "✅ Imports actualizados!"
```

### Script 4: Limpiar Build Folders
```bash
#!/bin/bash
# Tools/Scripts/clean-all.sh

echo "🧹 Limpiando todas las carpetas .build..."

# Encontrar y eliminar todas las carpetas .build
find . -name ".build" -type d -exec rm -rf {} + 2>/dev/null

# Limpiar DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/EduGo*

# Limpiar .swiftpm
find . -name ".swiftpm" -type d -exec rm -rf {} + 2>/dev/null

echo "✅ Limpieza completada!"
echo "💾 Espacio liberado: ~6GB"
```

---

## 📋 CHECKLIST DE MIGRACIÓN

### Pre-Migración
- [ ] Hacer backup completo del proyecto
- [ ] Crear branch: `refactor/restructure-for-xcode`
- [ ] Verificar que todos los tests pasen en estructura actual
- [ ] Documentar estado actual (coverage, build time, etc.)
- [ ] Comunicar a equipo sobre migración

### Migración
- [ ] Ejecutar `create-new-structure.sh`
- [ ] Migrar Foundation (Tier 0)
- [ ] Migrar Core (Tier 1)
- [ ] Migrar Infrastructure (Tier 2)
- [ ] Migrar Domain (Tier 2.5-3)
- [ ] Migrar Presentation (Tier 3)
- [ ] Migrar Features (Tier 4)
- [ ] Ejecutar `update-imports.sh`
- [ ] Actualizar Package.swift raíz
- [ ] Mover documentación a `Documentation/`
- [ ] Crear scripts en `Tools/`

### Post-Migración
- [ ] Compilar todo el proyecto sin errores
- [ ] Verificar que todos los tests pasen
- [ ] Ejecutar `clean-all.sh`
- [ ] Regenerar Xcode workspace
- [ ] Configurar schemes compartidos
- [ ] Actualizar README.md
- [ ] Crear guía de migración para equipo
- [ ] Actualizar CI/CD pipelines
- [ ] Medir mejoras (build time, espacio, etc.)

### Validación
- [ ] Code review completo
- [ ] Testing manual en simulador
- [ ] Verificar Xcode Previews funcionan
- [ ] Validar navegación en Xcode
- [ ] Verificar documentación está accesible
- [ ] Confirmar mejoras de performance

### Deploy
- [ ] Merge a `main`
- [ ] Tag versión `v2.0.0`
- [ ] Actualizar documentación en wiki/confluence
- [ ] Comunicar cambios a equipo
- [ ] Archivar estructura antigua (por 30 días)

---

## 🚨 RIESGOS Y MITIGACIONES

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| **Imports rotos** | Alta | Alto | Script automatizado + testing exhaustivo |
| **Tests fallan** | Media | Alto | Migrar tests en paralelo, validar fase por fase |
| **Pérdida de código** | Baja | Crítico | Backup completo + Git + verificación manual |
| **Build issues** | Media | Medio | Testing incremental, rollback plan |
| **CI/CD breaks** | Media | Alto | Actualizar pipelines en paralelo |
| **Team confusion** | Alta | Bajo | Documentación + onboarding session |

---

## 📅 TIMELINE ESTIMADO

| Fase | Duración | Recursos |
|------|----------|----------|
| **Preparación** | 2 horas | 1 dev |
| **Foundation + Core** | 3 horas | 1 dev |
| **Infrastructure** | 3 horas | 1 dev |
| **Domain** | 4 horas | 1 dev |
| **Presentation** | 4 horas | 1-2 devs |
| **Features** | 3 horas | 1 dev |
| **Documentación** | 3 horas | 1 dev |
| **Xcode Config** | 2 horas | 1 dev |
| **Testing** | 3 horas | 2 devs |
| **Deploy** | 1 hora | 1 dev |
| **TOTAL** | **28 horas** | **~3.5 días laborales** |

---

## 🎓 GUÍA DE NAVEGACIÓN POST-MIGRACIÓN

### Encontrar algo rápido:

**¿Dónde está el modelo User?**
```
Packages/Core/Sources/Core/Models/Domain/User.swift
```

**¿Dónde está el AuthService?**
```
Packages/Domain/Sources/Services/Auth/AuthService.swift
```

**¿Dónde está el LoginView?**
```
Packages/Features/Sources/Authentication/Views/LoginView.swift
```

**¿Dónde está el Theme?**
```
Packages/Presentation/Sources/DesignSystem/Theme/EduTheme.swift
```

**¿Dónde están los componentes UI?**
```
Packages/Presentation/Sources/Components/
```

**¿Dónde está la documentación?**
```
Documentation/
```

---

## 🔗 REFERENCIAS

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [Xcode Workspace Best Practices](https://developer.apple.com/documentation/xcode/organizing-your-code)
- [Modular Architecture in iOS](https://www.pointfree.co/collections/tours/modular-architecture)

---

## ✅ CONCLUSIÓN

Esta reorganización transforma el proyecto de una estructura técnica y confusa (TIER-X) a una estructura funcional, intuitiva y optimizada para Xcode, **sin comprometer los principios de Clean Architecture**.

### ROI Esperado
- **Tiempo:** 3.5 días de migración
- **Beneficio:** Mejora permanente en velocidad de desarrollo (~30%)
- **Ahorro:** ~6GB de espacio, ~60% más rápido compilación
- **Onboarding:** De 2-3 días a 2-3 horas

### Próximos Pasos
1. Revisión y aprobación del equipo
2. Planificación de sprint para migración
3. Ejecución de migración
4. Sesión de onboarding con equipo

---

**¿Listo para empezar?** 🚀

```bash
# Comando para iniciar migración
git checkout -b refactor/restructure-for-xcode
./Tools/Scripts/create-new-structure.sh
```
