import Testing
import Foundation
@testable import UseCases
import Models
import EduGoCommon

// MARK: - Mock Repositories

/// Mock de AuthRepository para testing
actor MockAuthRepository: AuthRepositoryProtocol {
    var shouldFailLogin = false
    var shouldFailRefresh = false
    var shouldFailLogout = false

    var loginCallCount = 0
    var refreshCallCount = 0
    var logoutCallCount = 0

    var mockUser: User?
    var mockAccessToken = "mock-access-token"
    var mockRefreshToken = "mock-refresh-token"

    func login(email: String, password: String) async throws -> (user: User, accessToken: String, refreshToken: String) {
        loginCallCount += 1

        if shouldFailLogin {
            throw RepositoryError.connectionError(reason: "Mock login error")
        }

        let user = mockUser ?? (try! User(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: email,
            isActive: true
        ))

        return (user, mockAccessToken, mockRefreshToken)
    }

    func refreshToken(_ refreshToken: String) async throws -> (accessToken: String, refreshToken: String) {
        refreshCallCount += 1

        if shouldFailRefresh {
            throw RepositoryError.fetchFailed(reason: "Token expirado")
        }

        return ("new-access-token", "new-refresh-token")
    }

    func logout() async throws {
        logoutCallCount += 1

        if shouldFailLogout {
            throw RepositoryError.connectionError(reason: "Servidor no disponible")
        }
    }

    func reset() {
        loginCallCount = 0
        refreshCallCount = 0
        logoutCallCount = 0
        shouldFailLogin = false
        shouldFailRefresh = false
        shouldFailLogout = false
    }
}

/// Mock de TokenRepository para testing
actor MockTokenRepository: TokenRepositoryProtocol {
    var storedAccessToken: String?
    var storedRefreshToken: String?
    var shouldFailSave = false
    var shouldFailClear = false

    var saveCallCount = 0
    var clearCallCount = 0

    func saveTokens(accessToken: String, refreshToken: String) async throws {
        saveCallCount += 1

        if shouldFailSave {
            throw RepositoryError.saveFailed(reason: "Mock save error")
        }

        storedAccessToken = accessToken
        storedRefreshToken = refreshToken
    }

    func getAccessToken() async throws -> String? {
        storedAccessToken
    }

    func getRefreshToken() async throws -> String? {
        storedRefreshToken
    }

    func clearTokens() async throws {
        clearCallCount += 1

        if shouldFailClear {
            throw RepositoryError.deleteFailed(reason: "Mock clear error")
        }

        storedAccessToken = nil
        storedRefreshToken = nil
    }

    func reset() {
        storedAccessToken = nil
        storedRefreshToken = nil
        shouldFailSave = false
        shouldFailClear = false
        saveCallCount = 0
        clearCallCount = 0
    }
}

/// Mock de UserRepository para testing
actor MockUserRepository: UserRepositoryProtocol {
    var users: [UUID: User] = [:]
    var shouldFailSave = false

    var saveCallCount = 0

    func get(id: UUID) async throws -> User? {
        users[id]
    }

    func save(_ user: User) async throws {
        saveCallCount += 1

        if shouldFailSave {
            throw RepositoryError.saveFailed(reason: "Mock save error")
        }

        users[user.id] = user
    }

    func delete(id: UUID) async throws {
        users.removeValue(forKey: id)
    }

    func list() async throws -> [User] {
        Array(users.values)
    }

    func reset() {
        users = [:]
        shouldFailSave = false
        saveCallCount = 0
    }
}

/// Mock de SessionRepository para testing
actor MockSessionRepository: SessionRepositoryProtocol {
    var isCleared = false
    var shouldFailClear = false

    var clearCallCount = 0

    func clearSession() async throws {
        clearCallCount += 1

        if shouldFailClear {
            throw RepositoryError.deleteFailed(reason: "Mock clear session error")
        }

        isCleared = true
    }

    func reset() {
        isCleared = false
        shouldFailClear = false
        clearCallCount = 0
    }
}

// MARK: - LoginUseCase Tests

@Suite("LoginUseCase Tests")
struct LoginUseCaseTests {

    @Test("execute con credenciales válidas retorna LoginOutput")
    func executeWithValidCredentials() async throws {
        let authRepo = MockAuthRepository()
        let userRepo = MockUserRepository()
        let tokenRepo = MockTokenRepository()
        let useCase = LoginUseCase(
            authRepository: authRepo,
            userRepository: userRepo,
            tokenRepository: tokenRepo
        )

        let input = LoginInput(
            email: "test@edugo.com",
            password: "password123"
        )

        let output = try await useCase.execute(input: input)

        #expect(output.user.email == "test@edugo.com")
        #expect(output.accessToken == "mock-access-token")
        #expect(output.refreshToken == "mock-refresh-token")

        // Verificar que se llamaron los repositorios
        let loginCalls = await authRepo.loginCallCount
        let saveCalls = await userRepo.saveCallCount
        let tokenSaveCalls = await tokenRepo.saveCallCount

        #expect(loginCalls == 1)
        #expect(saveCalls == 1)
        #expect(tokenSaveCalls == 1)
    }

