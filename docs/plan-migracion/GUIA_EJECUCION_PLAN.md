# Guia de Ejecucion del Plan de Accion

Esta guia explica como ejecutar el plan de migracion una vez que las fases de planificacion estan completas.

---

## Resumen del Plan

### Estructura Final Deseada
```
Apple/
└── EduGoModules/
    ├── Packages/
    │   ├── Foundation/     <- TIER-0-Foundation/EduGoCommon
    │   ├── Core/           <- TIER-1-Core/{Logger,Models,Utilities}
    │   ├── Infrastructure/ <- TIER-2-Infrastructure/{Network,Storage,LocalPersistence}
    │   ├── Domain/         <- TIER-2-Domain + TIER-3-Domain
    │   ├── Presentation/   <- TIER-3-Presentation + TIER-3-ViewModels
    │   └── Features/       <- TIER-4-Features/{AI,API,Analytics}
    ├── Apps/
    ├── Documentation/
    ├── Tools/
    └── Package.swift
```

### Orden de Ejecucion
```
FASE 01 -> FASE 02 -> FASE 03 -> FASE 04 -> FASE 05 -> FASE 06
   |          |          |          |          |          |
   v          v          v          v          v          v
Preparar   Migrar     Migrar     Migrar     Migrar     Migrar
Base       F+Core     Infra      Domain     Present    Features
                                                       + Limpiar
```

---

## Antes de Empezar

### Verificar Prerequisitos

1. **Git configurado**
   ```bash
   git --version
   # Debe mostrar version instalada
   ```

2. **Swift 6.2 disponible**
   ```bash
   swift --version
   # Debe mostrar Swift 6.2 o superior
   ```

3. **Xcode instalado**
   ```bash
   xcode-select -p
   # Debe mostrar path a Xcode
   ```

4. **Espacio en disco**
   ```bash
   df -h .
   # Verificar al menos 10GB libres
   ```

5. **Estado limpio del repositorio**
   ```bash
   git status
   # Debe estar limpio o sin cambios criticos
   ```

### Preparar el Entorno

1. **Navegar al directorio del proyecto**
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple
   ```

2. **Verificar que los documentos de planificacion existen**
   ```bash
   ls docs/plan-migracion/
   # Debe mostrar: PLAN_MAESTRO.md, GUIA_*.md, fases/
   ```

3. **Leer el Plan Maestro**
   ```bash
   cat docs/plan-migracion/PLAN_MAESTRO.md
   ```

---

## Ejecutando Fase por Fase

### FASE 01: Preparacion e Infraestructura

**Objetivo:** Crear branch, backup, y estructura de carpetas vacia.

**Tiempo estimado:** 1-2 horas

**Comando para iniciar:**
```bash
# En un nuevo chat de Claude:
"Ejecuta la FASE 01 de la migracion. 
Lee docs/plan-migracion/PLAN_MAESTRO.md y 
docs/plan-migracion/fases/FASE-01-PREPARACION.md"
```

**Verificacion de exito:**
```bash
# Despues de completar FASE 01:
git branch --show-current
# Debe ser: refactor/restructure-for-xcode

ls -la EduGoModules/Packages/
# Debe mostrar: Foundation, Core, Infrastructure, Domain, Presentation, Features

cd EduGoModules && swift build && cd ..
# Debe compilar sin errores
```

**Checkpoint:** Commit y push antes de continuar.

---

### FASE 02: Migracion Foundation y Core

**Objetivo:** Migrar modulos base (sin dependencias internas).

**Tiempo estimado:** 2-3 horas

**Prerequisito:** FASE 01 completada

**Comando para iniciar:**
```bash
# En un nuevo chat de Claude:
"Ejecuta la FASE 02 de la migracion.
La FASE 01 esta completada.
Lee docs/plan-migracion/PLAN_MAESTRO.md y
docs/plan-migracion/fases/FASE-02-FOUNDATION-CORE.md"
```

**Verificacion de exito:**
```bash
# Verificar archivos migrados
find EduGoModules/Packages/Foundation/Sources -name "*.swift" | wc -l
find EduGoModules/Packages/Core/Sources -name "*.swift" | wc -l

