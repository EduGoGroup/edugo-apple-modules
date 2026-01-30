import Testing
import Foundation
@testable import UseCases
import Models
import EduGoCommon

// MARK: - Mock UserSessionRepository

/// Mock de UserSessionRepository para tests
actor MockUserSessionRepository: UserSessionRepositoryProtocol {
    var currentMembershipId: UUID?
    var currentUnitId: UUID?
    var currentSchoolId: UUID?
    var shouldFailOnGet = false
    var shouldFailOnUpdate = false
    var updateCallCount = 0

    func getCurrentMembershipId() async throws -> UUID? {
        if shouldFailOnGet {
            throw RepositoryError.fetchFailed(reason: "Mock session fetch error")
        }
        return currentMembershipId
    }

    func updateSessionContext(
        membershipId: UUID,
        unitId: UUID,
        schoolId: UUID
    ) async throws {
        if shouldFailOnUpdate {
            throw RepositoryError.saveFailed(reason: "Mock session update error")
        }
        updateCallCount += 1
        currentMembershipId = membershipId
        currentUnitId = unitId
        currentSchoolId = schoolId
    }

    func setCurrentMembership(_ id: UUID?) {
        currentMembershipId = id
    }

    func setShouldFailOnUpdate(_ value: Bool) {
        shouldFailOnUpdate = value
    }

    func setShouldFailOnGet(_ value: Bool) {
        shouldFailOnGet = value
    }

    func getUpdateCallCount() -> Int {
        updateCallCount
    }
}

// MARK: - Mock CacheInvalidator

/// Mock de CacheInvalidator para tests
actor MockCacheInvalidator: CacheInvalidatorProtocol {
    var dashboardInvalidated = false
    var materialsInvalidated = false

    nonisolated func invalidateDashboardCache() async {
        await setDashboardInvalidated(true)
    }

    nonisolated func invalidateMaterialsCache() async {
        await setMaterialsInvalidated(true)
    }

    func setDashboardInvalidated(_ value: Bool) {
        dashboardInvalidated = value
    }

    func setMaterialsInvalidated(_ value: Bool) {
        materialsInvalidated = value
    }

    func wasDashboardInvalidated() -> Bool {
        dashboardInvalidated
    }

    func wasMaterialsInvalidated() -> Bool {
        materialsInvalidated
    }
}

// MARK: - SwitchSchoolContextUseCase Tests

@Suite("SwitchSchoolContextUseCase Tests")
struct SwitchSchoolContextUseCaseTests {

    // MARK: - Helper Methods

    /// Crea los repositorios mock necesarios para los tests
    private func createMocks() async throws -> (
        membershipRepo: MockMembershipRepository,
        unitRepo: MockAcademicUnitRepository,
        schoolRepo: MockSchoolRepository,
        sessionRepo: MockUserSessionRepository,
        cacheInvalidator: MockCacheInvalidator
    ) {
        (
            MockMembershipRepository(),
            MockAcademicUnitRepository(),
            MockSchoolRepository(),
            MockUserSessionRepository(),
            MockCacheInvalidator()
        )
    }

    /// Crea datos de prueba básicos
    private func createTestData() throws -> (
        user: User,
        school: School,
        unit: AcademicUnit,
        membership: Membership
    ) {
        let userId = UUID()
        let schoolId = UUID()
        let unitId = UUID()

        let user = try User(
            id: userId,
            firstName: "Test",
            lastName: "User",
            email: "test@edugo.com"
        )

        let school = try School(
            id: schoolId,
            name: "Test School",
            code: "TST-001"
        )

        let unit = try AcademicUnit(
            id: unitId,
            displayName: "10th Grade",
            type: .grade,
            schoolID: schoolId
        )

        let membership = Membership(
            id: UUID(),
            userID: userId,
            unitID: unitId,
            role: .student
        )

        return (user, school, unit, membership)
    }

    // MARK: - Success Tests

