import Testing
@testable import StateManagement

// MARK: - Test States

private struct ProgressState: AsyncState {
    let value: Int
}

// MARK: - UnboundedBuffer Tests

@Suite("UnboundedBuffer")
struct UnboundedBufferTests {

    @Test("Enqueue always succeeds")
    func enqueueAlwaysSucceeds() async throws {
        let buffer = UnboundedBuffer<ProgressState>()

        for i in 0..<100 {
            let result = await buffer.enqueue(ProgressState(value: i))
            #expect(result == .enqueued)
        }

        let count = await buffer.count
        #expect(count == 100)
    }

    @Test("Dequeue returns elements in order")
    func dequeueReturnsInOrder() async throws {
        let buffer = UnboundedBuffer<ProgressState>()

        for i in 0..<5 {
            await buffer.enqueue(ProgressState(value: i))
        }

        for i in 0..<5 {
            let element = await buffer.dequeue()
            #expect(element?.value == i)
        }
    }

    @Test("Dequeue returns nil when empty")
    func dequeueReturnsNilWhenEmpty() async throws {
        let buffer = UnboundedBuffer<ProgressState>()

        let element = await buffer.dequeue()
        #expect(element == nil)
    }

    @Test("isFull always returns false")
    func isFullAlwaysReturnsFalse() async throws {
        let buffer = UnboundedBuffer<ProgressState>()

        for i in 0..<1000 {
            await buffer.enqueue(ProgressState(value: i))
        }

        let isFull = await buffer.isFull
        #expect(isFull == false)
    }

    @Test("isEmpty returns correct value")
    func isEmptyReturnsCorrectValue() async throws {
        let buffer = UnboundedBuffer<ProgressState>()

        var isEmpty = await buffer.isEmpty
        #expect(isEmpty == true)

        await buffer.enqueue(ProgressState(value: 1))
        isEmpty = await buffer.isEmpty
        #expect(isEmpty == false)

        _ = await buffer.dequeue()
        isEmpty = await buffer.isEmpty
        #expect(isEmpty == true)
    }

    @Test("Clear removes all elements")
    func clearRemovesAllElements() async throws {
        let buffer = UnboundedBuffer<ProgressState>()

        for i in 0..<10 {
            await buffer.enqueue(ProgressState(value: i))
        }

        await buffer.clear()

        let count = await buffer.count
        #expect(count == 0)
    }

    @Test("Terminate prevents further enqueues")
    func terminatePreventsFurtherEnqueues() async throws {
        let buffer = UnboundedBuffer<ProgressState>()

        await buffer.terminate()

        let result = await buffer.enqueue(ProgressState(value: 1))
        #expect(result == .terminated)
    }
}

// MARK: - DroppingBuffer Tests

@Suite("DroppingBuffer")
struct DroppingBufferTests {

    @Test("Enqueue succeeds when not full")
    func enqueueSucceedsWhenNotFull() async throws {
        let buffer = DroppingBuffer<ProgressState>(capacity: 5)

        for i in 0..<5 {
            let result = await buffer.enqueue(ProgressState(value: i))
            #expect(result == .enqueued)
        }
    }

    @Test("Enqueue drops oldest when full")
    func enqueueDropsOldestWhenFull() async throws {
        let buffer = DroppingBuffer<ProgressState>(capacity: 3)

        // Fill the buffer
        for i in 0..<3 {
            await buffer.enqueue(ProgressState(value: i))
        }

        // Add one more - should drop oldest
        let result = await buffer.enqueue(ProgressState(value: 100))
        #expect(result == .droppedOldest)

        // First element should now be 1, not 0
        let first = await buffer.dequeue()
        #expect(first?.value == 1)
    }

    @Test("isFull returns true at capacity")
    func isFullReturnsTrueAtCapacity() async throws {
        let buffer = DroppingBuffer<ProgressState>(capacity: 3)

        for i in 0..<3 {
            await buffer.enqueue(ProgressState(value: i))
        }

        let isFull = await buffer.isFull
        #expect(isFull == true)
    }

    @Test("Count never exceeds capacity")
    func countNeverExceedsCapacity() async throws {
        let buffer = DroppingBuffer<ProgressState>(capacity: 5)

        for i in 0..<100 {
            await buffer.enqueue(ProgressState(value: i))
        }

        let count = await buffer.count
        #expect(count == 5)
    }

    @Test("Contains latest elements after overflow")
    func containsLatestElementsAfterOverflow() async throws {
        let buffer = DroppingBuffer<ProgressState>(capacity: 3)

        for i in 0..<10 {
            await buffer.enqueue(ProgressState(value: i))
        }

        // Should contain 7, 8, 9
        let first = await buffer.dequeue()
        let second = await buffer.dequeue()
        let third = await buffer.dequeue()

        #expect(first?.value == 7)
        #expect(second?.value == 8)
        #expect(third?.value == 9)
    }

