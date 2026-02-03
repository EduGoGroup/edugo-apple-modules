import SwiftUI

@MainActor
public struct EduErrorStateView: View {
    private let title: String
    private let message: String
    private let retryTitle: String
    private let onRetry: () -> Void

    public init(
        title: String = "Error",
        message: String,
        retryTitle: String = "Reintentar",
        onRetry: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            VStack(spacing: DesignTokens.Spacing.small) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(retryTitle, action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}

// MARK: - Previews

#Preview("Error b\u00e1sico") {
    EduErrorStateView(
        message: "No se pudo cargar la informaci\u00f3n"
    ) {
        print("Reintentando...")
    }
}

#Preview("Error de red") {
    EduErrorStateView(
        title: "Sin conexi\u00f3n",
        message: "Verifica tu conexi\u00f3n a internet e intenta nuevamente",
        retryTitle: "Reintentar conexi\u00f3n"
    ) {
        print("Reintentando conexi\u00f3n...")
    }
}

#Preview("Error personalizado") {
    EduErrorStateView(
        title: "Sesi\u00f3n expirada",
        message: "Tu sesi\u00f3n ha expirado. Por favor, inicia sesi\u00f3n nuevamente.",
        retryTitle: "Iniciar sesi\u00f3n"
    ) {
        print("Iniciando sesi\u00f3n...")
    }
}

#Preview("Dark Mode") {
    EduErrorStateView(
        message: "Ocurri\u00f3 un error inesperado"
    ) {
        print("Reintentando...")
    }
    .preferredColorScheme(.dark)
}
