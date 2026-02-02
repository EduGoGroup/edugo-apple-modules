import Testing
import SwiftUI
@testable import Theme

/// Tests para validar que SemanticColors se resuelven correctamente.
///
/// Estos tests verifican que:
/// - Todos los semantic colors tienen valores válidos
/// - Los semantic colors mapean correctamente a ColorTokens
/// - Los pares de colores (texto/background) tienen contraste adecuado
@MainActor
@Suite("SemanticColors Tests")
struct SemanticColorsTests {

    // MARK: - Existence Tests

    @Test("Background colors existen")
    func testBackgroundColorsExist() {
        #expect(SemanticColors.background.light != Color.clear)
        #expect(SemanticColors.backgroundSecondary.light != Color.clear)
        #expect(SemanticColors.backgroundTertiary.light != Color.clear)

        #expect(SemanticColors.background.dark != Color.clear)
        #expect(SemanticColors.backgroundSecondary.dark != Color.clear)
        #expect(SemanticColors.backgroundTertiary.dark != Color.clear)
    }

    @Test("Surface colors existen")
    func testSurfaceColorsExist() {
        #expect(SemanticColors.surface.light != Color.clear)
        #expect(SemanticColors.surfaceElevated.light != Color.clear)
        #expect(SemanticColors.surfaceOverlay.light != Color.clear)
    }

    @Test("Text colors existen")
    func testTextColorsExist() {
        #expect(SemanticColors.textPrimary.light != Color.clear)
        #expect(SemanticColors.textSecondary.light != Color.clear)
        #expect(SemanticColors.textTertiary.light != Color.clear)
        #expect(SemanticColors.textDisabled.light != Color.clear)
        #expect(SemanticColors.textOnPrimary.light != Color.clear)
        #expect(SemanticColors.textOnError.light != Color.clear)
    }

    @Test("Border colors existen")
    func testBorderColorsExist() {
        #expect(SemanticColors.border.light != Color.clear)
        #expect(SemanticColors.borderFocused.light != Color.clear)
        #expect(SemanticColors.borderError.light != Color.clear)
        #expect(SemanticColors.borderDisabled.light != Color.clear)
    }

    @Test("State colors existen")
    func testStateColorsExist() {
        #expect(SemanticColors.error.light != Color.clear)
        #expect(SemanticColors.errorBackground.light != Color.clear)
        #expect(SemanticColors.warning.light != Color.clear)
        #expect(SemanticColors.warningBackground.light != Color.clear)
        #expect(SemanticColors.success.light != Color.clear)
        #expect(SemanticColors.successBackground.light != Color.clear)
        #expect(SemanticColors.info.light != Color.clear)
        #expect(SemanticColors.infoBackground.light != Color.clear)
    }

    @Test("Interactive colors existen")
    func testInteractiveColorsExist() {
        #expect(SemanticColors.interactive.light != Color.clear)
        #expect(SemanticColors.interactiveHovered.light != Color.clear)
        #expect(SemanticColors.interactivePressed.light != Color.clear)
        #expect(SemanticColors.interactiveDisabled.light != Color.clear)
    }

    // MARK: - Color Pairing Contrast Tests

    @Test("textPrimary tiene contraste suficiente sobre background")
    func testTextPrimaryOnBackground() {
        let contrast = calculateContrastRatio(
            foreground: SemanticColors.textPrimary.light,
            background: SemanticColors.background.light
        )
        // WCAG AA requiere 4.5:1 para texto normal
        #expect(contrast >= 4.5, "textPrimary sobre background debe tener contraste >= 4.5:1, obtuvo \(contrast)")
    }

    @Test("textSecondary tiene contraste suficiente sobre background")
    func testTextSecondaryOnBackground() {
        let contrast = calculateContrastRatio(
            foreground: SemanticColors.textSecondary.light,
            background: SemanticColors.background.light
        )
        // WCAG AA requiere 4.5:1 para texto normal
        #expect(contrast >= 4.5, "textSecondary sobre background debe tener contraste >= 4.5:1, obtuvo \(contrast)")
    }

