//
//  DynamicTypeTests.swift
//  EduAccessibilityTests
//
//  Test suite for DynamicTypeSupport functionality.
//
//  Test Coverage:
//  - Base size mapping for all text styles
//  - Linear, logarithmic, exponential, stepped, and clamped scaling curves
//  - Size category classification (standard vs accessibility)
//  - Scaling level calculation
//  - Alternative layout detection
//
//  Swift 6.2 strict concurrency compliant
//

import Testing
import SwiftUI
@testable import EduAccessibility

@Suite("Dynamic Type Support Tests")
struct DynamicTypeTests {

    // MARK: - Base Size Tests

    @Test("Base size for text styles")
    func testBaseSize() {
        #expect(DynamicTypeSupport.baseSize(for: .largeTitle) == 34)
        #expect(DynamicTypeSupport.baseSize(for: .title) == 28)
        #expect(DynamicTypeSupport.baseSize(for: .title2) == 22)
        #expect(DynamicTypeSupport.baseSize(for: .title3) == 20)
        #expect(DynamicTypeSupport.baseSize(for: .headline) == 17)
        #expect(DynamicTypeSupport.baseSize(for: .body) == 17)
        #expect(DynamicTypeSupport.baseSize(for: .callout) == 16)
        #expect(DynamicTypeSupport.baseSize(for: .subheadline) == 15)
        #expect(DynamicTypeSupport.baseSize(for: .footnote) == 13)
        #expect(DynamicTypeSupport.baseSize(for: .caption) == 12)
        #expect(DynamicTypeSupport.baseSize(for: .caption2) == 11)
    }

    // MARK: - Scaling Tests

    @Test("Linear scaling curve")
    func testLinearScaling() {
        let baseValue: CGFloat = 10

        // Large es el base (1.0x)
        let large = DynamicTypeSupport.scaled(baseValue, for: .large, curve: .linear)
        #expect(large == 10)

        // ExtraLarge debería ser mayor
        let extraLarge = DynamicTypeSupport.scaled(baseValue, for: .extraLarge, curve: .linear)
        #expect(extraLarge > large)

        // Small debería ser menor
        let small = DynamicTypeSupport.scaled(baseValue, for: .small, curve: .linear)
        #expect(small < large)

        // Accessibility sizes deberían ser mucho mayores
        let axLarge = DynamicTypeSupport.scaled(baseValue, for: .accessibilityLarge, curve: .linear)
        #expect(axLarge > extraLarge)
    }

    @Test("Logarithmic scaling curve")
    func testLogarithmicScaling() {
        let baseValue: CGFloat = 10

        // Para tamaño large (base), logarithmic debería ser igual al baseValue
        let logLarge = DynamicTypeSupport.scaled(baseValue, for: .large, curve: .logarithmic)
        #expect(logLarge == baseValue)

        // Para tamaños más grandes, logarithmic escala pero de forma moderada
        let logXXXL = DynamicTypeSupport.scaled(baseValue, for: .extraExtraExtraLarge, curve: .logarithmic)
        #expect(logXXXL > baseValue)

        // La curva logarítmica produce resultados consistentes
        let logAX = DynamicTypeSupport.scaled(baseValue, for: .accessibilityMedium, curve: .logarithmic)
        #expect(logAX > logXXXL)
    }

    @Test("Exponential scaling curve")
    func testExponentialScaling() {
        let baseValue: CGFloat = 10

        let linearXL = DynamicTypeSupport.scaled(baseValue, for: .extraLarge, curve: .linear)
        let expXL = DynamicTypeSupport.scaled(baseValue, for: .extraLarge, curve: .exponential)

        // Exponential debería crecer más rápido que linear
        #expect(expXL > linearXL)
    }

    @Test("Stepped scaling curve")
    func testSteppedScaling() {
        let baseValue: CGFloat = 10
        let steps: [CGFloat] = [1.0, 1.5, 2.0, 2.5]

        let small = DynamicTypeSupport.scaled(baseValue, for: .small, curve: .stepped(steps))
        let large = DynamicTypeSupport.scaled(baseValue, for: .large, curve: .stepped(steps))
        let xxl = DynamicTypeSupport.scaled(baseValue, for: .extraExtraLarge, curve: .stepped(steps))

        // Debería usar valores discretos de los steps
        #expect(small >= baseValue * steps[0])
        #expect(large >= baseValue * steps[0])
        #expect(xxl >= baseValue * steps[0])
    }

