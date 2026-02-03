//
//  ScalingTests.swift
//  EduAccessibilityTests
//
//  Test suite for ScalingMetrics functionality.
//
//  Test Coverage:
//  - Constant definitions (spacing, padding, corner radius, icons, borders, touch targets)
//  - Scaling functions (spacing, padding, corner radius, icon size, border width)
//  - Minimum touch target calculations
//  - Environment integration
//
//  Swift 6.2 strict concurrency compliant
//

import Testing
import SwiftUI
@testable import EduAccessibility

@Suite("Scaling Metrics Tests")
struct ScalingMetricsTests {

    // MARK: - Base Values Tests

    @Test("Spacing constants are defined")
    func testSpacingConstants() {
        #expect(ScalingMetrics.spacingXS == 4)
        #expect(ScalingMetrics.spacingSM == 8)
        #expect(ScalingMetrics.spacingMD == 12)
        #expect(ScalingMetrics.spacingLG == 16)
        #expect(ScalingMetrics.spacingXL == 24)
        #expect(ScalingMetrics.spacing2XL == 32)
        #expect(ScalingMetrics.spacing3XL == 48)
    }

    @Test("Padding constants are defined")
    func testPaddingConstants() {
        #expect(ScalingMetrics.paddingXS == 4)
        #expect(ScalingMetrics.paddingSM == 8)
        #expect(ScalingMetrics.paddingMD == 12)
        #expect(ScalingMetrics.paddingLG == 16)
        #expect(ScalingMetrics.paddingXL == 24)
        #expect(ScalingMetrics.padding2XL == 32)
    }

    @Test("Corner radius constants are defined")
    func testCornerRadiusConstants() {
        #expect(ScalingMetrics.cornerRadiusXS == 4)
        #expect(ScalingMetrics.cornerRadiusSM == 8)
        #expect(ScalingMetrics.cornerRadiusMD == 12)
        #expect(ScalingMetrics.cornerRadiusLG == 16)
        #expect(ScalingMetrics.cornerRadiusXL == 20)
        #expect(ScalingMetrics.cornerRadius2XL == 24)
    }

    @Test("Icon size constants are defined")
    func testIconSizeConstants() {
        #expect(ScalingMetrics.iconXS == 12)
        #expect(ScalingMetrics.iconSM == 16)
        #expect(ScalingMetrics.iconMD == 20)
        #expect(ScalingMetrics.iconLG == 24)
        #expect(ScalingMetrics.iconXL == 32)
        #expect(ScalingMetrics.icon2XL == 48)
    }

    @Test("Border width constants are defined")
    func testBorderWidthConstants() {
        #expect(ScalingMetrics.borderThin == 1)
        #expect(ScalingMetrics.borderMedium == 2)
        #expect(ScalingMetrics.borderThick == 3)
    }

    @Test("Touch target constants are defined")
    func testTouchTargetConstants() {
        #expect(ScalingMetrics.minTouchTarget == 44)
        #expect(ScalingMetrics.minAccessibilityTouchTarget == 48)
    }

    // MARK: - Scaling Function Tests

    @Test("Scaled spacing uses logarithmic curve")
    func testScaledSpacing() {
        let baseSpacing = ScalingMetrics.spacingMD

        // Large debería ser el base
        let large = ScalingMetrics.scaledSpacing(baseSpacing, for: .large)
        #expect(large == baseSpacing)

        // ExtraLarge debería ser mayor pero no linealmente
        let xl = ScalingMetrics.scaledSpacing(baseSpacing, for: .extraLarge)
        #expect(xl > large)

        // Accessibility debería ser mayor
        let axLarge = ScalingMetrics.scaledSpacing(baseSpacing, for: .accessibilityLarge)
        #expect(axLarge > xl)

        // Small debería ser menor
        let small = ScalingMetrics.scaledSpacing(baseSpacing, for: .small)
        #expect(small < large)
    }

    @Test("Scaled padding uses logarithmic curve")
    func testScaledPadding() {
        let basePadding = ScalingMetrics.paddingLG

        let large = ScalingMetrics.scaledPadding(basePadding, for: .large)
        #expect(large == basePadding)

        let xl = ScalingMetrics.scaledPadding(basePadding, for: .extraLarge)
        #expect(xl > large)

        let small = ScalingMetrics.scaledPadding(basePadding, for: .small)
        #expect(small < large)
    }

