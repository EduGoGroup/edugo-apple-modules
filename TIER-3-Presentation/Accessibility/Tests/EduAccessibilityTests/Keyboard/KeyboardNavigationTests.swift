import Testing
import SwiftUI
@testable import EduAccessibility

// MARK: - FocusManager Tests

@Suite("FocusManager Tests")
struct FocusManagerTests {

    @Test("FocusManager.shared es singleton")
    @MainActor
    func testSharedIsSingleton() {
        let instance1 = FocusManager.shared
        let instance2 = FocusManager.shared
        #expect(instance1 === instance2)
    }

    @Test("setFocus actualiza currentFocusID")
    @MainActor
    func testSetFocusUpdatesCurrentFocusID() {
        let manager = FocusManager.shared
        manager.clearFocus()

        manager.setFocus("test-element-1")
        #expect(manager.currentFocusID as? String == "test-element-1")

        manager.setFocus("test-element-2")
        #expect(manager.currentFocusID as? String == "test-element-2")

        manager.clearFocus()
    }

    @Test("clearFocus limpia currentFocusID")
    @MainActor
    func testClearFocusRemovesCurrentFocusID() {
        let manager = FocusManager.shared
        manager.setFocus("test-element")
        #expect(manager.currentFocusID != nil)

        manager.clearFocus()
        #expect(manager.currentFocusID == nil)
    }

    @Test("FocusContext inicializa correctamente")
    func testFocusContextInitialization() {
        let context = FocusContext(
            name: "test-modal",
            initialFocusID: "first-field",
            restorationFocusID: "trigger-button",
            trapsFocus: true,
            allowedFocusIDs: ["first-field", "second-field", "submit-btn"]
        )

        #expect(context.name == "test-modal")
        #expect(context.initialFocusID == "first-field")
        #expect(context.restorationFocusID == "trigger-button")
        #expect(context.trapsFocus == true)
        #expect(context.allowedFocusIDs?.count == 3)
    }

    @Test("FocusContext.isAllowed verifica IDs permitidos")
    func testFocusContextIsAllowed() {
        let context = FocusContext(
            name: "modal",
            trapsFocus: true,
            allowedFocusIDs: ["btn-1", "btn-2"]
        )

        #expect(context.isAllowed("btn-1") == true)
        #expect(context.isAllowed("btn-2") == true)
        #expect(context.isAllowed("btn-3") == false)
    }

    @Test("FocusContext sin allowedFocusIDs permite todo")
    func testFocusContextWithoutAllowedIDsPermitsAll() {
        let context = FocusContext(name: "open-context")

        #expect(context.isAllowed("any-id") == true)
        #expect(context.isAllowed("another-id") == true)
    }

    @Test("pushFocusContext y popFocusContext funcionan")
    @MainActor
    func testPushPopFocusContext() {
        let manager = FocusManager.shared
        manager.clearHistory()

        let context1 = FocusContext(name: "modal-1", trapsFocus: true)
        let context2 = FocusContext(name: "modal-2", trapsFocus: true)

        manager.pushFocusContext(context1)
        #expect(manager.currentContext?.name == "modal-1")
        #expect(manager.hasActiveContext == true)

        manager.pushFocusContext(context2)
        #expect(manager.currentContext?.name == "modal-2")

        let popped = manager.popFocusContext()
        #expect(popped?.name == "modal-2")
        #expect(manager.currentContext?.name == "modal-1")

        _ = manager.popFocusContext()
        #expect(manager.hasActiveContext == false)
    }
}

// MARK: - TabOrderOptimizer Tests

@Suite("TabOrderOptimizer Tests")
struct TabOrderOptimizerTests {

    @Test("TabOrderOptimizer.shared es singleton")
    @MainActor
    func testSharedIsSingleton() {
        let instance1 = TabOrderOptimizer.shared
        let instance2 = TabOrderOptimizer.shared
        #expect(instance1 === instance2)
    }

    @Test("register agrega elemento con prioridad")
    @MainActor
    func testRegisterElement() {
        let optimizer = TabOrderOptimizer.shared
        optimizer.reset()

        optimizer.register(element: "field-1", priority: 10)
        optimizer.register(element: "field-2", priority: 20)

        let ordered = optimizer.orderedElements()
        #expect(ordered.count >= 2)

        optimizer.reset()
    }

