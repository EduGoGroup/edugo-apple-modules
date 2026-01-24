---
name: 031-planner-decompose-story
description: Orquestador para descomponer una story en tasks técnicas atómicas
color: blue
allowed-tools: Task, TodoWrite, mcp__MCPEco__get_project_info, mcp__MCPEco__get_flow_info, mcp__MCPEco__get_flow_row, mcp__MCPEco__get_story, mcp__MCPEco__execution_session_manage
---

# Planner: Descomponer Story

Orquestador que coordina la descomposición de una story en tasks técnicas delegando a agentes especializados.

---

## 📥 Input del Usuario

**Project ID (OBLIGATORIO):** El project_id debe ser pasado como argumento del comando.
**Story ID (OBLIGATORIO):** El story_id debe ser pasado en el prompt.

**Ejemplo**: `/031-planner-decompose-story proj-xxx story-yyy`

**Formato**:
```
$ARGUMENTS = project_id (requerido)
$PROMPT = story_id (requerido)
```

---

## 🎯 Flujo de Orquestación

```
┌─────────────────────────────────────────────────────────────────────────┐
│              031-planner-decompose-story (ORQUESTADOR)                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  FASE 0:  Validar MCP          → common/mcp-validator                  │
│  FASE 1:  Preprocesar input    → Script (STORY_ID, PROJECT_ID)         │
│  FASE 2:  Iniciar Tracking     → MCP directo (start_session)           │
│  FASE 3:  Obtener contexto     → MCP directo (story, flow_row, flow)   │
│  FASE 4:  Buscar documentación → common/search-local                   │
│  FASE 5:  Analizar story       → planner/story-analyzer-agent          │
│  FASE 6:  Crear tasks          → planner/task-creator-agent            │
│  FASE 7:  Finalizar tracking   → MCP directo (finish_session)          │
│  FASE 8:  Retornar resultado   → Script (JSON consolidado)             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de Ejecución

### FASE -2: Inicializar TODO List

**OBLIGATORIO**: Crear TODO list al inicio para dar visibilidad del progreso al usuario.

```typescript
// ✅ CREAR TODO LIST PARA TRACKING VISUAL
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "in_progress" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "pending" },
    { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "pending" },
    { content: "Analizar story y generar plan", activeForm: "Analizando story y generando plan", status: "pending" },
    { content: "Crear tasks en BD", activeForm: "Creando tasks en BD", status: "pending" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" }
  ]
})
```

---

### FASE -1: Cargar Herramientas MCP

**OBLIGATORIO**: Antes de ejecutar cualquier lógica, cargar TODAS las herramientas MCP requeridas.

```typescript
// Cargar herramientas MCP explícitamente
await MCPSearch({ query: "select:mcp__MCPEco__get_project_info" })
await MCPSearch({ query: "select:mcp__MCPEco__get_flow_info" })
await MCPSearch({ query: "select:mcp__MCPEco__get_flow_row" })
await MCPSearch({ query: "select:mcp__MCPEco__get_story" })
await MCPSearch({ query: "select:mcp__MCPEco__execution_session_manage" })

console.log("✅ Herramientas MCP cargadas correctamente")

### FASE 0: Validar MCP Disponible

```typescript
console.log("🔍 Validando MCP...")

const mcpValidation = await Task({
  subagent_type: "mcp-validator",
  description: "Validar servidor MCP",
  prompt: "Valida que el servidor MCP MCPEco esté disponible"
})

if (mcpValidation.status !== "ok") {
  console.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  console.error("  ❌ ERROR CRÍTICO: MCP Server no disponible")
  console.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  console.error(`Sugerencia: ${mcpValidation.suggestion}`)
  throw new Error("MCP Server no disponible")
}

console.log("✅ MCP validado exitosamente")

// ✅ ACTUALIZAR TODO: FASE 0 completada
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "in_progress" },
    { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "pending" },
    { content: "Analizar story y generar plan", activeForm: "Analizando story y generando plan", status: "pending" },
    { content: "Crear tasks en BD", activeForm: "Creando tasks en BD", status: "pending" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" }
  ]
})
```

---

### FASE 1: Preprocesar Input

