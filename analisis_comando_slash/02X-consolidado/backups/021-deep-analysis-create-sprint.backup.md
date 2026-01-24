---
name: 021-deep-analysis-create-sprint
description: Crear sprint con análisis profundo del proyecto
allowed-tools: Task, TodoWrite, MCPSearch, mcp__MCPEco__get_project_info, mcp__MCPEco__execution_session_manage, mcp__MCPEco__list_flows
---

# Deep Analysis: Crear Sprint

Orquestador que coordina la creación de un sprint completo.

## 📥 Input

**Project ID (OBLIGATORIO):** El project_id debe ser pasado como argumento del comando.
**Descripción del Sprint (opcional):** Prompt adicional con descripción del milestone/sprint.

**Ejemplo**: `/021-deep-analysis-create-sprint proj-1768611555348527000`

---

## 🔄 Flujo de Ejecución

### FASE -2: Inicializar TODO List

**OBLIGATORIO**: Crear TODO list al inicio para dar visibilidad del progreso al usuario.

```typescript
await TodoWrite({
  todos: [
    { content: "Cargar herramientas MCP", activeForm: "Cargando herramientas MCP", status: "pending" },
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "pending" },
    { content: "Obtener y validar proyecto", activeForm: "Obteniendo y validando proyecto", status: "pending" },
    { content: "Analizar milestone del sprint", activeForm: "Analizando milestone del sprint", status: "pending" },
    { content: "Crear flow (sprint)", activeForm: "Creando flow (sprint)", status: "pending" },
    { content: "Filtrar módulos por límites", activeForm: "Filtrando módulos por límites", status: "pending" },
    { content: "Crear flow_rows en BD", activeForm: "Creando flow_rows en BD", status: "pending" },
    { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "pending" },
    { content: "Crear stories", activeForm: "Creando stories", status: "pending" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" },
    { content: "Retornar resultado", activeForm: "Retornando resultado", status: "pending" }
  ]
})

console.log("✅ TODO list inicializado con 11 items")
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
    { content: "Obtener y validar proyecto", activeForm: "Obteniendo y validando proyecto", status: "pending" },
    { content: "Analizar milestone del sprint", activeForm: "Analizando milestone del sprint", status: "pending" },
    { content: "Crear flow (sprint)", activeForm: "Creando flow (sprint)", status: "pending" },
    { content: "Filtrar módulos por límites", activeForm: "Filtrando módulos por límites", status: "pending" },
    { content: "Crear flow_rows en BD", activeForm: "Creando flow_rows en BD", status: "pending" },
    { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "pending" },
    { content: "Crear stories", activeForm: "Creando stories", status: "pending" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" },
    { content: "Retornar resultado", activeForm: "Retornando resultado", status: "pending" }
  ]
})

// Cargar herramientas MCP explícitamente
await MCPSearch({ query: "select:mcp__MCPEco__get_project_info" })
await MCPSearch({ query: "select:mcp__MCPEco__execution_session_manage" })
await MCPSearch({ query: "select:mcp__MCPEco__list_flows" })

console.log("✅ Herramientas MCP cargadas correctamente")

// ✅ Actualizar TODO: FASE -1 completada
await TodoWrite({
  todos: [
    { content: "Cargar herramientas MCP", activeForm: "Cargando herramientas MCP", status: "completed" },
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "in_progress" },
    { content: "Obtener y validar proyecto", activeForm: "Obteniendo y validando proyecto", status: "pending" },
    { content: "Analizar milestone del sprint", activeForm: "Analizando milestone del sprint", status: "pending" },
    { content: "Crear flow (sprint)", activeForm: "Creando flow (sprint)", status: "pending" },
    { content: "Filtrar módulos por límites", activeForm: "Filtrando módulos por límites", status: "pending" },
    { content: "Crear flow_rows en BD", activeForm: "Creando flow_rows en BD", status: "pending" },
    { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "pending" },
    { content: "Crear stories", activeForm: "Creando stories", status: "pending" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" },
    { content: "Retornar resultado", activeForm: "Retornando resultado", status: "pending" }
  ]
})
```

### FASE 0: Validar MCP

