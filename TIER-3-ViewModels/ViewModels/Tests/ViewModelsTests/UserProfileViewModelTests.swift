import Foundation
import Testing
@testable import ViewModels
@testable import CQRS
import Models
import UseCases
import EduGoCommon

/// Tests unitarios para UserProfileViewModel.
///
/// Este test suite valida:
/// - Carga desde cache
/// - Refresh forzado
/// - Modo edición
/// - Guardado de cambios
/// - Validación de campos editados
/// - Computed properties
@Suite("UserProfileViewModel Tests")
struct UserProfileViewModelTests {

    // MARK: - Test: Carga de perfil exitosa

    @Test("Loads profile successfully")
    @MainActor
    func testLoadsProfileSuccessfully() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)
        let mockUpdateHandler = MockUpdateUserProfileCommandHandler()
        try await mediator.registerCommandHandler(mockUpdateHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar a que cargue (se inicia automáticamente en init)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Verify
        #expect(viewModel.hasUser)
        #expect(viewModel.user != nil)
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
    }

    // MARK: - Test: Modo edición

    @Test("Enter edit mode copies user values")
    @MainActor
    func testEnterEditModeCopiesUserValues() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)
        let mockUpdateHandler = MockUpdateUserProfileCommandHandler()
        try await mediator.registerCommandHandler(mockUpdateHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga inicial
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify estado inicial
        #expect(!viewModel.editMode)
        #expect(viewModel.editedFirstName.isEmpty)

        // Execute
        viewModel.enterEditMode()

        // Verify
        #expect(viewModel.editMode)
        #expect(viewModel.editedFirstName == viewModel.user?.firstName)
        #expect(viewModel.editedLastName == viewModel.user?.lastName)
        #expect(viewModel.editedEmail == viewModel.user?.email)
    }

    // MARK: - Test: Cancelar edición

    @Test("Cancel edit clears edited values")
    @MainActor
    func testCancelEditClearsEditedValues() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)
        let mockUpdateHandler = MockUpdateUserProfileCommandHandler()
        try await mediator.registerCommandHandler(mockUpdateHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga y entrar a modo edición
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.enterEditMode()

        // Modificar valores
        viewModel.editedFirstName = "Modified"

        // Execute
        viewModel.cancelEdit()

        // Verify
        #expect(!viewModel.editMode)
        #expect(viewModel.editedFirstName.isEmpty)
        #expect(viewModel.editedLastName.isEmpty)
        #expect(viewModel.editedEmail.isEmpty)
    }

    // MARK: - Test: Guardado de cambios

    @Test("Save changes updates user locally")
    @MainActor
    func testSaveChangesUpdatesUserLocally() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)
        let mockUpdateHandler = MockUpdateUserProfileCommandHandler()
        try await mediator.registerCommandHandler(mockUpdateHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga y entrar a modo edición
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.enterEditMode()

        // Modificar valores
        let newFirstName = "Updated"
        viewModel.editedFirstName = newFirstName

        // Execute
        await viewModel.saveChanges()

        // Verify
        #expect(!viewModel.editMode)
        #expect(!viewModel.isSaving)
        #expect(viewModel.user?.firstName == newFirstName)
        #expect(viewModel.error == nil)
    }

    // MARK: - Test: Validación de campo vacío

    @Test("Save changes validates empty firstName")
    @MainActor
    func testSaveChangesValidatesEmptyFirstName() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)
        let mockUpdateHandler = MockUpdateUserProfileCommandHandler()
        try await mediator.registerCommandHandler(mockUpdateHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga y entrar a modo edición
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.enterEditMode()

        // Vaciar firstName
        viewModel.editedFirstName = ""

        // Execute
        await viewModel.saveChanges()

        // Verify
        #expect(viewModel.hasError)
        #expect(viewModel.editMode) // Sigue en modo edición
    }

    // MARK: - Test: isEdited computed property

    @Test("isEdited returns true when values differ")
    @MainActor
    func testIsEditedReturnsTrueWhenValuesDiffer() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)
        let mockUpdateHandler = MockUpdateUserProfileCommandHandler()
        try await mediator.registerCommandHandler(mockUpdateHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga y entrar a modo edición
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.enterEditMode()

        // Verify: Sin cambios, isEdited es false
        #expect(!viewModel.isEdited)

        // Modificar valor
        viewModel.editedFirstName = "Different"

        // Verify: Con cambios, isEdited es true
        #expect(viewModel.isEdited)
    }

    // MARK: - Test: canSave computed property

    @Test("canSave validates all conditions")
    @MainActor
    func testCanSaveValidatesAllConditions() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)
        let mockUpdateHandler = MockUpdateUserProfileCommandHandler()
        try await mediator.registerCommandHandler(mockUpdateHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga y entrar a modo edición
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.enterEditMode()

        // Sin cambios: canSave es false
        #expect(!viewModel.canSave)

        // Con cambio válido: canSave es true
        viewModel.editedFirstName = "Changed"
        #expect(viewModel.canSave)

        // Con campo vacío: canSave es false
        viewModel.editedEmail = ""
        #expect(!viewModel.canSave)
    }

    // MARK: - Test: Computed properties

    @Test("Computed properties work correctly")
    @MainActor
    func testComputedPropertiesWork() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify
        #expect(viewModel.hasUser)
        #expect(!viewModel.fullName.isEmpty)
        #expect(!viewModel.email.isEmpty)
        #expect(!viewModel.initials.isEmpty)
        #expect(viewModel.initials.count == 2)
    }

    // MARK: - Test: Clear error

    @Test("Clear error works correctly")
    @MainActor
    func testClearErrorWorks() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga y provocar error
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.enterEditMode()
        viewModel.editedFirstName = ""
        await viewModel.saveChanges()

        #expect(viewModel.hasError)

        // Execute
        viewModel.clearError()

        // Verify
        #expect(!viewModel.hasError)
    }

    // MARK: - Test: Refresh forzado

    @Test("Refresh forces reload from server")
    @MainActor
    func testRefreshForcesReload() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga inicial
        try await Task.sleep(nanoseconds: 100_000_000)

        let initialCallCount = await mockHandler.callCount

        // Execute refresh
        await viewModel.refresh()

        // Verify: Handler fue llamado de nuevo
        let newCallCount = await mockHandler.callCount
        #expect(newCallCount > initialCallCount)
    }

    // MARK: - Test: UserProfileUpdatedEvent triggers refresh

    @Test("UserProfileUpdatedEvent triggers refresh")
    @MainActor
    func testUserProfileUpdatedEventTriggersRefresh() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga inicial
        try await Task.sleep(nanoseconds: 100_000_000)
        let initialCallCount = await mockHandler.callCount

        // Act: Publicar evento de perfil actualizado
        let userId = viewModel.user?.id ?? UUID()
        let event = UserProfileUpdatedEvent(
            userId: userId,
            firstName: "Updated",
            lastName: "User",
            email: "updated@example.com"
        )
        await eventBus.publish(event)

        // Esperar refresco
        try await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        let newCallCount = await mockHandler.callCount
        #expect(newCallCount > initialCallCount)
    }

    // MARK: - Test: initials calculation

    @Test("Initials calculated correctly")
    @MainActor
    func testInitialsCalculatedCorrectly() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify: Initials son primera letra de firstName y lastName
        let expectedInitials = "\(viewModel.user!.firstName.prefix(1).uppercased())\(viewModel.user!.lastName.prefix(1).uppercased())"
        #expect(viewModel.initials == expectedInitials)
    }

    // MARK: - Test: Trim newlines from fields

    @Test("Trims newlines from firstName")
    @MainActor
    func testTrimsNewlinesFromFirstName() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)
        let mockUpdateHandler = MockUpdateUserProfileCommandHandler()
        try await mediator.registerCommandHandler(mockUpdateHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga y entrar a modo edición
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.enterEditMode()

        // Execute: Guardar con firstName que contiene newlines
        viewModel.editedFirstName = "John\n"
        viewModel.editedLastName = "Doe"
        viewModel.editedEmail = "john@example.com"

        await viewModel.saveChanges()

        // Verify: Se guardó sin newlines
        #expect(viewModel.user?.firstName == "John")
        #expect(viewModel.error == nil)
    }

    @Test("Trims newlines and carriage returns from lastName")
    @MainActor
    func testTrimsNewlinesFromLastName() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)
        let mockUpdateHandler = MockUpdateUserProfileCommandHandler()
        try await mediator.registerCommandHandler(mockUpdateHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga y entrar a modo edición
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.enterEditMode()

        // Execute: Guardar con lastName que contiene \r\n
        viewModel.editedFirstName = "Jane"
        viewModel.editedLastName = "Smith\r\n"
        viewModel.editedEmail = "jane@example.com"

        await viewModel.saveChanges()

        // Verify: Se guardó sin \r\n
        #expect(viewModel.user?.lastName == "Smith")
        #expect(viewModel.error == nil)
    }

    @Test("Trims tabs and newlines from email")
    @MainActor
    func testTrimsTabsAndNewlinesFromEmail() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)
        let mockUpdateHandler = MockUpdateUserProfileCommandHandler()
        try await mediator.registerCommandHandler(mockUpdateHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga y entrar a modo edición
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.enterEditMode()

        // Execute: Guardar con email que contiene tabs y newlines
        viewModel.editedFirstName = "Bob"
        viewModel.editedLastName = "Johnson"
        viewModel.editedEmail = "\t\nbob@example.com\n\t"

        await viewModel.saveChanges()

        // Verify: Se guardó sin tabs ni newlines
        #expect(viewModel.user?.email == "bob@example.com")
        #expect(viewModel.error == nil)
    }

    @Test("Rejects firstName with only newlines")
    @MainActor
    func testRejectsFirstNameWithOnlyNewlines() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let localRepository = MockUserRepository()
        let mockHandler = MockGetUserContextQueryHandler()

        try await mediator.registerQueryHandler(mockHandler)

        let viewModel = UserProfileViewModel(
            mediator: mediator,
            eventBus: eventBus,
            localRepository: localRepository
        )

        // Esperar carga y entrar a modo edición
        try await Task.sleep(nanoseconds: 100_000_000)
        let originalUser = viewModel.user
        viewModel.enterEditMode()

        // Execute: Intentar guardar con firstName de solo newlines
        viewModel.editedFirstName = "\n\n\n"
        viewModel.editedLastName = "Doe"
        viewModel.editedEmail = "test@example.com"

        await viewModel.saveChanges()

        // Verify: Se rechazó con error y se mantiene en modo edición
        #expect(viewModel.error != nil)
        #expect(viewModel.editMode == true) // Se mantiene en modo edición
        #expect(viewModel.user == originalUser) // Usuario no cambió
    }
}

