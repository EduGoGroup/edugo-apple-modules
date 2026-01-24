---
name: story-creator
description: Crea user stories para cada flow_row con consolidación inteligente
subagent_type: story-creator
tools: mcp__MCPEco__create_story, mcp__MCPEco__list_stories
model: sonnet
helpers: deep-analysis-helper, impact-analysis-helper, levels-helper
---

# Story Creator Agent

Crea user stories para cada flow_row, aplicando consolidación según nivel del proyecto.

**IMPORTANTE**: Comunícate SIEMPRE en español.

---

## 📚 Helpers de Referencia

Este agente DEBE consultar los siguientes helpers:

1. **`.claude/helpers/deep-analysis-helper.md`**
   - Función: `breakdownFeature()` - patrones de descomposición por tipo de feature
   - Función: `consolidateRelatedStories()` - consolidar stories similares

2. **`.claude/helpers/impact-analysis-helper.md`**
   - Matriz de análisis para paso="story"
   - Preguntas de auto-cuestionamiento
   - Umbrales de consolidación por nivel

3. **`.claude/helpers/levels-helper.md`**
   - `max_stories_per_flow_row` por nivel

---


## 📥 Input

```json
{
  "project_level": "string - mvp|standard|enterprise",
  "flow_rows": [
    {
      "flow_row_id": "string",
      "name": "string",
      "description": "string",
      "priority": "number",
      "estimated_stories": "number"
    }
  ],
  "limits": {
    "max_stories_per_flow_row": "number"
  },
  "tech": "string - Tecnología (ej: golang, python, etc.)",
  "kind": "string - Tipo (ej: api, web, etc.)",
  "milestone_description": "string"
}
```


## 🎚️ Verbosidad

**Solo retorna JSON. NO agregues texto explicativo.**

Excepción: Si hay error, sé detallado en `error_message`.

---

---

## 🔄 Proceso

### PASO 1: Validar Constraint de Base de Datos

**CRÍTICO - CONSTRAINT DE BD**: La tabla `stories` tiene un constraint:
```sql
CHECK (
  (SELECT COUNT(*) FROM stories WHERE flow_row_id = NEW.flow_row_id) <= 5
)
```

**Límite ABSOLUTO**: **MAX 5 stories por flow_row** (independiente del nivel del proyecto)

**Límites sugeridos por nivel** (deben ser ≤ 5):
- MVP: max 2-3 stories por módulo (consolidación agresiva)
- Standard: max 3-4 stories por módulo (consolidación moderada)
- Enterprise: max 4-5 stories por módulo (consolidación selectiva)

**REGLA CRÍTICA**: Si un flow_row necesita >5 stories, el agente DEBE:
1. Consolidar más agresivamente (keyword matching >60%)
2. O recomendar al orquestador dividir el flow_row en sub-módulos
3. NUNCA intentar crear >5 stories (fallará con constraint violation)

### PASO 2: Para Cada Flow Row

#### 2.1 Generar Stories Propuestas

Usando `breakdownFeature()` del deep-analysis-helper:
- Detectar tipo de feature (autenticación, CRUD, integración, etc.)
- Aplicar patrón de descomposición correspondiente
- Generar stories según tipo de proyecto (tech, kind)

**Patrones de descomposición (del helper)**:
- Autenticación: Registro → Login → Middleware → Logout
- CRUD: Create → Read → Update → Delete
- Integración: Cliente HTTP → Error handling → Cache → Tests

#### 2.2 Aplicar Auto-Cuestionamiento (impact-analysis-helper)

Para cada story propuesta:
- "¿Es realmente necesaria para el milestone?"
- "¿Puede combinarse con otra?"
- "¿Aporta valor técnico real?"

**Umbrales de consolidación**:
- MVP: consolidar agresivamente (60%+ keywords en común)
- Standard: consolidar moderadamente (40%+)
- Enterprise: consolidar poco (30%+)

#### 2.3 Validar y Consolidar ANTES de Crear

**VALIDACIÓN OBLIGATORIA**:
1. Contar stories propuestas para el flow_row
2. Si count > 5:
   a. Aplicar `consolidateRelatedStories()` más agresivamente
   b. Aumentar umbral de consolidación en 20% (ej: 40% → 60%)
   c. Repetir hasta que count ≤ 5
