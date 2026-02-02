import SwiftUI

/// Botón genérico con variantes de estilo y soporte multi-plataforma.
///
/// Características:
/// - Variantes: primary, secondary, destructive, link
/// - Estados: normal, loading, disabled
/// - Iconos opcionales (leading o trailing)
/// - Adaptación automática por plataforma
/// - Tamaños configurables
@MainActor
public struct EduButton: View {
    // MARK: - Types

    public enum Style {
        case primary
        case secondary
        case destructive
        case link
    }

    public enum Size {
        case small
        case medium
        case large

        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .medium:
                return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
            case .large:
                return EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
            }
        }

        var fontSize: Font {
            switch self {
            case .small:
                return .caption
            case .medium:
                return .body
            case .large:
                return .title3
            }
        }
    }

    public enum IconPosition {
        case leading
        case trailing
    }

    // MARK: - Properties

    private let title: String
    private let icon: String?
    private let iconPosition: IconPosition
    private let style: Style
    private let size: Size
    private let isLoading: Bool
    private let isDisabled: Bool
    private let action: () -> Void

    // MARK: - Initializer

    /// Inicializa un EduButton con todas las opciones de personalización.
    ///
    /// - Parameters:
    ///   - title: Texto del botón
    ///   - icon: Nombre del SF Symbol opcional
    ///   - iconPosition: Posición del icono (leading o trailing)
    ///   - style: Estilo visual del botón
    ///   - size: Tamaño del botón
    ///   - isLoading: Si está en estado de carga (muestra spinner)
    ///   - isDisabled: Si el botón está deshabilitado
    ///   - action: Closure que se ejecuta al presionar
    public init(
        _ title: String,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        style: Style = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.iconPosition = iconPosition
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Leading icon o spinner
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else if iconPosition == .leading, let icon = icon {
                    Image(systemName: icon)
                }

                // Título
                Text(title)
                    .font(size.fontSize)
                    .fontWeight(style == .link ? .regular : .semibold)

                // Trailing icon
                if !isLoading, iconPosition == .trailing, let icon = icon {
                    Image(systemName: icon)
                }
            }
            .padding(style == .link ? EdgeInsets() : size.padding)
            .frame(maxWidth: style == .link ? nil : .infinity)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .cornerRadius(style == .link ? 0 : cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: style == .link ? 0 : cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .opacity(effectiveOpacity)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }

    // MARK: - Styling Helpers

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .accentColor
        case .destructive:
            return isDisabled ? .secondary : .red
        case .link:
            return .accentColor
        }
    }

    private var backgroundColor: Color {
        if style == .link {
            return .clear
        }

        switch style {
        case .primary:
            return .accentColor
        case .secondary:
            return .clear
        case .destructive:
            return .clear
        case .link:
            return .clear
        }
    }

    private var borderColor: Color {
        if style == .link {
            return .clear
        }

        switch style {
        case .primary:
            return .clear
        case .secondary:
            return .accentColor
        case .destructive:
            return isDisabled ? .secondary.opacity(0.3) : .red
        case .link:
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .primary, .link:
            return 0
        case .secondary, .destructive:
            return 2
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small:
            return 6
        case .medium:
            return 8
        case .large:
            return 10
        }
    }

    private var effectiveOpacity: Double {
        if isDisabled {
            return 0.5
        }
        return 1.0
    }
}

// MARK: - Convenience Initializers

extension EduButton {
    /// Crea un botón primary sin icono.
    public static func primary(
        _ title: String,
        size: Size = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> EduButton {
        EduButton(
            title,
            style: .primary,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }

    /// Crea un botón secondary sin icono.
    public static func secondary(
        _ title: String,
        size: Size = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> EduButton {
        EduButton(
            title,
            style: .secondary,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }

    /// Crea un botón destructive sin icono.
    public static func destructive(
        _ title: String,
        size: Size = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> EduButton {
        EduButton(
            title,
            style: .destructive,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }

    /// Crea un botón link sin icono.
    public static func link(
        _ title: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> EduButton {
        EduButton(
            title,
            style: .link,
            size: .medium,
            isLoading: false,
            isDisabled: isDisabled,
            action: action
        )
    }
}

// MARK: - Previews

#Preview("Todos los estilos") {
    VStack(spacing: 16) {
        EduButton.primary("Primary Button") { }
        EduButton.secondary("Secondary Button") { }
        EduButton.destructive("Destructive Button") { }
        EduButton.link("Link Button") { }
    }
    .padding()
}

#Preview("Todos los tamaños") {
    VStack(spacing: 16) {
        EduButton.primary("Small", size: .small) { }
        EduButton.primary("Medium", size: .medium) { }
        EduButton.primary("Large", size: .large) { }
    }
    .padding()
}

#Preview("Con iconos") {
    VStack(spacing: 16) {
        EduButton(
            "Leading Icon",
            icon: "arrow.right",
            iconPosition: .leading,
            style: .primary
        ) { }

        EduButton(
            "Trailing Icon",
            icon: "arrow.right",
            iconPosition: .trailing,
            style: .secondary
        ) { }

        EduButton(
            "Delete",
            icon: "trash",
            style: .destructive
        ) { }
    }
    .padding()
}

#Preview("Estados: Loading") {
    VStack(spacing: 16) {
        EduButton.primary("Loading...", isLoading: true) { }
        EduButton.secondary("Processing...", isLoading: true) { }
        EduButton.destructive("Deleting...", isLoading: true) { }
    }
    .padding()
}

#Preview("Estados: Disabled") {
    VStack(spacing: 16) {
        EduButton.primary("Disabled", isDisabled: true) { }
        EduButton.secondary("Disabled", isDisabled: true) { }
        EduButton.destructive("Disabled", isDisabled: true) { }
        EduButton.link("Disabled", isDisabled: true) { }
    }
    .padding()
}

#Preview("Botón en formulario") {
    @Previewable @State var isSubmitting = false

    VStack(spacing: 24) {
        Text("Formulario de Ejemplo")
            .font(.title2)
            .fontWeight(.bold)

        VStack(spacing: 12) {
            Text("Campo 1")
            Text("Campo 2")
            Text("Campo 3")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(white: 0.95))
        .cornerRadius(12)

        EduButton(
            "Enviar Formulario",
            icon: "checkmark",
            style: .primary,
            isLoading: isSubmitting
        ) {
            isSubmitting = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                isSubmitting = false
            }
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        EduButton.primary("Primary") { }
        EduButton.secondary("Secondary") { }
        EduButton.destructive("Destructive") { }
        EduButton.link("Link") { }
    }
    .padding()
    .preferredColorScheme(.dark)
}
