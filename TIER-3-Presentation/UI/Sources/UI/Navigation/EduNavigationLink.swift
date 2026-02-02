import SwiftUI

// MARK: - Lazy Navigation Link

/// NavigationLink mejorado con lazy loading
@MainActor
public struct EduNavigationLink<Label: View, Destination: View>: View {
    private let destination: () -> Destination
    private let label: () -> Label
    private let isActive: Bool

    public init(
        isActive: Bool = true,
        @ViewBuilder destination: @escaping () -> Destination,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.isActive = isActive
        self.destination = destination
        self.label = label
    }

    public var body: some View {
        if isActive {
            NavigationLink {
                LazyView(destination)
            } label: {
                label()
            }
        } else {
            label()
                .disabled(true)
                .opacity(0.6)
        }
    }
}

// MARK: - Lazy View Wrapper

/// Wrapper para lazy loading de vistas
@MainActor
private struct LazyView<Content: View>: View {
    private let build: () -> Content

    init(_ build: @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

// MARK: - String-Based Navigation Link

/// NavigationLink que navega usando strings (útil con coordinadores)
@MainActor
public struct EduNavigationLinkValue<Label: View>: View {
    private let value: String
    private let label: () -> Label

    public init(
        value: String,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.value = value
        self.label = label
    }

    public var body: some View {
        NavigationLink(value: value) {
            label()
        }
    }
}

// MARK: - Navigation Link with Analytics

/// NavigationLink con tracking de navegación
@MainActor
public struct EduTrackedNavigationLink<Label: View, Destination: View>: View {
    private let destination: () -> Destination
    private let label: () -> Label
    private let trackingId: String
    private let onNavigate: (@Sendable (String) -> Void)?

    public init(
        trackingId: String,
        onNavigate: (@Sendable (String) -> Void)? = nil,
        @ViewBuilder destination: @escaping () -> Destination,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.trackingId = trackingId
        self.onNavigate = onNavigate
        self.destination = destination
        self.label = label
    }

    public var body: some View {
        NavigationLink {
            LazyView(destination)
                .onAppear {
                    onNavigate?(trackingId)
                }
        } label: {
            label()
        }
    }
}

// MARK: - Styled Navigation Link

/// NavigationLink con estilos predefinidos
@MainActor
public struct EduStyledNavigationLink<Destination: View>: View {
    private let title: String
    private let subtitle: String?
    private let icon: String?
    private let badge: String?
    private let destination: () -> Destination
    private let style: Style

    public enum Style: Sendable {
        case plain
        case card
        case row
    }

    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        badge: String? = nil,
        style: Style = .row,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.badge = badge
        self.style = style
        self.destination = destination
    }

    public var body: some View {
        NavigationLink {
            LazyView(destination)
        } label: {
            switch style {
            case .plain:
                plainView
            case .card:
                cardView
            case .row:
                rowView
            }
        }
    }

    @ViewBuilder
    private var plainView: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
            }
            Text(title)
            Spacer()
            if let badge {
                Text(badge)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var cardView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(white: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var rowView: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let badge {
                Text(badge)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Navigation Router

/// Router para gestionar navegación basada en destinos
@MainActor
@Observable
public final class EduNavigationRouter: Sendable {
    public enum Destination: Hashable, Sendable {
        case detail(id: String)
        case settings
        case profile
        case custom(String)
    }

    public private(set) var path: [Destination] = []

    public init() {}

    /// Navega a un destino
    public func navigate(to destination: Destination) {
        path.append(destination)
    }

    /// Vuelve atrás
    public func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    /// Vuelve a la raíz
    public func goToRoot() {
        path.removeAll()
    }

    /// Navega a una ruta específica
    public func navigate(to route: [Destination]) {
        path = route
    }
}
