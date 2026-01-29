import Testing
import Foundation
import SwiftData
import Models
@testable import LocalPersistence

@Suite("LocalRepository Concurrency Tests", .serialized)
struct LocalRepositoryConcurrencyTests {
    // MARK: - Setup Helper

    private func setupRepositories() async throws -> (LocalUserRepository, LocalDocumentRepository) {
        let provider = PersistenceContainerProvider()
        // Always configure a fresh provider to avoid cross-suite interference
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        return (
            LocalUserRepository(containerProvider: provider),
            LocalDocumentRepository(containerProvider: provider)
        )
    }

    // MARK: - Concurrent Save Tests

    @Test("1000 concurrent user saves complete without data races")
    func testConcurrentUserSaves() async throws {
        let (userRepo, _) = try await setupRepositories()
        let operationCount = 1000

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for i in 0..<operationCount {
                group.addTask {
                    do {
                        let user = try TestDataFactory.makeUser(
                            firstName: "Concurrent",
                            lastName: "User\(i)",
                            email: "concurrent\(i)@test.com"
                        )
                        try await userRepo.save(user)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(operationCount)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == operationCount, "All saves should succeed")
        #expect(elapsed < .seconds(2), "Should complete within target time")
    }

    @Test("1000 concurrent document saves complete without data races")
    func testConcurrentDocumentSaves() async throws {
        let (_, docRepo) = try await setupRepositories()
        let ownerID = UUID()
        let operationCount = 1000

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for i in 0..<operationCount {
                group.addTask {
                    do {
                        let document = try TestDataFactory.makeDocument(
                            title: "ConcurrentDoc \(i)",
                            content: "Content \(i)",
                            ownerID: ownerID
                        )
                        try await docRepo.save(document)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(operationCount)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == operationCount, "All saves should succeed")
        #expect(elapsed < .seconds(2), "Should complete within target time")
    }

    // MARK: - Concurrent Read Tests

    @Test("5000 concurrent user reads complete without errors")
    func testConcurrentUserReads() async throws {
        let (userRepo, _) = try await setupRepositories()
        let operationCount = 5000

        // Create a user to read
        let user = try TestDataFactory.makeUser(
            firstName: "ReadTest",
            lastName: "User",
            email: "readtest@test.com"
        )
        try await userRepo.save(user)
        _ = try await userRepo.list()

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for _ in 0..<operationCount {
                group.addTask {
                    do {
                        let fetched = try await userRepo.get(id: user.id)
                        return fetched != nil
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(operationCount)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == operationCount, "All reads should succeed")
        #expect(elapsed < .seconds(1), "Should complete within target time")
    }

    @Test("5000 concurrent document searches complete without errors")
    func testConcurrentDocumentSearches() async throws {
        let (_, docRepo) = try await setupRepositories()
        let operationCount = 5000

        // Create some documents to search
        for i in 0..<5 {
            let document = try TestDataFactory.makeDocument(
                title: "Searchable Item \(i)",
                content: "This is searchable content number \(i)"
            )
            try await docRepo.save(document)
        }

        _ = try await docRepo.list()

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for _ in 0..<operationCount {
                group.addTask {
                    do {
                        let results = try await docRepo.search(query: "searchable")
                        return !results.isEmpty
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(operationCount)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == operationCount, "All searches should succeed and find results")
        #expect(elapsed < .seconds(1), "Should complete within target time")
    }

    // MARK: - Mixed Read/Write Tests

    @Test("Mixed read and write operations complete without data races")
    func testMixedReadWriteOperations() async throws {
        let (userRepo, _) = try await setupRepositories()

        // Pre-populate with some users
        var userIDs: [UUID] = []
        for i in 0..<5 {
            let user = try TestDataFactory.makeUser(
                firstName: "Initial",
                lastName: "User\(i)",
                email: "initial\(i)@test.com"
            )
            try await userRepo.save(user)
            userIDs.append(user.id)
        }
        _ = try await userRepo.list()

        let writeOperations = 300
        let readOperations = 700
        let totalOperations = writeOperations + readOperations

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            // Add write operations
            for i in 0..<writeOperations {
                group.addTask {
                    do {
                        let user = try TestDataFactory.makeUser(
                            firstName: "New",
                            lastName: "User\(i)",
                            email: "newuser\(i)@test.com"
                        )
                        try await userRepo.save(user)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            // Add read operations
            for i in 0..<readOperations {
                let userID = userIDs[i % userIDs.count]
                group.addTask {
                    do {
                        _ = try await userRepo.get(id: userID)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(totalOperations)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == totalOperations, "All operations should succeed")
        #expect(elapsed < .seconds(2), "Should complete within target time")
    }

    // MARK: - Actor Isolation Tests

    @Test("Concurrent updates to same user are serialized by actor")
    func testConcurrentUpdatesToSameUser() async throws {
        let (userRepo, _) = try await setupRepositories()

        let userID = UUID()
        let user = try User(
            id: userID,
            firstName: "Shared",
            lastName: "User",
            email: "shared@test.com",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await userRepo.save(user)

        // Perform concurrent updates to the same user
        let updateCount = 50
        let results = await withTaskGroup(of: Int.self, returning: [Int].self) { group in
            for i in 0..<updateCount {
                group.addTask {
                    do {
                        let updatedUser = try User(
                            id: userID,
                            firstName: "Updated",
                            lastName: "\(i)",
                            email: "shared@test.com",
                            isActive: true,
                            createdAt: user.createdAt,
                            updatedAt: Date()
                        )
                        try await userRepo.save(updatedUser)
                        return i
                    } catch {
                        return -1
                    }
                }
            }

            var collected: [Int] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        // All updates should succeed (actor serializes access)
        let successCount = results.filter { $0 >= 0 }.count
        #expect(successCount == updateCount)

        // User should exist with one of the update values
        let finalUser = try await userRepo.get(id: userID)
        #expect(finalUser != nil)
        #expect(finalUser!.firstName == "Updated")
    }

    // MARK: - Extended Concurrency Tests for New Entities

    @Test("1000 concurrent membership saves complete without data races")
    func testConcurrentMembershipSaves() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        let membershipRepo = LocalMembershipRepository(containerProvider: provider)
        let operationCount = 1000

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for i in 0..<operationCount {
                group.addTask {
                    do {
                        let membership = TestDataFactory.makeMembership(
                            userID: UUID(),
                            unitID: UUID(),
                            role: MembershipRole.allCases[i % MembershipRole.allCases.count]
                        )
                        try await membershipRepo.save(membership)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(operationCount)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == operationCount, "All membership saves should succeed")
        #expect(elapsed < .seconds(3), "Should complete within target time")
    }

    @Test("1000 concurrent material saves complete without data races")
    func testConcurrentMaterialSaves() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        let materialRepo = LocalMaterialRepository(containerProvider: provider)
        let operationCount = 1000
        let schoolID = UUID()

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for i in 0..<operationCount {
                group.addTask {
                    do {
                        let material = try TestDataFactory.makeMaterial(
                            title: "Concurrent Material \(i)",
                            status: MaterialStatus.allCases[i % MaterialStatus.allCases.count],
                            schoolID: schoolID
                        )
                        try await materialRepo.save(material)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(operationCount)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == operationCount, "All material saves should succeed")
        #expect(elapsed < .seconds(3), "Should complete within target time")
    }

    @Test("1000 concurrent school saves complete without data races")
    func testConcurrentSchoolSaves() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        let schoolRepo = LocalSchoolRepository(containerProvider: provider)
        let operationCount = 1000

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for i in 0..<operationCount {
                group.addTask {
                    do {
                        let school = try TestDataFactory.makeSchool(
                            name: "Concurrent School \(i)",
                            code: "CONC-\(i)"
                        )
                        try await schoolRepo.save(school)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(operationCount)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == operationCount, "All school saves should succeed")
        #expect(elapsed < .seconds(3), "Should complete within target time")
    }

    @Test("1000 concurrent academic unit saves complete without data races")
    func testConcurrentAcademicUnitSaves() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        let unitRepo = LocalAcademicUnitRepository(containerProvider: provider)
        let operationCount = 1000
        let schoolID = UUID()

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for i in 0..<operationCount {
                group.addTask {
                    do {
                        let unit = try TestDataFactory.makeAcademicUnit(
                            displayName: "Concurrent Unit \(i)",
                            type: AcademicUnitType.allCases[i % AcademicUnitType.allCases.count],
                            schoolID: schoolID
                        )
                        try await unitRepo.save(unit)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(operationCount)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == operationCount, "All academic unit saves should succeed")
        #expect(elapsed < .seconds(3), "Should complete within target time")
    }

    @Test("5000 concurrent membership reads complete without errors")
    func testConcurrentMembershipReads() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        let membershipRepo = LocalMembershipRepository(containerProvider: provider)
        let operationCount = 5000

        // Create a membership to read
        let membership = TestDataFactory.makeMembership(role: .teacher)
        try await membershipRepo.save(membership)
        _ = try await membershipRepo.list()

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for _ in 0..<operationCount {
                group.addTask {
                    do {
                        let fetched = try await membershipRepo.get(id: membership.id)
                        return fetched != nil
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(operationCount)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == operationCount, "All membership reads should succeed")
        #expect(elapsed < .seconds(1), "Should complete within target time")
    }

    @Test("Mixed read and write operations on memberships complete without data races")
    func testMixedMembershipReadWriteOperations() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        let membershipRepo = LocalMembershipRepository(containerProvider: provider)

        // Pre-populate with some memberships
        var membershipIDs: [UUID] = []
        for i in 0..<5 {
            let membership = TestDataFactory.makeMembership(
                role: MembershipRole.allCases[i % MembershipRole.allCases.count]
            )
            try await membershipRepo.save(membership)
            membershipIDs.append(membership.id)
        }
        _ = try await membershipRepo.list()

        let writeOperations = 300
        let readOperations = 700
        let totalOperations = writeOperations + readOperations

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            // Add write operations
            for i in 0..<writeOperations {
                group.addTask {
                    do {
                        let membership = TestDataFactory.makeMembership(
                            role: MembershipRole.allCases[i % MembershipRole.allCases.count]
                        )
                        try await membershipRepo.save(membership)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            // Add read operations
            for i in 0..<readOperations {
                let membershipID = membershipIDs[i % membershipIDs.count]
                group.addTask {
                    do {
                        _ = try await membershipRepo.get(id: membershipID)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(totalOperations)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == totalOperations, "All operations should succeed")
        #expect(elapsed < .seconds(3), "Should complete within target time")
    }

    @Test("Concurrent updates to same school are serialized by actor")
    func testConcurrentUpdatesToSameSchool() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        let schoolRepo = LocalSchoolRepository(containerProvider: provider)

        let schoolID = UUID()
        let school = try School(
            id: schoolID,
            name: "Shared School",
            code: "SHARED-001",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await schoolRepo.save(school)

        // Perform concurrent updates to the same school
        let updateCount = 50
        let results = await withTaskGroup(of: Int.self, returning: [Int].self) { group in
            for i in 0..<updateCount {
                group.addTask {
                    do {
                        let updatedSchool = try School(
                            id: schoolID,
                            name: "Updated School \(i)",
                            code: "SHARED-001",
                            isActive: true,
                            createdAt: school.createdAt,
                            updatedAt: Date()
                        )
                        try await schoolRepo.save(updatedSchool)
                        return i
                    } catch {
                        return -1
                    }
                }
            }

            var collected: [Int] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        // All updates should succeed (actor serializes access)
        let successCount = results.filter { $0 >= 0 }.count
        #expect(successCount == updateCount)

        // School should exist with one of the update values
        let finalSchool = try await schoolRepo.get(id: schoolID)
        #expect(finalSchool != nil)
        #expect(finalSchool!.name.hasPrefix("Updated School"))
    }

    @Test("Concurrent queries on academic units by school")
    func testConcurrentQueriesOnAcademicUnits() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        let unitRepo = LocalAcademicUnitRepository(containerProvider: provider)
        let schoolID = UUID()
        let queryCount = 500

        // Pre-populate with academic units
        for i in 0..<20 {
            let unit = try TestDataFactory.makeAcademicUnit(
                displayName: "Unit \(i)",
                type: AcademicUnitType.allCases[i % AcademicUnitType.allCases.count],
                schoolID: schoolID
            )
            try await unitRepo.save(unit)
        }
        _ = try await unitRepo.list()

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for _ in 0..<queryCount {
                group.addTask {
                    do {
                        let units = try await unitRepo.listBySchool(schoolID: schoolID)
                        return units.count == 20
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(queryCount)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == queryCount, "All queries should succeed and return correct count")
        #expect(elapsed < .seconds(1), "Should complete within target time")
    }

    @Test("Concurrent queries on materials by school")
    func testConcurrentQueriesOnMaterials() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        let materialRepo = LocalMaterialRepository(containerProvider: provider)
        let schoolID = UUID()
        let queryCount = 500

        // Pre-populate with materials
        for i in 0..<20 {
            let material = try TestDataFactory.makeMaterial(
                title: "Material \(i)",
                status: MaterialStatus.allCases[i % MaterialStatus.allCases.count],
                schoolID: schoolID
            )
            try await materialRepo.save(material)
        }
        _ = try await materialRepo.list()

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for _ in 0..<queryCount {
                group.addTask {
                    do {
                        let materials = try await materialRepo.listBySchool(schoolID: schoolID)
                        return materials.count == 20
                    } catch {
                        return false
                    }
                }
            }

            var collected: [Bool] = []
            collected.reserveCapacity(queryCount)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let elapsed = ContinuousClock.now - startTime

        let successCount = results.filter { $0 }.count
        #expect(successCount == queryCount, "All queries should succeed and return correct count")
        #expect(elapsed < .seconds(1), "Should complete within target time")
    }
}
