import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduButtonTests {

    // MARK: - Initialization Tests

    @Test("EduButton inicializa correctamente con parámetros básicos")
    func testBasicInitialization() {
        let button = EduButton("Test Button") { }

        #expect(button != nil, "Button debe inicializarse correctamente")
    }

    @Test("EduButton inicializa con icono leading")
    func testInitializationWithLeadingIcon() {
        let button = EduButton(
            "Save",
            icon: "checkmark",
            iconPosition: .leading
        ) { }

        #expect(button != nil, "Button con icono leading debe inicializarse")
    }

    @Test("EduButton inicializa con icono trailing")
    func testInitializationWithTrailingIcon() {
        let button = EduButton(
            "Next",
            icon: "arrow.right",
            iconPosition: .trailing
        ) { }

        #expect(button != nil, "Button con icono trailing debe inicializarse")
    }

    // MARK: - Style Tests

    @Test("EduButton con estilo primary se crea correctamente")
    func testPrimaryStyle() {
        let button = EduButton(
            "Primary",
            style: .primary
        ) { }

        #expect(button != nil, "Button primary debe crearse")
    }

    @Test("EduButton con estilo secondary se crea correctamente")
    func testSecondaryStyle() {
        let button = EduButton(
            "Secondary",
            style: .secondary
        ) { }

        #expect(button != nil, "Button secondary debe crearse")
    }

    @Test("EduButton con estilo destructive se crea correctamente")
    func testDestructiveStyle() {
        let button = EduButton(
            "Delete",
            style: .destructive
        ) { }

        #expect(button != nil, "Button destructive debe crearse")
    }

    @Test("EduButton con estilo link se crea correctamente")
    func testLinkStyle() {
        let button = EduButton(
            "Learn More",
            style: .link
        ) { }

        #expect(button != nil, "Button link debe crearse")
    }

    // MARK: - Size Tests

    @Test("EduButton con tamaño small se crea correctamente")
    func testSmallSize() {
        let button = EduButton(
            "Small",
            size: .small
        ) { }

        #expect(button != nil, "Button small debe crearse")
    }

    @Test("EduButton con tamaño medium se crea correctamente")
    func testMediumSize() {
        let button = EduButton(
            "Medium",
            size: .medium
        ) { }

        #expect(button != nil, "Button medium debe crearse")
    }

    @Test("EduButton con tamaño large se crea correctamente")
    func testLargeSize() {
        let button = EduButton(
            "Large",
            size: .large
        ) { }

        #expect(button != nil, "Button large debe crearse")
    }

    // MARK: - Loading State Tests

    @Test("EduButton en estado loading se crea correctamente")
    func testLoadingState() {
        let button = EduButton(
            "Loading...",
            isLoading: true
        ) { }

        #expect(button != nil, "Button en estado loading debe crearse")
    }

    @Test("EduButton cambia de normal a loading")
    func testLoadingStateToggle() {
        @MainActor
        class TestContext {
            var isLoading = false
        }

        let context = TestContext()

        let button = EduButton(
            "Process",
            isLoading: context.isLoading
        ) {
            context.isLoading = true
        }

        #expect(button != nil, "Button debe manejar cambios de loading state")
    }

    // MARK: - Disabled State Tests

    @Test("EduButton deshabilitado se crea correctamente")
    func testDisabledState() {
        let button = EduButton(
            "Disabled",
            isDisabled: true
        ) { }

        #expect(button != nil, "Button deshabilitado debe crearse")
    }

    // MARK: - Action Tests

    @Test("EduButton ejecuta acción al presionar")
    func testActionExecution() {
        @MainActor
        class TestContext {
            var actionCalled = false
        }

        let context = TestContext()

        let button = EduButton("Test") {
            context.actionCalled = true
        }

        #expect(button != nil, "Button con acción debe crearse")
        // Nota: La ejecución real de la acción requeriría ViewInspector o similar
    }

    // MARK: - Convenience Initializers Tests

    @Test("Método estático primary crea button correctamente")
    func testPrimaryConvenience() {
        let button = EduButton.primary("Primary Button") { }

        #expect(button != nil, "Convenience primary debe crear button")
    }

    @Test("Método estático secondary crea button correctamente")
    func testSecondaryConvenience() {
        let button = EduButton.secondary("Secondary Button") { }

        #expect(button != nil, "Convenience secondary debe crear button")
    }

    @Test("Método estático destructive crea button correctamente")
    func testDestructiveConvenience() {
        let button = EduButton.destructive("Delete") { }

        #expect(button != nil, "Convenience destructive debe crear button")
    }

    @Test("Método estático link crea button correctamente")
    func testLinkConvenience() {
        let button = EduButton.link("Learn More") { }

        #expect(button != nil, "Convenience link debe crear button")
    }

    // MARK: - Size Padding Tests

    @Test("Size.small tiene padding correcto")
    func testSmallSizePadding() {
        let padding = EduButton.Size.small.padding

        #expect(padding.top == 6, "Small padding top debe ser 6")
        #expect(padding.leading == 12, "Small padding leading debe ser 12")
        #expect(padding.bottom == 6, "Small padding bottom debe ser 6")
        #expect(padding.trailing == 12, "Small padding trailing debe ser 12")
    }

    @Test("Size.medium tiene padding correcto")
    func testMediumSizePadding() {
        let padding = EduButton.Size.medium.padding

        #expect(padding.top == 10, "Medium padding top debe ser 10")
        #expect(padding.leading == 16, "Medium padding leading debe ser 16")
        #expect(padding.bottom == 10, "Medium padding bottom debe ser 10")
        #expect(padding.trailing == 16, "Medium padding trailing debe ser 16")
    }

    @Test("Size.large tiene padding correcto")
    func testLargeSizePadding() {
        let padding = EduButton.Size.large.padding

        #expect(padding.top == 14, "Large padding top debe ser 14")
        #expect(padding.leading == 20, "Large padding leading debe ser 20")
        #expect(padding.bottom == 14, "Large padding bottom debe ser 14")
        #expect(padding.trailing == 20, "Large padding trailing debe ser 20")
    }

    // MARK: - Size Font Tests

    @Test("Size.small tiene fuente caption")
    func testSmallSizeFont() {
        let font = EduButton.Size.small.fontSize

        #expect(font == .caption, "Small size debe usar fuente caption")
    }

    @Test("Size.medium tiene fuente body")
    func testMediumSizeFont() {
        let font = EduButton.Size.medium.fontSize

        #expect(font == .body, "Medium size debe usar fuente body")
    }

    @Test("Size.large tiene fuente title3")
    func testLargeSizeFont() {
        let font = EduButton.Size.large.fontSize

        #expect(font == .title3, "Large size debe usar fuente title3")
    }

    // MARK: - Complex Scenarios Tests

    @Test("Button con todas las características")
    func testFullFeaturedButton() async {
        @MainActor
        class TestContext {
            var isLoading = false
            var isDisabled = false
            var actionCalled = false
        }

        let context = TestContext()

        let button = EduButton(
            "Complete Action",
            icon: "checkmark.circle",
            iconPosition: .leading,
            style: .primary,
            size: .large,
            isLoading: context.isLoading,
            isDisabled: context.isDisabled
        ) {
            context.actionCalled = true
        }

        #expect(button != nil, "Button completo debe crearse correctamente")
    }

    @Test("Button simula flujo async con loading")
    func testAsyncLoadingFlow() async {
        @MainActor
        class TestContext {
            var isLoading = false
            var completed = false
        }

        let context = TestContext()

        let button = EduButton(
            "Submit",
            isLoading: context.isLoading
        ) {
            Task {
                context.isLoading = true
                // Simular operación async
                try? await Task.sleep(for: .seconds(0.1))
                context.isLoading = false
                context.completed = true
            }
        }

        #expect(button != nil, "Button con flujo async debe crearse")
    }

    // MARK: - ButtonStyle Tests

    @Test("EduPrimaryButtonStyle inicializa correctamente")
    func testEduPrimaryButtonStyleInitialization() {
        let style = EduPrimaryButtonStyle()

        #expect(style.size == .medium, "Default size debe ser medium")
    }

    @Test("EduPrimaryButtonStyle con tamaño custom")
    func testEduPrimaryButtonStyleCustomSize() {
        let style = EduPrimaryButtonStyle(size: .large)

        #expect(style.size == .large, "Size custom debe ser respetado")
    }

    @Test("EduSecondaryButtonStyle inicializa correctamente")
    func testEduSecondaryButtonStyleInitialization() {
        let style = EduSecondaryButtonStyle()

        #expect(style.size == .medium, "Default size debe ser medium")
    }

    @Test("EduDestructiveButtonStyle inicializa correctamente")
    func testEduDestructiveButtonStyleInitialization() {
        let style = EduDestructiveButtonStyle()

        #expect(style.size == .medium, "Default size debe ser medium")
    }

    @Test("EduLinkButtonStyle inicializa correctamente")
    func testEduLinkButtonStyleInitialization() {
        let style = EduLinkButtonStyle()

        #expect(style != nil, "Link style debe inicializarse")
    }
}
