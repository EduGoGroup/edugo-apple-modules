import Testing
@testable import StateManagement

// MARK: - Test State

private struct FilterTestState: AsyncState {
    let id: Int
    let isActive: Bool
}

// MARK: - StateFilter Tests

@Suite("StateFilter")
struct StateFilterTests {

    @Test("Filter includes matching elements")
    func filterIncludesMatching() async {
        let input = [
            FilterTestState(id: 1, isActive: true),
            FilterTestState(id: 2, isActive: false),
            FilterTestState(id: 3, isActive: true),
            FilterTestState(id: 4, isActive: false),
            FilterTestState(id: 5, isActive: true)
        ]
        let stream = StateStream.from(input)

        let filtered = stream.filter { $0.isActive }

        var results: [FilterTestState] = []
        for await state in filtered {
            results.append(state)
        }

        #expect(results.count == 3)
        #expect(results.map(\.id) == [1, 3, 5])
    }

    @Test("Filter excludes all when none match")
    func filterExcludesAll() async {
        let input = (1...5).map { FilterTestState(id: $0, isActive: false) }
        let stream = StateStream.from(input)

        let filtered = stream.filter { $0.isActive }

        var count = 0
        for await _ in filtered {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Filter includes all when all match")
    func filterIncludesAll() async {
        let input = (1...5).map { FilterTestState(id: $0, isActive: true) }
        let stream = StateStream.from(input)

        let filtered = stream.filter { $0.isActive }

        var results: [FilterTestState] = []
        for await state in filtered {
            results.append(state)
        }

        #expect(results.count == 5)
    }

    @Test("Filter preserves order of matching elements")
    func filterPreservesOrder() async {
        let input = (1...10).map { FilterTestState(id: $0, isActive: $0 % 2 == 0) }
        let stream = StateStream.from(input)

        let filtered = stream.filter { $0.isActive }

        var results: [Int] = []
        for await state in filtered {
            results.append(state.id)
        }

        #expect(results == [2, 4, 6, 8, 10])
    }

    @Test("Filter with empty stream produces empty result")
    func filterEmptyStream() async {
        let stream = StateStream<FilterTestState>.empty()
        let filtered = stream.filter { $0.isActive }

        var count = 0
        for await _ in filtered {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Filter with single matching element")
    func filterSingleMatching() async {
        let stream = StateStream.just(FilterTestState(id: 1, isActive: true))
        let filtered = stream.filter { $0.isActive }

        var results: [FilterTestState] = []
        for await state in filtered {
            results.append(state)
        }

        #expect(results.count == 1)
        #expect(results[0].id == 1)
    }

    @Test("Filter with single non-matching element")
    func filterSingleNonMatching() async {
        let stream = StateStream.just(FilterTestState(id: 1, isActive: false))
        let filtered = stream.filter { $0.isActive }

        var count = 0
        for await _ in filtered {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Filter respects cancellation")
    func filterRespectsCancellation() async {
        let input = (1...100).map { FilterTestState(id: $0, isActive: true) }
        let stream = StateStream.from(input)
        let filtered = stream.filter { $0.isActive }

        let task = Task {
            var count = 0
            for await _ in filtered {
                count += 1
                if count >= 5 {
                    break
                }
            }
            return count
        }

        let result = await task.value
        #expect(result == 5)
    }

    @Test("Filter with numeric predicate")
    func filterNumericPredicate() async {
        let input = (1...10).map { FilterTestState(id: $0, isActive: true) }
        let stream = StateStream.from(input)

        let filtered = stream.filter { $0.id > 5 }

        var results: [Int] = []
        for await state in filtered {
            results.append(state.id)
        }

        #expect(results == [6, 7, 8, 9, 10])
    }
}

// MARK: - StateFilter Sendable Tests

@Suite("StateFilter Sendable Conformance")
struct StateFilterSendableTests {

    @Test("Filtered stream can be passed across actor boundaries")
    func filteredStreamPassedAcrossActors() async {
        let input = (1...6).map { FilterTestState(id: $0, isActive: $0 % 2 == 0) }
        let stream = StateStream.from(input)
        let filtered = stream.filter { $0.isActive }

        let result = await Task {
            var collected: [Int] = []
            for await state in filtered {
                collected.append(state.id)
            }
            return collected
        }.value

        #expect(result == [2, 4, 6])
    }
}
