# FASE 05: Migracion Presentation

**Estado:** PENDIENTE  
**Duracion Estimada:** 3-4 horas  
**Dependencias:** FASE 04 completada  
**Fase Anterior:** [FASE-04-DOMAIN.md](./FASE-04-DOMAIN.md)  
**Siguiente Fase:** [FASE-06-FEATURES-FINALIZACION.md](./FASE-06-FEATURES-FINALIZACION.md)

---

## OBJETIVO DE LA FASE

Consolidar toda la capa de presentacion en un unico paquete: UI Components, Theme, Effects, Navigation, Accessibility, Binding y ViewModels. Esta es la fase mas grande ya que TIER-3-Presentation contiene muchos modulos y TIER-3-ViewModels se integra aqui.

---

## MAPEO DE ARCHIVOS

### Theme (TIER-3-Presentation -> DesignSystem/Theme)
```
ORIGEN:
TIER-3-Presentation/Theme/Sources/Theme/

DESTINO:
EduGoModules/Packages/Presentation/Sources/DesignSystem/Theme/
```

### Effects (TIER-3-Presentation -> DesignSystem/Effects)
```
ORIGEN:
TIER-3-Presentation/Effects/Sources/Effects/

DESTINO:
EduGoModules/Packages/Presentation/Sources/DesignSystem/Effects/
```

### Accessibility (TIER-3-Presentation -> DesignSystem/Accessibility)
```
ORIGEN:
TIER-3-Presentation/Accessibility/Sources/EduAccessibility/

DESTINO:
EduGoModules/Packages/Presentation/Sources/DesignSystem/Accessibility/
```

### UI Components (TIER-3-Presentation -> Components)
```
ORIGEN:
TIER-3-Presentation/UI/Sources/UI/
├── Containers/
├── Feedback/
├── Forms/
├── Input/
├── Lists/
├── Loading/
├── Navigation/
└── Utilities/

DESTINO:
EduGoModules/Packages/Presentation/Sources/Components/
├── Containers/
├── Feedback/
├── Forms/
├── Input/
├── Lists/
├── Loading/
├── Navigation/
└── Utilities/
```

### Navigation (TIER-3-Presentation -> Navigation)
```
ORIGEN:
TIER-3-Presentation/Navigation/Sources/Navigation/

DESTINO:
EduGoModules/Packages/Presentation/Sources/Navigation/
```

### Binding (TIER-3-Presentation -> Utilities)
```
ORIGEN:
TIER-3-Presentation/Binding/Sources/Binding/

DESTINO:
EduGoModules/Packages/Presentation/Sources/Utilities/
```

### ViewModels (TIER-3-ViewModels -> ViewModels)
```
ORIGEN:
TIER-3-ViewModels/ViewModels/Sources/ViewModels/

DESTINO:
EduGoModules/Packages/Presentation/Sources/ViewModels/
```

---

## PREREQUISITOS

- [ ] FASE 04 completada exitosamente
- [ ] Foundation, Core, Infrastructure y Domain compilando
- [ ] Branch `refactor/restructure-for-xcode` activo
- [ ] No hay cambios sin commit

---

## TAREAS DETALLADAS

### TAREA 5.1: Verificar Estado Previo
**Tiempo estimado:** 5 minutos

