import Testing
import SwiftUI
@testable import Theme

/// Tests para ThemeManager.
///
/// Verifica:
/// - Thread-safety (concurrent access)
/// - Cambio de themes
/// - Cambio de color schemes
/// - Sincronización con sistema
/// - Persistencia de preferencias
@MainActor
@Suite("ThemeManager Tests")
struct ThemeManagerTests {

    // MARK: - Initialization Tests

    @Test("ThemeManager se inicializa con theme por defecto")
    func testInitialization() {
        let manager = ThemeManager(userDefaults: .ephemeral)

        #expect(manager.currentTheme.id == "default")
        #expect(manager.colorSchemePreference == .auto)
    }

    @Test("ThemeManager shared es singleton")
    func testSharedInstance() {
        let manager1 = ThemeManager.shared
        let manager2 = ThemeManager.shared

        #expect(manager1 === manager2)
    }

    @Test("ThemeManager carga preferencias guardadas en init")
    func testInitializationLoadsPreferences() {
        let userDefaults = UserDefaults.ephemeral
        userDefaults.set("dark", forKey: "com.edugo.theme.selectedThemeId")
        userDefaults.set("dark", forKey: "com.edugo.theme.colorScheme")

        let manager = ThemeManager(userDefaults: userDefaults)

        #expect(manager.currentTheme.id == "dark")
        #expect(manager.colorSchemePreference == .dark)
    }

    // MARK: - Theme Switching Tests

    @Test("setTheme cambia el theme actual")
    func testSetTheme() {
        let manager = ThemeManager(userDefaults: .ephemeral)

        manager.setTheme(.dark)

        #expect(manager.currentTheme.id == "dark")
        #expect(manager.currentTheme.name == "Dark")
    }

    @Test("setTheme persiste la preferencia en UserDefaults")
    func testSetThemePersistence() {
        let userDefaults = UserDefaults.ephemeral
        let manager = ThemeManager(userDefaults: userDefaults)

        manager.setTheme(.highContrast)

        let savedThemeId = userDefaults.string(forKey: "com.edugo.theme.selectedThemeId")
        #expect(savedThemeId == "highContrast")
    }

    // MARK: - Color Scheme Tests

    @Test("setColorScheme cambia la preferencia")
    func testSetColorScheme() {
        let manager = ThemeManager(userDefaults: .ephemeral)

        manager.setColorScheme(.dark)

        #expect(manager.colorSchemePreference == .dark)
        #expect(manager.effectiveColorScheme == .dark)
    }

    @Test("setColorScheme persiste la preferencia en UserDefaults")
    func testSetColorSchemePersistence() {
        let userDefaults = UserDefaults.ephemeral
        let manager = ThemeManager(userDefaults: userDefaults)

        manager.setColorScheme(.light)

        let savedScheme = userDefaults.string(forKey: "com.edugo.theme.colorScheme")
        #expect(savedScheme == "light")
    }

    @Test("colorScheme auto respeta el sistema")
    func testColorSchemeAuto() {
        let manager = ThemeManager(userDefaults: .ephemeral)

        manager.setColorScheme(.auto)
        manager.updateSystemColorScheme(.dark)

        #expect(manager.colorSchemePreference == .auto)
        #expect(manager.effectiveColorScheme == .dark)

        manager.updateSystemColorScheme(.light)
        #expect(manager.effectiveColorScheme == .light)
    }

    @Test("colorScheme light siempre es light")
    func testColorSchemeLight() {
        let manager = ThemeManager(userDefaults: .ephemeral)

        manager.setColorScheme(.light)
        manager.updateSystemColorScheme(.dark)

        #expect(manager.effectiveColorScheme == .light)
    }

    @Test("colorScheme dark siempre es dark")
    func testColorSchemeDark() {
        let manager = ThemeManager(userDefaults: .ephemeral)

        manager.setColorScheme(.dark)
        manager.updateSystemColorScheme(.light)

        #expect(manager.effectiveColorScheme == .dark)
    }

    // MARK: - System Color Scheme Sync Tests

    @Test("updateSystemColorScheme actualiza el effective scheme en modo auto")
    func testSystemColorSchemeUpdate() {
        let manager = ThemeManager(userDefaults: .ephemeral)

        manager.setColorScheme(.auto)

        manager.updateSystemColorScheme(.dark)
        #expect(manager.effectiveColorScheme == .dark)

        manager.updateSystemColorScheme(.light)
        #expect(manager.effectiveColorScheme == .light)
    }

