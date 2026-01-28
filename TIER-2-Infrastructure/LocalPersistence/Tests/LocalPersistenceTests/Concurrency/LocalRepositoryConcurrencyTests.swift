import Testing
import Foundation
import SwiftData
import Models
@testable import LocalPersistence

@Suite("LocalRepository Concurrency Tests", .serialized)
struct LocalRepositoryConcurrencyTests {
    private let schema = Schema([UserModel.self, DocumentModel.self])

    // MARK: - Setup Helper

    private func setupRepositories() async throws -> (LocalUserRepository, LocalDocumentRepository) {
        let provider = PersistenceContainerProvider()
        // Always configure a fresh provider to avoid cross-suite interference
        try await provider.configure(
            with: .testing,
            schema: schema
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
                            name: "ConcurrentUser \(i)",
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
            name: "ReadTestUser",
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
                name: "Initial User \(i)",
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
                            name: "NewUser \(i)",
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
            name: "Shared User",
            email: "shared@test.com",
            isActive: true,
            roleIDs: []
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
                            name: "Updated \(i)",
                            email: "shared@test.com",
                            isActive: true,
                            roleIDs: []
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
        #expect(finalUser!.name.hasPrefix("Updated"))
    }
}
