# CQRS Examples

Ejemplos prácticos y avanzados de uso del módulo CQRS.

## Tabla de Contenidos

1. [Crear Query + Handler Custom](#crear-query--handler-custom)
2. [Crear Command + Handler Custom](#crear-command--handler-custom)
3. [Validación Custom en Commands](#validación-custom-en-commands)
4. [Manejo de Errores en Handlers](#manejo-de-errores-en-handlers)
5. [Cache Strategy Personalizada](#cache-strategy-personalizada)
6. [Testing de Handlers](#testing-de-handlers)
7. [Integración con SwiftUI](#integración-con-swiftui)
8. [Uso Avanzado: Queries Compuestas](#uso-avanzado-queries-compuestas)

---

## Crear Query + Handler Custom

### Paso 1: Definir la Query

```swift
import CQRS
import Models

/// Query para obtener el progreso del estudiante en un curso específico
struct GetStudentProgressQuery: Query {
    typealias Result = StudentProgress
    
    let studentId: String
    let courseId: String
    let includeAssessments: Bool
    
    var metadata: [String: String]?
}
```

### Paso 2: Implementar el Handler

```swift
import CQRS
import UseCases
import Foundation

actor GetStudentProgressQueryHandler: QueryHandler {
    typealias QueryType = GetStudentProgressQuery
    
    // Dependencias
    private let getProgressUseCase: GetStudentProgressUseCase
    
    // Cache (opcional)
    private var cache: [String: (data: StudentProgress, expiry: Date)] = [:]
    private let cacheTTL: TimeInterval = 300 // 5 minutos
    
    init(getProgressUseCase: GetStudentProgressUseCase) {
        self.getProgressUseCase = getProgressUseCase
    }
    
    func handle(_ query: GetStudentProgressQuery) async throws -> StudentProgress {
        let cacheKey = "\(query.studentId)-\(query.courseId)"
        
        // Check cache
        if let cached = cache[cacheKey], cached.expiry > Date() {
            return cached.data
        }
        
        // Fetch fresh data
        let progress = try await getProgressUseCase.execute(
            studentId: query.studentId,
            courseId: query.courseId,
            includeAssessments: query.includeAssessments
        )
        
        // Update cache
        cache[cacheKey] = (progress, Date().addingTimeInterval(cacheTTL))
        
        return progress
    }
    
    func invalidateCache(for studentId: String, courseId: String) {
        let cacheKey = "\(studentId)-\(courseId)"
        cache.removeValue(forKey: cacheKey)
    }
}
```

### Paso 3: Registrar en el Mediator

```swift
// En AppDelegate o inicio de la app
let mediator = Mediator()

let handler = GetStudentProgressQueryHandler(
    getProgressUseCase: getStudentProgressUseCase
)

try await mediator.registerQueryHandler(handler)
```

### Paso 4: Usar en ViewModel

```swift
import SwiftUI
import CQRS

@MainActor
class CourseViewModel: ObservableObject {
    @Published var progress: StudentProgress?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let mediator: Mediator
    private let studentId: String
    private let courseId: String
    
    init(mediator: Mediator, studentId: String, courseId: String) {
        self.mediator = mediator
        self.studentId = studentId
        self.courseId = courseId
    }
    
    func loadProgress() async {
        isLoading = true
        errorMessage = nil
        
        do {
            progress = try await mediator.send(GetStudentProgressQuery(
                studentId: studentId,
                courseId: courseId,
                includeAssessments: true
            ))
        } catch {
            errorMessage = "Error al cargar progreso: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
```

---

## Crear Command + Handler Custom

### Paso 1: Definir el Command

```swift
import CQRS
import Models
import Foundation

/// Command para subir una respuesta de assessment
struct SubmitAssessmentAnswerCommand: Command {
    typealias Result = SubmissionResult
    
    let assessmentId: String
    let studentId: String
    let questionId: String
    let answer: String
    let submittedAt: Date
    
    var metadata: [String: String]?
    
    func validate() throws {
        // Validar que el answer no esté vacío
        guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyAnswer
        }
        
        // Validar que la fecha no sea futura
        guard submittedAt <= Date() else {
            throw ValidationError.futureSubmission
        }
        
        // Validar formato de IDs
        guard !assessmentId.isEmpty, !studentId.isEmpty, !questionId.isEmpty else {
            throw ValidationError.invalidIdentifiers
        }
    }
}

enum ValidationError: Error {
    case emptyAnswer
    case futureSubmission
    case invalidIdentifiers
}
```

### Paso 2: Implementar el Handler

```swift
import CQRS
import UseCases
import Foundation

actor SubmitAssessmentAnswerCommandHandler: CommandHandler {
    typealias CommandType = SubmitAssessmentAnswerCommand
    
    // Dependencias
    private let submitAnswerUseCase: SubmitAssessmentAnswerUseCase
    
    // Weak refs a handlers que necesitan invalidación
    weak var studentProgressHandler: GetStudentProgressQueryHandler?
    weak var dashboardHandler: GetStudentDashboardQueryHandler?
    
    init(submitAnswerUseCase: SubmitAssessmentAnswerUseCase) {
        self.submitAnswerUseCase = submitAnswerUseCase
    }
    
    func handle(_ command: SubmitAssessmentAnswerCommand) async throws -> CommandResult<SubmissionResult> {
        // Ejecutar caso de uso
        let result = try await submitAnswerUseCase.execute(
            assessmentId: command.assessmentId,
            studentId: command.studentId,
            questionId: command.questionId,
            answer: command.answer,
            submittedAt: command.submittedAt
        )
        
        // Invalidar caches relacionados
        await invalidateRelatedCaches(
            studentId: command.studentId,
            assessmentId: command.assessmentId
        )
        
        // Generar eventos
        let events = [
            "AssessmentAnswerSubmitted",
            result.isCorrect ? "CorrectAnswerSubmitted" : "IncorrectAnswerSubmitted"
        ]
        
        // Metadata adicional
        let metadata: [String: String] = [
            "studentId": command.studentId,
            "assessmentId": command.assessmentId,
            "isCorrect": String(result.isCorrect),
            "timestamp": ISO8601DateFormatter().string(from: command.submittedAt)
        ]
        
        return CommandResult(
            result: result,
            events: events,
            metadata: metadata
        )
    }
    
    private func invalidateRelatedCaches(studentId: String, assessmentId: String) async {
        // Invalidar progreso del estudiante
        await studentProgressHandler?.invalidateCache(
            for: studentId,
            courseId: assessmentId
        )
        
        // Invalidar dashboard
        await dashboardHandler?.invalidateCache(for: studentId)
    }
}
```

### Paso 3: Registrar y Ejecutar

```swift
// Registro
let handler = SubmitAssessmentAnswerCommandHandler(
    submitAnswerUseCase: submitAnswerUseCase
)

// Conectar weak refs para cache invalidation
handler.studentProgressHandler = progressHandler
handler.dashboardHandler = dashboardHandler

try await mediator.registerCommandHandler(handler)

// Uso
let result = try await mediator.execute(SubmitAssessmentAnswerCommand(
    assessmentId: "assess-123",
    studentId: "student-456",
    questionId: "q-789",
    answer: "42",
    submittedAt: Date()
))

if result.isSuccess {
    print("Respuesta enviada exitosamente")
    print("Eventos: \(result.events)")
    print("Correcta: \(result.metadata["isCorrect"] ?? "unknown")")
}
```

---

## Validación Custom en Commands

### Validación Simple

```swift
struct CreateUserCommand: Command {
    typealias Result = User
    
    let username: String
    let email: String
    let age: Int
    
    func validate() throws {
        // Username
        guard !username.isEmpty else {
            throw ValidationError.emptyUsername
        }
        guard username.count >= 3 else {
            throw ValidationError.usernameTooShort
        }
        
        // Email
        guard email.contains("@") else {
            throw ValidationError.invalidEmail
        }
        
        // Age
        guard age >= 18 else {
            throw ValidationError.underage
        }
    }
}
```

### Validación con Regex

```swift
struct UpdateEmailCommand: Command {
    typealias Result = Bool
    
    let userId: String
    let newEmail: String
    
    func validate() throws {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: newEmail) else {
            throw ValidationError.invalidEmailFormat(newEmail)
        }
    }
}

enum ValidationError: Error {
    case invalidEmailFormat(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidEmailFormat(let email):
            return "Email inválido: \(email)"
        }
    }
}
```

### Validación Asíncrona (en Handler)

Si la validación requiere I/O (ej: verificar si un username ya existe), hacerla en el handler, no en `validate()`:

```swift
actor CreateUserCommandHandler: CommandHandler {
    typealias CommandType = CreateUserCommand
    
    private let checkUsernameUseCase: CheckUsernameAvailabilityUseCase
    
    func handle(_ command: CreateUserCommand) async throws -> CommandResult<User> {
        // Validación síncrona ya pasó (Command.validate())
        
        // Validación asíncrona
        let isAvailable = try await checkUsernameUseCase.execute(command.username)
        guard isAvailable else {
            throw DomainError.usernameAlreadyExists(command.username)
        }
        
        // Continuar con la creación...
        let user = try await createUserUseCase.execute(command)
        
        return CommandResult(
            result: user,
            events: ["UserCreated"],
            metadata: ["userId": user.id]
        )
    }
}
```

---

## Manejo de Errores en Handlers

### Handler con Múltiples Tipos de Error

```swift
actor LoginCommandHandler: CommandHandler {
    typealias CommandType = LoginCommand
    
    private let authUseCase: AuthenticateUserUseCase
    
    func handle(_ command: LoginCommand) async throws -> CommandResult<AuthResult> {
        do {
            let authResult = try await authUseCase.execute(
                username: command.username,
                password: command.password
            )
            
            return CommandResult(
                result: authResult,
                events: ["UserLoggedIn"],
                metadata: ["userId": authResult.userId]
            )
            
        } catch let error as AuthError {
            // Manejar errores de autenticación específicos
            switch error {
            case .invalidCredentials:
                throw MediatorError.executionError(
                    message: "Usuario o contraseña incorrectos",
                    underlyingError: error
                )
            case .accountLocked:
                throw MediatorError.executionError(
                    message: "Cuenta bloqueada. Contacte al administrador",
                    underlyingError: error
                )
            case .accountExpired:
                throw MediatorError.executionError(
                    message: "Cuenta expirada",
                    underlyingError: error
                )
            }
            
        } catch {
            // Error genérico
            throw MediatorError.executionError(
                message: "Error al iniciar sesión",
                underlyingError: error
            )
        }
    }
}
```

### Retry Logic en Handler

```swift
actor UploadMaterialCommandHandler: CommandHandler {
    typealias CommandType = UploadMaterialCommand
    
    private let uploadUseCase: UploadMaterialUseCase
    private let maxRetries = 3
    
    func handle(_ command: UploadMaterialCommand) async throws -> CommandResult<UploadResult> {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                let result = try await uploadUseCase.execute(command)
                
                return CommandResult(
                    result: result,
                    events: ["MaterialUploaded"],
                    metadata: ["attempt": String(attempt)]
                )
                
            } catch let error as NetworkError where error.isRetryable {
                lastError = error
                
                if attempt < maxRetries {
                    // Exponential backoff
                    let delay = TimeInterval(pow(2.0, Double(attempt)))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            } catch {
                // Error no-retryable, fallar inmediatamente
                throw error
            }
        }
        
        // Todos los intentos fallaron
        throw MediatorError.executionError(
            message: "Failed to upload after \(maxRetries) attempts",
            underlyingError: lastError
        )
    }
}
```

---

## Cache Strategy Personalizada

### Cache con TTL

```swift
actor GetCourseMaterialsQueryHandler: QueryHandler {
    typealias QueryType = GetCourseMaterialsQuery
    
    private struct CachedEntry {
        let data: [Material]
        let expiry: Date
    }
    
    private var cache: [String: CachedEntry] = [:]
    private let cacheTTL: TimeInterval = 600 // 10 minutos
    
    func handle(_ query: GetCourseMaterialsQuery) async throws -> [Material] {
        let cacheKey = query.courseId
        
        // Check cache
        if let cached = cache[cacheKey], cached.expiry > Date() {
            return cached.data
        }
        
        // Fetch fresh
        let materials = try await useCase.execute(courseId: query.courseId)
        
        // Store in cache
        cache[cacheKey] = CachedEntry(
            data: materials,
            expiry: Date().addingTimeInterval(cacheTTL)
        )
        
        return materials
    }
    
    func invalidateCache(for courseId: String) {
        cache.removeValue(forKey: courseId)
    }
}
```

### Cache con Stale-While-Revalidate

```swift
actor GetDashboardQueryHandler: QueryHandler {
    typealias QueryType = GetDashboardQuery
    
    private var cachedDashboard: StudentDashboard?
    private var isFetching = false
    
    func handle(_ query: GetDashboardQuery) async throws -> StudentDashboard {
        // Si tenemos cache, retornar inmediatamente
        if let cached = cachedDashboard {
            // Refrescar en background si no estamos fetching ya
            if !isFetching {
                Task {
                    await refreshInBackground(query: query)
                }
            }
            return cached
        }
        
        // No hay cache, fetch normalmente
        return try await fetchAndCache(query: query)
    }
    
    private func fetchAndCache(query: GetDashboardQuery) async throws -> StudentDashboard {
        isFetching = true
        defer { isFetching = false }
        
        let dashboard = try await useCase.execute(studentId: query.studentId)
        cachedDashboard = dashboard
        return dashboard
    }
    
    private func refreshInBackground(query: GetDashboardQuery) async {
        do {
            _ = try await fetchAndCache(query: query)
        } catch {
            // Silent fail en background refresh
            print("Background refresh failed: \(error)")
        }
    }
}
```

### Cache con LRU Eviction

```swift
actor LRUCacheQueryHandler: QueryHandler {
    typealias QueryType = GetUserDetailsQuery
    
    private struct CacheEntry {
        let data: UserDetails
        var lastAccessed: Date
    }
    
    private var cache: [String: CacheEntry] = [:]
    private let maxCacheSize = 100
    
    func handle(_ query: GetUserDetailsQuery) async throws -> UserDetails {
        let cacheKey = query.userId
        
        // Check cache
        if var cached = cache[cacheKey] {
            // Update last accessed
            cached.lastAccessed = Date()
            cache[cacheKey] = cached
            return cached.data
        }
        
        // Fetch fresh
        let details = try await useCase.execute(userId: query.userId)
        
        // Evict if necessary
        if cache.count >= maxCacheSize {
            evictLeastRecentlyUsed()
        }
        
        // Store in cache
        cache[cacheKey] = CacheEntry(
            data: details,
            lastAccessed: Date()
        )
        
        return details
    }
    
    private func evictLeastRecentlyUsed() {
        guard let lruKey = cache.min(by: { $0.value.lastAccessed < $1.value.lastAccessed })?.key else {
            return
        }
        cache.removeValue(forKey: lruKey)
    }
}
```

---

## Testing de Handlers

### Test de Query Handler

```swift
import XCTest
@testable import CQRS

final class GetStudentProgressHandlerTests: XCTestCase {
    
    func testHandleReturnsProgress() async throws {
        // Arrange
        let mockUseCase = MockGetStudentProgressUseCase()
        mockUseCase.mockProgress = StudentProgress(
            studentId: "student-123",
            courseId: "course-456",
            completionPercentage: 75.0
        )
        
        let handler = GetStudentProgressQueryHandler(
            getProgressUseCase: mockUseCase
        )
        
        let query = GetStudentProgressQuery(
            studentId: "student-123",
            courseId: "course-456",
            includeAssessments: true
        )
        
        // Act
        let result = try await handler.handle(query)
        
        // Assert
        XCTAssertEqual(result.studentId, "student-123")
        XCTAssertEqual(result.completionPercentage, 75.0)
    }
    
    func testHandleUsesCacheOnSecondCall() async throws {
        // Arrange
        let mockUseCase = MockGetStudentProgressUseCase()
        let handler = GetStudentProgressQueryHandler(
            getProgressUseCase: mockUseCase
        )
        
        let query = GetStudentProgressQuery(
            studentId: "student-123",
            courseId: "course-456",
            includeAssessments: true
        )
        
        // Act
        _ = try await handler.handle(query)
        _ = try await handler.handle(query)
        
        // Assert
        XCTAssertEqual(mockUseCase.executeCallCount, 1, "UseCase should be called only once (cache hit)")
    }
}

actor MockGetStudentProgressUseCase: GetStudentProgressUseCase {
    var mockProgress: StudentProgress?
    var executeCallCount = 0
    
    func execute(studentId: String, courseId: String, includeAssessments: Bool) async throws -> StudentProgress {
        executeCallCount += 1
        guard let progress = mockProgress else {
            throw MockError.noMockData
        }
        return progress
    }
}
```

### Test de Command Handler

```swift
final class SubmitAssessmentAnswerHandlerTests: XCTestCase {
    
    func testHandleGeneratesCorrectEvents() async throws {
        // Arrange
        let mockUseCase = MockSubmitAnswerUseCase()
        mockUseCase.mockResult = SubmissionResult(isCorrect: true, score: 10)
        
        let handler = SubmitAssessmentAnswerCommandHandler(
            submitAnswerUseCase: mockUseCase
        )
        
        let command = SubmitAssessmentAnswerCommand(
            assessmentId: "assess-123",
            studentId: "student-456",
            questionId: "q-789",
            answer: "42",
            submittedAt: Date()
        )
        
        // Act
        let result = try await handler.handle(command)
        
        // Assert
        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(result.events.contains("CorrectAnswerSubmitted"))
        XCTAssertEqual(result.metadata["isCorrect"], "true")
    }
    
    func testHandleInvalidatesCaches() async throws {
        // Arrange
        let mockUseCase = MockSubmitAnswerUseCase()
        let mockProgressHandler = MockProgressHandler()
        let mockDashboardHandler = MockDashboardHandler()
        
        let handler = SubmitAssessmentAnswerCommandHandler(
            submitAnswerUseCase: mockUseCase
        )
        handler.studentProgressHandler = mockProgressHandler
        handler.dashboardHandler = mockDashboardHandler
        
        let command = SubmitAssessmentAnswerCommand(
            assessmentId: "assess-123",
            studentId: "student-456",
            questionId: "q-789",
            answer: "42",
            submittedAt: Date()
        )
        
        // Act
        _ = try await handler.handle(command)
        
        // Assert
        let progressInvalidated = await mockProgressHandler.invalidateCalled
        let dashboardInvalidated = await mockDashboardHandler.invalidateCalled
        
        XCTAssertTrue(progressInvalidated)
        XCTAssertTrue(dashboardInvalidated)
    }
}
```

---

## Integración con SwiftUI

### ViewModel Completo

```swift
import SwiftUI
import CQRS
import Combine

@MainActor
class AssessmentViewModel: ObservableObject {
    // Published properties
    @Published var assessment: Assessment?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var submitSuccess = false
    
    // Dependencies
    private let mediator: Mediator
    private let assessmentId: String
    private let studentId: String
    
    init(mediator: Mediator, assessmentId: String, studentId: String) {
        self.mediator = mediator
        self.assessmentId = assessmentId
        self.studentId = studentId
    }
    
    // Load assessment
    func loadAssessment() async {
        isLoading = true
        errorMessage = nil
        
        do {
            assessment = try await mediator.send(GetAssessmentQuery(
                assessmentId: assessmentId,
                includeQuestions: true
            ))
        } catch MediatorError.handlerNotFound {
            errorMessage = "Handler no encontrado"
        } catch MediatorError.executionError(let msg, _) {
            errorMessage = msg
        } catch {
            errorMessage = "Error inesperado: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Submit answer
    func submitAnswer(questionId: String, answer: String) async {
        isLoading = true
        errorMessage = nil
        submitSuccess = false
        
        do {
            let result = try await mediator.execute(SubmitAssessmentAnswerCommand(
                assessmentId: assessmentId,
                studentId: studentId,
                questionId: questionId,
                answer: answer,
                submittedAt: Date()
            ))
            
            if result.isSuccess {
                submitSuccess = true
                
                // Reload assessment to get updated state
                await loadAssessment()
            }
            
        } catch MediatorError.validationError(let msg, _) {
            errorMessage = "Validación: \(msg)"
        } catch MediatorError.executionError(let msg, _) {
            errorMessage = "Error: \(msg)"
        } catch {
            errorMessage = "Error inesperado"
        }
        
        isLoading = false
    }
}
```

### SwiftUI View

```swift
struct AssessmentView: View {
    @StateObject var viewModel: AssessmentViewModel
    @State private var currentAnswer = ""
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Cargando...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.loadAssessment() }
                }
            } else if let assessment = viewModel.assessment {
                AssessmentContent(
                    assessment: assessment,
                    currentAnswer: $currentAnswer,
                    onSubmit: {
                        Task {
                            await viewModel.submitAnswer(
                                questionId: assessment.currentQuestionId,
                                answer: currentAnswer
                            )
                        }
                    }
                )
            }
        }
        .task {
            await viewModel.loadAssessment()
        }
        .alert("Respuesta enviada", isPresented: $viewModel.submitSuccess) {
            Button("OK") { currentAnswer = "" }
        }
    }
}
```

---

## Uso Avanzado: Queries Compuestas

Cuando necesitas datos de múltiples queries:

```swift
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var dashboard: StudentDashboard?
    @Published var recentMaterials: [Material] = []
    @Published var upcomingAssessments: [Assessment] = []
    @Published var isLoading = false
    
    private let mediator: Mediator
    private let studentId: String
    
    func loadAll() async {
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            // Load dashboard
            group.addTask {
                await self.loadDashboard()
            }
            
            // Load materials
            group.addTask {
                await self.loadMaterials()
            }
            
            // Load assessments
            group.addTask {
                await self.loadAssessments()
            }
        }
        
        isLoading = false
    }
    
    private func loadDashboard() async {
        do {
            dashboard = try await mediator.send(GetStudentDashboardQuery(
                studentId: studentId
            ))
        } catch {
            print("Error loading dashboard: \(error)")
        }
    }
    
    private func loadMaterials() async {
        do {
            recentMaterials = try await mediator.send(ListMaterialsQuery(
                studentId: studentId,
                limit: 5
            ))
        } catch {
            print("Error loading materials: \(error)")
        }
    }
    
    private func loadAssessments() async {
        do {
            upcomingAssessments = try await mediator.send(ListUpcomingAssessmentsQuery(
                studentId: studentId,
                limit: 3
            ))
        } catch {
            print("Error loading assessments: \(error)")
        }
    }
}
```

**Beneficios**:
- Todas las queries se ejecutan concurrentemente
- Total type-safe
- Error handling independiente por query
- UI se actualiza incrementalmente

---

## Conclusión

Estos ejemplos cubren los casos de uso más comunes del módulo CQRS. Para patrones más avanzados (Event Sourcing, Saga pattern, etc.), consulta los sprints futuros y la documentación del EventBus (Sprint 4).

---

**Última actualización**: 2026-01-30  
**Versión**: 1.0.0
