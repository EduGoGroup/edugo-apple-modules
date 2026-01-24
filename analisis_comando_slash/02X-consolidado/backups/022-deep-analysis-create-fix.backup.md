---
name: 022-deep-analysis-create-fix
description: Crear fix cuando una task es rechazada (AUTOMÁTICO)
allowed-tools: Task, TodoWrite, MCPSearch, mcp__MCPEco__get_project_info, mcp__MCPEco__execution_session_manage
---

# Deep Analysis: Crear Fix (Automático)

Orquestador para crear fix cuando una task es rechazada. Invocado automáticamente por el orquestador Go.

## 📥 Parámetros (recibidos del orquestador)

Los parámetros vienen como argumentos del comando slash en orden:

**Formato**: `/022-deep-analysis-create-fix <project-id> <flow-id> <parent-flow-row-id> <task-id> <severity-level> <rejection-reason> <rejected-by> [issues-json]`

**Ejemplo**: `/022-deep-analysis-create-fix proj-xxx flow-yyy frow-zzz task-aaa 5 "Tests failing" code_review`

**Parámetros**:
1. `project_id`: ID del proyecto (**NUEVO v3.0 - OBLIGATORIO**)
2. `flow_id`: ID del flow
3. `parent_flow_row_id`: ID del flow_row padre
4. `task_id`: ID de la task rechazada
5. `severity_level`: Nivel de severidad (número)
6. `rejection_reason`: Razón del rechazo (entrecomillado si tiene espacios)
7. `rejected_by`: "code_review" o "qa"
8. `issues_json`: JSON con lista de issues (opcional)

---

## 🔄 Flujo de Ejecución

### FASE -2: Inicializar TODO List

```typescript
await TodoWrite({
  todos: [
    { content: "Cargar herramientas MCP", activeForm: "Cargando herramientas MCP", status: "pending" },
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "pending" },
    { content: "Validar parámetros y obtener proyecto", activeForm: "Validando parámetros y obteniendo proyecto", status: "pending" },
    { content: "Ejecutar sanity check", activeForm: "Ejecutando sanity check", status: "pending" },
    { content: "Validar profundidad de fix", activeForm: "Validando profundidad de fix", status: "pending" },
    { content: "Analizar causa raíz", activeForm: "Analizando causa raíz", status: "pending" },
    { content: "Crear fix", activeForm: "Creando fix", status: "pending" },
    { content: "Finalizar y retornar resultado", activeForm: "Finalizando y retornando resultado", status: "pending" }
  ]
})

console.log("✅ TODO list inicializado con 8 items")
```

---

### FASE -1: Cargar Herramientas MCP

**OBLIGATORIO**: Antes de ejecutar cualquier lógica, cargar TODAS las herramientas MCP requeridas.

```typescript
// ✅ Actualizar TODO: FASE -1 iniciada
await TodoWrite({
  todos: [
    { content: "Cargar herramientas MCP", activeForm: "Cargando herramientas MCP", status: "in_progress" },
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "pending" },
    { content: "Validar parámetros y obtener proyecto", activeForm: "Validando parámetros y obteniendo proyecto", status: "pending" },
    { content: "Ejecutar sanity check", activeForm: "Ejecutando sanity check", status: "pending" },
    { content: "Validar profundidad de fix", activeForm: "Validando profundidad de fix", status: "pending" },
    { content: "Analizar causa raíz", activeForm: "Analizando causa raíz", status: "pending" },
    { content: "Crear fix", activeForm: "Creando fix", status: "pending" },
    { content: "Finalizar y retornar resultado", activeForm: "Finalizando y retornando resultado", status: "pending" }
  ]
})

// Cargar herramientas MCP explícitamente
await MCPSearch({ query: "select:mcp__MCPEco__get_project_info" })
await MCPSearch({ query: "select:mcp__MCPEco__execution_session_manage" })

console.log("✅ Herramientas MCP cargadas correctamente")

// ✅ Actualizar TODO: FASE -1 completada
await TodoWrite({
  todos: [
    { content: "Cargar herramientas MCP", activeForm: "Cargando herramientas MCP", status: "completed" },
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "in_progress" },
    { content: "Validar parámetros y obtener proyecto", activeForm: "Validando parámetros y obteniendo proyecto", status: "pending" },
    { content: "Ejecutar sanity check", activeForm: "Ejecutando sanity check", status: "pending" },
    { content: "Validar profundidad de fix", activeForm: "Validando profundidad de fix", status: "pending" },
    { content: "Analizar causa raíz", activeForm: "Analizando causa raíz", status: "pending" },
    { content: "Crear fix", activeForm: "Creando fix", status: "pending" },
    { content: "Finalizar y retornar resultado", activeForm: "Finalizando y retornando resultado", status: "pending" }
  ]
})
```

