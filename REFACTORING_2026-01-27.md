# Refactorización: Estructura Modular y Desacoplamiento

**Fecha:** 2026-01-27
**Autor:** Sistema Automatizado
**Proyecto:** EduGo Apple Modules (proj-1768943256031988000)

---

## Resumen Ejecutivo

Se realizaron dos refactorizaciones críticas para mejorar la arquitectura modular del proyecto:

1. **Consolidación de estructura de carpetas**: Movimiento de archivos duplicados de `Sources/` raíz a `TIER-0-Foundation/EduGoCommon/`
2. **Desacoplamiento Roles ← Auth**: Eliminación de dependencia cross-tier mediante introducción de `UserContextProtocol`

---

## 1. Consolidación de Estructura de Carpetas

### Problema Detectado

Existía una inconsistencia estructural donde algunos archivos de `EduGoCommon` estaban en la raíz del proyecto en lugar de dentro de `TIER-0-Foundation/EduGoCommon/`:

```
❌ ANTES:
Apple/
├── Sources/
│   └── EduGoCommon/
│       ├── Domain/Entity.swift          (duplicado)
│       └── Errors/
│           ├── DomainError.swift        (fuera de lugar)
│           ├── UseCaseError.swift       (fuera de lugar)
│           └── RepositoryError.swift    (fuera de lugar)
├── Tests/
│   └── EduGoCommonTests/
│       └── Errors/
│           ├── DomainErrorTests.swift   (fuera de lugar)
│           ├── RepositoryErrorTests.swift (fuera de lugar)
│           └── UseCaseErrorTests.swift  (fuera de lugar)
└── TIER-0-Foundation/
    └── EduGoCommon/
        ├── Sources/EduGoCommon/
        │   ├── EduGoCommon.swift
        │   └── Domain/Entity.swift      (duplicado)
        └── Tests/EduGoCommonTests/
            └── EduGoCommonTests.swift
```

### Cambios Realizados

1. **Movimiento de archivos de producción**:
   ```bash
   Sources/EduGoCommon/Errors/*.swift
   → TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon/Errors/
   ```

2. **Movimiento de archivos de tests**:
   ```bash
   Tests/EduGoCommonTests/Errors/*.swift
   → TIER-0-Foundation/EduGoCommon/Tests/EduGoCommonTests/Errors/
   ```

3. **Eliminación de duplicados**:
   - Eliminado `Sources/EduGoCommon/Domain/Entity.swift` (duplicado)
   - Mantenida la versión en `TIER-0-Foundation/` (tiene copyright y mejor documentación)

4. **Eliminación de directorios raíz vacíos**:
   ```bash
   rm -rf Sources/ Tests/
   ```

### Estructura Final

```
✅ DESPUÉS:
Apple/
└── TIER-0-Foundation/
    └── EduGoCommon/
        ├── Sources/EduGoCommon/
        │   ├── EduGoCommon.swift
        │   ├── Domain/
        │   │   └── Entity.swift
        │   ├── Errors/
        │   │   ├── DomainError.swift
        │   │   ├── RepositoryError.swift
        │   │   └── UseCaseError.swift
        │   └── Protocols/
        │       └── UserContextProtocol.swift (nuevo)
        └── Tests/EduGoCommonTests/
            ├── EduGoCommonTests.swift
            ├── Domain/
            │   └── EntityTests.swift
            └── Errors/
                ├── DomainErrorTests.swift
                ├── RepositoryErrorTests.swift
                └── UseCaseErrorTests.swift
```

### Verificación de Compilación

Todos los módulos compilaron exitosamente después de los cambios:

- ✅ EduGoCommon (0.51s)
- ✅ Logger (4.94s)
- ✅ Auth (7.37s)
- ✅ Roles (2.04s)

---

## 2. Desacoplamiento Roles ← Auth

### Problema Detectado

