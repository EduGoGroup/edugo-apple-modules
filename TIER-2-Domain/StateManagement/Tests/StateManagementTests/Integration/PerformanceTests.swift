import Testing
import Foundation
@testable import StateManagement

// MARK: - Test State

private struct PerformanceTestState: AsyncState {
    let id: Int
    let payload: String

    init(id: Int, payloadSize: Int = 100) {
        self.id = id
        self.payload = String(repeating: "x", count: payloadSize)
    }
}

// MARK: - Emission Performance Tests

@Suite("Emission Performance")
struct EmissionPerformanceTests {

    @Test("Measure emit to consume latency")
    func measureEmitToConsumeLatency() async throws {
        let publisher = StatePublisher<PerformanceTestState>()
        let stream = await publisher.stream
        let sampleCount = 100

        let consumeTask = Task {
            var latencies: [TimeInterval] = []
            var receivedCount = 0
            for await _ in stream {
                let receiveTime = Date()
                // Calculate latency (approximate since we can't embed send time easily)
                latencies.append(Date().timeIntervalSince(receiveTime))
                receivedCount += 1
                if receivedCount >= sampleCount { break }
            }
            return latencies
        }

        // Small delay to ensure consumer is ready
        try await Task.sleep(nanoseconds: 10_000_000)

        for i in 0..<sampleCount {
            await publisher.send(PerformanceTestState(id: i))
        }

        let latencies = await consumeTask.value
        await publisher.finish()

        // All samples should be received
        #expect(latencies.count == sampleCount)
    }

    @Test("High throughput emission")
    func highThroughputEmission() async throws {
        let publisher = StatePublisher<PerformanceTestState>()
        let emissionCount = 10_000

        let startTime = Date()

        for i in 0..<emissionCount {
            await publisher.send(PerformanceTestState(id: i, payloadSize: 10))
        }

        let duration = Date().timeIntervalSince(startTime)
        let throughput = Double(emissionCount) / duration

        await publisher.finish()

        // Should achieve at least 10,000 emissions per second
        #expect(throughput > 1000, "Throughput: \(throughput) emissions/sec")
    }

    @Test("Emission with large payload")
    func emissionWithLargePayload() async throws {
        let publisher = StatePublisher<PerformanceTestState>()
        let emissionCount = 100
        let payloadSize = 10_000 // 10KB per state

        let startTime = Date()

        for i in 0..<emissionCount {
            await publisher.send(PerformanceTestState(id: i, payloadSize: payloadSize))
        }

        let duration = Date().timeIntervalSince(startTime)
        await publisher.finish()

        // Should complete in reasonable time (< 1 second for 1MB total)
        #expect(duration < 1.0, "Duration: \(duration)s")
    }
}

// MARK: - Operator Performance Tests

@Suite("Operator Performance")
struct OperatorPerformanceTests {

    @Test("Map operator performance")
    func mapOperatorPerformance() async throws {
        let publisher = StatePublisher<PerformanceTestState>()
        let stream = await publisher.stream
        let emissionCount = 1000

        let mappedStream = stream.map { state in
            PerformanceTestState(id: state.id * 2, payloadSize: 10)
        }

        let collectTask = Task {
            var count = 0
            for await _ in mappedStream {
                count += 1
                if count >= emissionCount { break }
            }
            return count
        }

        try await Task.sleep(nanoseconds: 5_000_000)

        let startTime = Date()
        for i in 0..<emissionCount {
            await publisher.send(PerformanceTestState(id: i, payloadSize: 10))
        }
        await publisher.finish()

        let count = await collectTask.value
        let duration = Date().timeIntervalSince(startTime)

        #expect(count == emissionCount)
        #expect(duration < 1.0, "Map processing took \(duration)s")
    }

    @Test("Filter operator performance")
    func filterOperatorPerformance() async throws {
        let publisher = StatePublisher<PerformanceTestState>()
        let stream = await publisher.stream
        let emissionCount = 1000

        let filteredStream = stream.filter { state in
            state.id % 2 == 0
        }

        let collectTask = Task {
            var count = 0
            for await _ in filteredStream {
                count += 1
                if count >= emissionCount / 2 { break }
            }
            return count
        }

        try await Task.sleep(nanoseconds: 5_000_000)

        let startTime = Date()
        for i in 0..<emissionCount {
            await publisher.send(PerformanceTestState(id: i, payloadSize: 10))
        }
        await publisher.finish()

        let count = await collectTask.value
        let duration = Date().timeIntervalSince(startTime)

        #expect(count == emissionCount / 2)
        #expect(duration < 1.0, "Filter processing took \(duration)s")
    }

    @Test("Chained operators performance")
    func chainedOperatorsPerformance() async throws {
        let publisher = StatePublisher<PerformanceTestState>()
        let stream = await publisher.stream
        let emissionCount = 500

        let processedStream = stream
            .filter { $0.id % 2 == 0 }
            .map { PerformanceTestState(id: $0.id * 2, payloadSize: 10) }
            .filter { $0.id < 1000 }

        let collectTask = Task {
            var count = 0
            for await _ in processedStream {
                count += 1
                if count >= 100 { break }
            }
            return count
        }

        try await Task.sleep(nanoseconds: 5_000_000)

        let startTime = Date()
        for i in 0..<emissionCount {
            await publisher.send(PerformanceTestState(id: i, payloadSize: 10))
        }
        await publisher.finish()

        let count = await collectTask.value
        let duration = Date().timeIntervalSince(startTime)

        #expect(count > 0)
        #expect(duration < 1.0, "Chained operators processing took \(duration)s")
    }
}

// MARK: - Buffer Performance Tests

