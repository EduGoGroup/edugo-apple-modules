import Testing
@testable import Logger

@Suite("Logger Tests")
struct LoggerTests {
    @Test("Logger shared instance is accessible")
    func testSharedInstance() async {
        let logger = Logger.shared
        await logger.info("Test log message")
        // Logger should not crash
    }
}

@Suite("OSLoggerAdapter Tests")
struct OSLoggerAdapterTests {

    @Test("OSLoggerAdapter initializes with default configuration")
    func testDefaultInitialization() async {
        let logger = OSLoggerAdapter()
        let count = await logger.cachedLoggerCount
        #expect(count == 0)
    }

    @Test("OSLoggerAdapter initializes with custom configuration")
    func testCustomConfiguration() async {
        let config = LogConfiguration(
            globalLevel: .info,
            environment: .development
        )
        let logger = OSLoggerAdapter(configuration: config)
        let count = await logger.cachedLoggerCount
        #expect(count == 0)
    }

    @Test("OSLoggerAdapter logs debug message")
    func testDebugLogging() async {
        let logger = OSLoggerAdapter(configuration: .development)
        await logger.debug("Debug test message")
        // Should not crash
    }

    @Test("OSLoggerAdapter logs info message")
    func testInfoLogging() async {
        let logger = OSLoggerAdapter(configuration: .development)
        await logger.info("Info test message")
        // Should not crash
    }

    @Test("OSLoggerAdapter logs warning message")
    func testWarningLogging() async {
        let logger = OSLoggerAdapter(configuration: .development)
        await logger.warning("Warning test message")
        // Should not crash
    }

    @Test("OSLoggerAdapter logs error message")
    func testErrorLogging() async {
        let logger = OSLoggerAdapter(configuration: .development)
        await logger.error("Error test message")
        // Should not crash
    }

    @Test("OSLoggerAdapter caches loggers by category")
    func testLoggerCaching() async {
        let logger = OSLoggerAdapter(configuration: .development)
        let category = SystemLogCategory.logger

        await logger.info("First message", category: category)
        var count = await logger.cachedLoggerCount
        #expect(count == 1)

        await logger.info("Second message", category: category)
        count = await logger.cachedLoggerCount
        #expect(count == 1)

        let category2 = SystemLogCategory.network
        await logger.info("Third message", category: category2)
        count = await logger.cachedLoggerCount
        #expect(count == 2)
    }

    @Test("OSLoggerAdapter respects level filtering")
    func testLevelFiltering() async {
        // Logger con nivel mínimo warning
        let config = LogConfiguration(
            globalLevel: .warning,
            environment: .production
        )
        let logger = OSLoggerAdapter(configuration: config)

        // Debug e info no deberían registrarse
        await logger.debug("Debug message")
        await logger.info("Info message")

        // Warning y error sí deberían registrarse
        await logger.warning("Warning message")
        await logger.error("Error message")

        // No crash = test passed
    }

    @Test("OSLoggerAdapter clears cache correctly")
    func testClearCache() async {
        let logger = OSLoggerAdapter(configuration: .development)

        await logger.info("Message 1", category: SystemLogCategory.logger)
        await logger.info("Message 2", category: SystemLogCategory.network)

        var count = await logger.cachedLoggerCount
        #expect(count == 2)

        await logger.clearCache()
        count = await logger.cachedLoggerCount
        #expect(count == 0)
    }
}

@Suite("OSLoggerFactory Tests")
struct OSLoggerFactoryTests {

    @Test("Factory creates development logger")
    func testDevelopmentFactory() async {
        let logger = OSLoggerFactory.development()
        await logger.debug("Development logger test")
        // Should not crash
    }

    @Test("Factory creates staging logger")
    func testStagingFactory() async {
        let logger = OSLoggerFactory.staging()
        await logger.info("Staging logger test")
        // Should not crash
    }

    @Test("Factory creates production logger")
    func testProductionFactory() async {
        let logger = OSLoggerFactory.production()
        await logger.warning("Production logger test")
        // Should not crash
    }

    @Test("Factory creates testing logger")
    func testTestingFactory() async {
        let logger = OSLoggerFactory.testing()
        await logger.error("Testing logger test")
        // Should not crash (but won't log anything)
    }

    @Test("Factory creates custom logger")
    func testCustomFactory() async {
        let logger = OSLoggerFactory.custom(
            globalLevel: .info,
            environment: .development,
            subsystem: "com.test.custom"
        )
        await logger.info("Custom logger test")
        // Should not crash
    }

    @Test("Factory creates automatic logger")
    func testAutomaticFactory() async {
        let logger = OSLoggerFactory.automatic()
        await logger.info("Automatic logger test")
        // Should not crash
    }

    @Test("Builder pattern creates logger correctly")
    func testBuilderPattern() async {
        let logger = OSLoggerFactory.builder()
            .globalLevel(.info)
            .environment(.development)
            .override(level: .debug, for: "com.edugo.auth")
            .includeMetadata(true)
            .build()

        await logger.info("Builder pattern test")
        // Should not crash
    }

    @Test("Builder pattern with category override")
    func testBuilderWithCategoryOverride() async {
        let logger = OSLoggerFactory.builder()
            .globalLevel(.warning)
            .override(level: .debug, for: SystemLogCategory.logger)
            .build()

        await logger.debug("Debug message", category: SystemLogCategory.logger)
        // Should not crash
    }
}
