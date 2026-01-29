# Arquitectura del Modulo Network

## Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           TIER-3 (Domain)                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐          │
│  │  Use Cases      │  │  Domain Models  │  │  Domain Errors  │          │
│  └────────┬────────┘  └─────────────────┘  └─────────────────┘          │
│           │                                                              │
└───────────┼──────────────────────────────────────────────────────────────┘
            │ uses
┌───────────▼──────────────────────────────────────────────────────────────┐
│                        TIER-2 Network Module                             │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                      Repositories Layer                          │    │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │    │
│  │  │ MaterialsRepo   │ │ ProgressRepo    │ │ StatsRepo       │    │    │
│  │  │ - getMaterials  │ │ - updateProgress│ │ - getGlobalStats│    │    │
│  │  │ - getMaterial   │ └─────────────────┘ └─────────────────┘    │    │
│  │  │ - submitAssess  │                                             │    │
│  │  └────────┬────────┘                                             │    │
│  └───────────┼──────────────────────────────────────────────────────┘    │
│              │ uses                                                       │
│  ┌───────────▼──────────────────────────────────────────────────────┐    │
│  │                    NetworkClient (Actor)                          │    │
│  │  ┌─────────────────────────────────────────────────────────┐     │    │
│  │  │  request<T>() -> T    requestData() -> (Data, Response) │     │    │
│  │  │  upload<T>()          download() -> URL                  │     │    │
│  │  │  get/post/put/delete/patch convenience methods           │     │    │
│  │  └─────────────────────────────────────────────────────────┘     │    │
│  └───────────┬──────────────────────────────────────────────────────┘    │
│              │ delegates to                                               │
│  ┌───────────▼──────────────────────────────────────────────────────┐    │
│  │                    Interceptor Chain                              │    │
│  │                                                                   │    │
│  │   Request Flow:  [Auth] -> [Logging] -> [Retry] -> URLSession    │    │
│  │   Response Flow: URLSession -> [Retry] <- [Logging] <- [Auth]    │    │
│  │                                                                   │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐              │    │
│  │  │ AuthInterc.  │ │ LoggingInt.  │ │ RetryInterc. │              │    │
│  │  │ - addToken   │ │ - logRequest │ │ - shouldRetry│              │    │
│  │  │ - refresh    │ │ - logResponse│ │ - calcDelay  │              │    │
│  │  └──────────────┘ └──────────────┘ └──────────────┘              │    │
│  └──────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │                         DTOs Layer                                │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │    │
│  │  │ MaterialDTO │  │ ProgressDTO │  │ StatsDTO    │               │    │
│  │  │ AttemptDTO  │  │             │  │ JSONValue   │               │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘               │    │
│  └──────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │                       Error Types                                 │    │
│  │  NetworkError | MaterialsRepoError | ProgressRepoError | StatsErr │    │
│  └──────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────┘
            │ uses
┌───────────▼──────────────────────────────────────────────────────────────┐
│                           Foundation                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐          │
│  │  URLSession     │  │  JSONEncoder    │  │  JSONDecoder    │          │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘          │
└──────────────────────────────────────────────────────────────────────────┘
```

## Patrones de Diseno

### 1. Repository Pattern

**Proposito**: Encapsular la logica de acceso a datos y proporcionar una interfaz limpia para el dominio.

**Implementacion**:
```swift
public protocol MaterialsRepositoryProtocol: Sendable {
    func getMaterials() async throws -> [MaterialDTO]
    func getMaterial(id: String) async throws -> MaterialDTO
    func submitAssessment(materialId: String, request: CreateAttemptRequest) async throws -> AttemptResultDTO
}

public actor MaterialsRepository: MaterialsRepositoryProtocol {
    private let client: any NetworkClientProtocol
    private let baseURL: String
    
    // Implementacion...
}
```

**Beneficios**:
- Abstraccion del origen de datos (network, cache, mock)
- Validacion centralizada de parametros
- Mapeo de errores HTTP a errores de dominio
- Facilita testing con mocks

### 2. Chain of Responsibility (Interceptors)

**Proposito**: Procesar requests/responses en una cadena de handlers independientes.

**Implementacion**:
```swift
public protocol RequestInterceptor: Sendable {
    func adapt(_ request: URLRequest, context: RequestContext) async throws -> URLRequest
    func retry(_ request: URLRequest, dueTo error: NetworkError, context: RequestContext) async -> RetryDecision
    func didReceive(response: HTTPURLResponse, data: Data, for request: URLRequest, context: RequestContext) async
}

public struct InterceptorChain: RequestInterceptor {
    private let interceptors: [any RequestInterceptor]
    
    public func adapt(_ request: URLRequest, context: RequestContext) async throws -> URLRequest {
        var modified = request
        for interceptor in interceptors {
            modified = try await interceptor.adapt(modified, context: context)
        }
        return modified
    }
}
```

**Flujo de Request**:
```
HTTPRequest
    │
    ▼
┌─────────────────┐
│ Auth Interceptor │ ──► Agrega Authorization header
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Logging Interc. │ ──► Log de request saliente
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ URLSession      │ ──► Ejecuta request HTTP
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Retry Interc.   │ ──► Decide si reintentar en error
└────────┬────────┘
         │
         ▼
    Response/Error
```

**Beneficios**:
- Separacion de concerns (auth, logging, retry son independientes)
- Facil agregar/remover interceptors
- Orden configurable
- Cada interceptor es testeable individualmente

### 3. Builder Pattern (HTTPRequest)

**Proposito**: Construir objetos complejos paso a paso con una API fluida.

**Implementacion**:
```swift
let request = HTTPRequest(url: "https://api.edugo.com/v1/users")
    .method(.post)
    .header("X-Custom", "value")
    .queryParam("page", "1")
    .body(userData)
    .timeout(30)
    .bearerToken(token)
    .build()
