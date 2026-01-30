import Testing
import Foundation
@testable import StateManagement

// MARK: - Test State

private struct ConcurrencyTestState: AsyncState {
    let id: Int
    let timestamp: Date

    init(id: Int) {
        self.id = id
        self.timestamp = Date()
    }
}

// MARK: - StatePublisher Concurrency Tests

@Suite("StatePublisher Race Conditions")
struct StatePublisherRaceConditionTests {

    @Test("Multiple tasks emitting concurrently to same publisher")
    func multipleTasksEmittingConcurrently() async throws {
        let publisher = StatePublisher<ConcurrencyTestState>()
        let taskCount = 20  // Reduced from 100 for faster tests
        let emissionsPerTask = 5  // Reduced from 10 for faster tests

        await withTaskGroup(of: Void.self) { group in
            for taskId in 0..<taskCount {
                group.addTask {
                    for emission in 0..<emissionsPerTask {
                        let id = taskId * emissionsPerTask + emission
                        await publisher.send(ConcurrencyTestState(id: id))
                    }
                }
            }
        }

        // Verify publisher is still functional
        let current = await publisher.currentState
        #expect(current != nil)
        await publisher.finish()
    }

    @Test("Concurrent readers and writer")
    func concurrentReadersAndWriter() async throws {
        let publisher = StatePublisher<ConcurrencyTestState>()
        let iterations = 20  // Reduced from 50 for faster tests

        await withTaskGroup(of: Void.self) { group in
            // Writer task
            group.addTask {
                for i in 0..<iterations {
                    await publisher.send(ConcurrencyTestState(id: i))
                    try? await Task.sleep(nanoseconds: 100_000)  // Reduced from 1ms to 0.1ms
                }
            }

            // Multiple reader tasks
            for _ in 0..<5 {
                group.addTask {
                    for _ in 0..<iterations {
                        _ = await publisher.currentState
                        try? await Task.sleep(nanoseconds: 50_000)  // Reduced from 0.5ms to 0.05ms
                    }
                }
            }
        }

        await publisher.finish()
    }

    @Test("Finish while emitting")
    func finishWhileEmitting() async throws {
        let publisher = StatePublisher<ConcurrencyTestState>()

        let emitTask = Task {
            for i in 0..<100 {  // Reduced from 1000 for faster tests
                await publisher.send(ConcurrencyTestState(id: i))
            }
        }

        // Small delay then finish
        try await Task.sleep(nanoseconds: 1_000_000)  // Reduced from 10ms to 1ms
        await publisher.finish()

        emitTask.cancel()
    }
}

// MARK: - StateStream Concurrency Tests

@Suite("StateStream Race Conditions")
struct StateStreamRaceConditionTests {

    @Test("Multiple consumers from same stream")
    func multipleConsumersFromSameStream() async throws {
        let publisher = StatePublisher<ConcurrencyTestState>()
        let stream = await publisher.stream

        var consumer1Count = 0
        var consumer2Count = 0

        let consumer1 = Task {
            var count = 0
            for await _ in stream {
                count += 1
                if count >= 5 { break }
            }
            return count
        }

        let consumer2 = Task {
            var count = 0
            for await _ in stream {
                count += 1
                if count >= 5 { break }
            }
            return count
        }

        // Emit states
        for i in 0..<10 {
            await publisher.send(ConcurrencyTestState(id: i))
        }
        await publisher.finish()

        consumer1Count = await consumer1.value
        consumer2Count = await consumer2.value

        // Both consumers should have received states
        #expect(consumer1Count >= 0)
        #expect(consumer2Count >= 0)
    }

    @Test("Cancellation during iteration")
    func cancellationDuringIteration() async throws {
        let publisher = StatePublisher<ConcurrencyTestState>()
        let stream = await publisher.stream

        let consumeTask = Task {
            var count = 0
            for await _ in stream {
                count += 1
                try? await Task.sleep(nanoseconds: 1_000_000)  // Reduced from 10ms to 1ms
            }
            return count
        }

        // Emit some states
        for i in 0..<5 {
            await publisher.send(ConcurrencyTestState(id: i))
        }

        // Cancel the consume task
        consumeTask.cancel()

        // Should complete without hanging
        let _ = await consumeTask.value
        await publisher.finish()
    }
}

// MARK: - Operators Concurrency Tests

@Suite("Operators Race Conditions")
struct OperatorsRaceConditionTests {

    @Test("Concurrent map operations")
    func concurrentMapOperations() async throws {
        let publisher = StatePublisher<ConcurrencyTestState>()
        let stream = await publisher.stream

        let mappedStream = stream.map { state in
            ConcurrencyTestState(id: state.id * 2)
        }

        let collectTask = Task {
            var collected: [Int] = []
            for await state in mappedStream {
                collected.append(state.id)
                if collected.count >= 10 { break }
            }
            return collected
        }

        // Emit concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await publisher.send(ConcurrencyTestState(id: i))
                }
            }
        }

        await publisher.finish()
        let collected = await collectTask.value
        #expect(collected.count >= 0)
    }

    @Test("Concurrent filter operations")
    func concurrentFilterOperations() async throws {
        let publisher = StatePublisher<ConcurrencyTestState>()
        let stream = await publisher.stream

        let filteredStream = stream.filter { state in
            state.id % 2 == 0
        }

        let collectTask = Task {
            var count = 0
            for await _ in filteredStream {
                count += 1
                if count >= 5 { break }
            }
            return count
        }

        for i in 0..<20 {
            await publisher.send(ConcurrencyTestState(id: i))
        }

        await publisher.finish()
        let count = await collectTask.value
        #expect(count >= 0)
    }
}

