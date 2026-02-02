import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduOverlayManagerTests {
    // MARK: - Unified Manager Tests

    @Test("EduOverlayManager es singleton")
    func testSingleton() {
        let manager1 = EduOverlayManager.shared
        let manager2 = EduOverlayManager.shared
        #expect(manager1 === manager2)
    }

    @Test("EduOverlayManager tiene acceso a ToastManager")
    func testHasToastManager() {
        let manager = EduOverlayManager.shared
        #expect(manager.toastManager === ToastManager.shared)
    }

    @Test("EduOverlayManager tiene acceso a AlertManager")
    func testHasAlertManager() {
        let manager = EduOverlayManager.shared
        #expect(manager.alertManager === EduAlertManager.shared)
    }

    @Test("EduOverlayManager tiene acceso a ModalManager")
    func testHasModalManager() {
        let manager = EduOverlayManager.shared
        #expect(manager.modalManager === EduModalManager.shared)
    }

    @Test("EduOverlayManager tiene acceso a ActionSheetManager")
    func testHasActionSheetManager() {
        let manager = EduOverlayManager.shared
        #expect(manager.actionSheetManager === EduActionSheetManager.shared)
    }

    // MARK: - Banner Management Tests

    @Test("EduOverlayManager muestra banner")
    func testShowBanner() {
        let manager = EduOverlayManager.shared

        manager.showBanner("Test banner", style: .info)

        #expect(manager.currentBanner != nil)
        #expect(manager.currentBanner?.message == "Test banner")
        #expect(manager.currentBanner?.style == .info)
    }

    @Test("EduOverlayManager dismiss banner")
    func testDismissBanner() {
        let manager = EduOverlayManager.shared

        manager.showBanner("Test", style: .info)
        manager.dismissBanner()

        #expect(manager.currentBanner == nil)
    }

    @Test("EduOverlayManager banner con onDismiss")
    func testBannerWithDismiss() {
        let manager = EduOverlayManager.shared

        manager.showBanner("Test", style: .success, onDismiss: {})

        #expect(manager.currentBanner != nil)
    }

    // MARK: - Convenience Methods Tests

    @Test("EduOverlayManager toast() method")
    func testToastMethod() {
        let manager = EduOverlayManager.shared

        manager.toast("Quick toast", style: .success)

        #expect(manager.toastManager.toasts.count > 0)
    }

    @Test("EduOverlayManager confirm() method")
    func testConfirmMethod() {
        let manager = EduOverlayManager.shared

        manager.confirm(
            title: "Confirm",
            message: "Sure?",
            onConfirm: {}
        )

        #expect(manager.alertManager.isPresented == true)
    }

    @Test("EduOverlayManager confirmDestruct() method")
    func testConfirmDestructMethod() {
        let manager = EduOverlayManager.shared

        manager.confirmDestruct(
            title: "Delete",
            onDestroy: {}
        )

        #expect(manager.alertManager.isPresented == true)
    }

    @Test("EduOverlayManager showModal() method")
    func testShowModalMethod() {
        let manager = EduOverlayManager.shared

        manager.showModal {
            Text("Modal")
        }

        #expect(manager.modalManager.isPresented == true)
    }

    @Test("EduOverlayManager showOptions() method")
    func testShowOptionsMethod() {
        let manager = EduOverlayManager.shared

        manager.showOptions(
            title: "Options",
            options: [
                (title: "Option 1", icon: "star", action: {})
            ]
        )

        #expect(manager.actionSheetManager.isPresented == true)
    }

    // MARK: - DismissAll Tests

    @Test("EduOverlayManager dismissAll limpia banner y managers")
    func testDismissAll() {
        let manager = EduOverlayManager.shared

        // Setup: Mostrar varios overlays
        manager.toast("Toast")
        manager.showBanner("Banner")
        manager.confirm(title: "Alert", onConfirm: {})
        manager.showModal { Text("Modal") }
        manager.showOptions(title: "Options", options: [])

        // Execute
        manager.dismissAll()

        // Verify
        #expect(manager.currentBanner == nil)
        #expect(manager.alertManager.isPresented == false)
        #expect(manager.modalManager.isPresented == false)
        #expect(manager.actionSheetManager.isPresented == false)
    }

    // MARK: - BannerItem Tests

    @Test("BannerItem inicializa correctamente")
    func testBannerItem() {
        let item = BannerItem(
            message: "Test",
            style: .warning,
            onDismiss: {}
        )

        #expect(item.message == "Test")
        #expect(item.style == .warning)
    }

    @Test("BannerItem tiene ID único")
    func testBannerItemUniqueID() {
        let item1 = BannerItem(message: "1", style: .info, onDismiss: nil)
        let item2 = BannerItem(message: "2", style: .info, onDismiss: nil)

        #expect(item1.id != item2.id)
    }

    @Test("BannerItem sin onDismiss")
    func testBannerItemNoDismiss() {
        let item = BannerItem(message: "Test", style: .error, onDismiss: nil)

        #expect(item.message == "Test")
        #expect(item.onDismiss == nil)
    }
}
