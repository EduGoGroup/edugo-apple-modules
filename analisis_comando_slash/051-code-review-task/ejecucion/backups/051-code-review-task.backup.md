---
name: 051-code-review-task
description: Orquestador para ejecutar revisión de código de una tarea del workflow
allowed-tools: Task, TodoWrite, MCPSearch, mcp__MCPEco__get_project_info, mcp__MCPEco__get_flow_info, mcp__MCPEco__get_flow_row, mcp__MCPEco__get_task_details, mcp__MCPEco__execution_session_manage, mcp__MCPEco__create_work_item, mcp__MCPEco__list_work_items
---

# Code Review Task - Orquestador

Orquesta la revisión de código delegando a agentes especializados y manejando el ciclo de **Soft Retry** para correcciones menores.

---

## 📥 Input del Usuario

**Project ID (OBLIGATORIO):** El project_id debe ser pasado como argumento del comando.
**Task ID (OBLIGATORIO):** El task_id debe ser pasado en el prompt.

**Ejemplo**: `/051-code-review-task proj-xxx task-yyy`

**Formato**:
```
$ARGUMENTS = project_id (requerido)
$PROMPT = task_id (requerido)
```

---

## 🎯 Flujo de Orquestación

```
┌─────────────────────────────────────────────────────────────────────────┐
│              051-code-review-task (ORQUESTADOR)                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  FASE 0:  Validar MCP          → common/mcp-validator                  │
│  FASE 1:  Preprocesar input    → Script (PROJECT_ID, TASK_ID)          │
│  FASE 2:  Iniciar Tracking     → MCP directo (start_session)           │
│  FASE 3:  Obtener contexto     → MCP directo (task, flow_row, flow)    │
│  FASE 4:  Crear work_item      → MCP directo (create_work_item)        │
│  FASE 5:  Obtener archivos     → MCP directo (list_work_items)         │
│  FASE 6:  Ciclo Soft Retry     → code-review/decision-maker-agent      │
│           └─ Análisis          → code-review/code-analyzer-agent       │
│           └─ Validación        → implementer/validator-agent           │
│           └─ Severity          → code-review/severity-calculator-agent │
│           └─ Correcciones      → implementer/correction-executor-agent │
│  FASE 7:  Reportar resultados  → code-review/review-reporter-agent     │
│  FASE 8:  Finalizar tracking   → MCP directo (finish_session)          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

**FILOSOFÍA**: El comando orquesta y maneja el ciclo Soft Retry, los agentes ejecutan tareas atómicas.

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
    { content: "Crear work item", activeForm: "Creando work item", status: "pending" },
    { content: "Obtener archivos a revisar", activeForm: "Obteniendo archivos a revisar", status: "pending" },
    { content: "Ciclo de revisión (Soft Retry)", activeForm: "Ejecutando ciclo de revisión", status: "pending" },
    { content: "Reportar resultados", activeForm: "Reportando resultados", status: "pending" },
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
await MCPSearch({ query: "select:mcp__MCPEco__get_task_details" })
await MCPSearch({ query: "select:mcp__MCPEco__execution_session_manage" })
await MCPSearch({ query: "select:mcp__MCPEco__create_work_item" })
await MCPSearch({ query: "select:mcp__MCPEco__list_work_items" })

console.log("✅ Herramientas MCP cargadas correctamente")
console.log("")
```

---

## Variables Globales

```typescript
// Variables de tracking
let SESSION_ID: string | null = null
let CURRENT_STEP_ID: number | null = null

// Variables de contexto (declaradas a nivel de comando para disponibilidad entre fases)
let task: any = null
let flowRow: any = null
let flow: any = null
let project: any = null
let workItem: any = null
let filesToReview: string[] = []

// Variables de resultado
let cycle: number = 0
let finalDecision: string | null = null
let finalSeverity: number = 0
let currentIssues: any[] = []
let correctionCycles: any[] = []
let config: any = null
let threshold: number = 50
let reporterData: any = null
```

---

## Helpers de Tracking

