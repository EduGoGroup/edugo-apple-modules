import Testing
import Foundation
@testable import UseCases
import Models
import EduGoCommon

// MARK: - Mock Repositories

/// Mock de MembershipRepository
actor MockMembershipRepository: MembershipRepositoryProtocol {
    var memberships: [UUID: Membership] = [:]
    var membershipsByUser: [UUID: [Membership]] = [:]
    var membershipsByUnit: [UUID: [Membership]] = [:]

    func get(id: UUID) async throws -> Membership? {
        memberships[id]
    }

    func get(userID: UUID, unitID: UUID) async throws -> Membership? {
        memberships.values.first { $0.userID == userID && $0.unitID == unitID }
    }

    func save(_ membership: Membership) async throws {
        memberships[membership.id] = membership
        membershipsByUser[membership.userID, default: []].append(membership)
        membershipsByUnit[membership.unitID, default: []].append(membership)
    }

    func delete(id: UUID) async throws {
        memberships.removeValue(forKey: id)
    }

    func list() async throws -> [Membership] {
        Array(memberships.values)
    }

    func listByUser(userID: UUID) async throws -> [Membership] {
        membershipsByUser[userID] ?? []
    }

    func listByUnit(unitID: UUID) async throws -> [Membership] {
        membershipsByUnit[unitID] ?? []
    }
}

/// Mock de AcademicUnitRepository
actor MockAcademicUnitRepository: AcademicUnitRepositoryProtocol {
    var units: [UUID: AcademicUnit] = [:]
    var shouldFail = false
    var failForUnitIDs: Set<UUID> = []

    func get(id: UUID) async throws -> AcademicUnit? {
        if shouldFail || failForUnitIDs.contains(id) {
            throw RepositoryError.fetchFailed(reason: "Mock unit fetch error")
        }
        return units[id]
    }

    func save(_ unit: AcademicUnit) async throws {
        units[unit.id] = unit
    }

    func delete(id: UUID) async throws {
        units.removeValue(forKey: id)
    }

    func list() async throws -> [AcademicUnit] {
        Array(units.values)
    }

    func listBySchool(schoolID: UUID) async throws -> [AcademicUnit] {
        units.values.filter { $0.schoolID == schoolID }
    }

    func listChildren(parentID: UUID) async throws -> [AcademicUnit] {
        units.values.filter { $0.parentUnitID == parentID }
    }

    func listRoots(schoolID: UUID) async throws -> [AcademicUnit] {
        units.values.filter { $0.schoolID == schoolID && $0.parentUnitID == nil }
    }

    func addUnit(_ unit: AcademicUnit) {
        units[unit.id] = unit
    }

    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }

    func setFailForUnit(_ unitID: UUID) {
        failForUnitIDs.insert(unitID)
    }
}

/// Mock de SchoolRepository
actor MockSchoolRepository: SchoolRepositoryProtocol {
    var schools: [UUID: School] = [:]
    var shouldFail = false

    func get(id: UUID) async throws -> School? {
        if shouldFail {
            throw RepositoryError.fetchFailed(reason: "Mock school fetch error")
        }
        return schools[id]
    }

    func getByCode(code: String) async throws -> School? {
        schools.values.first { $0.code == code }
    }

    func save(_ school: School) async throws {
        schools[school.id] = school
    }

    func delete(id: UUID) async throws {
        schools.removeValue(forKey: id)
    }

    func list() async throws -> [School] {
        Array(schools.values)
    }

    func addSchool(_ school: School) {
        schools[school.id] = school
    }

    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }
}

// MARK: - LoadUserContextUseCase Tests

@Suite("LoadUserContextUseCase Tests")
struct LoadUserContextUseCaseTests {