    @Test("Clamped scaling curve")
    func testClampedScaling() {
        let baseValue: CGFloat = 10
        let minValue: CGFloat = 8
        let maxValue: CGFloat = 15

        // Extra small debería estar limitado al mínimo
        let xs = DynamicTypeSupport.scaled(baseValue, for: .extraSmall, curve: .clamped(min: minValue, max: maxValue))
        #expect(xs >= minValue)

        // Accessibility XXXL debería estar limitado al máximo
        let axXXXL = DynamicTypeSupport.scaled(baseValue, for: .accessibilityExtraExtraExtraLarge, curve: .clamped(min: minValue, max: maxValue))
        #expect(axXXXL <= maxValue)

        // Large debería estar entre min y max
        let large = DynamicTypeSupport.scaled(baseValue, for: .large, curve: .clamped(min: minValue, max: maxValue))
        #expect(large >= minValue && large <= maxValue)
    }

    // MARK: - Size Category Detection Tests

    @Test("Accessibility category detection")
    func testAccessibilityCategoryDetection() {
        #expect(DynamicTypeSupport.isAccessibilityCategory(.large) == false)
        #expect(DynamicTypeSupport.isAccessibilityCategory(.extraExtraExtraLarge) == false)

        #expect(DynamicTypeSupport.isAccessibilityCategory(.accessibilityMedium) == true)
        #expect(DynamicTypeSupport.isAccessibilityCategory(.accessibilityLarge) == true)
        #expect(DynamicTypeSupport.isAccessibilityCategory(.accessibilityExtraLarge) == true)
        #expect(DynamicTypeSupport.isAccessibilityCategory(.accessibilityExtraExtraLarge) == true)
        #expect(DynamicTypeSupport.isAccessibilityCategory(.accessibilityExtraExtraExtraLarge) == true)
    }

    @Test("Scaling level mapping")
    func testScalingLevel() {
        #expect(DynamicTypeSupport.scalingLevel(for: .extraSmall) == 0)
        #expect(DynamicTypeSupport.scalingLevel(for: .small) == 1)
        #expect(DynamicTypeSupport.scalingLevel(for: .medium) == 2)
        #expect(DynamicTypeSupport.scalingLevel(for: .large) == 3)
        #expect(DynamicTypeSupport.scalingLevel(for: .extraLarge) == 4)
        #expect(DynamicTypeSupport.scalingLevel(for: .extraExtraLarge) == 5)
        #expect(DynamicTypeSupport.scalingLevel(for: .extraExtraExtraLarge) == 6)
        #expect(DynamicTypeSupport.scalingLevel(for: .accessibilityMedium) == 7)
        #expect(DynamicTypeSupport.scalingLevel(for: .accessibilityLarge) == 8)
        #expect(DynamicTypeSupport.scalingLevel(for: .accessibilityExtraLarge) == 9)
        #expect(DynamicTypeSupport.scalingLevel(for: .accessibilityExtraExtraLarge) == 10)
        #expect(DynamicTypeSupport.scalingLevel(for: .accessibilityExtraExtraExtraLarge) == 11)
    }

    @Test("Alternative layout detection")
    func testAlternativeLayoutDetection() {
        #expect(DynamicTypeSupport.shouldUseAlternativeLayout(for: .large) == false)
        #expect(DynamicTypeSupport.shouldUseAlternativeLayout(for: .extraExtraExtraLarge) == false)

        #expect(DynamicTypeSupport.shouldUseAlternativeLayout(for: .accessibilityMedium) == true)
        #expect(DynamicTypeSupport.shouldUseAlternativeLayout(for: .accessibilityExtraExtraExtraLarge) == true)
    }
}

@Suite("ContentSizeCategory Extensions Tests")
struct ContentSizeCategoryExtensionsTests {

    // MARK: - Category Information Tests

