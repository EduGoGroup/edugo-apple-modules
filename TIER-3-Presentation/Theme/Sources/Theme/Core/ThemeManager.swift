import SwiftUI
import Observation

/// Gestor centralizado del tema de la aplicación.
///
/// ThemeManager es un actor observable que gestiona el tema activo,
/// las preferencias del usuario y la sincronización con el esquema de color del sistema.
///
/// ## Thread Safety
/// ThemeManager es un actor, garantizando acceso thread-safe a todas sus propiedades
/// y métodos desde cualquier contexto.
///
/// ## Observation
/// Marcado con @Observable, permitiendo que las vistas SwiftUI se actualicen
/// automáticamente cuando cambia el tema.
///
/// ## Uso
/// ```swift
/// let manager = ThemeManager.shared
/// await manager.setTheme(.dark)
/// await manager.setColorScheme(.auto)
/// ```
@Observable
public final class ThemeManager {

    // MARK: - Singleton

    /// Instancia compartida del ThemeManager
    ///
    /// Nota: La carga de preferencias se debe llamar explícitamente con `loadInitialPreferences()`
    /// después de obtener la instancia shared.
    @MainActor
    public static let shared: ThemeManager = ThemeManager()

    // MARK: - Published Properties

    /// Tema actual de la aplicación
    public private(set) var currentTheme: Theme

    /// Esquema de color preferido por el usuario
    public private(set) var colorSchemePreference: ColorSchemePreference

    /// Esquema de color efectivo (resuelto según preferencia y sistema)
    public private(set) var effectiveColorScheme: ColorScheme

    // MARK: - Private Properties

    private let storage: ThemeStorage
    private var systemColorScheme: ColorScheme = .light

    // MARK: - Initializer

    /// Inicializa el ThemeManager
    /// - Parameter storage: Storage para persistencia (inyectable para testing)
    public init(storage: ThemeStorage = ThemeStorage()) {
        self.storage = storage
        self.currentTheme = .default
        self.colorSchemePreference = .auto
        self.effectiveColorScheme = .light
    }

    /// Carga las preferencias iniciales desde el storage
    @MainActor
    public func loadInitialPreferences() async {
        let preference = await storage.loadThemePreference()
        applyPreference(preference)
    }

    // MARK: - Public Methods

    /// Cambia el tema activo
    /// - Parameter theme: Nuevo tema a aplicar
    @MainActor
    public func setTheme(_ theme: Theme) {
        currentTheme = theme

        // Persistir cambio
        Task {
            await storage.saveThemePreference(
                id: theme.id,
                colorScheme: colorSchemePreference
            )
        }
    }

    /// Cambia la preferencia de esquema de color
    /// - Parameter preference: Nueva preferencia (.light, .dark, .auto)
    @MainActor
    public func setColorScheme(_ preference: ColorSchemePreference) {
        colorSchemePreference = preference
        updateEffectiveColorScheme()

        // Persistir cambio
        Task {
            await storage.saveThemePreference(
                id: currentTheme.id,
                colorScheme: preference
            )
        }
    }

    /// Actualiza el esquema de color del sistema
    /// - Parameter systemScheme: Esquema detectado del sistema
    @MainActor
    public func updateSystemColorScheme(_ systemScheme: ColorScheme) {
        systemColorScheme = systemScheme
        updateEffectiveColorScheme()
    }

    /// Restaura la configuración a valores por defecto
    @MainActor
    public func reset() {
        currentTheme = .default
        colorSchemePreference = .auto
        effectiveColorScheme = systemColorScheme

        // Limpiar persistencia
        Task {
            await storage.clearAll()
        }
    }

    /// Carga un tema personalizado
    /// - Parameter theme: Tema custom a cargar
    @MainActor
    public func loadCustomTheme(_ theme: Theme) {
        currentTheme = theme

        // Persistir tema custom
        Task {
            await storage.saveThemePreference(
                id: theme.id,
                colorScheme: colorSchemePreference
            )
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func applyPreference(_ preference: ThemePreference) {
        // Buscar tema por ID
        let theme = themeForId(preference.themeId)
        currentTheme = theme
        colorSchemePreference = preference.colorScheme
        updateEffectiveColorScheme()
    }

    @MainActor
    private func updateEffectiveColorScheme() {
        switch colorSchemePreference {
        case .light:
            effectiveColorScheme = .light
        case .dark:
            effectiveColorScheme = .dark
        case .auto:
            effectiveColorScheme = systemColorScheme
        }
    }

    private func themeForId(_ id: String) -> Theme {
        switch id {
        case "default":
            return .default
        case "dark":
            return .dark
        case "highContrast":
            return .highContrast
        case "grayscale":
            return .grayscale
        default:
            return .default
        }
    }
}

// MARK: - Convenience Accessors

extension ThemeManager {

    /// Indica si está usando dark mode actualmente
    public var isDarkMode: Bool {
        effectiveColorScheme == .dark
    }

    /// Indica si está en modo automático
    public var isAutoMode: Bool {
        colorSchemePreference == .auto
    }

    /// Temas predefinidos disponibles
    public var availableThemes: [Theme] {
        [.default, .dark, .highContrast, .grayscale]
    }
}