```typescript
async function startStep(stepName: string, stepOrder: number): Promise<void> {
  const result = await mcp__MCPEco__execution_session_manage({
    action: "start_step",
    session_id: SESSION_ID,
    step_name: stepName,
    step_order: stepOrder
  })
  CURRENT_STEP_ID = result.step_id
}

async function logStep(message: string, level: string = "info"): Promise<void> {
  await mcp__MCPEco__execution_session_manage({
    action: "log",
    step_id: CURRENT_STEP_ID,
    message: message,
    level: level
  })
}

async function completeStep(success: boolean = true): Promise<void> {
  await mcp__MCPEco__execution_session_manage({
    action: "complete_step",
    step_id: CURRENT_STEP_ID,
    success: success
  })
}

async function failSession(errorMessage: string): Promise<void> {
  await mcp__MCPEco__execution_session_manage({
    action: "fail",
    session_id: SESSION_ID,
    error_message: errorMessage
  })
}

async function finishSession(summary: string): Promise<void> {
  await mcp__MCPEco__execution_session_manage({
    action: "finish_session",
    session_id: SESSION_ID,
    summary: summary
  })
}
```

---

### FASE 0: Validar MCP

```typescript
console.log("═══════════════════════════════════════════════════════")
console.log("  🔍 CODE REVIEW: REVISAR TAREA")
console.log("═══════════════════════════════════════════════════════")
console.log("")
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
console.log("")

// ✅ ACTUALIZAR TODO: FASE 0 completada
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "in_progress" },
    { content: "Crear work item", activeForm: "Creando work item", status: "pending" },
    { content: "Obtener archivos a revisar", activeForm: "Obteniendo archivos a revisar", status: "pending" },
    { content: "Ciclo de revisión (Soft Retry)", activeForm: "Ejecutando ciclo de revisión", status: "pending" },
    { content: "Reportar resultados", activeForm: "Reportando resultados", status: "pending" },
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
  console.error("💡 Uso: /051-code-review-task <project-id> <task-id>")
  throw new Error("Project ID es OBLIGATORIO")
}

// Obtener task_id (OBLIGATORIO desde PROMPT)
const taskId = PROMPT?.trim()

if (!taskId || taskId === "") {
  console.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  console.error("  ❌ ERROR: Task ID es OBLIGATORIO")
  console.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  console.error("💡 Uso: /051-code-review-task <project-id> <task-id>")
  throw new Error("Task ID es OBLIGATORIO")
}

console.log(`📦 Project ID: ${projectId}`)
console.log(`📋 Task ID: ${taskId}`)
console.log("")
```

---

### FASE 2: Iniciar Tracking

```typescript
console.log("🎬 Iniciando tracking de sesión...")

try {
  const sessionResult = await mcp__MCPEco__execution_session_manage({
    action: "start_session",
    command: "051-code-review-task",
    provider: "claude",
    trigger_source: "cli",
    project_id: projectId  // Siempre presente (obligatorio)
  })
  SESSION_ID = sessionResult.session_id
  console.log(`📊 Session ID: ${SESSION_ID}`)
  console.log("")
} catch (error) {
  console.error("❌ Error iniciando tracking")
  throw new Error("TRACKING_INIT_FAILED")
}
```

---

### FASE 3: Obtener Contexto

