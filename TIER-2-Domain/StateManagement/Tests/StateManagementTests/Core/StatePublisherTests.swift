import Testing
@testable import StateManagement

// MARK: - Test State

struct TestState: AsyncState {
    let value: Int
    let message: String

    init(value: Int, message: String = "") {
        self.value = value
        self.message = message
    }
}

// MARK: - StatePublisher Tests

@Suite("StatePublisher")
struct StatePublisherTests {

    @Test("Initial state is nil")
    func initialStateIsNil() async {
        let publisher = StatePublisher<TestState>()

        let current = await publisher.currentState
        #expect(current == nil)
    }

    @Test("Send updates current state")
    func sendUpdatesCurrentState() async {
        let publisher = StatePublisher<TestState>()
        let state = TestState(value: 42, message: "Hello")

        await publisher.send(state)

        let current = await publisher.currentState
        #expect(current == state)
    }

    @Test("Send emits to stream")
    func sendEmitsToStream() async {
        let publisher = StatePublisher<TestState>()
        let expectedState = TestState(value: 1)

        // Get stream first
        let stream = await publisher.stream

        // Send state
        await publisher.send(expectedState)
        await publisher.finish()

        // Collect results
        var received: [TestState] = []
        for await state in stream {
            received.append(state)
        }

        #expect(received.count == 1)
        #expect(received.first == expectedState)
    }

    @Test("Multiple sends emit in order")
    func multipleSendsEmitInOrder() async {
        let publisher = StatePublisher<TestState>()
        let states = (1...5).map { TestState(value: $0) }

        let stream = await publisher.stream

        for state in states {
            await publisher.send(state)
        }
        await publisher.finish()

        var received: [TestState] = []
        for await state in stream {
            received.append(state)
        }

        #expect(received == states)
    }

    @Test("SendIfChanged deduplicates equal states")
    func sendIfChangedDeduplicates() async {
        let publisher = StatePublisher<TestState>()
        let state1 = TestState(value: 1)
        let state2 = TestState(value: 1) // Same value
        let state3 = TestState(value: 2) // Different value

        let stream = await publisher.stream

        let sent1 = await publisher.sendIfChanged(state1)
        let sent2 = await publisher.sendIfChanged(state2)
        let sent3 = await publisher.sendIfChanged(state3)

        await publisher.finish()

        #expect(sent1 == true)
        #expect(sent2 == false)
        #expect(sent3 == true)

        var received: [TestState] = []
        for await state in stream {
            received.append(state)
        }

        #expect(received.count == 2)
        #expect(received[0].value == 1)
        #expect(received[1].value == 2)
    }

    @Test("Finish terminates stream")
    func finishTerminatesStream() async {
        let publisher = StatePublisher<TestState>()

        let stream = await publisher.stream

        await publisher.send(TestState(value: 1))
        await publisher.finish()

        // This should complete without hanging
        var count = 0
        for await _ in stream {
            count += 1
        }

        #expect(count == 1)
    }

    @Test("Send after finish has no effect")
    func sendAfterFinishIgnored() async {
        let publisher = StatePublisher<TestState>()

        let stream = await publisher.stream

        await publisher.send(TestState(value: 1))
        await publisher.finish()
        await publisher.send(TestState(value: 2)) // Should be ignored

        var received: [TestState] = []
        for await state in stream {
            received.append(state)
        }

        #expect(received.count == 1)
        #expect(received.first?.value == 1)
    }

    @Test("Finish is idempotent")
    func finishIsIdempotent() async {
        let publisher = StatePublisher<TestState>()

        let stream = await publisher.stream

        await publisher.send(TestState(value: 1))
        await publisher.finish()
        await publisher.finish() // Should not crash
        await publisher.finish()

        var count = 0
        for await _ in stream {
            count += 1
        }

        #expect(count == 1)
    }

    @Test("Finish with error terminates stream")
    func finishWithErrorTerminates() async {
        struct TestError: Error {}

        let publisher = StatePublisher<TestState>()

        let stream = await publisher.stream

        await publisher.send(TestState(value: 1))
        await publisher.finish(throwing: TestError())

        var count = 0
        for await _ in stream {
            count += 1
        }

        #expect(count == 1)
    }

    @Test("Current state reflects last sent state")
    func currentStateReflectsLastSent() async {
        let publisher = StatePublisher<TestState>()

        await publisher.send(TestState(value: 1))
        await publisher.send(TestState(value: 2))
        await publisher.send(TestState(value: 3))

        let current = await publisher.currentState
        #expect(current?.value == 3)
    }
}

// MARK: - Concurrency Tests

@Suite("StatePublisher Concurrency")
struct StatePublisherConcurrencyTests {

    @Test("Concurrent sends are thread-safe")
    func concurrentSendsAreThreadSafe() async {
        let publisher = StatePublisher<TestState>()

        let stream = await publisher.stream

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    await publisher.send(TestState(value: i))
                }
            }
        }

        await publisher.finish()

        var count = 0
        for await _ in stream {
            count += 1
        }

        #expect(count == 100)
    }

    @Test("Concurrent reads of current state are safe")
    func concurrentReadsAreSafe() async {
        let publisher = StatePublisher<TestState>()
        await publisher.send(TestState(value: 42))

        let results = await withTaskGroup(of: TestState?.self, returning: [TestState?].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    await publisher.currentState
                }
            }

            var collected: [TestState?] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        #expect(results.count == 50)
        #expect(results.allSatisfy { $0?.value == 42 })
    }

    @Test("Mixed concurrent reads and writes are safe")
    func mixedConcurrentOperationsAreSafe() async {
        let publisher = StatePublisher<TestState>()

        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 0..<20 {
                group.addTask {
                    await publisher.send(TestState(value: i))
                }
            }

            // Readers
            for _ in 0..<20 {
                group.addTask {
                    _ = await publisher.currentState
                }
            }
        }

        // Should complete without crashes
        let finalState = await publisher.currentState
        #expect(finalState != nil)
    }
}
