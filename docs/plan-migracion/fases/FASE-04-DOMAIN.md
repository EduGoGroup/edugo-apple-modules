# FASE 04: Migracion Domain

**Estado:** PENDIENTE  
**Duracion Estimada:** 3-4 horas  
**Dependencias:** FASE 03 completada  
**Fase Anterior:** [FASE-03-INFRASTRUCTURE.md](./FASE-03-INFRASTRUCTURE.md)  
**Siguiente Fase:** [FASE-05-PRESENTATION.md](./FASE-05-PRESENTATION.md)

---

## OBJETIVO DE LA FASE

Consolidar toda la logica de negocio en un unico paquete Domain. Esta fase es critica porque unifica codigo que actualmente esta disperso en:
- TIER-2-Domain (CQRS, StateManagement, UseCases)
- TIER-3-Domain (Auth, Roles)

Esta consolidacion resuelve el problema de tener "Domain" en dos niveles diferentes.

---

## MAPEO DE ARCHIVOS

### CQRS (TIER-2-Domain -> Domain)
```
ORIGEN:
TIER-2-Domain/CQRS/Sources/CQRS/

DESTINO:
EduGoModules/Packages/Domain/Sources/CQRS/
```

### StateManagement (TIER-2-Domain -> Domain)
```
ORIGEN:
TIER-2-Domain/StateManagement/Sources/StateManagement/

DESTINO:
EduGoModules/Packages/Domain/Sources/StateManagement/
```

### UseCases (TIER-2-Domain -> Domain)
```
ORIGEN:
TIER-2-Domain/UseCases/Sources/UseCases/

DESTINO:
EduGoModules/Packages/Domain/Sources/UseCases/
```

### Auth (TIER-3-Domain -> Domain/Services)
```
ORIGEN:
TIER-3-Domain/Auth/Sources/Auth/

DESTINO:
EduGoModules/Packages/Domain/Sources/Services/Auth/
```

### Roles (TIER-3-Domain -> Domain/Services)
```
ORIGEN:
TIER-3-Domain/Roles/Sources/Roles/

DESTINO:
EduGoModules/Packages/Domain/Sources/Services/Roles/
```

---

## PREREQUISITOS

- [ ] FASE 03 completada exitosamente
- [ ] Foundation, Core e Infrastructure compilando
- [ ] Branch `refactor/restructure-for-xcode` activo
- [ ] No hay cambios sin commit

---

## TAREAS DETALLADAS

### TAREA 4.1: Verificar Estado Previo
**Tiempo estimado:** 5 minutos

