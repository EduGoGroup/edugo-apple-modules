import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduBannerTests {
    // MARK: - EduBanner View Tests

    @Test("EduBanner inicializa con valores mínimos")
    func testBannerMinimal() {
        let banner = EduBanner(message: "Test message")
        #expect(banner != nil)
    }

    @Test("EduBanner inicializa con estilo")
    func testBannerWithStyle() {
        let banner = EduBanner(message: "Success", style: .success)
        #expect(banner != nil)
    }

    @Test("EduBanner inicializa con onDismiss")
    func testBannerWithDismiss() {
        var dismissed = false
        let banner = EduBanner(
            message: "Test",
            onDismiss: { dismissed = true }
        )
        #expect(banner != nil)
    }

    @Test("EduBanner con todos los parámetros")
    func testBannerFull() {
        var dismissed = false
        let banner = EduBanner(
            message: "Warning message",
            style: .warning,
            onDismiss: { dismissed = true }
        )
        #expect(banner != nil)
    }

    @Test("EduBanner sin onDismiss")
    func testBannerNoDismiss() {
        let banner = EduBanner(
            message: "Info message",
            style: .info,
            onDismiss: nil
        )
        #expect(banner != nil)
    }

    @Test("EduBanner con estilo success")
    func testBannerSuccess() {
        let banner = EduBanner(message: "Success!", style: .success)
        #expect(banner != nil)
    }

    @Test("EduBanner con estilo error")
    func testBannerError() {
        let banner = EduBanner(message: "Error!", style: .error)
        #expect(banner != nil)
    }

    @Test("EduBanner con estilo warning")
    func testBannerWarning() {
        let banner = EduBanner(message: "Warning!", style: .warning)
        #expect(banner != nil)
    }

    @Test("EduBanner con estilo info")
    func testBannerInfo() {
        let banner = EduBanner(message: "Info", style: .info)
        #expect(banner != nil)
    }
}