```typescript
const mcpResult = await Task({
  subagent_type: "mcp-validator",
  description: "Validar MCP",
  prompt: "Valida que el servidor MCP MCPEco esté disponible"
})

if (mcpResult.status !== "ok") {
  // ✅ Actualizar TODO: Error - marcar todo como completado
  await TodoWrite({
    todos: [
      { content: "Cargar herramientas MCP", activeForm: "Cargando herramientas MCP", status: "completed" },
      { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
      { content: "Obtener y validar proyecto", activeForm: "Obteniendo y validando proyecto", status: "completed" },
      { content: "Analizar milestone del sprint", activeForm: "Analizando milestone del sprint", status: "completed" },
      { content: "Crear flow (sprint)", activeForm: "Creando flow (sprint)", status: "completed" },
      { content: "Filtrar módulos por límites", activeForm: "Filtrando módulos por límites", status: "completed" },
      { content: "Crear flow_rows en BD", activeForm: "Creando flow_rows en BD", status: "completed" },
      { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "completed" },
      { content: "Crear stories", activeForm: "Creando stories", status: "completed" },
      { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "completed" },
      { content: "Retornar resultado", activeForm: "Retornando resultado", status: "completed" }
    ]
  })

  throw new Error("MCP no disponible: " + mcpResult.error_message)
}

console.log("✅ FASE 0: MCP validado correctamente")

// ✅ Actualizar TODO: FASE 0 completada
await TodoWrite({
  todos: [
    { content: "Cargar herramientas MCP", activeForm: "Cargando herramientas MCP", status: "completed" },
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener y validar proyecto", activeForm: "Obteniendo y validando proyecto", status: "in_progress" },
    { content: "Analizar milestone del sprint", activeForm: "Analizando milestone del sprint", status: "pending" },
    { content: "Crear flow (sprint)", activeForm: "Creando flow (sprint)", status: "pending" },
    { content: "Filtrar módulos por límites", activeForm: "Filtrando módulos por límites", status: "pending" },
    { content: "Crear flow_rows en BD", activeForm: "Creando flow_rows en BD", status: "pending" },
    { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "pending" },
    { content: "Crear stories", activeForm: "Creando stories", status: "pending" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" },
    { content: "Retornar resultado", activeForm: "Retornando resultado", status: "pending" }
  ]
})
```

### FASE 1: Obtener Proyecto y Validar

