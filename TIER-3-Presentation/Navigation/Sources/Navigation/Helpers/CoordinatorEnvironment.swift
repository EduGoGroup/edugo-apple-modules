import SwiftUI

/// EnvironmentKey para inyectar AppCoordinator en el environment de SwiftUI.
///
/// Permite acceder al coordinador desde cualquier View sin necesidad de
/// pasar explícitamente la referencia a través de la jerarquía.
///
/// # Ejemplo de uso:
/// ```swift
/// // En la raíz de la app
/// ContentView()
///     .withCoordinator(appCoordinator)
///
/// // En cualquier View hija
/// struct MyView: View {
///     @Environment(\.appCoordinator) var coordinator
///
///     var body: some View {
///         Button("Navigate") {
///             coordinator?.navigate(to: .dashboard)
///         }
///     }
/// }
/// ```
private struct AppCoordinatorKey: EnvironmentKey {
    static let defaultValue: AppCoordinator? = nil
}

extension EnvironmentValues {
    /// AppCoordinator accesible desde el environment.
    ///
    /// Permite acceder al coordinador de navegación desde cualquier View.
    /// Retorna `nil` si no se ha inyectado un coordinador en el environment.
    public var appCoordinator: AppCoordinator? {
        get { self[AppCoordinatorKey.self] }
        set { self[AppCoordinatorKey.self] = newValue }
    }
}

extension View {
    /// Inyecta un AppCoordinator en el environment de la View.
    ///
    /// Todas las Views hijas tendrán acceso al coordinador a través
    /// del environment.
    ///
    /// - Parameter coordinator: Coordinador a inyectar
    /// - Returns: View modificada con el coordinador en el environment
    ///
    /// # Ejemplo:
    /// ```swift
    /// NavigationStack {
    ///     RootView()
    /// }
    /// .withCoordinator(appCoordinator)
    /// ```
    public func withCoordinator(_ coordinator: AppCoordinator) -> some View {
        environment(\.appCoordinator, coordinator)
    }
}