    @Test("Terminate prevents further enqueues")
    func terminatePreventsFurtherEnqueues() async throws {
        let buffer = DroppingBuffer<ProgressState>(capacity: 5)

        await buffer.terminate()

        let result = await buffer.enqueue(ProgressState(value: 1))
        #expect(result == .terminated)
    }

    @Test("Clear removes all elements")
    func clearRemovesAllElements() async throws {
        let buffer = DroppingBuffer<ProgressState>(capacity: 5)

        for i in 0..<5 {
            await buffer.enqueue(ProgressState(value: i))
        }

        await buffer.clear()

        let count = await buffer.count
        #expect(count == 0)
    }
}

// MARK: - BoundedBuffer Tests

@Suite("BoundedBuffer")
struct BoundedBufferTests {

    @Test("Enqueue succeeds when not full")
    func enqueueSucceedsWhenNotFull() async throws {
        let buffer = BoundedBuffer<ProgressState>(capacity: 5)

        for i in 0..<5 {
            let result = await buffer.enqueue(ProgressState(value: i))
            #expect(result == .enqueued)
        }
    }

    @Test("isFull returns true at capacity")
    func isFullReturnsTrueAtCapacity() async throws {
        let buffer = BoundedBuffer<ProgressState>(capacity: 3)

        for i in 0..<3 {
            await buffer.enqueue(ProgressState(value: i))
        }

        let isFull = await buffer.isFull
        #expect(isFull == true)
    }

    @Test("Dequeue returns elements in order")
    func dequeueReturnsInOrder() async throws {
        let buffer = BoundedBuffer<ProgressState>(capacity: 5)

        for i in 0..<5 {
            await buffer.enqueue(ProgressState(value: i))
        }

        for i in 0..<5 {
            let element = await buffer.dequeue()
            #expect(element?.value == i)
        }
    }

    @Test("Dequeue returns nil when empty")
    func dequeueReturnsNilWhenEmpty() async throws {
        let buffer = BoundedBuffer<ProgressState>(capacity: 5)

        let element = await buffer.dequeue()
        #expect(element == nil)
    }

    @Test("Clear removes all elements")
    func clearRemovesAllElements() async throws {
        let buffer = BoundedBuffer<ProgressState>(capacity: 5)

        for i in 0..<5 {
            await buffer.enqueue(ProgressState(value: i))
        }

        await buffer.clear()

        let count = await buffer.count
        #expect(count == 0)
    }

    @Test("Terminate prevents further enqueues")
    func terminatePreventsFurtherEnqueues() async throws {
        let buffer = BoundedBuffer<ProgressState>(capacity: 5)

        await buffer.terminate()

        let result = await buffer.enqueue(ProgressState(value: 1))
        #expect(result == .terminated)
    }

    @Test("isEmpty returns correct value")
    func isEmptyReturnsCorrectValue() async throws {
        let buffer = BoundedBuffer<ProgressState>(capacity: 5)

        var isEmpty = await buffer.isEmpty
        #expect(isEmpty == true)

        await buffer.enqueue(ProgressState(value: 1))
        isEmpty = await buffer.isEmpty
        #expect(isEmpty == false)
    }
}

// MARK: - BufferEnqueueResult Tests

@Suite("BufferEnqueueResult")
struct BufferEnqueueResultTests {

    @Test("Enqueued result is correct")
    func enqueuedResultIsCorrect() {
        let result = BufferEnqueueResult.enqueued
        #expect(result == .enqueued)
    }

    @Test("DroppedOldest result is correct")
    func droppedOldestResultIsCorrect() {
        let result = BufferEnqueueResult.droppedOldest
        #expect(result == .droppedOldest)
    }

    @Test("Terminated result is correct")
    func terminatedResultIsCorrect() {
        let result = BufferEnqueueResult.terminated
        #expect(result == .terminated)
    }

    @Test("EnqueuedAfterWaiting result is correct")
    func enqueuedAfterWaitingResultIsCorrect() {
        let result = BufferEnqueueResult.enqueuedAfterWaiting
        #expect(result == .enqueuedAfterWaiting)
    }

    @Test("Results are equatable")
    func resultsAreEquatable() {
        #expect(BufferEnqueueResult.enqueued == BufferEnqueueResult.enqueued)
        #expect(BufferEnqueueResult.enqueued != BufferEnqueueResult.terminated)
    }
}
