# FASE 03: Migracion Infrastructure

**Estado:** PENDIENTE  
**Duracion Estimada:** 2-3 horas  
**Dependencias:** FASE 02 completada  
**Fase Anterior:** [FASE-02-FOUNDATION-CORE.md](./FASE-02-FOUNDATION-CORE.md)  
**Siguiente Fase:** [FASE-04-DOMAIN.md](./FASE-04-DOMAIN.md)

---

## OBJETIVO DE LA FASE

Migrar los servicios de infraestructura que manejan la comunicacion con sistemas externos: Network (HTTP client), Storage (persistencia local) y LocalPersistence (Core Data/SQLite).

---

## MAPEO DE ARCHIVOS

### Network
```
ORIGEN:
TIER-2-Infrastructure/Network/Sources/Network/

DESTINO:
EduGoModules/Packages/Infrastructure/Sources/Network/
```

### Storage
```
ORIGEN:
TIER-2-Infrastructure/Storage/Sources/Storage/

DESTINO:
EduGoModules/Packages/Infrastructure/Sources/Storage/
```

### LocalPersistence (Persistence)
```
ORIGEN:
TIER-2-Infrastructure/LocalPersistence/Sources/LocalPersistence/

DESTINO:
EduGoModules/Packages/Infrastructure/Sources/Persistence/
```

---

## PREREQUISITOS

- [ ] FASE 02 completada exitosamente
- [ ] Foundation y Core compilando en EduGoModules
- [ ] Branch `refactor/restructure-for-xcode` activo
- [ ] No hay cambios sin commit

---

## TAREAS DETALLADAS

### TAREA 3.1: Verificar Estado Previo
**Tiempo estimado:** 5 minutos

