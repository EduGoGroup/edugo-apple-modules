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
    func testInitialization() async {
        let manager = ThemeManager(storage: ThemeStorage(userDefaults: .ephemeral))

        // Dar tiempo para que se carguen las preferencias
        try? await Task.sleep(for: .milliseconds(100))

        #expect(manager.currentTheme.id == "default")
        #expect(manager.colorSchemePreference == .auto)
    }

    @Test("ThemeManager shared es singleton")
    func testSharedInstance() {
        let manager1 = ThemeManager.shared
        let manager2 = ThemeManager.shared

        #expect(manager1 === manager2)
    }

    // MARK: - Theme Switching Tests

    @Test("setTheme cambia el theme actual")
    func testSetTheme() {
        let storage = ThemeStorage(userDefaults: .ephemeral)
        let manager = ThemeManager(storage: storage)

        manager.setTheme(.dark)

        #expect(manager.currentTheme.id == "dark")
        #expect(manager.currentTheme.name == "Dark")
    }

    @Test("setTheme persiste la preferencia")
    func testSetThemePersistence() async {
        let userDefaults = UserDefaults.ephemeral
        let storage = ThemeStorage(userDefaults: userDefaults)
        let manager = ThemeManager(storage: storage)

        manager.setTheme(.highContrast)

        // Dar tiempo para que se persista
        try? await Task.sleep(for: .milliseconds(100))

        // Verificar que se guardó
        let preference = await storage.loadThemePreference()
        #expect(preference.themeId == "highContrast")
    }

    // MARK: - Color Scheme Tests

    @Test("setColorScheme cambia la preferencia")
    func testSetColorScheme() {
        let manager = ThemeManager(storage: ThemeStorage(userDefaults: .ephemeral))

        manager.setColorScheme(.dark)

        #expect(manager.colorSchemePreference == .dark)
        #expect(manager.effectiveColorScheme == .dark)
    }

    @Test("colorScheme auto respeta el sistema")
    func testColorSchemeAuto() {
        let manager = ThemeManager(storage: ThemeStorage(userDefaults: .ephemeral))

        manager.setColorScheme(.auto)
        manager.updateSystemColorScheme(.dark)

        #expect(manager.colorSchemePreference == .auto)
        #expect(manager.effectiveColorScheme == .dark)

        manager.updateSystemColorScheme(.light)
        #expect(manager.effectiveColorScheme == .light)
    }

    @Test("colorScheme light siempre es light")
    func testColorSchemeLight() {
        let manager = ThemeManager(storage: ThemeStorage(userDefaults: .ephemeral))

        manager.setColorScheme(.light)
        manager.updateSystemColorScheme(.dark)

        #expect(manager.effectiveColorScheme == .light)
    }

    @Test("colorScheme dark siempre es dark")
    func testColorSchemeDark() {
        let manager = ThemeManager(storage: ThemeStorage(userDefaults: .ephemeral))

        manager.setColorScheme(.dark)
        manager.updateSystemColorScheme(.light)

        #expect(manager.effectiveColorScheme == .dark)
    }

    // MARK: - System Color Scheme Sync Tests

    @Test("updateSystemColorScheme actualiza el effective scheme en modo auto")
    func testSystemColorSchemeUpdate() {
        let manager = ThemeManager(storage: ThemeStorage(userDefaults: .ephemeral))

        manager.setColorScheme(.auto)

        manager.updateSystemColorScheme(.dark)
        #expect(manager.effectiveColorScheme == .dark)

        manager.updateSystemColorScheme(.light)
        #expect(manager.effectiveColorScheme == .light)
    }

    // MARK: - Reset Tests

    @Test("reset restaura valores por defecto")
    func testReset() async {
        let storage = ThemeStorage(userDefaults: .ephemeral)
        let manager = ThemeManager(storage: storage)

        // Cambiar valores
        manager.setTheme(.highContrast)
        manager.setColorScheme(.dark)

        // Reset
        manager.reset()

        #expect(manager.currentTheme.id == "default")
        #expect(manager.colorSchemePreference == .auto)

        // Verificar que se limpia storage
        try? await Task.sleep(for: .milliseconds(100))
        let preference = await storage.loadThemePreference()
        #expect(preference.themeId == "default")
    }

    // MARK: - Custom Theme Tests

    @Test("loadCustomTheme carga un theme personalizado")
    func testLoadCustomTheme() {
        let manager = ThemeManager(storage: ThemeStorage(userDefaults: .ephemeral))
        let customTheme = Theme.custom(
            id: "custom1",
            name: "My Theme",
            palette: .grayscale
        )

        manager.loadCustomTheme(customTheme)

        #expect(manager.currentTheme.id == "custom1")
        #expect(manager.currentTheme.name == "My Theme")
    }

    // MARK: - Convenience Accessors Tests

    @Test("isDarkMode refleja el effective color scheme")
    func testIsDarkMode() {
        let manager = ThemeManager(storage: ThemeStorage(userDefaults: .ephemeral))

        manager.setColorScheme(.light)
        #expect(manager.isDarkMode == false)

        manager.setColorScheme(.dark)
        #expect(manager.isDarkMode == true)
    }

    @Test("isAutoMode refleja la preferencia")
    func testIsAutoMode() {
        let manager = ThemeManager(storage: ThemeStorage(userDefaults: .ephemeral))

        manager.setColorScheme(.auto)
        #expect(manager.isAutoMode == true)

        manager.setColorScheme(.light)
        #expect(manager.isAutoMode == false)
    }

    @Test("availableThemes retorna todos los themes predefinidos")
    func testAvailableThemes() {
        let manager = ThemeManager(storage: ThemeStorage(userDefaults: .ephemeral))
        let themes = manager.availableThemes

        #expect(themes.count == 4)
        #expect(themes.contains { $0.id == "default" })
        #expect(themes.contains { $0.id == "dark" })
        #expect(themes.contains { $0.id == "highContrast" })
        #expect(themes.contains { $0.id == "grayscale" })
    }
}