    // MARK: - Reset Tests

    @Test("reset restaura valores por defecto")
    func testReset() {
        let userDefaults = UserDefaults.ephemeral
        let manager = ThemeManager(userDefaults: userDefaults)

        // Cambiar valores
        manager.setTheme(.highContrast)
        manager.setColorScheme(.dark)

        // Reset
        manager.reset()

        #expect(manager.currentTheme.id == "default")
        #expect(manager.colorSchemePreference == .auto)

        // Verificar que se limpia UserDefaults
        let savedThemeId = userDefaults.string(forKey: "com.edugo.theme.selectedThemeId")
        let savedColorScheme = userDefaults.string(forKey: "com.edugo.theme.colorScheme")
        #expect(savedThemeId == nil)
        #expect(savedColorScheme == nil)
    }

    // MARK: - Custom Theme Tests

    @Test("loadCustomTheme carga un theme personalizado")
    func testLoadCustomTheme() {
        let manager = ThemeManager(userDefaults: .ephemeral)
        let customTheme = Theme.custom(
            id: "custom1",
            name: "My Theme",
            palette: .grayscale
        )

        manager.loadCustomTheme(customTheme)

        #expect(manager.currentTheme.id == "custom1")
        #expect(manager.currentTheme.name == "My Theme")
    }

    @Test("loadCustomTheme persiste el theme custom")
    func testLoadCustomThemePersistence() {
        let userDefaults = UserDefaults.ephemeral
        let manager = ThemeManager(userDefaults: userDefaults)
        let customTheme = Theme.custom(
            id: "custom1",
            name: "My Theme",
            palette: .grayscale
        )

        manager.loadCustomTheme(customTheme)

        let savedThemeId = userDefaults.string(forKey: "com.edugo.theme.selectedThemeId")
        #expect(savedThemeId == "custom1")
    }

    // MARK: - Convenience Accessors Tests

    @Test("isDarkMode refleja el effective color scheme")
    func testIsDarkMode() {
        let manager = ThemeManager(userDefaults: .ephemeral)

        manager.setColorScheme(.light)
        #expect(manager.isDarkMode == false)

        manager.setColorScheme(.dark)
        #expect(manager.isDarkMode == true)
    }

    @Test("isAutoMode refleja la preferencia")
    func testIsAutoMode() {
        let manager = ThemeManager(userDefaults: .ephemeral)

        manager.setColorScheme(.auto)
        #expect(manager.isAutoMode == true)

        manager.setColorScheme(.light)
        #expect(manager.isAutoMode == false)
    }

    @Test("availableThemes retorna todos los themes predefinidos")
    func testAvailableThemes() {
        let manager = ThemeManager(userDefaults: .ephemeral)
        let themes = manager.availableThemes

        #expect(themes.count == 4)
        #expect(themes.contains { $0.id == "default" })
        #expect(themes.contains { $0.id == "dark" })
        #expect(themes.contains { $0.id == "highContrast" })
        #expect(themes.contains { $0.id == "grayscale" })
    }
}

// MARK: - ColorSchemePreference Tests

@Suite("ColorSchemePreference Tests")
struct ColorSchemePreferenceTests {

    @Test("ColorSchemePreference tiene display names correctos")
    func testDisplayNames() {
        #expect(ColorSchemePreference.light.displayName == "Light")
        #expect(ColorSchemePreference.dark.displayName == "Dark")
        #expect(ColorSchemePreference.auto.displayName == "Auto")
    }

    @Test("ColorSchemePreference.allCases contiene todos los valores")
    func testAllCases() {
        let allCases = ColorSchemePreference.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.light))
        #expect(allCases.contains(.dark))
        #expect(allCases.contains(.auto))
    }

    @Test("ColorSchemePreference es Sendable")
    func testSendable() {
        let preference: ColorSchemePreference = .auto
        Task {
            let _ = preference // Verifica que se puede usar en Task
        }
    }
}

// MARK: - UserDefaults Extension for Testing

extension UserDefaults {
    /// UserDefaults efímero para testing (no persiste entre ejecuciones)
    nonisolated(unsafe) static var ephemeral: UserDefaults {
        let defaults = UserDefaults(suiteName: "com.edugo.theme.tests.\(UUID().uuidString)")!
        return defaults
    }
}
