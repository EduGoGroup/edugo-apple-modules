# Network Module

Modulo de networking async/await para EduGo Apple, implementado con Swift 6.2 y strict concurrency.

## Overview

El modulo Network proporciona una capa de abstraccion para comunicacion HTTP con el backend de EduGo. Incluye:

- **NetworkClient**: Cliente HTTP thread-safe basado en actors
- **Interceptors**: Sistema de interceptores para auth, logging y retry
- **Repositories**: Repositorios tipados para endpoints especificos
- **DTOs**: Data Transfer Objects para serialization/deserialization

## Requisitos

- iOS 26.0+ / macOS 26.0+
- Swift 6.2
- Xcode 16.0+

## Instalacion

### Swift Package Manager

Agrega la dependencia en tu `Package.swift`:

```swift
dependencies: [
    .package(path: "../TIER-2-Infrastructure/Network")
]
```

Y en el target:

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "Network", package: "Network")
    ]
)
```

## Quick Start

### 1. Configuracion Basica

```swift
import Network

// Usar instancia compartida con configuracion por defecto
let client = NetworkClient.shared

// O crear instancia personalizada
let customClient = NetworkClient(
    interceptors: [
        AuthenticationInterceptor(tokenProvider: myTokenProvider),
        LoggingInterceptor(level: .info)
    ],
    retryPolicy: ExponentialBackoffRetryPolicy.standard
)
```

### 2. Realizar una Request Simple

```swift
// GET request
let users: [UserDTO] = try await client.get("https://api.edugo.com/v1/users")

// POST request con body
let newUser = CreateUserRequest(name: "John", email: "john@example.com")
let created: UserDTO = try await client.post(
    "https://api.edugo.com/v1/users",
    body: newUser
)
```

### 3. Usar Repositorios

```swift
// Crear repositorio
let materialsRepo = MaterialsRepository(
    client: NetworkClient.shared,
    baseURL: "https://api.edugo.com"
)

// Obtener materiales
let materials = try await materialsRepo.getMaterials()

// Obtener material por ID
let material = try await materialsRepo.getMaterial(id: "uuid-123")

// Enviar assessment
let attemptRequest = CreateAttemptRequest(
    answers: [
        AnswerRequest(questionId: "q1", selectedAnswerId: "a1", timeSpentSeconds: 30)
    ],
    timeSpentSeconds: 120
)
let result = try await materialsRepo.submitAssessment(
    materialId: "uuid-123",
    request: attemptRequest
)
```

### 4. Manejo de Errores

```swift
do {
    let material = try await materialsRepo.getMaterial(id: "uuid-123")
} catch MaterialsRepositoryError.materialNotFound(let id) {
    print("Material no encontrado: \(id)")
} catch MaterialsRepositoryError.unauthorized {
    print("Sesion expirada, redirigir a login")
} catch MaterialsRepositoryError.networkError(let error) {
    print("Error de red: \(error.localizedDescription)")
}
```

## Estructura del Modulo

```
Network/
├── Sources/Network/
│   ├── NetworkClientProtocol.swift   # Protocolo principal
│   ├── Network.swift                  # Implementacion NetworkClient
│   ├── NetworkError.swift             # Errores tipados
│   ├── HTTPRequest.swift              # Builder de requests
│   ├── Interceptors/
│   │   ├── RequestInterceptor.swift   # Protocolo base
│   │   ├── AuthenticationInterceptor.swift
│   │   ├── LoggingInterceptor.swift
│   │   ├── RetryPolicy.swift
│   │   └── InterceptableNetworkClient.swift
│   ├── Repositories/
│   │   ├── MaterialsRepository.swift
│   │   ├── ProgressRepository.swift
│   │   └── StatsRepository.swift
│   └── DTOs/
│       ├── MaterialDTO.swift
│       ├── ProgressDTO.swift
│       └── StatsDTO.swift
├── Tests/NetworkTests/
│   ├── Mocks/
│   ├── Fixtures/
│   └── *Tests.swift
└── Documentation/
    ├── Architecture.md
    ├── UsageGuide.md
    └── TestingGuide.md
```

## Documentacion

- [Arquitectura](Documentation/Architecture.md) - Patrones y decisiones de diseno
- [Guia de Uso](Documentation/UsageGuide.md) - Ejemplos detallados
- [Guia de Testing](Documentation/TestingGuide.md) - Como escribir tests

## Caracteristicas Principales

### Thread Safety
Todo el modulo usa `actor` para garantizar thread safety automatico con Swift 6.2 strict concurrency.

### Interceptors
Sistema de interceptores para modificar requests/responses:
- `AuthenticationInterceptor`: Inyecta tokens Bearer automaticamente
- `LoggingInterceptor`: Logging configurable con os.Logger
- `RetryInterceptor`: Retry automatico con exponential backoff

### Retry Inteligente
Tres politicas de retry incluidas:
- `ExponentialBackoffRetryPolicy`: Delay exponencial con jitter
- `LinearBackoffRetryPolicy`: Delay lineal
- `FixedDelayRetryPolicy`: Delay constante

### Validacion de Parametros
Los repositorios validan UUIDs, porcentajes y otros parametros antes de enviar requests.

## Licencia

Copyright 2026 EduGo. Todos los derechos reservados.