### FASE 0: Validar MCP

```typescript
console.log("🔍 FASE 0: Validando disponibilidad del servidor MCP...")

const mcpResult = await Task({
  subagent_type: "mcp-validator",
  description: "Validar MCP",
  prompt: "Valida que el servidor MCP MCPEco esté disponible"
})

if (mcpResult.status !== "ok") {
  console.error("❌ FASE 0: Validación MCP falló - servidor no disponible")
  throw new Error("MCP no disponible")
}

console.log("✅ FASE 0: Servidor MCP validado correctamente")
```

### FASE 1: Validar Parámetros y Obtener Proyecto

```typescript
// Parsear argumentos (vienen como string separados por espacios)
const args = ARGUMENTS?.trim().split(/\s+/)

if (!args || args.length < 7) {
  throw new Error("❌ ERROR: Faltan argumentos obligatorios. Uso: /022 <project-id> <flow-id> <parent-flow-row-id> <task-id> <severity-level> <rejection-reason> <rejected-by> [issues-json]")
}

const [projectId, flowId, parentFlowRowId, taskId, severityLevelStr, rejectionReason, rejectedByRaw, issuesJsonStr] = args

// Validar parámetros obligatorios
if (!projectId) throw new Error("project_id requerido")
if (!flowId) throw new Error("flow_id requerido")
if (!parentFlowRowId) throw new Error("parent_flow_row_id requerido")
if (!taskId) throw new Error("task_id requerido")
if (!rejectedByRaw) throw new Error("rejected_by requerido")

// Parsear severity level
const severityLevel = parseInt(severityLevelStr, 10) || 5

// Normalizar rejected_by
const rejectedBy = rejectedByRaw.toLowerCase().replace("-", "_")
if (!["code_review", "qa"].includes(rejectedBy)) {
  throw new Error("rejected_by debe ser 'code_review' o 'qa'")
}

// Parsear issues JSON (opcional)
let issues = []
if (issuesJsonStr) {
  try {
    issues = JSON.parse(issuesJsonStr)
  } catch (e) {
    console.log(`⚠️ Error parseando issues JSON, continuando con lista vacía: ${e.message}`)
  }
}

// Obtener proyecto por ID (NUEVO v3.0: reemplaza get_active_project)
const project = await mcp__MCPEco__get_project_info({ project_id: projectId })

if (!project || !project.success) {
  throw new Error(`Proyecto no encontrado: ${projectId}`)
}

console.log(`✅ Proyecto: ${project.project_name} (${project.project_level})`)
console.log(`   Parámetros: flow=${flowId}, parent=${parentFlowRowId}, task=${taskId}`)
console.log(`   Rejected by: ${rejectedBy} (severity: ${severityLevel})`)

// ✅ Actualizar TODO: FASE 1 completada
await TodoWrite({
  todos: [
    { content: "Cargar herramientas MCP", activeForm: "Cargando herramientas MCP", status: "completed" },
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Validar parámetros y obtener proyecto", activeForm: "Validando parámetros y obteniendo proyecto", status: "completed" },
    { content: "Ejecutar sanity check", activeForm: "Ejecutando sanity check", status: "in_progress" },
    { content: "Validar profundidad de fix", activeForm: "Validando profundidad de fix", status: "pending" },
    { content: "Analizar causa raíz", activeForm: "Analizando causa raíz", status: "pending" },
    { content: "Crear fix", activeForm: "Creando fix", status: "pending" },
    { content: "Finalizar y retornar resultado", activeForm: "Finalizando y retornando resultado", status: "pending" }
  ]
})
```

### FASE 1.5: Inicializar Sesión de Ejecución

```typescript
let sessionId
let stepId

// Si el proyecto NO tiene sesión previa, crear una nueva
if (!project.last_session_id) {
  console.log("🔧 Creando nueva sesión de ejecución...")

  const sessionResult = await mcp__MCPEco__execution_session_manage({
    action: "start_session",
    command: "022-deep-analysis-create-fix",
    provider: "claude",
    project_id: project.project_id,
    trigger_source: "orchestrator",
    context_metadata: {
      task_id: TASK_ID,
      flow_id: FLOW_ID,
      parent_flow_row_id: PARENT_FLOW_ROW_ID,
      rejected_by: rejectedBy,
      severity_level: SEVERITY_LEVEL
    }
  })

  if (!sessionResult || !sessionResult.session_id) {
    throw new Error("❌ Error creando sesión de ejecución")
  }

  sessionId = sessionResult.session_id
  console.log(`✅ Sesión creada: ${sessionId}`)
} else {
  // Reusar sesión existente
  sessionId = project.last_session_id
  console.log(`♻️ Reusando sesión: ${sessionId}`)
}

// Iniciar nuevo step en la sesión
const stepResult = await mcp__MCPEco__execution_session_manage({
  action: "start_step",
  session_id: sessionId,
  step_name: "create-fix-automatic",
  step_order: 1
})

if (!stepResult || !stepResult.step_id) {
  throw new Error("❌ Error creando step de ejecución")
}

stepId = stepResult.step_id
console.log(`✅ Step iniciado: ${stepId}`)
```

