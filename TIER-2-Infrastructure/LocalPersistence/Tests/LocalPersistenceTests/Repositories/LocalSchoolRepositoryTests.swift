import Testing
import Foundation
import SwiftData
import Models
import EduGoCommon
@testable import LocalPersistence

@Suite("LocalSchoolRepository Tests", .serialized)
struct LocalSchoolRepositoryTests {
    // MARK: - Setup Helper

    private func setupRepository() async throws -> LocalSchoolRepository {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        return LocalSchoolRepository(containerProvider: provider)
    }

    // MARK: - CRUD Tests

    @Test("Save and get school")
    func testSaveAndGet() async throws {
        let repository = try await setupRepository()
        let school = try TestDataFactory.makeSchool(name: "Test Academy")

        try await repository.save(school)
        let fetched = try await repository.get(id: school.id)

        #expect(fetched != nil)
        #expect(fetched?.id == school.id)
        #expect(fetched?.name == "Test Academy")
    }

    @Test("Get returns nil for non-existent school")
    func testGetReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.get(id: UUID())

        #expect(fetched == nil)
    }

    @Test("List returns saved schools")
    func testListReturnsSavedSchools() async throws {
        let repository = try await setupRepository()
        let school1 = try TestDataFactory.makeSchool(name: "School One", code: "SCH001")
        let school2 = try TestDataFactory.makeSchool(name: "School Two", code: "SCH002")

        try await repository.save(school1)
        try await repository.save(school2)

        let listed = try await repository.list()

        #expect(listed.contains { $0.id == school1.id })
        #expect(listed.contains { $0.id == school2.id })
    }

    @Test("Delete removes school")
    func testDeleteRemovesSchool() async throws {
        let repository = try await setupRepository()
        let school = try TestDataFactory.makeSchool()

        try await repository.save(school)
        try await repository.delete(id: school.id)

        let fetched = try await repository.get(id: school.id)
        #expect(fetched == nil)
    }

    @Test("Delete throws for non-existent school")
    func testDeleteThrowsForNonExistent() async throws {
        let repository = try await setupRepository()

        do {
            try await repository.delete(id: UUID())
            Issue.record("Expected deleteFailed error")
        } catch let error as RepositoryError {
            if case .deleteFailed = error {
                // Expected
            } else {
                Issue.record("Expected deleteFailed, got \(error)")
            }
        }
    }

    // MARK: - Upsert Tests

    @Test("Save same school twice updates instead of duplicating")
    func testUpsertUpdatesExisting() async throws {
        let repository = try await setupRepository()
        let school = try TestDataFactory.makeSchool(name: "Original Name")

        try await repository.save(school)

        let updatedSchool = try School(
            id: school.id,
            name: "Updated Name",
            code: school.code,
            isActive: school.isActive,
            createdAt: school.createdAt,
            updatedAt: Date()
        )
        try await repository.save(updatedSchool)

        let fetched = try await repository.get(id: school.id)
        #expect(fetched?.name == "Updated Name")
    }

    // MARK: - Query Tests

    @Test("Get by code returns correct school")
    func testGetByCode() async throws {
        let repository = try await setupRepository()
        let school = try TestDataFactory.makeSchool(name: "Code School", code: "UNIQUE-CODE")

        try await repository.save(school)

        let fetched = try await repository.getByCode(code: "UNIQUE-CODE")

        #expect(fetched != nil)
        #expect(fetched?.id == school.id)
    }

    @Test("Get by code returns nil for non-existent code")
    func testGetByCodeReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.getByCode(code: "NON-EXISTENT")

        #expect(fetched == nil)
    }
}
