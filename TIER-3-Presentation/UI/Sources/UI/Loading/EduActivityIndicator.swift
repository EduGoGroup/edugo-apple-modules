import SwiftUI

// MARK: - Activity Indicator Style

/// Estilos disponibles para el activity indicator
public enum EduActivityIndicatorStyle: Sendable {
    case small
    case medium
    case large

    #if os(iOS) || os(visionOS)
    var uiStyle: UIActivityIndicatorView.Style {
        switch self {
        case .small: return .medium
        case .medium: return .medium
        case .large: return .large
        }
    }
    #endif
}

// MARK: - Activity Indicator

/// Activity Indicator adaptativo por plataforma con accessibility
@MainActor
public struct EduActivityIndicator: View {
    private let style: EduActivityIndicatorStyle
    private let color: Color?

    public init(style: EduActivityIndicatorStyle = .medium, color: Color? = nil) {
        self.style = style
        self.color = color
    }

    public var body: some View {
        #if os(iOS) || os(visionOS)
        ProgressView()
            .progressViewStyle(.circular)
            .scaleEffect(scaleForStyle)
            .tint(color)
            .accessibilityLabel("Loading")
            .accessibilityAddTraits(.updatesFrequently)
        #elseif os(macOS)
        ProgressView()
            .progressViewStyle(.circular)
            .controlSize(controlSizeForStyle)
            .tint(color)
            .accessibilityLabel("Loading")
            .accessibilityAddTraits(.updatesFrequently)
        #endif
    }

    private var scaleForStyle: CGFloat {
        switch style {
        case .small: return 0.8
        case .medium: return 1.0
        case .large: return 1.5
        }
    }

    #if os(macOS)
    private var controlSizeForStyle: ControlSize {
        switch style {
        case .small: return .small
        case .medium: return .regular
        case .large: return .large
        }
    }
    #endif
}

// MARK: - Loading Overlay Modifier

/// Modifier para mostrar un loading overlay sobre una vista
@MainActor
public struct LoadingOverlayModifier: ViewModifier {
    private let isLoading: Bool
    private let message: String?
    private let style: EduActivityIndicatorStyle

    public init(isLoading: Bool, message: String? = nil, style: EduActivityIndicatorStyle = .medium) {
        self.isLoading = isLoading
        self.message = message
        self.style = style
    }

    public func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)

            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: DesignTokens.Spacing.large) {
                    EduActivityIndicator(style: style, color: .white)

                    if let message {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }
                .padding(DesignTokens.Spacing.xxl)
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
            }
        }
    }
}

extension View {
    /// Aplica un loading overlay a la vista
    public func loadingOverlay(isLoading: Bool, message: String? = nil, style: EduActivityIndicatorStyle = .medium) -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message, style: style))
    }
}

// MARK: - Inline Loading

/// Loading inline para uso dentro de botones u otros componentes
@MainActor
public struct EduInlineLoader: View {
    private let style: EduActivityIndicatorStyle
    private let tint: Color?

    public init(style: EduActivityIndicatorStyle = .small, tint: Color? = nil) {
        self.style = style
        self.tint = tint
    }

    public var body: some View {
        EduActivityIndicator(style: style, color: tint)
            .frame(width: sizeForStyle, height: sizeForStyle)
    }

    private var sizeForStyle: CGFloat {
        switch style {
        case .small: return DesignTokens.IconSize.small
        case .medium: return DesignTokens.IconSize.medium
        case .large: return DesignTokens.IconSize.large
        }
    }
}

// MARK: - Previews

#Preview("Tamaños") {
    VStack(spacing: 32) {
        EduActivityIndicator(style: .small)
        EduActivityIndicator(style: .medium)
        EduActivityIndicator(style: .large)
    }
    .padding()
}

#Preview("Con color personalizado") {
    VStack(spacing: 32) {
        EduActivityIndicator(style: .medium, color: .blue)
        EduActivityIndicator(style: .medium, color: .green)
        EduActivityIndicator(style: .medium, color: .orange)
    }
    .padding()
}

#Preview("Loading Overlay") {
    VStack {
        Text("Contenido de la vista")
            .font(.title)
        Text("Este contenido está detrás del overlay")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .modifier(LoadingOverlayModifier(isLoading: true, message: "Cargando...", style: .medium))
}

#Preview("Loading Overlay sin mensaje") {
    Text("Contenido")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(LoadingOverlayModifier(isLoading: true, message: nil, style: .medium))
}

#Preview("Inline Loader") {
    HStack(spacing: 16) {
        EduInlineLoader(style: .small)
        Text("Procesando...")
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 32) {
        EduActivityIndicator(style: .small)
        EduActivityIndicator(style: .medium)
        EduActivityIndicator(style: .large)
    }
    .padding()
    .preferredColorScheme(.dark)
}