    @Test("orderedElements respeta prioridades")
    @MainActor
    func testOrderedElementsRespectsPriority() {
        let optimizer = TabOrderOptimizer.shared
        optimizer.reset()

        optimizer.register(element: "low-priority", priority: 100)
        optimizer.register(element: "high-priority", priority: 10)
        optimizer.register(element: "medium-priority", priority: 50)

        let ordered = optimizer.orderedElements()

        if let firstIndex = ordered.firstIndex(where: { ($0 as? String) == "high-priority" }),
           let lastIndex = ordered.firstIndex(where: { ($0 as? String) == "low-priority" }) {
            #expect(firstIndex < lastIndex)
        }

        optimizer.reset()
    }

    @Test("skip marca elemento para saltar")
    @MainActor
    func testSkipElement() {
        let optimizer = TabOrderOptimizer.shared
        optimizer.reset()

        optimizer.register(element: "skippable", priority: 10)
        #expect(optimizer.shouldSkip(element: "skippable") == false)

        optimizer.skip(element: "skippable")
        #expect(optimizer.shouldSkip(element: "skippable") == true)

        optimizer.unskip(element: "skippable")
        #expect(optimizer.shouldSkip(element: "skippable") == false)

        optimizer.reset()
    }

    @Test("TabGroup inicializa correctamente")
    func testTabGroupInitialization() {
        let group = TabGroup(
            id: "form-fields",
            name: "Form Fields",
            priority: 20,
            elements: ["email", "password", "submit"]
        )

        #expect(group.id == "form-fields")
        #expect(group.name == "Form Fields")
        #expect(group.priority == 20)
        #expect(group.elements.count == 3)
    }

    @Test("registerGroup y group(for:) funcionan")
    @MainActor
    func testRegisterAndRetrieveGroup() {
        let optimizer = TabOrderOptimizer.shared
        optimizer.reset()

        let group = TabGroup(
            id: "nav-group",
            name: "Navigation",
            priority: 5,
            elements: ["tab-1", "tab-2"]
        )

        optimizer.registerGroup(group)

        let retrieved = optimizer.group(for: "nav-group")
        #expect(retrieved?.name == "Navigation")
        #expect(retrieved?.elements.count == 2)

        optimizer.reset()
    }

    @Test("FormTabOrderHelper.setupFormTabOrder genera prioridades")
    func testFormTabOrderHelper() {
        let priorities = FormTabOrderHelper.setupFormTabOrder(fields: ["email", "password", "submit"])

        #expect(priorities["email"] != nil)
        #expect(priorities["password"] != nil)
        #expect(priorities["submit"] != nil)
    }

    @Test("CommonFieldPriority tiene valores esperados")
    func testCommonFieldPriority() {
        #expect(FormTabOrderHelper.CommonFieldPriority.email == 1)
        #expect(FormTabOrderHelper.CommonFieldPriority.password == 2)
        #expect(FormTabOrderHelper.CommonFieldPriority.submitButton == 99)
        #expect(FormTabOrderHelper.CommonFieldPriority.cancelButton == 100)
    }
}

// MARK: - EscapeHatchManager Tests

@Suite("EscapeHatchManager Tests")
struct EscapeHatchManagerTests {

    @Test("EscapeHatchManager.shared es singleton")
    @MainActor
    func testSharedIsSingleton() {
        let instance1 = EscapeHatchManager.shared
        let instance2 = EscapeHatchManager.shared
        #expect(instance1 === instance2)
    }

    @Test("register agrega handler")
    @MainActor
    func testRegisterHandler() {
        let manager = EscapeHatchManager.shared
        manager.clear()

        let handler = EscapeHatchHandler(
            id: "test-handler",
            behavior: .dismissModal,
            action: { }
        )

        manager.register(handler)
        #expect(manager.hasActiveHandlers == true)

        manager.clear()
        #expect(manager.hasActiveHandlers == false)
    }

    @Test("handleEscape retorna true cuando hay handler")
    @MainActor
    func testHandleEscapeReturnsTrue() {
        let manager = EscapeHatchManager.shared
        manager.clear()

        let handler = EscapeHatchHandler(
            id: "test",
            behavior: .dismissModal,
            action: { }
        )

        manager.register(handler)
        let handled = manager.handleEscape()
        #expect(handled == true)

        manager.clear()
    }