    @Test("execute con email inválido lanza precondition error")
    func executeWithInvalidEmail() async {
        let authRepo = MockAuthRepository()
        let userRepo = MockUserRepository()
        let tokenRepo = MockTokenRepository()
        let useCase = LoginUseCase(
            authRepository: authRepo,
            userRepository: userRepo,
            tokenRepository: tokenRepo
        )

        let input = LoginInput(
            email: "invalid-email",
            password: "password123"
        )

        await #expect(throws: UseCaseError.self) {
            try await useCase.execute(input: input)
        }
    }

    @Test("execute con contraseña corta lanza precondition error")
    func executeWithShortPassword() async {
        let authRepo = MockAuthRepository()
        let userRepo = MockUserRepository()
        let tokenRepo = MockTokenRepository()
        let useCase = LoginUseCase(
            authRepository: authRepo,
            userRepository: userRepo,
            tokenRepository: tokenRepo
        )

        let input = LoginInput(
            email: "test@edugo.com",
            password: "short"
        )

        await #expect(throws: UseCaseError.self) {
            try await useCase.execute(input: input)
        }
    }

    @Test("execute cuando authRepository falla propaga el error")
    func executeWhenAuthRepositoryFails() async {
        let authRepo = MockAuthRepository()
        await authRepo.setShouldFailLogin(true)
        let userRepo = MockUserRepository()
        let tokenRepo = MockTokenRepository()
        let useCase = LoginUseCase(
            authRepository: authRepo,
            userRepository: userRepo,
            tokenRepository: tokenRepo
        )

        let input = LoginInput(
            email: "test@edugo.com",
            password: "password123"
        )

        await #expect(throws: UseCaseError.self) {
            try await useCase.execute(input: input)
        }
    }

    @Test("execute guarda tokens correctamente")
    func executeSavesTokensCorrectly() async throws {
        let authRepo = MockAuthRepository()
        let userRepo = MockUserRepository()
        let tokenRepo = MockTokenRepository()
        let useCase = LoginUseCase(
            authRepository: authRepo,
            userRepository: userRepo,
            tokenRepository: tokenRepo
        )

        let input = LoginInput(
            email: "test@edugo.com",
            password: "password123"
        )

        _ = try await useCase.execute(input: input)

        let accessToken = try await tokenRepo.getAccessToken()
        let refreshToken = try await tokenRepo.getRefreshToken()

        #expect(accessToken == "mock-access-token")
        #expect(refreshToken == "mock-refresh-token")
    }
}

// MARK: - MockAuthRepository Helper Extensions

extension MockAuthRepository {
    func setShouldFailLogin(_ value: Bool) {
        shouldFailLogin = value
    }

    func setShouldFailRefresh(_ value: Bool) {
        shouldFailRefresh = value
    }

    func setShouldFailLogout(_ value: Bool) {
        shouldFailLogout = value
    }
}

// MARK: - RefreshTokenUseCase Tests

@Suite("RefreshTokenUseCase Tests")
struct RefreshTokenUseCaseTests {

    @Test("execute con token válido retorna TokenOutput")
    func executeWithValidToken() async throws {
        let authRepo = MockAuthRepository()
        let tokenRepo = MockTokenRepository()
        let useCase = RefreshTokenUseCase(
            authRepository: authRepo,
            tokenRepository: tokenRepo
        )

        let input = RefreshTokenInput(refreshToken: "valid-refresh-token-abcdef123456")

        let output = try await useCase.execute(input: input)

        #expect(output.accessToken == "new-access-token")
        #expect(output.refreshToken == "new-refresh-token")

        let refreshCalls = await authRepo.refreshCallCount
        let saveCalls = await tokenRepo.saveCallCount

        #expect(refreshCalls == 1)
        #expect(saveCalls == 1)
    }

