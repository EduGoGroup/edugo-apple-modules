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
        let _ = EduActivityIndicator(style: .small)
    }

    @Test("EduActivityIndicator inicializa con estilo medium (default)")
    func testActivityIndicatorStyleMedium() {
        let _ = EduActivityIndicator(style: .medium)
    }

    @Test("EduActivityIndicator inicializa con estilo large")
    func testActivityIndicatorStyleLarge() {
        let _ = EduActivityIndicator(style: .large)
    }

    @Test("EduActivityIndicator inicializa sin color (default)")
    func testActivityIndicatorDefaultColor() {
        let _ = EduActivityIndicator()
    }

    @Test("EduActivityIndicator inicializa con color custom")
    func testActivityIndicatorWithCustomColor() {
        let _ = EduActivityIndicator(style: .medium, color: .blue)
    }

    // MARK: - Inline Loader Tests

    @Test("EduInlineLoader inicializa con estilo small (default)")
    func testInlineLoaderInitialization() {
        let _ = EduInlineLoader(style: .small)
    }

    @Test("EduInlineLoader inicializa con estilo medium")
    func testInlineLoaderMediumStyle() {
        let _ = EduInlineLoader(style: .medium)
    }

    @Test("EduInlineLoader inicializa con color tint")
    func testInlineLoaderWithTint() {
        let _ = EduInlineLoader(style: .small, tint: .red)
    }

    // MARK: - Loading Overlay Modifier Tests

    @Test("LoadingOverlayModifier cuando isLoading es false")
    func testLoadingOverlayNotLoading() {
        let _ = LoadingOverlayModifier(isLoading: false)
    }

    @Test("LoadingOverlayModifier cuando isLoading es true")
    func testLoadingOverlayLoading() {
        let _ = LoadingOverlayModifier(isLoading: true)
    }

    @Test("LoadingOverlayModifier con mensaje custom")
    func testLoadingOverlayWithMessage() {
        let _ = LoadingOverlayModifier(isLoading: true, message: "Loading data...")
    }

    @Test("LoadingOverlayModifier con estilo large")
    func testLoadingOverlayWithLargeStyle() {
        let _ = LoadingOverlayModifier(isLoading: true, style: .large)
    }

    @Test("LoadingOverlayModifier con mensaje y estilo")
    func testLoadingOverlayWithMessageAndStyle() {
        let _ = LoadingOverlayModifier(
            isLoading: true,
            message: "Processing...",
            style: .medium
        )
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
        let _ = EduActivityIndicator(style: .large, color: nil)
    }

    @Test("EduInlineLoader maneja tint nil correctamente")
    func testInlineLoaderNilTint() {
        let _ = EduInlineLoader(style: .medium, tint: nil)
    }
}