```typescript
await startStep("Obtener contexto", 1)
await logStep("🔍 Resolviendo contexto de la task...")

try {
  // 1. Validar y obtener proyecto
  project = await mcp__MCPEco__get_project_info({ project_id: projectId })
  if (!project || !project.success) {
    await completeStep(false)
    await failSession(`Proyecto no encontrado: ${projectId}`)
    throw new Error(`Proyecto no encontrado: ${projectId}`)
  }
  await logStep(`✅ Project: ${project.project_name}`)
  await logStep(`   Tech: ${project.tech} | Kind: ${project.kind}`)
  await logStep(`   Level: ${project.project_level || 'standard'}`)

  // 2. Obtener task
  task = await mcp__MCPEco__get_task_details({ task_id: taskId })
  if (!task || !task.success) {
    await completeStep(false)
    await failSession(`Task no encontrada: ${taskId}`)
    throw new Error(`Task no encontrada: ${taskId}`)
  }
  await logStep(`✅ Task: ${task.task_title}`)
  await logStep(`   Status: ${task.status}`)

  // 3. Obtener flow_row
  flowRow = await mcp__MCPEco__get_flow_row({ flow_row_id: task.flow_row_id })
  if (!flowRow) {
    await completeStep(false)
    await failSession(`Flow row no encontrado: ${task.flow_row_id}`)
    throw new Error(`Flow row no encontrado: ${task.flow_row_id}`)
  }
  await logStep(`✅ Flow Row: ${flowRow.row_name}`)

  // 4. Obtener flow
  flow = await mcp__MCPEco__get_flow_info({ flow_id: flowRow.flow_id })
  if (!flow || !flow.success) {
    await completeStep(false)
    await failSession(`Flow no encontrado: ${flowRow.flow_id}`)
    throw new Error(`Flow no encontrado: ${flowRow.flow_id}`)
  }
  await logStep(`✅ Flow: ${flow.flow_name}`)

  // 5. Validar que la task pertenece al proyecto correcto
  if (flow.project_id !== projectId) {
    const errorMsg = `Task ${taskId} no pertenece al proyecto ${projectId} (pertenece a ${flow.project_id})`
    await completeStep(false)
    await failSession(errorMsg)
    throw new Error(errorMsg)
  }
  await logStep(`✅ Validación: Task pertenece al proyecto correcto`)

  await completeStep(true)

  console.log(`✅ Contexto obtenido: ${project.project_name} / ${flow.flow_name} / ${task.task_title}`)
  console.log("")

} catch (error) {
  console.error(`❌ Error obteniendo contexto: ${error.message}`)
  throw error
}

// ✅ ACTUALIZAR TODO: FASE 3 completada
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "completed" },
    { content: "Crear work item", activeForm: "Creando work item", status: "in_progress" },
    { content: "Obtener archivos a revisar", activeForm: "Obteniendo archivos a revisar", status: "pending" },
    { content: "Ciclo de revisión (Soft Retry)", activeForm: "Ejecutando ciclo de revisión", status: "pending" },
    { content: "Reportar resultados", activeForm: "Reportando resultados", status: "pending" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" }
  ]
})
```

---

### FASE 4: Crear Work Item

```typescript
await startStep("Crear work item", 2)
await logStep("💾 Creando work item para code review...")

try {
  workItem = await mcp__MCPEco__create_work_item({
    flow_row_id: task.flow_row_id,
    step_type: "code_review",
    task_id: taskId
  })
  await logStep(`✅ Work item creado: ${workItem.work_item_id}`)
  await completeStep(true)

  console.log(`✅ Work item creado: ${workItem.work_item_id}`)
  console.log("")

} catch (error) {
  await logStep(`Error: ${error.message}`, "error")
  await completeStep(false)
  await failSession(`FASE 4 falló: ${error.message}`)
  throw error
}

// ✅ ACTUALIZAR TODO: FASE 4 completada
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "completed" },
    { content: "Crear work item", activeForm: "Creando work item", status: "completed" },
    { content: "Obtener archivos a revisar", activeForm: "Obteniendo archivos a revisar", status: "in_progress" },
    { content: "Ciclo de revisión (Soft Retry)", activeForm: "Ejecutando ciclo de revisión", status: "pending" },
    { content: "Reportar resultados", activeForm: "Reportando resultados", status: "pending" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" }
  ]
})
```

---

### FASE 5: Obtener Archivos del Implementer

```typescript
await startStep("Obtener archivos implementados", 3)
await logStep("📄 Obteniendo archivos implementados por el implementer...")

try {
  // Listar work items de la tarea
  const workItemsResponse = await mcp__MCPEco__list_work_items({ task_id: taskId })
  const workItemsList = workItemsResponse.work_items || []

  // Filtrar el más reciente del implementer que esté completado
  const implementerWIs = workItemsList.filter(
    wi => wi.step_type === "implementer" && wi.status === "completed"
  )

  if (implementerWIs.length === 0) {
    throw new Error("No se encontró work item del implementer completado")
  }

  const latestImplWI = implementerWIs[0]
  const filesCreated = latestImplWI.metadata?.files_created || []
  const filesModified = latestImplWI.metadata?.files_modified || []

  // Normalizar a array de strings (pueden venir como objetos con .path o como strings directos)
  filesToReview = [
    ...filesCreated.map(f => typeof f === 'string' ? f : (f.path || f)),
    ...filesModified.map(f => typeof f === 'string' ? f : (f.path || f))
  ]

  await logStep(`✅ Archivos a revisar: ${filesToReview.length}`)
  await completeStep(true)

  console.log(`✅ Archivos obtenidos: ${filesToReview.length}`)
  console.log("")

} catch (error) {
  await logStep(`Error: ${error.message}`, "error")
  await completeStep(false)
  await failSession(`FASE 5 falló: ${error.message}`)
  throw error
}

// ✅ ACTUALIZAR TODO: FASE 5 completada
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "completed" },
    { content: "Crear work item", activeForm: "Creando work item", status: "completed" },
    { content: "Obtener archivos a revisar", activeForm: "Obteniendo archivos a revisar", status: "completed" },
    { content: "Ciclo de revisión (Soft Retry)", activeForm: "Ejecutando ciclo de revisión", status: "in_progress" },
    { content: "Reportar resultados", activeForm: "Reportando resultados", status: "pending" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" }
  ]
})
```

