# Auditoria PASO 2: Plan de Mejoras

## Comando: 031-planner-decompose-story

### Resumen General
| Metrica | Valor |
|---------|-------|
| Puntaje Comando | 72/100 |
| Puntaje Promedio Agentes | 79/100 |
| Total Mejoras | 28 |
| Tiempo Estimado | 85 minutos |

### Distribucion por Prioridad
| Prioridad | Cantidad | % |
|-----------|----------|---|
| CRITICA | 8 | 28.6% |
| ALTA | 10 | 35.7% |
| MEDIA | 9 | 32.1% |
| BAJA | 1 | 3.6% |

### Top 8 Mejoras Criticas (BLOQUEANTES)

| ID | Archivo | Descripcion |
|----|---------|-------------|
| M001 | comando | Agregar mcp__MCPEco__get_task_details a allowed-tools |
| M002 | comando | Agregar MCPSearch a allowed-tools |
| M003 | comando | Cargar get_task_details con MCPSearch en FASE -1 |
| M004 | comando | Corregir formato markdown de FASE -1 |
| SA001 | story-analyzer-agent | Agregar subagent_type al frontmatter |
| SA002 | story-analyzer-agent | Documentar herramientas permitidas |
| TC001 | task-creator-agent | Agregar subagent_type al frontmatter |
| TC002 | task-creator-agent | Documentar herramientas permitidas |

### Archivos Afectados
1. `.claude/commands/031-planner-decompose-story.md` (10 mejoras)
2. `.claude/agents/common/mcp-validator.md` (4 mejoras)
3. `.claude/agents/common/search-local.md` (2 mejoras)
4. `.claude/agents/planner/story-analyzer-agent.md` (7 mejoras)
5. `.claude/agents/planner/task-creator-agent.md` (5 mejoras)

### Fases de Ejecucion

| Fase | Nombre | Mejoras | Tiempo |
|------|--------|---------|--------|
| 1 | Correcciones Criticas | 8 | 25 min |
| 2 | Alta Prioridad - Comando | 4 | 10 min |
| 3 | Alta Prioridad - Agentes | 6 | 20 min |
| 4 | Media Prioridad - Comando | 2 | 5 min |
| 5 | Media Prioridad - Agentes | 7 | 20 min |
| 6 | Baja Prioridad | 1 | 5 min |

### Riesgos Identificados

1. **BLOQUEANTE**: Comando no ejecuta si allowed-tools incompleto
2. **BLOQUEANTE**: Subagentes no encontrados por paths incorrectos
3. **BLOQUEANTE**: Agentes sin frontmatter correcto rechazados

---

## Proximo Paso

```
/083-audit-step3-execute 031-planner-decompose-story
```

Aplica las mejoras planificadas en este paso.
