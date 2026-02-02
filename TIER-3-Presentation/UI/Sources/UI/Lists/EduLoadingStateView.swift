import SwiftUI

@MainActor
public struct EduLoadingStateView: View {
    @State private var isAnimating = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding()
    }
}

private struct SkeletonRow: View {
    @State private var opacity: Double = 0.3
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(opacity))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(opacity))
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(opacity))
                    .frame(width: 200, height: 12)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                opacity = 0.6
            }
        }
    }
}
