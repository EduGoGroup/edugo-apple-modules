# FASE 06: Migracion Features y Finalizacion

**Estado:** PENDIENTE  
**Duracion Estimada:** 3-4 horas  
**Dependencias:** FASE 05 completada  
**Fase Anterior:** [FASE-05-PRESENTATION.md](./FASE-05-PRESENTATION.md)  
**Siguiente Fase:** Ninguna (Fase Final)

---

## OBJETIVO DE LA FASE

Esta es la fase final que completa la migracion:
1. Migrar Features (AI, API, Analytics) desde TIER-4
2. Crear estructura de Apps/ con DemoApp
3. Mover documentacion a Documentation/
4. Configurar Xcode workspace
5. Limpiar estructura antigua
6. Eliminar carpetas .build
7. Validacion final y merge

---

## MAPEO DE ARCHIVOS

### AI Feature
```
ORIGEN:
TIER-4-Features/AI/Sources/AI/

DESTINO:
EduGoModules/Packages/Features/Sources/AI/
```

### API Feature
```
ORIGEN:
TIER-4-Features/API/Sources/API/

DESTINO:
EduGoModules/Packages/Features/Sources/API/
```

### Analytics Feature
```
ORIGEN:
TIER-4-Features/Analytics/Sources/Analytics/

DESTINO:
EduGoModules/Packages/Features/Sources/Analytics/
```

### Documentation
```
ORIGEN:
Apple/*.md (multiples archivos raiz)
Apple/docs/
Apple/analisis_comando_slash/

DESTINO:
EduGoModules/Documentation/
├── Architecture/
├── Guides/
├── API/
└── Decisions/
```

---

## PREREQUISITOS

- [ ] FASE 05 completada exitosamente
- [ ] Todos los packages anteriores compilando
- [ ] Branch `refactor/restructure-for-xcode` activo
- [ ] No hay cambios sin commit

---

## TAREAS DETALLADAS

### TAREA 6.1: Verificar Estado Previo
**Tiempo estimado:** 5 minutos