**Pasos:**
1. Verificar rama y estado
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple
   git branch --show-current
   git status
   ```

2. Verificar que todos los packages anteriores compilan
   ```bash
   cd EduGoModules
   swift build
   cd ..
   ```

3. Verificar estructura de Presentation
   ```bash
   ls -la EduGoModules/Packages/Presentation/Sources/
   ```

**Checklist:**
- [ ] Rama verificada
- [ ] EduGoModules compila
- [ ] Estructura Presentation verificada

---

### TAREA 5.2: Analizar Contenido de TIER-3-Presentation
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Analizar Theme
   ```bash
   echo "=== THEME ==="
   find TIER-3-Presentation/Theme/Sources/Theme -name "*.swift" -type f | head -20
   find TIER-3-Presentation/Theme/Sources/Theme -name "*.swift" | wc -l
   find TIER-3-Presentation/Theme/Sources/Theme -type d
   ```

2. Analizar Effects
   ```bash
   echo "=== EFFECTS ==="
   find TIER-3-Presentation/Effects/Sources/Effects -name "*.swift" -type f | head -20
   find TIER-3-Presentation/Effects/Sources/Effects -name "*.swift" | wc -l
   find TIER-3-Presentation/Effects/Sources/Effects -type d
   ```

3. Analizar Accessibility
   ```bash
   echo "=== ACCESSIBILITY ==="
   find TIER-3-Presentation/Accessibility/Sources/EduAccessibility -name "*.swift" -type f
   find TIER-3-Presentation/Accessibility/Sources/EduAccessibility -name "*.swift" | wc -l
   ```

4. Analizar UI (mas grande)
   ```bash
   echo "=== UI COMPONENTS ==="
   find TIER-3-Presentation/UI/Sources/UI -name "*.swift" -type f | wc -l
   find TIER-3-Presentation/UI/Sources/UI -type d
   # Desglose por subcarpeta
   for dir in Containers Feedback Forms Input Lists Loading Navigation Utilities; do
     count=$(find TIER-3-Presentation/UI/Sources/UI/$dir -name "*.swift" 2>/dev/null | wc -l)
     echo "$dir: $count archivos"
   done
   ```

5. Analizar Navigation
   ```bash
   echo "=== NAVIGATION ==="
   find TIER-3-Presentation/Navigation/Sources/Navigation -name "*.swift" -type f
   find TIER-3-Presentation/Navigation/Sources/Navigation -name "*.swift" | wc -l
   ```

6. Analizar Binding
   ```bash
   echo "=== BINDING ==="
   find TIER-3-Presentation/Binding/Sources/Binding -name "*.swift" -type f
   find TIER-3-Presentation/Binding/Sources/Binding -name "*.swift" | wc -l
   ```

7. Analizar ViewModels (TIER-3-ViewModels)
   ```bash
   echo "=== VIEWMODELS ==="
   find TIER-3-ViewModels/ViewModels/Sources/ViewModels -name "*.swift" -type f | head -20
   find TIER-3-ViewModels/ViewModels/Sources/ViewModels -name "*.swift" | wc -l
   find TIER-3-ViewModels/ViewModels/Sources/ViewModels -type d
   ```

8. Documentar hallazgos:

| Modulo | Archivos | Subcarpetas |
|--------|----------|-------------|
| Theme | ___ | ___ |
| Effects | ___ | ___ |
| Accessibility | ___ | ___ |
| UI Components | ___ | 8 |
| Navigation | ___ | ___ |
| Binding | ___ | ___ |
| ViewModels | ___ | ___ |
| **TOTAL** | ___ | |

**Checklist:**
- [ ] Theme analizado
- [ ] Effects analizado
- [ ] Accessibility analizado
- [ ] UI Components analizado
- [ ] Navigation analizado
- [ ] Binding analizado
- [ ] ViewModels analizado
- [ ] Totales documentados

---

### TAREA 5.3: Migrar Theme
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Presentation/Sources/DesignSystem/Theme/Placeholder.swift
   ```

2. Copiar archivos de Theme
   ```bash
   cp -R TIER-3-Presentation/Theme/Sources/Theme/* \
         EduGoModules/Packages/Presentation/Sources/DesignSystem/Theme/
   ```

3. Verificar copia
   ```bash
   ls -la EduGoModules/Packages/Presentation/Sources/DesignSystem/Theme/
   ```

4. Actualizar imports (Theme probablemente no tiene dependencias internas)
   ```bash
   grep -h "^import " EduGoModules/Packages/Presentation/Sources/DesignSystem/Theme/*.swift | sort -u
   # Si hay imports a EduGoCommon:
   find EduGoModules/Packages/Presentation/Sources/DesignSystem/Theme -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports verificados/actualizados

---

### TAREA 5.4: Migrar Effects
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Presentation/Sources/DesignSystem/Effects/Placeholder.swift
   ```