---

### FASE 6: Ciclo de Revisión con Soft Retry

```typescript
await startStep("Ciclo de revisión", 4)

// Configuración de Soft Retry por nivel
// NOTA: Para niveles no listados (startup, enterprise-plus, etc.) se usa "standard" como fallback
const SOFT_RETRY_CONFIG = {
  mvp: { soft_threshold: 25, max_retries: 2 },
  standard: { soft_threshold: 30, max_retries: 2 },
  enterprise: { soft_threshold: 35, max_retries: 3 }
}

const projectLevel = project.config?.project_level || "standard"
config = SOFT_RETRY_CONFIG[projectLevel] || SOFT_RETRY_CONFIG["standard"]
threshold = project.config?.threshold_code_review || 50

await logStep(`Nivel: ${projectLevel}, Threshold: ${threshold}, Soft: ${config.soft_threshold}`)

// ═══════════════════════════════════════════════════════════════════════
// VALIDACIÓN: Si no hay archivos para revisar, aprobar automáticamente
// ═══════════════════════════════════════════════════════════════════════
if (filesToReview.length === 0) {
  await logStep("⚠️ Sin archivos para revisar - aprobando automáticamente", "warn")
  finalDecision = "APPROVE"
  finalSeverity = 0
  currentIssues = []
  cycle = 1
  correctionCycles.push({
    cycle: 1,
    severity: 0,
    issues_count: 0,
    decision: "APPROVE",
    compiles: true,
    tests_pass: true,
    note: "Sin archivos para revisar"
  })
  await completeStep()
  // Continuar a FASE 7 (no hay código que revisar)
} else {
  // Ciclo normal de revisión
  try {
    while (cycle <= config.max_retries) {
      cycle++
      await logStep(`--- Ciclo ${cycle} de ${config.max_retries + 1} ---`)
      
      // 6.1: Analizar código
      await logStep("Analizando código...")
      const analyzerResult = await Task({
        subagent_type: "code-analyzer",
        description: "Analizar archivos",
        prompt: JSON.stringify({
          files_to_review: filesToReview,
          project_path: project.project_path,
          tech: project.tech,
          kind: project.kind,
          project_level: projectLevel
        })
      })
      const analyzerData = JSON.parse(analyzerResult)
      
      if (analyzerData.status === "error") {
        throw new Error(`Analyzer falló: ${analyzerData.error_message}`)
      }
      
      currentIssues = analyzerData.issues || []
      await logStep(`Issues encontrados: ${currentIssues.length}`)
      
      // 6.2: Validar compilación
      await logStep("Validando compilación...")
      const validatorResult = await Task({
        subagent_type: "validator",
        description: "Validar build/tests",
        prompt: JSON.stringify({
          project_path: project.project_path,
          tech: project.tech,
          files_to_validate: filesToReview
        })
      })
      const validatorData = JSON.parse(validatorResult)
      
      if (validatorData.status === "error") {
        throw new Error(`Validator falló: ${validatorData.error_message}`)
      }
      
      const compiles = validatorData.validation?.compiles ?? true
      const testsPass = validatorData.validation?.tests_pass ?? true
      await logStep(`Compila: ${compiles}, Tests: ${testsPass}`)
      
      // 6.3: Calcular severity
      await logStep("Calculando severity...")
      const severityResult = await Task({
        subagent_type: "severity-calculator",
        description: "Calcular severity",
        prompt: JSON.stringify({
          issues: currentIssues,
          project_level: projectLevel,
          threshold_code_review: threshold
        })
      })
      const severityData = JSON.parse(severityResult)
      
      if (severityData.status === "error") {
        throw new Error(`Severity calculator falló: ${severityData.error_message}`)
      }
      
      finalSeverity = severityData.severity || 0
      await logStep(`Severity: ${finalSeverity}/${threshold}`)
      
      // 6.4: Tomar decisión
      await logStep("Evaluando decisión...")
      const decisionResult = await Task({
        subagent_type: "decision-maker",
        description: "Decidir aprobación",
        prompt: JSON.stringify({
          severity: finalSeverity,
          threshold_code_review: threshold,
          soft_threshold: config.soft_threshold,
          current_cycle: cycle,
          max_soft_retries: config.max_retries,
          compiles: compiles,
          tests_pass: testsPass
        })
      })
      const decisionData = JSON.parse(decisionResult)
      
      if (decisionData.status === "error") {
        throw new Error(`Decision maker falló: ${decisionData.error_message}`)
      }
      
      await logStep(`Decisión: ${decisionData.decision} - ${decisionData.reason}`)
      
      // Registrar ciclo
      correctionCycles.push({
        cycle: cycle,
        severity: finalSeverity,
        issues_count: currentIssues.length,
        decision: decisionData.decision,
        compiles: compiles,
        tests_pass: testsPass
      })
      
      // 6.5: Evaluar decisión
      if (decisionData.decision === "APPROVE") {
        finalDecision = "APPROVE"
        await logStep("✅ APROBADO")
        break
      }
      
      if (decisionData.decision === "REJECT") {
        finalDecision = "REJECT"
        await logStep("❌ RECHAZADO")
        break
      }
      
      if (decisionData.decision === "SOFT_RETRY" && cycle <= config.max_retries) {
        await logStep(`🔄 Soft retry ${cycle}/${config.max_retries}...`)
        
        // 6.6: Aplicar correcciones
        const correctionResult = await Task({
          subagent_type: "correction-executor",
          description: "Aplicar correcciones",
          prompt: JSON.stringify({
            project_path: project.project_path,
            tech: project.tech,
            issues_to_fix: currentIssues.map(i => ({
              severity: i.severity,
              category: i.category,
              file: i.file,
              line: i.line,
              message: i.message,
              suggestion: i.suggestion
            }))
          })
        })
        const correctionData = JSON.parse(correctionResult)
        
        if (correctionData.status === "error") {
          throw new Error(`Correction executor falló: ${correctionData.error_message}`)
        }
        
        correctionCycles[correctionCycles.length - 1].correction_applied = true
        correctionCycles[correctionCycles.length - 1].correction_result = {
          success: correctionData.status === "success",
          files_modified: correctionData.files_modified?.length || 0
        }
        
        await logStep(`Correcciones aplicadas: ${correctionData.files_modified?.length || 0} archivos`)
        
        // 6.7: Validar que sigue compilando
        const postCorrValidator = await Task({
          subagent_type: "validator",
          description: "Validar post-corrección",
          prompt: JSON.stringify({
            project_path: project.project_path,
            tech: project.tech,
            files_to_validate: correctionData.files_modified || filesToReview
          })
        })
        const postCorrData = JSON.parse(postCorrValidator)
        
        if (postCorrData.status === "error") {
          throw new Error(`Post-correction validator falló: ${postCorrData.error_message}`)
        }
        
        // ═══════════════════════════════════════════════════════════════════
        // CORRECCIÓN: Si la corrección rompe el build, RECHAZAR directamente
        // No se puede aprobar código que no compila
        // ═══════════════════════════════════════════════════════════════════
        if (!postCorrData.validation?.compiles) {
          await logStep("❌ Corrección rompió el build - RECHAZANDO", "error")
          finalDecision = "REJECT"
          // Recalcular severity con issue de build failure
          const buildFailureIssue = [{
            severity: "critical",
            category: "build_failure",
            file: "project",
            line: 0,
            message: "Build failed after correction attempt",
            suggestion: "Revert corrections and fix manually"
          }]
          const recalcResult = await Task({
            subagent_type: "severity-calculator",
            description: "Recalcular severity por build roto",
            prompt: JSON.stringify({
              issues: [...currentIssues, ...buildFailureIssue],
              project_level: projectLevel,
              threshold_code_review: threshold
            })
          })
          const recalcData = JSON.parse(recalcResult)
          finalSeverity = recalcData.severity || 100
          correctionCycles[correctionCycles.length - 1].build_broken_after_correction = true
          correctionCycles[correctionCycles.length - 1].recalculated_severity = finalSeverity
          break
        }
        
        // Continuar al siguiente ciclo
        continue
      }
      
      // Si llegamos aquí sin decisión, usar severity vs threshold
      // (Este caso ocurre cuando SOFT_RETRY pero ya agotamos los retries)
      finalDecision = finalSeverity <= threshold ? "APPROVE" : "REJECT"
      await logStep(`Decisión por threshold: ${finalDecision}`)
      break
    }
    
    await completeStep(true)

  } catch (error) {
    await logStep(`Error en ciclo: ${error.message}`, "error")
    await completeStep(false)
    await failSession(`FASE 6 falló: ${error.message}`)
    throw error
  }
}

console.log(`✅ Ciclo de revisión completado: ${finalDecision}`)
console.log("")

// ✅ ACTUALIZAR TODO: FASE 6 completada
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "completed" },
    { content: "Crear work item", activeForm: "Creando work item", status: "completed" },
    { content: "Obtener archivos a revisar", activeForm: "Obteniendo archivos a revisar", status: "completed" },
    { content: "Ciclo de revisión (Soft Retry)", activeForm: "Ejecutando ciclo de revisión", status: "completed" },
    { content: "Reportar resultados", activeForm: "Reportando resultados", status: "in_progress" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "pending" }
  ]
})
```