@Suite("Buffer Performance")
struct BufferPerformanceTests {

    @Test("UnboundedBuffer enqueue performance")
    func unboundedBufferEnqueuePerformance() async throws {
        let buffer = UnboundedBuffer<PerformanceTestState>()
        let operationCount = 10_000

        let startTime = Date()
        for i in 0..<operationCount {
            await buffer.enqueue(PerformanceTestState(id: i, payloadSize: 10))
        }
        let duration = Date().timeIntervalSince(startTime)

        let count = await buffer.count
        #expect(count == operationCount)
        #expect(duration < 1.0, "Enqueue took \(duration)s")
    }

    @Test("BoundedBuffer enqueue/dequeue cycle performance")
    func boundedBufferCyclePerformance() async throws {
        let buffer = BoundedBuffer<PerformanceTestState>(capacity: 100)
        let operationCount = 1000

        let startTime = Date()

        // Interleaved enqueue and dequeue
        for i in 0..<operationCount {
            await buffer.enqueue(PerformanceTestState(id: i, payloadSize: 10))
            if i % 2 == 0 {
                _ = await buffer.dequeue()
            }
        }

        let duration = Date().timeIntervalSince(startTime)
        #expect(duration < 1.0, "Cycle took \(duration)s")
    }

    @Test("DroppingBuffer under pressure")
    func droppingBufferUnderPressure() async throws {
        let buffer = DroppingBuffer<PerformanceTestState>(capacity: 10)
        let operationCount = 10_000

        let startTime = Date()
        var droppedCount = 0

        for i in 0..<operationCount {
            let result = await buffer.enqueue(PerformanceTestState(id: i, payloadSize: 10))
            if result == .droppedOldest {
                droppedCount += 1
            }
        }

        let duration = Date().timeIntervalSince(startTime)
        let count = await buffer.count

        #expect(count == 10)
        #expect(droppedCount > 0)
        #expect(duration < 1.0, "Pressure test took \(duration)s")
    }
}

// MARK: - StateMachine Performance Tests

@Suite("StateMachine Performance")
struct StateMachinePerformanceTests {

    @Test("UploadStateMachine transition performance")
    func uploadStateMachineTransitionPerformance() async throws {
        let machine = UploadStateMachine()
        let progressUpdates = 100

        try await machine.transitionToCreating()
        try await machine.startUploading()

        let startTime = Date()
        for i in 1...progressUpdates {
            try await machine.updateProgress(Double(i) / Double(progressUpdates))
        }
        let duration = Date().timeIntervalSince(startTime)

        #expect(duration < 0.5, "Transitions took \(duration)s")
    }

    @Test("AssessmentStateMachine with persistence performance")
    func assessmentStateMachineWithPersistencePerformance() async throws {
        let persistence = InMemoryStatePersistence()
        let machine = AssessmentStateMachine(
            assessmentId: "perf-test",
            persistence: persistence
        )

        try await machine.startLoading()
        try await machine.transitionToReady()
        try await machine.startAssessment(totalQuestions: 100)

        let startTime = Date()
        for _ in 0..<100 {
            try await machine.answerQuestion()
        }
        let duration = Date().timeIntervalSince(startTime)

        #expect(duration < 1.0, "Answer recording took \(duration)s")
    }
}

// MARK: - Merge/CombineLatest Performance Tests

@Suite("Merge CombineLatest Performance")
struct MergeCombineLatestPerformanceTests {

    @Test("Merge multiple streams performance")
    func mergeMultipleStreamsPerformance() async throws {
        let publisher1 = StatePublisher<PerformanceTestState>()
        let publisher2 = StatePublisher<PerformanceTestState>()
        let publisher3 = StatePublisher<PerformanceTestState>()

        let stream1 = await publisher1.stream
        let stream2 = await publisher2.stream
        let stream3 = await publisher3.stream

        let merged = StateMerge.merge(stream1, stream2, stream3)

        let collectTask = Task {
            var count = 0
            for try await _ in merged {
                count += 1
                if count >= 30 { break }
            }
            return count
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        let startTime = Date()

        // Emit to all publishers
        for i in 0..<10 {
            await publisher1.send(PerformanceTestState(id: i, payloadSize: 10))
            await publisher2.send(PerformanceTestState(id: 100 + i, payloadSize: 10))
            await publisher3.send(PerformanceTestState(id: 200 + i, payloadSize: 10))
        }

        await publisher1.finish()
        await publisher2.finish()
        await publisher3.finish()

        let count = try await collectTask.value
        let duration = Date().timeIntervalSince(startTime)

        #expect(count == 30)
        #expect(duration < 1.0, "Merge took \(duration)s")
    }

    @Test("CombineLatest performance")
    func combineLatestPerformance() async throws {
        let publisher1 = StatePublisher<PerformanceTestState>()
        let publisher2 = StatePublisher<PerformanceTestState>()

        let stream1 = await publisher1.stream
        let stream2 = await publisher2.stream

        let combined = StateCombineLatest2(stream1, stream2)

        let collectTask = Task {
            var count = 0
            for try await _ in combined {
                count += 1
                if count >= 10 { break }
            }
            return count
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        let startTime = Date()

        // Emit to both publishers
        for i in 0..<10 {
            await publisher1.send(PerformanceTestState(id: i, payloadSize: 10))
            await publisher2.send(PerformanceTestState(id: i, payloadSize: 10))
        }

        await publisher1.finish()
        await publisher2.finish()

        let count = try await collectTask.value
        let duration = Date().timeIntervalSince(startTime)

        #expect(count >= 1)
        #expect(duration < 1.0, "CombineLatest took \(duration)s")
    }
}
