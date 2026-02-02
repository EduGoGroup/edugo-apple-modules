import XCTest
import SwiftUI
import ViewInspector
@testable import UI

@MainActor
final class EduFeedbackTests: XCTestCase {

    // MARK: - Toast Tests

    func testToastManagerShowsToast() {
        let manager = ToastManager.shared

        manager.show(message: "Test", type: .info)

        XCTAssertEqual(manager.toasts.count, 1)
        XCTAssertEqual(manager.toasts.first?.message, "Test")
        XCTAssertEqual(manager.toasts.first?.type, .info)
    }

    func testToastManagerDismissesToast() {
        let manager = ToastManager.shared

        manager.show(message: "Test", type: .info)
        let toastId = manager.toasts.first?.id

        XCTAssertNotNil(toastId)

        if let id = toastId {
            manager.dismiss(id: id)
            XCTAssertTrue(manager.toasts.isEmpty)
        }
    }

    func testToastHasCorrectType() {
        let successToast = ToastItem(message: "Success", type: .success)
        let errorToast = ToastItem(message: "Error", type: .error)
        let warningToast = ToastItem(message: "Warning", type: .warning)
        let infoToast = ToastItem(message: "Info", type: .info)

        XCTAssertEqual(successToast.type, .success)
        XCTAssertEqual(errorToast.type, .error)
        XCTAssertEqual(warningToast.type, .warning)
        XCTAssertEqual(infoToast.type, .info)
    }

    // MARK: - Banner Tests

    func testBannerInitialization() {
        let banner = EduBanner(
            message: "Test Banner",
            type: .info,
            isDismissible: true,
            onDismiss: {}
        )

        // El banner se crea correctamente
        XCTAssertNotNil(banner)
    }

    // MARK: - Alert Tests

    func testAlertManagerShowsAlert() {
        let manager = EduAlertManager.shared

        let alert = EduAlertContent(
            title: "Test Alert",
            message: "Test Message",
            actions: [
                EduAlertAction(title: "OK", action: {})
            ]
        )

        manager.show(alert: alert)

        XCTAssertTrue(manager.isPresented)
        XCTAssertEqual(manager.currentAlert?.title, "Test Alert")
        XCTAssertEqual(manager.currentAlert?.message, "Test Message")
    }

    func testAlertManagerDismissesAlert() {
        let manager = EduAlertManager.shared

        let alert = EduAlertContent(
            title: "Test",
            actions: [EduAlertAction(title: "OK", action: {})]
        )

        manager.show(alert: alert)
        manager.dismiss()

        XCTAssertFalse(manager.isPresented)
        XCTAssertNil(manager.currentAlert)
    }

    func testAlertManagerShowsConfirmation() {
        let manager = EduAlertManager.shared
        var confirmed = false

        manager.showConfirmation(
            title: "Confirm",
            message: "Are you sure?",
            onConfirm: { confirmed = true }
        )

        XCTAssertTrue(manager.isPresented)
        XCTAssertEqual(manager.currentAlert?.title, "Confirm")
        XCTAssertEqual(manager.currentAlert?.actions.count, 2)
    }

    func testAlertManagerShowsDestructive() {
        let manager = EduAlertManager.shared
        var destroyed = false

        manager.showDestructive(
            title: "Delete",
            message: "This cannot be undone",
            onDestroy: { destroyed = true }
        )

        XCTAssertTrue(manager.isPresented)
        XCTAssertEqual(manager.currentAlert?.actions.count, 2)
        XCTAssertEqual(manager.currentAlert?.actions.last?.role, .destructive)
    }

    // MARK: - Modal Tests

    func testModalManagerShowsModal() {
        let manager = EduModalManager.shared

        manager.show {
            Text("Test Modal")
        }

        XCTAssertTrue(manager.isPresented)
        XCTAssertNotNil(manager.modalView)
    }

    func testModalManagerDismissesModal() async {
        let manager = EduModalManager.shared

        manager.show {
            Text("Test")
        }

        manager.dismiss()

        // Dar tiempo para la animación
        try? await Task.sleep(for: .milliseconds(400))

        XCTAssertFalse(manager.isPresented)
    }

    func testModalSizeCalculation() {
        XCTAssertEqual(EduModalSize.small.height, 300)
        XCTAssertEqual(EduModalSize.medium.height, 500)
        XCTAssertEqual(EduModalSize.large.height, 700)
        XCTAssertNil(EduModalSize.fullScreen.height)
        XCTAssertEqual(EduModalSize.custom(400).height, 400)
    }

    // MARK: - Action Sheet Tests

    func testActionSheetManagerShowsActionSheet() {
        let manager = EduActionSheetManager.shared

        let actionSheet = EduActionSheetContent(
            title: "Options",
            message: "Choose an option",
            actions: [
                EduActionSheetAction(title: "Option 1", action: {}),
                EduActionSheetAction(title: "Option 2", action: {})
            ]
        )

        manager.show(actionSheet: actionSheet)

        XCTAssertTrue(manager.isPresented)
        XCTAssertEqual(manager.currentActionSheet?.title, "Options")
        XCTAssertEqual(manager.currentActionSheet?.actions.count, 2)
    }

    func testActionSheetManagerShowsOptions() {
        let manager = EduActionSheetManager.shared
        var option1Selected = false
        var option2Selected = false

        manager.showOptions(
            title: "Select",
            options: [
                ("Option 1", "star", { option1Selected = true }),
                ("Option 2", "heart", { option2Selected = true })
            ],
            includeCancel: true
        )

        XCTAssertTrue(manager.isPresented)
        XCTAssertEqual(manager.currentActionSheet?.actions.count, 3) // 2 options + cancel
    }

    func testActionSheetManagerDismisses() {
        let manager = EduActionSheetManager.shared

        let actionSheet = EduActionSheetContent(
            title: "Test",
            actions: [EduActionSheetAction(title: "OK", action: {})]
        )

        manager.show(actionSheet: actionSheet)
        manager.dismiss()

        XCTAssertFalse(manager.isPresented)
        XCTAssertNil(manager.currentActionSheet)
    }

    func testActionSheetActionWithIcon() {
        let action = EduActionSheetAction(
            title: "Delete",
            icon: "trash",
            role: .destructive,
            action: {}
        )

        XCTAssertEqual(action.title, "Delete")
        XCTAssertEqual(action.icon, "trash")
        XCTAssertEqual(action.role, .destructive)
    }
}
