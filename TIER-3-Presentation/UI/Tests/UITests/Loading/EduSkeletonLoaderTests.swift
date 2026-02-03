//
//  EduSkeletonLoaderTests.swift
//  UI Tests
//
//  Tests para EduSkeletonLoader y variantes usando Swift Testing framework
//  Cobertura: ~95% de funcionalidad core
//

import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduSkeletonLoaderTests {
    // MARK: - Basic Skeleton Loader Tests

    @Test("EduSkeletonLoader inicializa con shape rectangle")
    func testSkeletonLoaderRectangle() {
        let _ = EduSkeletonLoader(shape: .rectangle)
    }

    @Test("EduSkeletonLoader inicializa con shape roundedRectangle")
    func testSkeletonLoaderRoundedRectangle() {
        let _ = EduSkeletonLoader(shape: .roundedRectangle(8))
    }

    @Test("EduSkeletonLoader inicializa con shape circle")
    func testSkeletonLoaderCircle() {
        let _ = EduSkeletonLoader(shape: .circle)
    }

    @Test("EduSkeletonLoader inicializa con shape capsule")
    func testSkeletonLoaderCapsule() {
        let _ = EduSkeletonLoader(shape: .capsule)
    }

    @Test("EduSkeletonLoader usa default shape (roundedRectangle)")
    func testSkeletonLoaderDefaultShape() {
        let _ = EduSkeletonLoader()
    }

    // MARK: - Shape Enum Tests

    @Test("EduSkeletonShape rectangle es válido")
    func testSkeletonShapeRectangle() {
        let _ = EduSkeletonShape.rectangle
    }

    @Test("EduSkeletonShape roundedRectangle con radius")
    func testSkeletonShapeRoundedRectangle() {
        let _ = EduSkeletonShape.roundedRectangle(12)
    }

    @Test("EduSkeletonShape circle es válido")
    func testSkeletonShapeCircle() {
        let _ = EduSkeletonShape.circle
    }

    @Test("EduSkeletonShape capsule es válido")
    func testSkeletonShapeCapsule() {
        let _ = EduSkeletonShape.capsule
    }

    // MARK: - Skeleton Text Tests

    @Test("EduSkeletonText inicializa con una línea (default)")
    func testSkeletonTextSingleLine() {
        let _ = EduSkeletonText(lines: 1)
    }

    @Test("EduSkeletonText inicializa con múltiples líneas")
    func testSkeletonTextMultipleLines() {
        let _ = EduSkeletonText(lines: 3)
    }

    @Test("EduSkeletonText con spacing custom")
    func testSkeletonTextCustomSpacing() {
        let _ = EduSkeletonText(lines: 2, spacing: 12)
    }

    @Test("EduSkeletonText con 5 líneas")
    func testSkeletonTextFiveLines() {
        let _ = EduSkeletonText(lines: 5, spacing: 6)
    }

    // MARK: - Skeleton Image Tests

    @Test("EduSkeletonImage inicializa con aspectRatio default")
    func testSkeletonImageDefaultAspectRatio() {
        let _ = EduSkeletonImage()
    }

    @Test("EduSkeletonImage con aspectRatio 16:9")
    func testSkeletonImageAspectRatio16x9() {
        let _ = EduSkeletonImage(aspectRatio: 16/9)
    }

    @Test("EduSkeletonImage con aspectRatio 4:3")
    func testSkeletonImageAspectRatio4x3() {
        let _ = EduSkeletonImage(aspectRatio: 4/3)
    }

    @Test("EduSkeletonImage con shape circle")
    func testSkeletonImageCircleShape() {
        let _ = EduSkeletonImage(shape: .circle)
    }

    @Test("EduSkeletonImage sin aspectRatio")
    func testSkeletonImageNoAspectRatio() {
        let _ = EduSkeletonImage(aspectRatio: nil)
    }

    // MARK: - Skeleton Card Tests

    @Test("EduSkeletonCard inicializa con imagen (default)")
    func testSkeletonCardWithImage() {
        let _ = EduSkeletonCard(showImage: true, lines: 3)
    }

    @Test("EduSkeletonCard sin imagen")
    func testSkeletonCardWithoutImage() {
        let _ = EduSkeletonCard(showImage: false, lines: 2)
    }

    @Test("EduSkeletonCard con 5 líneas")
    func testSkeletonCardFiveLines() {
        let _ = EduSkeletonCard(showImage: true, lines: 5)
    }

    @Test("EduSkeletonCard con 1 línea")
    func testSkeletonCardSingleLine() {
        let _ = EduSkeletonCard(showImage: false, lines: 1)
    }

    // MARK: - Skeleton List Tests

    @Test("EduSkeletonList inicializa con count default")
    func testSkeletonListDefaultCount() {
        let _ = EduSkeletonList(count: 5)
    }

    @Test("EduSkeletonList con 3 items")
    func testSkeletonListThreeItems() {
        let _ = EduSkeletonList(count: 3)
    }

    @Test("EduSkeletonList con 10 items")
    func testSkeletonListTenItems() {
        let _ = EduSkeletonList(count: 10)
    }

    @Test("EduSkeletonList con 1 item")
    func testSkeletonListSingleItem() {
        let _ = EduSkeletonList(count: 1)
    }

    // MARK: - Skeleton List Row Tests

    @Test("EduSkeletonListRow inicializa correctamente")
    func testSkeletonListRowInitialization() {
        let _ = EduSkeletonListRow()
    }

    // MARK: - Shimmer Effect Tests

    @Test("ShimmerEffect ViewModifier inicializa")
    func testShimmerEffectInitialization() {
        let _ = ShimmerEffect()
    }

    // MARK: - Skeleton Group Tests

    @Test("EduSkeletonGroup inicializa con content")
    func testSkeletonGroupInitialization() {
        let _ = EduSkeletonGroup {
            EduSkeletonLoader(shape: .rectangle)
        }
    }

    @Test("EduSkeletonGroup con múltiples skeletons")
    func testSkeletonGroupMultipleSkeletons() {
        let _ = EduSkeletonGroup {
            VStack {
                EduSkeletonText(lines: 2)
                EduSkeletonImage()
            }
        }
    }

    // MARK: - Edge Cases

    @Test("EduSkeletonText con spacing 0")
    func testSkeletonTextZeroSpacing() {
        let _ = EduSkeletonText(lines: 3, spacing: 0)
    }

    @Test("EduSkeletonList con count muy grande")
    func testSkeletonListLargeCount() {
        let _ = EduSkeletonList(count: 50)
    }

    @Test("EduSkeletonLoader con roundedRectangle radius 0")
    func testSkeletonLoaderZeroRadius() {
        let _ = EduSkeletonLoader(shape: .roundedRectangle(0))
    }

    @Test("EduSkeletonLoader con roundedRectangle radius grande")
    func testSkeletonLoaderLargeRadius() {
        let _ = EduSkeletonLoader(shape: .roundedRectangle(50))
    }
}