```typescript
console.log("📋 Procesando input...")

// Obtener project_id (OBLIGATORIO desde ARGUMENTS)
const projectId = ARGUMENTS?.trim()

if (!projectId || projectId === "") {
  console.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  console.error("  ❌ ERROR: Project ID es OBLIGATORIO")
  console.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  console.error("💡 Uso: /031-planner-decompose-story <project-id> <story-id>")
  throw new Error("Project ID es OBLIGATORIO")
}

// Obtener story_id (OBLIGATORIO desde PROMPT)
const storyId = PROMPT?.trim()

if (!storyId || storyId === "") {
  console.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  console.error("  ❌ ERROR: Story ID es OBLIGATORIO")
  console.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  console.error("💡 Uso: /031-planner-decompose-story <project-id> <story-id>")
  throw new Error("Story ID es OBLIGATORIO")
}

console.log(`📦 Project ID: ${projectId}`)
console.log(`📋 Story ID: ${storyId}`)
```

---

### FASE 2: Iniciar Tracking de Ejecución

```typescript
console.log("🎬 Iniciando tracking de sesión...")

let SESSION_ID = null
let CURRENT_STEP_ID = null

const sessionResult = await mcp__MCPEco__execution_session_manage({
  action: "start_session",
  command: "031-planner-decompose-story",
  provider: "claude",
  trigger_source: "cli",
  project_id: projectId  // Siempre presente (obligatorio)
})

SESSION_ID = sessionResult.session_id
console.log(`📊 Session ID: ${SESSION_ID}`)

// Helpers para tracking
async function startStep(stepName, stepOrder) {
  const result = await mcp__MCPEco__execution_session_manage({
    action: "start_step",
    session_id: SESSION_ID,
    step_name: stepName,
    step_order: stepOrder
  })
  CURRENT_STEP_ID = result.step_id
  return result.step_id
}

async function logStep(message, level = "info") {
  await mcp__MCPEco__execution_session_manage({
    action: "log",
    step_id: CURRENT_STEP_ID,
    message: message,
    log_level: level
  })
}

async function completeStep(success = true, errorMessage = null) {
  await mcp__MCPEco__execution_session_manage({
    action: "complete_step",
    step_id: CURRENT_STEP_ID,
    success: success,
    error_message: errorMessage
  })
}
```

---

### FASE 3: Obtener Contexto Completo

```typescript
await startStep("Obtener contexto", 1)
await logStep("🔍 Resolviendo contexto de la story...")

let story = null
let flowRow = null
let flow = null
let project = null

try {
  // 1. Validar y obtener proyecto
  project = await mcp__MCPEco__get_project_info({ project_id: projectId })
  if (!project || !project.success) {
    await completeStep(false, `Proyecto no encontrado: ${projectId}`)
    throw new Error(`Proyecto no encontrado: ${projectId}`)
  }
  await logStep(`✅ Project: ${project.project_name}`)
  await logStep(`   Tech: ${project.tech} | Kind: ${project.kind}`)
  await logStep(`   Level: ${project.project_level || 'standard'}`)

  // 2. Obtener story
  story = await mcp__MCPEco__get_story({ story_id: storyId })
  if (!story || !story.success) {
    await completeStep(false, `Story no encontrada: ${storyId}`)
    throw new Error(`Story no encontrada: ${storyId}`)
  }
  await logStep(`✅ Story: ${story.story_title}`)

  // 3. Obtener flow_row
  flowRow = await mcp__MCPEco__get_flow_row({ flow_row_id: story.flow_row_id })
  if (!flowRow || !flowRow.success) {
    await completeStep(false, `Flow row no encontrado: ${story.flow_row_id}`)
    throw new Error(`Flow row no encontrado: ${story.flow_row_id}`)
  }
  await logStep(`✅ Flow Row: ${flowRow.flow_row_title} (${flowRow.flow_row_type})`)

  // 4. Obtener flow
  flow = await mcp__MCPEco__get_flow_info({ flow_id: flowRow.flow_id })
  if (!flow || !flow.success) {
    await completeStep(false, `Flow no encontrado: ${flowRow.flow_id}`)
    throw new Error(`Flow no encontrado: ${flowRow.flow_id}`)
  }
  await logStep(`✅ Flow: ${flow.flow_name}`)

  // 5. Validar que la story pertenece al proyecto correcto
  if (flow.project_id !== projectId) {
    const errorMsg = `Story ${storyId} no pertenece al proyecto ${projectId} (pertenece a ${flow.project_id})`
    await completeStep(false, errorMsg)
    throw new Error(errorMsg)
  }
  await logStep(`✅ Validación: Story pertenece al proyecto correcto`)

  await completeStep(true)
  
} catch (error) {
  await mcp__MCPEco__execution_session_manage({
    action: "fail",
    session_id: SESSION_ID,
    error_message: error.message
  })
  throw error
}

console.log(`✅ Contexto obtenido: ${project.project_name} / ${flow.flow_name} / ${story.story_title}`)

// ✅ ACTUALIZAR TODO: FASE 3 completada
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "completed" },
    { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "in_progress" },
    { content: "Analizar story y generar plan", activeForm: "Analizando story y generando plan", status: "pending" },
    { content: "Crear tasks en BD", activeForm: "Creando tasks en BD", status: "pending" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" }
  ]
})
```

