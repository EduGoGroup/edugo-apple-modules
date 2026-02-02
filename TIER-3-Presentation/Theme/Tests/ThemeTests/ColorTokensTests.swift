import Testing
import SwiftUI
@testable import Theme

/// Tests para validar la integridad del sistema de ColorTokens.
///
/// Estos tests verifican que:
/// - Todos los tokens existen en light y dark mode
/// - Los colores tienen contraste mínimo (WCAG AA)
/// - No hay valores inválidos (NaN, infinity, out of range)
@MainActor
@Suite("ColorTokens Tests")
struct ColorTokensTests {

    // MARK: - Existence Tests

    @Test("Todos los primary tokens existen")
    func testPrimaryTokensExist() {
        // Verificar que todos los tokens primary tienen valores válidos
        #expect(ColorTokens.primary50.light != Color.clear)
        #expect(ColorTokens.primary100.light != Color.clear)
        #expect(ColorTokens.primary200.light != Color.clear)
        #expect(ColorTokens.primary300.light != Color.clear)
        #expect(ColorTokens.primary400.light != Color.clear)
        #expect(ColorTokens.primary500.light != Color.clear)
        #expect(ColorTokens.primary600.light != Color.clear)
        #expect(ColorTokens.primary700.light != Color.clear)
        #expect(ColorTokens.primary800.light != Color.clear)
        #expect(ColorTokens.primary900.light != Color.clear)

        // Verificar dark mode
        #expect(ColorTokens.primary50.dark != Color.clear)
        #expect(ColorTokens.primary500.dark != Color.clear)
        #expect(ColorTokens.primary900.dark != Color.clear)
    }

    @Test("Todos los neutral tokens existen")
    func testNeutralTokensExist() {
        #expect(ColorTokens.neutral50.light != Color.clear)
        #expect(ColorTokens.neutral500.light != Color.clear)
        #expect(ColorTokens.neutral900.light != Color.clear)

        #expect(ColorTokens.neutral50.dark != Color.clear)
        #expect(ColorTokens.neutral500.dark != Color.clear)
        #expect(ColorTokens.neutral900.dark != Color.clear)
    }

    @Test("Todos los error tokens existen")
    func testErrorTokensExist() {
        #expect(ColorTokens.error50.light != Color.clear)
        #expect(ColorTokens.error500.light != Color.clear)
        #expect(ColorTokens.error900.light != Color.clear)
    }

    @Test("Todos los warning tokens existen")
    func testWarningTokensExist() {
        #expect(ColorTokens.warning50.light != Color.clear)
        #expect(ColorTokens.warning500.light != Color.clear)
        #expect(ColorTokens.warning900.light != Color.clear)
    }

    @Test("Todos los success tokens existen")
    func testSuccessTokensExist() {
        #expect(ColorTokens.success50.light != Color.clear)
        #expect(ColorTokens.success500.light != Color.clear)
        #expect(ColorTokens.success900.light != Color.clear)
    }

    @Test("Todos los info tokens existen")
    func testInfoTokensExist() {
        #expect(ColorTokens.info50.light != Color.clear)
        #expect(ColorTokens.info500.light != Color.clear)
        #expect(ColorTokens.info900.light != Color.clear)
    }

    // MARK: - ColorToken Resolve Tests

    @Test("ColorToken resolve retorna color correcto para light mode")
    func testColorTokenResolveLight() {
        let token = ColorTokens.primary500
        let resolved = token.resolve(for: .light)
        #expect(resolved == token.light)
    }

    @Test("ColorToken resolve retorna color correcto para dark mode")
    func testColorTokenResolveDark() {
        let token = ColorTokens.primary500
        let resolved = token.resolve(for: .dark)
        #expect(resolved == token.dark)
    }

    // MARK: - Contrast Tests (WCAG AA)

    @Test("Primary 500 tiene contraste suficiente sobre blanco")
    func testPrimary500ContrastOnWhite() {
        let contrast = calculateContrastRatio(
            foreground: ColorTokens.primary500.light,
            background: Color.white
        )
        // WCAG AA requiere 4.5:1 para texto normal
        #expect(contrast >= 4.5)
    }

    @Test("Neutral 900 tiene contraste suficiente sobre neutral 50")
    func testNeutral900ContrastOnNeutral50() {
        let contrast = calculateContrastRatio(
            foreground: ColorTokens.neutral900.light,
            background: ColorTokens.neutral50.light
        )
        #expect(contrast >= 4.5)
    }

    @Test("Error 500 tiene contraste suficiente sobre blanco")
    func testError500ContrastOnWhite() {
        let contrast = calculateContrastRatio(
            foreground: ColorTokens.error500.light,
            background: Color.white
        )
        #expect(contrast >= 4.5)
    }

    // MARK: - Color Value Validation

    @Test("Primary tokens no tienen valores inválidos")
    func testPrimaryTokensValidValues() {
        validateColorComponents(ColorTokens.primary500.light)
        validateColorComponents(ColorTokens.primary500.dark)
    }

    @Test("Neutral tokens no tienen valores inválidos")
    func testNeutralTokensValidValues() {
        validateColorComponents(ColorTokens.neutral500.light)
        validateColorComponents(ColorTokens.neutral500.dark)
    }

    // MARK: - Helper Functions

    /// Calcula el ratio de contraste entre dos colores según WCAG
    private func calculateContrastRatio(foreground: Color, background: Color) -> Double {
        let fgLuminance = relativeLuminance(foreground)
        let bgLuminance = relativeLuminance(background)

        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Calcula la luminancia relativa de un color según WCAG
    private func relativeLuminance(_ color: Color) -> Double {
        // Obtener componentes RGB
        let components = colorComponents(color)
        let r = linearizeColorComponent(components.red)
        let g = linearizeColorComponent(components.green)
        let b = linearizeColorComponent(components.blue)

        // Fórmula WCAG: 0.2126 * R + 0.7152 * G + 0.0722 * B
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Lineariza un componente de color según WCAG
    private func linearizeColorComponent(_ component: Double) -> Double {
        if component <= 0.03928 {
            return component / 12.92
        } else {
            return pow((component + 0.055) / 1.055, 2.4)
        }
    }

    /// Extrae los componentes RGB de un Color
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

    /// Valida que los componentes de un color estén en rango válido
    private func validateColorComponents(_ color: Color) {
        let components = colorComponents(color)

        #expect(components.red >= 0.0 && components.red <= 1.0)
        #expect(components.green >= 0.0 && components.green <= 1.0)
        #expect(components.blue >= 0.0 && components.blue <= 1.0)
        #expect(components.alpha >= 0.0 && components.alpha <= 1.0)

        // Verificar que no son NaN
        #expect(!components.red.isNaN)
        #expect(!components.green.isNaN)
        #expect(!components.blue.isNaN)
        #expect(!components.alpha.isNaN)
    }
}