# Verificar compilacion
cd EduGoModules/Packages/Foundation && swift build && swift test && cd ../../..
cd EduGoModules/Packages/Core && swift build && swift test && cd ../../..
```

**Checkpoint:** Commit y push antes de continuar.

---

### FASE 03: Migracion Infrastructure

**Objetivo:** Migrar Network, Storage, Persistence.

**Tiempo estimado:** 2-3 horas

**Prerequisito:** FASE 02 completada

**Comando para iniciar:**
```bash
# En un nuevo chat de Claude:
"Ejecuta la FASE 03 de la migracion.
FASE 01 y 02 completadas.
Lee docs/plan-migracion/PLAN_MAESTRO.md y
docs/plan-migracion/fases/FASE-03-INFRASTRUCTURE.md"
```

**Verificacion de exito:**
```bash
# Verificar archivos migrados
find EduGoModules/Packages/Infrastructure/Sources -name "*.swift" | wc -l

# Verificar compilacion
cd EduGoModules/Packages/Infrastructure && swift build && swift test && cd ../../..

# Verificar cadena de dependencias
cd EduGoModules && swift package show-dependencies
# Debe mostrar: Foundation <- Core <- Infrastructure
```

**Checkpoint:** Commit y push antes de continuar.

---

### FASE 04: Migracion Domain

**Objetivo:** Consolidar CQRS, StateManagement, UseCases, Auth, Roles.

**Tiempo estimado:** 3-4 horas

**Prerequisito:** FASE 03 completada

**Comando para iniciar:**
```bash
# En un nuevo chat de Claude:
"Ejecuta la FASE 04 de la migracion.
FASES 01-03 completadas.
Lee docs/plan-migracion/PLAN_MAESTRO.md y
docs/plan-migracion/fases/FASE-04-DOMAIN.md"
```

**Verificacion de exito:**
```bash
# Verificar archivos migrados
find EduGoModules/Packages/Domain/Sources -name "*.swift" | wc -l

# Verificar estructura
ls EduGoModules/Packages/Domain/Sources/
# Debe mostrar: CQRS, StateManagement, UseCases, Services/

# Verificar compilacion
cd EduGoModules/Packages/Domain && swift build && swift test && cd ../../..
```

**Checkpoint:** Commit y push antes de continuar.

---

### FASE 05: Migracion Presentation

**Objetivo:** Consolidar Theme, Effects, UI, Navigation, ViewModels.

**Tiempo estimado:** 3-4 horas

**Prerequisito:** FASE 04 completada

**Comando para iniciar:**
```bash
# En un nuevo chat de Claude:
"Ejecuta la FASE 05 de la migracion.
FASES 01-04 completadas.
Lee docs/plan-migracion/PLAN_MAESTRO.md y
docs/plan-migracion/fases/FASE-05-PRESENTATION.md"
```

**Verificacion de exito:**
```bash
# Verificar archivos migrados (esta es la fase mas grande)
find EduGoModules/Packages/Presentation/Sources -name "*.swift" | wc -l

# Verificar estructura
ls EduGoModules/Packages/Presentation/Sources/
# Debe mostrar: DesignSystem/, Components/, Navigation/, ViewModels/, Utilities/

# Verificar compilacion
cd EduGoModules/Packages/Presentation && swift build && swift test && cd ../../..

# Verificar Xcode Previews (opcional)
open EduGoModules/Package.swift
# Navegar a un componente y verificar que el preview funciona
```

**Checkpoint:** Commit y push antes de continuar.

---

### FASE 06: Migracion Features y Finalizacion

**Objetivo:** Migrar AI, API, Analytics. Configurar Xcode. Limpiar.

**Tiempo estimado:** 3-4 horas

**Prerequisito:** FASE 05 completada

**Comando para iniciar:**
```bash
# En un nuevo chat de Claude:
"Ejecuta la FASE 06 de la migracion.
FASES 01-05 completadas.
Lee docs/plan-migracion/PLAN_MAESTRO.md y
docs/plan-migracion/fases/FASE-06-FEATURES-FINALIZACION.md"
```

**Verificacion de exito:**
```bash
# Verificar compilacion completa
cd EduGoModules && swift build && swift test

