# Changelog

Todos los cambios notables de este modulo seran documentados en este archivo.

El formato esta basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-28

### Added

#### Core
- `NetworkClient` - Cliente HTTP thread-safe basado en actors
- `NetworkClientProtocol` - Protocolo para abstraccion e inyeccion de dependencias
- `HTTPRequest` - Builder pattern para construccion de requests HTTP
- `NetworkError` - Errores tipados con mapeo de status codes y URLError

#### Response Types
- `EmptyResponse` - Para requests sin body de respuesta
- `APIResponse<T>` - Wrapper para respuestas con metadata
- `PaginatedResponse<T>` - Para respuestas paginadas

#### Interceptors
- `RequestInterceptor` - Protocolo base para interceptores
- `InterceptorChain` - Composicion de multiples interceptores
- `AuthenticationInterceptor` - Inyeccion automatica de Bearer tokens
- `LoggingInterceptor` - Logging configurable con os.Logger
- `RetryInterceptor` - Retry automatico con politicas configurables

#### Retry Policies
- `ExponentialBackoffRetryPolicy` - Backoff exponencial con jitter
- `LinearBackoffRetryPolicy` - Backoff lineal
- `FixedDelayRetryPolicy` - Delay fijo entre reintentos
- Presets: `.standard`, `.aggressive`, `.conservative`, `.none`

#### Repositories
- `MaterialsRepository` - GET /v1/materials, GET /v1/materials/{id}, POST assessment
- `ProgressRepository` - PUT /v1/progress (upsert)
- `StatsRepository` - GET /v1/stats/global

#### DTOs
- `MaterialDTO` - Material response
- `MaterialStatus` - Estados del material (uploaded, processing, ready, failed)
- `CreateAttemptRequest` - Request de intento de assessment
- `AnswerRequest` - Respuesta individual
- `AttemptResultDTO` - Resultado de assessment
- `QuestionFeedback` - Feedback por pregunta
- `ProgressDTO` - Response de progreso
- `UpsertProgressRequest` - Request de actualizacion de progreso
- `GlobalStatsDTO` - Estadisticas globales
- `JSONValue` - Tipo seguro para JSON dinamico

#### Testing
- `MockNetworkClient` - Mock actor para tests unitarios
- `URLProtocolMock` - Mock de URLProtocol para tests de integracion
- Fixtures JSON para materials, progress, stats
- 76 tests en 11 suites

#### Documentation
- README.md con quick start
- Architecture.md con patrones y decisiones de diseno
- UsageGuide.md con ejemplos detallados
- TestingGuide.md con guia de testing
- CHANGELOG.md

### Technical Details

- Swift 6.2 con strict concurrency
- iOS 26+ / macOS 26+
- Todas las operaciones son async/await
- Thread safety garantizado via actors
- Todos los tipos conforman Sendable
- Validacion de parametros en repositorios
- Mapeo de errores HTTP a errores de dominio
- Soporte para campos JSON dinamicos via JSONValue

## [Unreleased]

### Planned
- Cache layer con estrategias configurables
- Offline support con queue de requests
- Certificate pinning
- Metricas y telemetria
- WebSocket support

---

[1.0.0]: https://github.com/edugo/eduui-modules-apple/releases/tag/network-v1.0.0
[Unreleased]: https://github.com/edugo/eduui-modules-apple/compare/network-v1.0.0...HEAD
