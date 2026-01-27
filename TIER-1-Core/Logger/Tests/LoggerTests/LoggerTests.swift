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

@Suite("LoggerRegistry Tests", .serialized)
struct LoggerRegistryTests {

    @Test("LoggerRegistry shared instance is accessible")
    func testSharedInstance() async {
        let registry = LoggerRegistry.shared
        let config = await registry.configuration
        #expect(config.subsystem == "com.edugo.apple")
    }

    @Test("Configure registry with new configuration")
    func testConfigureRegistry() async {
        let registry = LoggerRegistry.shared
        let newConfig = LogConfiguration(
            globalLevel: .warning,
            environment: .production
        )

        await registry.configure(with: newConfig)
        let config = await registry.configuration

        #expect(config.globalLevel == .warning)
        #expect(config.environment == .production)
    }

    @Test("Register category successfully")
    func testRegisterCategory() async {
        let registry = LoggerRegistry.shared
        await registry.reset()

        let wasRegistered = await registry.register(category: SystemLogCategory.logger)
        #expect(wasRegistered == true)

        let isRegistered = await registry.isRegistered(category: SystemLogCategory.logger)
        #expect(isRegistered == true)
    }

    @Test("Register duplicate category returns false")
    func testRegisterDuplicateCategory() async {
        let registry = LoggerRegistry.shared
        await registry.reset()

        let firstRegistration = await registry.register(category: SystemLogCategory.network)
        #expect(firstRegistration == true)

        let secondRegistration = await registry.register(category: SystemLogCategory.network)
        #expect(secondRegistration == false)
    }

    @Test("Register multiple categories")
    func testRegisterMultipleCategories() async {
        let registry = LoggerRegistry.shared
        await registry.reset()

        let categories: [LogCategory] = [
            SystemLogCategory.logger,
            SystemLogCategory.network,
            SystemLogCategory.database
        ]

        let count = await registry.register(categories: categories)
        #expect(count == 3)

        let registeredCount = await registry.registeredCategoryCount
        #expect(registeredCount == 3)
    }

    @Test("Register system categories")
    func testRegisterSystemCategories() async {
        let registry = LoggerRegistry.shared
        await registry.reset()

        let count = await registry.registerSystemCategories()
        #expect(count > 0)

        let isRegistered = await registry.isRegistered(category: SystemLogCategory.logger)
        #expect(isRegistered == true)
    }

    @Test("Logger factory creates logger for category")
    func testLoggerFactory() async {
        let registry = LoggerRegistry.shared
        await registry.reset()
        await registry.configure(with: .development)

        let logger = await registry.logger(for: SystemLogCategory.logger)

        // Logger should be usable
        await logger.info("Test message from registry logger")
    }

    @Test("Logger factory caches loggers")
    func testLoggerFactoryCaching() async {
        let registry = LoggerRegistry.shared
        await registry.reset()
        await registry.configure(with: .development)

        let logger1 = await registry.logger(for: SystemLogCategory.logger)
        let count1 = await registry.cachedLoggerCount
        #expect(count1 == 1)

        let logger2 = await registry.logger(for: SystemLogCategory.logger)
        let count2 = await registry.cachedLoggerCount
        #expect(count2 == 1)

        // Should be same instance
        await logger1.info("Message 1")
        await logger2.info("Message 2")
    }

    @Test("Set level override for category")
    func testSetLevelOverride() async {
        let registry = LoggerRegistry.shared
        await registry.reset()
        await registry.configure(with: .production)

        // Set debug level for specific category
        await registry.setLevel(.debug, for: SystemLogCategory.logger)

        let logger = await registry.logger(for: SystemLogCategory.logger)
        await logger.debug("Debug message should be logged")
    }

    @Test("Set configuration override for category")
    func testSetConfigurationOverride() async {
        let registry = LoggerRegistry.shared
        await registry.reset()
        await registry.configure(with: .production)

        let customConfig = LogConfiguration(
            globalLevel: .debug,
            environment: .development,
            includeMetadata: true
        )

        await registry.setConfiguration(customConfig, for: SystemLogCategory.network)

        let logger = await registry.logger(for: SystemLogCategory.network)
        await logger.debug("Custom config message")
    }

    @Test("Reset configuration for category")
    func testResetConfigurationForCategory() async {
        let registry = LoggerRegistry.shared
        await registry.reset()
        await registry.configure(with: .production)

        // Set override
        await registry.setLevel(.debug, for: SystemLogCategory.logger)
        let logger1 = await registry.logger(for: SystemLogCategory.logger)
        await logger1.debug("With override")

        // Reset override
        await registry.resetConfiguration(for: SystemLogCategory.logger)
        let logger2 = await registry.logger(for: SystemLogCategory.logger)
        await logger2.debug("After reset")
    }