```typescript
// Parsear argumentos (command-args viene como string)
const args = context.commandArgs?.trim()

if (!args) {
  // ✅ Actualizar TODO: Error
  await TodoWrite({
    todos: [
      { content: "Cargar herramientas MCP", activeForm: "Cargando herramientas MCP", status: "completed" },
      { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
      { content: "Obtener y validar proyecto", activeForm: "Obteniendo y validando proyecto", status: "completed" },
      { content: "Analizar milestone del sprint", activeForm: "Analizando milestone del sprint", status: "completed" },
      { content: "Crear flow (sprint)", activeForm: "Creando flow (sprint)", status: "completed" },
      { content: "Filtrar módulos por límites", activeForm: "Filtrando módulos por límites", status: "completed" },
      { content: "Crear flow_rows en BD", activeForm: "Creando flow_rows en BD", status: "completed" },
      { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "completed" },
      { content: "Crear stories", activeForm: "Creando stories", status: "completed" },
      { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "completed" },
      { content: "Retornar resultado", activeForm: "Retornando resultado", status: "completed" }
    ]
  })

  throw new Error("❌ ERROR: project_id es OBLIGATORIO. Uso: /021-deep-analysis-create-sprint <project_id>")
}

const projectId = args

// Obtener información del proyecto (incluye last_session_id)
const project = await mcp__MCPEco__get_project_info({ project_id: projectId })

if (!project || !project.success) {
  // ✅ Actualizar TODO: Error
  await TodoWrite({
    todos: [
      { content: "Cargar herramientas MCP", activeForm: "Cargando herramientas MCP", status: "completed" },
      { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
      { content: "Obtener y validar proyecto", activeForm: "Obteniendo y validando proyecto", status: "completed" },
      { content: "Analizar milestone del sprint", activeForm: "Analizando milestone del sprint", status: "completed" },
      { content: "Crear flow (sprint)", activeForm: "Creando flow (sprint)", status: "completed" },
      { content: "Filtrar módulos por límites", activeForm: "Filtrando módulos por límites", status: "completed" },
      { content: "Crear flow_rows en BD", activeForm: "Creando flow_rows en BD", status: "completed" },
      { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "completed" },
      { content: "Crear stories", activeForm: "Creando stories", status: "completed" },
      { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "completed" },
      { content: "Retornar resultado", activeForm: "Retornando resultado", status: "completed" }
    ]
  })

  throw new Error(`❌ Proyecto no encontrado: ${projectId}`)
}

console.log(`✅ Proyecto: ${project.project_name} (${project.project_level})`)

const milestoneDescription = context.prompt?.trim() || `Sprint para proyecto ${project.project_name}`

// ✅ Actualizar TODO: FASE 1 completada
await TodoWrite({
  todos: [
    { content: "Cargar herramientas MCP", activeForm: "Cargando herramientas MCP", status: "completed" },
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener y validar proyecto", activeForm: "Obteniendo y validando proyecto", status: "completed" },
    { content: "Analizar milestone del sprint", activeForm: "Analizando milestone del sprint", status: "in_progress" },
    { content: "Crear flow (sprint)", activeForm: "Creando flow (sprint)", status: "pending" },
    { content: "Filtrar módulos por límites", activeForm: "Filtrando módulos por límites", status: "pending" },
    { content: "Crear flow_rows en BD", activeForm: "Creando flow_rows en BD", status: "pending" },
    { content: "Buscar documentación relevante", activeForm: "Buscando documentación relevante", status: "pending" },
    { content: "Crear stories", activeForm: "Creando stories", status: "pending" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" },
    { content: "Retornar resultado", activeForm: "Retornando resultado", status: "pending" }
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
    command: "021-deep-analysis-create-sprint",
    provider: "claude",
    project_id: projectId,
    trigger_source: "cli",
    context_metadata: {
      project_level: project.project_level,
      tech: project.tech,
      kind: project.kind,
      milestone_description: milestoneDescription
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
  step_name: "create-sprint",
  step_order: 1
})

if (!stepResult || !stepResult.step_id) {
  throw new Error("❌ Error creando step de ejecución")
}

stepId = stepResult.step_id
console.log(`✅ Step iniciado: ${stepId}`)
```

### FASE 2: Analizar Milestone

```typescript
await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: "🔍 FASE 2: Iniciando análisis del milestone del sprint...",
  log_level: "info"
})

const analysisResult = await Task({
  subagent_type: "milestone-analyzer",
  description: "Analizar milestone",
  prompt: JSON.stringify({
    milestone_description: milestoneDescription,
    tech: project.tech,
    kind: project.kind,
    project_level: project.project_level || "standard",
    project_path: project.project_path,
    project_name: project.project_name
  })
})

if (!analysisResult || analysisResult.status !== "success") {
  await mcp__MCPEco__execution_session_manage({
    action: "log",
    step_id: stepId,
    message: `❌ FASE 2: Milestone Analyzer falló: ${analysisResult?.error_message || 'Respuesta inválida'}`,
    log_level: "error"
  })
  throw new Error(`Milestone Analyzer falló: ${analysisResult?.error_message}`)
}

await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `✅ FASE 2: Análisis de milestone completado exitosamente`,
  log_level: "info"
})
```

### FASE 3: Crear Flow (Sprint)

```typescript
const existingFlows = await mcp__MCPEco__list_flows({ project_id: project.project_id })
const currentSprintCount = existingFlows?.flows?.length || 0

await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `🔍 FASE 3: Creando flow (sprint #${currentSprintCount + 1})...`,
  log_level: "info"
})

const flowResult = await Task({
  subagent_type: "flow-creator",
  description: "Crear flow",
  prompt: JSON.stringify({
    project_id: project.project_id,
    project_level: project.project_level || "standard",
    current_sprint_count: currentSprintCount,
    limits: project.config?.limits || {},
    milestone_analysis: analysisResult.analysis
  })
})

if (!flowResult || flowResult.status !== "success") {
  await mcp__MCPEco__execution_session_manage({
    action: "log",
    step_id: stepId,
    message: `❌ FASE 3: Flow Creator falló: ${flowResult?.error_message || 'Respuesta inválida'}`,
    log_level: "error"
  })
  throw new Error(`Flow Creator falló: ${flowResult?.error_message}`)
}

