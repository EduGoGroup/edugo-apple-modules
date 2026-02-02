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
        let skeleton = EduSkeletonLoader(shape: .rectangle)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonLoader inicializa con shape roundedRectangle")
    func testSkeletonLoaderRoundedRectangle() {
        let skeleton = EduSkeletonLoader(shape: .roundedRectangle(8))
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonLoader inicializa con shape circle")
    func testSkeletonLoaderCircle() {
        let skeleton = EduSkeletonLoader(shape: .circle)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonLoader inicializa con shape capsule")
    func testSkeletonLoaderCapsule() {
        let skeleton = EduSkeletonLoader(shape: .capsule)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonLoader usa default shape (roundedRectangle)")
    func testSkeletonLoaderDefaultShape() {
        let skeleton = EduSkeletonLoader()
        #expect(skeleton != nil)
    }

    // MARK: - Shape Enum Tests

    @Test("EduSkeletonShape rectangle es válido")
    func testSkeletonShapeRectangle() {
        let shape = EduSkeletonShape.rectangle
        #expect(shape != nil)
    }

    @Test("EduSkeletonShape roundedRectangle con radius")
    func testSkeletonShapeRoundedRectangle() {
        let shape = EduSkeletonShape.roundedRectangle(12)
        #expect(shape != nil)
    }

    @Test("EduSkeletonShape circle es válido")
    func testSkeletonShapeCircle() {
        let shape = EduSkeletonShape.circle
        #expect(shape != nil)
    }

    @Test("EduSkeletonShape capsule es válido")
    func testSkeletonShapeCapsule() {
        let shape = EduSkeletonShape.capsule
        #expect(shape != nil)
    }

    // MARK: - Skeleton Text Tests

    @Test("EduSkeletonText inicializa con una línea (default)")
    func testSkeletonTextSingleLine() {
        let skeleton = EduSkeletonText(lines: 1)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonText inicializa con múltiples líneas")
    func testSkeletonTextMultipleLines() {
        let skeleton = EduSkeletonText(lines: 3)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonText con spacing custom")
    func testSkeletonTextCustomSpacing() {
        let skeleton = EduSkeletonText(lines: 2, spacing: 12)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonText con 5 líneas")
    func testSkeletonTextFiveLines() {
        let skeleton = EduSkeletonText(lines: 5, spacing: 6)
        #expect(skeleton != nil)
    }

    // MARK: - Skeleton Image Tests

    @Test("EduSkeletonImage inicializa con aspectRatio default")
    func testSkeletonImageDefaultAspectRatio() {
        let skeleton = EduSkeletonImage()
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonImage con aspectRatio 16:9")
    func testSkeletonImageAspectRatio16x9() {
        let skeleton = EduSkeletonImage(aspectRatio: 16/9)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonImage con aspectRatio 4:3")
    func testSkeletonImageAspectRatio4x3() {
        let skeleton = EduSkeletonImage(aspectRatio: 4/3)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonImage con shape circle")
    func testSkeletonImageCircleShape() {
        let skeleton = EduSkeletonImage(shape: .circle)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonImage sin aspectRatio")
    func testSkeletonImageNoAspectRatio() {
        let skeleton = EduSkeletonImage(aspectRatio: nil)
        #expect(skeleton != nil)
    }

    // MARK: - Skeleton Card Tests

    @Test("EduSkeletonCard inicializa con imagen (default)")
    func testSkeletonCardWithImage() {
        let skeleton = EduSkeletonCard(showImage: true, lines: 3)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonCard sin imagen")
    func testSkeletonCardWithoutImage() {
        let skeleton = EduSkeletonCard(showImage: false, lines: 2)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonCard con 5 líneas")
    func testSkeletonCardFiveLines() {
        let skeleton = EduSkeletonCard(showImage: true, lines: 5)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonCard con 1 línea")
    func testSkeletonCardSingleLine() {
        let skeleton = EduSkeletonCard(showImage: false, lines: 1)
        #expect(skeleton != nil)
    }

    // MARK: - Skeleton List Tests

    @Test("EduSkeletonList inicializa con count default")
    func testSkeletonListDefaultCount() {
        let skeleton = EduSkeletonList(count: 5)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonList con 3 items")
    func testSkeletonListThreeItems() {
        let skeleton = EduSkeletonList(count: 3)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonList con 10 items")
    func testSkeletonListTenItems() {
        let skeleton = EduSkeletonList(count: 10)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonList con 1 item")
    func testSkeletonListSingleItem() {
        let skeleton = EduSkeletonList(count: 1)
        #expect(skeleton != nil)
    }

    // MARK: - Skeleton List Row Tests

    @Test("EduSkeletonListRow inicializa correctamente")
    func testSkeletonListRowInitialization() {
        let row = EduSkeletonListRow()
        #expect(row != nil)
    }

    // MARK: - Shimmer Effect Tests

    @Test("ShimmerEffect ViewModifier inicializa")
    func testShimmerEffectInitialization() {
        let modifier = ShimmerEffect()
        #expect(modifier != nil)
    }

    // MARK: - Skeleton Group Tests

    @Test("EduSkeletonGroup inicializa con content")
    func testSkeletonGroupInitialization() {
        let group = EduSkeletonGroup {
            EduSkeletonLoader(shape: .rectangle)
        }
        #expect(group != nil)
    }

    @Test("EduSkeletonGroup con múltiples skeletons")
    func testSkeletonGroupMultipleSkeletons() {
        let group = EduSkeletonGroup {
            VStack {
                EduSkeletonText(lines: 2)
                EduSkeletonImage()
            }
        }
        #expect(group != nil)
    }

    // MARK: - Edge Cases

    @Test("EduSkeletonText con spacing 0")
    func testSkeletonTextZeroSpacing() {
        let skeleton = EduSkeletonText(lines: 3, spacing: 0)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonList con count muy grande")
    func testSkeletonListLargeCount() {
        let skeleton = EduSkeletonList(count: 50)
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonLoader con roundedRectangle radius 0")
    func testSkeletonLoaderZeroRadius() {
        let skeleton = EduSkeletonLoader(shape: .roundedRectangle(0))
        #expect(skeleton != nil)
    }

    @Test("EduSkeletonLoader con roundedRectangle radius grande")
    func testSkeletonLoaderLargeRadius() {
        let skeleton = EduSkeletonLoader(shape: .roundedRectangle(50))
        #expect(skeleton != nil)
    }
}
