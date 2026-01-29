# Guia de Testing del Modulo Network

## Tabla de Contenidos

1. [Estructura de Tests](#estructura-de-tests)
2. [MockNetworkClient](#mocknetworkclient)
3. [URLProtocolMock](#urlprotocolmock)
4. [Fixtures JSON](#fixtures-json)
5. [Testing de Repositorios](#testing-de-repositorios)
6. [Testing de Error Handling](#testing-de-error-handling)
7. [Testing de Interceptors](#testing-de-interceptors)
8. [Mejores Practicas](#mejores-practicas)

---

## Estructura de Tests

```
Tests/NetworkTests/
├── Mocks/
│   ├── MockNetworkClient.swift    # Mock del cliente de red
│   └── URLProtocolMock.swift      # Mock de URLProtocol
├── Fixtures/
│   ├── materials.json             # Datos de prueba
│   ├── progress.json
│   └── stats.json
├── NetworkTests.swift             # Tests basicos
├── NetworkClientTests.swift       # Tests de HTTPRequest, client
├── RepositoriesTests.swift        # Tests de repos
├── ErrorHandlingTests.swift       # Tests de errores
└── InterceptorTests.swift         # Tests de interceptors
```

---

## MockNetworkClient

`MockNetworkClient` es un actor que implementa `NetworkClientProtocol` para tests unitarios sin red real.

### Configuracion Basica

```swift
import Testing
@testable import Network

@Suite("Mi Feature Tests")
struct MiFeatureTests {
    
    @Test("Obtiene datos correctamente")
    func testObtieneDatos() async throws {
        // Arrange
        let mock = MockNetworkClient()
        let expectedData = MyDTO(id: "1", name: "Test")
        await mock.setResponse(expectedData)
        
        // Act
        let request = HTTPRequest.get("https://api.test.com/data")
        let result: MyDTO = try await mock.request(request)
        
        // Assert
        #expect(result.id == "1")
        #expect(result.name == "Test")
    }
}
```

### Configurar Respuestas

```swift
// Respuesta exitosa
await mock.setResponse(myDTO)

// Error
await mock.setError(.unauthorized)
await mock.setError(.notFound)
await mock.setError(.serverError(statusCode: 500, message: "Internal error"))

// Data cruda
await mock.mockData = jsonData
await mock.mockHTTPResponse = HTTPURLResponse(...)

// URL para downloads
await mock.mockDownloadURL = URL(fileURLWithPath: "/tmp/file.pdf")
```

### Verificar Requests

```swift
@Test("Envia request correcta")
func testEnviaRequestCorrecta() async throws {
    let mock = MockNetworkClient()
    await mock.setResponse(EmptyResponse())
    
    // Ejecutar
    let repo = MaterialsRepository(client: mock, baseURL: "https://api.test.com")
    _ = try await repo.getMaterials()
    
    // Verificar
    let wasRequested = await mock.wasRequestedWith(url: "/v1/materials")
    #expect(wasRequested)
    
    let usedGet = await mock.wasRequestedWith(method: .get)
    #expect(usedGet)
    
    let count = await mock.requestCount
    #expect(count == 1)
    
    let lastRequest = await mock.lastRequest
    #expect(lastRequest?.url.contains("materials") == true)
}
```

### Resetear Estado

```swift
@Test("Multiples escenarios")
func testMultiplesEscenarios() async throws {
    let mock = MockNetworkClient()
    
    // Escenario 1
    await mock.setResponse(successData)
    // ... test ...
    
    // Reset para escenario 2
    await mock.reset()
    
    // Escenario 2
    await mock.setError(.timeout)
    // ... test ...
}
```

---

## URLProtocolMock

`URLProtocolMock` intercepta requests HTTP reales. Util para tests de integracion.

### Configuracion Basica

```swift
@Test("Test de integracion")
func testIntegracion() async throws {
    // Configurar mock
    URLProtocolMock.reset()
    try URLProtocolMock.setJSONResponse(myExpectedData, statusCode: 200)
    
    // Crear session con mock
    let session = URLProtocolMock.createMockSession()
    
    // Usar session en cliente
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolMock.self]
    
    // Ejecutar request real (interceptada)
    let (data, response) = try await session.data(from: URL(string: "https://api.test.com")!)
    
    // Verificar
    #expect(response.statusCode == 200)
}
```

### Simular Errores

```swift
// Error de red
URLProtocolMock.setNetworkError(.notConnectedToInternet)

// Error HTTP
URLProtocolMock.setHTTPError(statusCode: 500, message: "Server error")

// Timeout
URLProtocolMock.setNetworkError(.timedOut)
```

### Simular Latencia

```swift
// Agregar delay artificial
URLProtocolMock.artificialDelay = 2.0  // 2 segundos

// No olvidar resetear
defer { URLProtocolMock.artificialDelay = 0 }
```

### Handler Personalizado

```swift
URLProtocolMock.requestHandler = { request in
    // Logica custom basada en la request
    if request.url?.path == "/v1/users" {
        let users = [User(id: "1", name: "Test")]
        let data = try JSONEncoder().encode(users)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }
    
    throw URLError(.fileDoesNotExist)
}
```

---

## Fixtures JSON

Los fixtures JSON proveen datos de prueba consistentes.

### Cargar Fixtures

```swift
// Ubicacion: Tests/NetworkTests/Fixtures/materials.json

// Cargar en test (requiere Bundle.module)
func loadFixture<T: Decodable>(_ name: String) throws -> T {
    let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(T.self, from: data)
}

@Test("Usa fixture de materials")
func testUsaFixture() throws {
    let materials: [MaterialDTO] = try loadFixture("materials")
    #expect(materials.count > 0)
}
```

### Estructura de Fixtures

**materials.json**:
```json
{
  "material_single": {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "title": "Introduccion a las Matematicas",
    "status": "ready"
  },
  "material_list": [...],
  "assessment_request": {...},
  "assessment_result": {...}
}
```

**progress.json**:
```json
{
  "progress_request": {
    "material_id": "uuid",
    "user_id": "uuid",
    "percentage": 75
  },
  "progress_response": {...}
}
```

---

## Testing de Repositorios

### Test de Operacion Exitosa

```swift
@Suite("MaterialsRepository Tests")
struct MaterialsRepositoryTests {
    
    @Test("getMaterials retorna lista de materiales")
    func testGetMaterials() async throws {
        // Arrange
        let mock = MockNetworkClient()
        let repo = MaterialsRepository(client: mock, baseURL: "https://api.test.com")
        
        let expectedMaterials = [
            MaterialDTO(id: "1", title: "Math", ...)
        ]
        await mock.setResponse(expectedMaterials)
        
        // Act
        let result = try await repo.getMaterials()
        
        // Assert
        #expect(result.count == 1)
        #expect(result[0].id == "1")
    }
}
```

### Test de Validacion

```swift
@Test("getMaterial lanza error para ID vacio")
func testGetMaterialIdVacio() async throws {
    let mock = MockNetworkClient()
    let repo = MaterialsRepository(client: mock, baseURL: "https://api.test.com")
    
    await #expect(throws: MaterialsRepositoryError.invalidMaterialId("")) {
        _ = try await repo.getMaterial(id: "")
    }
}

@Test("getMaterial lanza error para UUID invalido")
func testGetMaterialIdInvalido() async throws {
    let mock = MockNetworkClient()
    let repo = MaterialsRepository(client: mock, baseURL: "https://api.test.com")
    
    await #expect(throws: MaterialsRepositoryError.invalidMaterialId("not-a-uuid")) {
        _ = try await repo.getMaterial(id: "not-a-uuid")
    }
}
```

### Test de Mapeo de Errores

```swift
@Test("getMaterial mapea 404 a materialNotFound")
func testGetMaterial404() async throws {
    let mock = MockNetworkClient()
    let repo = MaterialsRepository(client: mock, baseURL: "https://api.test.com")
    
    await mock.setError(.notFound)
    
    let materialId = "550e8400-e29b-41d4-a716-446655440001"
    
    await #expect(throws: MaterialsRepositoryError.materialNotFound(materialId)) {
        _ = try await repo.getMaterial(id: materialId)
    }
}

@Test("getMaterial mapea 401 a unauthorized")
func testGetMaterial401() async throws {
    let mock = MockNetworkClient()
    let repo = MaterialsRepository(client: mock, baseURL: "https://api.test.com")
    
    await mock.setError(.unauthorized)
    
    await #expect(throws: MaterialsRepositoryError.unauthorized) {
        _ = try await repo.getMaterials()
    }
}
```

---

## Testing de Error Handling

### Test de NetworkError Factory

```swift
@Suite("NetworkError Tests")
struct NetworkErrorTests {
    
    @Test("from statusCode crea error correcto")
    func testFromStatusCode() {
        #expect(NetworkError.from(statusCode: 401) == .unauthorized)
        #expect(NetworkError.from(statusCode: 403) == .forbidden)
        #expect(NetworkError.from(statusCode: 404) == .notFound)
        #expect(NetworkError.from(statusCode: 429) == .rateLimited(retryAfter: nil))
        #expect(NetworkError.from(statusCode: 500) == .serverError(statusCode: 500, message: nil))
    }
    
    @Test("from URLError mapea correctamente")
    func testFromURLError() {
        let timeout = NetworkError.from(urlError: URLError(.timedOut))
        #expect(timeout == .timeout)
        
        let cancelled = NetworkError.from(urlError: URLError(.cancelled))
        #expect(cancelled == .cancelled)
    }
}
```

### Test de Status Code Validation

```swift
@Test("isSuccessStatusCode valida 2xx")
func testIsSuccess() {
    #expect(NetworkError.isSuccessStatusCode(200))
    #expect(NetworkError.isSuccessStatusCode(201))
    #expect(NetworkError.isSuccessStatusCode(204))
    #expect(!NetworkError.isSuccessStatusCode(400))
    #expect(!NetworkError.isSuccessStatusCode(500))
}
```

### Test de LocalizedError

```swift
@Test("NetworkError provee descripcion localizada")
func testLocalizedDescription() {
    let unauthorized = NetworkError.unauthorized
    #expect(!unauthorized.localizedDescription.isEmpty)
    
    let rateLimited = NetworkError.rateLimited(retryAfter: 30)
    #expect(rateLimited.localizedDescription.contains("30"))
}
```

---

## Testing de Interceptors

### Test de AuthenticationInterceptor

```swift
@Test("AuthenticationInterceptor agrega header Authorization")
func testAuthInterceptorAgregaHeader() async throws {
    let tokenProvider = StaticTokenProvider(token: "test-token-123")
    let interceptor = AuthenticationInterceptor(
        tokenProvider: tokenProvider,
        autoRefresh: false
    )
    
    let httpRequest = HTTPRequest.get("https://api.test.com")
    let urlRequest = try httpRequest.build()
    
    let adapted = try await interceptor.adapt(
        urlRequest,
        context: RequestContext(originalRequest: httpRequest)
    )
    
    #expect(adapted.value(forHTTPHeaderField: "Authorization") == "Bearer test-token-123")
}
```

### Test de InterceptorChain

```swift
@Test("InterceptorChain aplica adapt en orden")
func testChainOrden() async throws {
    struct HeaderInterceptor: RequestInterceptor {
        let value: String
        
        func adapt(_ request: URLRequest, context: RequestContext) async throws -> URLRequest {
            var modified = request
            modified.setValue(value, forHTTPHeaderField: "X-Test")
            return modified
        }
    }
    
    let first = HeaderInterceptor(value: "A")
    let second = HeaderInterceptor(value: "B")
    let chain = InterceptorChain([first, second])
    
    let httpRequest = HTTPRequest.get("https://test.com")
    let urlRequest = try httpRequest.build()
    
    let adapted = try await chain.adapt(
        urlRequest,
        context: RequestContext(originalRequest: httpRequest)
    )
    
    // El ultimo en la cadena gana
    #expect(adapted.value(forHTTPHeaderField: "X-Test") == "B")
}
```

### Test de Retry Policy

```swift
@Test("ExponentialBackoff calcula delays correctos")
func testExponentialBackoffDelays() {
    let policy = ExponentialBackoffRetryPolicy(
        baseDelay: 1.0,
        maxDelay: 30.0,
        jitterFactor: 0.0,  // Sin jitter para test determinista
        maxRetryCount: 5
    )
    
    #expect(policy.delay(forAttempt: 1) == 1.0)
    #expect(policy.delay(forAttempt: 2) == 2.0)
    #expect(policy.delay(forAttempt: 3) == 4.0)
    #expect(policy.delay(forAttempt: 4) == 8.0)
}

@Test("ExponentialBackoff identifica errores retriable")
func testRetriableErrors() {
    let policy = ExponentialBackoffRetryPolicy.standard
    
    #expect(policy.shouldRetry(error: .timeout))
    #expect(policy.shouldRetry(error: .networkFailure(underlyingError: "offline")))
    #expect(!policy.shouldRetry(error: .unauthorized))
    #expect(!policy.shouldRetry(error: .notFound))
}
```

---

## Mejores Practicas

### 1. Usar Test Fixtures Helper

```swift
enum TestFixtures {
    static let baseURL = "https://api.test.com"
    static let validMaterialId = "550e8400-e29b-41d4-a716-446655440001"
    static let validUserId = "550e8400-e29b-41d4-a716-446655440099"
    static let invalidId = "not-a-uuid"
    
    static func createMaterialDTO() -> MaterialDTO {
        MaterialDTO(
            id: validMaterialId,
            title: "Test Material",
            // ...
        )
    }
}
```

### 2. Aislar Tests con Reset

```swift
@Test("Test aislado")
func testAislado() async throws {
    let mock = MockNetworkClient()
    defer { Task { await mock.reset() } }
    
    // Test...
}
```

### 3. Usar await Correctamente con Actors

```swift
// CORRECTO
let count = await mock.requestCount
let wasRequested = await mock.wasRequested

// INCORRECTO - Error de compilacion
let count = mock.requestCount  // Actor-isolated property
```

### 4. Nombrar Tests Descriptivamente

```swift
// BUENO
@Test("getMaterial lanza materialNotFound cuando servidor retorna 404")

// MALO
@Test("test404")
```

### 5. Probar Casos Limite

```swift
@Test("updateProgress acepta valores limite 0 y 100")
func testBoundaryValues() async throws {
    let mock = MockNetworkClient()
    let repo = ProgressRepository(client: mock, baseURL: TestFixtures.baseURL)
    
    // Test 0%
    await mock.setResponse(ProgressDTO(percentage: 0, ...))
    let result0 = try await repo.updateProgress(request: UpsertProgressRequest(percentage: 0, ...))
    #expect(result0.percentage == 0)
    
    // Test 100%
    await mock.setResponse(ProgressDTO(percentage: 100, ...))
    let result100 = try await repo.updateProgress(request: UpsertProgressRequest(percentage: 100, ...))
    #expect(result100.percentage == 100)
}
```

### 6. Verificar No Solo Exito Sino Tambien Comportamiento

```swift
@Test("submitAssessment envia request POST correcta")
func testSubmitAssessmentRequest() async throws {
    let mock = MockNetworkClient()
    await mock.setResponse(expectedResult)
    
    let repo = MaterialsRepository(client: mock, baseURL: "https://api.test.com")
    _ = try await repo.submitAssessment(materialId: "uuid", request: attemptRequest)
    
    // Verificar URL
    let wasRequestedURL = await mock.wasRequestedWith(url: "assessment/attempts")
    #expect(wasRequestedURL)
    
    // Verificar metodo
    let wasPost = await mock.wasRequestedWith(method: .post)
    #expect(wasPost)
    
    // Verificar que solo se hizo una request
    let count = await mock.requestCount
    #expect(count == 1)
}
```

### 7. Ejecutar Tests

```bash
# Todos los tests
swift test

# Tests especificos
swift test --filter "MaterialsRepository"

# Con verbose output
swift test -v
```
