import SwiftUI

@MainActor
public struct EduEmptyStateView: View {
    private let icon: String
    private let title: String
    private let description: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        icon: String = "tray",
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: DesignTokens.Spacing.small) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
    }
}

// MARK: - Previews

#Preview("Estado vac\u00edo b\u00e1sico") {
    EduEmptyStateView(
        title: "Sin resultados",
        description: "No hay elementos para mostrar"
    )
}

#Preview("Con icono personalizado") {
    EduEmptyStateView(
        icon: "magnifyingglass",
        title: "Sin resultados de b\u00fasqueda",
        description: "Intenta con otros t\u00e9rminos de b\u00fasqueda"
    )
}

#Preview("Con acci\u00f3n") {
    EduEmptyStateView(
        icon: "plus.circle",
        title: "Sin elementos",
        description: "Comienza agregando tu primer elemento",
        actionTitle: "Agregar elemento"
    ) {
        print("Acci\u00f3n ejecutada")
    }
}

#Preview("Dark Mode") {
    EduEmptyStateView(
        icon: "folder",
        title: "Carpeta vac\u00eda",
        description: "Esta carpeta no contiene archivos"
    )
    .preferredColorScheme(.dark)
}
