import Foundation
import SwiftUI
import Testing
@testable import Binding

/// Tests for ViewModifiers and their associated style configurations.
@Suite("ViewModifiers Tests")
@MainActor
struct ViewModifiersTests {

    // MARK: - ValidationFieldStyle Tests

    @Suite("ValidationFieldStyle Tests")
    @MainActor
    struct ValidationFieldStyleTests {

        @Test("Default style has correct values")
        func defaultStyle() {
            let style = ValidationFieldStyle.default

            #expect(style.showIcon == true)
            #expect(style.validIconName == "checkmark.circle.fill")
            #expect(style.invalidIconName == "xmark.circle.fill")
            #expect(style.borderWidth == 1)
            #expect(style.borderRadius == 8)
            #expect(style.iconPadding == 8)
            #expect(style.errorSpacing == 4)
            #expect(style.animationDuration == 0.2)
        }

        @Test("Minimal style hides icons")
        func minimalStyle() {
            let style = ValidationFieldStyle.minimal

            #expect(style.showIcon == false)
            #expect(style.borderWidth == 2)
        }

        @Test("Custom style preserves values")
        func customStyle() {
            let style = ValidationFieldStyle(
                showIcon: false,
                validIconName: "star.fill",
                invalidIconName: "star",
                validColor: .blue,
                errorColor: .orange,
                borderWidth: 3,
                borderRadius: 16,
                iconPadding: 12,
                iconFont: .largeTitle,
                errorFont: .body,
                errorSpacing: 8,
                animationDuration: 0.5
            )

            #expect(style.showIcon == false)
            #expect(style.validIconName == "star.fill")
            #expect(style.invalidIconName == "star")
            #expect(style.borderWidth == 3)
            #expect(style.borderRadius == 16)
            #expect(style.iconPadding == 12)
            #expect(style.errorSpacing == 8)
            #expect(style.animationDuration == 0.5)
        }
    }

    // MARK: - LoadingOverlayStyle Tests

    @Suite("LoadingOverlayStyle Tests")
    @MainActor
    struct LoadingOverlayStyleTests {

        @Test("Default style has correct values")
        func defaultStyle() {
            let style = LoadingOverlayStyle.default

            #expect(style.blurRadius == 2)
            #expect(style.spinnerScale == 1.5)
            #expect(style.contentSpacing == 16)
            #expect(style.containerPadding == 24)
            #expect(style.containerCornerRadius == 12)
            #expect(style.shadowRadius == 10)
            #expect(style.animationDuration == 0.2)
        }

        @Test("Fullscreen style has no container")
        func fullscreenStyle() {
            let style = LoadingOverlayStyle.fullscreen

            #expect(style.blurRadius == 3)
            #expect(style.spinnerScale == 2.0)
            #expect(style.containerPadding == 0)
            #expect(style.containerCornerRadius == 0)
            #expect(style.shadowRadius == 0)
        }

        @Test("Custom style preserves values")
        func customStyle() {
            let style = LoadingOverlayStyle(
                blurRadius: 5,
                spinnerScale: 2.5,
                spinnerColor: .blue,
                contentSpacing: 20,
                messageFont: .headline,
                messageColor: .primary,
                containerPadding: 32,
                containerCornerRadius: 20,
                containerBackground: .init(.thinMaterial),
                shadowColor: .black.opacity(0.2),
                shadowRadius: 15,
                shadowY: 8,
                animationDuration: 0.4
            )

            #expect(style.blurRadius == 5)
            #expect(style.spinnerScale == 2.5)
            #expect(style.contentSpacing == 20)
            #expect(style.containerPadding == 32)
            #expect(style.containerCornerRadius == 20)
            #expect(style.shadowRadius == 15)
            #expect(style.shadowY == 8)
            #expect(style.animationDuration == 0.4)
        }
    }

    // MARK: - FormErrorBannerStyle Tests

    @Suite("FormErrorBannerStyle Tests")
    @MainActor
    struct FormErrorBannerStyleTests {

        @Test("Default style has correct values")
        func defaultStyle() {
            let style = FormErrorBannerStyle.default

            #expect(style.iconName == "exclamationmark.triangle.fill")
            #expect(style.iconSpacing == 12)
            #expect(style.showDismissButton == true)
            #expect(style.animationDuration == 0.3)
        }

        @Test("Warning style uses different icon and colors")
        func warningStyle() {
            let style = FormErrorBannerStyle.warning

            #expect(style.iconName == "exclamationmark.circle.fill")
            #expect(style.showDismissButton == true)
        }

        @Test("Custom style preserves values")
        func customStyle() {
            let style = FormErrorBannerStyle(
                iconName: "info.circle",
                iconFont: .title,
                iconSpacing: 16,
                messageFont: .body,
                textColor: .black,
                backgroundColor: .gray,
                padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
                showDismissButton: false,
                dismissButtonFont: .title2,
                animationDuration: 0.5
            )

            #expect(style.iconName == "info.circle")
            #expect(style.iconSpacing == 16)
            #expect(style.showDismissButton == false)
            #expect(style.animationDuration == 0.5)
        }
    }

    // MARK: - DisabledDuringSubmitStyle Tests

