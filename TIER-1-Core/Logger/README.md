# Logger

Sistema de logging centralizado para EduGo Apple Modules basado en `os.Logger` de Apple.

## TIER

**TIER-1 Core** - Dependencia directa de TIER-0 (EduGoCommon)

## Descripcion

Este modulo proporciona un sistema de logging unificado con:

- Integracion nativa con Unified Logging System de Apple (`os.Logger`)
- Categorias por modulo para filtrado granular
- Niveles configurables: debug, info, warning, error
- Configuracion dinamica via variables de entorno
- Thread-safety completo con Swift Concurrency (actors)
- Cumplimiento de Swift 6.2 Strict Concurrency

## Instalacion

El modulo esta incluido en el monorepo. Agregar dependencia en tu `Package.swift`:

```swift
dependencies: [
    .package(path: "../TIER-1-Core/Logger")
]
```

Y en tu target:

```swift
.target(
    name: "TuModulo",
    dependencies: [
        .product(name: "Logger", package: "Logger")
    ]
)
```

## Uso Rapido

### Configuracion Inicial

```swift
import Logger

// Opcion 1: Configuracion automatica desde environment
await LoggerConfigurator.shared.configureFromEnvironment()

// Opcion 2: Usar preset
await LoggerConfigurator.shared.applyPreset(.development)
```

### Logging Basico

```swift
// Obtener logger
let logger = await LoggerRegistry.shared.logger()

// Registrar mensajes
await logger.debug("Mensaje de debug")
await logger.info("Informacion general")
await logger.warning("Algo no esperado")
await logger.error("Error critico")
```

### Usar Categorias

```swift
// Usar categoria predefinida
await logger.info("Usuario autenticado", category: StandardLogCategory.TIER0.entity)

// Crear categoria custom
enum AuthCategory: String, LogCategory {
    case login = "com.edugo.tier2.auth.login"
    case logout = "com.edugo.tier2.auth.logout"
}

await logger.info("Login exitoso", category: AuthCategory.login)
```

## Variables de Entorno

| Variable | Valores | Default |
|----------|---------|---------|
| `EDUGO_LOG_LEVEL` | debug, info, warning, error | Segun build |
| `EDUGO_LOG_ENABLED` | true, false, 1, 0 | true |
| `EDUGO_LOG_METADATA` | true, false | Segun build |
| `EDUGO_ENVIRONMENT` | development, staging, production | Detectado |
| `EDUGO_LOG_SUBSYSTEM` | String | com.edugo.apple |

## Estructura del Modulo

```
Sources/Logger/
├── Protocols/          # LoggerProtocol
├── Models/             # LogLevel, LogCategory, LogConfiguration
├── Implementation/     # OSLoggerAdapter, OSLoggerFactory
├── Registry/           # LoggerRegistry
├── Categories/         # StandardLogCategory, extensiones
├── Configuration/      # LoggerConfigurator, EnvironmentConfiguration
└── Documentation/      # Guias y documentacion
```

## Documentacion

Ver carpeta `Sources/Logger/Documentation/` para guias detalladas:

- [QuickStart.md](Sources/Logger/Documentation/QuickStart.md) - Inicio rapido
- [Integration.md](Sources/Logger/Documentation/Integration.md) - Integracion en modulos
- [BestPractices.md](Sources/Logger/Documentation/BestPractices.md) - Mejores practicas
- [Troubleshooting.md](Sources/Logger/Documentation/Troubleshooting.md) - Resolucion de problemas
- [CategoryGuide.md](Sources/Logger/Documentation/CategoryGuide.md) - Guia de categorias
- [Architecture.md](Sources/Logger/Documentation/Architecture.md) - Arquitectura

## Tests

Ejecutar tests:

```bash
swift test
```

## Requisitos

- Swift 6.2+
- iOS 26+ / macOS 26+
- Xcode 16+

## Licencia

Copyright 2026 EduGo. Todos los derechos reservados.
