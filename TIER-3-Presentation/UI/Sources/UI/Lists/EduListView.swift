import SwiftUI
import StateManagement

public enum ViewState<T>: Sendable where T: Sendable {
    case loading
    case success(T)
    case error(String)
    case empty
}

@MainActor
public struct EduListView<Item, Content: View>: View where Item: Sendable {
    private let state: ViewState<[Item]>
    private let emptyTitle: String
    private let emptyDescription: String
    private let onRetry: (() -> Void)?
    private let content: (Item) -> Content
    
    public init(
        state: ViewState<[Item]>,
        emptyTitle: String = "Sin resultados",
        emptyDescription: String = "No hay elementos para mostrar",
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.state = state
        self.emptyTitle = emptyTitle
        self.emptyDescription = emptyDescription
        self.onRetry = onRetry
        self.content = content
    }
    
    public var body: some View {
        Group {
            switch state {
            case .loading:
                EduLoadingStateView()
            case .success(let items):
                if items.isEmpty {
                    EduEmptyStateView(
                        title: emptyTitle,
                        description: emptyDescription
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                                content(item)
                            }
                        }
                    }
                }
            case .error(let message):
                EduErrorStateView(
                    message: message,
                    onRetry: onRetry ?? {}
                )
            case .empty:
                EduEmptyStateView(
                    title: emptyTitle,
                    description: emptyDescription
                )
            }
        }
    }
}