    @Test("execute cambia contexto exitosamente")
    func executeSuccessfullyChangesContext() async throws {
        // Setup
        let (membershipRepo, unitRepo, schoolRepo, sessionRepo, cacheInvalidator) = try await createMocks()

        let (user, school, unit, currentMembership) = try createTestData()

        // Crear segundo membership para el switch
        let newSchool = try School(id: UUID(), name: "New School", code: "NEW-001")
        let newUnit = try AcademicUnit(id: UUID(), displayName: "11th Grade", type: .grade, schoolID: newSchool.id)
        let newMembership = Membership(id: UUID(), userID: user.id, unitID: newUnit.id, role: .student)

        // Configurar repositorios
        try await membershipRepo.save(currentMembership)
        try await membershipRepo.save(newMembership)
        await unitRepo.addUnit(unit)
        await unitRepo.addUnit(newUnit)
        await schoolRepo.addSchool(school)
        await schoolRepo.addSchool(newSchool)
        await sessionRepo.setCurrentMembership(currentMembership.id)

        let useCase = SwitchSchoolContextUseCase(
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo,
            sessionRepository: sessionRepo,
            cacheInvalidator: cacheInvalidator
        )

        let input = SwitchSchoolInput(userId: user.id, targetMembershipId: newMembership.id)

        // Execute
        let output = try await useCase.execute(input: input)

        // Assert
        #expect(output.newContext.activeMembership.id == newMembership.id)
        #expect(output.newContext.unit.id == newUnit.id)
        #expect(output.newContext.school.id == newSchool.id)
        #expect(output.previousMembershipId == currentMembership.id)
    }

    @Test("execute retorna contexto actual cuando se hace switch al mismo membership")
    func executeReturnsCurrentContextForSameMembership() async throws {
        // Setup
        let (membershipRepo, unitRepo, schoolRepo, sessionRepo, cacheInvalidator) = try await createMocks()
        let (user, school, unit, membership) = try createTestData()

        try await membershipRepo.save(membership)
        await unitRepo.addUnit(unit)
        await schoolRepo.addSchool(school)
        await sessionRepo.setCurrentMembership(membership.id)

        let useCase = SwitchSchoolContextUseCase(
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo,
            sessionRepository: sessionRepo,
            cacheInvalidator: cacheInvalidator
        )

        let input = SwitchSchoolInput(userId: user.id, targetMembershipId: membership.id)

        // Execute
        let output = try await useCase.execute(input: input)

        // Assert - debería retornar el mismo contexto sin error
        #expect(output.newContext.activeMembership.id == membership.id)
        #expect(output.previousMembershipId == membership.id)

        // No debería haber llamado a updateSessionContext
        let updateCount = await sessionRepo.getUpdateCallCount()
        #expect(updateCount == 0)
    }

    @Test("execute invalida caches correctamente")
    func executeInvalidatesCaches() async throws {
        // Setup
        let (membershipRepo, unitRepo, schoolRepo, sessionRepo, cacheInvalidator) = try await createMocks()

        let userId = UUID()
        let school = try School(id: UUID(), name: "Test School", code: "TST-001")
        let unit = try AcademicUnit(id: UUID(), displayName: "Grade", type: .grade, schoolID: school.id)
        let currentMembership = Membership(id: UUID(), userID: userId, unitID: unit.id, role: .student)

        let newSchool = try School(id: UUID(), name: "New School", code: "NEW-001")
        let newUnit = try AcademicUnit(id: UUID(), displayName: "New Grade", type: .grade, schoolID: newSchool.id)
        let newMembership = Membership(id: UUID(), userID: userId, unitID: newUnit.id, role: .student)

        try await membershipRepo.save(currentMembership)
        try await membershipRepo.save(newMembership)
        await unitRepo.addUnit(unit)
        await unitRepo.addUnit(newUnit)
        await schoolRepo.addSchool(school)
        await schoolRepo.addSchool(newSchool)
        await sessionRepo.setCurrentMembership(currentMembership.id)

        let useCase = SwitchSchoolContextUseCase(
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo,
            sessionRepository: sessionRepo,
            cacheInvalidator: cacheInvalidator
        )

        let input = SwitchSchoolInput(userId: userId, targetMembershipId: newMembership.id)

        // Execute
        _ = try await useCase.execute(input: input)

        // Assert - caches deben estar invalidados
        let dashboardInvalidated = await cacheInvalidator.wasDashboardInvalidated()
        let materialsInvalidated = await cacheInvalidator.wasMaterialsInvalidated()
        #expect(dashboardInvalidated)
        #expect(materialsInvalidated)
    }

    // MARK: - Validation Error Tests

