# Guia de Uso del Modulo Network

## Tabla de Contenidos

1. [Configuracion Inicial](#configuracion-inicial)
2. [Requests Basicas](#requests-basicas)
3. [Uso de Repositorios](#uso-de-repositorios)
4. [Configuracion de Interceptors](#configuracion-de-interceptors)
5. [Manejo de Errores](#manejo-de-errores)
6. [Retry Policies](#retry-policies)
7. [Ejemplos Avanzados](#ejemplos-avanzados)
8. [Troubleshooting](#troubleshooting)

---

## Configuracion Inicial

### Importar el Modulo

```swift
import Network
```

### Usar el Cliente Compartido

Para la mayoria de casos, usa la instancia compartida:

```swift
let client = NetworkClient.shared
```

### Crear Cliente Personalizado

```swift
// Con autenticacion y logging
let client = NetworkClient(
    interceptors: [
        AuthenticationInterceptor(
            tokenProvider: MyTokenProvider(),
            autoRefresh: true
        ),
        LoggingInterceptor(level: .info)
    ],
    retryPolicy: ExponentialBackoffRetryPolicy.standard
)

// Con configuracion custom de URLSession
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 60
config.waitsForConnectivity = true

let client = NetworkClient(
    configuration: config,
    interceptors: [],
    retryPolicy: ExponentialBackoffRetryPolicy.conservative
)
```

---

## Requests Basicas

### Ejemplo 1: GET Simple

```swift
struct User: Decodable, Sendable {
    let id: String
    let name: String
    let email: String
}

// Obtener lista de usuarios
let users: [User] = try await client.get("https://api.edugo.com/v1/users")

// Obtener usuario por ID
let user: User = try await client.get("https://api.edugo.com/v1/users/123")
```

### Ejemplo 2: GET con Query Parameters

```swift
// Usando HTTPRequest builder
let request = HTTPRequest.get("https://api.edugo.com/v1/users")
    .queryParam("page", "1")
    .queryParam("limit", "20")
    .queryParam("sort", "name")

let users: [User] = try await client.request(request)

// Multiples parametros de una vez
let request = HTTPRequest.get("https://api.edugo.com/v1/search")
    .queryParams([
        "q": "matematicas",
        "grade": "6",
        "subject": "math"
    ])
```

### Ejemplo 3: POST con Body JSON

```swift
struct CreateUserRequest: Encodable, Sendable {
    let name: String
    let email: String
    let role: String
}

let newUser = CreateUserRequest(
    name: "Maria Garcia",
    email: "maria@example.com",
    role: "student"
)

// Usando convenience method
let created: User = try await client.post(
    "https://api.edugo.com/v1/users",
    body: newUser
)

// Usando HTTPRequest builder
let jsonData = try await CodableSerializer.dtoSerializer.encode(newUser)
let request = HTTPRequest.post("https://api.edugo.com/v1/users")
    .jsonBody(jsonData)
    .header("X-Request-ID", UUID().uuidString)

let created: User = try await client.request(request)
```

### Ejemplo 4: PUT para Actualizar

```swift
struct UpdateUserRequest: Encodable, Sendable {
    let name: String
    let email: String
}

let update = UpdateUserRequest(name: "Maria Garcia Lopez", email: "maria.new@example.com")

let updated: User = try await client.put(
    "https://api.edugo.com/v1/users/123",
    body: update
)
```

### Ejemplo 5: DELETE

```swift
// DELETE que retorna el objeto eliminado
let deleted: User = try await client.delete("https://api.edugo.com/v1/users/123")

// DELETE sin response body
let _: EmptyResponse = try await client.delete("https://api.edugo.com/v1/users/123")
```

---

## Uso de Repositorios

### MaterialsRepository

```swift
// Crear instancia
let materialsRepo = MaterialsRepository(
    client: NetworkClient.shared,
    baseURL: "https://api.edugo.com"
)

// Obtener todos los materiales
let materials = try await materialsRepo.getMaterials()
for material in materials {
    print("\(material.title) - \(material.status)")
}

// Obtener material especifico
let material = try await materialsRepo.getMaterial(
    id: "550e8400-e29b-41d4-a716-446655440001"
)

// Enviar intento de assessment
let answers = [
    AnswerRequest(questionId: "q1", selectedAnswerId: "a1", timeSpentSeconds: 30),
    AnswerRequest(questionId: "q2", selectedAnswerId: "a2", timeSpentSeconds: 45),
    AnswerRequest(questionId: "q3", selectedAnswerId: "a3", timeSpentSeconds: 60)
]

let attemptRequest = CreateAttemptRequest(
    answers: answers,
    timeSpentSeconds: 180
)

let result = try await materialsRepo.submitAssessment(
    materialId: "550e8400-e29b-41d4-a716-446655440001",
    request: attemptRequest
)

print("Score: \(result.score)/\(result.maxScore)")
print("Passed: \(result.passed)")
print("Correct: \(result.correctAnswers)/\(result.totalQuestions)")
```

### ProgressRepository

```swift
let progressRepo = ProgressRepository(
    client: NetworkClient.shared,
    baseURL: "https://api.edugo.com"
)

// Actualizar progreso (operacion upsert)
let progressRequest = UpsertProgressRequest(
    materialId: "550e8400-e29b-41d4-a716-446655440001",
    userId: "user-uuid-123",
    percentage: 75
)

let progress = try await progressRepo.updateProgress(request: progressRequest)
print("Progreso actualizado: \(progress.percentage)%")
```

### StatsRepository

```swift
let statsRepo = StatsRepository(
    client: NetworkClient.shared,
    baseURL: "https://api.edugo.com"
)

// Obtener estadisticas globales (requiere admin)
do {
    let stats = try await statsRepo.getGlobalStats()
    
    if let users = stats.totalUsers {
        print("Total usuarios: \(users)")
    }
    if let materials = stats.totalMaterials {
        print("Total materiales: \(materials)")
    }
    if let progress = stats.averageProgress {
        print("Progreso promedio: \(progress)%")
    }
    
    // Acceder a campos dinamicos
    for (key, value) in stats.additionalFields {
        print("\(key): \(value)")
    }
} catch StatsRepositoryError.forbidden {
    print("Requiere permisos de administrador")
}
```

---

## Configuracion de Interceptors

### AuthenticationInterceptor

```swift
// Token estatico (para desarrollo)
let staticProvider = StaticTokenProvider(token: "my-dev-token")

// Token dinamico (para produccion)
final class KeychainTokenProvider: TokenProvider {
    func getToken() async throws -> String? {
        // Leer token de Keychain
        return KeychainHelper.shared.getToken()
    }
    
    func refreshToken() async throws -> String {
        // Llamar endpoint de refresh
        let newToken = try await authService.refreshToken()
        KeychainHelper.shared.saveToken(newToken)
        return newToken
    }
}

let authInterceptor = AuthenticationInterceptor(
    tokenProvider: KeychainTokenProvider(),
    autoRefresh: true,              // Refresh automatico en 401
    excludedPaths: ["/auth/login", "/auth/register"]  // No agregar token
)
```

### LoggingInterceptor

```swift
// Niveles disponibles: none, error, info, debug, verbose

// Solo errores (produccion)
let prodLogging = LoggingInterceptor(level: .error)

// Informacion general (staging)
let stagingLogging = LoggingInterceptor(level: .info)

// Todo el detalle (desarrollo)
let devLogging = LoggingInterceptor(level: .verbose)

// Los logs van a Console.app via os.Logger
// Filtrar en Console: subsystem "com.edugo.network"
```

### Combinar Interceptors

```swift
let client = NetworkClient(
    interceptors: [
        authInterceptor,      // 1. Agrega token
        loggingInterceptor,   // 2. Log request/response
        RetryInterceptor(policy: ExponentialBackoffRetryPolicy.standard)  // 3. Retry
    ],
    retryPolicy: ExponentialBackoffRetryPolicy.standard
)
```

---

## Manejo de Errores

### NetworkError

```swift
do {
    let data: MyData = try await client.get(url)
} catch let error as NetworkError {
    switch error {
    case .invalidURL(let url):
        print("URL invalida: \(url)")
        
    case .noData:
        print("El servidor no retorno datos")
        
    case .decodingError(let type, let underlyingError):
        print("Error decodificando \(type): \(underlyingError)")
        
    case .serverError(let statusCode, let message):
        print("Error del servidor (\(statusCode)): \(message ?? "Sin mensaje")")
        
    case .networkFailure(let error):
        print("Fallo de conexion: \(error)")
        
    case .timeout:
        print("Timeout - intente de nuevo")
        
    case .cancelled:
        print("Request cancelada")
        
    case .sslError(let error):
        print("Error de seguridad: \(error)")
        
    case .unauthorized:
        // Redirigir a login
        await redirectToLogin()
        
    case .forbidden:
        print("No tiene permisos para esta accion")
        
    case .notFound:
        print("Recurso no encontrado")
        
    case .rateLimited(let retryAfter):
        if let delay = retryAfter {
            print("Demasiadas solicitudes. Espere \(Int(delay)) segundos")
        }
    }
}
```

### Repository Errors

```swift
// MaterialsRepositoryError
do {
    let material = try await materialsRepo.getMaterial(id: materialId)
} catch MaterialsRepositoryError.invalidMaterialId(let id) {
    showError("ID de material invalido: \(id)")
} catch MaterialsRepositoryError.materialNotFound(let id) {
    showError("Material no encontrado")
} catch MaterialsRepositoryError.emptyAnswers {
    showError("Debe responder al menos una pregunta")
} catch MaterialsRepositoryError.invalidTimeSpent(let seconds) {
    showError("Tiempo invalido: \(seconds)s")
} catch MaterialsRepositoryError.unauthorized {
    await redirectToLogin()
} catch MaterialsRepositoryError.assessmentNotFound(let id) {
    showError("Assessment no disponible para este material")
} catch MaterialsRepositoryError.networkError(let networkError) {
    handleNetworkError(networkError)
}

// ProgressRepositoryError
do {
    let progress = try await progressRepo.updateProgress(request: request)
} catch ProgressRepositoryError.invalidPercentage(let pct) {
    showError("Porcentaje debe estar entre 0 y 100, recibido: \(pct)")
} catch ProgressRepositoryError.forbidden {
    showError("Solo puede actualizar su propio progreso")
}

// StatsRepositoryError  
do {
    let stats = try await statsRepo.getGlobalStats()
} catch StatsRepositoryError.forbidden {
    showError("Requiere permisos de administrador")
}
```

---

## Retry Policies

### ExponentialBackoffRetryPolicy

```swift
// Presets disponibles
let standard = ExponentialBackoffRetryPolicy.standard      // 3 retries, 1-30s
let aggressive = ExponentialBackoffRetryPolicy.aggressive  // 5 retries, 0.5-10s
let conservative = ExponentialBackoffRetryPolicy.conservative  // 3 retries, 2-60s
let none = ExponentialBackoffRetryPolicy.none              // Sin retries

// Configuracion custom
let customPolicy = ExponentialBackoffRetryPolicy(
    baseDelay: 1.0,         // Delay inicial
    maxDelay: 30.0,         // Delay maximo
    jitterFactor: 0.5,      // Variacion aleatoria (0-1)
    maxRetryCount: 3,       // Maximo intentos
    retriableErrors: [.timeout, .networkFailure, .rateLimited],
    retriableStatusCodes: [500, 502, 503, 504]
)

// Delays resultantes (sin jitter):
// Intento 1: 1s
// Intento 2: 2s
// Intento 3: 4s
// Intento 4: 8s (si maxRetryCount > 3)
```

### LinearBackoffRetryPolicy

```swift
let linearPolicy = LinearBackoffRetryPolicy(
    baseDelay: 1.0,
    delayIncrement: 2.0,
    maxDelay: 10.0,
    maxRetryCount: 3
)

// Delays resultantes:
// Intento 1: 1s
// Intento 2: 3s
// Intento 3: 5s
```

### FixedDelayRetryPolicy

```swift
let fixedPolicy = FixedDelayRetryPolicy(
    delay: 5.0,
    maxRetryCount: 3
)

// Delays resultantes:
// Intento 1: 5s
// Intento 2: 5s
// Intento 3: 5s
```

---

## Ejemplos Avanzados

### Ejemplo: ViewModel con Repository

```swift
@MainActor
final class MaterialsViewModel: ObservableObject {
    @Published private(set) var materials: [MaterialDTO] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let repository: MaterialsRepositoryProtocol
    
    init(repository: MaterialsRepositoryProtocol = MaterialsRepository(
        client: NetworkClient.shared,
        baseURL: "https://api.edugo.com"
    )) {
        self.repository = repository
    }
    
    func loadMaterials() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            materials = try await repository.getMaterials()
        } catch MaterialsRepositoryError.unauthorized {
            errorMessage = "Sesion expirada"
            // Notificar para redirigir a login
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Ejemplo: Cancelacion de Requests

```swift
class SearchController {
    private var currentTask: Task<Void, Never>?
    
    func search(query: String) {
        // Cancelar busqueda anterior
        currentTask?.cancel()
        
        currentTask = Task {
            do {
                // Debounce de 300ms
                try await Task.sleep(for: .milliseconds(300))
                
                guard !Task.isCancelled else { return }
                
                let results: [SearchResult] = try await client.get(
                    "https://api.edugo.com/v1/search",
                    headers: ["X-Search-Query": query]
                )
                
                await MainActor.run {
                    self.updateResults(results)
                }
            } catch is CancellationError {
                // Ignorar - fue cancelada intencionalmente
            } catch {
                await MainActor.run {
                    self.showError(error)
                }
            }
        }
    }
}
```

### Ejemplo: Requests en Paralelo

```swift
func loadDashboard() async throws -> Dashboard {
    async let materials = materialsRepo.getMaterials()
    async let stats = statsRepo.getGlobalStats()
    async let recentProgress = progressRepo.getRecentProgress()
    
    // Esperar todas en paralelo
    let (materialsResult, statsResult, progressResult) = try await (
        materials,
        stats,
        recentProgress
    )
    
    return Dashboard(
        materials: materialsResult,
        stats: statsResult,
        progress: progressResult
    )
}
```

---

## Troubleshooting

### 1. Error: "No se recibieron datos del servidor"

**Causa**: El servidor retorno 204 No Content o body vacio.

**Solucion**: Usar `EmptyResponse` como tipo:
```swift
let _: EmptyResponse = try await client.delete(url)
```

### 2. Error: "Error al decodificar X"

**Causa**: El JSON no coincide con la estructura del DTO.

**Solucion**: 
- Verificar que los nombres de campos usen snake_case en JSON
- El decoder usa `keyDecodingStrategy: .convertFromSnakeCase`
- Agregar campos opcionales si el servidor puede omitirlos

### 3. Error: "URL invalida"

**Causa**: La URL contiene caracteres especiales sin encodear.

**Solucion**:
```swift
let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
let url = "https://api.com/search?q=\(encodedQuery ?? "")"
```

### 4. Error: "No autorizado" persistente

**Causa**: Token expirado y refresh fallando.

**Solucion**:
- Verificar que `autoRefresh: true` en AuthenticationInterceptor
- Verificar que TokenProvider.refreshToken() funciona
- Revisar logs de LoggingInterceptor

### 5. Requests muy lentas

**Causa**: Retry policy muy agresiva o problemas de red.

**Solucion**:
```swift
// Reducir timeouts
let request = HTTPRequest.get(url).timeout(10)

// Usar policy menos agresiva
let client = NetworkClient(
    retryPolicy: ExponentialBackoffRetryPolicy.conservative
)
```

### 6. Error: "Rate limited"

**Causa**: Demasiadas requests en poco tiempo.

**Solucion**:
- El modulo respeta automaticamente Retry-After header
- Implementar debounce en busquedas
- Usar cache local cuando sea posible

### 7. Memoria alta durante uploads

**Causa**: Cargando archivo completo en memoria.

**Solucion**: Usar upload con fileURL:
```swift
let localFile = URL(fileURLWithPath: "/path/to/file.pdf")
let result: UploadResult = try await client.upload(
    fileURL: localFile,
    request: HTTPRequest.post("https://api.com/upload")
)
```

### 8. Logs no aparecen en Console.app

**Causa**: Nivel de logging muy restrictivo o filtro incorrecto.

**Solucion**:
- Usar `LoggingInterceptor(level: .verbose)`
- En Console.app filtrar por: `subsystem:com.edugo.network`
- Asegurar que Include Info Messages y Include Debug Messages esten habilitados

### 9. Tests fallan con "Actor-isolated property"

**Causa**: Accediendo propiedades del mock sin await.

**Solucion**:
```swift
// Incorrecto
let count = mock.requestCount

// Correcto
let count = await mock.requestCount
```

### 10. Error SSL en desarrollo

**Causa**: Servidor de desarrollo con certificado auto-firmado.

**Solucion**: Solo para desarrollo, no usar en produccion:
```swift
// En Info.plist agregar:
// App Transport Security Settings
//   Allow Arbitrary Loads: YES (solo desarrollo)
```