```

**Beneficios**:
- API clara y autodocumentada
- Inmutabilidad (cada metodo retorna nueva instancia)
- Validacion en build()
- Facil de extender

### 4. Strategy Pattern (Retry Policies)

**Proposito**: Definir familia de algoritmos intercambiables.

**Implementacion**:
```swift
public protocol RetryPolicy: Sendable {
    func shouldRetry(error: NetworkError) -> Bool
    func delay(forAttempt attemptNumber: Int) -> TimeInterval
    var maxRetryCount: Int { get }
}

// Estrategias concretas
public struct ExponentialBackoffRetryPolicy: RetryPolicy { ... }
public struct LinearBackoffRetryPolicy: RetryPolicy { ... }
public struct FixedDelayRetryPolicy: RetryPolicy { ... }
```

**Beneficios**:
- Algoritmos de retry intercambiables
- Facil agregar nuevas estrategias
- Configuracion flexible por contexto

## Decisiones de Arquitectura

### 1. Uso de Actors para Thread Safety

**Decision**: `NetworkClient` y todos los repositorios son `actor`.

**Justificacion**:
- Swift 6.2 requiere strict concurrency
- Actors garantizan acceso serializado automatico
- Elimina race conditions sin locks manuales
- Cumple con `Sendable` automaticamente

**Trade-offs**:
- Overhead minimo de actor isolation
- Todas las llamadas son `async`

### 2. Errores Tipados por Capa

**Decision**: Cada capa tiene su propio tipo de error.

```swift
// Capa Network
public enum NetworkError: Error { ... }

// Capa Repository
public enum MaterialsRepositoryError: Error {
    case networkError(NetworkError)  // Wrapping
    case invalidMaterialId(String)   // Validacion
    case materialNotFound(String)    // Dominio
}
```

**Justificacion**:
- Errores semanticos por contexto
- Mapeo de HTTP a errores de dominio
- Informacion relevante para cada capa

### 3. DTOs Separados de Domain Models

**Decision**: DTOs viven en Network, Domain Models en TIER-3.

**Justificacion**:
- DTOs mapean 1:1 con JSON del backend
- Domain Models representan logica de negocio
- Cambios en API no afectan dominio
- Mapeo explicito entre capas

### 4. Protocolo para NetworkClient

**Decision**: `NetworkClientProtocol` permite inyeccion de dependencias.

```swift
public protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable & Sendable>(_ request: HTTPRequest) async throws -> T
    // ...
}

// Implementacion real
public actor NetworkClient: NetworkClientProtocol { ... }

// Mock para tests
public actor MockNetworkClient: NetworkClientProtocol { ... }
```

**Justificacion**:
- Facilita testing sin red real
- Permite diferentes implementaciones (cache, offline)
- Inversion de dependencias (DIP)

## Flujo de una Request

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. Repository recibe llamada                                         │
│    materialsRepo.getMaterial(id: "uuid-123")                        │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 2. Repository valida parametros                                      │
│    - Verifica que id no este vacio                                  │
│    - Verifica formato UUID valido                                   │
│    - Lanza MaterialsRepositoryError si invalido                     │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 3. Repository construye URL y llama a NetworkClient                  │
│    client.get(baseURL + "/v1/materials/" + id)                      │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 4. NetworkClient construye HTTPRequest                               │
│    HTTPRequest.get(url).acceptJSON()                                │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 5. InterceptorChain.adapt() modifica request                         │
│    - AuthInterceptor agrega "Authorization: Bearer token"           │
│    - LoggingInterceptor registra request saliente                   │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 6. URLSession ejecuta request HTTP                                   │
│    - Timeout: 30s                                                   │
│    - SSL/TLS verificado                                             │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
              ┌──────────────────┴──────────────────┐
              │                                     │
              ▼                                     ▼
┌─────────────────────────┐           ┌─────────────────────────┐
│ Success (200-299)       │           │ Error                   │
│ - Decode JSON a DTO     │           │ - Mapear a NetworkError │
│ - Return MaterialDTO    │           │ - Consultar retry policy│
└─────────────────────────┘           └────────────┬────────────┘
                                                   │
                                      ┌────────────┴────────────┐
                                      │                         │
                                      ▼                         ▼
                         ┌─────────────────────┐   ┌─────────────────────┐
                         │ Retriable           │   │ Non-retriable       │
                         │ - timeout           │   │ - 401 unauthorized  │
                         │ - network failure   │   │ - 404 not found     │
                         │ - 500, 502, 503     │   │ - 400 bad request   │
                         │ Retry con backoff   │   │ Propagar error      │
                         └─────────────────────┘   └─────────────────────┘
```

## Configuracion Recomendada

### Produccion
```swift
let productionClient = NetworkClient(
    interceptors: [
        AuthenticationInterceptor(
            tokenProvider: KeychainTokenProvider(),
            autoRefresh: true
        ),
        LoggingInterceptor(level: .error)  // Solo errores
    ],
    retryPolicy: ExponentialBackoffRetryPolicy.standard
)
```

### Desarrollo
```swift
let devClient = NetworkClient(
    interceptors: [
        AuthenticationInterceptor(
            tokenProvider: StaticTokenProvider(token: "dev-token")
        ),
        LoggingInterceptor(level: .verbose)  // Todo
    ],
    retryPolicy: ExponentialBackoffRetryPolicy.aggressive
)
```

### Tests
```swift
let mockClient = MockNetworkClient()
await mockClient.setResponse(expectedMaterial)
let repository = MaterialsRepository(client: mockClient, baseURL: "https://test")
```