    @Test("execute con token vacío lanza precondition error")
    func executeWithEmptyToken() async {
        let authRepo = MockAuthRepository()
        let tokenRepo = MockTokenRepository()
        let useCase = RefreshTokenUseCase(
            authRepository: authRepo,
            tokenRepository: tokenRepo
        )

        let input = RefreshTokenInput(refreshToken: "   ")

        await #expect(throws: UseCaseError.self) {
            try await useCase.execute(input: input)
        }
    }

    @Test("execute con token muy corto lanza precondition error")
    func executeWithShortToken() async {
        let authRepo = MockAuthRepository()
        let tokenRepo = MockTokenRepository()
        let useCase = RefreshTokenUseCase(
            authRepository: authRepo,
            tokenRepository: tokenRepo
        )

        let input = RefreshTokenInput(refreshToken: "short")

        await #expect(throws: UseCaseError.self) {
            try await useCase.execute(input: input)
        }
    }

    @Test("execute guarda nuevos tokens atómicamente")
    func executeSavesNewTokensAtomically() async throws {
        let authRepo = MockAuthRepository()
        let tokenRepo = MockTokenRepository()
        let useCase = RefreshTokenUseCase(
            authRepository: authRepo,
            tokenRepository: tokenRepo
        )

        let input = RefreshTokenInput(refreshToken: "valid-refresh-token-xyz789")

        _ = try await useCase.execute(input: input)

        let newAccessToken = try await tokenRepo.getAccessToken()
        let newRefreshToken = try await tokenRepo.getRefreshToken()

        #expect(newAccessToken == "new-access-token")
        #expect(newRefreshToken == "new-refresh-token")
    }

    @Test("execute cuando authRepository falla propaga el error")
    func executeWhenAuthRepositoryFails() async {
        let authRepo = MockAuthRepository()
        await authRepo.setShouldFailRefresh(true)
        let tokenRepo = MockTokenRepository()
        let useCase = RefreshTokenUseCase(
            authRepository: authRepo,
            tokenRepository: tokenRepo
        )

        let input = RefreshTokenInput(refreshToken: "valid-refresh-token-abc123")

        await #expect(throws: UseCaseError.self) {
            try await useCase.execute(input: input)
        }
    }
}

// MARK: - LogoutUseCase Tests

@Suite("LogoutUseCase Tests")
struct LogoutUseCaseTests {

    @Test("execute limpia todos los repositorios exitosamente")
    func executeClearsAllRepositories() async throws {
        let authRepo = MockAuthRepository()
        let tokenRepo = MockTokenRepository()
        let sessionRepo = MockSessionRepository()
        let useCase = LogoutUseCase(
            authRepository: authRepo,
            tokenRepository: tokenRepo,
            sessionRepository: sessionRepo
        )

        try await useCase.execute()

        let logoutCalls = await authRepo.logoutCallCount
        let clearTokenCalls = await tokenRepo.clearCallCount
        let clearSessionCalls = await sessionRepo.clearCallCount

        #expect(logoutCalls == 1)
        #expect(clearTokenCalls == 1)
        #expect(clearSessionCalls == 1)
    }

    @Test("execute limpia tokens localmente")
    func executeClearsTokensLocally() async throws {
        let authRepo = MockAuthRepository()
        let tokenRepo = MockTokenRepository()

        // Setup: guardar tokens primero
        try await tokenRepo.saveTokens(
            accessToken: "some-token",
            refreshToken: "some-refresh"
        )

        let sessionRepo = MockSessionRepository()
        let useCase = LogoutUseCase(
            authRepository: authRepo,
            tokenRepository: tokenRepo,
            sessionRepository: sessionRepo
        )

        try await useCase.execute()

        let accessToken = try await tokenRepo.getAccessToken()
        let refreshToken = try await tokenRepo.getRefreshToken()

        #expect(accessToken == nil)
        #expect(refreshToken == nil)
    }

    @Test("execute limpia sesión localmente")
    func executeClearsSessionLocally() async throws {
        let authRepo = MockAuthRepository()
        let tokenRepo = MockTokenRepository()
        let sessionRepo = MockSessionRepository()
        let useCase = LogoutUseCase(
            authRepository: authRepo,
            tokenRepository: tokenRepo,
            sessionRepository: sessionRepo
        )

        try await useCase.execute()

        let isCleared = await sessionRepo.isCleared
        #expect(isCleared == true)
    }

    @Test("execute no bloquea cuando authRepository falla")
    func executeDoesNotBlockWhenAuthRepositoryFails() async throws {
        let authRepo = MockAuthRepository()
        await authRepo.setShouldFailLogout(true)
        let tokenRepo = MockTokenRepository()
        let sessionRepo = MockSessionRepository()
        let useCase = LogoutUseCase(
            authRepository: authRepo,
            tokenRepository: tokenRepo,
            sessionRepository: sessionRepo
        )

        // No debe lanzar error
        try await useCase.execute()

        // Debe haber limpiado localmente de todas formas
        let clearTokenCalls = await tokenRepo.clearCallCount
        let clearSessionCalls = await sessionRepo.clearCallCount

        #expect(clearTokenCalls == 1)
        #expect(clearSessionCalls == 1)
    }

    @Test("execute lanza error cuando tokenRepository falla")
    func executeThrowsWhenTokenRepositoryFails() async {
        let authRepo = MockAuthRepository()
        let tokenRepo = MockTokenRepository()
        await tokenRepo.setShouldFailClear(true)
        let sessionRepo = MockSessionRepository()
        let useCase = LogoutUseCase(
            authRepository: authRepo,
            tokenRepository: tokenRepo,
            sessionRepository: sessionRepo
        )

        await #expect(throws: UseCaseError.self) {
            try await useCase.execute()
        }
    }
}

// MARK: - MockTokenRepository Helper Extensions

extension MockTokenRepository {
    func setShouldFailClear(_ value: Bool) {
        shouldFailClear = value
    }
}