    @Test("Scaled corner radius is clamped")
    func testScaledCornerRadius() {
        let baseRadius = ScalingMetrics.cornerRadiusMD

        let large = ScalingMetrics.scaledCornerRadius(baseRadius, for: .large)
        #expect(large == baseRadius)

        let xl = ScalingMetrics.scaledCornerRadius(baseRadius, for: .extraLarge)
        #expect(xl > large)

        // Debería tener un límite máximo (no más del 150%)
        let axXXXL = ScalingMetrics.scaledCornerRadius(baseRadius, for: .accessibilityExtraExtraExtraLarge)
        #expect(axXXXL <= baseRadius * 1.5)

        // Debería tener un límite mínimo (no menos del 80%)
        let xs = ScalingMetrics.scaledCornerRadius(baseRadius, for: .extraSmall)
        #expect(xs >= baseRadius * 0.8)
    }

    @Test("Scaled icon size uses linear curve")
    func testScaledIconSize() {
        let baseSize = ScalingMetrics.iconMD

        let large = ScalingMetrics.scaledIconSize(baseSize, for: .large)
        #expect(large == baseSize)

        let xl = ScalingMetrics.scaledIconSize(baseSize, for: .extraLarge)
        #expect(xl > large)

        let small = ScalingMetrics.scaledIconSize(baseSize, for: .small)
        #expect(small < large)

        // Linear debería escalar proporcionalmente
        let axLarge = ScalingMetrics.scaledIconSize(baseSize, for: .accessibilityLarge)
        #expect(axLarge > xl * 1.3)  // Mucho mayor en accessibility
    }

    @Test("Scaled border width uses stepped curve")
    func testScaledBorderWidth() {
        let baseWidth = ScalingMetrics.borderThin

        let small = ScalingMetrics.scaledBorderWidth(baseWidth, for: .small)
        let large = ScalingMetrics.scaledBorderWidth(baseWidth, for: .large)
        let xl = ScalingMetrics.scaledBorderWidth(baseWidth, for: .extraLarge)
        let axXXXL = ScalingMetrics.scaledBorderWidth(baseWidth, for: .accessibilityExtraExtraExtraLarge)

        // Stepped debería usar valores discretos
        #expect(small >= 1.0)
        #expect(large >= 1.0)
        #expect(xl >= 1.0)
        #expect(axXXXL >= 1.0)

        // Valores más grandes deberían tener borders más gruesos
        #expect(axXXXL >= xl)
        #expect(xl >= large)
    }

    @Test("Minimum touch target varies by category")
    func testMinimumTouchTarget() {
        // Categorías estándar usan 44pt
        let large = ScalingMetrics.minimumTouchTarget(for: .large)
        #expect(large == 44)

        let xl = ScalingMetrics.minimumTouchTarget(for: .extraLarge)
        #expect(xl == 44)

        // Categorías de accesibilidad usan 48pt
        let axMedium = ScalingMetrics.minimumTouchTarget(for: .accessibilityMedium)
        #expect(axMedium == 48)

        let axXXXL = ScalingMetrics.minimumTouchTarget(for: .accessibilityExtraExtraExtraLarge)
        #expect(axXXXL == 48)
    }
}

@Suite("Scaling Metrics Environment Tests")
struct ScalingMetricsEnvironmentTests {

    @Test("Environment wrapper initialization")
    func testEnvironmentInitialization() {
        let env = ScalingMetricsEnvironment(sizeCategory: .large)
        #expect(env.sizeCategory == .large)
    }

    @Test("Environment wrapper default initialization")
    func testEnvironmentDefaultInitialization() {
        let env = ScalingMetricsEnvironment()
        #expect(env.sizeCategory == .large)
    }

    @Test("Environment computed spacing values")
    func testEnvironmentComputedSpacing() {
        let env = ScalingMetricsEnvironment(sizeCategory: .large)

        #expect(env.spacingXS == ScalingMetrics.scaledSpacing(ScalingMetrics.spacingXS, for: .large))
        #expect(env.spacingSM == ScalingMetrics.scaledSpacing(ScalingMetrics.spacingSM, for: .large))
        #expect(env.spacingMD == ScalingMetrics.scaledSpacing(ScalingMetrics.spacingMD, for: .large))
        #expect(env.spacingLG == ScalingMetrics.scaledSpacing(ScalingMetrics.spacingLG, for: .large))
        #expect(env.spacingXL == ScalingMetrics.scaledSpacing(ScalingMetrics.spacingXL, for: .large))
        #expect(env.spacing2XL == ScalingMetrics.scaledSpacing(ScalingMetrics.spacing2XL, for: .large))
        #expect(env.spacing3XL == ScalingMetrics.scaledSpacing(ScalingMetrics.spacing3XL, for: .large))
    }