2. Copiar archivos de Effects
   ```bash
   cp -R TIER-3-Presentation/Effects/Sources/Effects/* \
         EduGoModules/Packages/Presentation/Sources/DesignSystem/Effects/
   ```

3. Actualizar imports
   ```bash
   find EduGoModules/Packages/Presentation/Sources/DesignSystem/Effects -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 5.5: Migrar Accessibility
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Presentation/Sources/DesignSystem/Accessibility/Placeholder.swift
   ```

2. Copiar archivos de Accessibility
   ```bash
   cp -R TIER-3-Presentation/Accessibility/Sources/EduAccessibility/* \
         EduGoModules/Packages/Presentation/Sources/DesignSystem/Accessibility/
   ```

3. Actualizar imports
   ```bash
   find EduGoModules/Packages/Presentation/Sources/DesignSystem/Accessibility -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 5.6: Migrar UI Components
**Tiempo estimado:** 25 minutos

**ATENCION:** Este es el modulo mas grande. UI depende de Binding, Theme y Accessibility.

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Presentation/Sources/Components/Placeholder.swift
   ```

2. Copiar estructura completa de UI
   ```bash
   cp -R TIER-3-Presentation/UI/Sources/UI/* \
         EduGoModules/Packages/Presentation/Sources/Components/
   ```

3. Verificar estructura
   ```bash
   find EduGoModules/Packages/Presentation/Sources/Components -type d
   find EduGoModules/Packages/Presentation/Sources/Components -name "*.swift" | wc -l
   ```

4. Actualizar imports masivamente
   ```bash
   # EduGoCommon -> EduFoundation
   find EduGoModules/Packages/Presentation/Sources/Components -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   # Binding -> Sera interno en Presentation
   find EduGoModules/Packages/Presentation/Sources/Components -name "*.swift" -exec \
     sed -i '' 's/import Binding//g' {} +
   
   # Theme -> Sera interno en Presentation
   find EduGoModules/Packages/Presentation/Sources/Components -name "*.swift" -exec \
     sed -i '' 's/import Theme//g' {} +
   
   # Accessibility -> Sera interno en Presentation
   find EduGoModules/Packages/Presentation/Sources/Components -name "*.swift" -exec \
     sed -i '' 's/import EduAccessibility//g' {} +
   find EduGoModules/Packages/Presentation/Sources/Components -name "*.swift" -exec \
     sed -i '' 's/import Accessibility//g' {} +
   
   # StateManagement -> EduDomain
   find EduGoModules/Packages/Presentation/Sources/Components -name "*.swift" -exec \
     sed -i '' 's/import StateManagement/import EduDomain/g' {} +
   ```

5. Limpiar lineas vacias de imports eliminados
   ```bash
   find EduGoModules/Packages/Presentation/Sources/Components -name "*.swift" -exec \
     sed -i '' '/^import $/d' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Estructura verificada
- [ ] Imports actualizados

---

### TAREA 5.7: Migrar Navigation
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Presentation/Sources/Navigation/Placeholder.swift
   ```

2. Copiar archivos de Navigation
   ```bash
   cp -R TIER-3-Presentation/Navigation/Sources/Navigation/* \
         EduGoModules/Packages/Presentation/Sources/Navigation/
   ```

3. Actualizar imports
   ```bash
   find EduGoModules/Packages/Presentation/Sources/Navigation -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 5.8: Migrar Binding (-> Utilities)
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Presentation/Sources/Utilities/Placeholder.swift
   ```

2. Copiar archivos de Binding
   ```bash
   cp -R TIER-3-Presentation/Binding/Sources/Binding/* \
         EduGoModules/Packages/Presentation/Sources/Utilities/
   ```

3. Actualizar imports
   ```bash
   find EduGoModules/Packages/Presentation/Sources/Utilities -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 5.9: Migrar ViewModels
**Tiempo estimado:** 20 minutos

**ATENCION:** ViewModels probablemente depende de Domain (UseCases, StateManagement).

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Presentation/Sources/ViewModels/Placeholder.swift
   ```

