# Guía de Manejo de Errores Tipados en EduGo Apple Modules

**Versión**: 1.0.0
**Última actualización**: 2026-01-26
**Autor**: EduGo iOS Team

---

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Jerarquía de Errores](#jerarquía-de-errores)
3. [Errores por Capa](#errores-por-capa)
4. [Patrón de Wrapping](#patrón-de-wrapping)
5. [Propagación con async/await](#propagación-con-asyncawait)
6. [Presentación en UI](#presentación-en-ui)
7. [Anti-Patrones](#anti-patrones)
8. [Flujo de Errores entre Capas](#flujo-de-errores-entre-capas)
9. [Checklist de Code Review](#checklist-de-code-review)
10. [Ejemplos Completos](#ejemplos-completos)

---

## Introducción

EduGo Apple Modules implementa una jerarquía de errores tipados que se alinea con la arquitectura de 4 tiers del sistema. Esta guía documenta cómo usar correctamente cada tipo de error, cuándo propagar o transformar errores entre capas, y cómo presentarlos al usuario final.

### Objetivos

- **Claridad**: Cada capa tiene su propio tipo de error, facilitando el debugging
- **Trazabilidad**: Los errores pueden ser encapsulados manteniendo el contexto original
- **Localización**: Todos los errores implementan `LocalizedError` para mensajes en español
- **Concurrencia segura**: Todos los errores son `Sendable` (Swift 6.2 strict concurrency)

### Tipos de Error por Tier

| Tier | Tipo de Error | Responsabilidad |
|------|---------------|-----------------|
| TIER-0 (Foundation) | `DomainError` | Validaciones de negocio, reglas de dominio |
| TIER-1 (Data Layer) | `RepositoryError` | Operaciones de persistencia y red |
| TIER-2 (Services) | `UseCaseError` | Lógica de aplicación, wrapping de errores inferiores |
| TIER-3 (Features) | `UseCaseError` + manejo en UI | Presentación de errores al usuario |

---

## Jerarquía de Errores

```swift
// TIER-0: Foundation
public enum DomainError: Error, LocalizedError, Sendable {
    case validationFailed(field: String, reason: String)
    case businessRuleViolated(rule: String)
    case invalidOperation(operation: String)
    case entityNotFound(type: String, id: String)
}

// TIER-1: Data Layer
public enum RepositoryError: Error, LocalizedError, Sendable {
    case fetchFailed(reason: String)
    case saveFailed(reason: String)
    case deleteFailed(reason: String)
    case connectionError(underlyingError: Error?)
    case serializationError(type: String)
    case dataInconsistency(description: String)
}

// TIER-2 y TIER-3: Services y Features
public enum UseCaseError: Error, LocalizedError, Sendable {
    case preconditionFailed(description: String)
    case unauthorized(action: String)
    case domainError(DomainError)          // Wrapping
    case repositoryError(RepositoryError)  // Wrapping
    case executionFailed(reason: String)
    case timeout
}
```

### Conformidades Obligatorias

Todos los errores deben conformar:

1. `Error`: Para poder ser lanzados con `throw`
2. `LocalizedError`: Para proporcionar mensajes descriptivos
3. `Sendable`: Para cumplir con Swift 6.2 strict concurrency

---

## Errores por Capa

### TIER-0: DomainError

Uso en entidades de dominio y lógica de negocio pura.

#### Cuándo usar cada caso

| Caso | Cuándo usarlo | Ejemplo |
|------|---------------|---------|
| `validationFailed` | Validación de datos de entrada falla | Email inválido, edad negativa |
| `businessRuleViolated` | Se viola una regla de negocio | Estudiante inscrito en más de 6 materias |
| `invalidOperation` | Operación no permitida en estado actual | Calificar examen no enviado |
| `entityNotFound` | Entidad de dominio no existe | Estudiante con ID inexistente |

#### Ejemplos

```swift
// Validación en entidad de dominio
public struct Student: Sendable {
    public let id: UUID
    public let name: String
    public let email: String
    public let age: Int

    public init(id: UUID, name: String, email: String, age: Int) throws {
        // Validación de nombre
        guard !name.isEmpty else {
            throw DomainError.validationFailed(
                field: "name",
                reason: "El nombre no puede estar vacío"
            )
        }

        // Validación de email
        guard email.contains("@") else {
            throw DomainError.validationFailed(
                field: "email",
                reason: "Formato de correo electrónico inválido"
            )
        }

        // Regla de negocio
        guard age >= 18 else {
            throw DomainError.businessRuleViolated(
                rule: "Los estudiantes deben ser mayores de edad (18+)"
            )
        }

        self.id = id
        self.name = name
        self.email = email
        self.age = age
    }
}

// Validación en método de dominio
extension Student {
    public func enroll(in course: Course) throws {
        guard course.capacity > course.enrolledCount else {
            throw DomainError.invalidOperation(
                operation: "No se puede inscribir en un curso que alcanzó su capacidad máxima"
            )
        }

        guard course.startDate > Date() else {
            throw DomainError.invalidOperation(
                operation: "No se puede inscribir en un curso que ya comenzó"
            )
        }
    }
}
```

---

### TIER-1: RepositoryError

Uso en repositorios, clientes de red, y operaciones de persistencia.

#### Cuándo usar cada caso

| Caso | Cuándo usarlo | Ejemplo |
|------|---------------|---------|
| `fetchFailed` | Error al leer datos | API retorna 404, BD local vacía |
| `saveFailed` | Error al escribir datos | Fallo de sincronización, disco lleno |
| `deleteFailed` | Error al eliminar datos | Registro referenciado por FK |
| `connectionError` | Error de red/conectividad | Sin internet, timeout |
| `serializationError` | Error de parsing JSON | Formato inesperado, campos faltantes |
| `dataInconsistency` | Datos corruptos o inconsistentes | Múltiples registros con mismo ID |

#### Ejemplos

```swift
// Repositorio con manejo de errores
public protocol StudentRepository: Sendable {
    func fetch(id: UUID) async throws -> Student
    func save(_ student: Student) async throws
    func delete(id: UUID) async throws
}

public final class APIStudentRepository: StudentRepository {
    private let baseURL: URL
    private let session: URLSession

    public func fetch(id: UUID) async throws -> Student {
        // Construir URL
        guard let url = URL(string: "\(baseURL)/students/\(id)") else {
            throw RepositoryError.fetchFailed(
                reason: "URL inválida para estudiante con ID \(id)"
            )
        }

        // Ejecutar request
        do {
            let (data, response) = try await session.data(from: url)

            // Validar response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RepositoryError.fetchFailed(
                    reason: "Respuesta HTTP inválida"
                )
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw RepositoryError.fetchFailed(
                    reason: "Código HTTP \(httpResponse.statusCode)"
                )
            }

            // Deserializar
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(Student.self, from: data)
            } catch {
                throw RepositoryError.serializationError(type: "Student")
            }

        } catch let error as RepositoryError {
            throw error
        } catch {
            // Wrappear errores de URLSession
            throw RepositoryError.connectionError(underlyingError: error)
        }
    }

    public func save(_ student: Student) async throws {
        guard let url = URL(string: "\(baseURL)/students/\(student.id)") else {
            throw RepositoryError.saveFailed(
                reason: "URL inválida para estudiante"
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(student)
        } catch {
            throw RepositoryError.serializationError(type: "Student")
        }

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw RepositoryError.saveFailed(
                    reason: "Falló la sincronización con el servidor"
                )
            }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.connectionError(underlyingError: error)
        }
    }
}
```

---

### TIER-2 y TIER-3: UseCaseError

Uso en servicios (TIER-2) y ViewModels (TIER-3).

#### Cuándo usar cada caso

| Caso | Cuándo usarlo | Ejemplo |
|------|---------------|---------|
| `preconditionFailed` | Precondición del caso de uso no cumplida | Usuario no autenticado |
| `unauthorized` | Falta de permisos | Modificar datos de otro usuario |
| `domainError` | Wrappear error de TIER-0 | Validación de dominio falló |
| `repositoryError` | Wrappear error de TIER-1 | Fallo de red/persistencia |
| `executionFailed` | Error genérico de ejecución | Proceso complejo falló |
| `timeout` | Operación excedió tiempo límite | Operación larga cancelada |

#### Ejemplos

```swift
// Use Case (TIER-2)
public protocol EnrollStudentUseCase: Sendable {
    func execute(studentId: UUID, courseId: UUID) async throws -> Enrollment
}

public final class DefaultEnrollStudentUseCase: EnrollStudentUseCase {
    private let studentRepository: StudentRepository
    private let courseRepository: CourseRepository
    private let enrollmentRepository: EnrollmentRepository

    public init(
        studentRepository: StudentRepository,
        courseRepository: CourseRepository,
        enrollmentRepository: EnrollmentRepository
    ) {
        self.studentRepository = studentRepository
        self.courseRepository = courseRepository
        self.enrollmentRepository = enrollmentRepository
    }

    public func execute(studentId: UUID, courseId: UUID) async throws -> Enrollment {
        // Validar precondición
        guard await AuthManager.shared.isAuthenticated else {
            throw UseCaseError.preconditionFailed(
                description: "El usuario debe estar autenticado para inscribirse"
            )
        }

        // Fetch student
        let student: Student
        do {
            student = try await studentRepository.fetch(id: studentId)
        } catch let error as RepositoryError {
            // Wrappear error de repositorio
            throw UseCaseError.repositoryError(error)
        }

        // Fetch course
        let course: Course
        do {
            course = try await courseRepository.fetch(id: courseId)
        } catch let error as RepositoryError {
            throw UseCaseError.repositoryError(error)
        }

        // Validar regla de dominio
        do {
            try student.enroll(in: course)
        } catch let error as DomainError {
            // Wrappear error de dominio
            throw UseCaseError.domainError(error)
        }

        // Crear enrollment
        let enrollment = Enrollment(
            id: UUID(),
            studentId: studentId,
            courseId: courseId,
            enrolledAt: Date()
        )

        // Persistir
        do {
            try await enrollmentRepository.save(enrollment)
        } catch let error as RepositoryError {
            throw UseCaseError.repositoryError(error)
        }

        return enrollment
    }
}

// ViewModel (TIER-3)
@MainActor
public final class EnrollmentViewModel: ObservableObject {
    @Published public private(set) var state: ViewState = .idle
    @Published public private(set) var errorMessage: String?

    private let enrollUseCase: EnrollStudentUseCase

    public enum ViewState {
        case idle
        case loading
        case success
        case error
    }

    public init(enrollUseCase: EnrollStudentUseCase) {
        self.enrollUseCase = enrollUseCase
    }

    public func enrollStudent(studentId: UUID, courseId: UUID) async {
        state = .loading
        errorMessage = nil

        do {
            _ = try await enrollUseCase.execute(
                studentId: studentId,
                courseId: courseId
            )
            state = .success
        } catch let error as UseCaseError {
            state = .error
            errorMessage = error.localizedDescription
        } catch {
            state = .error
            errorMessage = "Error inesperado: \(error.localizedDescription)"
        }
    }
}
```

---

## Patrón de Wrapping

El patrón de wrapping permite que `UseCaseError` encapsule errores de capas inferiores manteniendo el contexto original.

### Wrapping de DomainError

```swift
do {
    try validateBusinessRule()
} catch let error as DomainError {
    throw UseCaseError.domainError(error)
}
```

### Wrapping de RepositoryError

```swift
do {
    let data = try await repository.fetch(id: id)
} catch let error as RepositoryError {
    throw UseCaseError.repositoryError(error)
}
```

### Unwrapping de Errores Encapsulados

```swift
do {
    try await useCase.execute()
} catch let error as UseCaseError {
    // Acceder a error de dominio encapsulado
    if let domainError = error.underlyingDomainError {
        switch domainError {
        case .validationFailed(let field, let reason):
            print("Validación falló en \(field): \(reason)")
        case .businessRuleViolated(let rule):
            print("Regla violada: \(rule)")
        default:
            break
        }
    }

    // Acceder a error de repositorio encapsulado
    if let repoError = error.underlyingRepositoryError {
        switch repoError {
        case .connectionError:
            print("Error de conexión, reintentando...")
        case .fetchFailed(let reason):
            print("Fetch falló: \(reason)")
        default:
            break
        }
    }
}
```

### Ejemplo Completo de Wrapping

```swift
public final class CreateStudentUseCase {
    private let repository: StudentRepository

    public func execute(name: String, email: String, age: Int) async throws -> Student {
        // 1. Validar en dominio (puede lanzar DomainError)
        let student: Student
        do {
            student = try Student(id: UUID(), name: name, email: email, age: age)
        } catch let error as DomainError {
            // Wrappear error de dominio
            throw UseCaseError.domainError(error)
        }

        // 2. Persistir (puede lanzar RepositoryError)
        do {
            try await repository.save(student)
        } catch let error as RepositoryError {
            // Wrappear error de repositorio
            throw UseCaseError.repositoryError(error)
        }

        return student
    }
}
```

---

## Propagación con async/await

### Reglas de Propagación

1. Siempre capture el tipo específico de error con `catch let error as ErrorType`
2. Wrappee errores de capas inferiores antes de propagar
3. Use `async throws` en la firma de funciones que pueden fallar
4. Documente los errores que puede lanzar usando DocC

### Ejemplo de Propagación en Cadena

```swift
// TIER-1: Repository
public func fetchStudent(id: UUID) async throws -> Student {
    // ... lógica que puede lanzar RepositoryError
    throw RepositoryError.fetchFailed(reason: "No encontrado")
}

// TIER-2: Use Case
public func getStudentProfile(id: UUID) async throws -> StudentProfile {
    do {
        let student = try await repository.fetchStudent(id: id)
        return StudentProfile(from: student)
    } catch let error as RepositoryError {
        throw UseCaseError.repositoryError(error)
    }
}

// TIER-3: ViewModel
@MainActor
public func loadProfile(id: UUID) async {
    state = .loading
    do {
        let profile = try await useCase.getStudentProfile(id: id)
        self.profile = profile
        state = .success
    } catch let error as UseCaseError {
        errorMessage = error.localizedDescription
        state = .error

        // Manejo específico según tipo de error encapsulado
        if let repoError = error.underlyingRepositoryError {
            switch repoError {
            case .connectionError:
                // Mostrar botón de reintentar
                showRetryButton = true
            default:
                break
            }
        }
    }
}
```

### Timeout con async/await

```swift
public func executeWithTimeout() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        // Tarea principal
        group.addTask {
            try await self.longRunningOperation()
        }

        // Tarea de timeout
        group.addTask {
            try await Task.sleep(nanoseconds: 30_000_000_000) // 30 segundos
            throw UseCaseError.timeout
        }

        // Retornar el primero que complete (éxito o timeout)
        try await group.next()
        group.cancelAll()
    }
}
```

---

## Presentación en UI

### Uso de LocalizedError

Todos los errores implementan `LocalizedError`, proporcionando:

- `errorDescription`: Mensaje principal
- `failureReason`: Razón técnica del fallo
- `recoverySuggestion`: Sugerencia de recuperación

### Ejemplo en SwiftUI

```swift
@MainActor
public final class CourseListViewModel: ObservableObject {
    @Published public private(set) var courses: [Course] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorAlert: ErrorAlert?

    private let fetchCoursesUseCase: FetchCoursesUseCase

    public struct ErrorAlert: Identifiable {
        public let id = UUID()
        public let title: String
        public let message: String
        public let recoverySuggestion: String?
    }

    public func loadCourses() async {
        isLoading = true
        errorAlert = nil

        do {
            courses = try await fetchCoursesUseCase.execute()
        } catch let error as UseCaseError {
            errorAlert = ErrorAlert(
                title: "Error al cargar cursos",
                message: error.errorDescription ?? "Error desconocido",
                recoverySuggestion: error.recoverySuggestion
            )
        } catch {
            errorAlert = ErrorAlert(
                title: "Error inesperado",
                message: error.localizedDescription,
                recoverySuggestion: "Intente nuevamente más tarde"
            )
        }

        isLoading = false
    }
}

// Vista SwiftUI
public struct CourseListView: View {
    @StateObject private var viewModel: CourseListViewModel

    public var body: some View {
        List(viewModel.courses) { course in
            CourseRow(course: course)
        }
        .alert(item: $viewModel.errorAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .task {
            await viewModel.loadCourses()
        }
    }
}
```

### Presentación de Errores con Contexto

```swift
@MainActor
public func presentError(_ error: UseCaseError) {
    // Determinar tipo de alerta según error encapsulado
    if let domainError = error.underlyingDomainError {
        switch domainError {
        case .validationFailed(let field, let reason):
            showValidationError(field: field, reason: reason)
        case .businessRuleViolated(let rule):
            showBusinessRuleAlert(rule: rule)
        default:
            showGenericAlert(error.localizedDescription)
        }
    } else if let repoError = error.underlyingRepositoryError {
        switch repoError {
        case .connectionError:
            showConnectionErrorWithRetry()
        case .fetchFailed, .saveFailed:
            showDataErrorAlert()
        default:
            showGenericAlert(error.localizedDescription)
        }
    } else {
        showGenericAlert(error.localizedDescription)
    }
}
```

---

## Anti-Patrones

### 1. Usar UseCaseError en capa de dominio

**Incorrecto**:
```swift
// En TIER-0 (Dominio)
public struct Student {
    public init(name: String) throws {
        guard !name.isEmpty else {
            throw UseCaseError.preconditionFailed(description: "Nombre vacío") // ❌
        }
        self.name = name
    }
}
```

**Correcto**:
```swift
// En TIER-0 (Dominio)
public struct Student {
    public init(name: String) throws {
        guard !name.isEmpty else {
            throw DomainError.validationFailed(field: "name", reason: "El nombre no puede estar vacío") // ✅
        }
        self.name = name
    }
}
```

### 2. No wrappear errores de capas inferiores

**Incorrecto**:
```swift
// En TIER-2 (Use Case)
public func execute() async throws {
    let student = try await repository.fetch(id: id) // ❌ Propaga RepositoryError directamente
}
```

**Correcto**:
```swift
// En TIER-2 (Use Case)
public func execute() async throws {
    do {
        let student = try await repository.fetch(id: id)
    } catch let error as RepositoryError {
        throw UseCaseError.repositoryError(error) // ✅ Wrappea el error
    }
}
```

### 3. Usar strings genéricos en lugar de casos específicos

**Incorrecto**:
```swift
throw RepositoryError.fetchFailed(reason: "Error") // ❌ Mensaje genérico
```

**Correcto**:
```swift
throw RepositoryError.fetchFailed(reason: "El servidor respondió con código 404") // ✅ Mensaje específico
```

### 4. No documentar errores con DocC

**Incorrecto**:
```swift
public func fetch(id: UUID) async throws -> Student {
    // ...
}
```

**Correcto**:
```swift
/// Recupera un estudiante por su identificador único.
///
/// - Parameter id: Identificador único del estudiante
/// - Returns: El estudiante encontrado
/// - Throws: `RepositoryError.fetchFailed` si el estudiante no existe
///           `RepositoryError.connectionError` si hay problemas de red
public func fetch(id: UUID) async throws -> Student {
    // ...
}
```

### 5. Silenciar errores sin logging

**Incorrecto**:
```swift
do {
    try await operation()
} catch {
    // ❌ Error silenciado
}
```

**Correcto**:
```swift
do {
    try await operation()
} catch {
    // ✅ Log del error
    logger.error("Operación falló: \(error.localizedDescription)")
    throw error
}
```

### 6. Exponer errores internos a UI

**Incorrecto**:
```swift
// ViewModel exponiendo RepositoryError directamente
@Published var error: RepositoryError? // ❌
```

**Correcto**:
```swift
// ViewModel exponiendo solo mensajes de usuario
@Published var errorMessage: String? // ✅
```

---

## Flujo de Errores entre Capas

### Diagrama de Flujo

```
┌───────────────────────────────────────────────────────────────┐
│ TIER-3: Feature (UI)                                          │
│                                                               │
│  ┌──────────────────────────────────────────────────┐        │
│  │ ViewModel                                        │        │
│  │                                                  │        │
│  │  do {                                            │        │
│  │    try await useCase.execute()                   │        │
│  │  } catch let error as UseCaseError {             │        │
│  │    errorMessage = error.localizedDescription ◄───┼────────┼─── Presentar al usuario
│  │  }                                               │        │
│  └──────────────────────────────────────────────────┘        │
│                          ▲                                    │
│                          │ UseCaseError                       │
└──────────────────────────┼────────────────────────────────────┘
                           │
┌──────────────────────────┼────────────────────────────────────┐
│ TIER-2: Service (Use Case)                                    │
│                          │                                    │
│  ┌──────────────────────────────────────────────────┐        │
│  │ UseCase                                          │        │
│  │                                                  │        │
│  │  do {                                            │        │
│  │    let data = try await repository.fetch(id)     │        │
│  │    try validateBusinessRule(data)                │        │
│  │  } catch let error as DomainError {              │        │
│  │    throw UseCaseError.domainError(error) ────────┼────────┼─── Wrapping
│  │  } catch let error as RepositoryError {          │        │
│  │    throw UseCaseError.repositoryError(error) ────┼────────┼─── Wrapping
│  │  }                                               │        │
│  └──────────────────────────────────────────────────┘        │
│                     ▲              ▲                          │
│                     │              │                          │
│              DomainError    RepositoryError                   │
└─────────────────────┼──────────────┼─────────────────────────┘
                      │              │
┌─────────────────────┼──────────────┼─────────────────────────┐
│ TIER-1: Data Layer  │              │                         │
│                     │              │                         │
│  ┌─────────────────────────────────────────────┐            │
│  │ Repository                                  │            │
│  │                                             │            │
│  │  do {                                       │            │
│  │    let response = try await urlSession.data │            │
│  │    return try decoder.decode(...)           │            │
│  │  } catch {                                  │            │
│  │    throw RepositoryError.connectionError ───┼────────────┼─── Lanzar
│  │  }                                          │            │
│  └─────────────────────────────────────────────┘            │
│                          ▲                                   │
└──────────────────────────┼───────────────────────────────────┘
                           │
┌──────────────────────────┼───────────────────────────────────┐
│ TIER-0: Foundation       │                                   │
│                          │                                   │
│  ┌─────────────────────────────────────────────┐            │
│  │ Domain Model                                │            │
│  │                                             │            │
│  │  init(name: String) throws {                │            │
│  │    guard !name.isEmpty else {               │            │
│  │      throw DomainError.validationFailed ────┼────────────┼─── Lanzar
│  │    }                                        │            │
│  │  }                                          │            │
│  └─────────────────────────────────────────────┘            │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Matriz de Transformación de Errores

| Capa Origen | Error Lanzado | Capa Destino | Error Recibido | Acción |
|-------------|---------------|--------------|----------------|--------|
| TIER-0 | `DomainError` | TIER-2 | `DomainError` | Wrappear en `UseCaseError.domainError` |
| TIER-1 | `RepositoryError` | TIER-2 | `RepositoryError` | Wrappear en `UseCaseError.repositoryError` |
| TIER-2 | `UseCaseError` | TIER-3 | `UseCaseError` | Presentar con `LocalizedError` |
| URLSession | `URLError` | TIER-1 | `URLError` | Wrappear en `RepositoryError.connectionError` |
| JSONDecoder | `DecodingError` | TIER-1 | `DecodingError` | Wrappear en `RepositoryError.serializationError` |

---

## Checklist de Code Review

Use este checklist al revisar código que maneja errores:

### Errores de Dominio (TIER-0)

- [ ] Los errores se lanzan usando `DomainError`
- [ ] No se usa `UseCaseError` ni `RepositoryError` en esta capa
- [ ] Los mensajes de error son descriptivos y específicos
- [ ] Las validaciones usan los casos apropiados (`validationFailed`, `businessRuleViolated`, etc.)
- [ ] Los errores están documentados con DocC

### Errores de Repositorio (TIER-1)

- [ ] Los errores se lanzan usando `RepositoryError`
- [ ] Los errores de red/URLSession se wrappean en `connectionError`
- [ ] Los errores de serialización se wrappean en `serializationError`
- [ ] No se propagan errores raw de frameworks del sistema
- [ ] Los mensajes incluyen contexto útil para debugging

### Errores de Use Case (TIER-2)

- [ ] Los errores de `DomainError` se wrappean en `UseCaseError.domainError`
- [ ] Los errores de `RepositoryError` se wrappean en `UseCaseError.repositoryError`
- [ ] Se usa `catch let error as ErrorType` para capturar tipos específicos
- [ ] Las precondiciones de negocio usan `preconditionFailed`
- [ ] La autorización usa `unauthorized`
- [ ] Los errores wrappados mantienen el contexto original

### Presentación en UI (TIER-3)

- [ ] Los ViewModels capturan `UseCaseError`
- [ ] Se usa `errorDescription` para mensajes de usuario
- [ ] No se exponen tipos de error internos (`RepositoryError`, `DomainError`)
- [ ] Los errores se presentan de forma user-friendly
- [ ] Se proporciona `recoverySuggestion` cuando es apropiado
- [ ] Los errores de conexión ofrecen opción de reintentar

### General

- [ ] Todas las funciones `async throws` documentan los errores que lanzan
- [ ] No hay errores silenciados sin logging
- [ ] Los errores críticos se logguean con nivel apropiado
- [ ] No se usa `try!` ni `try?` sin justificación
- [ ] Los tests validan el manejo de errores

---

## Ejemplos Completos

### Ejemplo 1: Flujo de Inscripción a Curso

```swift
// TIER-0: Dominio
public struct Enrollment: Sendable {
    public let id: UUID
    public let studentId: UUID
    public let courseId: UUID
    public let enrolledAt: Date

    public init(id: UUID, studentId: UUID, courseId: UUID, enrolledAt: Date) throws {
        guard enrolledAt <= Date() else {
            throw DomainError.validationFailed(
                field: "enrolledAt",
                reason: "La fecha de inscripción no puede ser futura"
            )
        }

        self.id = id
        self.studentId = studentId
        self.courseId = courseId
        self.enrolledAt = enrolledAt
    }
}

// TIER-1: Repositorio
public final class APIEnrollmentRepository: EnrollmentRepository {
    private let baseURL: URL
    private let session: URLSession

    public func save(_ enrollment: Enrollment) async throws {
        guard let url = URL(string: "\(baseURL)/enrollments") else {
            throw RepositoryError.saveFailed(reason: "URL inválida")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(enrollment)
        } catch {
            throw RepositoryError.serializationError(type: "Enrollment")
        }

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw RepositoryError.saveFailed(
                    reason: "El servidor rechazó la inscripción"
                )
            }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.connectionError(underlyingError: error)
        }
    }
}

// TIER-2: Use Case
public final class EnrollStudentUseCase {
    private let studentRepo: StudentRepository
    private let courseRepo: CourseRepository
    private let enrollmentRepo: EnrollmentRepository

    public init(
        studentRepo: StudentRepository,
        courseRepo: CourseRepository,
        enrollmentRepo: EnrollmentRepository
    ) {
        self.studentRepo = studentRepo
        self.courseRepo = courseRepo
        self.enrollmentRepo = enrollmentRepo
    }

    public func execute(studentId: UUID, courseId: UUID) async throws -> Enrollment {
        // Validar autenticación
        guard await AuthManager.shared.isAuthenticated else {
            throw UseCaseError.preconditionFailed(
                description: "Debe estar autenticado para inscribirse"
            )
        }

        // Obtener estudiante
        let student: Student
        do {
            student = try await studentRepo.fetch(id: studentId)
        } catch let error as RepositoryError {
            throw UseCaseError.repositoryError(error)
        }

        // Obtener curso
        let course: Course
        do {
            course = try await courseRepo.fetch(id: courseId)
        } catch let error as RepositoryError {
            throw UseCaseError.repositoryError(error)
        }

        // Validar regla de negocio
        do {
            try student.enroll(in: course)
        } catch let error as DomainError {
            throw UseCaseError.domainError(error)
        }

        // Crear inscripción
        let enrollment: Enrollment
        do {
            enrollment = try Enrollment(
                id: UUID(),
                studentId: studentId,
                courseId: courseId,
                enrolledAt: Date()
            )
        } catch let error as DomainError {
            throw UseCaseError.domainError(error)
        }

        // Guardar inscripción
        do {
            try await enrollmentRepo.save(enrollment)
        } catch let error as RepositoryError {
            throw UseCaseError.repositoryError(error)
        }

        return enrollment
    }
}

// TIER-3: ViewModel
@MainActor
public final class EnrollmentViewModel: ObservableObject {
    @Published public private(set) var state: State = .idle
    @Published public private(set) var errorAlert: ErrorAlert?

    private let enrollUseCase: EnrollStudentUseCase

    public enum State {
        case idle
        case enrolling
        case enrolled
        case failed
    }

    public struct ErrorAlert: Identifiable {
        public let id = UUID()
        public let title: String
        public let message: String
        public let suggestion: String?
    }

    public init(enrollUseCase: EnrollStudentUseCase) {
        self.enrollUseCase = enrollUseCase
    }

    public func enrollStudent(studentId: UUID, courseId: UUID) async {
        state = .enrolling
        errorAlert = nil

        do {
            _ = try await enrollUseCase.execute(studentId: studentId, courseId: courseId)
            state = .enrolled
        } catch let error as UseCaseError {
            state = .failed

            // Determinar tipo de error y presentar apropiadamente
            if let domainError = error.underlyingDomainError {
                switch domainError {
                case .businessRuleViolated(let rule):
                    errorAlert = ErrorAlert(
                        title: "No se puede inscribir",
                        message: rule,
                        suggestion: "Verifique los requisitos del curso"
                    )
                default:
                    errorAlert = ErrorAlert(
                        title: "Error de validación",
                        message: error.localizedDescription,
                        suggestion: error.recoverySuggestion
                    )
                }
            } else if let repoError = error.underlyingRepositoryError {
                switch repoError {
                case .connectionError:
                    errorAlert = ErrorAlert(
                        title: "Sin conexión",
                        message: "No se pudo conectar con el servidor",
                        suggestion: "Verifique su conexión a internet e intente nuevamente"
                    )
                default:
                    errorAlert = ErrorAlert(
                        title: "Error del servidor",
                        message: error.localizedDescription,
                        suggestion: error.recoverySuggestion
                    )
                }
            } else {
                errorAlert = ErrorAlert(
                    title: "Error",
                    message: error.localizedDescription,
                    suggestion: error.recoverySuggestion
                )
            }
        }
    }
}

// TIER-3: Vista
public struct EnrollmentView: View {
    @StateObject private var viewModel: EnrollmentViewModel
    let studentId: UUID
    let courseId: UUID

    public var body: some View {
        VStack {
            switch viewModel.state {
            case .idle:
                Button("Inscribirse") {
                    Task {
                        await viewModel.enrollStudent(
                            studentId: studentId,
                            courseId: courseId
                        )
                    }
                }

            case .enrolling:
                ProgressView("Inscribiendo...")

            case .enrolled:
                Text("¡Inscripción exitosa!")
                    .foregroundColor(.green)

            case .failed:
                Text("Error al inscribir")
                    .foregroundColor(.red)
            }
        }
        .alert(item: $viewModel.errorAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("Entendido"))
            )
        }
    }
}
```

---

## Referencias

- [ARCHITECTURE.md](../../ARCHITECTURE.md) - Decisiones de arquitectura
- [DEVELOPMENT_GUIDE.md](../../DEVELOPMENT_GUIDE.md) - Guía de desarrollo
- [Swift Error Handling Best Practices](https://docs.swift.org/swift-book/LanguageGuide/ErrorHandling.html)
- [LocalizedError Documentation](https://developer.apple.com/documentation/foundation/localizederror)

---

**Última revisión**: 2026-01-26
**Próxima revisión**: 2026-04-26
**Maintainer**: @edugo-ios-team