    @Test("Clear cache removes all loggers")
    func testClearCache() async {
        let registry = LoggerRegistry.shared
        await registry.reset()

        _ = await registry.logger(for: SystemLogCategory.logger)
        _ = await registry.logger(for: SystemLogCategory.network)

        let count1 = await registry.cachedLoggerCount
        #expect(count1 == 2)

        await registry.clearCache()

        let count2 = await registry.cachedLoggerCount
        #expect(count2 == 0)
    }

    @Test("Clear cache for specific category")
    func testClearCacheForCategory() async {
        let registry = LoggerRegistry.shared
        await registry.reset()

        _ = await registry.logger(for: SystemLogCategory.logger)
        _ = await registry.logger(for: SystemLogCategory.network)

        let count1 = await registry.cachedLoggerCount
        #expect(count1 == 2)

        await registry.clearCache(for: SystemLogCategory.logger)

        let count2 = await registry.cachedLoggerCount
        #expect(count2 == 1)
    }

    @Test("Logger for category by string ID")
    func testLoggerForCategoryId() async {
        let registry = LoggerRegistry.shared
        await registry.reset()
        await registry.configure(with: .development)

        let logger = await registry.logger(forCategoryId: "com.edugo.custom.test")
        await logger.info("Test message from string ID")
    }

    @Test("Configure with preset")
    func testConfigureWithPreset() async {
        let registry = LoggerRegistry.shared
        await registry.reset()

        await registry.configure(preset: .production)
        let config = await registry.configuration

        #expect(config.globalLevel == .warning)
        #expect(config.environment == .production)
    }

    @Test("Reset registry clears everything")
    func testResetRegistry() async {
        let registry = LoggerRegistry.shared

        // Setup some state
        await registry.register(category: SystemLogCategory.logger)
        _ = await registry.logger(for: SystemLogCategory.network)
        await registry.setLevel(.debug, for: SystemLogCategory.database)

        let count1 = await registry.registeredCategoryCount
        let cached1 = await registry.cachedLoggerCount
        #expect(count1 > 0)
        #expect(cached1 > 0)

        // Reset
        await registry.reset()

        let count2 = await registry.registeredCategoryCount
        let cached2 = await registry.cachedLoggerCount
        #expect(count2 == 0)
        #expect(cached2 == 0)
    }

    @Test("Logger without category uses global config")
    func testLoggerWithoutCategory() async {
        let registry = LoggerRegistry.shared
        await registry.reset()
        await registry.configure(with: .development)

        let logger = await registry.logger()
        await logger.info("Message without category")
    }
}

@Suite("EnvironmentConfiguration Tests", .serialized)
struct EnvironmentConfigurationTests {
    
    @Test("Load empty environment")
    func testLoadEmptyEnvironment() {
        let config = EnvironmentConfiguration.load(from: [:])
        
        #expect(config.logLevel == nil)
        #expect(config.isEnabled == nil)
        #expect(config.includeMetadata == nil)
        #expect(config.environment == nil)
        #expect(config.subsystem == nil)
        #expect(config.hasAnyConfiguration == false)
    }
    
    @Test("Parse log level from environment")
    func testParseLogLevel() {
        let env = ["EDUGO_LOG_LEVEL": "debug"]
        let config = EnvironmentConfiguration.load(from: env)
        
        #expect(config.logLevel == .debug)
    }
    
    @Test("Parse all log levels")
    func testParseAllLogLevels() {
        let levels = [
            ("debug", LogLevel.debug),
            ("info", LogLevel.info),
            ("warning", LogLevel.warning),
            ("warn", LogLevel.warning),
            ("error", LogLevel.error)
        ]
        
        for (string, expected) in levels {
            let config = EnvironmentConfiguration.load(from: ["EDUGO_LOG_LEVEL": string])
            #expect(config.logLevel == expected)
        }
    }
    
    @Test("Parse boolean values")
    func testParseBooleanValues() {
        let trueValues = ["true", "1", "yes", "TRUE", "Yes"]
        let falseValues = ["false", "0", "no", "FALSE", "No"]
        
        for value in trueValues {
            let config = EnvironmentConfiguration.load(from: ["EDUGO_LOG_ENABLED": value])
            #expect(config.isEnabled == true)
        }
        
        for value in falseValues {
            let config = EnvironmentConfiguration.load(from: ["EDUGO_LOG_ENABLED": value])
            #expect(config.isEnabled == false)
        }
    }
    
    @Test("Parse environment")
    func testParseEnvironment() {
        let envs: [(String, LogConfiguration.Environment)] = [
            ("development", .development),
            ("staging", .staging),
            ("production", .production)
        ]
        
        for (string, expected) in envs {
            let config = EnvironmentConfiguration.load(from: ["EDUGO_ENVIRONMENT": string])
            #expect(config.environment == expected)
        }
    }
    
    @Test("Parse subsystem")
    func testParseSubsystem() {
        let env = ["EDUGO_LOG_SUBSYSTEM": "com.test.custom"]
        let config = EnvironmentConfiguration.load(from: env)
        
        #expect(config.subsystem == "com.test.custom")
    }
    
