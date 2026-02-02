import SwiftUI

// MARK: - Tab Item

/// Representa un item del TabBar
@MainActor
public struct EduTabItem: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let icon: String
    public let selectedIcon: String?
    public let badge: String?

    public init(
        id: String,
        title: String,
        icon: String,
        selectedIcon: String? = nil,
        badge: String? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.badge = badge
    }
}

// MARK: - Tab Bar

/// TabBar customizado multi-plataforma
@MainActor
public struct EduTabBar<Content: View>: View {
    @Binding private var selection: String
    private let items: [EduTabItem]
    private let content: (String) -> Content

    public init(
        selection: Binding<String>,
        items: [EduTabItem],
        @ViewBuilder content: @escaping (String) -> Content
    ) {
        self._selection = selection
        self.items = items
        self.content = content
    }

    public var body: some View {
        #if os(iOS) || os(visionOS)
        TabView(selection: $selection) {
            ForEach(items) { item in
                content(item.id)
                    .tabItem {
                        Label(item.title, systemImage: selection == item.id ? (item.selectedIcon ?? item.icon) : item.icon)
                    }
                    .badge(item.badge)
                    .tag(item.id)
            }
        }
        #elseif os(macOS)
        NavigationSplitView {
            List(items, selection: $selection) { item in
                HStack {
                    Image(systemName: selection == item.id ? (item.selectedIcon ?? item.icon) : item.icon)
                        .foregroundStyle(selection == item.id ? Color.accentColor : Color.secondary)
                    Text(item.title)
                        .foregroundStyle(selection == item.id ? Color.primary : Color.secondary)
                    Spacer()
                    if let badge = item.badge {
                        Text(badge)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .contentShape(Rectangle())
                .tag(item.id)
            }
            .listStyle(.sidebar)
            .navigationTitle("Navegación")
        } detail: {
            content(selection)
        }
        #endif
    }
}

// MARK: - Custom Tab Bar Style

#if os(iOS) || os(visionOS)
/// Estilo personalizable para el TabBar
public enum EduTabBarStyle: Sendable {
    case automatic
    case transparent
    case opaque
}

extension View {
    /// Aplica un estilo personalizado al TabBar
    public func eduTabBarStyle(_ style: EduTabBarStyle) -> some View {
        self.onAppear {
            let appearance = UITabBarAppearance()

            switch style {
            case .automatic:
                appearance.configureWithDefaultBackground()
            case .transparent:
                appearance.configureWithTransparentBackground()
            case .opaque:
                appearance.configureWithOpaqueBackground()
            }

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
#endif

// MARK: - Tab Bar Coordinator

/// Coordinador para gestionar la navegación del TabBar
@MainActor
@Observable
public final class EduTabBarCoordinator: Sendable {
    public private(set) var selectedTab: String
    public private(set) var previousTab: String?

    public init(initialTab: String) {
        self.selectedTab = initialTab
    }

    /// Selecciona un tab específico
    public func select(tab: String) {
        previousTab = selectedTab
        selectedTab = tab
    }

    /// Vuelve al tab anterior si existe
    public func goBackToPreviousTab() {
        if let previous = previousTab {
            let temp = selectedTab
            selectedTab = previous
            previousTab = temp
        }
    }
}

// MARK: - Tab Bar with Coordinator

/// TabBar con coordinador integrado
@MainActor
public struct EduCoordinatedTabBar<Content: View>: View {
    @State private var coordinator: EduTabBarCoordinator
    private let items: [EduTabItem]
    private let content: (String, EduTabBarCoordinator) -> Content

    public init(
        initialTab: String,
        items: [EduTabItem],
        @ViewBuilder content: @escaping (String, EduTabBarCoordinator) -> Content
    ) {
        self._coordinator = State(initialValue: EduTabBarCoordinator(initialTab: initialTab))
        self.items = items
        self.content = content
    }

    public var body: some View {
        EduTabBar(
            selection: Binding(
                get: { coordinator.selectedTab },
                set: { coordinator.select(tab: $0) }
            ),
            items: items
        ) { tabId in
            content(tabId, coordinator)
        }
    }
}
