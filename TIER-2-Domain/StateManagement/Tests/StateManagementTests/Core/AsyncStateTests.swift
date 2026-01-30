import Testing
@testable import StateManagement

// MARK: - Test State Types

struct SimpleState: AsyncState {
    let value: Int
}

struct ComplexState: AsyncState {
    let id: String
    let progress: Double
    let isComplete: Bool
}

enum StatusState: AsyncState {
    case idle
    case loading
    case success(String)
    case failure(String)
}

// MARK: - AsyncState Protocol Tests

@Suite("AsyncState Protocol")
struct AsyncStateTests {

    @Test("SimpleState conforms to Sendable and Equatable")
    func simpleStateConformance() {
        let state1 = SimpleState(value: 42)
        let state2 = SimpleState(value: 42)
        let state3 = SimpleState(value: 100)

        #expect(state1 == state2)
        #expect(state1 != state3)
    }

    @Test("ComplexState equality works correctly")
    func complexStateEquality() {
        let state1 = ComplexState(id: "abc", progress: 0.5, isComplete: false)
        let state2 = ComplexState(id: "abc", progress: 0.5, isComplete: false)
        let state3 = ComplexState(id: "abc", progress: 0.75, isComplete: false)

        #expect(state1 == state2)
        #expect(state1 != state3)
    }

    @Test("Enum states work with AsyncState")
    func enumStateConformance() {
        let idle1 = StatusState.idle
        let idle2 = StatusState.idle
        let loading = StatusState.loading
        let success1 = StatusState.success("Done")
        let success2 = StatusState.success("Done")
        let success3 = StatusState.success("Different")

        #expect(idle1 == idle2)
        #expect(idle1 != loading)
        #expect(success1 == success2)
        #expect(success1 != success3)
    }

    @Test("AsyncState can be used in concurrent context")
    func asyncStateSendable() async {
        let state = ComplexState(id: "test", progress: 1.0, isComplete: true)

        let results = await withTaskGroup(of: ComplexState.self, returning: [ComplexState].self) { group in
            for _ in 0..<10 {
                group.addTask {
                    // State can be safely passed across task boundaries
                    return state
                }
            }

            var collected: [ComplexState] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        #expect(results.count == 10)
        #expect(results.allSatisfy { $0 == state })
    }
}
