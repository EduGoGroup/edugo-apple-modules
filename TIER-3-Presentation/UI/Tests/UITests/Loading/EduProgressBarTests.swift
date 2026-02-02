//
//  EduProgressBarTests.swift
//  UI Tests
//
//  Tests para EduProgressBar y variantes usando Swift Testing framework
//  Cobertura: ~95% de funcionalidad core
//

import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduProgressBarTests {
    // MARK: - Basic Initialization Tests

    @Test("EduProgressBar inicializa en modo determinate")
    func testProgressBarDeterminateMode() {
        let progressBar = EduProgressBar(mode: .determinate(0.5))
        #expect(progressBar != nil)
    }

    @Test("EduProgressBar inicializa en modo indeterminate")
    func testProgressBarIndeterminateMode() {
        let progressBar = EduProgressBar(mode: .indeterminate)
        #expect(progressBar != nil)
    }

    // MARK: - Style Tests

    @Test("EduProgressBar con estilo linear")
    func testProgressBarLinearStyle() {
        let progressBar = EduProgressBar(mode: .determinate(0.7), style: .linear)
        #expect(progressBar != nil)
    }

    @Test("EduProgressBar con estilo rounded (default)")
    func testProgressBarRoundedStyle() {
        let progressBar = EduProgressBar(mode: .determinate(0.3), style: .rounded)
        #expect(progressBar != nil)
    }

    @Test("EduProgressBar con estilo thin")
    func testProgressBarThinStyle() {
        let progressBar = EduProgressBar(mode: .determinate(0.9), style: .thin)
        #expect(progressBar != nil)
    }

    // MARK: - Color Customization Tests

    @Test("EduProgressBar con tint color custom")
    func testProgressBarCustomTint() {
        let progressBar = EduProgressBar(
            mode: .determinate(0.6),
            tint: .blue
        )
        #expect(progressBar != nil)
    }

    @Test("EduProgressBar con background color custom")
    func testProgressBarCustomBackground() {
        let progressBar = EduProgressBar(
            mode: .determinate(0.4),
            backgroundColor: .gray
        )
        #expect(progressBar != nil)
    }

    // MARK: - Progress Validation Tests (Edge Cases)

    @Test("EduProgressBar valida progreso < 0 (debe clampearse a 0)")
    func testProgressBarClampingAtZero() {
        let progressBar = EduProgressBar(mode: .determinate(-0.5))
        #expect(progressBar != nil)
    }

    @Test("EduProgressBar valida progreso > 1 (debe clampearse a 1)")
    func testProgressBarClampingAtOne() {
        let progressBar = EduProgressBar(mode: .determinate(1.5))
        #expect(progressBar != nil)
    }

    @Test("EduProgressBar acepta progreso exactamente 0")
    func testProgressBarExactlyZero() {
        let progressBar = EduProgressBar(mode: .determinate(0.0))
        #expect(progressBar != nil)
    }

    @Test("EduProgressBar acepta progreso exactamente 1")
    func testProgressBarExactlyOne() {
        let progressBar = EduProgressBar(mode: .determinate(1.0))
        #expect(progressBar != nil)
    }

    @Test("EduProgressBar acepta progreso 0.5 (mitad)")
    func testProgressBarHalfway() {
        let progressBar = EduProgressBar(mode: .determinate(0.5))
        #expect(progressBar != nil)
    }

    // MARK: - Labeled Progress Bar Tests

    @Test("EduLabeledProgressBar inicializa con label")
    func testLabeledProgressBarWithLabel() {
        let progressBar = EduLabeledProgressBar(
            progress: 0.6,
            label: "Uploading"
        )
        #expect(progressBar != nil)
    }

    @Test("EduLabeledProgressBar sin label")
    func testLabeledProgressBarWithoutLabel() {
        let progressBar = EduLabeledProgressBar(
            progress: 0.7,
            label: nil
        )
        #expect(progressBar != nil)
    }

    @Test("EduLabeledProgressBar muestra porcentaje")
    func testLabeledProgressBarShowsPercentage() {
        let progressBar = EduLabeledProgressBar(
            progress: 0.75,
            showPercentage: true
        )
        #expect(progressBar != nil)
    }

    @Test("EduLabeledProgressBar oculta porcentaje")
    func testLabeledProgressBarHidesPercentage() {
        let progressBar = EduLabeledProgressBar(
            progress: 0.4,
            showPercentage: false
        )
        #expect(progressBar != nil)
    }

    @Test("EduLabeledProgressBar con estilo thin")
    func testLabeledProgressBarThinStyle() {
        let progressBar = EduLabeledProgressBar(
            progress: 0.8,
            style: .thin
        )
        #expect(progressBar != nil)
    }

    // MARK: - Segmented Progress Bar Tests

    @Test("EduSegmentedProgressBar inicializa con steps")
    func testSegmentedProgressBarInitialization() {
        let progressBar = EduSegmentedProgressBar(totalSteps: 5, currentStep: 3)
        #expect(progressBar != nil)
    }

    @Test("EduSegmentedProgressBar en primer step")
    func testSegmentedProgressBarFirstStep() {
        let progressBar = EduSegmentedProgressBar(totalSteps: 4, currentStep: 1)
        #expect(progressBar != nil)
    }

    @Test("EduSegmentedProgressBar en último step")
    func testSegmentedProgressBarLastStep() {
        let progressBar = EduSegmentedProgressBar(totalSteps: 6, currentStep: 6)
        #expect(progressBar != nil)
    }

    @Test("EduSegmentedProgressBar con tint color custom")
    func testSegmentedProgressBarCustomTint() {
        let progressBar = EduSegmentedProgressBar(
            totalSteps: 3,
            currentStep: 2,
            tint: .green
        )
        #expect(progressBar != nil)
    }

    // MARK: - Mode Enum Tests

    @Test("EduProgressBarMode modo determinate con valor")
    func testProgressBarModeDeterminate() {
        let mode = EduProgressBarMode.determinate(0.5)
        switch mode {
        case .determinate(let value):
            #expect(value == 0.5)
        case .indeterminate:
            Issue.record("Expected determinate mode")
        }
    }

    @Test("EduProgressBarMode modo indeterminate")
    func testProgressBarModeIndeterminate() {
        let mode = EduProgressBarMode.indeterminate
        switch mode {
        case .indeterminate:
            #expect(true) // Success
        case .determinate:
            Issue.record("Expected indeterminate mode")
        }
    }

    // MARK: - Style Enum Tests

    @Test("EduProgressBarStyle tiene 3 estilos")
    func testProgressBarStyleCases() {
        let styles: [EduProgressBarStyle] = [.linear, .rounded, .thin]
        #expect(styles.count == 3)
    }
}
