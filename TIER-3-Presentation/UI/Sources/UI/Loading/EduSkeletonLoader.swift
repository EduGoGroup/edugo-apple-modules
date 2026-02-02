import SwiftUI

// MARK: - Skeleton Shape

/// Formas disponibles para skeleton loaders
public enum EduSkeletonShape: Sendable {
    case rectangle
    case roundedRectangle(CGFloat)
    case circle
    case capsule
}

// MARK: - Skeleton Loader

/// Skeleton loader con efecto shimmer optimizado
///
/// Usa animaciones energy-efficient y soporta accessibility.
@MainActor
public struct EduSkeletonLoader: View {
    private let shape: EduSkeletonShape
    @State private var opacity: Double = 0.3

    // Constantes para animación
    private let minOpacity: Double = 0.3
    private let maxOpacity: Double = 0.6
    private let animationDuration: Double = 0.8

    public init(shape: EduSkeletonShape = .roundedRectangle(8)) {
        self.shape = shape
    }

    public var body: some View {
        Group {
            switch shape {
            case .rectangle:
                Rectangle()
            case .roundedRectangle(let radius):
                RoundedRectangle(cornerRadius: radius)
            case .circle:
                Circle()
            case .capsule:
                Capsule()
            }
        }
        .foregroundStyle(Color(white: 0.85))
        .opacity(opacity)
        .accessibilityLabel("Loading content")
        .accessibilityAddTraits(.updatesFrequently)
        .onAppear {
            withAnimation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                opacity = maxOpacity
            }
        }
    }
}

// MARK: - Skeleton Text

/// Skeleton para texto
@MainActor
public struct EduSkeletonText: View {
    private let lines: Int
    private let spacing: CGFloat

    public init(lines: Int = 1, spacing: CGFloat = 8) {
        self.lines = lines
        self.spacing = spacing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<lines, id: \.self) { index in
                EduSkeletonLoader(shape: .capsule)
                    .frame(height: 12)
                    .frame(width: widthForLine(index))
            }
        }
    }

    private func widthForLine(_ index: Int) -> CGFloat? {
        if index == lines - 1 && lines > 1 {
            return nil // Last line takes 70% width
        }
        return nil
    }
}

// MARK: - Skeleton Image

/// Skeleton para imágenes
@MainActor
public struct EduSkeletonImage: View {
    private let aspectRatio: CGFloat?
    private let shape: EduSkeletonShape

    public init(aspectRatio: CGFloat? = 1.0, shape: EduSkeletonShape = .roundedRectangle(12)) {
        self.aspectRatio = aspectRatio
        self.shape = shape
    }

    public var body: some View {
        EduSkeletonLoader(shape: shape)
            .aspectRatio(aspectRatio, contentMode: .fit)
    }
}

// MARK: - Skeleton Card

/// Skeleton para cards
@MainActor
public struct EduSkeletonCard: View {
    private let showImage: Bool
    private let lines: Int

    public init(showImage: Bool = true, lines: Int = 3) {
        self.showImage = showImage
        self.lines = lines
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showImage {
                EduSkeletonImage(aspectRatio: 16/9)
                    .frame(height: 180)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Title
                EduSkeletonLoader(shape: .capsule)
                    .frame(height: 20)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Description lines
                EduSkeletonText(lines: lines, spacing: 6)
            }
            .padding(showImage ? 12 : 0)
        }
        .padding(16)
        .background(Color(white: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Skeleton List

/// Skeleton para listas
@MainActor
public struct EduSkeletonList: View {
    private let count: Int

    public init(count: Int = 5) {
        self.count = count
    }

    public var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { _ in
                EduSkeletonListRow()
            }
        }
    }
}

// MARK: - Skeleton List Row

/// Skeleton para row de lista
@MainActor
public struct EduSkeletonListRow: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 12) {
            EduSkeletonLoader(shape: .circle)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                EduSkeletonLoader(shape: .capsule)
                    .frame(height: 14)
                    .frame(maxWidth: 200)

                EduSkeletonLoader(shape: .capsule)
                    .frame(height: 10)
                    .frame(maxWidth: 150)
            }

            Spacer()
        }
        .padding()
        .background(Color(white: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Shimmer Effect

/// Efecto shimmer para skeleton loaders con animación energy-efficient
@MainActor
public struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    // Constantes para shimmer effect
    private let shimmerDuration: Double = 1.5
    private let shimmerDistance: CGFloat = 400
    private let shimmerOpacity: Double = 0.3

    public func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(shimmerOpacity),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: shimmerDuration).repeatForever(autoreverses: false)) {
                    phase = shimmerDistance
                }
            }
    }
}

extension View {
    /// Aplica efecto shimmer a la vista
    public func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Group

/// Grupo de skeletons con shimmer
@MainActor
public struct EduSkeletonGroup<Content: View>: View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        content()
            .shimmer()
    }
}