2. Copiar archivos de ViewModels
   ```bash
   cp -R TIER-3-ViewModels/ViewModels/Sources/ViewModels/* \
         EduGoModules/Packages/Presentation/Sources/ViewModels/
   ```

3. Verificar estructura
   ```bash
   ls -la EduGoModules/Packages/Presentation/Sources/ViewModels/
   find EduGoModules/Packages/Presentation/Sources/ViewModels -type d
   ```

4. Actualizar imports
   ```bash
   # EduGoCommon -> EduFoundation
   find EduGoModules/Packages/Presentation/Sources/ViewModels -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   # Models -> EduCore
   find EduGoModules/Packages/Presentation/Sources/ViewModels -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   
   # UseCases, StateManagement, CQRS -> EduDomain
   find EduGoModules/Packages/Presentation/Sources/ViewModels -name "*.swift" -exec \
     sed -i '' 's/import UseCases/import EduDomain/g' {} +
   
   find EduGoModules/Packages/Presentation/Sources/ViewModels -name "*.swift" -exec \
     sed -i '' 's/import StateManagement/import EduDomain/g' {} +
   
   find EduGoModules/Packages/Presentation/Sources/ViewModels -name "*.swift" -exec \
     sed -i '' 's/import CQRS/import EduDomain/g' {} +
   
   # Auth, Roles -> EduDomain
   find EduGoModules/Packages/Presentation/Sources/ViewModels -name "*.swift" -exec \
     sed -i '' 's/import Auth/import EduDomain/g' {} +
   
   find EduGoModules/Packages/Presentation/Sources/ViewModels -name "*.swift" -exec \
     sed -i '' 's/import Roles/import EduDomain/g' {} +
   ```