El módulo `Roles` (TIER-3) tenía una dependencia directa con `Auth` (también TIER-3), violando el principio de independencia modular:

```swift
// ❌ ANTES: Roles/Package.swift
dependencies: [
    .package(path: "../Auth")  // Cross-tier dependency
]
```

**Impacto:**
- No se puede usar `Roles` sin `Auth`
- Impide compilación paralela de módulos TIER-3
- Dificulta testing aislado
- Violación de arquitectura modular

### Solución Implementada

#### 2.1. Creación de `UserContextProtocol` en TIER-0

Archivo: `TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon/Protocols/UserContextProtocol.swift`

```swift
/// Protocolo que define el contexto del usuario autenticado.
///
/// Permite que módulos accedan a información básica del usuario
/// sin depender directamente de AuthManager.
public protocol UserContextProtocol: Sendable {
    /// ID del usuario actualmente autenticado
    var currentUserId: UUID? { get async }
    
    /// Indica si hay un usuario autenticado
    var isAuthenticated: Bool { get async }
    
    /// Email del usuario autenticado
    var currentUserEmail: String? { get async }
}
```

**Características:**
- Definido en TIER-0 (Foundation) para uso universal
- Conformidad a `Sendable` para thread-safety
- Propiedades async para compatibilidad con `actor`
- Documentación completa en español

#### 2.2. Implementación en AuthManager

Archivo: `TIER-3-Domain/Auth/Sources/Auth/Auth.swift`

```swift
import EduGoCommon

public actor AuthManager: Sendable, UserContextProtocol {
    // ... código existente ...
    
    // MARK: - UserContextProtocol Implementation
    
    public var currentUserId: UUID? {
        get async { currentUser?.id }
    }
    
    public var currentUserEmail: String? {
        get async { currentUser?.email }
    }
}
```

#### 2.3. Eliminación de Dependencia en Roles

Archivo: `TIER-3-Domain/Roles/Package.swift`

```diff
dependencies: [
    .package(path: "../../TIER-0-Foundation/EduGoCommon"),
    .package(path: "../../TIER-1-Core/Logger"),
    .package(path: "../../TIER-1-Core/Models"),
-   .package(path: "../../TIER-2-Infrastructure/Storage"),
-   .package(path: "../Auth")
+   .package(path: "../../TIER-2-Infrastructure/Storage")
]
```

### Beneficios Obtenidos

1. **Independencia Modular**: Roles ya no depende de Auth
2. **Compilación Paralela**: TIER-3 modules pueden compilarse simultáneamente
3. **Testing Mejorado**: Roles puede testearse con mocks de UserContextProtocol
4. **Flexibilidad**: Cualquier módulo puede implementar UserContextProtocol
5. **Arquitectura Limpia**: Conformidad con separación de responsabilidades

---

## 3. Verificación de Compilación

Todos los módulos compilaron exitosamente:

```bash
✅ EduGoCommon:     Build complete! (0.41s)
✅ Auth:            Build complete! (0.77s)
✅ Roles:           Build complete! (2.04s)
```

---

## 4. Impacto en Sprints Existentes

### Sprint 2: TIER 1 Domain Layer

**Flow Row afectado:** `domain-protocols` (fr-1769041611302346000)

**Story:** "Definir protocolos de repositorios"

**Impacto:** ✅ **UserContextProtocol** ya implementado como parte de esta refactorización.

**Acción requerida:** Documentar en la story que `UserContextProtocol` está completo y listo para uso.

---

## 5. Nuevas Tareas Sugeridas para MCP

### Tarea 1: Documentar UserContextProtocol en Story

**Flow Row:** `domain-protocols` (fr-1769041611302346000)  
**Story:** `story-definir-protocolos-de-repositorios-23bce58c`

