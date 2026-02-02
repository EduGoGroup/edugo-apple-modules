import Foundation

/// Gestiona la persistencia de las preferencias de tema en UserDefaults.
///
/// ThemeStorage se encarga de guardar y cargar la configuración del tema
/// seleccionado por el usuario, permitiendo que la preferencia persista
/// entre sesiones de la aplicación.
///
/// ## Thread Safety
/// Este tipo es thread-safe y puede ser usado desde cualquier contexto.
///
/// ## Uso
/// ```swift
/// let storage = ThemeStorage()
/// storage.saveThemePreference(id: "dark", colorScheme: .dark)
/// let prefs = storage.loadThemePreference()
/// ```
public actor ThemeStorage {

    // MARK: - Keys

    private enum Keys {
        static let themeId = "com.edugo.theme.selectedThemeId"
        static let colorScheme = "com.edugo.theme.colorScheme"
        static let customThemeData = "com.edugo.theme.customThemeData"
    }

    // MARK: - Properties

    private let userDefaults: UserDefaults

    // MARK: - Initializer

    /// Inicializa ThemeStorage con un UserDefaults específico
    /// - Parameter userDefaults: UserDefaults a usar (por defecto .standard)
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Save Methods

    /// Guarda la preferencia de tema del usuario
    /// - Parameters:
    ///   - themeId: ID del tema seleccionado
    ///   - colorScheme: Esquema de color preferido (.light, .dark, .auto)
    public func saveThemePreference(
        id themeId: String,
        colorScheme: ColorSchemePreference
    ) {
        userDefaults.set(themeId, forKey: Keys.themeId)
        userDefaults.set(colorScheme.rawValue, forKey: Keys.colorScheme)
    }

    /// Guarda datos de un tema personalizado
    /// - Parameter data: Datos codificados del tema custom
    public func saveCustomThemeData(_ data: Data) {
        userDefaults.set(data, forKey: Keys.customThemeData)
    }

    // MARK: - Load Methods

    /// Carga la preferencia de tema guardada
    /// - Returns: Preferencia de tema o valores por defecto si no existe
    public func loadThemePreference() -> ThemePreference {
        let themeId = userDefaults.string(forKey: Keys.themeId) ?? "default"
        let colorSchemeRaw = userDefaults.string(forKey: Keys.colorScheme) ?? "auto"
        let colorScheme = ColorSchemePreference(rawValue: colorSchemeRaw) ?? .auto

        return ThemePreference(
            themeId: themeId,
            colorScheme: colorScheme
        )
    }

    /// Carga datos de tema personalizado si existen
    /// - Returns: Datos del tema custom o nil si no existe
    public func loadCustomThemeData() -> Data? {
        userDefaults.data(forKey: Keys.customThemeData)
    }

    // MARK: - Clear Methods

    /// Elimina todas las preferencias de tema guardadas
    public func clearAll() {
        userDefaults.removeObject(forKey: Keys.themeId)
        userDefaults.removeObject(forKey: Keys.colorScheme)
        userDefaults.removeObject(forKey: Keys.customThemeData)
    }

    // MARK: - Migration

    /// Migra preferencias de versiones antiguas si existen
    /// - Parameter legacyKey: Clave legacy a migrar
    public func migrateLegacyPreferences(from legacyKey: String) {
        // Si ya existe configuración nueva, no migrar
        if userDefaults.string(forKey: Keys.themeId) != nil {
            return
        }

        // Intentar migrar de versión legacy
        if let legacyValue = userDefaults.string(forKey: legacyKey) {
            // Mapear valores legacy a nuevos
            let newThemeId: String
            let newColorScheme: ColorSchemePreference

            switch legacyValue {
            case "dark":
                newThemeId = "default"
                newColorScheme = .dark
            case "light":
                newThemeId = "default"
                newColorScheme = .light
            case "auto", "system":
                newThemeId = "default"
                newColorScheme = .auto
            default:
                newThemeId = "default"
                newColorScheme = .auto
            }

            saveThemePreference(id: newThemeId, colorScheme: newColorScheme)

            // Eliminar clave legacy
            userDefaults.removeObject(forKey: legacyKey)
        }
    }
}

// MARK: - ThemePreference

/// Preferencia de tema guardada por el usuario
public struct ThemePreference: Sendable, Equatable {

    /// ID del tema seleccionado
    public let themeId: String

    /// Esquema de color preferido
    public let colorScheme: ColorSchemePreference

    public init(themeId: String, colorScheme: ColorSchemePreference) {
        self.themeId = themeId
        self.colorScheme = colorScheme
    }
}

// MARK: - ColorSchemePreference

/// Preferencia de esquema de color
public enum ColorSchemePreference: String, Sendable, CaseIterable {

    /// Modo claro forzado
    case light = "light"

    /// Modo oscuro forzado
    case dark = "dark"

    /// Automático según configuración del sistema
    case auto = "auto"

    /// Nombre legible para UI
    public var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .auto:
            return "Auto"
        }
    }
}