5. Verificar imports resultantes
   ```bash
   grep -h "^import " EduGoModules/Packages/Presentation/Sources/ViewModels/*.swift 2>/dev/null | sort -u
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Estructura verificada
- [ ] Imports actualizados

---

### TAREA 5.10: Actualizar Package.swift de Presentation
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Actualizar Package.swift
   ```bash
   cat > EduGoModules/Packages/Presentation/Package.swift << 'EOF'
   // swift-tools-version: 6.2
   import PackageDescription

   let package = Package(
       name: "EduPresentation",
       platforms: [
           .iOS(.v26),
           .macOS(.v26)
       ],
       products: [
           .library(name: "EduPresentation", targets: ["EduPresentation"]),
           // Exponer submodulos individualmente
           .library(name: "EduDesignSystem", targets: ["EduDesignSystem"]),
           .library(name: "EduComponents", targets: ["EduComponents"]),
           .library(name: "EduNavigation", targets: ["EduNavigation"]),
           .library(name: "EduViewModels", targets: ["EduViewModels"]),
           .library(name: "EduPresentationUtilities", targets: ["EduPresentationUtilities"])
       ],
       dependencies: [
           .package(path: "../Foundation"),
           .package(path: "../Core"),
           .package(path: "../Domain")
       ],
       targets: [
           // Target principal que agrupa todo
           .target(
               name: "EduPresentation",
               dependencies: [
                   "EduDesignSystem",
                   "EduComponents",
                   "EduNavigation",
                   "EduViewModels",
                   "EduPresentationUtilities"
               ]
           ),
           // Design System (Theme + Effects + Accessibility)
           .target(
               name: "EduDesignSystem",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation")
               ],
               path: "Sources/DesignSystem"
           ),
           // UI Components
           .target(
               name: "EduComponents",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation"),
                   "EduDesignSystem",
                   "EduPresentationUtilities"
               ],
               path: "Sources/Components"
           ),
           // Navigation
           .target(
               name: "EduNavigation",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation")
               ],
               path: "Sources/Navigation"
           ),
           // ViewModels
           .target(
               name: "EduViewModels",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation"),
                   .product(name: "EduCore", package: "Core"),
                   .product(name: "EduDomain", package: "Domain")
               ],
               path: "Sources/ViewModels"
           ),
           // Utilities (Binding helpers, View extensions)
           .target(
               name: "EduPresentationUtilities",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation")
               ],
               path: "Sources/Utilities"
           ),
           // Tests
           .testTarget(
               name: "EduPresentationTests",
               dependencies: ["EduPresentation"],
               path: "Tests/PresentationTests"
           )
       ]
   )
   EOF
   ```

2. Crear archivo de reexportacion
   ```bash
   mkdir -p EduGoModules/Packages/Presentation/Sources/EduPresentation
   cat > EduGoModules/Packages/Presentation/Sources/EduPresentation/Exports.swift << 'EOF'
   // EduPresentation - Re-exports all submodules
   @_exported import EduDesignSystem
   @_exported import EduComponents
   @_exported import EduNavigation
   @_exported import EduViewModels
   @_exported import EduPresentationUtilities
   EOF
   ```

**Checklist:**
- [ ] Package.swift actualizado
- [ ] Archivo Exports.swift creado

---

### TAREA 5.11: Compilar Presentation
**Tiempo estimado:** 30 minutos

**Pasos:**
1. Compilar Presentation
   ```bash
   cd EduGoModules/Packages/Presentation
   swift build 2>&1 | tee /tmp/presentation-build.log
   ```

2. Si hay errores, analizar
   ```bash
   grep -i "error:" /tmp/presentation-build.log | head -20
   ```

3. Errores comunes y soluciones:

   **Error: Tipos de Theme/Effects/Accessibility no encontrados en Components**
   
   Los componentes necesitan acceso a DesignSystem. Verificar dependencia en Package.swift:
   ```swift
   .target(
       name: "EduComponents",
       dependencies: [
           "EduDesignSystem",  // <-- Debe estar presente
           // ...
       ]
   )
   ```

   **Error: Tipos de Binding no encontrados en Components**
   
   Binding ahora es EduPresentationUtilities:
   ```swift
   .target(
       name: "EduComponents",
       dependencies: [
           "EduPresentationUtilities",  // <-- Agregar
           // ...
       ]
   )
   ```

   **Error: ViewModels necesita StateManagement**
   
   StateManagement ahora esta en Domain:
   ```bash
   # Ya debe estar manejado, pero verificar
   grep -r "import StateManagement" EduGoModules/Packages/Presentation/
   # Si hay, reemplazar por import EduDomain
   ```

   **Error: Referencias a tipos de UI que estan en otro submodulo**
   
   Si Components necesita tipos de Navigation o viceversa:
   ```swift
   // Agregar dependencia cruzada en Package.swift
   .target(
       name: "EduComponents",
       dependencies: [
           "EduNavigation",  // Si necesita Navigation
       ]
   )
   ```

4. Una vez compila, ejecutar tests
   ```bash
   swift test
   cd ../../..
   ```

**Checklist:**
- [ ] Build ejecutado
- [ ] Errores corregidos
- [ ] Build exitoso
- [ ] Tests pasan

---

### TAREA 5.12: Migrar Tests de Presentation
**Tiempo estimado:** 25 minutos

**Pasos:**
1. Verificar tests existentes
   ```bash
   find TIER-3-Presentation/Theme/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-3-Presentation/Effects/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-3-Presentation/Accessibility/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-3-Presentation/UI/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-3-Presentation/Navigation/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-3-Presentation/Binding/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-3-ViewModels/ViewModels/Tests -name "*.swift" 2>/dev/null | wc -l
   ```

2. Eliminar test placeholder
   ```bash
   rm EduGoModules/Packages/Presentation/Tests/PresentationTests/PresentationTests.swift
   ```

3. Crear estructura de tests
   ```bash
   mkdir -p EduGoModules/Packages/Presentation/Tests/PresentationTests/DesignSystem
   mkdir -p EduGoModules/Packages/Presentation/Tests/PresentationTests/Components
   mkdir -p EduGoModules/Packages/Presentation/Tests/PresentationTests/Navigation
   mkdir -p EduGoModules/Packages/Presentation/Tests/PresentationTests/ViewModels
   mkdir -p EduGoModules/Packages/Presentation/Tests/PresentationTests/Utilities
   ```

4. Copiar tests (solo si existen)
   ```bash
   # Theme tests
   cp -R TIER-3-Presentation/Theme/Tests/ThemeTests/* \
         EduGoModules/Packages/Presentation/Tests/PresentationTests/DesignSystem/ 2>/dev/null || true
   
   # Effects tests
   cp -R TIER-3-Presentation/Effects/Tests/EffectsTests/* \
         EduGoModules/Packages/Presentation/Tests/PresentationTests/DesignSystem/ 2>/dev/null || true
   
   # UI tests
   cp -R TIER-3-Presentation/UI/Tests/UITests/* \
         EduGoModules/Packages/Presentation/Tests/PresentationTests/Components/ 2>/dev/null || true
   
   # Navigation tests
   cp -R TIER-3-Presentation/Navigation/Tests/NavigationTests/* \
         EduGoModules/Packages/Presentation/Tests/PresentationTests/Navigation/ 2>/dev/null || true
   
   # ViewModels tests
   cp -R TIER-3-ViewModels/ViewModels/Tests/ViewModelsTests/* \
         EduGoModules/Packages/Presentation/Tests/PresentationTests/ViewModels/ 2>/dev/null || true
   ```

5. Actualizar imports en tests
   ```bash
   find EduGoModules/Packages/Presentation/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import Theme/@testable import EduDesignSystem/g' {} +
   
   find EduGoModules/Packages/Presentation/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import Effects/@testable import EduDesignSystem/g' {} +
   
   find EduGoModules/Packages/Presentation/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import UI/@testable import EduComponents/g' {} +
   
   find EduGoModules/Packages/Presentation/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import Navigation/@testable import EduNavigation/g' {} +
   
   find EduGoModules/Packages/Presentation/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import ViewModels/@testable import EduViewModels/g' {} +
   
   find EduGoModules/Packages/Presentation/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import Binding/@testable import EduPresentationUtilities/g' {} +
   
   find EduGoModules/Packages/Presentation/Tests -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

6. Crear test minimo si no hay tests
   ```bash
   cat > EduGoModules/Packages/Presentation/Tests/PresentationTests/PresentationTests.swift << 'EOF'
   import XCTest
   @testable import EduPresentation
   @testable import EduDesignSystem
   @testable import EduComponents
   @testable import EduNavigation
   @testable import EduViewModels
   @testable import EduPresentationUtilities

   final class PresentationTests: XCTestCase {
       func testModulesLoad() {
           XCTAssertTrue(true, "EduPresentation modules loaded successfully")
       }
   }
   EOF
   ```

7. Ejecutar tests
   ```bash
   cd EduGoModules/Packages/Presentation
   swift test
   cd ../../..
   ```

**Checklist:**
- [ ] Tests existentes verificados
- [ ] Estructura de tests creada
- [ ] Tests copiados
- [ ] Imports actualizados
- [ ] Tests pasan

---

### TAREA 5.13: Verificar Xcode Previews (Opcional pero Recomendado)
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Verificar que hay PreviewProvider en Components
   ```bash
   grep -r "PreviewProvider\|#Preview" EduGoModules/Packages/Presentation/Sources/Components/ | head -10
   ```

2. Si hay previews, abrir en Xcode para verificar
   ```bash
   open EduGoModules/Package.swift
   # En Xcode, navegar a Components y abrir un archivo con Preview
   # Verificar que los previews se renderizan correctamente
   ```

**Checklist:**
- [ ] Previews verificados (si aplica)

---

### TAREA 5.14: Verificar Compilacion Completa
**Tiempo estimado:** 10 minutos

**Pasos:**
1. Compilar desde raiz
   ```bash
   cd EduGoModules
   swift build
   ```

2. Ejecutar todos los tests
   ```bash
   swift test
   ```

3. Verificar cadena de dependencias
   ```bash
   swift package show-dependencies
   ```

**Cadena esperada:**
```
Foundation <- Core <- Infrastructure <- Domain <- Presentation
```

**Checklist:**
- [ ] Build desde raiz exitoso
- [ ] Tests desde raiz exitosos
- [ ] Cadena de dependencias correcta

---

### TAREA 5.15: Commit de Fase 05
**Tiempo estimado:** 5 minutos

**Pasos:**
1. Agregar cambios
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple
   git add EduGoModules/
   ```

2. Commit
   ```bash
   git commit -m "feat(migration): migrate Presentation package - consolidate UI layer

   Presentation (consolidated from TIER-3-Presentation and TIER-3-ViewModels):
   
   DesignSystem:
   - Migrated Theme from TIER-3-Presentation/Theme
   - Migrated Effects from TIER-3-Presentation/Effects
   - Migrated Accessibility from TIER-3-Presentation/Accessibility
   
   Components:
   - Migrated UI components from TIER-3-Presentation/UI
   - Includes: Containers, Feedback, Forms, Input, Lists, Loading, Navigation, Utilities
   
   Navigation:
   - Migrated from TIER-3-Presentation/Navigation
   
   ViewModels:
   - Migrated from TIER-3-ViewModels/ViewModels
   
   Utilities:
   - Migrated Binding helpers from TIER-3-Presentation/Binding
   
   Key improvements:
   - Unified all UI code in single Presentation package
   - Resolved TIER-3 triple-purpose confusion
   - DesignSystem groups Theme, Effects, Accessibility
   - Updated Package.swift with submodule structure
   - All tests passing
   
   Dependency chain verified:
   Foundation <- Core <- Infrastructure <- Domain <- Presentation
   
   Part of: restructure-for-xcode migration
   Phase: 05/06"
   ```

3. Push
   ```bash
   git push origin refactor/restructure-for-xcode
   ```

**Checklist:**
- [ ] Cambios agregados
- [ ] Commit realizado
- [ ] Push exitoso

---

## ARCHIVOS MIGRADOS EN ESTA FASE

**Completar durante ejecucion:**

| Origen | Destino | Archivos |
|--------|---------|----------|
| TIER-3-Presentation/Theme | DesignSystem/Theme | ___ |
| TIER-3-Presentation/Effects | DesignSystem/Effects | ___ |
| TIER-3-Presentation/Accessibility | DesignSystem/Accessibility | ___ |
| TIER-3-Presentation/UI | Components | ___ |
| TIER-3-Presentation/Navigation | Navigation | ___ |
| TIER-3-Presentation/Binding | Utilities | ___ |
| TIER-3-ViewModels/ViewModels | ViewModels | ___ |
| **TOTAL** | | ___ |

---

## RESUMEN DE EJECUCION

**Completar al finalizar la fase:**

```
Fecha inicio: _____
Fecha fin: _____
Ejecutor: _____
Duracion real: _____

Tareas completadas: ___/15
Archivos migrados: ___
Tests pasando: ___

Problemas encontrados:
- 

Soluciones aplicadas:
- 

Notas adicionales:
- 
```

---

## CRITERIOS DE SALIDA

Para considerar esta fase COMPLETADA:

- [ ] Theme migrado a DesignSystem/Theme
- [ ] Effects migrado a DesignSystem/Effects
- [ ] Accessibility migrado a DesignSystem/Accessibility
- [ ] UI Components migrado a Components
- [ ] Navigation migrado
- [ ] Binding migrado a Utilities
- [ ] ViewModels migrado
- [ ] Package.swift de Presentation actualizado
- [ ] Presentation compila sin errores
- [ ] Presentation tests pasan
- [ ] Build desde raiz de EduGoModules exitoso
- [ ] Cadena de dependencias verificada
- [ ] Xcode Previews funcionan (si aplica)
- [ ] Commit de fase realizado
- [ ] Push exitoso

---

## SIGUIENTE PASO

Una vez completada esta fase, actualizar el PLAN_MAESTRO.md con:
1. Marcar FASE 05 como COMPLETADA
2. Registrar fecha, ejecutor y duracion
3. Copiar el RESUMEN DE EJECUCION
4. Notar la consolidacion de TIER-3-Presentation y TIER-3-ViewModels

Luego proceder a: **[FASE-06-FEATURES-FINALIZACION.md](./FASE-06-FEATURES-FINALIZACION.md)**