    @Test("Environment computed padding values")
    func testEnvironmentComputedPadding() {
        let env = ScalingMetricsEnvironment(sizeCategory: .extraLarge)

        #expect(env.paddingXS > 0)
        #expect(env.paddingSM > 0)
        #expect(env.paddingMD > 0)
        #expect(env.paddingLG > 0)
        #expect(env.paddingXL > 0)
        #expect(env.padding2XL > 0)
    }

    @Test("Environment computed corner radius values")
    func testEnvironmentComputedCornerRadius() {
        let env = ScalingMetricsEnvironment(sizeCategory: .large)

        #expect(env.cornerRadiusXS > 0)
        #expect(env.cornerRadiusSM > 0)
        #expect(env.cornerRadiusMD > 0)
        #expect(env.cornerRadiusLG > 0)
        #expect(env.cornerRadiusXL > 0)
        #expect(env.cornerRadius2XL > 0)
    }

    @Test("Environment computed icon values")
    func testEnvironmentComputedIcons() {
        let env = ScalingMetricsEnvironment(sizeCategory: .large)

        #expect(env.iconXS > 0)
        #expect(env.iconSM > 0)
        #expect(env.iconMD > 0)
        #expect(env.iconLG > 0)
        #expect(env.iconXL > 0)
        #expect(env.icon2XL > 0)
    }

    @Test("Environment touch target value")
    func testEnvironmentTouchTarget() {
        let standardEnv = ScalingMetricsEnvironment(sizeCategory: .large)
        #expect(standardEnv.minTouchTarget == 44)

        let accessibilityEnv = ScalingMetricsEnvironment(sizeCategory: .accessibilityMedium)
        #expect(accessibilityEnv.minTouchTarget == 48)
    }

    @Test("Environment values scale with size category")
    func testEnvironmentScalingBehavior() {
        let smallEnv = ScalingMetricsEnvironment(sizeCategory: .small)
        let largeEnv = ScalingMetricsEnvironment(sizeCategory: .large)
        let axEnv = ScalingMetricsEnvironment(sizeCategory: .accessibilityExtraLarge)

        // Spacing debería crecer con el tamaño
        #expect(smallEnv.spacingMD < largeEnv.spacingMD)
        #expect(largeEnv.spacingMD < axEnv.spacingMD)

        // Padding debería crecer con el tamaño
        #expect(smallEnv.paddingLG < largeEnv.paddingLG)
        #expect(largeEnv.paddingLG < axEnv.paddingLG)

        // Icons deberían crecer con el tamaño
        #expect(smallEnv.iconMD < largeEnv.iconMD)
        #expect(largeEnv.iconMD < axEnv.iconMD)
    }
}

@Suite("Adaptive Layout Tests")
struct AdaptiveLayoutTests {

    // MARK: - Layout Direction Tests

    @Test("Optimal direction for standard sizes")
    func testOptimalDirectionStandard() {
        #expect(AdaptiveLayout.optimalDirection(for: .small) == .horizontal)
        #expect(AdaptiveLayout.optimalDirection(for: .large) == .horizontal)
        #expect(AdaptiveLayout.optimalDirection(for: .extraExtraExtraLarge) == .horizontal)
    }

    @Test("Optimal direction for accessibility sizes")
    func testOptimalDirectionAccessibility() {
        #expect(AdaptiveLayout.optimalDirection(for: .accessibilityMedium) == .vertical)
        #expect(AdaptiveLayout.optimalDirection(for: .accessibilityLarge) == .vertical)
        #expect(AdaptiveLayout.optimalDirection(for: .accessibilityExtraExtraExtraLarge) == .vertical)
    }

    @Test("Should stack with default threshold")
    func testShouldStackDefault() {
        // Threshold por defecto es 7 (accessibilityMedium)
        #expect(AdaptiveLayout.shouldStack(for: .large) == false)
        #expect(AdaptiveLayout.shouldStack(for: .extraExtraExtraLarge) == false)
        #expect(AdaptiveLayout.shouldStack(for: .accessibilityMedium) == true)
        #expect(AdaptiveLayout.shouldStack(for: .accessibilityExtraExtraExtraLarge) == true)
    }