---

### FASE 4: Buscar Documentación Relevante

```typescript
await startStep("Buscar documentación", 2)
await logStep("🔍 Buscando documentación relevante...")

let relevantDocs = []

try {
  const docsResult = await Task({
    subagent_type: "search-local",
    description: "Buscar documentación",
    prompt: JSON.stringify({
      query: `${project.tech} ${project.kind} ${story.story_title}`,
      step_type: "planner",
      search_method: "semantic",
      top_k: 5,
      min_similarity: 0.3
    })
  })
  
  if (docsResult.status === "success" && docsResult.documents_found > 0) {
    relevantDocs = docsResult.results
    await logStep(`✅ Documentos encontrados: ${relevantDocs.length}`)
  } else {
    await logStep("ℹ️ No se encontraron documentos relevantes")
  }
  
  await completeStep(true)
  
} catch (error) {
  await logStep(`⚠️ Error buscando docs: ${error.message}`, "warn")
  await completeStep(true)  // No es fatal, continuar sin docs
}

// ✅ ACTUALIZAR TODO: FASE 4 completada
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "completed" },
    { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "completed" },
    { content: "Analizar story y generar plan", activeForm: "Analizando story y generando plan", status: "in_progress" },
    { content: "Crear tasks en BD", activeForm: "Creando tasks en BD", status: "pending" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" }
  ]
})
```

---

### FASE 5: Analizar Story y Generar Plan de Tasks

```typescript
await startStep("Analizar story", 3)
await logStep("📊 Analizando story y generando plan de tasks...")

const analysisResult = await Task({
  subagent_type: "story-analyzer",
  description: "Analizar story",
  prompt: JSON.stringify({
    // Datos de la story
    story_id: storyId,
    story_title: story.story_title,
    story_content: story.story_content,
    acceptance_criteria: story.acceptance_criteria || [],
    
    // Contexto del proyecto
    project_level: project.project_level || "standard",
    tech: project.tech,
    kind: project.kind,
    
    // Tipo de story
    flow_row_type: flowRow.flow_row_type,  // feature | fix
    
    // Documentación relevante
    relevant_docs: relevantDocs.map(d => ({
      title: d.title,
      summary: d.summary
    }))
  })
})

if (analysisResult.status !== "success") {
  await completeStep(false, analysisResult.error_message)
  await mcp__MCPEco__execution_session_manage({
    action: "fail",
    session_id: SESSION_ID,
    error_message: analysisResult.error_message
  })
  throw new Error(analysisResult.error_message)
}

// Validar que proposed_tasks exista y sea un array válido
if (!analysisResult.proposed_tasks || !Array.isArray(analysisResult.proposed_tasks)) {
  const errorMsg = "Respuesta inválida del analyzer: proposed_tasks faltante o no es array"
  await completeStep(false, errorMsg)
  await mcp__MCPEco__execution_session_manage({
    action: "fail",
    session_id: SESSION_ID,
    error_message: errorMsg
  })
  throw new Error(errorMsg)
}

if (analysisResult.proposed_tasks.length === 0) {
  const errorMsg = "El analyzer no generó ninguna task para esta story"
  await completeStep(false, errorMsg)
  await mcp__MCPEco__execution_session_manage({
    action: "fail",
    session_id: SESSION_ID,
    error_message: errorMsg
  })
  throw new Error(errorMsg)
}

await logStep(`✅ Tasks propuestas: ${analysisResult.proposed_tasks.length}`)
await logStep(`⏱️ Esfuerzo total: ${analysisResult.total_estimated_hours}h`)
await completeStep(true)

console.log(`✅ Análisis completado: ${analysisResult.proposed_tasks.length} tasks propuestas`)

// ✅ ACTUALIZAR TODO: FASE 5 completada
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "completed" },
    { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "completed" },
    { content: "Analizar story y generar plan", activeForm: "Analizando story y generando plan", status: "completed" },
    { content: "Crear tasks en BD", activeForm: "Creando tasks en BD", status: "in_progress" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" }
  ]
})
```