### FASE 2: Sanity Check

await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: "🔍 FASE 2: Ejecutando sanity check para validar necesidad de fix...",
  log_level: "info"
})

const sanityResult = await Task({
  subagent_type: "sanity-check",
  description: "Validar necesidad de fix",
  prompt: JSON.stringify({
    project_path: project?.project_path || ".",
    tech: project?.tech || "golang",
    issues: issues,
    circuit_breaker_data: null
  })
})

if (sanityResult.status === "skip") {
  await mcp__MCPEco__execution_session_manage({
    action: "log",
    step_id: stepId,
    message: `✅ FASE 2: Sanity check completado - Fix no necesario: ${sanityResult.reason}`,
    log_level: "info"
  })
  console.log("ℹ️ Fix no necesario: " + sanityResult.reason)

  // Completar step con metadata de skip
  await mcp__MCPEco__execution_session_manage({
    action: "complete_step",
    step_id: stepId,
    metadata: {
      skipped: true,
      reason: sanityResult.reason
    }
  })

  // Finalizar sesión
  await mcp__MCPEco__execution_session_manage({
    action: "finish_session",
    session_id: sessionId,
    summary: `Fix no necesario según sanity check: ${sanityResult.reason}`
  })

  return JSON.stringify({
    success: true,
    skipped: true,
    reason: sanityResult.reason,
    session_id: sessionId,
    step_id: stepId
  })
}

await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: "✅ FASE 2: Sanity check completado - Fix es necesario, continuando...",
  log_level: "info"
})
```

### FASE 3: Validar Profundidad

```typescript
await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: "🔍 FASE 3: Validando profundidad del fix flow...",
  log_level: "info"
})

const depthResult = await Task({
  subagent_type: "depth-validator",
  description: "Validar profundidad",
  prompt: JSON.stringify({
    parent_flow_row_id: PARENT_FLOW_ROW_ID,
    max_fix_depth: project?.config?.max_alt_flow_depth || 3
  })
})

if (depthResult.status === "exceeded") {
  await mcp__MCPEco__execution_session_manage({
    action: "log",
    step_id: stepId,
    message: `❌ FASE 3: Validación de profundidad falló - profundidad máxima excedida (${depthResult.current_depth}/${depthResult.max_depth})`,
    log_level: "error"
  })
  console.error("❌ Profundidad máxima excedida")

  // Marcar step y sesión como fallidos
  await mcp__MCPEco__execution_session_manage({
    action: "fail",
    session_id: sessionId,
    step_id: stepId,
    error_message: `Profundidad máxima excedida: ${depthResult.current_depth}/${depthResult.max_depth}`
  })

  return JSON.stringify({
    success: false,
    error: "MAX_DEPTH_EXCEEDED",
    current_depth: depthResult.current_depth,
    max_depth: depthResult.max_depth,
    session_id: sessionId,
    step_id: stepId
  })
}

await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `✅ FASE 3: Profundidad validada correctamente (${depthResult.current_depth}/${depthResult.max_depth})`,
  log_level: "info"
})
```

### FASE 4: Analizar Causa Raíz

```typescript
await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `🔍 FASE 4: Analizando causa raíz del rechazo (rechazado por: ${rejectedBy})...`,
  log_level: "info"
})

const rootCauseResult = await Task({
  subagent_type: "root-cause-analyzer",
  description: "Analizar causa raíz",
  prompt: JSON.stringify({
    task_id: TASK_ID,
    rejected_by: rejectedBy,
    rejection_reason: REJECTION_REASON || "",
    severity_level: SEVERITY_LEVEL || 5,
    issues: issues,
    tech: project?.tech || "golang",
    kind: project?.kind || "api"
  })
})

if (!rootCauseResult || rootCauseResult.status !== "success") {
  await mcp__MCPEco__execution_session_manage({
    action: "log",
    step_id: stepId,
    message: `❌ FASE 4: Análisis de causa raíz falló: ${rootCauseResult?.error_message || 'Respuesta inválida'}`,
    log_level: "error"
  })
  throw new Error(`Análisis de causa raíz falló: ${rootCauseResult?.error_message}`)
}