await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `✅ FASE 3: Flow creado exitosamente: ${flowResult.flow.flow_name}`,
  log_level: "info"
})
```

### FASE 4: Filtrar Módulos

```typescript
await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `🔍 FASE 4: Filtrando módulos según límites del proyecto (${analysisResult.analysis.proposed_modules?.length || 0} propuestos)...`,
  log_level: "info"
})

const filterResult = await Task({
  subagent_type: "impact-filter",
  description: "Filtrar módulos",
  prompt: JSON.stringify({
    project_level: project.project_level || "standard",
    proposed_modules: analysisResult.analysis.proposed_modules,
    limits: project.config?.limits || {},
    milestone_description: milestoneDescription
  })
})

if (!filterResult || filterResult.status !== "success") {
  await mcp__MCPEco__execution_session_manage({
    action: "log",
    step_id: stepId,
    message: `❌ FASE 4: Impact Filter falló: ${filterResult?.error_message || 'Respuesta inválida'}`,
    log_level: "error"
  })
  throw new Error(`Impact Filter falló: ${filterResult?.error_message}`)
}

await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `✅ FASE 4: Filtrado completado: ${filterResult.filtering_result?.approved_modules?.length || 0} módulos aprobados`,
  log_level: "info"
})
```

### FASE 5: Crear Flow Rows

```typescript
await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `🔍 FASE 5: Creando flow_rows para ${filterResult.filtering_result?.approved_modules?.length || 0} módulos aprobados...`,
  log_level: "info"
})

const moduleResult = await Task({
  subagent_type: "module-creator",
  description: "Crear flow_rows",
  prompt: JSON.stringify({
    flow_id: flowResult.flow.flow_id,
    approved_modules: filterResult.filtering_result.approved_modules,
    global_risks: analysisResult.analysis.global_risks || [],
    global_dependencies: analysisResult.analysis.global_dependencies || [],
    tech: project.tech,
    kind: project.kind
  })
})

if (!moduleResult || moduleResult.status !== "success") {
  await mcp__MCPEco__execution_session_manage({
    action: "log",
    step_id: stepId,
    message: `❌ FASE 5: Module Creator falló: ${moduleResult?.error_message || 'Respuesta inválida'}`,
    log_level: "error"
  })
  throw new Error(`Module Creator falló: ${moduleResult?.error_message}`)
}

await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `✅ FASE 5: Flow_rows creados exitosamente: ${moduleResult.total_created || 0} módulos`,
  log_level: "info"
})
```

### FASE 6: Buscar Documentos

```typescript
await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `🔍 FASE 6: Buscando documentación relevante (${project.tech} ${project.kind})...`,
  log_level: "info"
})

const docsResult = await Task({
  subagent_type: "search-local",
  description: "Buscar documentación",
  prompt: JSON.stringify({
    query: `${project.tech} ${project.kind} ${milestoneDescription}`,
    search_method: "semantic",
    top_k: 5,
    min_similarity: 0.3
  })
})

if (!docsResult || docsResult.status !== "success") {
  await mcp__MCPEco__execution_session_manage({
    action: "log",
    step_id: stepId,
    message: `❌ FASE 6: Search Local falló: ${docsResult?.error_message || 'Respuesta inválida'}`,
    log_level: "error"
  })
  throw new Error(`Search Local falló: ${docsResult?.error_message}`)
}

await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `✅ FASE 6: Búsqueda completada: ${docsResult.documents_found || 0} documentos encontrados`,
  log_level: "info"
})
```

### FASE 7: Crear Stories

```typescript
await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `🔍 FASE 7: Creando stories para ${moduleResult.flow_rows_created?.length || 0} flow_rows...`,
  log_level: "info"
})

const storyResult = await Task({
  subagent_type: "story-creator",
  description: "Crear stories",
  prompt: JSON.stringify({
    project_level: project.project_level || "standard",
    flow_rows: moduleResult.flow_rows_created,
    limits: project.config?.limits || {},
    tech: project.tech,
    kind: project.kind,
    milestone_description: milestoneDescription
  })
})

