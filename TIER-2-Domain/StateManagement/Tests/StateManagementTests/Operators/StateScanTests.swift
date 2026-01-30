import Testing
@testable import StateManagement

// MARK: - Test State

private struct ScanTestState: AsyncState {
    let value: Int
}

// MARK: - StateScan Tests

@Suite("StateScan")
struct StateScanTests {

    @Test("Scan accumulates values")
    func scanAccumulatesValues() async {
        let input = [ScanTestState(value: 1), ScanTestState(value: 2), ScanTestState(value: 3)]
        let stream = StateStream.from(input)

        let scanned = stream.scan(initialState: 0) { accumulated, state in
            accumulated + state.value
        }

        var results: [Int] = []
        for await value in scanned {
            results.append(value)
        }

        #expect(results == [1, 3, 6])
    }

    @Test("Scan emits each intermediate result")
    func scanEmitsIntermediateResults() async {
        let input = (1...5).map { ScanTestState(value: $0) }
        let stream = StateStream.from(input)

        let scanned = stream.scan(initialState: 0) { accumulated, state in
            accumulated + state.value
        }

        var results: [Int] = []
        for await value in scanned {
            results.append(value)
        }

        // 1, 1+2=3, 3+3=6, 6+4=10, 10+5=15
        #expect(results == [1, 3, 6, 10, 15])
    }

    @Test("Scan with empty stream produces empty result")
    func scanEmptyStream() async {
        let stream = StateStream<ScanTestState>.empty()
        let scanned = stream.scan(initialState: 100) { accumulated, state in
            accumulated + state.value
        }

        var count = 0
        for await _ in scanned {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Scan with single element")
    func scanSingleElement() async {
        let stream = StateStream.just(ScanTestState(value: 42))
        let scanned = stream.scan(initialState: 10) { accumulated, state in
            accumulated + state.value
        }

        var results: [Int] = []
        for await value in scanned {
            results.append(value)
        }

        #expect(results == [52])
    }

    @Test("Scan can change type")
    func scanChangesType() async {
        let input = [ScanTestState(value: 1), ScanTestState(value: 2), ScanTestState(value: 3)]
        let stream = StateStream.from(input)

        let scanned = stream.scan(initialState: "Total:") { accumulated, state in
            "\(accumulated) \(state.value)"
        }

        var results: [String] = []
        for await value in scanned {
            results.append(value)
        }

        #expect(results == ["Total: 1", "Total: 1 2", "Total: 1 2 3"])
    }

    @Test("Scan with multiplication")
    func scanMultiplication() async {
        let input = [ScanTestState(value: 2), ScanTestState(value: 3), ScanTestState(value: 4)]
        let stream = StateStream.from(input)

        let scanned = stream.scan(initialState: 1) { accumulated, state in
            accumulated * state.value
        }

        var results: [Int] = []
        for await value in scanned {
            results.append(value)
        }

        // 1*2=2, 2*3=6, 6*4=24
        #expect(results == [2, 6, 24])
    }

    @Test("Scan collects into array")
    func scanCollectsIntoArray() async {
        let input = [ScanTestState(value: 1), ScanTestState(value: 2), ScanTestState(value: 3)]
        let stream = StateStream.from(input)

        let scanned = stream.scan(initialState: [Int]()) { accumulated, state in
            accumulated + [state.value]
        }

        var results: [[Int]] = []
        for await value in scanned {
            results.append(value)
        }

        #expect(results == [[1], [1, 2], [1, 2, 3]])
    }

    @Test("Scan respects cancellation")
    func scanRespectsCancellation() async {
        let input = (1...100).map { ScanTestState(value: $0) }
        let stream = StateStream.from(input)
        let scanned = stream.scan(initialState: 0) { accumulated, state in
            accumulated + state.value
        }

        let task = Task {
            var count = 0
            for await _ in scanned {
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

    @Test("Scan with state transformation")
    func scanWithStateTransformation() async {
        struct AccumulatedState: AsyncState {
            let count: Int
            let sum: Int
        }

        let input = [ScanTestState(value: 10), ScanTestState(value: 20), ScanTestState(value: 30)]
        let stream = StateStream.from(input)

        let scanned = stream.scan(initialState: AccumulatedState(count: 0, sum: 0)) { acc, state in
            AccumulatedState(count: acc.count + 1, sum: acc.sum + state.value)
        }

        var results: [AccumulatedState] = []
        for await value in scanned {
            results.append(value)
        }

        #expect(results.count == 3)
        #expect(results[0].count == 1)
        #expect(results[0].sum == 10)
        #expect(results[1].count == 2)
        #expect(results[1].sum == 30)
        #expect(results[2].count == 3)
        #expect(results[2].sum == 60)
    }
}

// MARK: - StateScan Sendable Tests

@Suite("StateScan Sendable Conformance")
struct StateScanSendableTests {

    @Test("Scanned stream can be passed across actor boundaries")
    func scannedStreamPassedAcrossActors() async {
        let input = (1...3).map { ScanTestState(value: $0) }
        let stream = StateStream.from(input)
        let scanned = stream.scan(initialState: 0) { accumulated, state in
            accumulated + state.value
        }

        let result = await Task {
            var collected: [Int] = []
            for await value in scanned {
                collected.append(value)
            }
            return collected
        }.value

        #expect(result == [1, 3, 6])
    }
}
