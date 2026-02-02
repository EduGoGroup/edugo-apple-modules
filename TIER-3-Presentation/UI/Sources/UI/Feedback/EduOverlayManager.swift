import SwiftUI

public struct ToastOverlayModifier: ViewModifier {
    @State private var toastManager = ToastManager.shared
    
    public func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            VStack(spacing: 8) {
                ForEach(toastManager.toasts) { toast in
                    EduToast(item: toast) {
                        toastManager.dismiss(toast)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 8)
            .animation(.spring(), value: toastManager.toasts.count)
        }
    }
}

extension View {
    public func withToasts() -> some View {
        self.modifier(ToastOverlayModifier())
    }
}
