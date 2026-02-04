# Guia de Uso de Fases

Esta guia explica como utilizar los documentos de fases para planificar la migracion en sesiones de chat independientes.

---

## Concepto General

El plan de migracion esta dividido en **6 fases**, cada una con su propio documento detallado. Esto permite:

1. **Trabajar en sesiones independientes:** Cada fase se puede ejecutar en un chat diferente
2. **Mantener contexto:** El documento centralizado (PLAN_MAESTRO.md) mantiene el estado global
3. **Nivel de detalle uniforme:** Todas las fases tienen el mismo nivel de detalle
4. **Trazabilidad:** Cada fase registra su progreso y problemas encontrados

---

## Estructura de Documentos

```
docs/plan-migracion/
├── PLAN_MAESTRO.md           <- Documento centralizado (leer siempre primero)
├── GUIA_USO_FASES.md         <- Esta guia
├── GUIA_EJECUCION_PLAN.md    <- Como ejecutar el plan de accion
└── fases/
    ├── FASE-01-PREPARACION.md
    ├── FASE-02-FOUNDATION-CORE.md
    ├── FASE-03-INFRASTRUCTURE.md
    ├── FASE-04-DOMAIN.md
    ├── FASE-05-PRESENTATION.md
    └── FASE-06-FEATURES-FINALIZACION.md
```

---

## Como Usar los Documentos

### Paso 1: Leer el Plan Maestro

Antes de cada sesion, leer PLAN_MAESTRO.md para conocer:
- Estado actual de la migracion
- Cual fase esta pendiente
- Resumen de fases anteriores (si las hay)

### Paso 2: Leer la Fase Correspondiente

Abrir el documento de la fase a ejecutar:
- Leer el OBJETIVO DE LA FASE
- Revisar PREREQUISITOS
- Revisar las TAREAS DETALLADAS

### Paso 3: Ejecutar las Tareas

Seguir las tareas en orden. Cada tarea tiene:
- Tiempo estimado
- Pasos detallados con comandos
- Criterio de exito
- Checklist

### Paso 4: Actualizar el Estado

Al completar la fase:
1. Completar el RESUMEN DE EJECUCION en el documento de fase
2. Verificar los CRITERIOS DE SALIDA
3. Actualizar PLAN_MAESTRO.md con el nuevo estado

---

## Iniciando una Nueva Sesion de Chat

### Mensaje para Claude

Cuando inicies un nuevo chat para ejecutar una fase, usa este formato:

```
Estoy ejecutando la migracion del proyecto Apple. 
Necesito que hagas el plan detallado de la FASE [N].

Por favor:
1. Lee el documento: docs/plan-migracion/PLAN_MAESTRO.md
2. Lee el resumen de fases anteriores completadas
3. Lee el documento: docs/plan-migracion/fases/FASE-[N]-[NOMBRE].md
4. Ejecuta las tareas detalladas en orden

El objetivo es completar esta fase y actualizar el documento centralizado.
```

### Ejemplo para FASE 02

```
Estoy ejecutando la migracion del proyecto Apple.
Necesito que hagas el plan detallado de la FASE 02.

Por favor:
1. Lee el documento: docs/plan-migracion/PLAN_MAESTRO.md
2. Lee el resumen de FASE 01 (debe estar completada)
3. Lee el documento: docs/plan-migracion/fases/FASE-02-FOUNDATION-CORE.md
4. Ejecuta las tareas detalladas en orden

El objetivo es migrar Foundation y Core a la nueva estructura.
```

---

## Flujo de Trabajo por Fase

### FASE 01: Preparacion
**Duracion:** 1-2 horas
**Objetivo:** Crear infraestructura base

```
Iniciar chat nuevo
  -> Leer PLAN_MAESTRO.md
  -> Leer FASE-01-PREPARACION.md
  -> Ejecutar tareas 1.1 a 1.9
  -> Actualizar PLAN_MAESTRO.md
Fin chat
```

### FASE 02: Foundation y Core
**Duracion:** 2-3 horas
**Objetivo:** Migrar modulos base

```
Iniciar chat nuevo
  -> Leer PLAN_MAESTRO.md (verificar FASE 01 completada)
  -> Leer FASE-02-FOUNDATION-CORE.md
  -> Ejecutar tareas 2.1 a 2.13
  -> Actualizar PLAN_MAESTRO.md
Fin chat
```

### FASE 03: Infrastructure
**Duracion:** 2-3 horas
**Objetivo:** Migrar Network, Storage, Persistence

