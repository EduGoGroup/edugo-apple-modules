import Testing
@testable import CQRS
import Foundation

@Suite("Observability Tests")
struct ObservabilityTests {

    // MARK: - CacheMetrics Tests

    @Test("CacheMetrics records hits and misses correctly")
    func testCacheMetricsHitsAndMisses() {
        var metrics = CacheMetrics(handlerType: "TestHandler")

        // Record hits
        metrics.recordHit()
        metrics.recordHit()
        metrics.recordHit()

        // Record misses
        metrics.recordMiss()

        #expect(metrics.hits == 3)
        #expect(metrics.misses == 1)
        #expect(metrics.totalAccesses == 4)
        #expect(metrics.hitRatio == 0.75)
        #expect(metrics.missRatio == 0.25)
    }

    @Test("CacheMetrics calculates hit ratio correctly")
    func testCacheMetricsHitRatio() {
        var metrics = CacheMetrics(handlerType: "TestHandler")

        // 7 hits, 3 misses = 70% hit ratio
        for _ in 0..<7 {
            metrics.recordHit()
        }
        for _ in 0..<3 {
            metrics.recordMiss()
        }

        #expect(metrics.hitRatio == 0.7)
        #expect(metrics.totalAccesses == 10)
    }

    @Test("CacheMetrics records invalidations")
    func testCacheMetricsInvalidations() {
        var metrics = CacheMetrics(handlerType: "TestHandler")

        metrics.recordInvalidation()
        metrics.recordInvalidation()
        metrics.recordInvalidation()

        #expect(metrics.invalidations == 3)
    }

    @Test("CacheMetrics records stale hits")
    func testCacheMetricsStaleHits() {
        var metrics = CacheMetrics(handlerType: "TestHandler")

        metrics.recordStaleHit()
        metrics.recordStaleHit()

        #expect(metrics.staleWhileRevalidateHits == 2)
    }

    @Test("CacheMetrics reset works correctly")
    func testCacheMetricsReset() {
        var metrics = CacheMetrics(handlerType: "TestHandler")

        metrics.recordHit()
        metrics.recordMiss()
        metrics.recordInvalidation()
        metrics.recordStaleHit()

        metrics.reset()

        #expect(metrics.hits == 0)
        #expect(metrics.misses == 0)
        #expect(metrics.invalidations == 0)
        #expect(metrics.staleWhileRevalidateHits == 0)
    }

    // MARK: - CQRSMetrics Tests

    @Test("CQRSMetrics records query latency")
    func testQueryLatencyRecording() async {
        let metrics = CQRSMetrics()

        await metrics.recordQueryLatency(
            queryType: "TestQuery",
            duration: .milliseconds(50)
        )

        let stats = await metrics.getQueryLatencyStats(for: "TestQuery")

        #expect(stats != nil)
        #expect(stats?.count == 1)
    }

    @Test("CQRSMetrics calculates query latency stats correctly")
    func testQueryLatencyStats() async {
        let metrics = CQRSMetrics()

        // Record multiple latencies
        await metrics.recordQueryLatency(queryType: "TestQuery", duration: .milliseconds(10))
        await metrics.recordQueryLatency(queryType: "TestQuery", duration: .milliseconds(20))
        await metrics.recordQueryLatency(queryType: "TestQuery", duration: .milliseconds(30))
        await metrics.recordQueryLatency(queryType: "TestQuery", duration: .milliseconds(40))
        await metrics.recordQueryLatency(queryType: "TestQuery", duration: .milliseconds(50))

        let stats = await metrics.getQueryLatencyStats(for: "TestQuery")

        #expect(stats != nil)
        #expect(stats?.count == 5)

        // p50 should be around 30ms
        let p50Ms = LatencyStats.toMilliseconds(stats!.p50)
        #expect(p50Ms >= 20.0 && p50Ms <= 40.0)
    }

    @Test("CQRSMetrics records command latency")
    func testCommandLatencyRecording() async {
        let metrics = CQRSMetrics()

        await metrics.recordCommandLatency(
            commandType: "TestCommand",
            duration: .milliseconds(100)
        )

        let stats = await metrics.getCommandLatencyStats(for: "TestCommand")

        #expect(stats != nil)
        #expect(stats?.count == 1)
    }

