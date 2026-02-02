import SwiftUI

/// ViewModifier que configura la barra de navegación con botón de retroceso automático.
///
/// Simplifica la configuración de navigation bars proporcionando:
/// - Título configurable con display mode
/// - Botón de retroceso automático basado en estado del coordinador
/// - Botón trailing opcional con acción personalizada
///
/// # Ejemplo de uso:
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         Content()
///             .navigationBar(
///                 title: "Mi Pantalla",
///                 showBackButton: true,
///                 trailingIcon: "gearshape.fill",
///                 trailingAction: { /* acción */ }
///             )
///     }
/// }
/// ```
public struct NavigationBarModifier: ViewModifier {
    let title: String
    let showBackButton: Bool
    let trailingAction: (() -> Void)?
    let trailingIcon: String?

    @Environment(\.appCoordinator) private var coordinator

    public func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                if showBackButton, let coordinator = coordinator, coordinator.canGoBack {
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            coordinator.goBack()
                        } label: {
                            Label("Atrás", systemImage: "chevron.left")
                        }
                    }
                    #else
                    ToolbarItem(placement: .navigation) {
                        Button {
                            coordinator.goBack()
                        } label: {
                            Label("Atrás", systemImage: "chevron.left")
                        }
                    }
                    #endif
                }

                if let trailingAction, let trailingIcon {
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: trailingAction) {
                            Image(systemName: trailingIcon)
                        }
                    }
                    #else
                    ToolbarItem(placement: .automatic) {
                        Button(action: trailingAction) {
                            Image(systemName: trailingIcon)
                        }
                    }
                    #endif
                }
            }
    }
}

extension View {
    /// Configura la barra de navegación con título y botones opcionales.
    ///
    /// - Parameters:
    ///   - title: Título a mostrar en la navigation bar
    ///   - showBackButton: Si mostrar botón de retroceso automático (default: true)
    ///   - trailingIcon: Nombre del SF Symbol para botón trailing (opcional)
    ///   - trailingAction: Acción al presionar botón trailing (opcional)
    /// - Returns: View modificada con navigation bar configurada
    ///
    /// # Ejemplo:
    /// ```swift
    /// MyView()
    ///     .navigationBar(
    ///         title: "Dashboard",
    ///         showBackButton: false,
    ///         trailingIcon: "gearshape.fill",
    ///         trailingAction: { showSettings() }
    ///     )
    /// ```
    public func navigationBar(
        title: String,
        showBackButton: Bool = true,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil
    ) -> some View {
        modifier(NavigationBarModifier(
            title: title,
            showBackButton: showBackButton,
            trailingAction: trailingAction,
            trailingIcon: trailingIcon
        ))
    }
}
