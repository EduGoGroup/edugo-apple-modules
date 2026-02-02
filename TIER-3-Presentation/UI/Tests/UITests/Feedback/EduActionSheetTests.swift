import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduActionSheetTests {
    // MARK: - ActionSheetManager Tests

    @Test("EduActionSheetManager es singleton")
    func testSingleton() {
        let manager1 = EduActionSheetManager.shared
        let manager2 = EduActionSheetManager.shared
        #expect(manager1 === manager2)
    }

    @Test("EduActionSheetManager muestra action sheet")
    func testShowActionSheet() {
        let manager = EduActionSheetManager.shared
        let actionSheet = EduActionSheetContent(
            title: "Options",
            message: "Choose one",
            actions: []
        )

        manager.show(actionSheet: actionSheet)

        #expect(manager.isPresented == true)
        #expect(manager.currentActionSheet?.title == "Options")
    }

    @Test("EduActionSheetManager dismiss")
    func testDismissActionSheet() {
        let manager = EduActionSheetManager.shared
        let actionSheet = EduActionSheetContent(
            title: "Test",
            actions: []
        )

        manager.show(actionSheet: actionSheet)
        manager.dismiss()

        #expect(manager.isPresented == false)
        #expect(manager.currentActionSheet == nil)
    }

    @Test("EduActionSheetManager showOptions")
    func testShowOptions() {
        let manager = EduActionSheetManager.shared

        manager.showOptions(
            title: "Actions",
            message: "Select an action",
            options: [
                (title: "Option 1", icon: "star", action: {}),
                (title: "Option 2", icon: "heart", action: {})
            ]
        )

        #expect(manager.isPresented == true)
        #expect(manager.currentActionSheet?.actions.count == 3) // 2 options + Cancel
    }

    @Test("EduActionSheetManager showOptions sin cancel")
    func testShowOptionsNoCancel() {
        let manager = EduActionSheetManager.shared

        manager.showOptions(
            title: "Actions",
            options: [
                (title: "Option 1", icon: nil, action: {})
            ],
            includeCancel: false
        )

        #expect(manager.isPresented == true)
        #expect(manager.currentActionSheet?.actions.count == 1)
    }

    // MARK: - ActionSheetAction Tests

    @Test("EduActionSheetAction inicializa correctamente")
    func testActionSheetAction() {
        let action = EduActionSheetAction(
            title: "Delete",
            icon: "trash",
            role: .destructive,
            action: {}
        )

        #expect(action.title == "Delete")
        #expect(action.icon == "trash")
        #expect(action.role == .destructive)
    }

    @Test("EduActionSheetAction sin icon")
    func testActionSheetActionNoIcon() {
        let action = EduActionSheetAction(
            title: "Action",
            action: {}
        )

        #expect(action.title == "Action")
        #expect(action.icon == nil)
        #expect(action.role == nil)
    }

    @Test("EduActionSheetAction con role cancel")
    func testActionSheetActionCancel() {
        let action = EduActionSheetAction(
            title: "Cancelar",
            role: .cancel,
            action: {}
        )

        #expect(action.role == .cancel)
    }

    @Test("EduActionSheetAction tiene ID único")
    func testActionSheetActionUniqueID() {
        let action1 = EduActionSheetAction(title: "Action 1", action: {})
        let action2 = EduActionSheetAction(title: "Action 2", action: {})

        #expect(action1.id != action2.id)
    }

    // MARK: - ActionSheetContent Tests

    @Test("EduActionSheetContent inicializa con mínimo")
    func testActionSheetContentMinimal() {
        let content = EduActionSheetContent(actions: [])

        #expect(content.title == nil)
        #expect(content.message == nil)
        #expect(content.actions.isEmpty)
    }

    @Test("EduActionSheetContent con título y mensaje")
    func testActionSheetContentFull() {
        let action = EduActionSheetAction(title: "OK", action: {})
        let content = EduActionSheetContent(
            title: "Confirm",
            message: "Are you sure?",
            actions: [action]
        )

        #expect(content.title == "Confirm")
        #expect(content.message == "Are you sure?")
        #expect(content.actions.count == 1)
    }

    @Test("EduActionSheetContent con múltiples acciones")
    func testActionSheetContentMultipleActions() {
        let actions = [
            EduActionSheetAction(title: "Action 1", icon: "star", action: {}),
            EduActionSheetAction(title: "Action 2", icon: "heart", action: {}),
            EduActionSheetAction(title: "Cancel", role: .cancel, action: {})
        ]
        let content = EduActionSheetContent(
            title: "Options",
            actions: actions
        )

        #expect(content.actions.count == 3)
    }

    @Test("EduActionSheetContent solo con título")
    func testActionSheetContentTitleOnly() {
        let content = EduActionSheetContent(
            title: "Select",
            actions: []
        )

        #expect(content.title == "Select")
        #expect(content.message == nil)
    }

    @Test("EduActionSheetContent solo con mensaje")
    func testActionSheetContentMessageOnly() {
        let content = EduActionSheetContent(
            message: "Choose wisely",
            actions: []
        )

        #expect(content.title == nil)
        #expect(content.message == "Choose wisely")
    }
}