**Pasos:**
1. Verificar rama y estado
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple
   git branch --show-current
   git status
   ```

2. Verificar que packages anteriores compilan
   ```bash
   cd EduGoModules
   swift build
   cd ..
   ```

3. Verificar estructura de Domain
   ```bash
   ls -la EduGoModules/Packages/Domain/Sources/
   # Debe mostrar: Services/, UseCases/, StateManagement/, CQRS/
   ```

**Criterio de exito:**
- Packages anteriores compilando
- Estructura de Domain verificada

**Checklist:**
- [ ] Rama verificada
- [ ] EduGoModules compila
- [ ] Estructura Domain verificada

---

### TAREA 4.2: Analizar Contenido de TIER-2-Domain
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Analizar CQRS
   ```bash
   echo "=== CQRS ==="
   find TIER-2-Domain/CQRS/Sources/CQRS -name "*.swift" -type f
   find TIER-2-Domain/CQRS/Sources/CQRS -name "*.swift" | wc -l
   find TIER-2-Domain/CQRS/Sources/CQRS -type d
   grep -h "^import " TIER-2-Domain/CQRS/Sources/CQRS/*.swift 2>/dev/null | sort -u
   ```

2. Analizar StateManagement
   ```bash
   echo "=== STATE MANAGEMENT ==="
   find TIER-2-Domain/StateManagement/Sources/StateManagement -name "*.swift" -type f
   find TIER-2-Domain/StateManagement/Sources/StateManagement -name "*.swift" | wc -l
   find TIER-2-Domain/StateManagement/Sources/StateManagement -type d
   grep -h "^import " TIER-2-Domain/StateManagement/Sources/StateManagement/*.swift 2>/dev/null | sort -u
   ```

3. Analizar UseCases
   ```bash
   echo "=== USE CASES ==="
   find TIER-2-Domain/UseCases/Sources/UseCases -name "*.swift" -type f
   find TIER-2-Domain/UseCases/Sources/UseCases -name "*.swift" | wc -l
   find TIER-2-Domain/UseCases/Sources/UseCases -type d
   grep -h "^import " TIER-2-Domain/UseCases/Sources/UseCases/*.swift 2>/dev/null | sort -u
   ```

4. Documentar hallazgos TIER-2-Domain:

**CQRS:**
- Archivos: _____
- Subcarpetas: _____
- Dependencias: _____

**StateManagement:**
- Archivos: _____
- Subcarpetas: _____
- Dependencias: _____

**UseCases:**
- Archivos: _____
- Subcarpetas: _____
- Dependencias: _____

**Checklist:**
- [ ] CQRS analizado
- [ ] StateManagement analizado
- [ ] UseCases analizado

---

### TAREA 4.3: Analizar Contenido de TIER-3-Domain
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Analizar Auth
   ```bash
   echo "=== AUTH ==="
   find TIER-3-Domain/Auth/Sources/Auth -name "*.swift" -type f
   find TIER-3-Domain/Auth/Sources/Auth -name "*.swift" | wc -l
   find TIER-3-Domain/Auth/Sources/Auth -type d
   grep -h "^import " TIER-3-Domain/Auth/Sources/Auth/*.swift 2>/dev/null | sort -u
   ```

2. Analizar Roles
   ```bash
   echo "=== ROLES ==="
   find TIER-3-Domain/Roles/Sources/Roles -name "*.swift" -type f
   find TIER-3-Domain/Roles/Sources/Roles -name "*.swift" | wc -l
   find TIER-3-Domain/Roles/Sources/Roles -type d
   grep -h "^import " TIER-3-Domain/Roles/Sources/Roles/*.swift 2>/dev/null | sort -u
   ```

3. Documentar hallazgos TIER-3-Domain:

**Auth:**
- Archivos: _____
- Subcarpetas: _____
- Dependencias: _____
- **ATENCION:** Auth probablemente depende de Network y Storage

**Roles:**
- Archivos: _____
- Subcarpetas: _____
- Dependencias: _____

**Checklist:**
- [ ] Auth analizado
- [ ] Roles analizado
- [ ] Dependencias criticas identificadas

---

### TAREA 4.4: Migrar CQRS
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Domain/Sources/CQRS/Placeholder.swift
   ```

2. Copiar archivos de CQRS
   ```bash
   cp -R TIER-2-Domain/CQRS/Sources/CQRS/* \
         EduGoModules/Packages/Domain/Sources/CQRS/
   ```

3. Verificar copia
   ```bash
   ls -la EduGoModules/Packages/Domain/Sources/CQRS/
   ```

4. Actualizar imports
   ```bash
   find EduGoModules/Packages/Domain/Sources/CQRS -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   find EduGoModules/Packages/Domain/Sources/CQRS -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 4.5: Migrar StateManagement
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Domain/Sources/StateManagement/Placeholder.swift
   ```

2. Copiar archivos
   ```bash
   cp -R TIER-2-Domain/StateManagement/Sources/StateManagement/* \
         EduGoModules/Packages/Domain/Sources/StateManagement/
   ```

3. Actualizar imports
   ```bash
   find EduGoModules/Packages/Domain/Sources/StateManagement -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 4.6: Migrar UseCases
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Domain/Sources/UseCases/Placeholder.swift
   ```

2. Copiar archivos
   ```bash
   cp -R TIER-2-Domain/UseCases/Sources/UseCases/* \
         EduGoModules/Packages/Domain/Sources/UseCases/
   ```

3. Actualizar imports
   ```bash
   find EduGoModules/Packages/Domain/Sources/UseCases -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   find EduGoModules/Packages/Domain/Sources/UseCases -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 4.7: Migrar Auth Service
**Tiempo estimado:** 20 minutos

**ATENCION:** Auth es un servicio de dominio que probablemente usa Network y Storage.
Esto es correcto en Clean Architecture (Domain puede usar Infrastructure a traves de protocolos).

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Domain/Sources/Services/Auth/Placeholder.swift
   ```

2. Copiar archivos de Auth
   ```bash
   cp -R TIER-3-Domain/Auth/Sources/Auth/* \
         EduGoModules/Packages/Domain/Sources/Services/Auth/
   ```

3. Verificar estructura
   ```bash
   ls -la EduGoModules/Packages/Domain/Sources/Services/Auth/
   find EduGoModules/Packages/Domain/Sources/Services/Auth -type d
   ```

4. Actualizar imports
   ```bash
   find EduGoModules/Packages/Domain/Sources/Services/Auth -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   find EduGoModules/Packages/Domain/Sources/Services/Auth -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   
   find EduGoModules/Packages/Domain/Sources/Services/Auth -name "*.swift" -exec \
     sed -i '' 's/import Logger/import EduCore/g' {} +
   
   find EduGoModules/Packages/Domain/Sources/Services/Auth -name "*.swift" -exec \
     sed -i '' 's/import Network/import EduInfrastructure/g' {} +
   
   find EduGoModules/Packages/Domain/Sources/Services/Auth -name "*.swift" -exec \
     sed -i '' 's/import Storage/import EduInfrastructure/g' {} +
   ```

5. Verificar imports resultantes
   ```bash
   grep -h "^import " EduGoModules/Packages/Domain/Sources/Services/Auth/*.swift | sort -u
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Estructura verificada
- [ ] Imports actualizados

---

### TAREA 4.8: Migrar Roles Service
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Domain/Sources/Services/Roles/Placeholder.swift
   ```

2. Copiar archivos de Roles
   ```bash
   cp -R TIER-3-Domain/Roles/Sources/Roles/* \
         EduGoModules/Packages/Domain/Sources/Services/Roles/
   ```

3. Actualizar imports
   ```bash
   find EduGoModules/Packages/Domain/Sources/Services/Roles -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   find EduGoModules/Packages/Domain/Sources/Services/Roles -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   
   find EduGoModules/Packages/Domain/Sources/Services/Roles -name "*.swift" -exec \
     sed -i '' 's/import Logger/import EduCore/g' {} +
   ```

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 4.9: Actualizar Package.swift de Domain
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Actualizar Package.swift con estructura completa
   ```bash
   cat > EduGoModules/Packages/Domain/Package.swift << 'EOF'
   // swift-tools-version: 6.2
   import PackageDescription

   let package = Package(
       name: "EduDomain",
       platforms: [
           .iOS(.v26),
           .macOS(.v26)
       ],
       products: [
           .library(name: "EduDomain", targets: ["EduDomain"]),
           // Exponer submodulos individualmente
           .library(name: "EduCQRS", targets: ["EduCQRS"]),
           .library(name: "EduStateManagement", targets: ["EduStateManagement"]),
           .library(name: "EduUseCases", targets: ["EduUseCases"]),
           .library(name: "EduAuthService", targets: ["EduAuthService"]),
           .library(name: "EduRolesService", targets: ["EduRolesService"])
       ],
       dependencies: [
           .package(path: "../Foundation"),
           .package(path: "../Core"),
           .package(path: "../Infrastructure")
       ],
       targets: [
           // Target principal que agrupa todo
           .target(
               name: "EduDomain",
               dependencies: [
                   "EduCQRS",
                   "EduStateManagement",
                   "EduUseCases",
                   "EduAuthService",
                   "EduRolesService"
               ]
           ),
           // CQRS - Comandos y Queries
           .target(
               name: "EduCQRS",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation"),
                   .product(name: "EduCore", package: "Core")
               ],
               path: "Sources/CQRS"
           ),
           // State Management - Estado global
           .target(
               name: "EduStateManagement",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation")
               ],
               path: "Sources/StateManagement"
           ),
           // Use Cases - Casos de uso
           .target(
               name: "EduUseCases",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation"),
                   .product(name: "EduCore", package: "Core")
               ],
               path: "Sources/UseCases"
           ),
           // Auth Service - Autenticacion
           .target(
               name: "EduAuthService",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation"),
                   .product(name: "EduCore", package: "Core"),
                   .product(name: "EduInfrastructure", package: "Infrastructure")
               ],
               path: "Sources/Services/Auth"
           ),
           // Roles Service - Permisos y roles
           .target(
               name: "EduRolesService",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation"),
                   .product(name: "EduCore", package: "Core")
               ],
               path: "Sources/Services/Roles"
           ),
           // Tests
           .testTarget(
               name: "EduDomainTests",
               dependencies: ["EduDomain"],
               path: "Tests/DomainTests"
           )
       ]
   )
   EOF
   ```

2. Crear archivo de reexportacion
   ```bash
   mkdir -p EduGoModules/Packages/Domain/Sources/EduDomain
   cat > EduGoModules/Packages/Domain/Sources/EduDomain/Exports.swift << 'EOF'
   // EduDomain - Re-exports all submodules
   @_exported import EduCQRS
   @_exported import EduStateManagement
   @_exported import EduUseCases
   @_exported import EduAuthService
   @_exported import EduRolesService
   EOF
   ```

**Checklist:**
- [ ] Package.swift actualizado
- [ ] Archivo Exports.swift creado

---

### TAREA 4.10: Compilar Domain
**Tiempo estimado:** 25 minutos

**Pasos:**
1. Compilar Domain
   ```bash
   cd EduGoModules/Packages/Domain
   swift build 2>&1 | tee /tmp/domain-build.log
   ```

2. Si hay errores, analizar
   ```bash
   grep -i "error:" /tmp/domain-build.log
   ```

3. Errores comunes y soluciones:

   **Error: Dependencias entre submodulos de Domain**
   
   Si UseCases necesita CQRS:
   ```swift
   // En Package.swift, agregar dependencia:
   .target(
       name: "EduUseCases",
       dependencies: [
           .product(name: "EduFoundation", package: "Foundation"),
           .product(name: "EduCore", package: "Core"),
           "EduCQRS"  // <-- Agregar dependencia interna
       ],
       path: "Sources/UseCases"
   ),
   ```

   **Error: Auth necesita tipos especificos de Network**
   
   Si Auth usa tipos como `HTTPClient` directamente:
   ```bash
   # Verificar que EduInfrastructure expone lo necesario
   grep -r "HTTPClient" EduGoModules/Packages/Domain/Sources/Services/Auth/
   # Si hay referencias, asegurar que estan exportados en EduInfrastructure
   ```

   **Error: Referencias a modulos antiguos**
   ```bash
   # Buscar referencias a nombres antiguos
   grep -r "TIER-2-Domain\|TIER-3-Domain" EduGoModules/Packages/Domain/
   grep -r "import Auth\|import Roles\|import CQRS\|import StateManagement\|import UseCases" \
     EduGoModules/Packages/Domain/Sources/
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

### TAREA 4.11: Migrar Tests de Domain
**Tiempo estimado:** 25 minutos

**Pasos:**
1. Verificar tests existentes
   ```bash
   find TIER-2-Domain/CQRS/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-2-Domain/StateManagement/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-2-Domain/UseCases/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-3-Domain/Auth/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-3-Domain/Roles/Tests -name "*.swift" 2>/dev/null | wc -l
   ```

2. Eliminar test placeholder
   ```bash
   rm EduGoModules/Packages/Domain/Tests/DomainTests/DomainTests.swift
   ```

3. Crear estructura de tests
   ```bash
   mkdir -p EduGoModules/Packages/Domain/Tests/DomainTests/CQRS
   mkdir -p EduGoModules/Packages/Domain/Tests/DomainTests/StateManagement
   mkdir -p EduGoModules/Packages/Domain/Tests/DomainTests/UseCases
   mkdir -p EduGoModules/Packages/Domain/Tests/DomainTests/Services/Auth
   mkdir -p EduGoModules/Packages/Domain/Tests/DomainTests/Services/Roles
   ```

4. Copiar tests
   ```bash
   # CQRS tests
   cp -R TIER-2-Domain/CQRS/Tests/CQRSTests/* \
         EduGoModules/Packages/Domain/Tests/DomainTests/CQRS/ 2>/dev/null || echo "No CQRS tests"
   
   # StateManagement tests
   cp -R TIER-2-Domain/StateManagement/Tests/StateManagementTests/* \
         EduGoModules/Packages/Domain/Tests/DomainTests/StateManagement/ 2>/dev/null || echo "No StateManagement tests"
   
   # UseCases tests
   cp -R TIER-2-Domain/UseCases/Tests/UseCasesTests/* \
         EduGoModules/Packages/Domain/Tests/DomainTests/UseCases/ 2>/dev/null || echo "No UseCases tests"
   
   # Auth tests
   cp -R TIER-3-Domain/Auth/Tests/AuthTests/* \
         EduGoModules/Packages/Domain/Tests/DomainTests/Services/Auth/ 2>/dev/null || echo "No Auth tests"
   
   # Roles tests
   cp -R TIER-3-Domain/Roles/Tests/RolesTests/* \
         EduGoModules/Packages/Domain/Tests/DomainTests/Services/Roles/ 2>/dev/null || echo "No Roles tests"
   ```

5. Actualizar imports en tests
   ```bash
   find EduGoModules/Packages/Domain/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import CQRS/@testable import EduCQRS/g' {} +
   
   find EduGoModules/Packages/Domain/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import StateManagement/@testable import EduStateManagement/g' {} +
   
   find EduGoModules/Packages/Domain/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import UseCases/@testable import EduUseCases/g' {} +
   
   find EduGoModules/Packages/Domain/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import Auth/@testable import EduAuthService/g' {} +
   
   find EduGoModules/Packages/Domain/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import Roles/@testable import EduRolesService/g' {} +
   
   find EduGoModules/Packages/Domain/Tests -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   find EduGoModules/Packages/Domain/Tests -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   ```

6. Si no hay tests, crear test minimo
   ```bash
   cat > EduGoModules/Packages/Domain/Tests/DomainTests/DomainTests.swift << 'EOF'
   import XCTest
   @testable import EduDomain
   @testable import EduCQRS
   @testable import EduStateManagement
   @testable import EduUseCases
   @testable import EduAuthService
   @testable import EduRolesService

   final class DomainTests: XCTestCase {
       func testModulesLoad() {
           XCTAssertTrue(true, "EduDomain modules loaded successfully")
       }
   }
   EOF
   ```

7. Ejecutar tests
   ```bash
   cd EduGoModules/Packages/Domain
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

### TAREA 4.12: Verificar Compilacion Completa
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
Foundation <- Core <- Infrastructure <- Domain
```

**Checklist:**
- [ ] Build desde raiz exitoso
- [ ] Tests desde raiz exitosos
- [ ] Cadena de dependencias correcta

---

### TAREA 4.13: Commit de Fase 04
**Tiempo estimado:** 5 minutos

**Pasos:**
1. Agregar cambios
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple
   git add EduGoModules/
   ```

2. Commit
   ```bash
   git commit -m "feat(migration): migrate Domain package - unify domain logic

   Domain (consolidated from TIER-2-Domain and TIER-3-Domain):
   - Migrated CQRS (Commands/Queries) from TIER-2-Domain/CQRS
   - Migrated StateManagement from TIER-2-Domain/StateManagement
   - Migrated UseCases from TIER-2-Domain/UseCases
   - Migrated Auth Service from TIER-3-Domain/Auth
   - Migrated Roles Service from TIER-3-Domain/Roles
   
   Key improvements:
   - Unified all domain logic in single package
   - Resolved TIER-2/TIER-3 domain confusion
   - Updated Package.swift with submodule structure
   - All imports updated to use Edu* naming
   - All tests passing
   
   Dependency chain verified:
   Foundation <- Core <- Infrastructure <- Domain
   
   Part of: restructure-for-xcode migration
   Phase: 04/06"
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

## RESOLUCION DE PROBLEMAS COMUNES

### Problema: Auth depende de tipos no disponibles
**Causa:** Auth usaba tipos de modulos que aun no estan migrados (ej: ViewModels)
**Solucion:**
1. Verificar que Auth solo dependa de Foundation, Core e Infrastructure
2. Si depende de Presentation, hay un problema de arquitectura que debe resolverse
3. Usar protocolos para romper dependencias incorrectas

### Problema: Referencias circulares entre CQRS, StateManagement y UseCases
**Solucion:**
1. Identificar codigo compartido
2. Extraer protocolos comunes a un target DomainProtocols
3. O mover codigo compartido a Core

### Problema: StateManagement necesita tipos de UI (SwiftUI.Binding, etc)
**Causa:** StateManagement esta acoplado a la capa de presentacion
**Solucion:**
1. Si StateManagement es para estado de UI, moverlo a Presentation
2. Si es estado de dominio, eliminar dependencias de SwiftUI
3. Crear wrappers que no dependan de SwiftUI

---

## ARCHIVOS MIGRADOS EN ESTA FASE

**Completar durante ejecucion:**

| Origen | Destino | Archivos |
|--------|---------|----------|
| TIER-2-Domain/CQRS | Domain/Sources/CQRS | ___ |
| TIER-2-Domain/StateManagement | Domain/Sources/StateManagement | ___ |
| TIER-2-Domain/UseCases | Domain/Sources/UseCases | ___ |
| TIER-3-Domain/Auth | Domain/Sources/Services/Auth | ___ |
| TIER-3-Domain/Roles | Domain/Sources/Services/Roles | ___ |
| **TOTAL** | | ___ |

---

## RESUMEN DE EJECUCION

**Completar al finalizar la fase:**

```
Fecha inicio: _____
Fecha fin: _____
Ejecutor: _____
Duracion real: _____

Tareas completadas: ___/13
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

- [ ] CQRS migrado completamente
- [ ] StateManagement migrado completamente
- [ ] UseCases migrado completamente
- [ ] Auth Service migrado completamente
- [ ] Roles Service migrado completamente
- [ ] Package.swift de Domain actualizado con todos los submodulos
- [ ] Domain compila sin errores
- [ ] Domain tests pasan
- [ ] Build desde raiz de EduGoModules exitoso
- [ ] Cadena de dependencias verificada
- [ ] Commit de fase realizado
- [ ] Push exitoso

---

## SIGUIENTE PASO

Una vez completada esta fase, actualizar el PLAN_MAESTRO.md con:
1. Marcar FASE 04 como COMPLETADA
2. Registrar fecha, ejecutor y duracion
3. Copiar el RESUMEN DE EJECUCION
4. Notar la unificacion de TIER-2-Domain y TIER-3-Domain

Luego proceder a: **[FASE-05-PRESENTATION.md](./FASE-05-PRESENTATION.md)**
