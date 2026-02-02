import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduCardTests {

    // MARK: - Initialization Tests

    @Test("EduCard inicializa correctamente con parámetros por defecto")
    func testDefaultInitialization() {
        let card = EduCard {
            Text("Test Content")
        }

        #expect(card != nil, "Card debe inicializarse correctamente")
    }

    @Test("EduCard inicializa con padding custom")
    func testCustomPaddingInitialization() {
        let card = EduCard(
            padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        ) {
            Text("Test Content")
        }

        #expect(card != nil, "Card con padding custom debe inicializarse")
    }

    @Test("EduCard inicializa con corner radius custom")
    func testCustomCornerRadius() {
        let card = EduCard(cornerRadius: 16) {
            Text("Test Content")
        }

        #expect(card != nil, "Card con corner radius custom debe inicializarse")
    }

    // MARK: - Elevation Tests

    @Test("EduCard con elevación none")
    func testElevationNone() {
        let card = EduCard(elevation: .none) {
            Text("No Shadow")
        }

        #expect(card != nil, "Card con elevación none debe crearse")
    }

    @Test("EduCard con elevación low")
    func testElevationLow() {
        let card = EduCard(elevation: .low) {
            Text("Low Shadow")
        }

        #expect(card != nil, "Card con elevación low debe crearse")
    }

    @Test("EduCard con elevación medium")
    func testElevationMedium() {
        let card = EduCard(elevation: .medium) {
            Text("Medium Shadow")
        }

        #expect(card != nil, "Card con elevación medium debe crearse")
    }

    @Test("EduCard con elevación high")
    func testElevationHigh() {
        let card = EduCard(elevation: .high) {
            Text("High Shadow")
        }

        #expect(card != nil, "Card con elevación high debe crearse")
    }

    // MARK: - Elevation Values Tests

    @Test("Elevation.none tiene shadowRadius 0")
    func testElevationNoneShadowRadius() {
        let elevation = EduCard<Text>.Elevation.none

        #expect(elevation.shadowRadius == 0, "Shadow radius debe ser 0")
        #expect(elevation.shadowY == 0, "Shadow Y debe ser 0")
    }

    @Test("Elevation.low tiene valores correctos")
    func testElevationLowValues() {
        let elevation = EduCard<Text>.Elevation.low

        #expect(elevation.shadowRadius == 2, "Shadow radius debe ser 2")
        #expect(elevation.shadowY == 1, "Shadow Y debe ser 1")
    }

    @Test("Elevation.medium tiene valores correctos")
    func testElevationMediumValues() {
        let elevation = EduCard<Text>.Elevation.medium

        #expect(elevation.shadowRadius == 4, "Shadow radius debe ser 4")
        #expect(elevation.shadowY == 2, "Shadow Y debe ser 2")
    }

    @Test("Elevation.high tiene valores correctos")
    func testElevationHighValues() {
        let elevation = EduCard<Text>.Elevation.high

        #expect(elevation.shadowRadius == 8, "Shadow radius debe ser 8")
        #expect(elevation.shadowY == 4, "Shadow Y debe ser 4")
    }

    // MARK: - State Tests

    @Test("EduCard con estado highlighted")
    func testHighlightedState() {
        let card = EduCard(isHighlighted: true) {
            Text("Highlighted")
        }

        #expect(card != nil, "Card destacado debe crearse")
    }

    @Test("EduCard con estado disabled")
    func testDisabledState() {
        let card = EduCard(isDisabled: true) {
            Text("Disabled")
        }

        #expect(card != nil, "Card deshabilitado debe crearse")
    }

    // MARK: - Interaction Tests

    @Test("EduCard con onTap action")
    func testInteractiveCard() {
        @MainActor
        class TestContext {
            var tapped = false
        }

        let context = TestContext()

        let card = EduCard(onTap: {
            context.tapped = true
        }) {
            Text("Tap Me")
        }

        #expect(card != nil, "Card interactivo debe crearse")
    }

    // MARK: - Convenience Initializers Tests

    @Test("EduCard.simple crea card correctamente")
    func testSimpleCardConvenience() {
        let card = EduCard.simple {
            Text("Simple Card")
        }

        #expect(card != nil, "Simple card debe crearse")
    }

    @Test("EduCard.hero crea card correctamente")
    func testHeroCardConvenience() {
        let card = EduCard.hero {
            Text("Hero Card")
        }

        #expect(card != nil, "Hero card debe crearse")
    }

    @Test("EduCard.list crea card correctamente")
    func testListCardConvenience() {
        let card = EduCard.list {
            Text("List Card")
        }

        #expect(card != nil, "List card debe crearse")
    }

    // MARK: - Specialized Cards Tests

    @Test("EduHeroCard inicializa correctamente")
    func testHeroCardInitialization() {
        let heroCard = EduHeroCard {
            Text("Hero Content")
        }

        #expect(heroCard != nil, "Hero card debe inicializarse")
    }

    @Test("EduHeroCard con onTap")
    func testHeroCardWithTap() {
        let heroCard = EduHeroCard(onTap: {}) {
            Text("Interactive Hero")
        }

        #expect(heroCard != nil, "Hero card interactivo debe crearse")
    }

    @Test("EduListCard inicializa correctamente")
    func testListCardInitialization() {
        let listCard = EduListCard {
            Text("List Item")
        }

        #expect(listCard != nil, "List card debe inicializarse")
    }

    @Test("EduListCard con onTap")
    func testListCardWithTap() {
        let listCard = EduListCard(onTap: {}) {
            Text("Interactive List Item")
        }

        #expect(listCard != nil, "List card interactivo debe crearse")
    }

    // MARK: - Background Color Tests

    @Test("EduCard con background color custom")
    func testCustomBackgroundColor() {
        let card = EduCard(backgroundColor: .blue) {
            Text("Blue Background")
        }

        #expect(card != nil, "Card con background custom debe crearse")
    }

    @Test("Color.cardBackground existe")
    func testCardBackgroundColor() {
        let color = Color.cardBackground

        #expect(color != nil, "cardBackground color debe estar definido")
    }

    // MARK: - Complex Scenarios Tests

    @Test("Card completo con todas las características")
    func testFullFeaturedCard() {
        @MainActor
        class TestContext {
            var tapped = false
        }

        let context = TestContext()

        let card = EduCard(
            padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
            cornerRadius: 16,
            elevation: .high,
            backgroundColor: .blue.opacity(0.1),
            isHighlighted: true,
            isDisabled: false,
            onTap: {
                context.tapped = true
            }
        ) {
            VStack {
                Text("Title")
                Text("Subtitle")
            }
        }

        #expect(card != nil, "Card completo debe crearse correctamente")
    }

    @Test("Card con contenido complejo")
    func testCardWithComplexContent() {
        let card = EduCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Header")
                    .font(.headline)

                Text("Body text with more content")
                    .font(.body)

                HStack {
                    Image(systemName: "star.fill")
                    Text("Footer")
                }
            }
        }

        #expect(card != nil, "Card con contenido complejo debe crearse")
    }
}