await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: "✅ FASE 4: Análisis de causa raíz completado exitosamente",
  log_level: "info"
})
```

### FASE 5: Crear Fix

```typescript
await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: "🔍 FASE 5: Creando fix flow row basado en análisis de causa raíz...",
  log_level: "info"
})

const fixResult = await Task({
  subagent_type: "fix-creator",
  description: "Crear fix",
  prompt: JSON.stringify({
    flow_id: FLOW_ID,
    parent_flow_row_id: PARENT_FLOW_ROW_ID,
    task_id: TASK_ID,
    rejected_by: rejectedBy,
    current_depth: depthResult.current_depth,
    root_cause_analysis: rootCauseResult.analysis,
    issues: issues
  })
})

if (fixResult.status !== "success") {
  await mcp__MCPEco__execution_session_manage({
    action: "log",
    step_id: stepId,
    message: `❌ FASE 5: Creación de fix falló: ${fixResult.error_message}`,
    log_level: "error"
  })
  throw new Error(fixResult.error_message)
}

await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `✅ FASE 5: Fix creado exitosamente - ${fixResult.fix.fix_name} (profundidad: ${fixResult.fix.depth})`,
  log_level: "info"
})
```

### FASE 6: Finalizar Step y Retornar Resultado

```typescript
console.log("═══════════════════════════════════════════════════════")
console.log("  ✅ FIX CREADO EXITOSAMENTE")
console.log("═══════════════════════════════════════════════════════")
console.log(`🔧 Fix: ${fixResult.fix.fix_name}`)
console.log(`📏 Profundidad: ${fixResult.fix.depth}`)

// Completar step de ejecución
await mcp__MCPEco__execution_session_manage({
  action: "complete_step",
  step_id: stepId,
  metadata: {
    fix_flow_row_id: fixResult.fix.fix_flow_row_id,
    fix_story_id: fixResult.fix.fix_story_id,
    fix_name: fixResult.fix.fix_name,
    depth: fixResult.fix.depth,
    rejected_by: rejectedBy
  }
})

console.log("✅ Step completado correctamente")

// Finalizar sesión
await mcp__MCPEco__execution_session_manage({
  action: "finish_session",
  session_id: sessionId,
  summary: `Fix creado automáticamente: ${fixResult.fix.fix_name} (profundidad: ${fixResult.fix.depth}, rechazado por: ${rejectedBy})`
})

console.log("✅ Sesión finalizada")

return JSON.stringify({
  success: true,
  fix_flow_row_id: fixResult.fix.fix_flow_row_id,
  fix_story_id: fixResult.fix.fix_story_id,
  fix_name: fixResult.fix.fix_name,
  depth: fixResult.fix.depth,
  session_id: sessionId,
  step_id: stepId
}, null, 2)
```

---

## 📋 Agentes Utilizados

| Fase | Agente | Responsabilidad |
|------|--------|-----------------|
| 0 | mcp-validator | Validar MCP |
| 2 | sanity-check | Circuit breaker |
| 3 | depth-validator | Validar profundidad |
| 4 | root-cause-analyzer | Analizar causa raíz |
| 5 | fix-creator | Crear fix |

---

## Changelog

### v3.0.0 (2026-01-17) - project_id Obligatorio + TODO List

**BREAKING CHANGES:**
- ⚠️ **project_id ahora es OBLIGATORIO** (primer argumento)
- ⚠️ **Formato de invocación cambiado**: ahora `/022 <project-id> <flow-id> ...` (antes: `/022 <flow-id> ...`)
- ⚠️ **Eliminado `get_active_project`** - ahora usa `get_project_info`
- ⚠️ **Orquestador Go DEBE actualizarse** para pasar project_id como primer argumento

**Nuevas features:**
- ✅ FASE -2: TODO List con 8 items para visibilidad del progreso
- ✅ TodoWrite y MCPSearch agregados a allowed-tools
- ✅ get_project_info reemplaza get_active_project
- ✅ Parseo robusto de argumentos en FASE 1
- ✅ TODO updates en FASE -1, 1 (fases críticas)

**Formato nuevo**:
```bash
/022-deep-analysis-create-fix <project-id> <flow-id> <parent-flow-row-id> <task-id> <severity-level> <rejection-reason> <rejected-by> [issues-json]
```

**Cambios requeridos en invocadores:**
- Orquestador Go: Debe pasar project_id como PRIMER argumento
- Web UI: Si invoca este comando, debe incluir project_id
- Tests: Actualizar orden de argumentos

**Sin breaking changes para**: Usuario final (comando es interno)

### v2.0 (2026-01-16)
- Session tracking completo
- MCPSearch explícito en FASE -1

---

**Versión**: 3.0.0
**Última actualización**: 2026-01-17