    @Test("Should stack with custom threshold")
    func testShouldStackCustomThreshold() {
        // Threshold 5 = extraExtraLarge
        #expect(AdaptiveLayout.shouldStack(for: .extraLarge, threshold: 5) == false)
        #expect(AdaptiveLayout.shouldStack(for: .extraExtraLarge, threshold: 5) == true)
        #expect(AdaptiveLayout.shouldStack(for: .extraExtraExtraLarge, threshold: 5) == true)

        // Threshold 3 = large
        #expect(AdaptiveLayout.shouldStack(for: .medium, threshold: 3) == false)
        #expect(AdaptiveLayout.shouldStack(for: .large, threshold: 3) == true)
    }

    // MARK: - Grid Columns Tests

    @Test("Grid columns for standard sizes")
    func testGridColumnsStandard() {
        #expect(AdaptiveLayout.gridColumns(for: .small, default: 4) == 4)
        #expect(AdaptiveLayout.gridColumns(for: .large, default: 4) == 4)

        // ExtraExtraLarge debería reducir columnas
        let xxlColumns = AdaptiveLayout.gridColumns(for: .extraExtraLarge, default: 4)
        #expect(xxlColumns >= 2 && xxlColumns <= 4)
    }

    @Test("Grid columns for accessibility sizes")
    func testGridColumnsAccessibility() {
        // Accessibility medium/large: mitad de columnas
        let axMediumColumns = AdaptiveLayout.gridColumns(for: .accessibilityMedium, default: 4)
        #expect(axMediumColumns == 2)

        // Accessibility extra large: columna única
        let axXLColumns = AdaptiveLayout.gridColumns(for: .accessibilityExtraLarge, default: 4)
        #expect(axXLColumns == 1)
    }

    @Test("Grid columns respects minimum")
    func testGridColumnsMinimum() {
        let columns = AdaptiveLayout.gridColumns(
            for: .accessibilityExtraExtraExtraLarge,
            default: 10,
            minimum: 2
        )
        #expect(columns >= 2)
    }

    // MARK: - Line Limit Tests

    @Test("Line limit for standard sizes")
    func testLineLimitStandard() {
        #expect(AdaptiveLayout.lineLimit(for: .small, default: 3) == 3)
        #expect(AdaptiveLayout.lineLimit(for: .large, default: 3) == 3)
        #expect(AdaptiveLayout.lineLimit(for: .extraExtraExtraLarge, default: 3) == 3)
    }

    @Test("Line limit for accessibility sizes")
    func testLineLimitAccessibility() {
        // Accessibility no debería tener límite (nil)
        #expect(AdaptiveLayout.lineLimit(for: .accessibilityMedium, default: 3) == nil)
        #expect(AdaptiveLayout.lineLimit(for: .accessibilityLarge, default: 3) == nil)
        #expect(AdaptiveLayout.lineLimit(for: .accessibilityExtraExtraExtraLarge, default: 5) == nil)
    }

    // MARK: - Truncation Mode Tests

    @Test("Truncation mode for standard sizes")
    func testTruncationModeStandard() {
        #expect(AdaptiveLayout.truncationMode(for: .small) == .tail)
        #expect(AdaptiveLayout.truncationMode(for: .large) == .tail)
        #expect(AdaptiveLayout.truncationMode(for: .extraExtraExtraLarge) == .tail)
    }

    @Test("Truncation mode for accessibility sizes")
    func testTruncationModeAccessibility() {
        #expect(AdaptiveLayout.truncationMode(for: .accessibilityMedium) == .middle)
        #expect(AdaptiveLayout.truncationMode(for: .accessibilityLarge) == .middle)
        #expect(AdaptiveLayout.truncationMode(for: .accessibilityExtraExtraExtraLarge) == .middle)
    }

    // MARK: - Minimum Scale Factor Tests

    @Test("Minimum scale factor for standard sizes")
    func testMinimumScaleFactorStandard() {
        #expect(AdaptiveLayout.minimumScaleFactor(for: .small) == 0.8)
        #expect(AdaptiveLayout.minimumScaleFactor(for: .large) == 0.8)
        #expect(AdaptiveLayout.minimumScaleFactor(for: .extraExtraExtraLarge) == 0.8)
    }

    @Test("Minimum scale factor for accessibility sizes")
    func testMinimumScaleFactorAccessibility() {
        // Accessibility no debería comprimir texto
        #expect(AdaptiveLayout.minimumScaleFactor(for: .accessibilityMedium) == 1.0)
        #expect(AdaptiveLayout.minimumScaleFactor(for: .accessibilityLarge) == 1.0)
        #expect(AdaptiveLayout.minimumScaleFactor(for: .accessibilityExtraExtraExtraLarge) == 1.0)
    }
}