    @Test("error tiene contraste suficiente sobre errorBackground")
    func testErrorOnErrorBackground() {
        let contrast = calculateContrastRatio(
            foreground: SemanticColors.error.light,
            background: SemanticColors.errorBackground.light
        )
        #expect(contrast >= 4.5, "error sobre errorBackground debe tener contraste >= 4.5:1, obtuvo \(contrast)")
    }

    @Test("textOnPrimary tiene contraste suficiente sobre interactive")
    func testTextOnPrimaryOnInteractive() {
        let contrast = calculateContrastRatio(
            foreground: SemanticColors.textOnPrimary.light,
            background: SemanticColors.interactive.light
        )
        #expect(contrast >= 4.5, "textOnPrimary sobre interactive debe tener contraste >= 4.5:1, obtuvo \(contrast)")
    }

    @Test("textOnError tiene contraste suficiente sobre error")
    func testTextOnErrorOnError() {
        let contrast = calculateContrastRatio(
            foreground: SemanticColors.textOnError.light,
            background: SemanticColors.error.light
        )
        #expect(contrast >= 4.5, "textOnError sobre error debe tener contraste >= 4.5:1, obtuvo \(contrast)")
    }

    // MARK: - Dark Mode Tests

    @Test("textPrimary dark mode tiene contraste suficiente sobre background dark")
    func testTextPrimaryOnBackgroundDarkMode() {
        let contrast = calculateContrastRatio(
            foreground: SemanticColors.textPrimary.dark,
            background: SemanticColors.background.dark
        )
        #expect(contrast >= 4.5, "textPrimary dark sobre background dark debe tener contraste >= 4.5:1, obtuvo \(contrast)")
    }

    @Test("error dark mode tiene contraste suficiente sobre errorBackground dark")
    func testErrorOnErrorBackgroundDarkMode() {
        let contrast = calculateContrastRatio(
            foreground: SemanticColors.error.dark,
            background: SemanticColors.errorBackground.dark
        )
        #expect(contrast >= 4.5, "error dark sobre errorBackground dark debe tener contraste >= 4.5:1, obtuvo \(contrast)")
    }

    // MARK: - Resolve Tests

    @Test("SemanticColor resolve funciona correctamente")
    func testSemanticColorResolve() {
        let textPrimary = SemanticColors.textPrimary

        let lightResolved = textPrimary.resolve(for: .light)
        let darkResolved = textPrimary.resolve(for: .dark)

        #expect(lightResolved == textPrimary.light)
        #expect(darkResolved == textPrimary.dark)
    }

    // MARK: - Color+Theme Extension Tests

    @Test("Color.theme.textPrimary es accesible")
    func testColorThemeAccessor() {
        let textPrimary = Color.theme.textPrimary
        #expect(textPrimary != Color.clear)
    }

    @Test("Color.theme.background es accesible")
    func testColorThemeBackground() {
        let background = Color.theme.background
        #expect(background != Color.clear)
    }

    @Test("Color.theme.error es accesible")
    func testColorThemeError() {
        let error = Color.theme.error
        #expect(error != Color.clear)
    }

    // MARK: - Helper Functions

    private func calculateContrastRatio(foreground: Color, background: Color) -> Double {
        let fgLuminance = relativeLuminance(foreground)
        let bgLuminance = relativeLuminance(background)

        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(_ color: Color) -> Double {
        let components = colorComponents(color)
        let r = linearizeColorComponent(components.red)
        let g = linearizeColorComponent(components.green)
        let b = linearizeColorComponent(components.blue)

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    private func linearizeColorComponent(_ component: Double) -> Double {
        if component <= 0.03928 {
            return component / 12.92
        } else {
            return pow((component + 0.055) / 1.055, 2.4)
        }
    }

    private func colorComponents(_ color: Color) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue), Double(alpha))
        #elseif os(macOS)
        guard let rgbColor = NSColor(color).usingColorSpace(.deviceRGB) else {
            return (0, 0, 0, 1)
        }
        return (
            Double(rgbColor.redComponent),
            Double(rgbColor.greenComponent),
            Double(rgbColor.blueComponent),
            Double(rgbColor.alphaComponent)
        )
        #else
        return (0, 0, 0, 1)
        #endif
    }
}
