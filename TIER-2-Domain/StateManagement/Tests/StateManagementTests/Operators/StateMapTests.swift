import Testing
@testable import StateManagement

// MARK: - Test States

private struct InputState: AsyncState {
    let value: Int
}

private struct OutputState: AsyncState {
    let transformed: String
}

// MARK: - StateMap Tests

@Suite("StateMap")
struct StateMapTests {

    @Test("Map transforms elements")
    func mapTransformsElements() async {
        let input = [InputState(value: 1), InputState(value: 2), InputState(value: 3)]
        let stream = StateStream.from(input)

        let mapped = stream.map { OutputState(transformed: "Value: \($0.value)") }

        var results: [OutputState] = []
        for await state in mapped {
            results.append(state)
        }

        #expect(results.count == 3)
        #expect(results[0].transformed == "Value: 1")
        #expect(results[1].transformed == "Value: 2")
        #expect(results[2].transformed == "Value: 3")
    }

    @Test("Map preserves order")
    func mapPreservesOrder() async {
        let input = (1...10).map { InputState(value: $0) }
        let stream = StateStream.from(input)

        let mapped = stream.map { $0.value * 2 }

        var results: [Int] = []
        for await value in mapped {
            results.append(value)
        }

        #expect(results == [2, 4, 6, 8, 10, 12, 14, 16, 18, 20])
    }

    @Test("Map with empty stream produces empty result")
    func mapEmptyStream() async {
        let stream = StateStream<InputState>.empty()
        let mapped = stream.map { OutputState(transformed: "\($0.value)") }

        var count = 0
        for await _ in mapped {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Map with single element")
    func mapSingleElement() async {
        let stream = StateStream.just(InputState(value: 42))
        let mapped = stream.map { $0.value * 2 }

        var results: [Int] = []
        for await value in mapped {
            results.append(value)
        }

        #expect(results == [84])
    }

    @Test("Map can change type")
    func mapChangesType() async {
        let input = [InputState(value: 1), InputState(value: 2)]
        let stream = StateStream.from(input)

        let mapped = stream.map { Double($0.value) / 2.0 }

        var results: [Double] = []
        for await value in mapped {
            results.append(value)
        }

        #expect(results == [0.5, 1.0])
    }

    @Test("Map respects cancellation")
    func mapRespectsCancellation() async {
        let input = (1...100).map { InputState(value: $0) }
        let stream = StateStream.from(input)
        let mapped = stream.map { $0.value }

        let task = Task {
            var count = 0
            for await _ in mapped {
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
}

// MARK: - StateMap Sendable Tests

@Suite("StateMap Sendable Conformance")
struct StateMapSendableTests {

    @Test("Mapped stream can be passed across actor boundaries")
    func mappedStreamPassedAcrossActors() async {
        let input = (1...3).map { InputState(value: $0) }
        let stream = StateStream.from(input)
        let mapped = stream.map { $0.value * 10 }

        let result = await Task {
            var collected: [Int] = []
            for await value in mapped {
                collected.append(value)
            }
            return collected
        }.value

        #expect(result == [10, 20, 30])
    }
}
