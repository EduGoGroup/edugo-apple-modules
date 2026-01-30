import Testing
@testable import StateManagement

// MARK: - Test States

private struct UserState: AsyncState {
    let id: Int
    let name: String
}

private struct SettingsState: AsyncState {
    let theme: String
}

private struct UnitsState: AsyncState {
    let count: Int
}

private struct MaterialsState: AsyncState {
    let items: [String]
}

// MARK: - StateCombineLatest2 Tests

@Suite("StateCombineLatest2")
struct StateCombineLatest2Tests {

    @Test("Emits tuple when both streams have values")
    func emitsTupleWhenBothHaveValues() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([SettingsState(theme: "dark")])

        let combined = StateCombineLatest2(stream1, stream2)

        var results: [(UserState, SettingsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        #expect(results.count >= 1)
        #expect(results[0].0.name == "Alice")
        #expect(results[0].1.theme == "dark")
    }

    @Test("Does not emit until both have values")
    func doesNotEmitUntilBothHaveValues() async throws {
        let publisher1 = StatePublisher<UserState>()
        let publisher2 = StatePublisher<SettingsState>()

        let stream1 = await publisher1.stream
        let stream2 = await publisher2.stream

        let combined = StateCombineLatest2(stream1, stream2)

        // Only emit from first, then finish both without second emitting
        await publisher1.send(UserState(id: 1, name: "Alice"))
        await publisher1.finish()
        await publisher2.finish()

        var count = 0
        for try await _ in combined {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Multiple values from arrays emits at least once")
    func multipleValuesEmitsAtLeastOnce() async throws {
        let stream1 = StateStream.from([
            UserState(id: 1, name: "Alice"),
            UserState(id: 2, name: "Bob")
        ])
        let stream2 = StateStream.from([
            SettingsState(theme: "dark"),
            SettingsState(theme: "light")
        ])

        let combined = StateCombineLatest2(stream1, stream2)

        var results: [(UserState, SettingsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        // Should have at least 1 emission when both have values
        #expect(results.count >= 1)
    }

    @Test("Completes with policy all when all complete")
    func completesWithPolicyAll() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([SettingsState(theme: "dark")])

        let combined = StateCombineLatest2(stream1, stream2, policy: .all)

        var results: [(UserState, SettingsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        #expect(results.count == 1)
    }

    @Test("Policy any completes with single source")
    func policyAnyCompletesWithSingleSource() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([SettingsState(theme: "dark")])

        let combined = StateCombineLatest2(stream1, stream2, policy: .any)

        var results: [(UserState, SettingsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        // With policy .any, completes when first source completes
        #expect(results.count >= 1)
    }

    @Test("Works with StateStream from arrays")
    func worksWithStateStreamFromArrays() async throws {
        let stream1 = StateStream.from([
            UserState(id: 1, name: "Alice"),
            UserState(id: 2, name: "Bob")
        ])
        let stream2 = StateStream.from([
            SettingsState(theme: "dark"),
            SettingsState(theme: "light")
        ])

        let combined = StateCombineLatest2(stream1, stream2)

        var results: [(UserState, SettingsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        // Should have at least 1 emission (when both have values)
        #expect(results.count >= 1)
    }
}

// MARK: - StateCombineLatest3 Tests

@Suite("StateCombineLatest3")
struct StateCombineLatest3Tests {

    @Test("Emits tuple when all three streams have values")
    func emitsTupleWhenAllHaveValues() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([UnitsState(count: 5)])
        let stream3 = StateStream.from([MaterialsState(items: ["A", "B"])])

        let combined = StateCombineLatest3(stream1, stream2, stream3)

        var results: [(UserState, UnitsState, MaterialsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        #expect(results.count >= 1)
        #expect(results[0].0.name == "Alice")
        #expect(results[0].1.count == 5)
        #expect(results[0].2.items == ["A", "B"])
    }

    @Test("Does not emit until all three have values")
    func doesNotEmitUntilAllHaveValues() async throws {
        let publisher1 = StatePublisher<UserState>()
        let publisher2 = StatePublisher<UnitsState>()
        let publisher3 = StatePublisher<MaterialsState>()

        let stream1 = await publisher1.stream
        let stream2 = await publisher2.stream
        let stream3 = await publisher3.stream

        let combined = StateCombineLatest3(stream1, stream2, stream3)

        // Only emit from two, then finish all
        await publisher1.send(UserState(id: 1, name: "Alice"))
        await publisher2.send(UnitsState(count: 5))
        // Third never emits

        await publisher1.finish()
        await publisher2.finish()
        await publisher3.finish()

        var count = 0
        for try await _ in combined {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Dashboard use case simulation")
    func dashboardUseCaseSimulation() async throws {
        // Simulate LoadStudentDashboardUseCase scenario
        let userStream = StateStream.from([UserState(id: 1, name: "Student")])
        let unitsStream = StateStream.from([UnitsState(count: 10)])
        let materialsStream = StateStream.from([MaterialsState(items: ["Book", "Video"])])

        let combined = StateCombineLatest3(userStream, unitsStream, materialsStream)

        var dashboardReady = false
        for try await (user, units, materials) in combined {
            dashboardReady = true
            #expect(user.name == "Student")
            #expect(units.count == 10)
            #expect(materials.items.count == 2)
        }

        #expect(dashboardReady)
    }
}

// MARK: - Extension Tests

@Suite("AsyncSequence+CombineLatest Extension")
struct AsyncSequenceCombineLatestExtensionTests {

    @Test("Extension combineLatest with one other")
    func extensionCombineLatestWithOne() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([SettingsState(theme: "dark")])

        let combined = stream1.combineLatest(with: stream2)

        var results: [(UserState, SettingsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        #expect(results.count >= 1)
    }

    @Test("Extension combineLatest with two others")
    func extensionCombineLatestWithTwo() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([UnitsState(count: 5)])
        let stream3 = StateStream.from([MaterialsState(items: ["A"])])

        let combined = stream1.combineLatest(with: stream2, stream3)

        var results: [(UserState, UnitsState, MaterialsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        #expect(results.count >= 1)
    }

    @Test("Extension with custom policy")
    func extensionWithCustomPolicy() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([SettingsState(theme: "dark")])

        let combined = stream1.combineLatest(with: stream2, policy: .any)

        var results: [(UserState, SettingsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        #expect(results.count >= 1)
    }
}

// MARK: - Free Function Tests

@Suite("CombineLatest Free Functions")
struct CombineLatestFreeFunctionsTests {

    @Test("Free function combineLatest2 works")
    func freeFunctionCombineLatest2() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([SettingsState(theme: "dark")])

        let combined = combineLatest(stream1, stream2)

        var results: [(UserState, SettingsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        #expect(results.count >= 1)
    }

    @Test("Free function combineLatest3 works")
    func freeFunctionCombineLatest3() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([UnitsState(count: 5)])
        let stream3 = StateStream.from([MaterialsState(items: ["A"])])

        let combined = combineLatest(stream1, stream2, stream3)

        var results: [(UserState, UnitsState, MaterialsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        #expect(results.count >= 1)
    }

    @Test("Free function with policy parameter")
    func freeFunctionWithPolicy() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([SettingsState(theme: "dark")])

        let combined = combineLatest(stream1, stream2, policy: .all)

        var results: [(UserState, SettingsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        #expect(results.count >= 1)
    }
}

// MARK: - Completion Policy Tests

@Suite("CombineLatestCompletionPolicy")
struct CombineLatestCompletionPolicyTests {

    @Test("Policy any works with static streams")
    func policyAnyWorksWithStaticStreams() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([SettingsState(theme: "dark")])

        let combined = StateCombineLatest2(stream1, stream2, policy: .any)

        var results: [(UserState, SettingsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        // With .any policy, should complete when first stream completes
        #expect(results.count >= 1)
    }

    @Test("Policy all works with static streams")
    func policyAllWorksWithStaticStreams() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([SettingsState(theme: "dark")])

        let combined = StateCombineLatest2(stream1, stream2, policy: .all)

        var results: [(UserState, SettingsState)] = []
        for try await tuple in combined {
            results.append(tuple)
        }

        // With .all policy, completes when all streams complete
        #expect(results.count >= 1)
    }
}

// MARK: - Edge Cases Tests

@Suite("StateCombineLatest Edge Cases")
struct StateCombineLatestEdgeCasesTests {

    @Test("Empty first stream produces no emissions")
    func emptyFirstStream() async throws {
        let stream1 = StateStream<UserState>.empty()
        let stream2 = StateStream.from([SettingsState(theme: "dark")])

        let combined = StateCombineLatest2(stream1, stream2)

        var count = 0
        for try await _ in combined {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Empty second stream produces no emissions")
    func emptySecondStream() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream<SettingsState>.empty()

        let combined = StateCombineLatest2(stream1, stream2)

        var count = 0
        for try await _ in combined {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Both empty streams produce no emissions")
    func bothEmptyStreams() async throws {
        let stream1 = StateStream<UserState>.empty()
        let stream2 = StateStream<SettingsState>.empty()

        let combined = StateCombineLatest2(stream1, stream2)

        var count = 0
        for try await _ in combined {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Break early stops iteration")
    func breakEarlyStopsIteration() async throws {
        let stream1 = StateStream.from((1...100).map { UserState(id: $0, name: "User\($0)") })
        let stream2 = StateStream.from((1...100).map { SettingsState(theme: "theme\($0)") })

        let combined = StateCombineLatest2(stream1, stream2)

        var count = 0
        for try await _ in combined {
            count += 1
            if count >= 5 {
                break
            }
        }

        #expect(count == 5)
    }
}

// MARK: - Sendable Conformance Tests

@Suite("StateCombineLatest Sendable Conformance")
struct StateCombineLatestSendableTests {

    @Test("Combined stream can be passed across actor boundaries")
    func combinedStreamAcrossActors() async throws {
        let stream1 = StateStream.from([UserState(id: 1, name: "Alice")])
        let stream2 = StateStream.from([SettingsState(theme: "dark")])
        let combined = StateCombineLatest2(stream1, stream2)

        let result = await Task {
            var collected: [(UserState, SettingsState)] = []
            do {
                for try await tuple in combined {
                    collected.append(tuple)
                }
            } catch {
                // Ignore errors in test
            }
            return collected
        }.value

        #expect(result.count >= 1)
    }
}