**Descripción de Task:**
```
Título: Documentar implementación de UserContextProtocol
Tipo: documentation
Applies To: [planner]

Descripción:
UserContextProtocol ya fue implementado como parte de refactorización
2026-01-27 para desacoplar Roles de Auth.

Archivo: TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon/Protocols/UserContextProtocol.swift

Implementaciones:
- AuthManager (TIER-3-Domain/Auth) implementa UserContextProtocol

Beneficios:
- Roles ya no depende de Auth directamente
- Cualquier módulo puede acceder a contexto de usuario
- Mejora testing con mocks

Referencia: REFACTORING_2026-01-27.md
```

### Tarea 2: Implementar Lógica Real en Auth.signIn()

**Flow Row Sugerido:** Nuevo flow row en Sprint 3

**Título:** `auth-real-implementation`

**Descripción:**
```
Implementar lógica real de autenticación con validación, network y persistencia.

Actualmente Auth.signIn() usa placeholders:
- Hardcoded User creation
- Mock access token
- No validación de email
- No llamada HTTP real
- No persistencia de sesión

Tareas requeridas:
1. Validar email con DomainError.validationFailed
2. Integrar NetworkClient para autenticación HTTP
3. Manejar RepositoryError de fallos de red
4. Persistir sesión con StorageManager
5. Tests unitarios y de integración
```

---

## 6. Archivos Modificados

### Archivos Nuevos (1)

- `TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon/Protocols/UserContextProtocol.swift`

### Archivos Modificados (2)

- `TIER-3-Domain/Auth/Sources/Auth/Auth.swift`
- `TIER-3-Domain/Roles/Package.swift`

### Archivos Movidos (6)

**Producción:**
- `Sources/EduGoCommon/Errors/DomainError.swift` → `TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon/Errors/`
- `Sources/EduGoCommon/Errors/UseCaseError.swift` → `TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon/Errors/`
- `Sources/EduGoCommon/Errors/RepositoryError.swift` → `TIER-0-Foundation/EduGoCommon/Sources/EduGoCommon/Errors/`

**Tests:**
- `Tests/EduGoCommonTests/Errors/DomainErrorTests.swift` → `TIER-0-Foundation/EduGoCommon/Tests/EduGoCommonTests/Errors/`
- `Tests/EduGoCommonTests/Errors/RepositoryErrorTests.swift` → `TIER-0-Foundation/EduGoCommon/Tests/EduGoCommonTests/Errors/`
- `Tests/EduGoCommonTests/Errors/UseCaseErrorTests.swift` → `TIER-0-Foundation/EduGoCommon/Tests/EduGoCommonTests/Errors/`

### Archivos Eliminados (1)

- `Sources/EduGoCommon/Domain/Entity.swift` (duplicado)

### Directorios Eliminados (2)

- `Sources/`
- `Tests/`

---

## 7. Compatibilidad con Xcode

Todos los cambios son compatibles con Xcode:

- ✅ Swift Package Manager estructura estándar
- ✅ Paths relativos en Package.swift
- ✅ Strict concurrency habilitada (Swift 6.2)
- ✅ No hay dependencias externas
- ✅ Compilación incremental funcional

---

## 8. Próximos Pasos Recomendados

1. **Inmediato**:
   - Crear tarea en MCP para documentar UserContextProtocol
   - Actualizar story `story-definir-protocolos-de-repositorios-23bce58c`

2. **Sprint 3**:
   - Implementar lógica real en Auth.signIn()
   - Agregar persistencia a RolesManager con StorageManager

3. **Sprint 4**:
   - Crear tests de integración Auth ↔ Roles usando UserContextProtocol
   - Implementar casos de uso que orquesten Auth + Roles

---

## Conclusión

La refactorización eliminó dos desviaciones arquitectónicas críticas:

1. ✅ **Estructura de carpetas** ahora es consistente con la arquitectura documentada
2. ✅ **Dependencia cross-tier** eliminada mediante abstracción de protocolo

El proyecto ahora tiene una arquitectura **más limpia, modular y testeable**.
