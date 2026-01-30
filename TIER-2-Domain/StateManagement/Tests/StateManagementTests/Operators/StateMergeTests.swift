import Testing
@testable import StateManagement

// MARK: - Test States

private struct MergeTestState: AsyncState {
    let id: Int
    let source: String
}

private struct IntState: AsyncState {
    let value: Int
}

private struct UnitsState: AsyncState {
    let units: [String]
}

private struct MaterialsState: AsyncState {
    let materials: [String]
}

private struct ProgressState: AsyncState {
    let progress: Int
}

// MARK: - StateMerge Tests

@Suite("StateMerge")
struct StateMergeTests {

    @Test("Merge two streams emits all elements")
    func mergeTwoStreams() async throws {
        let stream1 = StateStream.from([
            MergeTestState(id: 1, source: "A"),
            MergeTestState(id: 2, source: "A")
        ])
        let stream2 = StateStream.from([
            MergeTestState(id: 3, source: "B"),
            MergeTestState(id: 4, source: "B")
        ])

        let merged = StateMerge<MergeTestState>.merge(stream1, stream2)

        var results: [MergeTestState] = []
        for try await state in merged {
            results.append(state)
        }

        #expect(results.count == 4)
        let ids = Set(results.map(\.id))
        #expect(ids == [1, 2, 3, 4])
    }

    @Test("Merge three streams emits all elements")
    func mergeThreeStreams() async throws {
        let stream1 = StateStream.from([MergeTestState(id: 1, source: "A")])
        let stream2 = StateStream.from([MergeTestState(id: 2, source: "B")])
        let stream3 = StateStream.from([MergeTestState(id: 3, source: "C")])

        let merged = StateMerge<MergeTestState>.merge(stream1, stream2, stream3)

        var results: [MergeTestState] = []
        for try await state in merged {
            results.append(state)
        }

        #expect(results.count == 3)
        let ids = Set(results.map(\.id))
        #expect(ids == [1, 2, 3])
    }

    @Test("Merge four streams emits all elements")
    func mergeFourStreams() async throws {
        let stream1 = StateStream.from([MergeTestState(id: 1, source: "A")])
        let stream2 = StateStream.from([MergeTestState(id: 2, source: "B")])
        let stream3 = StateStream.from([MergeTestState(id: 3, source: "C")])
        let stream4 = StateStream.from([MergeTestState(id: 4, source: "D")])

        let merged = StateMerge<MergeTestState>.merge(stream1, stream2, stream3, stream4)

        var results: [MergeTestState] = []
        for try await state in merged {
            results.append(state)
        }

        #expect(results.count == 4)
        let ids = Set(results.map(\.id))
        #expect(ids == [1, 2, 3, 4])
    }

    @Test("Empty stream does not affect merge")
    func emptyStreamDoesNotAffectMerge() async throws {
        let stream1 = StateStream.from([
            MergeTestState(id: 1, source: "A"),
            MergeTestState(id: 2, source: "A")
        ])
        let emptyStream = StateStream<MergeTestState>.empty()

        let merged = StateMerge<MergeTestState>.merge(stream1, emptyStream)

        var results: [MergeTestState] = []
        for try await state in merged {
            results.append(state)
        }

        #expect(results.count == 2)
    }

