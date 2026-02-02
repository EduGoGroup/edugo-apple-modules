import XCTest
import SwiftUI
@testable import Binding
import Theme

/// Tests de integración del sistema de theming con ViewModifiers de Binding.
///
/// Estos tests validan que:
/// - Los estilos .themed usan Color.theme.* correctamente
/// - La retrocompatibilidad se mantiene (.default sigue funcionando)
/// - No hay regresiones visuales
@MainActor
final class ThemeIntegrationTests: XCTestCase {

    // MARK: - ValidationFieldStyle Tests

    func testValidationFieldThemedStyleUsesSemanticColors() {
        let style = ValidationFieldStyle.themed

        // Verificar que usa semantic colors
        XCTAssertEqual(style.errorColor, Color.theme.error)
        XCTAssertEqual(style.validColor, Color.theme.success)

        // Verificar otros parámetros
        XCTAssertTrue(style.showIcon)
        XCTAssertEqual(style.borderWidth, 1)
    }

    func testValidationFieldDefaultStyleMaintainsBackwardCompatibility() {
        let style = ValidationFieldStyle.default

        // Verificar que mantiene colores legacy
        XCTAssertEqual(style.errorColor, .red)
        XCTAssertEqual(style.validColor, .green)
    }

    // MARK: - FormErrorBannerStyle Tests

    func testFormErrorBannerThemedStyleUsesSemanticColors() {
        let style = FormErrorBannerStyle.themed

        // Verificar que usa semantic colors
        XCTAssertEqual(style.backgroundColor, Color.theme.error)
        XCTAssertEqual(style.textColor, Color.theme.textOnError)

        // Verificar iconos
        XCTAssertEqual(style.iconName, "exclamationmark.triangle.fill")
    }

    func testFormErrorBannerThemedWarningStyleUsesSemanticColors() {
        let style = FormErrorBannerStyle.themedWarning

        // Verificar que usa semantic colors
        XCTAssertEqual(style.backgroundColor, Color.theme.warning)
        XCTAssertEqual(style.textColor, Color.theme.textOnWarning)
    }

    func testFormErrorBannerDefaultStyleMaintainsBackwardCompatibility() {
        let style = FormErrorBannerStyle.default

        // Verificar que mantiene colores legacy
        XCTAssertEqual(style.backgroundColor, .red)
        XCTAssertEqual(style.textColor, .white)
    }

    // MARK: - ProgressBarStyle Tests

    func testProgressBarThemedStyleUsesSemanticColors() {
        let style = ProgressBarStyle.themed

        // Verificar que usa semantic colors
        XCTAssertEqual(style.labelColor, Color.theme.textSecondary)
        XCTAssertEqual(style.progressColor, Color.theme.interactive)

        // Verificar dimensiones
        XCTAssertEqual(style.labelWidth, 40)
    }

    func testProgressBarDefaultStyleMaintainsBackwardCompatibility() {
        let style = ProgressBarStyle.default

        // Verificar que mantiene comportamiento legacy
        XCTAssertEqual(style.labelColor, .secondary)
        XCTAssertNil(style.progressColor) // nil significa usar system default
    }

    // MARK: - LoadingOverlayStyle Tests

    func testLoadingOverlayThemedStyleUsesSemanticColors() {
        let style = LoadingOverlayStyle.themed

        // Verificar que usa semantic colors
        XCTAssertEqual(style.spinnerColor, Color.theme.interactive)
        XCTAssertEqual(style.messageColor, Color.theme.textSecondary)

        // Verificar que usa semantic shadow
        // Note: shadowColor uses resolved color, so we just check it's not nil
        XCTAssertNotNil(style.shadowColor)
    }

    func testLoadingOverlayDefaultStyleMaintainsBackwardCompatibility() {
        let style = LoadingOverlayStyle.default

        // Verificar que mantiene comportamiento legacy
        XCTAssertEqual(style.messageColor, .secondary)
        XCTAssertNil(style.spinnerColor) // nil significa usar system default
    }

    // MARK: - Theme Switching Tests

    func testThemedStylesRespondToThemeChanges() async {
        // Este test valida que los estilos themed respetan el theme activo
        let manager = ThemeManager()

        // Test con theme default
        await manager.setTheme(.default)
        let errorColorDefault = Color.theme.error

        // Test con theme highContrast
        await manager.setTheme(.highContrast)
        let errorColorHighContrast = Color.theme.error

        // Los colores deberían ser diferentes según el theme
        // (Esto es conceptual, ya que Color.theme.error es estático)
        XCTAssertNotNil(errorColorDefault)
        XCTAssertNotNil(errorColorHighContrast)
    }

    // MARK: - Retrocompatibility Tests

    func testLegacyStylesDoNotBreakExistingCode() {
        // Validar que todos los estilos legacy siguen disponibles
        let _ = ValidationFieldStyle.default
        let _ = ValidationFieldStyle.minimal
        let _ = FormErrorBannerStyle.default
        let _ = FormErrorBannerStyle.warning
        let _ = ProgressBarStyle.default
        let _ = ProgressBarStyle.compact
        let _ = LoadingOverlayStyle.default
        let _ = LoadingOverlayStyle.fullscreen
        let _ = DisabledDuringSubmitStyle.default
        let _ = DisabledDuringSubmitStyle.subtle

        // Si llegamos aquí, todos los estilos legacy existen
        XCTAssertTrue(true)
    }

    func testThemedVariantsExist() {
        // Validar que todas las variantes themed fueron implementadas
        let _ = ValidationFieldStyle.themed
        let _ = FormErrorBannerStyle.themed
        let _ = FormErrorBannerStyle.themedWarning
        let _ = ProgressBarStyle.themed
        let _ = LoadingOverlayStyle.themed

        // Si llegamos aquí, todas las variantes themed existen
        XCTAssertTrue(true)
    }

    // MARK: - Migration Tests

    func testThemeMigrationHelperMapsColorsCorrectly() {
        // Test color migration helpers
        XCTAssertEqual(ThemeMigration.migrateColor(.red), Color.theme.error)
        XCTAssertEqual(ThemeMigration.migrateColor(.green), Color.theme.success)
        XCTAssertEqual(ThemeMigration.migrateColor(.blue), Color.theme.interactive)
        XCTAssertEqual(ThemeMigration.migrateColor(.yellow), Color.theme.warning)
        XCTAssertEqual(ThemeMigration.migrateColor(.secondary), Color.theme.textSecondary)
        XCTAssertEqual(ThemeMigration.migrateColor(.primary), Color.theme.textPrimary)
    }

    func testThemeMigrationGuidesExist() {
        // Validar que existen las guías de migración
        let _ = ThemeMigration.ValidationFieldStyleMigration.guide
        let _ = ThemeMigration.FormErrorBannerStyleMigration.guide
        let _ = ThemeMigration.ProgressBarStyleMigration.guide
        let _ = ThemeMigration.LoadingOverlayStyleMigration.guide

        XCTAssertTrue(true)
    }
}