// MARK: - Mock Handlers

/// Mock QueryHandler para GetUserContextQuery
actor MockGetUserContextQueryHandler: QueryHandler {
    typealias QueryType = GetUserContextQuery

    private(set) var callCount = 0

    func handle(_ query: GetUserContextQuery) async throws -> UserContext {
        callCount += 1

        let user = try User(
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@test.com",
            isActive: true
        )

        return UserContext(
            user: user,
            memberships: [],
            unitsMap: [:],
            schoolsMap: [:],
            partialErrors: []
        )
    }
}

// MARK: - Mock Command Handler

/// Mock CommandHandler para UpdateUserProfileCommand
actor MockUpdateUserProfileCommandHandler: CommandHandler {
    typealias CommandType = UpdateUserProfileCommand

    private(set) var callCount = 0

    func handle(_ command: UpdateUserProfileCommand) async throws -> CommandResult<User> {
        callCount += 1

        let updatedUser = try User(
            id: command.userId,
            firstName: command.firstName,
            lastName: command.lastName,
            email: command.email,
            isActive: true
        )

        return .success(
            updatedUser,
            events: ["UserProfileUpdatedEvent"],
            metadata: [
                "userId": command.userId.uuidString
            ]
        )
    }
}

// MARK: - Mock Repository

/// Mock UserRepository para tests sin SwiftData
actor MockUserRepository: UserRepositoryProtocol {
    private var storage: [UUID: User] = [:]

    func get(id: UUID) async throws -> User? {
        return storage[id]
    }

    func save(_ user: User) async throws {
        storage[user.id] = user
    }

    func delete(id: UUID) async throws {
        storage.removeValue(forKey: id)
    }

    func list() async throws -> [User] {
        return Array(storage.values)
    }
}