    @Test("Is accessibility category property")
    func testIsAccessibilityCategoryProperty() {
        #expect(ContentSizeCategory.large.isAccessibilityCategory == false)
        #expect(ContentSizeCategory.accessibilityMedium.isAccessibilityCategory == true)
    }

    @Test("Scaling level property")
    func testScalingLevelProperty() {
        #expect(ContentSizeCategory.large.scalingLevel == 3)
        #expect(ContentSizeCategory.accessibilityExtraLarge.scalingLevel == 9)
    }

    @Test("Should use alternative layout property")
    func testShouldUseAlternativeLayoutProperty() {
        #expect(ContentSizeCategory.large.shouldUseAlternativeLayout == false)
        #expect(ContentSizeCategory.accessibilityMedium.shouldUseAlternativeLayout == true)
    }

    // MARK: - Scaling Helper Tests

    @Test("Scaled method")
    func testScaledMethod() {
        let baseValue: CGFloat = 10
        let large = ContentSizeCategory.large

        let scaled = large.scaled(baseValue)
        #expect(scaled == 10)  // Large es el base
    }

    @Test("Scaled spacing method")
    func testScaledSpacingMethod() {
        let baseValue: CGFloat = 8
        let result = ContentSizeCategory.large.scaledSpacing(baseValue)
        #expect(result >= baseValue * 0.9 && result <= baseValue * 1.1)
    }

    @Test("Scaled icon size method")
    func testScaledIconSizeMethod() {
        let baseSize: CGFloat = 24
        let small = ContentSizeCategory.small.scaledIconSize(baseSize)
        let large = ContentSizeCategory.large.scaledIconSize(baseSize)
        let axLarge = ContentSizeCategory.accessibilityLarge.scaledIconSize(baseSize)

        #expect(small < large)
        #expect(large < axLarge)
    }

    // MARK: - Layout Helper Tests

    @Test("Optimal layout direction")
    func testOptimalLayoutDirection() {
        #expect(ContentSizeCategory.large.optimalLayoutDirection == .horizontal)
        #expect(ContentSizeCategory.accessibilityMedium.optimalLayoutDirection == .vertical)
    }

    @Test("Should stack method")
    func testShouldStackMethod() {
        #expect(ContentSizeCategory.large.shouldStack() == false)
        #expect(ContentSizeCategory.extraExtraExtraLarge.shouldStack() == false)
        #expect(ContentSizeCategory.accessibilityMedium.shouldStack() == true)
        #expect(ContentSizeCategory.accessibilityExtraExtraExtraLarge.shouldStack() == true)
    }

    @Test("Should stack with custom threshold")
    func testShouldStackCustomThreshold() {
        // Threshold 5 = extraExtraLarge
        #expect(ContentSizeCategory.extraLarge.shouldStack(threshold: 5) == false)
        #expect(ContentSizeCategory.extraExtraLarge.shouldStack(threshold: 5) == true)
        #expect(ContentSizeCategory.accessibilityMedium.shouldStack(threshold: 5) == true)
    }

    @Test("Grid columns calculation")
    func testGridColumnsCalculation() {
        // 4 columnas por defecto
        #expect(ContentSizeCategory.large.gridColumns(default: 4) == 4)
        #expect(ContentSizeCategory.extraExtraLarge.gridColumns(default: 4) >= 2)
        #expect(ContentSizeCategory.accessibilityMedium.gridColumns(default: 4) == 2)
        #expect(ContentSizeCategory.accessibilityExtraLarge.gridColumns(default: 4) == 1)
    }

    @Test("Line limit calculation")
    func testLineLimitCalculation() {
        #expect(ContentSizeCategory.large.lineLimit(default: 3) == 3)
        #expect(ContentSizeCategory.accessibilityMedium.lineLimit(default: 3) == nil)  // Sin límite
    }

    @Test("Truncation mode")
    func testTruncationMode() {
        #expect(ContentSizeCategory.large.truncationMode == .tail)
        #expect(ContentSizeCategory.accessibilityMedium.truncationMode == .middle)
    }

    @Test("Minimum scale factor")
    func testMinimumScaleFactor() {
        #expect(ContentSizeCategory.large.minimumScaleFactor == 0.8)
        #expect(ContentSizeCategory.accessibilityMedium.minimumScaleFactor == 1.0)
    }

