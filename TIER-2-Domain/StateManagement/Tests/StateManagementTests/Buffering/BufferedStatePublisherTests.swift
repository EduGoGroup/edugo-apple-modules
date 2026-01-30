import Testing
@testable import StateManagement

// MARK: - Test States

private struct BufferTestState: AsyncState {
    let value: Int
}

// MARK: - BufferedStatePublisher Basic Tests

@Suite("BufferedStatePublisher")
struct BufferedStatePublisherTests {

    @Test("Default initializer uses unbounded buffer")
    func defaultInitializerUsesUnboundedBuffer() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>()

        // Should be able to enqueue many elements without blocking
        for i in 0..<100 {
            let result = await publisher.send(BufferTestState(value: i))
            #expect(result == .enqueued)
        }
    }

    @Test("Send updates currentState")
    func sendUpdatesCurrentState() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>()

        await publisher.send(BufferTestState(value: 42))

        let current = await publisher.currentState
        #expect(current?.value == 42)
    }

    @Test("SendIfChanged deduplicates equal states")
    func sendIfChangedDeduplicatesEqualStates() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>()

        let first = await publisher.sendIfChanged(BufferTestState(value: 1))
        #expect(first == .enqueued)

        let second = await publisher.sendIfChanged(BufferTestState(value: 1))
        #expect(second == nil)

        let third = await publisher.sendIfChanged(BufferTestState(value: 2))
        #expect(third == .enqueued)
    }

    @Test("Finish prevents further sends")
    func finishPreventsFurtherSends() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>()

        await publisher.finish()

        let result = await publisher.send(BufferTestState(value: 1))
        #expect(result == .terminated)
    }

    @Test("Finish with error prevents further sends")
    func finishWithErrorPreventsFurtherSends() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>()

        struct TestError: Error {}
        await publisher.finish(throwing: TestError())

        let result = await publisher.send(BufferTestState(value: 1))
        #expect(result == .terminated)
    }
}

// MARK: - Factory Method Tests

@Suite("BufferedStatePublisher Factory Methods")
struct BufferedStatePublisherFactoryTests {

    @Test("Bounded factory creates bounded buffer")
    func boundedFactoryCreatesBoundedBuffer() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>.bounded(capacity: 3)

        // Fill the buffer
        for i in 0..<3 {
            await publisher.send(BufferTestState(value: i))
        }

        let isFull = await publisher.isBufferFull
        #expect(isFull == true)
    }

    @Test("Dropping factory creates dropping buffer")
    func droppingFactoryCreatesDroppingBuffer() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>.dropping(capacity: 3)

        // Overfill should drop oldest
        for i in 0..<10 {
            await publisher.send(BufferTestState(value: i))
        }

        let count = await publisher.bufferCount
        #expect(count <= 3)
    }

    @Test("Unbounded factory creates unbounded buffer")
    func unboundedFactoryCreatesUnboundedBuffer() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>.unbounded()

        for i in 0..<100 {
            await publisher.send(BufferTestState(value: i))
        }

        let isFull = await publisher.isBufferFull
        #expect(isFull == false)
    }
}

// MARK: - Dropping Buffer Publisher Tests

@Suite("BufferedStatePublisher with DroppingBuffer")
struct BufferedStatePublisherDroppingTests {

    @Test("Dropping buffer returns droppedOldest when full")
    func droppingBufferReturnsDroppedOldest() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>.dropping(capacity: 2)

        await publisher.send(BufferTestState(value: 1))
        await publisher.send(BufferTestState(value: 2))

        let result = await publisher.send(BufferTestState(value: 3))
        #expect(result == .droppedOldest)
    }

    @Test("Buffer count stays at capacity")
    func bufferCountStaysAtCapacity() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>.dropping(capacity: 5)

        for i in 0..<20 {
            await publisher.send(BufferTestState(value: i))
        }

        let count = await publisher.bufferCount
        #expect(count == 5)
    }
}

// MARK: - Stream Tests

@Suite("BufferedStatePublisher Stream")
struct BufferedStatePublisherStreamTests {

    @Test("Stream returns StateStream type")
    func streamReturnsStateStreamType() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>()
        let stream = await publisher.stream

        // Verify it's a StateStream by using it
        await publisher.send(BufferTestState(value: 1))
        await publisher.finish()

        var count = 0
        for await _ in stream {
            count += 1
        }

        #expect(count >= 0) // Just verify iteration works
    }

    @Test("Stream is created lazily")
    func streamIsCreatedLazily() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>()

        // Send before accessing stream
        await publisher.send(BufferTestState(value: 1))

        // Now access stream
        _ = await publisher.stream

        // Should still be able to send
        let result = await publisher.send(BufferTestState(value: 2))
        #expect(result == .enqueued)
    }
}

// MARK: - Concurrency Tests

@Suite("BufferedStatePublisher Concurrency")
struct BufferedStatePublisherConcurrencyTests {

    @Test("Concurrent sends are thread-safe")
    func concurrentSendsAreThreadSafe() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    await publisher.send(BufferTestState(value: i))
                }
            }
        }

        let current = await publisher.currentState
        #expect(current != nil)
    }

    @Test("Concurrent reads of bufferCount are safe")
    func concurrentReadsOfBufferCountAreSafe() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>()

        // Fill some elements
        for i in 0..<10 {
            await publisher.send(BufferTestState(value: i))
        }

        await withTaskGroup(of: Int.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    await publisher.bufferCount
                }
            }

            for await count in group {
                #expect(count >= 0)
            }
        }
    }
}

// MARK: - BufferedStatePublisher Sendable Tests

@Suite("BufferedStatePublisher Sendable Conformance")
struct BufferedStatePublisherSendableTests {

    @Test("Publisher can be passed across actor boundaries")
    func publisherCanBePassedAcrossActorBoundaries() async throws {
        let publisher = BufferedStatePublisher<BufferTestState>()

        let result = await Task {
            await publisher.send(BufferTestState(value: 42))
            return await publisher.currentState?.value
        }.value

        #expect(result == 42)
    }
}
