# FASE 02: Migracion Foundation y Core

**Estado:** PENDIENTE  
**Duracion Estimada:** 2-3 horas  
**Dependencias:** FASE 01 completada  
**Fase Anterior:** [FASE-01-PREPARACION.md](./FASE-01-PREPARACION.md)  
**Siguiente Fase:** [FASE-03-INFRASTRUCTURE.md](./FASE-03-INFRASTRUCTURE.md)

---

## OBJETIVO DE LA FASE

Migrar los modulos base del proyecto: Foundation (TIER-0) y Core (TIER-1). Estos modulos son la base de toda la arquitectura y no dependen de otros modulos internos, por lo que deben migrarse primero.

---

## MAPEO DE ARCHIVOS

### Foundation (TIER-0 -> Foundation)
```
ORIGEN:
TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon/

DESTINO:
EduGoModules/Packages/Foundation/Sources/EduFoundation/
```

### Core - Models (TIER-1 -> Core)
```
ORIGEN:
TIER-1-Core/Models/Sources/Models/
├── DTOs/
├── Domain/
├── Mappers/
├── Protocols/
├── Support/
└── Validation/

DESTINO:
EduGoModules/Packages/Core/Sources/Models/
├── DTOs/
├── Domain/
├── Mappers/
├── Protocols/
├── Support/
└── Validation/
```

### Core - Logger (TIER-1 -> Core)
```
ORIGEN:
TIER-1-Core/Logger/Sources/Logger/

DESTINO:
EduGoModules/Packages/Core/Sources/Logger/
```

### Core - Utilities (TIER-1 -> Core)
```
ORIGEN:
TIER-1-Core/Utilities/Sources/Utilities/

DESTINO:
EduGoModules/Packages/Core/Sources/Utilities/
```

---

## PREREQUISITOS

- [ ] FASE 01 completada exitosamente
- [ ] Branch `refactor/restructure-for-xcode` activo
- [ ] EduGoModules/ existe con estructura base
- [ ] No hay cambios sin commit

---

## TAREAS DETALLADAS

### TAREA 2.1: Verificar Estado Previo
**Tiempo estimado:** 5 minutos