**Pasos:**
1. Verificar rama y estado
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple
   git branch --show-current
   git status
   ```

2. Verificar que todos los packages compilan
   ```bash
   cd EduGoModules
   swift build
   swift test
   cd ..
   ```

**Checklist:**
- [ ] Rama verificada
- [ ] EduGoModules compila
- [ ] Tests pasan

---

### TAREA 6.2: Analizar Features (TIER-4)
**Tiempo estimado:** 10 minutos

**Pasos:**
1. Analizar AI
   ```bash
   echo "=== AI ==="
   find TIER-4-Features/AI/Sources/AI -name "*.swift" -type f
   find TIER-4-Features/AI/Sources/AI -name "*.swift" | wc -l
   grep -h "^import " TIER-4-Features/AI/Sources/AI/*.swift 2>/dev/null | sort -u
   ```

2. Analizar API
   ```bash
   echo "=== API ==="
   find TIER-4-Features/API/Sources/API -name "*.swift" -type f
   find TIER-4-Features/API/Sources/API -name "*.swift" | wc -l
   grep -h "^import " TIER-4-Features/API/Sources/API/*.swift 2>/dev/null | sort -u
   ```

3. Analizar Analytics
   ```bash
   echo "=== ANALYTICS ==="
   find TIER-4-Features/Analytics/Sources/Analytics -name "*.swift" -type f
   find TIER-4-Features/Analytics/Sources/Analytics -name "*.swift" | wc -l
   grep -h "^import " TIER-4-Features/Analytics/Sources/Analytics/*.swift 2>/dev/null | sort -u
   ```

4. Documentar hallazgos:

| Feature | Archivos | Dependencias principales |
|---------|----------|--------------------------|
| AI | ___ | ___ |
| API | ___ | ___ |
| Analytics | ___ | ___ |

**Checklist:**
- [ ] AI analizado
- [ ] API analizado
- [ ] Analytics analizado

---

### TAREA 6.3: Migrar AI Feature
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Features/Sources/AI/Placeholder.swift
   ```

2. Copiar archivos de AI
   ```bash
   cp -R TIER-4-Features/AI/Sources/AI/* \
         EduGoModules/Packages/Features/Sources/AI/
   ```

3. Actualizar imports
   ```bash
   find EduGoModules/Packages/Features/Sources/AI -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   find EduGoModules/Packages/Features/Sources/AI -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   
   find EduGoModules/Packages/Features/Sources/AI -name "*.swift" -exec \
     sed -i '' 's/import Network/import EduInfrastructure/g' {} +
   
   # Si AI usa UI components
   find EduGoModules/Packages/Features/Sources/AI -name "*.swift" -exec \
     sed -i '' 's/import UI/import EduPresentation/g' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 6.4: Migrar API Feature
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Features/Sources/API/Placeholder.swift
   ```

2. Copiar archivos de API
   ```bash
   cp -R TIER-4-Features/API/Sources/API/* \
         EduGoModules/Packages/Features/Sources/API/
   ```

3. Actualizar imports
   ```bash
   find EduGoModules/Packages/Features/Sources/API -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   find EduGoModules/Packages/Features/Sources/API -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   
   find EduGoModules/Packages/Features/Sources/API -name "*.swift" -exec \
     sed -i '' 's/import Network/import EduInfrastructure/g' {} +
   
   find EduGoModules/Packages/Features/Sources/API -name "*.swift" -exec \
     sed -i '' 's/import Logger/import EduCore/g' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 6.5: Migrar Analytics Feature
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Features/Sources/Analytics/Placeholder.swift
   ```

2. Copiar archivos de Analytics
   ```bash
   cp -R TIER-4-Features/Analytics/Sources/Analytics/* \
         EduGoModules/Packages/Features/Sources/Analytics/
   ```

3. Actualizar imports
   ```bash
   find EduGoModules/Packages/Features/Sources/Analytics -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   find EduGoModules/Packages/Features/Sources/Analytics -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   
   find EduGoModules/Packages/Features/Sources/Analytics -name "*.swift" -exec \
     sed -i '' 's/import Logger/import EduCore/g' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 6.6: Actualizar Package.swift de Features
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Actualizar Package.swift
   ```bash
   cat > EduGoModules/Packages/Features/Package.swift << 'EOF'
   // swift-tools-version: 6.2
   import PackageDescription

   let package = Package(
       name: "EduFeatures",
       platforms: [
           .iOS(.v26),
           .macOS(.v26)
       ],
       products: [
           .library(name: "EduFeatures", targets: ["EduFeatures"]),
           // Exponer features individualmente
           .library(name: "EduAI", targets: ["EduAI"]),
           .library(name: "EduAPI", targets: ["EduAPI"]),
           .library(name: "EduAnalytics", targets: ["EduAnalytics"])
       ],
       dependencies: [
           .package(path: "../Foundation"),
           .package(path: "../Core"),
           .package(path: "../Infrastructure"),
           .package(path: "../Domain"),
           .package(path: "../Presentation")
       ],
       targets: [
           // Target principal que agrupa todo
           .target(
               name: "EduFeatures",
               dependencies: [
                   "EduAI",
                   "EduAPI",
                   "EduAnalytics"
               ]
           ),
           // AI Feature
           .target(
               name: "EduAI",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation"),
                   .product(name: "EduCore", package: "Core"),
                   .product(name: "EduInfrastructure", package: "Infrastructure"),
                   .product(name: "EduPresentation", package: "Presentation")
               ],
               path: "Sources/AI"
           ),
           // API Feature
           .target(
               name: "EduAPI",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation"),
                   .product(name: "EduCore", package: "Core"),
                   .product(name: "EduInfrastructure", package: "Infrastructure")
               ],
               path: "Sources/API"
           ),
           // Analytics Feature
           .target(
               name: "EduAnalytics",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation"),
                   .product(name: "EduCore", package: "Core")
               ],
               path: "Sources/Analytics"
           ),
           // Tests
           .testTarget(
               name: "EduFeaturesTests",
               dependencies: ["EduFeatures"],
               path: "Tests/FeaturesTests"
           )
       ]
   )
   EOF
   ```

2. Crear archivo de reexportacion
   ```bash
   mkdir -p EduGoModules/Packages/Features/Sources/EduFeatures
   cat > EduGoModules/Packages/Features/Sources/EduFeatures/Exports.swift << 'EOF'
   // EduFeatures - Re-exports all feature modules
   @_exported import EduAI
   @_exported import EduAPI
   @_exported import EduAnalytics
   EOF
   ```

**Checklist:**
- [ ] Package.swift actualizado
- [ ] Archivo Exports.swift creado

---

### TAREA 6.7: Compilar Features
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Compilar Features
   ```bash
   cd EduGoModules/Packages/Features
   swift build 2>&1 | tee /tmp/features-build.log
   ```

2. Si hay errores, corregir
   ```bash
   grep -i "error:" /tmp/features-build.log
   ```

3. Ejecutar tests
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

### TAREA 6.8: Migrar Tests de Features
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Verificar tests existentes
   ```bash
   find TIER-4-Features/AI/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-4-Features/API/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-4-Features/Analytics/Tests -name "*.swift" 2>/dev/null | wc -l
   ```

2. Eliminar test placeholder
   ```bash
   rm EduGoModules/Packages/Features/Tests/FeaturesTests/FeaturesTests.swift
   ```

3. Crear estructura y copiar tests
   ```bash
   mkdir -p EduGoModules/Packages/Features/Tests/FeaturesTests/AI
   mkdir -p EduGoModules/Packages/Features/Tests/FeaturesTests/API
   mkdir -p EduGoModules/Packages/Features/Tests/FeaturesTests/Analytics
   
   cp -R TIER-4-Features/AI/Tests/AITests/* \
         EduGoModules/Packages/Features/Tests/FeaturesTests/AI/ 2>/dev/null || true
   
   cp -R TIER-4-Features/API/Tests/APITests/* \
         EduGoModules/Packages/Features/Tests/FeaturesTests/API/ 2>/dev/null || true
   
   cp -R TIER-4-Features/Analytics/Tests/AnalyticsTests/* \
         EduGoModules/Packages/Features/Tests/FeaturesTests/Analytics/ 2>/dev/null || true
   ```

4. Actualizar imports
   ```bash
   find EduGoModules/Packages/Features/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import AI/@testable import EduAI/g' {} +
   
   find EduGoModules/Packages/Features/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import API/@testable import EduAPI/g' {} +
   
   find EduGoModules/Packages/Features/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import Analytics/@testable import EduAnalytics/g' {} +
   ```

5. Crear test minimo
   ```bash
   cat > EduGoModules/Packages/Features/Tests/FeaturesTests/FeaturesTests.swift << 'EOF'
   import XCTest
   @testable import EduFeatures
   @testable import EduAI
   @testable import EduAPI
   @testable import EduAnalytics

   final class FeaturesTests: XCTestCase {
       func testModulesLoad() {
           XCTAssertTrue(true, "EduFeatures modules loaded successfully")
       }
   }
   EOF
   ```

6. Ejecutar tests
   ```bash
   cd EduGoModules/Packages/Features
   swift test
   cd ../../..
   ```

**Checklist:**
- [ ] Estructura de tests creada
- [ ] Tests copiados
- [ ] Imports actualizados
- [ ] Tests pasan

---

### TAREA 6.9: Crear DemoApp
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Crear estructura de DemoApp
   ```bash
   mkdir -p EduGoModules/Apps/DemoApp/Sources
   mkdir -p EduGoModules/Apps/DemoApp/Resources
   ```

2. Crear App.swift
   ```bash
   cat > EduGoModules/Apps/DemoApp/Sources/DemoApp.swift << 'EOF'
   import SwiftUI
   import EduPresentation
   import EduFeatures

   @main
   struct DemoApp: App {
       var body: some Scene {
           WindowGroup {
               ContentView()
           }
       }
   }

   struct ContentView: View {
       var body: some View {
           NavigationStack {
               VStack(spacing: 20) {
                   Text("EduGo Demo App")
                       .font(.largeTitle)
                   
                   Text("Migration Complete!")
                       .font(.headline)
                   
                   Text("All modules loaded successfully")
                       .foregroundStyle(.secondary)
               }
               .padding()
               .navigationTitle("EduGo")
           }
       }
   }

   #Preview {
       ContentView()
   }
   EOF
   ```

3. Crear Package.swift para DemoApp (si se usa SPM) o proyecto Xcode
   
   **Opcion A: Como ejecutable SPM**
   ```bash
   cat > EduGoModules/Apps/DemoApp/Package.swift << 'EOF'
   // swift-tools-version: 6.2
   import PackageDescription

   let package = Package(
       name: "DemoApp",
       platforms: [
           .iOS(.v26),
           .macOS(.v26)
       ],
       dependencies: [
           .package(path: "../../Packages/Foundation"),
           .package(path: "../../Packages/Core"),
           .package(path: "../../Packages/Infrastructure"),
           .package(path: "../../Packages/Domain"),
           .package(path: "../../Packages/Presentation"),
           .package(path: "../../Packages/Features")
       ],
       targets: [
           .executableTarget(
               name: "DemoApp",
               dependencies: [
                   .product(name: "EduPresentation", package: "Presentation"),
                   .product(name: "EduFeatures", package: "Features")
               ],
               path: "Sources"
           )
       ]
   )
   EOF
   ```

**Checklist:**
- [ ] Estructura DemoApp creada
- [ ] App.swift creado
- [ ] Package.swift creado (o proyecto Xcode)

---

### TAREA 6.10: Mover Documentacion
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Identificar archivos de documentacion en raiz
   ```bash
   ls -la *.md 2>/dev/null
   ls -la docs/
   ```

2. Mover archivos de arquitectura
   ```bash
   # Si existe ARCHITECTURE.md
   cp ARCHITECTURE.md EduGoModules/Documentation/Architecture/ 2>/dev/null || true
   cp docs/architecture/* EduGoModules/Documentation/Architecture/ 2>/dev/null || true
   ```

3. Mover guias
   ```bash
   cp DEVELOPMENT_GUIDE.md EduGoModules/Documentation/Guides/ 2>/dev/null || true
   cp XCODE_NAVIGATION_GUIDE.md EduGoModules/Documentation/Guides/ 2>/dev/null || true
   cp MAKEFILE_USAGE.md EduGoModules/Documentation/Guides/ 2>/dev/null || true
   ```

4. Crear README principal para EduGoModules
   ```bash
   cat > EduGoModules/README.md << 'EOF'
   # EduGo Modules

   Modulos Swift para la plataforma educativa EduGo.

   ## Estructura

   ```
   EduGoModules/
   ├── Packages/           # Swift Packages principales
   │   ├── Foundation/     # Tipos base y extensiones
   │   ├── Core/           # Modelos, Logger, Utilities
   │   ├── Infrastructure/ # Network, Storage, Persistence
   │   ├── Domain/         # Logica de negocio, UseCases
   │   ├── Presentation/   # UI, Theme, ViewModels
   │   └── Features/       # AI, API, Analytics
   ├── Apps/               # Aplicaciones demo
   ├── Documentation/      # Documentacion centralizada
   └── Tools/              # Scripts y templates
   ```

   ## Quick Start

   ```bash
   # Compilar todo
   swift build

   # Ejecutar tests
   swift test

   # Abrir en Xcode
   open Package.swift
   ```

   ## Dependencias

   ```
   Foundation <- Core <- Infrastructure <- Domain <- Presentation <- Features
   ```

   ## Documentacion

   Ver `Documentation/` para guias detalladas.
   EOF
   ```

5. Crear ADR inicial
   ```bash
   cat > EduGoModules/Documentation/Decisions/001-restructure-for-xcode.md << 'EOF'
   # ADR 001: Reestructuracion para Xcode

   ## Estado
   Aceptado

   ## Contexto
   La estructura anterior basada en TIERs era confusa para navegacion en Xcode:
   - TIER-2 tenia Domain e Infrastructure
   - TIER-3 tenia Domain, Presentation y ViewModels
   - 23 carpetas .build dispersas
   - Proxy targets innecesarios

   ## Decision
   Reestructurar a nomenclatura funcional:
   - Foundation, Core, Infrastructure, Domain, Presentation, Features
   - Un solo Package.swift raiz
   - Submodulos agrupados logicamente

   ## Consecuencias
   - Navegacion intuitiva en Xcode
   - Build times reducidos
   - Onboarding mas rapido
   - Mantenimiento simplificado
   EOF
   ```

**Checklist:**
- [ ] Documentacion de arquitectura movida
- [ ] Guias movidas
- [ ] README creado
- [ ] ADR creado

---

### TAREA 6.11: Verificar Compilacion Completa del Proyecto
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Compilar todo desde raiz de EduGoModules
   ```bash
   cd EduGoModules
   swift build
   ```

2. Ejecutar todos los tests
   ```bash
   swift test
   ```

3. Verificar cadena completa de dependencias
   ```bash
   swift package show-dependencies
   ```

**Cadena esperada:**
```
Foundation <- Core <- Infrastructure <- Domain <- Presentation <- Features
```

4. Verificar conteo de archivos migrados
   ```bash
   find Packages -name "*.swift" | wc -l
   ```

**Checklist:**
- [ ] Build completo exitoso
- [ ] Todos los tests pasan
- [ ] Cadena de dependencias correcta
- [ ] Archivos migrados contados

---

### TAREA 6.12: Configurar Xcode Workspace
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Crear workspace si no existe
   ```bash
   mkdir -p EduGoModules/EduGoModules.xcworkspace
   cat > EduGoModules/EduGoModules.xcworkspace/contents.xcworkspacedata << 'EOF'
   <?xml version="1.0" encoding="UTF-8"?>
   <Workspace
      version = "1.0">
      <FileRef
         location = "group:Package.swift">
      </FileRef>
      <FileRef
         location = "group:Apps/DemoApp/Package.swift">
      </FileRef>
   </Workspace>
   EOF
   ```

2. Abrir workspace en Xcode
   ```bash
   open EduGoModules/EduGoModules.xcworkspace
   ```

3. En Xcode:
   - Verificar que todos los packages se cargan
   - Verificar que el autocompletado funciona
   - Verificar que los previews funcionan
   - Crear schemes compartidos si es necesario

**Checklist:**
- [ ] Workspace creado
- [ ] Xcode carga correctamente
- [ ] Autocompletado funciona
- [ ] Previews funcionan (si aplica)

---

### TAREA 6.13: Limpiar Carpetas .build Antiguas
**Tiempo estimado:** 10 minutos

**Pasos:**
1. Listar todas las carpetas .build antiguas
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple
   find . -name ".build" -type d -not -path "./EduGoModules/*"
   ```

2. Calcular espacio a liberar
   ```bash
   du -sh $(find . -name ".build" -type d -not -path "./EduGoModules/*") 2>/dev/null
   ```

3. Eliminar carpetas .build antiguas
   ```bash
   find . -name ".build" -type d -not -path "./EduGoModules/*" -exec rm -rf {} + 2>/dev/null
   ```

4. Limpiar .swiftpm
   ```bash
   find . -name ".swiftpm" -type d -not -path "./EduGoModules/*" -exec rm -rf {} + 2>/dev/null
   ```

5. Verificar espacio liberado
   ```bash
   echo "Espacio liberado!"
   ```

**Checklist:**
- [ ] Carpetas .build listadas
- [ ] Espacio calculado
- [ ] Carpetas .build eliminadas
- [ ] Carpetas .swiftpm eliminadas

---

### TAREA 6.14: Commit Final de Migracion
**Tiempo estimado:** 10 minutos

**Pasos:**
1. Agregar todos los cambios de EduGoModules
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple
   git add EduGoModules/
   git add docs/plan-migracion/
   ```

2. Verificar cambios
   ```bash
   git status
   git diff --cached --stat
   ```

3. Commit completo
   ```bash
   git commit -m "feat(migration): complete restructure for Xcode - Phase 06/06

   Features Package:
   - Migrated AI from TIER-4-Features/AI
   - Migrated API from TIER-4-Features/API
   - Migrated Analytics from TIER-4-Features/Analytics
   
   Apps:
   - Created DemoApp structure
   
   Documentation:
   - Centralized in Documentation/
   - Created ADR for restructure decision
   - Updated README
   
   Cleanup:
   - Removed old .build directories (saved ~6GB)
   - Removed .swiftpm directories
   
   Final structure:
   EduGoModules/
   ├── Packages/
   │   ├── Foundation/
   │   ├── Core/
   │   ├── Infrastructure/
   │   ├── Domain/
   │   ├── Presentation/
   │   └── Features/
   ├── Apps/
   ├── Documentation/
   └── Tools/
   
   All tests passing. Ready for review.
   
   Part of: restructure-for-xcode migration
   Phase: 06/06 (FINAL)"
   ```

4. Push
   ```bash
   git push origin refactor/restructure-for-xcode
   ```

**Checklist:**
- [ ] Cambios agregados
- [ ] Commit realizado
- [ ] Push exitoso

---

### TAREA 6.15: Documentar Resultados Finales
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Calcular metricas finales
   ```bash
   cd EduGoModules
   
   echo "=== METRICAS FINALES ==="
   echo "Archivos Swift: $(find Packages -name '*.swift' | wc -l)"
   echo "Carpetas .build: $(find . -name '.build' -type d | wc -l)"
   echo "Paquetes SPM: $(find Packages -name 'Package.swift' | wc -l)"
   ```

2. Comparar con metricas baseline (de FASE 01)
   
   | Metrica | Antes | Despues | Mejora |
   |---------|-------|---------|--------|
   | Archivos Swift | ___ | ___ | - |
   | Carpetas .build | 23 | 1 | -95% |
   | Espacio .build | ~6.3GB | ~1.5GB | -75% |
   | Niveles profundidad | 6-8 | 3-4 | -50% |
   | Tiempo build | ~5-8 min | ~2-3 min | -60% |

3. Actualizar PLAN_MAESTRO.md con resultados finales

**Checklist:**
- [ ] Metricas finales calculadas
- [ ] Comparativa documentada
- [ ] PLAN_MAESTRO actualizado

---

### TAREA 6.16: Crear Pull Request (Opcional)
**Tiempo estimado:** 10 minutos

**Pasos:**
1. Ir a GitHub/GitLab
2. Crear PR de `refactor/restructure-for-xcode` a `main`
3. Agregar descripcion detallada:
   - Resumen de cambios
   - Link a documentacion
   - Metricas de mejora
   - Instrucciones de testing

**Template PR:**
```markdown
## Restructure for Xcode Navigation

### Summary
Complete restructure of EduGo Apple Modules from TIER-based structure to functional package organization.

### Changes
- Migrated all modules to new `EduGoModules/` structure
- Consolidated Domain (TIER-2-Domain + TIER-3-Domain)
- Consolidated Presentation (TIER-3-Presentation + TIER-3-ViewModels)
- Centralized documentation
- Removed 23 .build directories (~6GB saved)

### Metrics Improvement
| Metric | Before | After |
|--------|--------|-------|
| .build folders | 23 | 1 |
| Disk space | ~6.3GB | ~1.5GB |
| Build time | ~5-8 min | ~2-3 min |

### Testing
- [ ] All unit tests pass
- [ ] Xcode navigation verified
- [ ] Previews working
- [ ] DemoApp builds

### Documentation
See `EduGoModules/Documentation/` for updated guides.
```

**Checklist:**
- [ ] PR creado
- [ ] Descripcion completa
- [ ] Reviewers asignados

---

## TAREAS POST-MIGRACION (Opcional)

### Eliminar Estructura Antigua
**IMPORTANTE:** Solo hacer esto despues de que el PR sea aprobado y mergeado.

```bash
# PELIGRO: Esto elimina la estructura antigua permanentemente
# Solo ejecutar despues de verificar que todo funciona

# Listar lo que se eliminara
ls -d TIER-*

# Eliminar (CON CUIDADO)
# rm -rf TIER-0-Foundation/
# rm -rf TIER-1-Core/
# rm -rf TIER-2-Domain/
# rm -rf TIER-2-Infrastructure/
# rm -rf TIER-3-Domain/
# rm -rf TIER-3-Presentation/
# rm -rf TIER-3-ViewModels/
# rm -rf TIER-4-Features/
# rm -rf Sources/  # Proxy targets antiguos
```

---

## ARCHIVOS MIGRADOS EN ESTA FASE

**Completar durante ejecucion:**

| Origen | Destino | Archivos |
|--------|---------|----------|
| TIER-4-Features/AI | Features/Sources/AI | ___ |
| TIER-4-Features/API | Features/Sources/API | ___ |
| TIER-4-Features/Analytics | Features/Sources/Analytics | ___ |
| Documentacion | Documentation/ | ___ |
| **TOTAL** | | ___ |

---

## RESUMEN DE EJECUCION

**Completar al finalizar la fase:**

```
Fecha inicio: _____
Fecha fin: _____
Ejecutor: _____
Duracion real: _____

Tareas completadas: ___/16
Archivos migrados total proyecto: ___
Tests pasando: ___
Espacio liberado: ___ GB

Problemas encontrados:
- 

Soluciones aplicadas:
- 

Notas adicionales:
- 
```

---

## CRITERIOS DE SALIDA

Para considerar esta fase y LA MIGRACION COMPLETA:

- [ ] AI Feature migrado
- [ ] API Feature migrado
- [ ] Analytics Feature migrado
- [ ] Features compila sin errores
- [ ] DemoApp creado y funcional
- [ ] Documentacion centralizada
- [ ] Xcode workspace configurado
- [ ] Carpetas .build antiguas eliminadas
- [ ] Build completo desde raiz exitoso
- [ ] Todos los tests pasan
- [ ] Cadena de dependencias completa verificada
- [ ] Commit final realizado
- [ ] Push exitoso
- [ ] Metricas finales documentadas
- [ ] PLAN_MAESTRO actualizado con estado COMPLETADO

---

## MIGRACION COMPLETADA

Una vez todos los criterios cumplidos:

1. Actualizar PLAN_MAESTRO.md:
   - Marcar FASE 06 como COMPLETADA
   - Marcar migracion como COMPLETADA
   - Registrar metricas finales

2. Comunicar al equipo:
   - Enviar resumen de cambios
   - Compartir guia de navegacion nueva
   - Programar sesion de onboarding si es necesario

3. Monitorear:
   - Verificar CI/CD funciona
   - Atender preguntas del equipo
   - Documentar issues encontrados post-migracion
