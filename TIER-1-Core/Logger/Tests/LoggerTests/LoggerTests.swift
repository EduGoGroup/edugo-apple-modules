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