    @Test("execute lanza error cuando membership no existe")
    func executeThrowsWhenMembershipNotFound() async throws {
        // Setup
        let (membershipRepo, unitRepo, schoolRepo, sessionRepo, cacheInvalidator) = try await createMocks()

        let useCase = SwitchSchoolContextUseCase(
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo,
            sessionRepository: sessionRepo,
            cacheInvalidator: cacheInvalidator
        )

        let input = SwitchSchoolInput(userId: UUID(), targetMembershipId: UUID())

        // Execute & Assert
        do {
            _ = try await useCase.execute(input: input)
            Issue.record("Debería haber lanzado error")
        } catch let error as UseCaseError {
            if case .preconditionFailed(let description) = error {
                #expect(description.contains("Membership no encontrado"))
            } else {
                Issue.record("Error incorrecto: \(error)")
            }
        }
    }

    @Test("execute lanza error cuando membership no pertenece al usuario")
    func executeThrowsWhenMembershipNotOwnedByUser() async throws {
        // Setup
        let (membershipRepo, unitRepo, schoolRepo, sessionRepo, cacheInvalidator) = try await createMocks()

        let otherUserId = UUID()
        let school = try School(id: UUID(), name: "Test School", code: "TST-001")
        let unit = try AcademicUnit(id: UUID(), displayName: "Grade", type: .grade, schoolID: school.id)
        let otherUserMembership = Membership(id: UUID(), userID: otherUserId, unitID: unit.id, role: .student)

        try await membershipRepo.save(otherUserMembership)
        await unitRepo.addUnit(unit)
        await schoolRepo.addSchool(school)

        let useCase = SwitchSchoolContextUseCase(
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo,
            sessionRepository: sessionRepo,
            cacheInvalidator: cacheInvalidator
        )

        // Intentar cambiar a un membership de otro usuario
        let input = SwitchSchoolInput(userId: UUID(), targetMembershipId: otherUserMembership.id)

        // Execute & Assert
        do {
            _ = try await useCase.execute(input: input)
            Issue.record("Debería haber lanzado error")
        } catch let error as UseCaseError {
            if case .unauthorized = error {
                // Esperado
            } else {
                Issue.record("Error incorrecto: \(error)")
            }
        }
    }

    @Test("execute lanza error cuando membership no está activo")
    func executeThrowsWhenMembershipNotActive() async throws {
        // Setup
        let (membershipRepo, unitRepo, schoolRepo, sessionRepo, cacheInvalidator) = try await createMocks()

        let userId = UUID()
        let school = try School(id: UUID(), name: "Test School", code: "TST-001")
        let unit = try AcademicUnit(id: UUID(), displayName: "Grade", type: .grade, schoolID: school.id)

        // Crear membership inactivo (withdrawn)
        let inactiveMembership = Membership(
            id: UUID(),
            userID: userId,
            unitID: unit.id,
            role: .student,
            isActive: false,
            withdrawnAt: Date()
        )

        try await membershipRepo.save(inactiveMembership)
        await unitRepo.addUnit(unit)
        await schoolRepo.addSchool(school)

        let useCase = SwitchSchoolContextUseCase(
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo,
            sessionRepository: sessionRepo,
            cacheInvalidator: cacheInvalidator
        )

        let input = SwitchSchoolInput(userId: userId, targetMembershipId: inactiveMembership.id)

        // Execute & Assert
        do {
            _ = try await useCase.execute(input: input)
            Issue.record("Debería haber lanzado error")
        } catch let error as UseCaseError {
            if case .preconditionFailed(let description) = error {
                #expect(description.contains("activo"))
            } else {
                Issue.record("Error incorrecto: \(error)")
            }
        }
    }

    @Test("execute lanza error cuando unit no existe")
    func executeThrowsWhenUnitNotFound() async throws {
        // Setup
        let (membershipRepo, unitRepo, schoolRepo, sessionRepo, cacheInvalidator) = try await createMocks()

        let userId = UUID()
        let membership = Membership(id: UUID(), userID: userId, unitID: UUID(), role: .student)

        try await membershipRepo.save(membership)
        // No agregamos la unit

        let useCase = SwitchSchoolContextUseCase(
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo,
            sessionRepository: sessionRepo,
            cacheInvalidator: cacheInvalidator
        )

        let input = SwitchSchoolInput(userId: userId, targetMembershipId: membership.id)

        // Execute & Assert
        do {
            _ = try await useCase.execute(input: input)
            Issue.record("Debería haber lanzado error")
        } catch let error as UseCaseError {
            if case .preconditionFailed(let description) = error {
                #expect(description.contains("Unidad académica"))
            } else {
                Issue.record("Error incorrecto: \(error)")
            }
        }
    }