---

### FASE 6: Crear Tasks en BD

```typescript
await startStep("Crear tasks", 4)
await logStep("💾 Insertando tasks en BD...")

const creatorResult = await Task({
  subagent_type: "task-creator",
  description: "Crear tasks en BD",
  prompt: JSON.stringify({
    story_id: storyId,
    tasks: analysisResult.proposed_tasks
  })
})

// ========================================
// VALIDACIÓN ROBUSTA (Patrón ERROR 7 - comando 025)
// ========================================

// Nivel 1: Validar respuesta no nula
if (!creatorResult) {
  const errorMsg = "task-creator retornó null/undefined"
  await logStep(`❌ ${errorMsg}`, "error")
  await completeStep(false, errorMsg)
  await mcp__MCPEco__execution_session_manage({
    action: "fail",
    session_id: SESSION_ID,
    error_message: errorMsg
  })
  throw new Error(errorMsg)
}

// Nivel 2: Validar status
if (creatorResult.status !== "success") {
  const errorMsg = `task-creator falló: ${creatorResult.error_message || 'Error desconocido'}`
  await logStep(`❌ ${errorMsg}`, "error")
  await completeStep(false, errorMsg)
  await mcp__MCPEco__execution_session_manage({
    action: "fail",
    session_id: SESSION_ID,
    error_message: errorMsg
  })
  throw new Error(errorMsg)
}

// Nivel 3: Validar campo tasks_created existe y es > 0
if (!creatorResult.tasks_created || creatorResult.tasks_created === 0) {
  const errorMsg = `task-creator reportó 0 tasks creadas. Respuesta: ${JSON.stringify(creatorResult).substring(0, 200)}`
  await logStep(`❌ ${errorMsg}`, "error")
  await completeStep(false, errorMsg)
  await mcp__MCPEco__execution_session_manage({
    action: "fail",
    session_id: SESSION_ID,
    error_message: errorMsg
  })
  throw new Error(errorMsg)
}

// Nivel 4: Validar estructura task_ids
if (!creatorResult.task_ids || !Array.isArray(creatorResult.task_ids)) {
  const errorMsg = `task-creator.task_ids no es un array válido. Respuesta: ${JSON.stringify(creatorResult).substring(0, 200)}`
  await logStep(`❌ ${errorMsg}`, "error")
  await completeStep(false, errorMsg)
  await mcp__MCPEco__execution_session_manage({
    action: "fail",
    session_id: SESSION_ID,
    error_message: errorMsg
  })
  throw new Error(errorMsg)
}

// Nivel 5: Validar consistencia de cantidad
if (creatorResult.task_ids.length !== creatorResult.tasks_created) {
  const errorMsg = `Inconsistencia: tasks_created=${creatorResult.tasks_created} pero task_ids.length=${creatorResult.task_ids.length}`
  await logStep(`❌ ${errorMsg}`, "error")
  await completeStep(false, errorMsg)
  await mcp__MCPEco__execution_session_manage({
    action: "fail",
    session_id: SESSION_ID,
    error_message: errorMsg
  })
  throw new Error(errorMsg)
}

// Nivel 6: CRÍTICO - Verificar que la primera task REALMENTE existe en BD
await logStep("🔍 Verificando inserción en BD...")
try {
  const verifyTask = await mcp__MCPEco__get_task_details({
    task_id: creatorResult.task_ids[0]
  })

  if (!verifyTask || !verifyTask.success) {
    const errorMsg = `CRÍTICO: task-creator reportó éxito pero la task ${creatorResult.task_ids[0]} NO existe en BD`
    await logStep(`❌ ${errorMsg}`, "error")
    await completeStep(false, errorMsg)
    await mcp__MCPEco__execution_session_manage({
      action: "fail",
      session_id: SESSION_ID,
      error_message: errorMsg
    })
    throw new Error(errorMsg)
  }

  await logStep(`✅ Verificación BD exitosa: task ${creatorResult.task_ids[0]} existe`)

} catch (error) {
  const errorMsg = `Error verificando tasks en BD: ${error.message}. IDs reportados: ${creatorResult.task_ids.join(", ")}`
  await logStep(`❌ ${errorMsg}`, "error")
  await completeStep(false, errorMsg)
  await mcp__MCPEco__execution_session_manage({
    action: "fail",
    session_id: SESSION_ID,
    error_message: errorMsg
  })
  throw new Error(errorMsg)
}

// ========================================
// FIN VALIDACIÓN ROBUSTA
// ========================================

await logStep(`✅ Tasks creadas: ${creatorResult.tasks_created}`)
await logStep(`🆔 IDs: ${creatorResult.task_ids.join(", ")}`)
await completeStep(true)

console.log(`✅ Tasks creadas: ${creatorResult.tasks_created}`)

// ✅ ACTUALIZAR TODO: FASE 6 completada
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "completed" },
    { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "completed" },
    { content: "Analizar story y generar plan", activeForm: "Analizando story y generando plan", status: "completed" },
    { content: "Crear tasks en BD", activeForm: "Creando tasks en BD", status: "completed" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "in_progress" }
  ]
})
```