# Verificar estructura final
tree EduGoModules -L 2

# Verificar espacio liberado (carpetas .build eliminadas)
du -sh EduGoModules/

# Verificar Xcode workspace
open EduGoModules/EduGoModules.xcworkspace
```

**Checkpoint FINAL:** Commit, push, crear PR.

---

## Comandos Utiles Durante la Ejecucion

### Verificar estado de compilacion
```bash
cd EduGoModules && swift build 2>&1 | grep -i error
```

### Buscar imports rotos
```bash
grep -r "import EduGoCommon" EduGoModules/Packages/
grep -r "import Models" EduGoModules/Packages/ | grep -v "import EduModels"
```

### Contar archivos migrados
```bash
find EduGoModules/Packages -name "*.swift" | wc -l
```

### Ver cadena de dependencias
```bash
cd EduGoModules && swift package show-dependencies
```

### Ejecutar tests especificos
```bash
cd EduGoModules/Packages/Core && swift test --filter CoreTests
```

### Limpiar cache de compilacion
```bash
cd EduGoModules && swift package clean
```

---

## Manejo de Errores Comunes

### Error: "No such module 'X'"

**Causa:** Import no actualizado
**Solucion:**
```bash
# Buscar el import incorrecto
grep -r "import X" EduGoModules/Packages/

# Reemplazar con el nombre correcto
find EduGoModules/Packages -name "*.swift" -exec \
  sed -i '' 's/import X/import EduX/g' {} +
```

### Error: "Cannot find type 'X' in scope"

**Causa:** Tipo no exportado o en modulo diferente
**Solucion:**
1. Verificar que el tipo sea `public`
2. Verificar que el modulo correcto este en dependencies

### Error: Dependencia circular

**Causa:** Modulo A depende de B y B depende de A
**Solucion:**
1. Extraer tipos compartidos a un tercer modulo
2. Usar protocolos para romper la dependencia

### Error: Tests fallan despues de migracion

**Causa:** Imports no actualizados en tests
**Solucion:**
```bash
# Actualizar imports en tests
find EduGoModules/Packages -path "*/Tests/*" -name "*.swift" -exec \
  sed -i '' 's/@testable import OldName/@testable import NewName/g' {} +
```

---

## Rollback de Emergencia

Si algo sale muy mal durante la migracion:

### Opcion 1: Volver al ultimo commit bueno
```bash
git log --oneline -10
# Identificar el commit antes del problema
git reset --hard <commit-hash>
```

### Opcion 2: Volver al backup
```bash
# El backup se creo en FASE 01
ls ~/EduGo-Backups/
# Restaurar si es necesario
```

### Opcion 3: Volver a branch main
```bash
git checkout main
# La estructura antigua sigue intacta
```

---

## Checklist de Finalizacion

Despues de completar todas las fases:

- [ ] Todos los packages compilan sin errores
- [ ] Todos los tests pasan
- [ ] Xcode workspace funciona correctamente
- [ ] Previews funcionan (si aplica)
- [ ] Documentacion actualizada
- [ ] Carpetas .build antiguas eliminadas
- [ ] PLAN_MAESTRO.md actualizado con estado COMPLETADO
- [ ] PR creado y listo para review
- [ ] Equipo notificado de los cambios

---

## Metricas de Exito

Al finalizar, comparar:

| Metrica | Antes | Despues | Mejora |
|---------|-------|---------|--------|
| Carpetas .build | 23 | 1 | -95% |
| Espacio .build | ~6.3GB | ~1.5GB | -75% |
| Niveles profundidad | 6-8 | 3-4 | -50% |
| Tiempo compilacion | ~5-8 min | ~2-3 min | -60% |
| Proxy targets | 8 | 0 | -100% |

---

## Soporte

Si encuentras problemas no documentados:

1. Documentar el problema en el documento de fase
2. Buscar en la seccion "Resolucion de Problemas"
3. Si no hay solucion, documentar para la siguiente persona
4. Considerar pausar y continuar en otra sesion con mas contexto
