import Testing
import Foundation
import SwiftData
import Models
import EduGoCommon
@testable import LocalPersistence

@Suite("LocalMaterialRepository Tests", .serialized)
struct LocalMaterialRepositoryTests {
    // MARK: - Setup Helper

    private func setupRepository() async throws -> LocalMaterialRepository {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        return LocalMaterialRepository(containerProvider: provider)
    }

    // MARK: - CRUD Tests

    @Test("Save and get material")
    func testSaveAndGet() async throws {
        let repository = try await setupRepository()
        let material = try TestDataFactory.makeMaterial(title: "Test PDF")

        try await repository.save(material)
        let fetched = try await repository.get(id: material.id)

        #expect(fetched != nil)
        #expect(fetched?.id == material.id)
        #expect(fetched?.title == "Test PDF")
    }

    @Test("Get returns nil for non-existent material")
    func testGetReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.get(id: UUID())

        #expect(fetched == nil)
    }

    @Test("List returns saved materials")
    func testListReturnsSavedMaterials() async throws {
        let repository = try await setupRepository()
        let material1 = try TestDataFactory.makeMaterial(title: "Material One")
        let material2 = try TestDataFactory.makeMaterial(title: "Material Two")

        try await repository.save(material1)
        try await repository.save(material2)

        let listed = try await repository.list()

        #expect(listed.contains { $0.id == material1.id })
        #expect(listed.contains { $0.id == material2.id })
    }

    @Test("Delete removes material")
    func testDeleteRemovesMaterial() async throws {
        let repository = try await setupRepository()
        let material = try TestDataFactory.makeMaterial()

        try await repository.save(material)
        try await repository.delete(id: material.id)

        let fetched = try await repository.get(id: material.id)
        #expect(fetched == nil)
    }

    @Test("Delete throws for non-existent material")
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

    @Test("Save same material twice updates instead of duplicating")
    func testUpsertUpdatesExisting() async throws {
        let repository = try await setupRepository()
        let material = try TestDataFactory.makeMaterial(title: "Original")

        try await repository.save(material)

        let updatedMaterial = try Material(
            id: material.id,
            title: "Updated",
            status: material.status,
            schoolID: material.schoolID,
            isPublic: material.isPublic,
            createdAt: material.createdAt,
            updatedAt: Date()
        )
        try await repository.save(updatedMaterial)

        let fetched = try await repository.get(id: material.id)
        #expect(fetched?.title == "Updated")
    }

    // MARK: - Query Tests

    @Test("List by school returns only materials for that school")
    func testListBySchool() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()
        let otherSchoolID = UUID()

        let material1 = try TestDataFactory.makeMaterial(title: "School Material", schoolID: schoolID)
        let material2 = try TestDataFactory.makeMaterial(title: "Other Material", schoolID: otherSchoolID)

        try await repository.save(material1)
        try await repository.save(material2)

        let schoolMaterials = try await repository.listBySchool(schoolID: schoolID)

        #expect(schoolMaterials.count == 1)
        #expect(schoolMaterials.first?.id == material1.id)
    }
}
