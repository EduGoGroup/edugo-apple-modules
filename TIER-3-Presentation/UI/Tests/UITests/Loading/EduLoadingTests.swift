import XCTest
import SwiftUI
@testable import UI

@MainActor
final class EduLoadingTests: XCTestCase {
    
    // MARK: - Activity Indicator Tests
    
    func testActivityIndicatorStyleSmall() {
        let indicator = EduActivityIndicator(style: .small)
        XCTAssertNotNil(indicator)
    }
    
    func testActivityIndicatorStyleMedium() {
        let indicator = EduActivityIndicator(style: .medium)
        XCTAssertNotNil(indicator)
    }
    
    func testActivityIndicatorStyleLarge() {
        let indicator = EduActivityIndicator(style: .large)
        XCTAssertNotNil(indicator)
    }
    
    func testActivityIndicatorWithColor() {
        let indicator = EduActivityIndicator(style: .medium, color: .blue)
        XCTAssertNotNil(indicator)
    }
    
    func testInlineLoaderInitialization() {
        let loader = EduInlineLoader(style: .small)
        XCTAssertNotNil(loader)
    }
    
    // MARK: - Progress Bar Tests
    
    func testProgressBarDeterminateMode() {
        let progressBar = EduProgressBar(mode: .determinate(0.5))
        XCTAssertNotNil(progressBar)
    }
    
    func testProgressBarIndeterminateMode() {
        let progressBar = EduProgressBar(mode: .indeterminate)
        XCTAssertNotNil(progressBar)
    }
    
    func testProgressBarLinearStyle() {
        let progressBar = EduProgressBar(mode: .determinate(0.7), style: .linear)
        XCTAssertNotNil(progressBar)
    }
    
    func testProgressBarRoundedStyle() {
        let progressBar = EduProgressBar(mode: .determinate(0.3), style: .rounded)
        XCTAssertNotNil(progressBar)
    }
    
    func testProgressBarThinStyle() {
        let progressBar = EduProgressBar(mode: .determinate(0.9), style: .thin)
        XCTAssertNotNil(progressBar)
    }
    
    func testLabeledProgressBarWithLabel() {
        let progressBar = EduLabeledProgressBar(
            progress: 0.6,
            showPercentage: true,
            label: "Uploading"
        )
        XCTAssertNotNil(progressBar)
    }
    
    func testSegmentedProgressBarInitialization() {
        let progressBar = EduSegmentedProgressBar(totalSteps: 5, currentStep: 3)
        XCTAssertNotNil(progressBar)
    }
    
    // MARK: - Progress Circle Tests
    
    func testProgressCircleInitialization() {
        let circle = EduProgressCircle(progress: 0.5)
        XCTAssertNotNil(circle)
    }
    
    func testProgressCircleWithPercentage() {
        let circle = EduProgressCircle(progress: 0.75, showPercentage: true)
        XCTAssertNotNil(circle)
    }
    
    func testProgressCircleCustomLineWidth() {
        let circle = EduProgressCircle(progress: 0.4, lineWidth: 12)
        XCTAssertNotNil(circle)
    }
    
    func testIndeterminateCircleInitialization() {
        let circle = EduIndeterminateCircle()
        XCTAssertNotNil(circle)
    }
    
    func testCircularProgressWithIcon() {
        let circle = EduCircularProgressWithIcon(progress: 0.8, icon: "checkmark")
        XCTAssertNotNil(circle)
    }
    
    func testMultiRingProgressInitialization() {
        let rings = [
            EduMultiRingProgress.RingData(progress: 0.7, color: .blue),
            EduMultiRingProgress.RingData(progress: 0.5, color: .green)
        ]
        let multiRing = EduMultiRingProgress(rings: rings)
        XCTAssertNotNil(multiRing)
    }
    
    func testGaugeProgressInitialization() {
        let gauge = EduGaugeProgress(progress: 0.65)
        XCTAssertNotNil(gauge)
    }
    
    func testGaugeProgressWithoutValue() {
        let gauge = EduGaugeProgress(progress: 0.4, showValue: false)
        XCTAssertNotNil(gauge)
    }
    
    // MARK: - Skeleton Loader Tests
    
    func testSkeletonLoaderRectangle() {
        let skeleton = EduSkeletonLoader(shape: .rectangle)
        XCTAssertNotNil(skeleton)
    }
    
    func testSkeletonLoaderRoundedRectangle() {
        let skeleton = EduSkeletonLoader(shape: .roundedRectangle(8))
        XCTAssertNotNil(skeleton)
    }
    
    func testSkeletonLoaderCircle() {
        let skeleton = EduSkeletonLoader(shape: .circle)
        XCTAssertNotNil(skeleton)
    }
    
    func testSkeletonLoaderCapsule() {
        let skeleton = EduSkeletonLoader(shape: .capsule)
        XCTAssertNotNil(skeleton)
    }
    
    func testSkeletonTextInitialization() {
        let skeleton = EduSkeletonText(lines: 3)
        XCTAssertNotNil(skeleton)
    }
    
    func testSkeletonImageInitialization() {
        let skeleton = EduSkeletonImage(aspectRatio: 16/9)
        XCTAssertNotNil(skeleton)
    }
    
    func testSkeletonCardWithImage() {
        let skeleton = EduSkeletonCard(showImage: true, lines: 3)
        XCTAssertNotNil(skeleton)
    }
    
    func testSkeletonCardWithoutImage() {
        let skeleton = EduSkeletonCard(showImage: false, lines: 2)
        XCTAssertNotNil(skeleton)
    }
    
    func testSkeletonListInitialization() {
        let skeleton = EduSkeletonList(count: 5)
        XCTAssertNotNil(skeleton)
    }
    
    func testSkeletonListRowInitialization() {
        let row = EduSkeletonListRow()
        XCTAssertNotNil(row)
    }
    
    // MARK: - Loading Overlay Tests
    
    func testLoadingOverlayModifierNotLoading() {
        let modifier = LoadingOverlayModifier(isLoading: false)
        XCTAssertNotNil(modifier)
    }
    
    func testLoadingOverlayModifierLoading() {
        let modifier = LoadingOverlayModifier(isLoading: true)
        XCTAssertNotNil(modifier)
    }
    
    func testLoadingOverlayModifierWithMessage() {
        let modifier = LoadingOverlayModifier(isLoading: true, message: "Loading...")
        XCTAssertNotNil(modifier)
    }
    
    func testLoadingOverlayModifierWithStyle() {
        let modifier = LoadingOverlayModifier(isLoading: true, style: .large)
        XCTAssertNotNil(modifier)
    }
    
    // MARK: - Progress Validation Tests
    
    func testProgressBarClampingAtZero() {
        let progressBar = EduProgressBar(mode: .determinate(-0.5))
        XCTAssertNotNil(progressBar)
    }
    
    func testProgressBarClampingAtOne() {
        let progressBar = EduProgressBar(mode: .determinate(1.5))
        XCTAssertNotNil(progressBar)
    }
    
    func testProgressCircleClampingAtZero() {
        let circle = EduProgressCircle(progress: -0.3)
        XCTAssertNotNil(circle)
    }
    
    func testProgressCircleClampingAtOne() {
        let circle = EduProgressCircle(progress: 1.2)
        XCTAssertNotNil(circle)
    }
}