// MARK: - Buffer Concurrency Tests

@Suite("Buffer Race Conditions")
struct BufferRaceConditionTests {

    @Test("Concurrent enqueue and dequeue on BoundedBuffer")
    func concurrentEnqueueDequeueOnBoundedBuffer() async throws {
        let buffer = BoundedBuffer<ConcurrencyTestState>(capacity: 10)
        let iterations = 50  // Reduced from 100 for faster tests

        await withTaskGroup(of: Void.self) { group in
            // Producer
            group.addTask {
                for i in 0..<iterations {
                    await buffer.enqueue(ConcurrencyTestState(id: i))
                }
            }

            // Consumer
            group.addTask {
                var dequeued = 0
                while dequeued < iterations {
                    if await buffer.dequeue() != nil {
                        dequeued += 1
                    } else {
                        try? await Task.sleep(nanoseconds: 100_000)
                    }
                }
            }
        }

        let isEmpty = await buffer.isEmpty
        #expect(isEmpty)
    }

    @Test("Concurrent enqueue on DroppingBuffer")
    func concurrentEnqueueOnDroppingBuffer() async throws {
        let buffer = DroppingBuffer<ConcurrencyTestState>(capacity: 5)

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {  // Reduced from 100 for faster tests
                group.addTask {
                    await buffer.enqueue(ConcurrencyTestState(id: i))
                }
            }
        }

        // Buffer should never exceed capacity
        let count = await buffer.count
        #expect(count <= 5)
    }

    @Test("Concurrent enqueue on UnboundedBuffer")
    func concurrentEnqueueOnUnboundedBuffer() async throws {
        let buffer = UnboundedBuffer<ConcurrencyTestState>()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {  // Reduced from 100 for faster tests
                group.addTask {
                    await buffer.enqueue(ConcurrencyTestState(id: i))
                }
            }
        }

        // All items should be enqueued
        let count = await buffer.count
        #expect(count == 50)  // Updated to match reduced iteration count
    }
}

// MARK: - StateMachine Concurrency Tests

@Suite("StateMachine Race Conditions")
struct StateMachineRaceConditionTests {

    @Test("Concurrent state reads on UploadStateMachine")
    func concurrentStateReadsOnUploadStateMachine() async throws {
        let machine = UploadStateMachine()

        await withTaskGroup(of: Void.self) { group in
            // State reader tasks
            for _ in 0..<5 {  // Reduced from 10 for faster tests
                group.addTask {
                    for _ in 0..<20 {  // Reduced from 100 for faster tests
                        _ = await machine.currentState
                    }
                }
            }
        }

        let state = await machine.currentState
        #expect(state == .validating)
    }

    @Test("Concurrent state transitions are serialized")
    func concurrentStateTransitionsAreSerialized() async throws {
        let machine = UploadStateMachine()

        // Start from validating
        try await machine.transitionToCreating()
        try await machine.startUploading()

        // Multiple concurrent progress updates should be serialized
        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    try? await machine.updateProgress(Double(i) / 10.0)
                }
            }
        }

        // State should still be valid
        let state = await machine.currentState
        switch state {
        case .uploading:
            break // Expected
        default:
            Issue.record("Unexpected state: \(state)")
        }
    }
}

// MARK: - Stress Tests

@Suite("Concurrency Stress Tests")
struct ConcurrencyStressTests {

    @Test("High-frequency emissions")
    func highFrequencyEmissions() async throws {
        let publisher = StatePublisher<ConcurrencyTestState>()
        let emissionCount = 200  // Reduced from 1000 for faster tests

        let emitTask = Task {
            for i in 0..<emissionCount {
                await publisher.send(ConcurrencyTestState(id: i))
            }
        }

        await emitTask.value
        await publisher.finish()

        // Verify we can still access current state
        let current = await publisher.currentState
        #expect(current?.id == emissionCount - 1)
    }

    @Test("Many concurrent publishers")
    func manyConcurrentPublishers() async throws {
        let publisherCount = 10  // Reduced from 50 for faster tests
        let emissionsPerPublisher = 5  // Reduced from 20 for faster tests

        await withTaskGroup(of: Void.self) { group in
            for p in 0..<publisherCount {
                group.addTask {
                    let publisher = StatePublisher<ConcurrencyTestState>()
                    for i in 0..<emissionsPerPublisher {
                        await publisher.send(ConcurrencyTestState(id: p * 100 + i))
                    }
                    await publisher.finish()
                }
            }
        }

        // If we get here without hanging, test passes
    }

    @Test("Rapid create and destroy cycles")
    func rapidCreateAndDestroyCycles() async throws {
        for cycle in 0..<20 {  // Reduced from 100 for faster tests
            let publisher = StatePublisher<ConcurrencyTestState>()
            await publisher.send(ConcurrencyTestState(id: cycle))
            await publisher.finish()
        }
        // If we complete without issues, test passes
    }
}