    @Test("handleEscape retorna false cuando no hay handler")
    @MainActor
    func testHandleEscapeReturnsFalse() {
        let manager = EscapeHatchManager.shared
        manager.clear()

        let handled = manager.handleEscape()
        #expect(handled == false)
    }

    @Test("EscapeHatchBehavior tiene descriptions correctas")
    func testEscapeHatchBehaviorDescriptions() {
        #expect(EscapeHatchBehavior.dismissModal.description == "Dismiss modal")
        #expect(EscapeHatchBehavior.cancelEditing.description == "Cancel editing")
        #expect(EscapeHatchBehavior.clearSearch.description == "Clear search")
        #expect(EscapeHatchBehavior.navigateBack.description == "Navigate back")
    }

    @Test("EscapeHatchHandler con shouldHandle false no se ejecuta")
    @MainActor
    func testHandlerWithShouldHandleFalse() {
        let manager = EscapeHatchManager.shared
        manager.clear()

        let handler = EscapeHatchHandler(
            id: "disabled-handler",
            behavior: .dismissModal,
            shouldHandle: { false },
            action: { }
        )

        manager.register(handler)
        let handled = manager.handleEscape()

        #expect(handled == false)

        manager.clear()
    }
}

// MARK: - KeyboardShortcutRegistry Tests

@Suite("KeyboardShortcutRegistry Tests")
struct KeyboardShortcutRegistryTests {

    @Test("KeyboardShortcutRegistry.shared es singleton")
    @MainActor
    func testSharedIsSingleton() {
        let instance1 = KeyboardShortcutRegistry.shared
        let instance2 = KeyboardShortcutRegistry.shared
        #expect(instance1 === instance2)
    }

    @Test("allShortcuts contiene shortcuts predefinidos")
    @MainActor
    func testAllShortcutsContainsPredefined() {
        let registry = KeyboardShortcutRegistry.shared
        let all = registry.allShortcuts

        // Verificar que hay shortcuts registrados
        #expect(all.count > 0)
    }

    @Test("shortcut(for:) recupera shortcut por ID")
    @MainActor
    func testShortcutForID() {
        let registry = KeyboardShortcutRegistry.shared

        // Los shortcuts predefinidos deberían existir
        let navBack = registry.shortcut(for: "nav.back")
        #expect(navBack?.category == .navigation)
    }

    @Test("shortcuts(in:) filtra por categoría")
    @MainActor
    func testShortcutsInCategory() {
        let registry = KeyboardShortcutRegistry.shared

        let navShortcuts = registry.shortcuts(in: .navigation)
        for shortcut in navShortcuts {
            #expect(shortcut.category == .navigation)
        }
    }

    @Test("disable y enable funcionan")
    @MainActor
    func testDisableAndEnable() {
        let registry = KeyboardShortcutRegistry.shared

        // Asumiendo que "nav.back" existe
        registry.enable("nav.back")
        #expect(registry.isEnabled("nav.back") == true)

        registry.disable("nav.back")
        #expect(registry.isEnabled("nav.back") == false)

        registry.enable("nav.back")
        #expect(registry.isEnabled("nav.back") == true)
    }

    @Test("KeyboardShortcutDefinition inicializa correctamente")
    func testShortcutDefinitionInit() {
        let shortcut = KeyboardShortcutDefinition(
            id: "test",
            key: KeyEquivalent("s"),
            modifiers: [.command],
            platforms: [.macOS],
            category: .general,
            description: "Test shortcut"
        )

        #expect(shortcut.id == "test")
        #expect(shortcut.category == .general)
        #expect(shortcut.description == "Test shortcut")
        #expect(shortcut.platforms.contains(.macOS))
    }

    @Test("ShortcutCategory displayNames son correctos")
    func testShortcutCategoryDisplayNames() {
        #expect(ShortcutCategory.navigation.displayName == "Navigation")
        #expect(ShortcutCategory.editing.displayName == "Editing")
        #expect(ShortcutCategory.general.displayName == "General")
        #expect(ShortcutCategory.custom.displayName == "Custom")
    }

    @Test("Platform enum tiene valores correctos")
    func testPlatformEnum() {
        #expect(Platform.macOS.rawValue == "macOS")
        #expect(Platform.iOS.rawValue == "iOS")
        #expect(Platform.visionOS.rawValue == "visionOS")
    }
}