    @Test("CQRSMetrics records cache hits")
    func testCacheHitRecording() async {
        let metrics = CQRSMetrics()

        await metrics.recordCacheHit(queryType: "TestQuery")
        await metrics.recordCacheHit(queryType: "TestQuery")

        let cacheMetrics = await metrics.getCacheMetrics(for: "TestQuery")

        #expect(cacheMetrics != nil)
        #expect(cacheMetrics?.hits == 2)
    }

    @Test("CQRSMetrics records cache misses")
    func testCacheMissRecording() async {
        let metrics = CQRSMetrics()

        await metrics.recordCacheMiss(queryType: "TestQuery")

        let cacheMetrics = await metrics.getCacheMetrics(for: "TestQuery")

        #expect(cacheMetrics != nil)
        #expect(cacheMetrics?.misses == 1)
    }

    @Test("CQRSMetrics calculates cache hit ratio")
    func testCacheHitRatioCalculation() async {
        let metrics = CQRSMetrics()

        // 3 hits, 1 miss = 75% hit ratio
        await metrics.recordCacheHit(queryType: "TestQuery")
        await metrics.recordCacheHit(queryType: "TestQuery")
        await metrics.recordCacheHit(queryType: "TestQuery")
        await metrics.recordCacheMiss(queryType: "TestQuery")

        let cacheMetrics = await metrics.getCacheMetrics(for: "TestQuery")

        #expect(cacheMetrics != nil)
        #expect(cacheMetrics?.hitRatio == 0.75)
    }

    @Test("CQRSMetrics records errors")
    func testErrorRecording() async {
        let metrics = CQRSMetrics()

        struct TestError: Error {}
        let error = TestError()

        await metrics.recordError(handlerType: "TestHandler", error: error)
        await metrics.recordError(handlerType: "TestHandler", error: error)

        let errorCount = await metrics.getErrorCount(for: "TestHandler")

        #expect(errorCount == 2)
    }

    @Test("CQRSMetrics records event published")
    func testEventPublishedRecording() async {
        let metrics = CQRSMetrics()

        await metrics.recordEventPublished(eventType: "UserLoggedIn")
        await metrics.recordEventPublished(eventType: "UserLoggedIn")

        let eventMetrics = await metrics.getEventMetrics()

        #expect(eventMetrics.getPublishedCount(for: "UserLoggedIn") == 2)
        #expect(eventMetrics.totalPublished == 2)
    }

    @Test("CQRSMetrics records event processed")
    func testEventProcessedRecording() async {
        let metrics = CQRSMetrics()

        await metrics.recordEventProcessed(eventType: "UserLoggedIn")

        let eventMetrics = await metrics.getEventMetrics()

        #expect(eventMetrics.getProcessedCount(for: "UserLoggedIn") == 1)
        #expect(eventMetrics.totalProcessed == 1)
    }

    @Test("CQRSMetrics reset clears all metrics")
    func testMetricsReset() async {
        let metrics = CQRSMetrics()

        // Record various metrics
        await metrics.recordQueryLatency(queryType: "TestQuery", duration: .milliseconds(10))
        await metrics.recordCommandLatency(commandType: "TestCommand", duration: .milliseconds(20))
        await metrics.recordCacheHit(queryType: "TestQuery")
        await metrics.recordError(handlerType: "TestHandler", error: NSError(domain: "test", code: 1))
        await metrics.recordEventPublished(eventType: "TestEvent")

        // Reset
        await metrics.reset()

        // Verify all cleared
        let queryStats = await metrics.getQueryLatencyStats(for: "TestQuery")
        let commandStats = await metrics.getCommandLatencyStats(for: "TestCommand")
        let cacheMetrics = await metrics.getCacheMetrics(for: "TestQuery")
        let errorCount = await metrics.getErrorCount(for: "TestHandler")
        let eventMetrics = await metrics.getEventMetrics()

        #expect(queryStats == nil)
        #expect(commandStats == nil)
        #expect(cacheMetrics == nil)
        #expect(errorCount == 0)
        #expect(eventMetrics.totalPublished == 0)
    }

    @Test("CQRSMetrics generates complete report")
    func testMetricsReport() async {
        let metrics = CQRSMetrics()

        // Record diverse metrics
        await metrics.recordQueryLatency(queryType: "GetUserQuery", duration: .milliseconds(15))
        await metrics.recordCommandLatency(commandType: "LoginCommand", duration: .milliseconds(100))
        await metrics.recordCacheHit(queryType: "GetUserQuery")
        await metrics.recordCacheMiss(queryType: "GetUserQuery")
        await metrics.recordError(handlerType: "TestHandler", error: NSError(domain: "test", code: 1))
        await metrics.recordEventPublished(eventType: "UserLoggedIn")

        let report = await metrics.generateReport()

        #expect(report.queryStats.count > 0)
        #expect(report.commandStats.count > 0)
        #expect(report.cacheMetrics.count > 0)
        #expect(report.errorCounts.count > 0)
        #expect(report.eventMetrics.totalPublished > 0)
    }