```
Iniciar chat nuevo
  -> Leer PLAN_MAESTRO.md (verificar FASE 02 completada)
  -> Leer FASE-03-INFRASTRUCTURE.md
  -> Ejecutar tareas 3.1 a 3.10
  -> Actualizar PLAN_MAESTRO.md
Fin chat
```

### FASE 04: Domain
**Duracion:** 3-4 horas
**Objetivo:** Consolidar logica de negocio

```
Iniciar chat nuevo
  -> Leer PLAN_MAESTRO.md (verificar FASE 03 completada)
  -> Leer FASE-04-DOMAIN.md
  -> Ejecutar tareas 4.1 a 4.13
  -> Actualizar PLAN_MAESTRO.md
Fin chat
```

### FASE 05: Presentation
**Duracion:** 3-4 horas
**Objetivo:** Consolidar capa de UI

```
Iniciar chat nuevo
  -> Leer PLAN_MAESTRO.md (verificar FASE 04 completada)
  -> Leer FASE-05-PRESENTATION.md
  -> Ejecutar tareas 5.1 a 5.15
  -> Actualizar PLAN_MAESTRO.md
Fin chat
```

### FASE 06: Features y Finalizacion
**Duracion:** 3-4 horas
**Objetivo:** Completar migracion

```
Iniciar chat nuevo
  -> Leer PLAN_MAESTRO.md (verificar FASE 05 completada)
  -> Leer FASE-06-FEATURES-FINALIZACION.md
  -> Ejecutar tareas 6.1 a 6.16
  -> Actualizar PLAN_MAESTRO.md con MIGRACION COMPLETADA
Fin chat
```

---

## Manejo de Problemas

### Si una tarea falla

1. **Documentar el error** en la seccion "Problemas encontrados" del documento de fase
2. **Buscar solucion** en la seccion "Resolucion de Problemas Comunes"
3. **Si no hay solucion:**
   - Pausar la fase
   - Documentar estado actual
   - Continuar en siguiente sesion con mas contexto

### Si necesitas pausar

1. Completar la tarea actual
2. Marcar el checklist hasta donde llegaste
3. Documentar en RESUMEN DE EJECUCION:
   ```
   Tareas completadas: 5/13
   Pausado en: TAREA X.Y
   Motivo: [razon]
   Siguiente paso: [que hacer al retomar]
   ```

### Al retomar

1. Leer PLAN_MAESTRO.md
2. Leer documento de fase pausada
3. Ir a RESUMEN DE EJECUCION para ver estado
4. Continuar desde la tarea indicada

---

## Actualizando el Plan Maestro

Despues de cada fase completada, actualizar PLAN_MAESTRO.md:

### 1. Actualizar tabla de fases
```markdown
| Fase | Nombre | Estado | Documento |
|------|--------|--------|-----------|
| 01 | Preparacion e Infraestructura | COMPLETADA | [FASE-01...] |
| 02 | Migracion Foundation y Core | EN_PROGRESO | [FASE-02...] |
```

### 2. Actualizar historial
```markdown
| Fase | Fecha Inicio | Fecha Fin | Ejecutor | Notas |
|------|--------------|-----------|----------|-------|
| 01 | 2026-02-04 | 2026-02-04 | Usuario | Sin problemas |
```

### 3. Actualizar resumen de progreso
```markdown
### FASE 01 - Preparacion
Estado: COMPLETADA
Progreso: 100%
Tareas completadas: 9/9
Problemas encontrados: Ninguno
Resumen ejecucion: Estructura base creada exitosamente
```

---

## Tips para Sesiones Eficientes

1. **Una fase por sesion:** No mezclar fases en el mismo chat
2. **Verificar prerequisitos:** Siempre confirmar que la fase anterior esta completa
3. **Seguir el orden:** Las tareas estan ordenadas por dependencia
4. **No saltarse tareas:** Cada tarea construye sobre la anterior
5. **Documentar todo:** Especialmente problemas y soluciones
6. **Hacer commits frecuentes:** Al menos uno por fase

---

## Preguntas Frecuentes

### Puedo hacer varias fases en una sesion?
Si, pero es recomendable hacer commits entre fases y actualizar el PLAN_MAESTRO.

### Que pasa si encuentro un error no documentado?
Documentalo en el documento de fase y en PLAN_MAESTRO para futuras referencias.

### Puedo modificar las tareas?
Si, pero documenta los cambios. Las tareas son una guia, no una ley.

### Que hago si una fase toma mas tiempo del estimado?
Es normal. Los tiempos son estimados. Lo importante es completar la fase correctamente.

### Puedo ejecutar tareas en paralelo?
Solo si explicitamente se indica en el documento. Por defecto, seguir el orden.
