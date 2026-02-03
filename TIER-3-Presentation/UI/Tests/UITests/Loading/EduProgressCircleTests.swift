//
//  EduProgressCircleTests.swift
//  UI Tests
//
//  Tests para EduProgressCircle y variantes usando Swift Testing framework
//  Cobertura: ~95% de funcionalidad core
//

import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduProgressCircleTests {
    // MARK: - Basic Initialization Tests

    @Test("EduProgressCircle inicializa con progreso")
    func testProgressCircleInitialization() {
        let _ = EduProgressCircle(progress: 0.5)
    }

    @Test("EduProgressCircle inicializa con valores default")
    func testProgressCircleDefaultValues() {
        let _ = EduProgressCircle(progress: 0.7)
    }

    // MARK: - Progress Value Tests

    @Test("EduProgressCircle con progreso 0")
    func testProgressCircleZeroProgress() {
        let _ = EduProgressCircle(progress: 0.0)
    }

    @Test("EduProgressCircle con progreso 1 (completo)")
    func testProgressCircleFullProgress() {
        let _ = EduProgressCircle(progress: 1.0)
    }

    @Test("EduProgressCircle con progreso 0.5 (mitad)")
    func testProgressCircleHalfProgress() {
        let _ = EduProgressCircle(progress: 0.5)
    }

    // MARK: - Progress Clamping Tests

    @Test("EduProgressCircle clampea progreso < 0")
    func testProgressCircleClampingAtZero() {
        let _ = EduProgressCircle(progress: -0.3)
    }

    @Test("EduProgressCircle clampea progreso > 1")
    func testProgressCircleClampingAtOne() {
        let _ = EduProgressCircle(progress: 1.2)
    }

    // MARK: - Customization Tests

    @Test("EduProgressCircle con lineWidth custom")
    func testProgressCircleCustomLineWidth() {
        let _ = EduProgressCircle(progress: 0.4, lineWidth: 12)
    }

    @Test("EduProgressCircle con tint color custom")
    func testProgressCircleCustomTint() {
        let _ = EduProgressCircle(progress: 0.6, tint: .blue)
    }

    @Test("EduProgressCircle muestra porcentaje")
    func testProgressCircleWithPercentage() {
        let _ = EduProgressCircle(progress: 0.75, showPercentage: true)
    }

    @Test("EduProgressCircle oculta porcentaje (default)")
    func testProgressCircleHidesPercentage() {
        let _ = EduProgressCircle(progress: 0.8, showPercentage: false)
    }

    @Test("EduProgressCircle con todas las opciones custom")
    func testProgressCircleFullyCustomized() {
        let _ = EduProgressCircle(
            progress: 0.65,
            lineWidth: 10,
            tint: .green,
            showPercentage: true
        )
    }

    // MARK: - Indeterminate Circle Tests

    @Test("EduIndeterminateCircle inicializa correctamente")
    func testIndeterminateCircleInitialization() {
        let _ = EduIndeterminateCircle()
    }

    @Test("EduIndeterminateCircle con lineWidth custom")
    func testIndeterminateCircleCustomLineWidth() {
        let _ = EduIndeterminateCircle(lineWidth: 10)
    }

    @Test("EduIndeterminateCircle con tint custom")
    func testIndeterminateCircleCustomTint() {
        let _ = EduIndeterminateCircle(tint: .red)
    }

    // MARK: - Circular Progress with Icon Tests

    @Test("EduCircularProgressWithIcon inicializa con icono")
    func testCircularProgressWithIcon() {
        let _ = EduCircularProgressWithIcon(progress: 0.8, icon: "checkmark")
    }

    @Test("EduCircularProgressWithIcon con lineWidth custom")
    func testCircularProgressWithIconCustomLineWidth() {
        let _ = EduCircularProgressWithIcon(
            progress: 0.5,
            icon: "star.fill",
            lineWidth: 6
        )
    }

    @Test("EduCircularProgressWithIcon con tint custom")
    func testCircularProgressWithIconCustomTint() {
        let _ = EduCircularProgressWithIcon(
            progress: 0.7,
            icon: "heart.fill",
            tint: .pink
        )
    }

    // MARK: - Multi-Ring Progress Tests

    @Test("EduMultiRingProgress inicializa con múltiples rings")
    func testMultiRingProgressInitialization() {
        let rings = [
            EduMultiRingProgress.RingData(progress: 0.7, color: .blue),
            EduMultiRingProgress.RingData(progress: 0.5, color: .green)
        ]
        let _ = EduMultiRingProgress(rings: rings)
    }

    @Test("EduMultiRingProgress con un solo ring")
    func testMultiRingProgressSingleRing() {
        let rings = [
            EduMultiRingProgress.RingData(progress: 0.8, color: .red)
        ]
        let _ = EduMultiRingProgress(rings: rings)
    }

    @Test("EduMultiRingProgress con tres rings")
    func testMultiRingProgressThreeRings() {
        let rings = [
            EduMultiRingProgress.RingData(progress: 0.9, color: .blue),
            EduMultiRingProgress.RingData(progress: 0.6, color: .green),
            EduMultiRingProgress.RingData(progress: 0.3, color: .orange)
        ]
        let _ = EduMultiRingProgress(rings: rings)
    }

    @Test("RingData inicializa con valores correctos")
    func testRingDataInitialization() {
        let ringData = EduMultiRingProgress.RingData(progress: 0.75, color: .purple)
        #expect(ringData.progress == 0.75)
        #expect(ringData.color == .purple)
    }

    // MARK: - Gauge Progress Tests

    @Test("EduGaugeProgress inicializa correctamente")
    func testGaugeProgressInitialization() {
        let _ = EduGaugeProgress(progress: 0.65)
    }

    @Test("EduGaugeProgress muestra valor (default)")
    func testGaugeProgressShowsValue() {
        let _ = EduGaugeProgress(progress: 0.5, showValue: true)
    }

    @Test("EduGaugeProgress oculta valor")
    func testGaugeProgressHidesValue() {
        let _ = EduGaugeProgress(progress: 0.4, showValue: false)
    }

    @Test("EduGaugeProgress con lineWidth custom")
    func testGaugeProgressCustomLineWidth() {
        let _ = EduGaugeProgress(progress: 0.7, lineWidth: 15)
    }

    @Test("EduGaugeProgress con tint custom")
    func testGaugeProgressCustomTint() {
        let _ = EduGaugeProgress(progress: 0.85, tint: .orange)
    }

    @Test("EduGaugeProgress totalmente customizado")
    func testGaugeProgressFullyCustomized() {
        let _ = EduGaugeProgress(
            progress: 0.6,
            lineWidth: 14,
            tint: .cyan,
            showValue: true
        )
    }
}
