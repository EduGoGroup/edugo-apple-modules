import Testing
import Foundation
@testable import Theme

/// Tests para ThemeStorage.
///
/// Verifica:
/// - Guardar y cargar preferencias
/// - Persistencia en UserDefaults
/// - Migración de preferencias legacy
/// - Clear de datos
@Suite("ThemeStorage Tests")
struct ThemeStorageTests {

    // MARK: - Save and Load Tests

    @Test("saveThemePreference guarda correctamente")
    func testSaveThemePreference() async {
        let storage = ThemeStorage(userDefaults: UserDefaults.ephemeral)

        await storage.saveThemePreference(id: "dark", colorScheme: .dark)

        // Verificar cargando de vuelta
        let preference = await storage.loadThemePreference()
        #expect(preference.themeId == "dark")
        #expect(preference.colorScheme == .dark)
    }

    @Test("loadThemePreference carga correctamente")
    func testLoadThemePreference() async {
        let defaults = UserDefaults.ephemeral
        let storage = ThemeStorage(userDefaults: defaults)

        // Guardar primero
        await storage.saveThemePreference(id: "highContrast", colorScheme: .light)

        // Cargar
        let preference = await storage.loadThemePreference()

        #expect(preference.themeId == "highContrast")
        #expect(preference.colorScheme == .light)
    }

    @Test("loadThemePreference retorna default si no hay datos")
    func testLoadThemePreferenceDefault() async {
        let storage = ThemeStorage(userDefaults: UserDefaults.ephemeral)

        let preference = await storage.loadThemePreference()

        #expect(preference.themeId == "default")
        #expect(preference.colorScheme == .auto)
    }

    // MARK: - Custom Theme Data Tests

    @Test("saveCustomThemeData guarda datos binarios")
    func testSaveCustomThemeData() async {
        let storage = ThemeStorage(userDefaults: UserDefaults.ephemeral)

        let testData = "custom theme data".data(using: .utf8)!
        await storage.saveCustomThemeData(testData)

        // Verificar cargando de vuelta
        let savedData = await storage.loadCustomThemeData()
        #expect(savedData == testData)
    }

    @Test("loadCustomThemeData carga datos binarios")
    func testLoadCustomThemeData() async {
        let storage = ThemeStorage(userDefaults: UserDefaults.ephemeral)

        let testData = "test data".data(using: .utf8)!
        await storage.saveCustomThemeData(testData)

        let loadedData = await storage.loadCustomThemeData()
        #expect(loadedData == testData)
    }

    @Test("loadCustomThemeData retorna nil si no hay datos")
    func testLoadCustomThemeDataNil() async {
        let storage = ThemeStorage(userDefaults: UserDefaults.ephemeral)

        let data = await storage.loadCustomThemeData()
        #expect(data == nil)
    }

    // MARK: - Clear Tests

    @Test("clearAll elimina todas las preferencias")
    func testClearAll() async {
        let storage = ThemeStorage(userDefaults: UserDefaults.ephemeral)

        // Guardar datos
        await storage.saveThemePreference(id: "dark", colorScheme: .dark)
        await storage.saveCustomThemeData("data".data(using: .utf8)!)

        // Limpiar
        await storage.clearAll()

        // Verificar que se eliminó todo cargando de vuelta
        let preference = await storage.loadThemePreference()
        #expect(preference.themeId == "default")
        #expect(preference.colorScheme == .auto)

        let customData = await storage.loadCustomThemeData()
        #expect(customData == nil)
    }

    // MARK: - Migration Tests

    @Test("migrateLegacyPreferences migra de dark legacy")
    func testMigrateLegacyDark() async {
        let defaults = UserDefaults.ephemeral
        // Simular datos legacy ANTES de crear el storage
        defaults.set("dark", forKey: "legacy.theme")

        let storage = ThemeStorage(userDefaults: defaults)
        await storage.migrateLegacyPreferences(from: "legacy.theme")

        let preference = await storage.loadThemePreference()
        #expect(preference.themeId == "default")
        #expect(preference.colorScheme == .dark)
    }

    @Test("migrateLegacyPreferences migra de light legacy")
    func testMigrateLegacyLight() async {
        let defaults = UserDefaults.ephemeral
        defaults.set("light", forKey: "legacy.theme")

        let storage = ThemeStorage(userDefaults: defaults)
        await storage.migrateLegacyPreferences(from: "legacy.theme")

        let preference = await storage.loadThemePreference()
        #expect(preference.themeId == "default")
        #expect(preference.colorScheme == .light)
    }

    @Test("migrateLegacyPreferences migra de auto legacy")
    func testMigrateLegacyAuto() async {
        let defaults = UserDefaults.ephemeral
        defaults.set("auto", forKey: "legacy.theme")

        let storage = ThemeStorage(userDefaults: defaults)
        await storage.migrateLegacyPreferences(from: "legacy.theme")

        let preference = await storage.loadThemePreference()
        #expect(preference.themeId == "default")
        #expect(preference.colorScheme == .auto)
    }

    @Test("migrateLegacyPreferences no migra si ya hay datos nuevos")
    func testMigrateLegacySkipsIfNewDataExists() async {
        let defaults = UserDefaults.ephemeral
        defaults.set("dark", forKey: "legacy.theme")

        let storage = ThemeStorage(userDefaults: defaults)

        // Guardar datos nuevos primero
        await storage.saveThemePreference(id: "highContrast", colorScheme: .light)

        // Intentar migrar (no debería hacer nada porque ya hay datos)
        await storage.migrateLegacyPreferences(from: "legacy.theme")

        let preference = await storage.loadThemePreference()
        #expect(preference.themeId == "highContrast")
        #expect(preference.colorScheme == .light)
    }

    // MARK: - ColorSchemePreference Tests

    @Test("ColorSchemePreference tiene display names correctos")
    func testColorSchemePreferenceDisplayNames() {
        #expect(ColorSchemePreference.light.displayName == "Light")
        #expect(ColorSchemePreference.dark.displayName == "Dark")
        #expect(ColorSchemePreference.auto.displayName == "Auto")
    }

    @Test("ColorSchemePreference.allCases contiene todos los valores")
    func testColorSchemePreferenceAllCases() {
        let allCases = ColorSchemePreference.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.light))
        #expect(allCases.contains(.dark))
        #expect(allCases.contains(.auto))
    }
}

// MARK: - UserDefaults Extension for Testing

extension UserDefaults {
    /// UserDefaults efímero para testing (no persiste entre ejecuciones)
    nonisolated(unsafe) static var ephemeral: UserDefaults {
        let defaults = UserDefaults(suiteName: "com.edugo.theme.storage.tests.\(UUID().uuidString)")!
        return defaults
    }
}