---

### FASE 7: Finalizar Tracking

```typescript
await startStep("Finalizar", 5)

const summary = `Story "${story.story_title}" descompuesta en ${creatorResult.tasks_created} tasks (${analysisResult.total_estimated_hours}h total)`

await mcp__MCPEco__execution_session_manage({
  action: "finish_session",
  session_id: SESSION_ID,
  success: true,
  summary: summary
})

await logStep(`✅ ${summary}`)
await completeStep(true)
```

---

### FASE 8: Retornar Resultado Final

```typescript
console.log("")
console.log("═══════════════════════════════════════════════════════")
console.log("  ✅ STORY DESCOMPUESTA EXITOSAMENTE")
console.log("═══════════════════════════════════════════════════════")
console.log("")
console.log(`📋 Story: ${story.story_title}`)
console.log(`📦 Project: ${project.project_name}`)
console.log(`🏃 Sprint: ${flow.flow_name}`)
console.log(`📝 Tasks creadas: ${creatorResult.tasks_created}`)
console.log(`⏱️ Estimación: ${analysisResult.total_estimated_hours}h`)
console.log("")
console.log("📦 Task IDs:")
creatorResult.task_ids.forEach((id, i) => {
  console.log(`   ${i + 1}. ${id}`)
})
console.log("")
console.log(`💡 Siguiente paso: /041-implementer-task <project-id> <task-id>`)
console.log("")

// Retornar JSON estructurado
const result = {
  success: true,
  story_id: storyId,
  story_title: story.story_title,
  project_id: projectId,
  project_name: project.project_name,
  flow_id: flow.flow_id,
  flow_name: flow.flow_name,
  project_level: project.project_level || "standard",
  tasks_created: creatorResult.tasks_created,
  task_ids: creatorResult.task_ids,
  total_estimated_hours: analysisResult.total_estimated_hours,
  analysis: {
    tasks_proposed: analysisResult.proposed_tasks.length,
    validation: analysisResult.validation
  },
  documents_used: relevantDocs.length,
  tracking: {
    session_id: SESSION_ID,
    status: "completed"
  },
  next_steps: [
    `/041-implementer-task ${projectId} ${creatorResult.task_ids[0]}`,
    "/list-tasks (ver todas las tasks)"
  ]
}

return JSON.stringify(result, null, 2)
```

