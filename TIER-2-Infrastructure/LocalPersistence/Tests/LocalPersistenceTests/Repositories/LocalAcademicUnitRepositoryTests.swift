import Testing
import Foundation
import SwiftData
import Models
import EduGoCommon
@testable import LocalPersistence

@Suite("LocalAcademicUnitRepository Tests", .serialized)
struct LocalAcademicUnitRepositoryTests {
    // MARK: - Setup Helper

    private func setupRepository() async throws -> LocalAcademicUnitRepository {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        return LocalAcademicUnitRepository(containerProvider: provider)
    }

    // MARK: - CRUD Tests

    @Test("Save and get academic unit")
    func testSaveAndGet() async throws {
        let repository = try await setupRepository()
        let unit = try TestDataFactory.makeAcademicUnit(displayName: "Grade 10")

        try await repository.save(unit)
        let fetched = try await repository.get(id: unit.id)

        #expect(fetched != nil)
        #expect(fetched?.id == unit.id)
        #expect(fetched?.displayName == "Grade 10")
    }

    @Test("Get returns nil for non-existent unit")
    func testGetReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.get(id: UUID())

        #expect(fetched == nil)
    }

    @Test("List returns saved units")
    func testListReturnsSavedUnits() async throws {
        let repository = try await setupRepository()
        let unit1 = try TestDataFactory.makeAcademicUnit(displayName: "Unit One")
        let unit2 = try TestDataFactory.makeAcademicUnit(displayName: "Unit Two")

        try await repository.save(unit1)
        try await repository.save(unit2)

        let listed = try await repository.list()

        #expect(listed.contains { $0.id == unit1.id })
        #expect(listed.contains { $0.id == unit2.id })
    }

    @Test("Delete removes unit")
    func testDeleteRemovesUnit() async throws {
        let repository = try await setupRepository()
        let unit = try TestDataFactory.makeAcademicUnit()

        try await repository.save(unit)
        try await repository.delete(id: unit.id)

        let fetched = try await repository.get(id: unit.id)
        #expect(fetched == nil)
    }

    @Test("Delete throws for non-existent unit")
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

    @Test("Save same unit twice updates instead of duplicating")
    func testUpsertUpdatesExisting() async throws {
        let repository = try await setupRepository()
        let unit = try TestDataFactory.makeAcademicUnit(displayName: "Original")

        try await repository.save(unit)

        let updatedUnit = try AcademicUnit(
            id: unit.id,
            displayName: "Updated",
            type: unit.type,
            parentUnitID: unit.parentUnitID,
            schoolID: unit.schoolID,
            createdAt: unit.createdAt,
            updatedAt: Date()
        )
        try await repository.save(updatedUnit)

        let fetched = try await repository.get(id: unit.id)
        #expect(fetched?.displayName == "Updated")
    }

    // MARK: - Query Tests

    @Test("List by school returns only units for that school")
    func testListBySchool() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()
        let otherSchoolID = UUID()

        let unit1 = try TestDataFactory.makeAcademicUnit(displayName: "School Unit", schoolID: schoolID)
        let unit2 = try TestDataFactory.makeAcademicUnit(displayName: "Other Unit", schoolID: otherSchoolID)

        try await repository.save(unit1)
        try await repository.save(unit2)

        let schoolUnits = try await repository.listBySchool(schoolID: schoolID)

        #expect(schoolUnits.count == 1)
        #expect(schoolUnits.first?.id == unit1.id)
    }

    @Test("List roots returns only units without parent")
    func testListRoots() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()

        let rootUnit = try TestDataFactory.makeAcademicUnit(
            displayName: "Root Unit",
            schoolID: schoolID,
            parentUnitID: nil
        )

        try await repository.save(rootUnit)

        let roots = try await repository.listRoots(schoolID: schoolID)

        #expect(roots.count == 1)
        #expect(roots.first?.id == rootUnit.id)
    }
}