---

### FASE 7: Reportar Resultados

```typescript
await startStep("Reportar resultados", 5)
await logStep("📊 Delegando reporte a review-reporter...")

try {
  const reporterResult = await Task({
    subagent_type: "review-reporter",
    description: "Reportar a BD",
    prompt: JSON.stringify({
      work_item_id: workItem.work_item_id,
      task_id: taskId,
      current_step: "code_review",
      final_decision: finalDecision,
      final_severity: finalSeverity,
      threshold: threshold,
      soft_threshold: config.soft_threshold,
      files_reviewed: filesToReview,
      issues: currentIssues,
      correction_cycles: correctionCycles,
      total_cycles: cycle,
      soft_retries_used: Math.max(0, cycle - 1)
    })
  })
  reporterData = JSON.parse(reporterResult)
  
  if (reporterData.status === "error") {
    throw new Error(reporterData.error_message || "Error desconocido en reporter")
  }
  
  // Validar campos esperados de reporterData
  const evaluationStatus = reporterData.evaluation_status || (finalDecision === "APPROVE" ? "approved" : "rejected")
  const nextStep = reporterData.next_step || null
  const fixFlowRowId = reporterData.fix_flow_row_id || null
  
  await logStep(`✅ Reportado: ${evaluationStatus}`)
  await logStep(`   Next step: ${nextStep || 'unknown'}`)
  await completeStep(true)

  // Normalizar reporterData con valores por defecto
  reporterData = {
    ...reporterData,
    evaluation_status: evaluationStatus,
    next_step: nextStep,
    fix_flow_row_id: fixFlowRowId
  }

  console.log(`✅ Resultados reportados`)
  console.log("")

} catch (error) {
  await logStep(`Error: ${error.message}`, "error")
  await completeStep(false)
  await failSession(`FASE 7 falló: ${error.message}`)
  throw error
}

// ✅ ACTUALIZAR TODO: FASE 7 completada
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "completed" },
    { content: "Crear work item", activeForm: "Creando work item", status: "completed" },
    { content: "Obtener archivos a revisar", activeForm: "Obteniendo archivos a revisar", status: "completed" },
    { content: "Ciclo de revisión (Soft Retry)", activeForm: "Ejecutando ciclo de revisión", status: "completed" },
    { content: "Reportar resultados", activeForm: "Reportando resultados", status: "completed" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "in_progress" }
  ]
})
```

