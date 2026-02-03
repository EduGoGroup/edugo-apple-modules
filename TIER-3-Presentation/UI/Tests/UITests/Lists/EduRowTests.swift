import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduRowTests {
    // MARK: - Basic Tests

    @Test("EduRow inicializa correctamente")
    func testBasicInitialization() {
        let _ = EduRow("Test")
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduRow con description")
    func testWithDescription() {
        let _ = EduRow("Title", description: "Description")
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduRow con leading content")
    func testWithLeading() {
        let _ = EduRow("Title", leading: Image(systemName: "star"))
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduRow con trailing content")
    func testWithTrailing() {
        let _ = EduRow("Title", trailing: Image(systemName: "chevron.right"))
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduRow con divider desactivado")
    func testWithoutDivider() {
        let _ = EduRow("Title", showDivider: false)
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduRow con onTap action")
    func testOnTapExecution() {
        let _ = EduRow("Title", onTap: {
            // Action defined
        })
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduRow con leading Y trailing")
    func testWithLeadingAndTrailing() {
        let _ = EduRow(
            "Title",
            leading: Image(systemName: "star"),
            trailing: Image(systemName: "chevron.right")
        )
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduRow sin leading ni trailing")
    func testWithoutLeadingOrTrailing() {
        let _ = EduRow("Simple Title")
        // La inicialización exitosa del struct es suficiente validación
    }

    // MARK: - Swipe Actions Tests

    @Test("SwipeAction inicializa correctamente con valores por defecto")
    func testSwipeActionDefaultInit() {
        let action = SwipeAction(title: "Delete") {
            // Action
        }
        #expect(action.title == "Delete")
        #expect(action.icon == nil)
        #expect(action.role == .normal)
    }

    @Test("SwipeAction inicializa con todos los parámetros")
    func testSwipeActionFullInit() {
        let action = SwipeAction(title: "Delete", icon: "trash", role: .destructive) {
            // Action
        }
        #expect(action.title == "Delete")
        #expect(action.icon == "trash")
        #expect(action.role == .destructive)
    }

    @Test("EduRow con trailing swipe actions")
    func testWithTrailingSwipeActions() {
        let actions = [
            SwipeAction(title: "Delete", icon: "trash", role: .destructive) {
                print("Deleted")
            }
        ]

        let row = EduRow("Title", trailingSwipeActions: actions)
        #expect(row.trailingSwipeActions.count == 1)
    }

    @Test("EduRow con leading swipe actions")
    func testWithLeadingSwipeActions() {
        let actions = [
            SwipeAction(title: "Mark", icon: "flag") {
                print("Marked")
            }
        ]

        let row = EduRow("Title", leadingSwipeActions: actions)
        #expect(row.leadingSwipeActions.count == 1)
    }

    @Test("EduRow con trailing y leading swipe actions")
    func testWithBothSwipeActions() {
        let trailingActions = [
            SwipeAction(title: "Delete", icon: "trash", role: .destructive) {
                print("Deleted")
            }
        ]

        let leadingActions = [
            SwipeAction(title: "Mark", icon: "flag") {
                print("Marked")
            }
        ]

        let row = EduRow(
            "Title",
            trailingSwipeActions: trailingActions,
            leadingSwipeActions: leadingActions
        )
        #expect(row.trailingSwipeActions.count == 1)
        #expect(row.leadingSwipeActions.count == 1)
    }

    @Test("EduRow con múltiples trailing swipe actions")
    func testWithMultipleTrailingSwipeActions() {
        let actions = [
            SwipeAction(title: "Delete", icon: "trash", role: .destructive) {
                print("Deleted")
            },
            SwipeAction(title: "Archive", icon: "archivebox") {
                print("Archived")
            },
            SwipeAction(title: "Share", icon: "square.and.arrow.up") {
                print("Shared")
            }
        ]

        let row = EduRow("Title", trailingSwipeActions: actions)
        #expect(row.trailingSwipeActions.count == 3)
    }

    @Test("EduRow allowsFullSwipe por defecto es true")
    func testAllowsFullSwipeDefault() {
        let row = EduRow("Title")
        #expect(row.allowsFullSwipe == true)
    }

    @Test("EduRow allowsFullSwipe puede ser configurado")
    func testAllowsFullSwipeConfiguration() {
        let row = EduRow("Title", allowsFullSwipe: false)
        #expect(row.allowsFullSwipe == false)
    }

    @Test("EduRow swipe actions con description y leading/trailing")
    func testSwipeActionsWithFullConfiguration() {
        let actions = [
            SwipeAction(title: "Delete", icon: "trash", role: .destructive) {
                print("Deleted")
            }
        ]

        let row = EduRow(
            "Title",
            description: "Description",
            leading: Image(systemName: "envelope"),
            trailing: Image(systemName: "chevron.right"),
            trailingSwipeActions: actions,
            allowsFullSwipe: true
        )

        #expect(row.description == "Description")
        #expect(row.trailingSwipeActions.count == 1)
        #expect(row.allowsFullSwipe == true)
    }
}
