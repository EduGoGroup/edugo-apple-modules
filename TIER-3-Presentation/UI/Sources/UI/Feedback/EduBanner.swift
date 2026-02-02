import SwiftUI

@MainActor
public struct EduBanner: View {
    let message: String
    let style: ToastStyle
    let onDismiss: (() -> Void)?
    
    public init(message: String, style: ToastStyle = .info, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.style = style
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: style.icon)
                .foregroundStyle(style.color)
            Text(message)
                .font(.body)
            Spacer()
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(style.color.opacity(0.1))
    }
}