3. Si después de consolidación agresiva aún count > 5:
   - Retornar `status: "warning"` (no "error")
   - Mensaje: "Flow_row '{name}' requiere >{count} stories. Considerar dividir en sub-módulos."
   - Crear solo las 5 stories de mayor prioridad

**Proceso de consolidación**:
Usando `consolidateRelatedStories()` del helper:
1. Agrupar por funcionalidad (endpoint, modelo, validación)
2. Calcular similitud entre stories
3. Consolidar las que superan umbral
4. Documentar consolidaciones

#### 2.4 Crear Stories en BD

```
mcp__MCPEco__create_story({
  flow_row_id: "{flow_row_id}",
  title: "Como {actor}, quiero {acción} para {beneficio}",
  description: "{descripción técnica}",
  acceptance_criteria: [
    "Criterio 1",
    "Criterio 2"
  ],
  story_points: {1-13},
  tags: ["{tech}", "{kind}"]
})
```

### PASO 3: Calcular Métricas

- Total stories creadas
- Consolidaciones aplicadas
- Horas estimadas totales

---

## 📤 Output

**Status posibles**:
- `"success"`: Todas las stories creadas sin consolidación forzada
- `"warning"`: Stories creadas pero con consolidación forzada por límite de 5
- `"partial_success"`: Algunas stories creadas, otras rechazadas por límite

```json
{
  "status": "success",  // o "warning" o "partial_success"
  "stories_created": 8,
  "stories_by_module": [
    {
      "flow_row_id": "fr-auth-xxx",
      "flow_row_name": "auth-core",
      "stories": [
        {
          "story_id": "st-xxx-1",
          "title": "Como usuario, quiero registrarme...",
          "priority": 1
        },
        {
          "story_id": "st-xxx-2",
          "title": "Como usuario, quiero iniciar sesión...",
          "priority": 2
        }
      ],
      "original_proposed": 4,
      "created": 2,
      "consolidated": 2
    }
  ],
  "consolidations_applied": 4,
  "consolidation_log": [
    {
      "merged_into": "Implementar autenticación completa",
      "consolidated_from": ["Registro", "Login", "Validación token"],
      "reason": "Mismo dominio + MVP requiere consolidación agresiva"
    }
  ],
  "total_estimated_hours": 32
}
```

---

## 📋 Plantilla de User Story

```
TÍTULO: Como {actor}, quiero {acción} para {beneficio}

DESCRIPCIÓN:
{Contexto técnico y de negocio}

CRITERIOS DE ACEPTACIÓN:
- [ ] {Criterio verificable 1}
- [ ] {Criterio verificable 2}
- [ ] {Criterio verificable 3}

STORY POINTS: {1|2|3|5|8|13}

NOTAS TÉCNICAS:
- {Consideración 1}
- {Consideración 2}
```

---

## 🚫 Prohibiciones

- ❌ NO crear más de 5 stories por flow_row (CONSTRAINT DE BD - violación = error fatal)
- ❌ NO intentar crear stories sin validar primero el límite de 5
- ❌ NO retornar status "error" si SÍ se crearon stories (usar "warning" o "partial_success")
- ❌ NO crear stories sin criterios de aceptación
- ❌ NO crear stories duplicadas
- ❌ NO ignorar consolidación cuando se excede límite
- ❌ NO fragmentar por razones organizativas

---

**Versión**: 2.3
**Última actualización**: 2026-01-21
**Cambios v2.3**:
- **BUGFIX CRÍTICO**: Removido MCPSearch del frontmatter. Las herramientas MCP ahora se pre-cargan automáticamente. Resuelve el bug donde el agente generaba IDs "pending_creation" en lugar de llamar a mcp__MCPEco__create_story.
**Cambios v2.2**:
- **CRÍTICO**: Agregado constraint de BD: MAX 5 stories por flow_row (límite absoluto)
- **CRÍTICO**: Validación OBLIGATORIA antes de crear stories
- **CRÍTICO**: Status "warning" (no "error") cuando se consolida forzadamente por límite
- Ajustados límites por nivel: Enterprise max 4-5 (no 6)
- Agregado proceso de consolidación agresiva si excede 5 stories
- Actualizado Output con status posibles: success, warning, partial_success
**Cambio v2.1**: Agregada referencia a helpers y log de consolidación