    @Test("execute carga contexto completo exitosamente")
    func executeLoadsCompleteContext() async throws {
        // Setup
        let userRepo = MockUserRepository()
        let membershipRepo = MockMembershipRepository()
        let unitRepo = MockAcademicUnitRepository()
        let schoolRepo = MockSchoolRepository()

        let user = try User(
            id: UUID(),
            firstName: "John",
            lastName: "Doe",
            email: "john@edugo.com"
        )
        try await userRepo.save(user)

        let school = try School(
            id: UUID(),
            name: "Test School",
            code: "TST-001"
        )
        await schoolRepo.addSchool(school)

        let unit = try AcademicUnit(
            id: UUID(),
            displayName: "10th Grade",
            type: .grade,
            schoolID: school.id
        )
        await unitRepo.addUnit(unit)

        let membership = Membership(
            id: UUID(),
            userID: user.id,
            unitID: unit.id,
            role: .student
        )
        try await membershipRepo.save(membership)

        let useCase = LoadUserContextUseCase(
            userRepository: userRepo,
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo
        )

        // Execute
        let context = try await useCase.execute()

        // Assert
        #expect(context.user.id == user.id)
        #expect(context.memberships.count == 1)
        #expect(context.memberships[0].id == membership.id)
        #expect(context.unitsMap[unit.id]?.id == unit.id)
        #expect(context.schoolsMap[school.id]?.id == school.id)
        #expect(context.partialErrors.isEmpty)
    }

    @Test("execute maneja múltiples memberships")
    func executeHandlesMultipleMemberships() async throws {
        // Setup
        let userRepo = MockUserRepository()
        let membershipRepo = MockMembershipRepository()
        let unitRepo = MockAcademicUnitRepository()
        let schoolRepo = MockSchoolRepository()

        let user = try User(
            id: UUID(),
            firstName: "Jane",
            lastName: "Smith",
            email: "jane@edugo.com"
        )
        try await userRepo.save(user)

        let school = try School(
            id: UUID(),
            name: "Test School",
            code: "TST-001"
        )
        await schoolRepo.addSchool(school)

        // Crear 3 unidades diferentes
        let units = try (1...3).map { i in
            try AcademicUnit(
                id: UUID(),
                displayName: "Unit \(i)",
                type: .grade,
                schoolID: school.id
            )
        }
        for unit in units {
            await unitRepo.addUnit(unit)
        }

        // Crear memberships para cada unidad
        for unit in units {
            let membership = Membership(
                id: UUID(),
                userID: user.id,
                unitID: unit.id,
                role: .student
            )
            try await membershipRepo.save(membership)
        }

        let useCase = LoadUserContextUseCase(
            userRepository: userRepo,
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo
        )

        // Execute
        let context = try await useCase.execute()

        // Assert
        #expect(context.memberships.count == 3)
        #expect(context.unitsMap.count == 3)
        #expect(context.schoolsMap.count == 1)
        #expect(context.partialErrors.isEmpty)
    }

    @Test("execute maneja errores parciales gracefully")
    func executeHandlesPartialErrorsGracefully() async throws {
        // Setup
        let userRepo = MockUserRepository()
        let membershipRepo = MockMembershipRepository()
        let unitRepo = MockAcademicUnitRepository()
        let schoolRepo = MockSchoolRepository()

        let user = try User(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: "test@edugo.com"
        )
        try await userRepo.save(user)

        let school = try School(
            id: UUID(),
            name: "Test School",
            code: "TST-001"
        )
        await schoolRepo.addSchool(school)

        // Unidad que existe y carga correctamente
        let validUnit = try AcademicUnit(
            id: UUID(),
            displayName: "Valid Unit",
            type: .grade,
            schoolID: school.id
        )
        await unitRepo.addUnit(validUnit)

        // Membership con unidad válida
        let validMembership = Membership(
            id: UUID(),
            userID: user.id,
            unitID: validUnit.id,
            role: .student
        )
        try await membershipRepo.save(validMembership)

        // Unidad problemática que causará error
        let problematicUnit = try AcademicUnit(
            id: UUID(),
            displayName: "Problematic Unit",
            type: .grade,
            schoolID: school.id
        )
        await unitRepo.addUnit(problematicUnit)
        await unitRepo.setFailForUnit(problematicUnit.id) // Configurar para que falle

        // Membership con unidad problemática
        let problematicMembership = Membership(
            id: UUID(),
            userID: user.id,
            unitID: problematicUnit.id,
            role: .teacher
        )
        try await membershipRepo.save(problematicMembership)

        let useCase = LoadUserContextUseCase(
            userRepository: userRepo,
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo
        )

        // Execute
        let context = try await useCase.execute()

        // Assert
        #expect(context.memberships.count == 2)
        #expect(context.unitsMap.count == 1) // Solo la unidad válida
        #expect(context.schoolsMap.count == 1)
        #expect(!context.partialErrors.isEmpty) // Debe haber errores parciales
    }