**Pasos:**
1. Verificar rama activa
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple
   git branch --show-current
   # Debe ser: refactor/restructure-for-xcode
   ```

2. Verificar estado limpio
   ```bash
   git status
   # Debe estar limpio o con cambios esperados
   ```

3. Verificar estructura base existe
   ```bash
   ls -la EduGoModules/Packages/
   # Debe mostrar: Foundation, Core, Infrastructure, Domain, Presentation, Features
   ```

4. Verificar que compila
   ```bash
   cd EduGoModules
   swift build
   cd ..
   ```

**Criterio de exito:**
- Rama correcta activa
- Estructura base verificada
- Compilacion exitosa

**Checklist:**
- [ ] Rama verificada
- [ ] Estado limpio
- [ ] Estructura existe
- [ ] Compila correctamente

---

### TAREA 2.2: Analizar Contenido de Foundation (EduGoCommon)
**Tiempo estimado:** 10 minutos

**Pasos:**
1. Listar archivos en EduGoCommon
   ```bash
   find TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon -name "*.swift" -type f
   ```

2. Contar archivos
   ```bash
   find TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon -name "*.swift" | wc -l
   ```

3. Identificar estructura de carpetas
   ```bash
   find TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon -type d
   ```

4. Documentar hallazgos en esta seccion:

**Archivos encontrados:**
```
(Completar durante ejecucion)
- 
- 
```

**Estructura de carpetas:**
```
(Completar durante ejecucion)
- 
- 
```

**Criterio de exito:**
- Lista completa de archivos documentada

**Checklist:**
- [ ] Archivos listados
- [ ] Conteo realizado
- [ ] Estructura documentada

---

### TAREA 2.3: Migrar Foundation
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Eliminar placeholder de Foundation
   ```bash
   rm EduGoModules/Packages/Foundation/Sources/EduFoundation/EduFoundation.swift
   ```

2. Copiar archivos de EduGoCommon a EduFoundation
   ```bash
   cp -R TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon/* \
         EduGoModules/Packages/Foundation/Sources/EduFoundation/
   ```

3. Verificar copia
   ```bash
   ls -la EduGoModules/Packages/Foundation/Sources/EduFoundation/
   ```

4. Actualizar imports en archivos copiados (si es necesario)
   
   Buscar imports que referencien EduGoCommon:
   ```bash
   grep -r "import EduGoCommon" EduGoModules/Packages/Foundation/
   ```
   
   Si hay coincidencias, reemplazar:
   ```bash
   find EduGoModules/Packages/Foundation -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

5. Verificar que no hay referencias internas rotas
   ```bash
   grep -r "EduGoCommon" EduGoModules/Packages/Foundation/
   # No debe haber resultados
   ```

6. Compilar Foundation
   ```bash
   cd EduGoModules/Packages/Foundation
   swift build
   cd ../../..
   ```

**Criterio de exito:**
- Archivos copiados
- Imports actualizados
- Foundation compila sin errores

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Copia verificada
- [ ] Imports actualizados (si aplica)
- [ ] Sin referencias rotas
- [ ] Compilacion exitosa

---

### TAREA 2.4: Migrar Tests de Foundation
**Tiempo estimado:** 10 minutos

**Pasos:**
1. Verificar si existen tests
   ```bash
   find TIER-0-Foundation/EduGoCommon/Tests -name "*.swift" -type f
   ```

2. Si existen tests, eliminar placeholder de tests
   ```bash
   rm EduGoModules/Packages/Foundation/Tests/EduFoundationTests/EduFoundationTests.swift
   ```

3. Copiar tests
   ```bash
   cp -R TIER-0-Foundation/EduGoCommon/Tests/EduGoCommonTests/* \
         EduGoModules/Packages/Foundation/Tests/EduFoundationTests/
   ```

4. Actualizar imports en tests
   ```bash
   find EduGoModules/Packages/Foundation/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import EduGoCommon/@testable import EduFoundation/g' {} +
   
   find EduGoModules/Packages/Foundation/Tests -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

5. Ejecutar tests
   ```bash
   cd EduGoModules/Packages/Foundation
   swift test
   cd ../../..
   ```

**Criterio de exito:**
- Tests copiados (si existian)
- Tests pasan

**Checklist:**
- [ ] Tests existentes verificados
- [ ] Tests copiados (si aplica)
- [ ] Imports actualizados
- [ ] Tests pasan

---

### TAREA 2.5: Analizar Contenido de Core (Models, Logger, Utilities)
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Listar archivos de Models
   ```bash
   find TIER-1-Core/Models/Sources/Models -name "*.swift" -type f | head -50
   find TIER-1-Core/Models/Sources/Models -name "*.swift" | wc -l
   ```

2. Listar archivos de Logger
   ```bash
   find TIER-1-Core/Logger/Sources/Logger -name "*.swift" -type f
   find TIER-1-Core/Logger/Sources/Logger -name "*.swift" | wc -l
   ```

3. Listar archivos de Utilities
   ```bash
   find TIER-1-Core/Utilities/Sources/Utilities -name "*.swift" -type f
   find TIER-1-Core/Utilities/Sources/Utilities -name "*.swift" | wc -l
   ```

4. Documentar hallazgos:

**Models - Archivos encontrados:** _____ archivos
```
Subcarpetas:
- DTOs/
- Domain/
- Mappers/
- Protocols/
- Support/
- Validation/
```

**Logger - Archivos encontrados:** _____ archivos

**Utilities - Archivos encontrados:** _____ archivos

**Criterio de exito:**
- Todos los archivos identificados y documentados

**Checklist:**
- [ ] Models analizado
- [ ] Logger analizado
- [ ] Utilities analizado
- [ ] Conteos documentados

---

### TAREA 2.6: Migrar Core - Models
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Eliminar placeholder de Models
   ```bash
   rm EduGoModules/Packages/Core/Sources/Models/Placeholder.swift
   ```

2. Copiar estructura completa de Models
   ```bash
   cp -R TIER-1-Core/Models/Sources/Models/* \
         EduGoModules/Packages/Core/Sources/Models/
   ```

3. Verificar estructura copiada
   ```bash
   find EduGoModules/Packages/Core/Sources/Models -type d
   ls -la EduGoModules/Packages/Core/Sources/Models/
   ```

4. Buscar y actualizar imports de EduGoCommon
   ```bash
   grep -r "import EduGoCommon" EduGoModules/Packages/Core/Sources/Models/
   ```
   
   Si hay coincidencias:
   ```bash
   find EduGoModules/Packages/Core/Sources/Models -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

5. Verificar dependencias en archivos
   ```bash
   grep -r "import " EduGoModules/Packages/Core/Sources/Models/ | grep -v "Foundation\|SwiftUI\|Combine" | head -20
   ```

**Criterio de exito:**
- Models copiado con estructura completa
- Imports actualizados

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Estructura verificada
- [ ] Imports actualizados

---

### TAREA 2.7: Migrar Core - Logger
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder de Logger
   ```bash
   rm EduGoModules/Packages/Core/Sources/Logger/Placeholder.swift
   ```

2. Copiar Logger
   ```bash
   cp -R TIER-1-Core/Logger/Sources/Logger/* \
         EduGoModules/Packages/Core/Sources/Logger/
   ```

3. Verificar copia
   ```bash
   ls -la EduGoModules/Packages/Core/Sources/Logger/
   ```

4. Actualizar imports
   ```bash
   find EduGoModules/Packages/Core/Sources/Logger -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

**Criterio de exito:**
- Logger copiado
- Imports actualizados

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 2.8: Migrar Core - Utilities
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Eliminar placeholder de Utilities
   ```bash
   rm EduGoModules/Packages/Core/Sources/Utilities/Placeholder.swift
   ```

2. Copiar Utilities
   ```bash
   cp -R TIER-1-Core/Utilities/Sources/Utilities/* \
         EduGoModules/Packages/Core/Sources/Utilities/
   ```

3. Verificar copia
   ```bash
   ls -la EduGoModules/Packages/Core/Sources/Utilities/
   ```

4. Actualizar imports
   ```bash
   find EduGoModules/Packages/Core/Sources/Utilities -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

**Criterio de exito:**
- Utilities copiado
- Imports actualizados

**Checklist:**
- [ ] Placeholder eliminado
- [ ] Archivos copiados
- [ ] Imports actualizados

---

### TAREA 2.9: Actualizar Package.swift de Core
**Tiempo estimado:** 15 minutos

El Package.swift de Core necesita exponer los tres modulos internos.

**Pasos:**
1. Editar Package.swift de Core
   ```bash
   cat > EduGoModules/Packages/Core/Package.swift << 'EOF'
   // swift-tools-version: 6.2
   import PackageDescription

   let package = Package(
       name: "EduCore",
       platforms: [
           .iOS(.v26),
           .macOS(.v26)
       ],
       products: [
           .library(name: "EduCore", targets: ["EduCore"]),
           // Exponer submodulos individualmente si es necesario
           .library(name: "EduModels", targets: ["EduModels"]),
           .library(name: "EduLogger", targets: ["EduLogger"]),
           .library(name: "EduUtilities", targets: ["EduUtilities"])
       ],
       dependencies: [
           .package(path: "../Foundation")
       ],
       targets: [
           // Target principal que agrupa todo
           .target(
               name: "EduCore",
               dependencies: [
                   "EduModels",
                   "EduLogger",
                   "EduUtilities"
               ]
           ),
           // Submodulos
           .target(
               name: "EduModels",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation")
               ],
               path: "Sources/Models"
           ),
           .target(
               name: "EduLogger",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation")
               ],
               path: "Sources/Logger"
           ),
           .target(
               name: "EduUtilities",
               dependencies: [
                   .product(name: "EduFoundation", package: "Foundation")
               ],
               path: "Sources/Utilities"
           ),
           // Tests
           .testTarget(
               name: "EduCoreTests",
               dependencies: ["EduCore"],
               path: "Tests/CoreTests"
           )
       ]
   )
   EOF
   ```

2. Crear archivo de reexportacion para EduCore
   ```bash
   mkdir -p EduGoModules/Packages/Core/Sources/EduCore
   cat > EduGoModules/Packages/Core/Sources/EduCore/Exports.swift << 'EOF'
   // EduCore - Re-exports all submodules
   @_exported import EduModels
   @_exported import EduLogger
   @_exported import EduUtilities
   EOF
   ```

**Criterio de exito:**
- Package.swift actualizado
- Archivo de reexportacion creado

**Checklist:**
- [ ] Package.swift actualizado
- [ ] Archivo Exports.swift creado

---

### TAREA 2.10: Compilar y Verificar Core
**Tiempo estimado:** 15 minutos

**Pasos:**
1. Compilar Core
   ```bash
   cd EduGoModules/Packages/Core
   swift build 2>&1 | tee /tmp/core-build.log
   ```

2. Si hay errores, analizarlos
   ```bash
   # Ver errores especificos
   grep -i "error:" /tmp/core-build.log
   ```

3. Errores comunes y soluciones:

   **Error: "No such module 'EduGoCommon'"**
   ```bash
   # Buscar archivos que aun referencien EduGoCommon
   grep -r "EduGoCommon" EduGoModules/Packages/Core/Sources/
   # Reemplazar manualmente o con sed
   ```

   **Error: "Cannot find type 'X' in scope"**
   - Verificar que el tipo exista en EduFoundation
   - O que este en el mismo modulo

   **Error: "Ambiguous use of 'X'"**
   - Calificar completamente el tipo: `EduModels.TypeName`

4. Una vez compila, ejecutar tests placeholder
   ```bash
   swift test
   cd ../../..
   ```

**Criterio de exito:**
- `swift build` exitoso sin errores
- Tests pasan

**Checklist:**
- [ ] Build ejecutado
- [ ] Errores resueltos (si hubo)
- [ ] Build exitoso
- [ ] Tests pasan

---

### TAREA 2.11: Migrar Tests de Core
**Tiempo estimado:** 20 minutos

**Pasos:**
1. Verificar tests existentes
   ```bash
   find TIER-1-Core/Models/Tests -name "*.swift" -type f 2>/dev/null | wc -l
   find TIER-1-Core/Logger/Tests -name "*.swift" -type f 2>/dev/null | wc -l
   find TIER-1-Core/Utilities/Tests -name "*.swift" -type f 2>/dev/null | wc -l
   ```

2. Eliminar test placeholder
   ```bash
   rm EduGoModules/Packages/Core/Tests/CoreTests/CoreTests.swift
   ```

3. Crear estructura de tests
   ```bash
   mkdir -p EduGoModules/Packages/Core/Tests/CoreTests/Models
   mkdir -p EduGoModules/Packages/Core/Tests/CoreTests/Logger
   mkdir -p EduGoModules/Packages/Core/Tests/CoreTests/Utilities
   ```

4. Copiar tests de Models
   ```bash
   cp -R TIER-1-Core/Models/Tests/ModelsTests/* \
         EduGoModules/Packages/Core/Tests/CoreTests/Models/ 2>/dev/null || echo "No Models tests found"
   ```

5. Copiar tests de Logger
   ```bash
   cp -R TIER-1-Core/Logger/Tests/LoggerTests/* \
         EduGoModules/Packages/Core/Tests/CoreTests/Logger/ 2>/dev/null || echo "No Logger tests found"
   ```

6. Copiar tests de Utilities
   ```bash
   cp -R TIER-1-Core/Utilities/Tests/UtilitiesTests/* \
         EduGoModules/Packages/Core/Tests/CoreTests/Utilities/ 2>/dev/null || echo "No Utilities tests found"
   ```

7. Actualizar imports en tests
   ```bash
   find EduGoModules/Packages/Core/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import Models/@testable import EduModels/g' {} +
   
   find EduGoModules/Packages/Core/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import Logger/@testable import EduLogger/g' {} +
   
   find EduGoModules/Packages/Core/Tests -name "*.swift" -exec \
     sed -i '' 's/@testable import Utilities/@testable import EduUtilities/g' {} +
   
   find EduGoModules/Packages/Core/Tests -name "*.swift" -exec \
     sed -i '' 's/import EduGoCommon/import EduFoundation/g' {} +
   ```

8. Si no hay tests, crear test minimo
   ```bash
   cat > EduGoModules/Packages/Core/Tests/CoreTests/CoreTests.swift << 'EOF'
   import XCTest
   @testable import EduCore
   @testable import EduModels
   @testable import EduLogger
   @testable import EduUtilities

   final class CoreTests: XCTestCase {
       func testModulesLoad() {
           // Test que los modulos cargan correctamente
           XCTAssertTrue(true, "EduCore modules loaded successfully")
       }
   }
   EOF
   ```

9. Ejecutar tests
   ```bash
   cd EduGoModules/Packages/Core
   swift test
   cd ../../..
   ```

**Criterio de exito:**
- Tests copiados o creados
- Tests pasan

**Checklist:**
- [ ] Tests existentes verificados
- [ ] Estructura de tests creada
- [ ] Tests copiados (si existian)
- [ ] Imports actualizados
- [ ] Tests pasan

---

### TAREA 2.12: Verificar Compilacion Completa
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

3. Verificar que Foundation y Core estan integrados
   ```bash
   # Este comando debe mostrar ambos packages compilados
   swift package show-dependencies
   ```

**Criterio de exito:**
- Compilacion completa exitosa
- Todos los tests pasan

**Checklist:**
- [ ] Build desde raiz exitoso
- [ ] Tests desde raiz exitosos
- [ ] Dependencias verificadas

---

### TAREA 2.13: Commit de Fase 02
**Tiempo estimado:** 5 minutos

**Pasos:**
1. Agregar cambios
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple
   git add EduGoModules/
   ```

2. Verificar cambios
   ```bash
   git status
   git diff --cached --stat
   ```

3. Commit
   ```bash
   git commit -m "feat(migration): migrate Foundation and Core packages

   Foundation:
   - Migrated from TIER-0-Foundation/EduGoCommon
   - Updated imports to EduFoundation
   - All tests passing
   
   Core:
   - Migrated Models from TIER-1-Core/Models
   - Migrated Logger from TIER-1-Core/Logger
   - Migrated Utilities from TIER-1-Core/Utilities
   - Updated Package.swift with submodule structure
   - Updated imports to use EduFoundation
   - All tests passing
   
   Part of: restructure-for-xcode migration
   Phase: 02/06"
   ```

4. Push
   ```bash
   git push origin refactor/restructure-for-xcode
   ```

**Criterio de exito:**
- Commit realizado con mensaje descriptivo
- Push exitoso

**Checklist:**
- [ ] Cambios agregados
- [ ] Commit realizado
- [ ] Push exitoso

---

## RESOLUCION DE PROBLEMAS COMUNES

### Problema: "No such module 'X'"
**Causa:** Import no actualizado o modulo no expuesto
**Solucion:**
1. Verificar que el modulo este en dependencies del Package.swift
2. Verificar que el import use el nombre correcto del producto

### Problema: Tipos duplicados
**Causa:** Mismo tipo definido en Foundation y Core
**Solucion:**
1. Eliminar duplicado de Core
2. O renombrar uno de los tipos
3. Usar typealiases si es necesario para compatibilidad

### Problema: Access level errors
**Causa:** Tipos marcados como internal que ahora estan en modulo diferente
**Solucion:**
1. Cambiar `internal` a `public` donde sea necesario
2. O usar `@_exported import` para reexportar

### Problema: Dependencias circulares
**Causa:** A depende de B y B depende de A
**Solucion:**
1. Extraer el codigo compartido a un tercer modulo
2. O usar protocolos para romper la dependencia

---

## ARCHIVOS MIGRADOS EN ESTA FASE

**Completar durante ejecucion:**

| Origen | Destino | Archivos |
|--------|---------|----------|
| TIER-0-Foundation/EduGoCommon | Packages/Foundation | ___ |
| TIER-1-Core/Models | Packages/Core/Sources/Models | ___ |
| TIER-1-Core/Logger | Packages/Core/Sources/Logger | ___ |
| TIER-1-Core/Utilities | Packages/Core/Sources/Utilities | ___ |
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

- [ ] Foundation migrado completamente
- [ ] Foundation compila sin errores
- [ ] Foundation tests pasan
- [ ] Core/Models migrado completamente
- [ ] Core/Logger migrado completamente
- [ ] Core/Utilities migrado completamente
- [ ] Core compila sin errores
- [ ] Core tests pasan
- [ ] Package.swift de Core actualizado con submodulos
- [ ] Build desde raiz de EduGoModules exitoso
- [ ] Commit de fase realizado
- [ ] Push exitoso

---

## SIGUIENTE PASO

Una vez completada esta fase, actualizar el PLAN_MAESTRO.md con:
1. Marcar FASE 02 como COMPLETADA
2. Registrar fecha, ejecutor y duracion
3. Copiar el RESUMEN DE EJECUCION
4. Actualizar conteo de archivos migrados

Luego proceder a: **[FASE-03-INFRASTRUCTURE.md](./FASE-03-INFRASTRUCTURE.md)**