    @Test("Minimum touch target")
    func testMinimumTouchTarget() {
        #expect(ContentSizeCategory.large.minimumTouchTarget == 44)
        #expect(ContentSizeCategory.accessibilityMedium.minimumTouchTarget == 48)
    }

    // MARK: - Comparison Tests

    @Test("Comparison between categories")
    func testComparison() {
        let small = ContentSizeCategory.small
        let large = ContentSizeCategory.large
        let axLarge = ContentSizeCategory.accessibilityLarge

        #expect(small.compare(to: large) == .orderedAscending)
        #expect(large.compare(to: small) == .orderedDescending)
        #expect(large.compare(to: .large) == .orderedSame)
        #expect(large.compare(to: axLarge) == .orderedAscending)
    }

    @Test("Is smaller than")
    func testIsSmaller() {
        #expect(ContentSizeCategory.small.isSmaller(than: .large) == true)
        #expect(ContentSizeCategory.large.isSmaller(than: .small) == false)
        #expect(ContentSizeCategory.large.isSmaller(than: .accessibilityMedium) == true)
    }

    @Test("Is larger than")
    func testIsLarger() {
        #expect(ContentSizeCategory.extraLarge.isLarger(than: .large) == true)
        #expect(ContentSizeCategory.large.isLarger(than: .extraLarge) == false)
        #expect(ContentSizeCategory.accessibilityMedium.isLarger(than: .large) == true)
    }

    @Test("Is at least")
    func testIsAtLeast() {
        #expect(ContentSizeCategory.large.isAtLeast(.large) == true)
        #expect(ContentSizeCategory.extraLarge.isAtLeast(.large) == true)
        #expect(ContentSizeCategory.small.isAtLeast(.large) == false)
    }

    @Test("Is at most")
    func testIsAtMost() {
        #expect(ContentSizeCategory.large.isAtMost(.large) == true)
        #expect(ContentSizeCategory.small.isAtMost(.large) == true)
        #expect(ContentSizeCategory.extraLarge.isAtMost(.large) == false)
    }

    // MARK: - String Representation Tests

    @Test("Category names")
    func testCategoryNames() {
        #expect(ContentSizeCategory.large.name == "Large (Default)")
        #expect(ContentSizeCategory.accessibilityMedium.name == "Accessibility Medium")
    }

    @Test("Category short names")
    func testCategoryShortNames() {
        #expect(ContentSizeCategory.extraSmall.shortName == "XS")
        #expect(ContentSizeCategory.large.shortName == "L")
        #expect(ContentSizeCategory.extraExtraExtraLarge.shortName == "XXXL")
        #expect(ContentSizeCategory.accessibilityMedium.shortName == "AX-M")
        #expect(ContentSizeCategory.accessibilityExtraExtraExtraLarge.shortName == "AX-XXXL")
    }

    @Test("Description conformance")
    func testDescription() {
        let large = ContentSizeCategory.large
        #expect(large.description == large.name)
    }

    // MARK: - All Cases Tests

    @Test("Native all cases available")
    func testNativeAllCases() {
        // SwiftUI proporciona allCases nativamente
        let allCases: [ContentSizeCategory] = ContentSizeCategory.allCases
        #expect(allCases.count == 12)
    }

    @Test("Standard cases count")
    func testStandardCasesCount() {
        let standardCases = ContentSizeCategory.eduStandardCases
        #expect(standardCases.count == 7)

        for category in standardCases {
            #expect(category.isAccessibilityCategory == false)
        }
    }

    @Test("Accessibility cases count")
    func testAccessibilityCasesCount() {
        let accessibilityCases = ContentSizeCategory.eduAccessibilityCases
        #expect(accessibilityCases.count == 5)

        for category in accessibilityCases {
            #expect(category.isAccessibilityCategory == true)
        }
    }

    @Test("Category lists completeness")
    func testCategoryListsCompleteness() {
        let nativeAllCases: [ContentSizeCategory] = ContentSizeCategory.allCases
        let standardCount = ContentSizeCategory.eduStandardCases.count
        let accessibilityCount = ContentSizeCategory.eduAccessibilityCases.count

        #expect(nativeAllCases.count == standardCount + accessibilityCount)
    }
}
