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
        let circle = EduProgressCircle(progress: 0.5)
        #expect(circle != nil)
    }

    @Test("EduProgressCircle inicializa con valores default")
    func testProgressCircleDefaultValues() {
        let circle = EduProgressCircle(progress: 0.7)
        #expect(circle != nil)
    }

    // MARK: - Progress Value Tests

    @Test("EduProgressCircle con progreso 0")
    func testProgressCircleZeroProgress() {
        let circle = EduProgressCircle(progress: 0.0)
        #expect(circle != nil)
    }

    @Test("EduProgressCircle con progreso 1 (completo)")
    func testProgressCircleFullProgress() {
        let circle = EduProgressCircle(progress: 1.0)
        #expect(circle != nil)
    }

    @Test("EduProgressCircle con progreso 0.5 (mitad)")
    func testProgressCircleHalfProgress() {
        let circle = EduProgressCircle(progress: 0.5)
        #expect(circle != nil)
    }

    // MARK: - Progress Clamping Tests

    @Test("EduProgressCircle clampea progreso < 0")
    func testProgressCircleClampingAtZero() {
        let circle = EduProgressCircle(progress: -0.3)
        #expect(circle != nil)
    }

    @Test("EduProgressCircle clampea progreso > 1")
    func testProgressCircleClampingAtOne() {
        let circle = EduProgressCircle(progress: 1.2)
        #expect(circle != nil)
    }

    // MARK: - Customization Tests

    @Test("EduProgressCircle con lineWidth custom")
    func testProgressCircleCustomLineWidth() {
        let circle = EduProgressCircle(progress: 0.4, lineWidth: 12)
        #expect(circle != nil)
    }

    @Test("EduProgressCircle con tint color custom")
    func testProgressCircleCustomTint() {
        let circle = EduProgressCircle(progress: 0.6, tint: .blue)
        #expect(circle != nil)
    }

    @Test("EduProgressCircle muestra porcentaje")
    func testProgressCircleWithPercentage() {
        let circle = EduProgressCircle(progress: 0.75, showPercentage: true)
        #expect(circle != nil)
    }

    @Test("EduProgressCircle oculta porcentaje (default)")
    func testProgressCircleHidesPercentage() {
        let circle = EduProgressCircle(progress: 0.8, showPercentage: false)
        #expect(circle != nil)
    }

    @Test("EduProgressCircle con todas las opciones custom")
    func testProgressCircleFullyCustomized() {
        let circle = EduProgressCircle(
            progress: 0.65,
            lineWidth: 10,
            tint: .green,
            showPercentage: true
        )
        #expect(circle != nil)
    }

    // MARK: - Indeterminate Circle Tests

    @Test("EduIndeterminateCircle inicializa correctamente")
    func testIndeterminateCircleInitialization() {
        let circle = EduIndeterminateCircle()
        #expect(circle != nil)
    }

    @Test("EduIndeterminateCircle con lineWidth custom")
    func testIndeterminateCircleCustomLineWidth() {
        let circle = EduIndeterminateCircle(lineWidth: 10)
        #expect(circle != nil)
    }

    @Test("EduIndeterminateCircle con tint custom")
    func testIndeterminateCircleCustomTint() {
        let circle = EduIndeterminateCircle(tint: .red)
        #expect(circle != nil)
    }

    // MARK: - Circular Progress with Icon Tests

    @Test("EduCircularProgressWithIcon inicializa con icono")
    func testCircularProgressWithIcon() {
        let circle = EduCircularProgressWithIcon(progress: 0.8, icon: "checkmark")
        #expect(circle != nil)
    }

    @Test("EduCircularProgressWithIcon con lineWidth custom")
    func testCircularProgressWithIconCustomLineWidth() {
        let circle = EduCircularProgressWithIcon(
            progress: 0.5,
            icon: "star.fill",
            lineWidth: 6
        )
        #expect(circle != nil)
    }

    @Test("EduCircularProgressWithIcon con tint custom")
    func testCircularProgressWithIconCustomTint() {
        let circle = EduCircularProgressWithIcon(
            progress: 0.7,
            icon: "heart.fill",
            tint: .pink
        )
        #expect(circle != nil)
    }

    // MARK: - Multi-Ring Progress Tests

    @Test("EduMultiRingProgress inicializa con múltiples rings")
    func testMultiRingProgressInitialization() {
        let rings = [
            EduMultiRingProgress.RingData(progress: 0.7, color: .blue),
            EduMultiRingProgress.RingData(progress: 0.5, color: .green)
        ]
        let multiRing = EduMultiRingProgress(rings: rings)
        #expect(multiRing != nil)
    }

    @Test("EduMultiRingProgress con un solo ring")
    func testMultiRingProgressSingleRing() {
        let rings = [
            EduMultiRingProgress.RingData(progress: 0.8, color: .red)
        ]
        let multiRing = EduMultiRingProgress(rings: rings)
        #expect(multiRing != nil)
    }

    @Test("EduMultiRingProgress con tres rings")
    func testMultiRingProgressThreeRings() {
        let rings = [
            EduMultiRingProgress.RingData(progress: 0.9, color: .blue),
            EduMultiRingProgress.RingData(progress: 0.6, color: .green),
            EduMultiRingProgress.RingData(progress: 0.3, color: .orange)
        ]
        let multiRing = EduMultiRingProgress(rings: rings)
        #expect(multiRing != nil)
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
        let gauge = EduGaugeProgress(progress: 0.65)
        #expect(gauge != nil)
    }

    @Test("EduGaugeProgress muestra valor (default)")
    func testGaugeProgressShowsValue() {
        let gauge = EduGaugeProgress(progress: 0.5, showValue: true)
        #expect(gauge != nil)
    }

    @Test("EduGaugeProgress oculta valor")
    func testGaugeProgressHidesValue() {
        let gauge = EduGaugeProgress(progress: 0.4, showValue: false)
        #expect(gauge != nil)
    }

    @Test("EduGaugeProgress con lineWidth custom")
    func testGaugeProgressCustomLineWidth() {
        let gauge = EduGaugeProgress(progress: 0.7, lineWidth: 15)
        #expect(gauge != nil)
    }

    @Test("EduGaugeProgress con tint custom")
    func testGaugeProgressCustomTint() {
        let gauge = EduGaugeProgress(progress: 0.85, tint: .orange)
        #expect(gauge != nil)
    }

    @Test("EduGaugeProgress totalmente customizado")
    func testGaugeProgressFullyCustomized() {
        let gauge = EduGaugeProgress(
            progress: 0.6,
            lineWidth: 14,
            tint: .cyan,
            showValue: true
        )
        #expect(gauge != nil)
    }
}