**Pasos:**
1. Verificar rama y estado
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple
   git branch --show-current
   git status
   ```

2. Verificar que Foundation y Core compilan
   ```bash
   cd EduGoModules/Packages/Foundation && swift build && cd ../../..
   cd EduGoModules/Packages/Core && swift build && cd ../../..
   ```

3. Verificar estructura de Infrastructure
   ```bash
   ls -la EduGoModules/Packages/Infrastructure/Sources/
   # Debe mostrar: Network, Storage, Persistence
   ```

**Criterio de exito:**
- Foundation y Core compilando
- Estructura de Infrastructure verificada

**Checklist:**
- [ ] Rama verificada
- [ ] Foundation compila
- [ ] Core compila
- [ ] Estructura Infrastructure verificada

---

### TAREA 3.2: Analizar Contenido de Infrastructure
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Analizar Network
   ```bash
   echo "=== NETWORK ==="
   find TIER-2-Infrastructure/Network/Sources/Network -name "*.swift" -type f
   find TIER-2-Infrastructure/Network/Sources/Network -name "*.swift" | wc -l
   find TIER-2-Infrastructure/Network/Sources/Network -type d
   ```

2. Analizar Storage
   ```bash
   echo "=== STORAGE ==="
   find TIER-2-Infrastructure/Storage/Sources/Storage -name "*.swift" -type f
   find TIER-2-Infrastructure/Storage/Sources/Storage -name "*.swift" | wc -l
   find TIER-2-Infrastructure/Storage/Sources/Storage -type d
   ```

3. Analizar LocalPersistence
   ```bash
   echo "=== LOCAL PERSISTENCE ==="
   find TIER-2-Infrastructure/LocalPersistence/Sources/LocalPersistence -name "*.swift" -type f
   find TIER-2-Infrastructure/LocalPersistence/Sources/LocalPersistence -name "*.swift" | wc -l
   find TIER-2-Infrastructure/LocalPersistence/Sources/LocalPersistence -type d
   ```

4. Identificar dependencias de cada modulo
   ```bash
   # Network
   grep -h "^import " TIER-2-Infrastructure/Network/Sources/Network/*.swift | sort -u
   
   # Storage
   grep -h "^import " TIER-2-Infrastructure/Storage/Sources/Storage/*.swift | sort -u
   
   # LocalPersistence
   grep -h "^import " TIER-2-Infrastructure/LocalPersistence/Sources/LocalPersistence/*.swift | sort -u
   ```

5. Documentar hallazgos:

**Network:**
- Archivos: _____
- Subcarpetas: _____
- Dependencias: _____

**Storage:**
- Archivos: _____
- Subcarpetas: _____
- Dependencias: _____

**LocalPersistence:**
- Archivos: _____
- Subcarpetas: _____
- Dependencias: _____

**Criterio de exito:**
- Todos los modulos analizados y documentados

**Checklist:**
- [ ] Network analizado
- [ ] Storage analizado
- [ ] LocalPersistence analizado
- [ ] Dependencias identificadas

---

### TAREA 3.3: Migrar Network
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Infrastructure/Sources/Network/Placeholder.swift
   ```

2. Copiar archivos de Network
   ```bash
   cp -R TIER-2-Infrastructure/Network/Sources/Network/* \
         EduGoModules/Packages/Infrastructure/Sources/Network/
   ```

3. Verificar copia
   ```bash
   ls -la EduGoModules/Packages/Infrastructure/Sources/Network/
   find EduGoModules/Packages/Infrastructure/Sources/Network -name "*.swift" | wc -l
   ```

4. Actualizar imports
   ```bash
   # EduGoCommon -> EduFoundation
   find EduGoModules/Packages/Infrastructure/Sources/Network -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   # Logger -> EduLogger (o EduCore si Logger esta en Core)
   find EduGoModules/Packages/Infrastructure/Sources/Network -name "*.swift" -exec \
     sed -i '' 's/import Logger/import EduCore/g' {} +
   
   # Models -> EduModels (o EduCore)
   find EduGoModules/Packages/Infrastructure/Sources/Network -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   ```

5. Verificar imports restantes
   ```bash
   grep -r "^import " EduGoModules/Packages/Infrastructure/Sources/Network/ | \
     grep -v "Foundation\|SwiftUI\|Combine\|EduFoundation\|EduCore"
   ```

**Criterio de exito:**
- Network copiado
- Imports actualizados

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados
- [ ] Verificacion de imports

---

### TAREA 3.4: Migrar Storage
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Infrastructure/Sources/Storage/Placeholder.swift
   ```

2. Copiar archivos de Storage
   ```bash
   cp -R TIER-2-Infrastructure/Storage/Sources/Storage/* \
         EduGoModules/Packages/Infrastructure/Sources/Storage/
   ```

3. Verificar copia
   ```bash
   ls -la EduGoModules/Packages/Infrastructure/Sources/Storage/
   ```

4. Actualizar imports
   ```bash
   find EduGoModules/Packages/Infrastructure/Sources/Storage -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   find EduGoModules/Packages/Infrastructure/Sources/Storage -name "*.swift" -exec \
     sed -i '' 's/import Logger/import EduCore/g' {} +
   
   find EduGoModules/Packages/Infrastructure/Sources/Storage -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   ```

**Criterio de exito:**
- Storage copiado
- Imports actualizados

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 3.5: Migrar LocalPersistence (Persistence)
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Eliminar placeholder
   ```bash
   rm EduGoModules/Packages/Infrastructure/Sources/Persistence/Placeholder.swift
   ```

2. Copiar archivos de LocalPersistence
   ```bash
   cp -R TIER-2-Infrastructure/LocalPersistence/Sources/LocalPersistence/* \
         EduGoModules/Packages/Infrastructure/Sources/Persistence/
   ```

3. Verificar copia
   ```bash
   ls -la EduGoModules/Packages/Infrastructure/Sources/Persistence/
   find EduGoModules/Packages/Infrastructure/Sources/Persistence -type d
   ```

4. Actualizar imports
   ```bash
   find EduGoModules/Packages/Infrastructure/Sources/Persistence -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   find EduGoModules/Packages/Infrastructure/Sources/Persistence -name "*.swift" -exec \
     sed -i '' 's/import Logger/import EduCore/g' {} +
   
   find EduGoModules/Packages/Infrastructure/Sources/Persistence -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   ```

5. Verificar si hay archivos .xcdatamodeld (Core Data)
   ```bash
   find EduGoModules/Packages/Infrastructure/Sources/Persistence -name "*.xcdatamodeld"
   ```

   Si hay modelos Core Data, asegurarse de que estan copiados correctamente.

**Criterio de exito:**
- Persistence copiado
- Imports actualizados
- Core Data models copiados (si aplica)

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados
- [ ] Core Data models verificados (si aplica)

---

### TAREA 3.6: Actualizar Package.swift de Infrastructure
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Actualizar Package.swift con estructura de submodulos
   ```bash
   cat > EduGoModules/Packages/Infrastructure/Package.swift << 'EOF'
   // swift-tools-version: 6.2
   import PackageDescription

   let package = Package(
       name: "EduInfrastructure",
       platforms: [
           .iOS(.v26),
           .macOS(.v26)
       ],
       products: [
           .library(name: "EduInfrastructure", targets: ["EduInfrastructure"]),
           // Exponer submodulos individualmente
           .library(name: "EduNetwork", targets: ["EduNetwork"]),
           .library(name: "EduStorage", targets: ["EduStorage"]),
           .library(name: "EduPersistence", targets: ["EduPersistence"])
       ],
       dependencies: [
           .package(path: "../Foundation"),
           .package(path: "../Core")
       ],
       targets: [
           // Target principal que agrupa todo
           .target(
               name: "EduInfrastructure",
               dependencies: [
                   "EduNetwork",
                   "EduStorage",
                   "EduPersistence"
               ]
           ),
           // Submodulos
           .target(
               name: "EduNetwork",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation"),
                   .product(name: "EduCore", package: "Core")
               ],
               path: "Sources/Network"
           ),
           .target(
               name: "EduStorage",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation"),
                   .product(name: "EduCore", package: "Core")
               ],
               path: "Sources/Storage"
           ),
           .target(
               name: "EduPersistence",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation"),
                   .product(name: "EduCore", package: "Core")
               ],
               path: "Sources/Persistence"
           ),
           // Tests
           .testTarget(
               name: "EduInfrastructureTests",
               dependencies: ["EduInfrastructure"],
               path: "Tests/InfrastructureTests"
           )
       ]
   )
   EOF
   ```

2. Crear archivo de reexportacion
   ```bash
   mkdir -p EduGoModules/Packages/Infrastructure/Sources/EduInfrastructure
   cat > EduGoModules/Packages/Infrastructure/Sources/EduInfrastructure/Exports.swift << 'EOF'
   // EduInfrastructure - Re-exports all submodules
   @_exported import EduNetwork
   @_exported import EduStorage
   @_exported import EduPersistence
   EOF
   ```

**Criterio de exito:**
- Package.swift actualizado
- Archivo de reexportacion creado

**Checklist:**
- [ ] Package.swift actualizado
- [ ] Archivo Exports.swift creado

---

### TAREA 3.7: Compilar Infrastructure
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Compilar Infrastructure
   ```bash
   cd EduGoModules/Packages/Infrastructure
   swift build 2>&1 | tee /tmp/infrastructure-build.log
   ```

2. Si hay errores, analizar y corregir
   ```bash
   grep -i "error:" /tmp/infrastructure-build.log
   ```

3. Errores comunes y soluciones:

   **Error: referencias a tipos de otros modulos Infrastructure**
   
   Si Network necesita tipos de Storage o viceversa:
   ```bash
   # Agregar dependencia interna en Package.swift
   # Por ejemplo, si Network necesita Storage:
   .target(
       name: "EduNetwork",
       dependencies: [
           .product(name: "EduFoundation", package: "Foundation"),
           .product(name: "EduCore", package: "Core"),
           "EduStorage"  // <-- Agregar dependencia interna
       ],
       path: "Sources/Network"
   ),
   ```

   **Error: "LocalPersistence" no se encuentra**
   
   Si hay referencias al nombre anterior:
   ```bash
   find EduGoModules/Packages/Infrastructure -name "*.swift" -exec \
     sed -i '' 's/import LocalPersistence/import EduPersistence/g' {} +
   ```

4. Una vez compila:
   ```bash
   swift test
   cd ../../..
   ```

**Criterio de exito:**
- Infrastructure compila sin errores
- Tests pasan

**Checklist:**
- [ ] Build ejecutado
- [ ] Errores corregidos (si hubo)
- [ ] Build exitoso
- [ ] Tests pasan

---

### TAREA 3.8: Migrar Tests de Infrastructure
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Verificar tests existentes
   ```bash
   find TIER-2-Infrastructure/Network/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-2-Infrastructure/Storage/Tests -name "*.swift" 2>/dev/null | wc -l
   find TIER-2-Infrastructure/LocalPersistence/Tests -name "*.swift" 2>/dev/null | wc -l
   ```

2. Eliminar test placeholder
   ```bash
   rm EduGoModules/Packages/Infrastructure/Tests/InfrastructureTests/InfrastructureTests.swift
   ```

3. Crear estructura de tests
   ```bash
   mkdir -p EduGoModules/Packages/Infrastructure/Tests/InfrastructureTests/Network
   mkdir -p EduGoModules/Packages/Infrastructure/Tests/InfrastructureTests/Storage
   mkdir -p EduGoModules/Packages/Infrastructure/Tests/InfrastructureTests/Persistence
   ```

4. Copiar tests
   ```bash
   # Network tests
   cp -R TIER-2-Infrastructure/Network/Tests/NetworkTests/* \
         EduGoModules/Packages/Infrastructure/Tests/InfrastructureTests/Network/ 2>/dev/null || echo "No Network tests"
   
   # Storage tests
   cp -R TIER-2-Infrastructure/Storage/Tests/StorageTests/* \
         EduGoModules/Packages/Infrastructure/Tests/InfrastructureTests/Storage/ 2>/dev/null || echo "No Storage tests"
   
   # LocalPersistence tests
   cp -R TIER-2-Infrastructure/LocalPersistence/Tests/LocalPersistenceTests/* \
         EduGoModules/Packages/Infrastructure/Tests/InfrastructureTests/Persistence/ 2>/dev/null || echo "No Persistence tests"
   ```

5. Actualizar imports en tests
   ```bash
   find EduGoModules/Packages/Infrastructure/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import Network/@testable import EduNetwork/g' {} +
   
   find EduGoModules/Packages/Infrastructure/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import Storage/@testable import EduStorage/g' {} +
   
   find EduGoModules/Packages/Infrastructure/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import LocalPersistence/@testable import EduPersistence/g' {} +
   
   find EduGoModules/Packages/Infrastructure/Tests -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   
   find EduGoModules/Packages/Infrastructure/Tests -name "*.swift" -exec \
     sed -i '' 's/import Models/import EduCore/g' {} +
   
   find EduGoModules/Packages/Infrastructure/Tests -name "*.swift" -exec \
     sed -i '' 's/import Logger/import EduCore/g' {} +
   ```

6. Si no hay tests, crear test minimo
   ```bash
   cat > EduGoModules/Packages/Infrastructure/Tests/InfrastructureTests/InfrastructureTests.swift << 'EOF'
   import XCTest
   @testable import EduInfrastructure
   @testable import EduNetwork
   @testable import EduStorage
   @testable import EduPersistence

   final class InfrastructureTests: XCTestCase {
       func testModulesLoad() {
           XCTAssertTrue(true, "EduInfrastructure modules loaded successfully")
       }
   }
   EOF
   ```

7. Ejecutar tests
   ```bash
   cd EduGoModules/Packages/Infrastructure
   swift test
   cd ../../..
   ```

**Criterio de exito:**
- Tests copiados o creados
- Tests pasan

**Checklist:**
- [ ] Tests existentes verificados
- [ ] Estructura de tests creada
- [ ] Tests copiados
- [ ] Imports actualizados
- [ ] Tests pasan

---

### TAREA 3.9: Verificar Compilacion Completa
**Tiempo estimado:** 10 minutos

**Pasos:**
1. Compilar desde raiz de EduGoModules
   ```bash
   cd EduGoModules
   swift build
   ```

2. Ejecutar todos los tests
   ```bash
   swift test
   ```

3. Verificar dependencias
   ```bash
   swift package show-dependencies
   ```

**Criterio de exito:**
- Compilacion completa exitosa
- Todos los tests pasan
- Cadena de dependencias: Foundation <- Core <- Infrastructure

**Checklist:**
- [ ] Build desde raiz exitoso
- [ ] Tests desde raiz exitosos
- [ ] Dependencias verificadas

---

### TAREA 3.10: Commit de Fase 03
**Tiempo estimado:** 5 minutos

**Pasos:**
1. Agregar cambios
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple
   git add EduGoModules/
   ```

2. Commit
   ```bash
   git commit -m "feat(migration): migrate Infrastructure package

   Infrastructure:
   - Migrated Network from TIER-2-Infrastructure/Network
   - Migrated Storage from TIER-2-Infrastructure/Storage
   - Migrated Persistence from TIER-2-Infrastructure/LocalPersistence
   - Updated Package.swift with submodule structure
   - Updated all imports to use EduFoundation and EduCore
   - All tests passing
   
   Dependency chain verified:
   Foundation <- Core <- Infrastructure
   
   Part of: restructure-for-xcode migration
   Phase: 03/06"
   ```

3. Push
   ```bash
   git push origin refactor/restructure-for-xcode
   ```

**Criterio de exito:**
- Commit realizado
- Push exitoso

**Checklist:**
- [ ] Cambios agregados
- [ ] Commit realizado
- [ ] Push exitoso

---

## RESOLUCION DE PROBLEMAS COMUNES

### Problema: Dependencias circulares entre Network/Storage/Persistence
**Solucion:**
1. Identificar el codigo compartido
2. Extraer protocolos a un modulo comun (InfrastructureProtocols)
3. O mover el codigo compartido a Core

### Problema: Core Data model no compila
**Solucion:**
1. Verificar que .xcdatamodeld esta copiado completo
2. Verificar que el path en Package.swift es correcto
3. Considerar usar recursos: `resources: [.copy("Model.xcdatamodeld")]`

### Problema: Referencias a tipos de TIER-3 (Auth, etc)
**Solucion:**
1. Estas referencias no deberian existir (violarian Clean Architecture)
2. Si existen, usar protocolos para invertir la dependencia
3. O mover la logica al lugar correcto

---

## ARCHIVOS MIGRADOS EN ESTA FASE

**Completar durante ejecucion:**

| Origen | Destino | Archivos |
|--------|---------|----------|
| TIER-2-Infrastructure/Network | Packages/Infrastructure/Sources/Network | ___ |
| TIER-2-Infrastructure/Storage | Packages/Infrastructure/Sources/Storage | ___ |
| TIER-2-Infrastructure/LocalPersistence | Packages/Infrastructure/Sources/Persistence | ___ |
| **TOTAL** | | ___ |

---

## RESUMEN DE EJECUCION

**Completar al finalizar la fase:**

```
Fecha inicio: _____
Fecha fin: _____
Ejecutor: _____
Duracion real: _____

Tareas completadas: ___/10
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

- [ ] Network migrado completamente
- [ ] Storage migrado completamente
- [ ] Persistence migrado completamente
- [ ] Package.swift de Infrastructure actualizado
- [ ] Infrastructure compila sin errores
- [ ] Infrastructure tests pasan
- [ ] Build desde raiz de EduGoModules exitoso
- [ ] Cadena de dependencias verificada
- [ ] Commit de fase realizado
- [ ] Push exitoso

---

## SIGUIENTE PASO

Una vez completada esta fase, actualizar el PLAN_MAESTRO.md con:
1. Marcar FASE 03 como COMPLETADA
2. Registrar fecha, ejecutor y duracion
3. Copiar el RESUMEN DE EJECUCION

Luego proceder a: **[FASE-04-DOMAIN.md](./FASE-04-DOMAIN.md)**