    @Test("All empty streams produce empty result")
    func allEmptyStreamsProduceEmptyResult() async throws {
        let empty1 = StateStream<MergeTestState>.empty()
        let empty2 = StateStream<MergeTestState>.empty()

        let merged = StateMerge<MergeTestState>.merge(empty1, empty2)

        var count = 0
        for try await _ in merged {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Merge completes only when all streams complete")
    func mergeCompletesWhenAllComplete() async throws {
        let publisher1 = StatePublisher<MergeTestState>()
        let publisher2 = StatePublisher<MergeTestState>()

        let stream1 = await publisher1.stream
        let stream2 = await publisher2.stream

        let merged = StateMerge<MergeTestState>.merge(stream1, stream2)

        // Emit from first, finish first
        await publisher1.send(MergeTestState(id: 1, source: "A"))
        await publisher1.finish()

        // Emit from second, finish second
        await publisher2.send(MergeTestState(id: 2, source: "B"))
        await publisher2.finish()

        var results: [MergeTestState] = []
        for try await state in merged {
            results.append(state)
        }

        #expect(results.count == 2)
    }
}

// MARK: - Extension Tests

@Suite("AsyncSequence+Merge Extension")
struct AsyncSequenceMergeExtensionTests {

    @Test("Extension merge with works")
    func extensionMergeWith() async throws {
        let stream1 = StateStream.from([MergeTestState(id: 1, source: "A")])
        let stream2 = StateStream.from([MergeTestState(id: 2, source: "B")])

        let merged = stream1.merge(with: stream2)

        var results: [MergeTestState] = []
        for try await state in merged {
            results.append(state)
        }

        #expect(results.count == 2)
    }

    @Test("Extension merge with two others works")
    func extensionMergeWithTwoOthers() async throws {
        let stream1 = StateStream.from([MergeTestState(id: 1, source: "A")])
        let stream2 = StateStream.from([MergeTestState(id: 2, source: "B")])
        let stream3 = StateStream.from([MergeTestState(id: 3, source: "C")])

        let merged = stream1.merge(with: stream2, stream3)

        var results: [MergeTestState] = []
        for try await state in merged {
            results.append(state)
        }

        #expect(results.count == 3)
    }

    @Test("Extension merge with three others works")
    func extensionMergeWithThreeOthers() async throws {
        let stream1 = StateStream.from([MergeTestState(id: 1, source: "A")])
        let stream2 = StateStream.from([MergeTestState(id: 2, source: "B")])
        let stream3 = StateStream.from([MergeTestState(id: 3, source: "C")])
        let stream4 = StateStream.from([MergeTestState(id: 4, source: "D")])

        let merged = stream1.merge(with: stream2, stream3, stream4)

        var results: [MergeTestState] = []
        for try await state in merged {
            results.append(state)
        }

        #expect(results.count == 4)
    }
}

// MARK: - Free Function Tests

@Suite("Merge Free Functions")
struct MergeFreeFunctionsTests {

    @Test("Free function merge2 works")
    func freeFunctionMerge2() async throws {
        let stream1 = StateStream.from([MergeTestState(id: 1, source: "A")])
        let stream2 = StateStream.from([MergeTestState(id: 2, source: "B")])

        let merged = merge(stream1, stream2)

        var results: [MergeTestState] = []
        for try await state in merged {
            results.append(state)
        }

        #expect(results.count == 2)
    }

    @Test("Free function merge3 works")
    func freeFunctionMerge3() async throws {
        let stream1 = StateStream.from([MergeTestState(id: 1, source: "A")])
        let stream2 = StateStream.from([MergeTestState(id: 2, source: "B")])
        let stream3 = StateStream.from([MergeTestState(id: 3, source: "C")])

        let merged = merge(stream1, stream2, stream3)

        var results: [MergeTestState] = []
        for try await state in merged {
            results.append(state)
        }

        #expect(results.count == 3)
    }

    @Test("Free function merge4 works")
    func freeFunctionMerge4() async throws {
        let stream1 = StateStream.from([MergeTestState(id: 1, source: "A")])
        let stream2 = StateStream.from([MergeTestState(id: 2, source: "B")])
        let stream3 = StateStream.from([MergeTestState(id: 3, source: "C")])
        let stream4 = StateStream.from([MergeTestState(id: 4, source: "D")])

        let merged = merge(stream1, stream2, stream3, stream4)

        var results: [MergeTestState] = []
        for try await state in merged {
            results.append(state)
        }

        #expect(results.count == 4)
    }
}

// MARK: - AnyAsyncSequence Tests

@Suite("AnyAsyncSequence")
struct AnyAsyncSequenceTests {

    @Test("Type erased sequence emits all elements")
    func typeErasedSequenceEmitsAll() async throws {
        let original = StateStream.from([
            MergeTestState(id: 1, source: "A"),
            MergeTestState(id: 2, source: "A")
        ])
        let erased = AnyAsyncSequence(original)

        var results: [MergeTestState] = []
        for try await state in erased {
            results.append(state)
        }

        #expect(results.count == 2)
        #expect(results[0].id == 1)
        #expect(results[1].id == 2)
    }

    @Test("Empty type erased sequence completes immediately")
    func emptyTypeErasedSequence() async throws {
        let original = StateStream<MergeTestState>.empty()
        let erased = AnyAsyncSequence(original)

        var count = 0
        for try await _ in erased {
            count += 1
        }

        #expect(count == 0)
    }
}

// MARK: - Cancellation Tests

@Suite("StateMerge Cancellation")
struct StateMergeCancellationTests {

    @Test("Break early stops iteration")
    func breakEarlyStopsIteration() async throws {
        let stream1 = StateStream.from((1...100).map { MergeTestState(id: $0, source: "A") })
        let stream2 = StateStream.from((101...200).map { MergeTestState(id: $0, source: "B") })

        let merged = StateMerge<MergeTestState>.merge(stream1, stream2)

        var count = 0
        for try await _ in merged {
            count += 1
            if count >= 5 {
                break
            }
        }

        #expect(count == 5)
    }
}

// MARK: - Integration Tests

@Suite("StateMerge Integration")
struct StateMergeIntegrationTests {

    @Test("Merge with map transformation")
    func mergeWithMapTransformation() async throws {
        let stream1 = StateStream.from([
            IntState(value: 1),
            IntState(value: 2),
            IntState(value: 3)
        ])
        let stream2 = StateStream.from([
            IntState(value: 4),
            IntState(value: 5),
            IntState(value: 6)
        ])

        let mapped1 = stream1.map { MergeTestState(id: $0.value, source: "A") }
        let mapped2 = stream2.map { MergeTestState(id: $0.value, source: "B") }

        let merged = StateMerge<MergeTestState>.merge(mapped1, mapped2)

        var results: [MergeTestState] = []
        for try await state in merged {
            results.append(state)
        }

        #expect(results.count == 6)
        let ids = Set(results.map(\.id))
        #expect(ids == [1, 2, 3, 4, 5, 6])
    }

    @Test("Dashboard use case simulation")
    func dashboardUseCaseSimulation() async throws {
        // Simulate LoadStudentDashboardUseCase scenario
        enum DashboardEvent: Sendable, Equatable {
            case units([String])
            case materials([String])
            case progress(Int)
        }

        let unitsStream = StateStream.from([UnitsState(units: ["Unit1", "Unit2"])])
            .map { DashboardEvent.units($0.units) }
        let materialsStream = StateStream.from([MaterialsState(materials: ["Mat1", "Mat2", "Mat3"])])
            .map { DashboardEvent.materials($0.materials) }
        let progressStream = StateStream.from([ProgressState(progress: 75)])
            .map { DashboardEvent.progress($0.progress) }

        let merged = StateMerge<DashboardEvent>.merge(unitsStream, materialsStream, progressStream)

        var results: [DashboardEvent] = []
        for try await event in merged {
            results.append(event)
        }

        #expect(results.count == 3)
        #expect(results.contains(.units(["Unit1", "Unit2"])))
        #expect(results.contains(.materials(["Mat1", "Mat2", "Mat3"])))
        #expect(results.contains(.progress(75)))
    }
}

// MARK: - Sendable Conformance Tests

@Suite("StateMerge Sendable Conformance")
struct StateMergeSendableTests {

    @Test("Merged stream can be passed across actor boundaries")
    func mergedStreamAcrossActors() async throws {
        let stream1 = StateStream.from([MergeTestState(id: 1, source: "A")])
        let stream2 = StateStream.from([MergeTestState(id: 2, source: "B")])
        let merged = StateMerge<MergeTestState>.merge(stream1, stream2)

        let result = await Task {
            var collected: [MergeTestState] = []
            do {
                for try await state in merged {
                    collected.append(state)
                }
            } catch {
                // Ignore errors in test
            }
            return collected
        }.value

        #expect(result.count == 2)
    }
}
