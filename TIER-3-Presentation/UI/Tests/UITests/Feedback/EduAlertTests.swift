import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduAlertTests {
    // MARK: - AlertManager Tests

    @Test("EduAlertManager es singleton")
    func testSingleton() {
        let manager1 = EduAlertManager.shared
        let manager2 = EduAlertManager.shared
        #expect(manager1 === manager2)
    }

    @Test("EduAlertManager muestra alert")
    func testShowAlert() {
        let manager = EduAlertManager.shared
        let alert = EduAlertContent(
            title: "Test",
            message: "Test message",
            actions: []
        )

        manager.show(alert: alert)

        #expect(manager.isPresented == true)
        #expect(manager.currentAlert?.title == "Test")
    }

    @Test("EduAlertManager dismiss alert")
    func testDismissAlert() {
        let manager = EduAlertManager.shared
        let alert = EduAlertContent(
            title: "Test",
            actions: []
        )

        manager.show(alert: alert)
        manager.dismiss()

        #expect(manager.isPresented == false)
        #expect(manager.currentAlert == nil)
    }

    @Test("EduAlertManager showConfirmation")
    func testShowConfirmation() {
        let manager = EduAlertManager.shared

        manager.showConfirmation(
            title: "Confirmar",
            message: "¿Estás seguro?",
            onConfirm: {}
        )

        #expect(manager.isPresented == true)
        #expect(manager.currentAlert?.title == "Confirmar")
        #expect(manager.currentAlert?.message == "¿Estás seguro?")
        #expect(manager.currentAlert?.actions.count == 2)
    }

    @Test("EduAlertManager showDestructive")
    func testShowDestructive() {
        let manager = EduAlertManager.shared

        manager.showDestructive(
            title: "Eliminar",
            message: "Esta acción no se puede deshacer",
            onDestroy: {}
        )

        #expect(manager.isPresented == true)
        #expect(manager.currentAlert?.title == "Eliminar")
        #expect(manager.currentAlert?.actions.count == 2)
    }

    // MARK: - AlertAction Tests

    @Test("EduAlertAction inicializa correctamente")
    func testAlertAction() {
        let action = EduAlertAction(
            title: "OK",
            role: .cancel,
            action: {}
        )

        #expect(action.title == "OK")
        #expect(action.role == .cancel)
    }

    @Test("EduAlertAction sin role")
    func testAlertActionNoRole() {
        let action = EduAlertAction(
            title: "Continue",
            action: {}
        )

        #expect(action.title == "Continue")
        #expect(action.role == nil)
    }

    // MARK: - AlertContent Tests

    @Test("EduAlertContent inicializa con título solamente")
    func testAlertContentTitleOnly() {
        let content = EduAlertContent(
            title: "Alert",
            actions: []
        )

        #expect(content.title == "Alert")
        #expect(content.message == nil)
        #expect(content.actions.isEmpty)
    }

    @Test("EduAlertContent inicializa completo")
    func testAlertContentFull() {
        let action = EduAlertAction(title: "OK", action: {})
        let content = EduAlertContent(
            title: "Alert",
            message: "Message",
            actions: [action]
        )

        #expect(content.title == "Alert")
        #expect(content.message == "Message")
        #expect(content.actions.count == 1)
    }

    @Test("EduAlertContent con múltiples acciones")
    func testAlertContentMultipleActions() {
        let actions = [
            EduAlertAction(title: "Cancelar", role: .cancel, action: {}),
            EduAlertAction(title: "Aceptar", action: {}),
            EduAlertAction(title: "Eliminar", role: .destructive, action: {})
        ]
        let content = EduAlertContent(
            title: "Múltiples opciones",
            actions: actions
        )

        #expect(content.actions.count == 3)
    }
}