    @Test("execute lanza error cuando school no existe")
    func executeThrowsWhenSchoolNotFound() async throws {
        // Setup
        let (membershipRepo, unitRepo, schoolRepo, sessionRepo, cacheInvalidator) = try await createMocks()

        let userId = UUID()
        let unit = try AcademicUnit(id: UUID(), displayName: "Grade", type: .grade, schoolID: UUID())
        let membership = Membership(id: UUID(), userID: userId, unitID: unit.id, role: .student)

        try await membershipRepo.save(membership)
        await unitRepo.addUnit(unit)
        // No agregamos la school

        let useCase = SwitchSchoolContextUseCase(
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo,
            sessionRepository: sessionRepo,
            cacheInvalidator: cacheInvalidator
        )

        let input = SwitchSchoolInput(userId: userId, targetMembershipId: membership.id)

        // Execute & Assert
        do {
            _ = try await useCase.execute(input: input)
            Issue.record("Debería haber lanzado error")
        } catch let error as UseCaseError {
            if case .preconditionFailed(let description) = error {
                #expect(description.contains("Escuela"))
            } else {
                Issue.record("Error incorrecto: \(error)")
            }
        }
    }

    @Test("execute lanza error cuando school no está activa")
    func executeThrowsWhenSchoolNotActive() async throws {
        // Setup
        let (membershipRepo, unitRepo, schoolRepo, sessionRepo, cacheInvalidator) = try await createMocks()

        let userId = UUID()
        let inactiveSchool = try School(id: UUID(), name: "Inactive School", code: "INA-001").with(isActive: false)
        let unit = try AcademicUnit(id: UUID(), displayName: "Grade", type: .grade, schoolID: inactiveSchool.id)
        let membership = Membership(id: UUID(), userID: userId, unitID: unit.id, role: .student)

        try await membershipRepo.save(membership)
        await unitRepo.addUnit(unit)
        await schoolRepo.addSchool(inactiveSchool)

        let useCase = SwitchSchoolContextUseCase(
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo,
            sessionRepository: sessionRepo,
            cacheInvalidator: cacheInvalidator
        )

        let input = SwitchSchoolInput(userId: userId, targetMembershipId: membership.id)

        // Execute & Assert
        do {
            _ = try await useCase.execute(input: input)
            Issue.record("Debería haber lanzado error")
        } catch let error as UseCaseError {
            if case .preconditionFailed(let description) = error {
                #expect(description.contains("escuela no está activa"))
            } else {
                Issue.record("Error incorrecto: \(error)")
            }
        }
    }

    @Test("execute lanza error cuando unit está eliminada")
    func executeThrowsWhenUnitDeleted() async throws {
        // Setup
        let (membershipRepo, unitRepo, schoolRepo, sessionRepo, cacheInvalidator) = try await createMocks()

        let userId = UUID()
        let school = try School(id: UUID(), name: "Test School", code: "TST-001")
        let deletedUnit = try AcademicUnit(
            id: UUID(),
            displayName: "Deleted Grade",
            type: .grade,
            schoolID: school.id,
            deletedAt: Date()
        )
        let membership = Membership(id: UUID(), userID: userId, unitID: deletedUnit.id, role: .student)

        try await membershipRepo.save(membership)
        await unitRepo.addUnit(deletedUnit)
        await schoolRepo.addSchool(school)

        let useCase = SwitchSchoolContextUseCase(
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo,
            sessionRepository: sessionRepo,
            cacheInvalidator: cacheInvalidator
        )

        let input = SwitchSchoolInput(userId: userId, targetMembershipId: membership.id)

        // Execute & Assert
        do {
            _ = try await useCase.execute(input: input)
            Issue.record("Debería haber lanzado error")
        } catch let error as UseCaseError {
            if case .preconditionFailed(let description) = error {
                #expect(description.contains("eliminada"))
            } else {
                Issue.record("Error incorrecto: \(error)")
            }
        }
    }

    // MARK: - Session Update Error Tests