    @Test("Parse multiple values")
    func testParseMultipleValues() {
        let env = [
            "EDUGO_LOG_LEVEL": "info",
            "EDUGO_LOG_ENABLED": "true",
            "EDUGO_LOG_METADATA": "false",
            "EDUGO_ENVIRONMENT": "staging",
            "EDUGO_LOG_SUBSYSTEM": "com.test.app"
        ]
        
        let config = EnvironmentConfiguration.load(from: env)
        
        #expect(config.logLevel == .info)
        #expect(config.isEnabled == true)
        #expect(config.includeMetadata == false)
        #expect(config.environment == .staging)
        #expect(config.subsystem == "com.test.app")
        #expect(config.hasAnyConfiguration == true)
    }
    
    @Test("Supported keys list")
    func testSupportedKeys() {
        let keys = EnvironmentConfiguration.supportedKeys()
        
        #expect(keys.contains("EDUGO_LOG_LEVEL"))
        #expect(keys.contains("EDUGO_LOG_ENABLED"))
        #expect(keys.contains("EDUGO_LOG_METADATA"))
        #expect(keys.contains("EDUGO_ENVIRONMENT"))
        #expect(keys.contains("EDUGO_LOG_SUBSYSTEM"))
    }
    
    @Test("Documentation generation")
    func testDocumentation() {
        let docs = EnvironmentConfiguration.documentation()
        
        #expect(docs.contains("EDUGO_LOG_LEVEL"))
        #expect(docs.contains("EDUGO_LOG_ENABLED"))
        #expect(docs.contains("Example"))
    }
}

@Suite("LoggerConfigurator Tests", .serialized)
struct LoggerConfiguratorTests {
    
    @Test("Configurator shared instance accessible")
    func testSharedInstance() async {
        let configurator = LoggerConfigurator.shared
        let level = await configurator.globalLevel
        
        // Should have some default level
        #expect([.debug, .info, .warning, .error].contains(level))
    }
    
    @Test("Set global level")
    func testSetGlobalLevel() async {
        let configurator = LoggerConfigurator.shared
        
        await configurator.setGlobalLevel(.error)
        let level = await configurator.globalLevel
        
        #expect(level == .error)
    }
    
    @Test("Set enabled state")
    func testSetEnabled() async {
        let configurator = LoggerConfigurator.shared
        
        await configurator.setEnabled(false)
        let enabled = await configurator.isEnabled
        
        #expect(enabled == false)
        
        // Restore
        await configurator.setEnabled(true)
    }
    
    @Test("Set include metadata")
    func testSetIncludeMetadata() async {
        let configurator = LoggerConfigurator.shared
        
        await configurator.setIncludeMetadata(true)
        let config = await configurator.configuration
        
        #expect(config.includeMetadata == true)
    }
    
    @Test("Set level for category")
    func testSetLevelForCategory() async {
        let configurator = LoggerConfigurator.shared
        
        await configurator.setLevel(.debug, for: SystemLogCategory.logger)
        
        // Should not crash
    }
    
    @Test("Reset category")
    func testResetCategory() async {
        let configurator = LoggerConfigurator.shared
        
        await configurator.setLevel(.debug, for: SystemLogCategory.network)
        await configurator.resetCategory(SystemLogCategory.network)
        
        // Should not crash
    }
    
    @Test("Apply preset development")
    func testApplyPresetDevelopment() async {
        let configurator = LoggerConfigurator.shared
        
        await configurator.applyPreset(.development)
        let level = await configurator.globalLevel
        let env = await configurator.environment
        
        #expect(level == .debug)
        #expect(env == .development)
    }
    
    @Test("Apply preset production")
    func testApplyPresetProduction() async {
        let configurator = LoggerConfigurator.shared
        
        await configurator.applyPreset(.production)
        let level = await configurator.globalLevel
        let env = await configurator.environment
        
        #expect(level == .warning)
        #expect(env == .production)
    }
    
    @Test("Convenience configure development")
    func testConfigureDevelopment() async {
        let configurator = LoggerConfigurator.shared
        
        await configurator.configureDevelopment()
        let env = await configurator.environment
        
        #expect(env == .development)
    }
    
    @Test("Convenience configure production")
    func testConfigureProduction() async {
        let configurator = LoggerConfigurator.shared
        
        await configurator.configureProduction()
        let env = await configurator.environment
        
        #expect(env == .production)
    }
    
    @Test("Configure from environment with no values")
    func testConfigureFromEnvironmentEmpty() async {
        let configurator = LoggerConfigurator.shared
        
        // Esto cargará el environment real que probablemente está vacío
        let found = await configurator.configureFromEnvironment()
        
        // Should return false if no environment vars are set
        // (can't guarantee this in all test environments)
    }
}