    @Test("execute usa cache cuando está disponible")
    func executeUsesCacheWhenAvailable() async throws {
        // Setup
        let userRepo = MockUserRepository()
        let membershipRepo = MockMembershipRepository()
        let unitRepo = MockAcademicUnitRepository()
        let schoolRepo = MockSchoolRepository()

        let user = try User(
            id: UUID(),
            firstName: "Cache",
            lastName: "Test",
            email: "cache@edugo.com"
        )
        try await userRepo.save(user)

        let school = try School(
            id: UUID(),
            name: "Test School",
            code: "TST-001"
        )
        await schoolRepo.addSchool(school)

        let unit = try AcademicUnit(
            id: UUID(),
            displayName: "Test Unit",
            type: .grade,
            schoolID: school.id
        )
        await unitRepo.addUnit(unit)

        let membership = Membership(
            id: UUID(),
            userID: user.id,
            unitID: unit.id,
            role: .student
        )
        try await membershipRepo.save(membership)

        let useCase = LoadUserContextUseCase(
            userRepository: userRepo,
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo
        )

        // Execute primera vez
        let context1 = try await useCase.execute()

        // Execute segunda vez (debería usar cache)
        let context2 = try await useCase.execute()

        // Assert - deberían ser iguales
        #expect(context1 == context2)
    }

    @Test("invalidateCache limpia el cache")
    func invalidateCacheClearsCache() async throws {
        // Setup
        let userRepo = MockUserRepository()
        let membershipRepo = MockMembershipRepository()
        let unitRepo = MockAcademicUnitRepository()
        let schoolRepo = MockSchoolRepository()

        let user = try User(
            id: UUID(),
            firstName: "Cache",
            lastName: "Test",
            email: "cache@edugo.com"
        )
        try await userRepo.save(user)

        let school = try School(
            id: UUID(),
            name: "Test School",
            code: "TST-001"
        )
        await schoolRepo.addSchool(school)

        let unit = try AcademicUnit(
            id: UUID(),
            displayName: "Test Unit",
            type: .grade,
            schoolID: school.id
        )
        await unitRepo.addUnit(unit)

        let membership = Membership(
            id: UUID(),
            userID: user.id,
            unitID: unit.id,
            role: .student
        )
        try await membershipRepo.save(membership)

        let useCase = LoadUserContextUseCase(
            userRepository: userRepo,
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo
        )

        // Execute y cachear
        _ = try await useCase.execute()

        // Invalidar cache
        await useCase.invalidateCache()

        // Modificar datos
        let newMembership = Membership(
            id: UUID(),
            userID: user.id,
            unitID: unit.id,
            role: .teacher
        )
        try await membershipRepo.save(newMembership)

        // Execute nuevamente
        let context = try await useCase.execute()

        // Assert - debería tener 2 memberships ahora
        #expect(context.memberships.count == 2)
    }

    @Test("execute lanza error cuando no hay usuario")
    func executeThrowsWhenNoUser() async throws {
        let userRepo = MockUserRepository() // Vacío
        let membershipRepo = MockMembershipRepository()
        let unitRepo = MockAcademicUnitRepository()
        let schoolRepo = MockSchoolRepository()

        let useCase = LoadUserContextUseCase(
            userRepository: userRepo,
            membershipRepository: membershipRepo,
            unitRepository: unitRepo,
            schoolRepository: schoolRepo
        )

        do {
            _ = try await useCase.execute()
            Issue.record("Debería haber lanzado error")
        } catch is UseCaseError {
            // Esperado
        }
    }

    @Test("UserContext inicializa correctamente")
    func userContextInitializesCorrectly() throws {
        let user = try User(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: "test@edugo.com"
        )

        let membership = Membership(
            id: UUID(),
            userID: user.id,
            unitID: UUID(),
            role: .student
        )

        let context = UserContext(
            user: user,
            memberships: [membership],
            unitsMap: [:],
            schoolsMap: [:]
        )

        #expect(context.user.id == user.id)
        #expect(context.memberships.count == 1)
        #expect(context.unitsMap.isEmpty)
        #expect(context.schoolsMap.isEmpty)
        #expect(context.partialErrors.isEmpty)
    }

    @Test("PartialLoadError inicializa correctamente")
    func partialLoadErrorInitializesCorrectly() {
        let error = PartialLoadError(
            membershipID: UUID(),
            resourceType: .unit,
            message: "Test error"
        )

        #expect(error.resourceType == .unit)
        #expect(error.message == "Test error")
    }
}