    @Test("execute lanza error cuando falla la actualización de sesión")
    func executeThrowsWhenSessionUpdateFails() async throws {
        // Setup
        let (membershipRepo, unitRepo, schoolRepo, sessionRepo, cacheInvalidator) = try await createMocks()

        let userId = UUID()
        let school = try School(id: UUID(), name: "Test School", code: "TST-001")
        let unit = try AcademicUnit(id: UUID(), displayName: "Grade", type: .grade, schoolID: school.id)
        let currentMembership = Membership(id: UUID(), userID: userId, unitID: unit.id, role: .student)
        let newMembership = Membership(id: UUID(), userID: userId, unitID: unit.id, role: .teacher)

        try await membershipRepo.save(currentMembership)
        try await membershipRepo.save(newMembership)
        await unitRepo.addUnit(unit)
        await schoolRepo.addSchool(school)
        await sessionRepo.setCurrentMembership(currentMembership.id)
        await sessionRepo.setShouldFailOnUpdate(true) // Configurar para fallar solo en update

        let useCase = SwitchSchoolContextUseCase(
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo,
            sessionRepository: sessionRepo,
            cacheInvalidator: cacheInvalidator
        )

        let input = SwitchSchoolInput(userId: userId, targetMembershipId: newMembership.id)

        // Execute & Assert
        do {
            _ = try await useCase.execute(input: input)
            Issue.record("Debería haber lanzado error")
        } catch let error as UseCaseError {
            if case .repositoryError = error {
                // Esperado
            } else {
                Issue.record("Error incorrecto: \(error)")
            }
        }
    }

    // MARK: - Input/Output Model Tests

    @Test("SwitchSchoolInput inicializa correctamente")
    func switchSchoolInputInitializesCorrectly() {
        let userId = UUID()
        let membershipId = UUID()

        let input = SwitchSchoolInput(userId: userId, targetMembershipId: membershipId)

        #expect(input.userId == userId)
        #expect(input.targetMembershipId == membershipId)
    }

    @Test("SwitchSchoolOutput inicializa correctamente")
    func switchSchoolOutputInitializesCorrectly() throws {
        let school = try School(id: UUID(), name: "Test", code: "TST")
        let unit = try AcademicUnit(id: UUID(), displayName: "Grade", type: .grade, schoolID: school.id)
        let membership = Membership(id: UUID(), userID: UUID(), unitID: unit.id, role: .student)
        let previousId = UUID()

        let context = SwitchSchoolContext(activeMembership: membership, unit: unit, school: school)
        let output = SwitchSchoolOutput(newContext: context, previousMembershipId: previousId)

        #expect(output.newContext.activeMembership.id == membership.id)
        #expect(output.previousMembershipId == previousId)
    }

    @Test("SwitchSchoolContext inicializa correctamente")
    func switchSchoolContextInitializesCorrectly() throws {
        let school = try School(id: UUID(), name: "Test", code: "TST")
        let unit = try AcademicUnit(id: UUID(), displayName: "Grade", type: .grade, schoolID: school.id)
        let membership = Membership(id: UUID(), userID: UUID(), unitID: unit.id, role: .student)

        let context = SwitchSchoolContext(activeMembership: membership, unit: unit, school: school)

        #expect(context.activeMembership.id == membership.id)
        #expect(context.unit.id == unit.id)
        #expect(context.school.id == school.id)
    }

    @Test("SchoolContextChangedEvent inicializa correctamente")
    func schoolContextChangedEventInitializesCorrectly() {
        let userId = UUID()
        let oldId = UUID()
        let newId = UUID()
        let schoolId = UUID()
        let timestamp = Date()

        let event = SchoolContextChangedEvent(
            userId: userId,
            oldMembershipId: oldId,
            newMembershipId: newId,
            newSchoolId: schoolId,
            timestamp: timestamp
        )

        #expect(event.userId == userId)
        #expect(event.oldMembershipId == oldId)
        #expect(event.newMembershipId == newId)
        #expect(event.newSchoolId == schoolId)
        #expect(event.timestamp == timestamp)
    }

    @Test("SwitchSchoolContextError tiene descripciones correctas")
    func switchSchoolContextErrorHasCorrectDescriptions() {
        let notOwned = SwitchSchoolContextError.membershipNotOwnedByUser
        #expect(notOwned.errorDescription?.contains("no pertenece") == true)

        let notActive = SwitchSchoolContextError.membershipNotActive
        #expect(notActive.errorDescription?.contains("activo") == true)

        let notAvailable = SwitchSchoolContextError.contextNotAvailable(reason: "Test reason")
        #expect(notAvailable.errorDescription?.contains("Test reason") == true)

        let sameContext = SwitchSchoolContextError.sameContextSwitch
        #expect(sameContext.errorDescription?.contains("contexto") == true)
    }
}