---

## 🚫 Lo que NO Hace Este Comando

1. ❌ NO analiza directamente la story (delega a story-analyzer)
2. ❌ NO crea tasks directamente (delega a task-creator)
3. ❌ NO lee helpers directamente (los agentes los usan internamente)
4. ❌ NO maneja lógica de descomposición compleja

---

## ✅ Lo que SÍ Hace Este Comando

1. ✅ Valida MCP disponible
2. ✅ Obtiene contexto completo (story → flow_row → flow → project)
3. ✅ Maneja tracking de sesiones
4. ✅ Orquesta agentes especializados
5. ✅ Busca documentación relevante
6. ✅ **Valida robustamente** la creación de tasks (6 niveles de validación)
7. ✅ **Verifica en BD** que las tasks realmente existen (no solo confía en el agente)
8. ✅ Maneja errores y rollback
9. ✅ Reporta progreso al usuario
10. ✅ Retorna resultado estructurado

---

## 📋 Agentes Utilizados

| Fase | Agente | Responsabilidad |
|------|--------|-----------------|
| 0 | common/mcp-validator | Validar MCP disponible |
| 4 | common/search-local | Buscar documentación |
| 5 | planner/story-analyzer | Analizar y proponer tasks |
| 6 | planner/task-creator | Insertar tasks en BD |

---

## 📤 Output Esperado

### Caso Éxito
```json
{
  "success": true,
  "story_id": "story-xxx",
  "story_title": "Implementar autenticación JWT",
  "project_id": "proj-xxx",
  "project_name": "Mi API",
  "flow_id": "flow-xxx",
  "flow_name": "Sprint 1",
  "project_level": "mvp",
  "tasks_created": 2,
  "task_ids": ["task-001", "task-002"],
  "total_estimated_hours": 6,
  "analysis": {
    "tasks_proposed": 2,
    "validation": {
      "valid": true,
      "warnings": []
    }
  },
  "documents_used": 2,
  "tracking": {
    "session_id": "sess-xxx",
    "status": "completed"
  },
  "next_steps": [
    "/041-implementer-task proj-xxx task-001",
    "/list-tasks (ver todas las tasks)"
  ]
}
```

### Caso Error
```json
{
  "success": false,
  "error": "Story no encontrada: story-invalid",
  "tracking": {
    "session_id": "sess-xxx",
    "status": "failed"
  }
}
```

---

**Versión**: 3.2
**Última actualización**: 2026-01-22

**Cambios v3.2**:
- **CRÍTICO**: Agregada validación robusta de 6 niveles en FASE 6 (patrón ERROR 7 del comando 025)
  - Nivel 1: Validar respuesta no nula
  - Nivel 2: Validar status === "success"
  - Nivel 3: Validar tasks_created > 0
  - Nivel 4: Validar task_ids es array válido
  - Nivel 5: Validar consistencia tasks_created === task_ids.length
  - **Nivel 6 (NUEVO)**: Verificar que la primera task REALMENTE existe en BD usando `get_task_details`
- **OBJETIVO**: Detectar cuando el agente task-creator reporta éxito pero no insertó nada en BD
- **IMPACTO**: Previene ejecuciones silenciosas que parecen exitosas pero no crean tasks
- **MOTIVACIÓN**: Bug detectado donde task-creator inventaba task_ids sin crear las tasks realmente

**Cambios v3.1**:
- Agregado TODO List con TodoWrite para visibilidad del progreso
- Agregado TodoWrite en allowed-tools
- Actualización del TODO en cada fase completada

**Cambios v3.0**:
- **BREAKING CHANGE**: project_id ahora es OBLIGATORIO (antes era opcional)
- **BREAKING CHANGE**: project_id se pasa en ARGUMENTS, story_id en PROMPT
- Eliminada búsqueda por "proyecto activo"
- Agregada validación de que la story pertenece al proyecto correcto
- Formato de uso actualizado: `/031-planner-decompose-story <project-id> <story-id>`
