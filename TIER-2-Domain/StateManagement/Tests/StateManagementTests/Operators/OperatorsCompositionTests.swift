import Testing
@testable import StateManagement

// MARK: - Test States

private struct UserState: AsyncState {
    let id: Int
    let name: String
    let isActive: Bool
}

private struct UserViewModel: AsyncState {
    let displayName: String
}

// MARK: - Operators Composition Tests

@Suite("Operators Composition")
struct OperatorsCompositionTests {

    @Test("Map then filter")
    func mapThenFilter() async {
        let users = [
            UserState(id: 1, name: "Alice", isActive: true),
            UserState(id: 2, name: "Bob", isActive: false),
            UserState(id: 3, name: "Charlie", isActive: true)
        ]
        let stream = StateStream.from(users)

        let result = stream
            .map { UserViewModel(displayName: $0.name.uppercased()) }
            .filter { $0.displayName.count > 4 }

        var results: [UserViewModel] = []
        for await viewModel in result {
            results.append(viewModel)
        }

        #expect(results.count == 2)
        #expect(results[0].displayName == "ALICE")
        #expect(results[1].displayName == "CHARLIE")
    }

    @Test("Filter then map")
    func filterThenMap() async {
        let users = [
            UserState(id: 1, name: "Alice", isActive: true),
            UserState(id: 2, name: "Bob", isActive: false),
            UserState(id: 3, name: "Charlie", isActive: true)
        ]
        let stream = StateStream.from(users)

        let result = stream
            .filter { $0.isActive }
            .map { UserViewModel(displayName: "User: \($0.name)") }

        var results: [UserViewModel] = []
        for await viewModel in result {
            results.append(viewModel)
        }

        #expect(results.count == 2)
        #expect(results[0].displayName == "User: Alice")
        #expect(results[1].displayName == "User: Charlie")
    }

    @Test("Filter then scan")
    func filterThenScan() async {
        let users = [
            UserState(id: 1, name: "A", isActive: true),
            UserState(id: 2, name: "B", isActive: false),
            UserState(id: 3, name: "C", isActive: true),
            UserState(id: 4, name: "D", isActive: false),
            UserState(id: 5, name: "E", isActive: true)
        ]
        let stream = StateStream.from(users)

        let result = stream
            .filter { $0.isActive }
            .scan(initialState: 0) { count, _ in count + 1 }

        var results: [Int] = []
        for await count in result {
            results.append(count)
        }

        #expect(results == [1, 2, 3])
    }

    @Test("Map then scan")
    func mapThenScan() async {
        let users = [
            UserState(id: 1, name: "Alice", isActive: true),
            UserState(id: 2, name: "Bob", isActive: true),
            UserState(id: 3, name: "Charlie", isActive: true)
        ]
        let stream = StateStream.from(users)

        let result = stream
            .map { $0.name.count }
            .scan(initialState: 0) { total, nameLength in total + nameLength }

        var results: [Int] = []
        for await value in result {
            results.append(value)
        }

        // Alice=5, Bob=3, Charlie=7 -> 5, 8, 15
        #expect(results == [5, 8, 15])
    }

    @Test("Triple composition: filter -> map -> scan")
    func tripleComposition() async {
        let users = (1...10).map { UserState(id: $0, name: "User\($0)", isActive: $0 % 2 == 0) }
        let stream = StateStream.from(users)

        let result = stream
            .filter { $0.isActive }
            .map { $0.id }
            .scan(initialState: 0) { sum, id in sum + id }

        var results: [Int] = []
        for await value in result {
            results.append(value)
        }

        // Active users: 2, 4, 6, 8, 10
        // Running sum: 2, 6, 12, 20, 30
        #expect(results == [2, 6, 12, 20, 30])
    }

    @Test("Complex workflow simulation")
    func complexWorkflowSimulation() async {
        struct AppState: AsyncState {
            let isLoading: Bool
            let data: [String]
            let error: String?
        }

        struct DisplayState: AsyncState {
            let itemCount: Int
            let hasError: Bool
        }

        let states = [
            AppState(isLoading: true, data: [], error: nil),
            AppState(isLoading: false, data: ["A"], error: nil),
            AppState(isLoading: false, data: ["A", "B"], error: nil),
            AppState(isLoading: true, data: ["A", "B"], error: nil),
            AppState(isLoading: false, data: ["A", "B", "C"], error: nil),
            AppState(isLoading: false, data: [], error: "Network error")
        ]
        let stream = StateStream.from(states)

        let displayStates = stream
            .filter { !$0.isLoading }
            .map { DisplayState(itemCount: $0.data.count, hasError: $0.error != nil) }

        var results: [DisplayState] = []
        for await state in displayStates {
            results.append(state)
        }

        #expect(results.count == 4)
        #expect(results[0].itemCount == 1)
        #expect(results[0].hasError == false)
        #expect(results[1].itemCount == 2)
        #expect(results[2].itemCount == 3)
        #expect(results[3].itemCount == 0)
        #expect(results[3].hasError == true)
    }
}

// MARK: - Integration with StatePublisher

@Suite("Operators with StatePublisher")
struct OperatorsWithPublisherTests {

    @Test("Operators work with live publisher")
    func operatorsWithLivePublisher() async {
        let publisher = StatePublisher<UserState>()
        let stream = await publisher.stream

        let viewModels = stream
            .filter { $0.isActive }
            .map { UserViewModel(displayName: $0.name) }

        // Emit states
        await publisher.send(UserState(id: 1, name: "Active", isActive: true))
        await publisher.send(UserState(id: 2, name: "Inactive", isActive: false))
        await publisher.send(UserState(id: 3, name: "AlsoActive", isActive: true))
        await publisher.finish()

        var results: [UserViewModel] = []
        for await viewModel in viewModels {
            results.append(viewModel)
        }

        #expect(results.count == 2)
        #expect(results[0].displayName == "Active")
        #expect(results[1].displayName == "AlsoActive")
    }
}