---

### FASE 8: Finalizar Tracking

```typescript
await startStep("Finalizar", 6)

const softRetriesUsed = Math.max(0, cycle - 1)
const taskTitle = task?.task_title || taskId
const summary = finalDecision === "APPROVE"
  ? `Code review aprobado: ${taskTitle} (severity ${finalSeverity}/${threshold}, ${softRetriesUsed} correcciones)`
  : `Code review rechazado: ${taskTitle} (severity ${finalSeverity}/${threshold})`

await finishSession(summary)
await logStep(`✅ ${summary}`)
await completeStep(true)

console.log("✅ Tracking finalizado")
console.log("")

// ✅ ACTUALIZAR TODO: FASE 8 completada
await TodoWrite({
  todos: [
    { content: "Validar MCP disponible", activeForm: "Validando MCP disponible", status: "completed" },
    { content: "Obtener contexto completo", activeForm: "Obteniendo contexto completo", status: "completed" },
    { content: "Crear work item", activeForm: "Creando work item", status: "completed" },
    { content: "Obtener archivos a revisar", activeForm: "Obteniendo archivos a revisar", status: "completed" },
    { content: "Ciclo de revisión (Soft Retry)", activeForm: "Ejecutando ciclo de revisión", status: "completed" },
    { content: "Reportar resultados", activeForm: "Reportando resultados", status: "completed" },
    { content: "Finalizar tracking", activeForm: "Finalizando tracking", status: "completed" }
  ]
})
```

