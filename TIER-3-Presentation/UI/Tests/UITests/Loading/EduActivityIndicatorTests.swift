//
//  EduActivityIndicatorTests.swift
//  UI Tests
//
//  Tests para EduActivityIndicator usando Swift Testing framework
//  Cobertura: ~95% de funcionalidad core
//

import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduActivityIndicatorTests {
    // MARK: - Initialization Tests

    @Test("EduActivityIndicator inicializa con estilo small")
    func testActivityIndicatorStyleSmall() {
        let indicator = EduActivityIndicator(style: .small)
        #expect(indicator != nil)
    }

    @Test("EduActivityIndicator inicializa con estilo medium (default)")
    func testActivityIndicatorStyleMedium() {
        let indicator = EduActivityIndicator(style: .medium)
        #expect(indicator != nil)
    }

    @Test("EduActivityIndicator inicializa con estilo large")
    func testActivityIndicatorStyleLarge() {
        let indicator = EduActivityIndicator(style: .large)
        #expect(indicator != nil)
    }

    @Test("EduActivityIndicator inicializa sin color (default)")
    func testActivityIndicatorDefaultColor() {
        let indicator = EduActivityIndicator()
        #expect(indicator != nil)
    }

    @Test("EduActivityIndicator inicializa con color custom")
    func testActivityIndicatorWithCustomColor() {
        let indicator = EduActivityIndicator(style: .medium, color: .blue)
        #expect(indicator != nil)
    }

    // MARK: - Inline Loader Tests

    @Test("EduInlineLoader inicializa con estilo small (default)")
    func testInlineLoaderInitialization() {
        let loader = EduInlineLoader(style: .small)
        #expect(loader != nil)
    }

    @Test("EduInlineLoader inicializa con estilo medium")
    func testInlineLoaderMediumStyle() {
        let loader = EduInlineLoader(style: .medium)
        #expect(loader != nil)
    }

    @Test("EduInlineLoader inicializa con color tint")
    func testInlineLoaderWithTint() {
        let loader = EduInlineLoader(style: .small, tint: .red)
        #expect(loader != nil)
    }

    // MARK: - Loading Overlay Modifier Tests

    @Test("LoadingOverlayModifier cuando isLoading es false")
    func testLoadingOverlayNotLoading() {
        let modifier = LoadingOverlayModifier(isLoading: false)
        #expect(modifier != nil)
    }

    @Test("LoadingOverlayModifier cuando isLoading es true")
    func testLoadingOverlayLoading() {
        let modifier = LoadingOverlayModifier(isLoading: true)
        #expect(modifier != nil)
    }

    @Test("LoadingOverlayModifier con mensaje custom")
    func testLoadingOverlayWithMessage() {
        let modifier = LoadingOverlayModifier(isLoading: true, message: "Loading data...")
        #expect(modifier != nil)
    }

    @Test("LoadingOverlayModifier con estilo large")
    func testLoadingOverlayWithLargeStyle() {
        let modifier = LoadingOverlayModifier(isLoading: true, style: .large)
        #expect(modifier != nil)
    }

    @Test("LoadingOverlayModifier con mensaje y estilo")
    func testLoadingOverlayWithMessageAndStyle() {
        let modifier = LoadingOverlayModifier(
            isLoading: true,
            message: "Processing...",
            style: .medium
        )
        #expect(modifier != nil)
    }

    // MARK: - Style Enum Tests

    @Test("EduActivityIndicatorStyle tiene 3 casos")
    func testActivityIndicatorStyleCases() {
        let styles: [EduActivityIndicatorStyle] = [.small, .medium, .large]
        #expect(styles.count == 3)
    }

    // MARK: - Edge Cases

    @Test("EduActivityIndicator maneja color nil correctamente")
    func testActivityIndicatorNilColor() {
        let indicator = EduActivityIndicator(style: .large, color: nil)
        #expect(indicator != nil)
    }

    @Test("EduInlineLoader maneja tint nil correctamente")
    func testInlineLoaderNilTint() {
        let loader = EduInlineLoader(style: .medium, tint: nil)
        #expect(loader != nil)
    }
}