    // MARK: - Integration Tests with Mediator

    @Test("Mediator records query latency metrics")
    func testMediatorQueryMetrics() async throws {
        // Usar instancia aislada de métricas para evitar interferencia entre tests
        let metrics = CQRSMetrics()
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: true, metrics: metrics)

        struct TestQuery: Query {
            typealias Result = Int
            let value: Int
        }

        actor TestQueryHandler: QueryHandler {
            typealias QueryType = TestQuery
            func handle(_ query: TestQuery) async throws -> Int {
                return query.value * 2
            }
        }

        try await mediator.registerQueryHandler(TestQueryHandler())

        let testQuery = TestQuery(value: 42)
        _ = try await mediator.send(testQuery)

        // El nombre del query incluye el namespace completo
        let queryTypeName = String(describing: type(of: testQuery))
        let stats = await metrics.getQueryLatencyStats(for: queryTypeName)

        #expect(stats != nil, "Stats should not be nil for query type: \(queryTypeName)")
        #expect(stats?.count == 1)
    }

    @Test("Mediator records command latency and events")
    func testMediatorCommandMetrics() async throws {
        // Usar instancia aislada de métricas para evitar interferencia entre tests
        let metrics = CQRSMetrics()
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: true, metrics: metrics)

        struct TestCommand: Command {
            typealias Result = Bool
            let value: Int
        }

        actor TestCommandHandler: CommandHandler {
            typealias CommandType = TestCommand
            func handle(_ command: TestCommand) async throws -> CommandResult<Bool> {
                return CommandResult.success(
                    true,
                    events: ["TestEvent"],
                    metadata: [:]
                )
            }
        }

        try await mediator.registerCommandHandler(TestCommandHandler())

        let testCommand = TestCommand(value: 10)
        _ = try await mediator.execute(testCommand)

        // El nombre del command incluye el namespace completo
        let commandTypeName = String(describing: type(of: testCommand))
        let stats = await metrics.getCommandLatencyStats(for: commandTypeName)
        let eventMetrics = await metrics.getEventMetrics()

        #expect(stats != nil, "Stats should not be nil for command type: \(commandTypeName)")
        #expect(stats?.count == 1)
        #expect(eventMetrics.getPublishedCount(for: "TestEvent") == 1)
    }

    @Test("Mediator records errors in metrics")
    func testMediatorErrorMetrics() async throws {
        // Usar instancia aislada de métricas para evitar interferencia entre tests
        let metrics = CQRSMetrics()
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: true, metrics: metrics)

        struct FailingQuery: Query {
            typealias Result = Int
        }

        actor FailingQueryHandler: QueryHandler {
            typealias QueryType = FailingQuery
            func handle(_ query: FailingQuery) async throws -> Int {
                struct TestError: Error {}
                throw TestError()
            }
        }

        try await mediator.registerQueryHandler(FailingQueryHandler())

        let failingQuery = FailingQuery()
        do {
            _ = try await mediator.send(failingQuery)
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
        }

        // El nombre del query incluye el namespace completo
        let queryTypeName = String(describing: type(of: failingQuery))
        let errorCount = await metrics.getErrorCount(for: queryTypeName)

        #expect(errorCount == 1, "Error count should be 1 for query type: \(queryTypeName)")
    }

    @Test("Mediator with metrics disabled doesn't record")
    func testMediatorMetricsDisabled() async throws {
        // Usar instancia aislada de métricas para evitar interferencia entre tests
        let metrics = CQRSMetrics()
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false, metrics: metrics)

        struct TestQuery: Query {
            typealias Result = Int
            let value: Int
        }

        actor TestQueryHandler: QueryHandler {
            typealias QueryType = TestQuery
            func handle(_ query: TestQuery) async throws -> Int {
                return query.value
            }
        }

        try await mediator.registerQueryHandler(TestQueryHandler())

        _ = try await mediator.send(TestQuery(value: 42))

        let stats = await metrics.getQueryLatencyStats(for: "TestQuery")

        #expect(stats == nil)
    }
}