    @Suite("DisabledDuringSubmitStyle Tests")
    @MainActor
    struct DisabledDuringSubmitStyleTests {

        @Test("Default style has correct values")
        func defaultStyle() {
            let style = DisabledDuringSubmitStyle.default

            #expect(style.disabledOpacity == 0.6)
            #expect(style.animationDuration == 0.2)
        }

        @Test("Subtle style has higher opacity")
        func subtleStyle() {
            let style = DisabledDuringSubmitStyle.subtle

            #expect(style.disabledOpacity == 0.8)
            #expect(style.animationDuration == 0.15)
        }

        @Test("Custom style preserves values")
        func customStyle() {
            let style = DisabledDuringSubmitStyle(
                disabledOpacity: 0.5,
                animationDuration: 0.3
            )

            #expect(style.disabledOpacity == 0.5)
            #expect(style.animationDuration == 0.3)
        }
    }

    // MARK: - ProgressBarStyle Tests

    @Suite("ProgressBarStyle Tests")
    @MainActor
    struct ProgressBarStyleTests {

        @Test("Default style has correct values")
        func defaultStyle() {
            let style = ProgressBarStyle.default

            #expect(style.spacing == 8)
            #expect(style.labelSpacing == 12)
            #expect(style.labelWidth == 40)
            #expect(style.animationDuration == 0.2)
        }

        @Test("Compact style has smaller spacing")
        func compactStyle() {
            let style = ProgressBarStyle.compact

            #expect(style.spacing == 4)
            #expect(style.labelSpacing == 0)
            #expect(style.labelWidth == 0)
        }

        @Test("Custom style preserves values")
        func customStyle() {
            let style = ProgressBarStyle(
                spacing: 12,
                labelSpacing: 16,
                labelWidth: 50,
                labelFont: .headline,
                labelColor: .primary,
                progressColor: .blue,
                animationDuration: 0.4
            )

            #expect(style.spacing == 12)
            #expect(style.labelSpacing == 16)
            #expect(style.labelWidth == 50)
            #expect(style.animationDuration == 0.4)
        }
    }

    // MARK: - ShakeEffectStyle Tests

    @Suite("ShakeEffectStyle Tests")
    @MainActor
    struct ShakeEffectStyleTests {

        @Test("Default style has correct values")
        func defaultStyle() {
            let style = ShakeEffectStyle.default

            #expect(style.shakeCount == 3)
            #expect(style.shakeAmplitude == 10)
            #expect(style.shakeDuration == 0.4)
        }

        @Test("Subtle style has smaller amplitude")
        func subtleStyle() {
            let style = ShakeEffectStyle.subtle

            #expect(style.shakeCount == 2)
            #expect(style.shakeAmplitude == 5)
            #expect(style.shakeDuration == 0.25)
        }

        @Test("Intense style has larger values")
        func intenseStyle() {
            let style = ShakeEffectStyle.intense

            #expect(style.shakeCount == 5)
            #expect(style.shakeAmplitude == 15)
            #expect(style.shakeDuration == 0.5)
        }

        @Test("Custom style preserves values")
        func customStyle() {
            let style = ShakeEffectStyle(
                shakeCount: 4,
                shakeAmplitude: 12,
                shakeDuration: 0.35
            )

            #expect(style.shakeCount == 4)
            #expect(style.shakeAmplitude == 12)
            #expect(style.shakeDuration == 0.35)
        }
    }

    // MARK: - ValidationState Integration Tests

    @Suite("ValidationState Integration Tests")
    @MainActor
    struct ValidationStateIntegrationTests {

        @Test("ValidationState updates correctly")
        func validationStateUpdates() {
            let state = BindableProperty<String>.ValidationState()

            #expect(state.isValid == true)
            #expect(state.errorMessage == nil)

            state.isValid = false
            state.errorMessage = "Invalid input"

            #expect(state.isValid == false)
            #expect(state.errorMessage == "Invalid input")
        }

        @Test("ValidationState can be reset")
        func validationStateReset() {
            let state = BindableProperty<String>.ValidationState()
            state.isValid = false
            state.errorMessage = "Error"

            state.isValid = true
            state.errorMessage = nil

            #expect(state.isValid == true)
            #expect(state.errorMessage == nil)
        }
    }

    // MARK: - FormState Integration Tests

    @Suite("FormState Integration Tests")
    @MainActor
    struct FormStateIntegrationTests {

        @Test("FormState tracks form errors correctly")
        func formStateErrors() {
            let formState = FormState()

            #expect(formState.errors["form"] == nil)

            formState.errors["form"] = "Cross-field validation failed"

            #expect(formState.errors["form"] == "Cross-field validation failed")
        }

        @Test("FormState clearError removes specific error")
        func clearSpecificError() {
            let formState = FormState()
            formState.errors["form"] = "Error message"
            formState.errors["email"] = "Invalid email"

            formState.clearError(for: "form")

            #expect(formState.errors["form"] == nil)
            #expect(formState.errors["email"] == "Invalid email")
        }

        @Test("FormState isSubmitting tracks submission state")
        func submittingState() {
            let formState = FormState()

            #expect(formState.isSubmitting == false)

            formState.isSubmitting = true

            #expect(formState.isSubmitting == true)
        }
    }
}