---

---

## Output Final

```typescript
// Imprimir resumen visual
console.log("\n═══════════════════════════════════════════════════════")
if (finalDecision === "APPROVE") {
  console.log("✅ CODE REVIEW APROBADO")
} else {
  console.log("⚠️ CODE REVIEW RECHAZADO")
}
console.log("═══════════════════════════════════════════════════════")
console.log(`📋 Task: ${taskId}`)
console.log(`📝 Work Item: ${workItem?.work_item_id || "N/A"}`)
console.log(`📊 Severity: ${finalSeverity}/${threshold}`)
console.log(`🔄 Ciclos: ${cycle}`)
console.log(`🔧 Soft retries usados: ${softRetriesUsed}`)
if (finalDecision === "APPROVE") {
  console.log(`➡️ Siguiente: ${reporterData?.next_step || "qa"}`)
} else {
  console.log(`🔧 Fix creado: ${reporterData?.fix_flow_row_id || "pendiente"}`)
}
console.log("")

// Retornar JSON estructurado
return JSON.stringify({
  success: true,
  task_id: taskId,
  task_title: task?.task_title || taskId,
  work_item_id: workItem?.work_item_id || null,
  project_id: project?.project_id || null,
  project_name: project?.project_name || null,
  
  decision: finalDecision,
  severity: finalSeverity,
  threshold: threshold,
  soft_threshold: config?.soft_threshold || 30,
  
  cycles_used: cycle,
  soft_retries_used: softRetriesUsed,
  max_soft_retries: config?.max_retries || 2,
  
  evaluation_status: reporterData?.evaluation_status || null,
  next_step: reporterData?.next_step || null,
  fix_flow_row_id: reporterData?.fix_flow_row_id || null,
  
  metrics: {
    files_reviewed: filesToReview.length,
    issues_found: currentIssues.length,
    // Agregación dinámica: cuenta todas las categorías de severity encontradas
    by_severity: currentIssues.reduce((acc, i) => {
      acc[i.severity] = (acc[i.severity] || 0) + 1
      return acc
    }, {}),
    // Mantener campos legacy para compatibilidad
    critical: currentIssues.filter(i => i.severity === "critical").length,
    high: currentIssues.filter(i => i.severity === "high").length,
    medium: currentIssues.filter(i => i.severity === "medium").length,
    low: currentIssues.filter(i => i.severity === "low").length,
    style: currentIssues.filter(i => i.severity === "style").length
  },
  
  correction_history: correctionCycles,
  
  tracking: {
    session_id: SESSION_ID,
    status: "completed"
  },
  
  summary: summary
})
```

---

## Agentes Utilizados

| Agente | Módulo | Responsabilidad |
|--------|--------|-----------------|
| `mcp-validator` | common | Validar disponibilidad del MCP |
| `code-analyzer` | code-review | Analizar código y detectar issues |
| `validator` | implementer | Validar compilación y tests |
| `severity-calculator` | code-review | Calcular severity ponderado |
| `decision-maker` | code-review | Decidir APPROVE/SOFT_RETRY/REJECT |
| `correction-executor` | implementer | Aplicar correcciones (soft retry) |
| `review-reporter` | code-review | Reportar resultados a BD |

---

## Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────────┐
│                    051-code-review-task.md                      │
│                    (Comando Orquestador)                        │
└─────────────────────────────────────────────────────────────────┘
     │
     ├─► FASE 0: mcp-validator
     ├─► FASE 1: Parsear $ARGUMENTS
     ├─► FASE 2: Iniciar Tracking (MCP directo)
     ├─► FASE 3: Obtener Contexto (MCP directo)
     ├─► FASE 4: Crear Work Item (MCP directo)
     ├─► FASE 5: Obtener Archivos Implementer (MCP directo)
     │
     ├─► FASE 6: CICLO SOFT RETRY (el comando controla el loop)
     │       │
     │       ├─► [VALIDACIÓN: Si no hay archivos → APPROVE directo]
     │       │
     │       ├─► code-analyzer → issues[]
     │       ├─► validator → compiles, tests_pass
     │       ├─► severity-calculator → severity
     │       ├─► decision-maker → decision
     │       │
     │       └─► if SOFT_RETRY:
     │              ├─► correction-executor
     │              └─► validator (post-corrección)
     │                  └─► [Si build roto → REJECT directo]
     │
     ├─► FASE 7: review-reporter → update BD
     └─► FASE 8: Finalizar Tracking (MCP directo)
```

---

## Reglas del Comando

1. ✅ **Validar MCP** antes de comenzar
2. ✅ **Iniciar/cerrar tracking** via MCP directo
3. ✅ **Manejar el ciclo de soft retry** (no delegarlo a agente)
4. ✅ **Delegar tareas atómicas** a agentes especializados
5. ✅ **Reportar errores** con tracking adecuado
6. ✅ **Validar archivos disponibles** antes de revisar
7. ✅ **Rechazar si corrección rompe build** (no aprobar código roto)
8. ❌ **NUNCA revisar código** directamente en el comando
9. ❌ **NUNCA calcular severity** directamente en el comando
10. ❌ **NUNCA modificar archivos** directamente en el comando

---

## Changelog

### v2.0.0 (2026-01-17)
- **BREAKING CHANGE**: project_id ahora es OBLIGATORIO (antes era opcional)
- **BREAKING CHANGE**: project_id se pasa en ARGUMENTS, task_id en PROMPT
- **BREAKING CHANGE**: Eliminada lógica de obtener proyecto desde flow (ahora valida primero project_id)
- **ADD**: Agregada FASE -2: TODO List con TodoWrite para visibilidad del progreso
- **ADD**: Agregada FASE -1: Cargar herramientas MCP explícitamente con MCPSearch
- **ADD**: TODO List se actualiza en cada fase completada (FASES 0-8)
- **ADD**: Validación de que task pertenece al proyecto correcto
- **ADD**: Logs mejorados antes de cada delegación a agentes
- **ADD**: Agregados MCPSearch y TodoWrite a allowed-tools
- **FIX**: FASE 8 ahora incluye startStep("Finalizar") y completeStep
- **FIX**: Formato de uso actualizado: `/051-code-review-task <project-id> <task-id>`
- **FIX**: Diagrama de flujo actualizado con FASES -2 y -1
- **FIX**: Manejo de errores mejorado (throw error en lugar de return JSON)

### v1.2.0 (2026-01-16)
- **FIX**: Corregida invocación de mcp-validator (removidos parámetros innecesarios)
- **FIX**: Cambiado `log_level` a `level` en helper logStep (según spec MCP)
- **FIX**: Agregada validación de status="error" a TODAS las respuestas de agentes
- **FIX**: Removido `correction_context` de correction-executor (parámetro no soportado)
- **FIX**: Severity ya no se asigna manualmente (100), se recalcula via severity-calculator
- **ADD**: Agregación dinámica de categorías de severity en metrics (campo `by_severity`)
- **ADD**: Campos legacy mantenidos para compatibilidad retroactiva

### v1.1.0 (2026-01-16)
- **FIX**: Declaración de variables de contexto a nivel de comando (task, project, workItem, etc.)
- **FIX**: Validación de filesToReview vacío al inicio de FASE 6
- **FIX**: Corrección que rompe build ahora RECHAZA directamente (no decide por severity original)
- **FIX**: Validación de campos de reporterData con valores por defecto
- **FIX**: Acceso seguro a propiedades con optional chaining (?.)
- **ADD**: correction_context al invocar correction-executor
- **ADD**: Normalización de formato de archivos (string vs objeto con .path)

### v1.0.0 (2026-01-15)
- Migración inicial desde `LLMs/Claude/.claude/commands/042-code-review-task.md`

---

## Versión

- **Versión**: 2.0.0
- **Migrado desde**: `LLMs/Claude/.claude/commands/042-code-review-task.md`
- **Fecha**: 2026-01-17