if (!storyResult || storyResult.status !== "success") {
  await mcp__MCPEco__execution_session_manage({
    action: "log",
    step_id: stepId,
    message: `❌ FASE 7: Story Creator falló: ${storyResult?.error_message || 'Respuesta inválida'}`,
    log_level: "error"
  })
  throw new Error(`Story Creator falló: ${storyResult?.error_message}`)
}

await mcp__MCPEco__execution_session_manage({
  action: "log",
  step_id: stepId,
  message: `✅ FASE 7: Stories creadas exitosamente: ${storyResult.stories_created || 0} stories (${storyResult.total_estimated_hours || 0}h estimadas)`,
  log_level: "info"
})
```

### FASE 8: Finalizar Step y Retornar Resultado

```typescript
console.log("═══════════════════════════════════════════════════════")
console.log("  ✅ SPRINT CREADO EXITOSAMENTE")
console.log("═══════════════════════════════════════════════════════")
console.log(`📋 Proyecto: ${project.project_name}`)
console.log(`🏃 Sprint: ${flowResult.flow.flow_name}`)
console.log(`📦 Módulos: ${moduleResult.total_created}`)
console.log(`📝 Stories: ${storyResult.stories_created}`)
console.log(`⏱️ Estimación: ${storyResult.total_estimated_hours}h`)

// Completar step de ejecución
await mcp__MCPEco__execution_session_manage({
  action: "complete_step",
  step_id: stepId,
  metadata: {
    flow_id: flowResult.flow.flow_id,
    flow_name: flowResult.flow.flow_name,
    modules_created: moduleResult.total_created,
    stories_created: storyResult.stories_created,
    estimated_hours: storyResult.total_estimated_hours
  }
})

console.log("✅ Step completado correctamente")

// Finalizar sesión
await mcp__MCPEco__execution_session_manage({
  action: "finish_session",
  session_id: sessionId,
  summary: `Sprint '${flowResult.flow.flow_name}' creado: ${moduleResult.total_created} módulos, ${storyResult.stories_created} stories (${storyResult.total_estimated_hours}h estimadas)`
})

console.log("✅ Sesión finalizada")
console.log("")
console.log("💡 Siguiente: /031-planner-decompose-story <story-id>")

return JSON.stringify({
  success: true,
  project_id: project.project_id,
  session_id: sessionId,
  step_id: stepId,
  flow_id: flowResult.flow.flow_id,
  flow_name: flowResult.flow.flow_name,
  modules_created: moduleResult.total_created,
  stories_created: storyResult.stories_created,
  estimated_hours: storyResult.total_estimated_hours
}, null, 2)
```

---

## 📋 Agentes Utilizados

| Fase | Agente | Responsabilidad |
|------|--------|-----------------|
| 0 | mcp-validator | Validar MCP |
| 2 | milestone-analyzer | Analizar milestone |
| 3 | flow-creator | Crear sprint |
| 4 | impact-filter | Filtrar módulos |
| 5 | module-creator | Crear flow_rows |
| 6 | search-local | Buscar docs |
| 7 | story-creator | Crear stories |

---

## Changelog

### v2.1.0 (2026-01-17) - TODO List Integration

**Nuevas features:**
- ✅ FASE -2: TODO List con 11 items para visibilidad del progreso
- ✅ TodoWrite y MCPSearch agregados a allowed-tools
- ✅ TODO updates en FASE -1, 0, 1 (fases críticas)
- ✅ TODO updates en early exits de FASE 0 y 1

**Patrón para fases restantes (1.5-8)**:
Cada fase debe actualizar TODO al final con patrón:
```typescript
// Al final de cada FASE X exitosa
await TodoWrite({ todos: [
  // Fases 0 a X-1: status="completed"
  // Fase X: status="completed"
  // Fase X+1: status="in_progress"
  // Fases X+2 en adelante: status="pending"
]})
```

**Sin breaking changes**

### v2.0 (2026-01-16)
- project_id OBLIGATORIO
- Formato: `/021 <project-id> [milestone-description]`
- Session tracking completo
- MCPSearch explícito en FASE -1

---

**Versión**: 2.1.0
**Última actualización**: 2026-01-17
