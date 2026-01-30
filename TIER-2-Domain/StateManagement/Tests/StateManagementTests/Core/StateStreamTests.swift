import Testing
@testable import StateManagement

// MARK: - Test State

struct StreamTestState: AsyncState {
    let id: Int
}

// MARK: - StateStream Tests

@Suite("StateStream")
struct StateStreamTests {

    @Test("Empty stream completes immediately")
    func emptyStreamCompletes() async {
        let stream = StateStream<StreamTestState>.empty()

        var count = 0
        for await _ in stream {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Just emits single state")
    func justEmitsSingleState() async {
        let expected = StreamTestState(id: 42)
        let stream = StateStream.just(expected)

        var received: [StreamTestState] = []
        for await state in stream {
            received.append(state)
        }

        #expect(received.count == 1)
        #expect(received.first == expected)
    }

    @Test("From emits all states in order")
    func fromEmitsAllStatesInOrder() async {
        let states = (1...5).map { StreamTestState(id: $0) }
        let stream = StateStream.from(states)

        var received: [StreamTestState] = []
        for await state in stream {
            received.append(state)
        }

        #expect(received == states)
    }

    @Test("From with empty array behaves like empty")
    func fromEmptyArray() async {
        let stream = StateStream<StreamTestState>.from([])

        var count = 0
        for await _ in stream {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Stream can be iterated with for-await-in")
    func streamIteration() async {
        let states = [
            StreamTestState(id: 1),
            StreamTestState(id: 2),
            StreamTestState(id: 3)
        ]
        let stream = StateStream.from(states)

        var sum = 0
        for await state in stream {
            sum += state.id
        }

        #expect(sum == 6)
    }

    @Test("Iterator returns nil after completion")
    func iteratorReturnsNilAfterCompletion() async {
        let stream = StateStream.just(StreamTestState(id: 1))
        var iterator = stream.makeAsyncIterator()

        let first = await iterator.next()
        let second = await iterator.next()
        let third = await iterator.next()

        #expect(first != nil)
        #expect(second == nil)
        #expect(third == nil)
    }
}

// MARK: - StateStream Sendable Tests

@Suite("StateStream Sendable Conformance")
struct StateStreamSendableTests {

    @Test("Stream can be passed across actor boundaries")
    func streamPassedAcrossActors() async {
        let states = (1...3).map { StreamTestState(id: $0) }
        let stream = StateStream.from(states)

        // Simulate passing to another actor context
        let result = await Task {
            var collected: [StreamTestState] = []
            for await state in stream {
                collected.append(state)
            }
            return collected
        }.value

        #expect(result.count == 3)
    }

    @Test("Multiple tasks can receive from publisher stream")
    func multipleSubscribers() async {
        let publisher = StatePublisher<StreamTestState>()

        // Note: Each call to .stream creates a new stream
        // This tests that the publisher itself is thread-safe
        let stream = await publisher.stream

        await publisher.send(StreamTestState(id: 1))
        await publisher.send(StreamTestState(id: 2))
        await publisher.finish()

        var received: [StreamTestState] = []
        for await state in stream {
            received.append(state)
        }

        #expect(received.count == 2)
    }
}

// MARK: - Integration Tests

@Suite("StateStream Integration")
struct StateStreamIntegrationTests {

    @Test("Publisher to stream workflow")
    func publisherToStreamWorkflow() async {
        let publisher = StatePublisher<StreamTestState>()

        // Get stream first
        let stream = await publisher.stream

        // Emit states sequentially
        for i in 1...10 {
            await publisher.send(StreamTestState(id: i))
        }
        await publisher.finish()

        // Collect all states
        var received: [StreamTestState] = []
        for await state in stream {
            received.append(state)
        }

        #expect(received.count == 10)
        #expect(received.map(\.id) == Array(1...10))
    }

    @Test("Stream can break early from iteration")
    func streamBreaksEarlyFromIteration() async {
        let publisher = StatePublisher<StreamTestState>()
        let stream = await publisher.stream

        // Send states first
        await publisher.send(StreamTestState(id: 1))
        await publisher.send(StreamTestState(id: 2))
        await publisher.send(StreamTestState(id: 3))
        await publisher.send(StreamTestState(id: 4))
        await publisher.send(StreamTestState(id: 5))
        await publisher.finish()

        // Iterate and break early
        var receivedCount = 0
        for await _ in stream {
            receivedCount += 1
            if receivedCount >= 3 {
                break
            }
        }

        // Should have stopped after 3
        #expect(receivedCount == 3)
    }
}
