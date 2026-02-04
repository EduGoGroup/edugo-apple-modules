// EffectsTests.swift
// EffectsTests
//
// Tests for the Effects module

import Testing
import SwiftUI
@testable import Effects

@Suite("Effects Module Tests")
struct EffectsTests {

    // MARK: - Liquid Glass Tests

    @Suite("Liquid Glass Intensity")
    struct LiquidGlassIntensityTests {

        @Test("All intensity levels have valid blur radius")
        func intensityBlurRadius() {
            for intensity in EduLiquidGlassIntensity.allCases {
                #expect(intensity.blurRadius > 0)
                #expect(intensity.blurRadius <= 32)
            }
        }

        @Test("All intensity levels have valid opacity")
        func intensityOpacity() {
            for intensity in EduLiquidGlassIntensity.allCases {
                #expect(intensity.opacity > 0)
                #expect(intensity.opacity <= 1.0)
            }
        }

        @Test("All intensity levels have valid saturation")
        func intensitySaturation() {
            for intensity in EduLiquidGlassIntensity.allCases {
                #expect(intensity.saturation >= 1.0)
                #expect(intensity.saturation <= 2.0)
            }
        }

        @Test("Desktop intensity is optimized for macOS")
        func desktopIntensity() {
            let desktop = EduLiquidGlassIntensity.desktop
            #expect(desktop.blurRadius == 12)
            #expect(desktop.opacity == 0.8)
        }
    }

    // MARK: - Glass State Tests

    @Suite("Glass State")
    struct GlassStateTests {

        @Test("Normal state has default values")
        func normalState() {
            let state = EduGlassState.normal
            #expect(state.scale == 1.0)
            #expect(state.opacityMultiplier == 1.0)
            #expect(state.shadowMultiplier == 1.0)
        }

        @Test("Hovered state increases scale slightly")
        func hoveredState() {
            let state = EduGlassState.hovered
            #expect(state.scale > 1.0)
            #expect(state.scale < 1.1)
        }

        @Test("Pressed state decreases scale")
        func pressedState() {
            let state = EduGlassState.pressed
            #expect(state.scale < 1.0)
        }

        @Test("Disabled state has reduced opacity")
        func disabledState() {
            let state = EduGlassState.disabled
            #expect(state.opacityMultiplier < 1.0)
            #expect(state.shadowMultiplier < 1.0)
        }
    }

    // MARK: - Liquid Animation Tests

    @Suite("Liquid Animation")
    struct LiquidAnimationTests {

        @Test("All animation styles produce valid animations")
        func animationStyles() {
            let styles: [EduLiquidAnimation] = [.smooth, .ripple, .pour, .wave, .morph]
            for style in styles {
                let animation = style.animation
                #expect(animation != Animation.default)
            }
        }
    }

    // MARK: - Configuration Tests

    @Suite("Liquid Glass Configuration")
    struct ConfigurationTests {

        @Test("Default configuration has standard intensity")
        func defaultConfiguration() {
            let config = EduLiquidGlassConfiguration.default
            #expect(config.intensity == .standard)
            #expect(config.cornerRadius == 16)
        }

        @Test("Predefined configurations have correct intensities")
        func predefinedConfigurations() {
            #expect(EduLiquidGlassConfiguration.subtle.intensity == .subtle)
            #expect(EduLiquidGlassConfiguration.prominent.intensity == .prominent)
            #expect(EduLiquidGlassConfiguration.immersive.intensity == .immersive)
            #expect(EduLiquidGlassConfiguration.desktop.intensity == .desktop)
        }

        @Test("Custom configuration preserves values")
        func customConfiguration() {
            let config = EduLiquidGlassConfiguration(
                intensity: .prominent,
                animation: .ripple,
                cornerRadius: 24,
                borderWidth: 1.0,
                borderOpacity: 0.3
            )
            #expect(config.intensity == .prominent)
            #expect(config.cornerRadius == 24)
            #expect(config.borderWidth == 1.0)
            #expect(config.borderOpacity == 0.3)
        }
    }

    // MARK: - Shadow Tests

    @Suite("Shadow System")
    struct ShadowTests {

        @Test("Shadow levels have increasing radius")
        func shadowLevelsIncrease() {
            let levels: [EduShadowLevel] = [.none, .sm, .md, .lg, .xl, .xxl]
            var previousRadius: CGFloat = -1

            for level in levels {
                let config = level.configuration
                #expect(config.radius >= previousRadius)
                previousRadius = config.radius
            }
        }

        @Test("None shadow has zero values")
        func noneShadow() {
            let config = EduShadowLevel.none.configuration
            #expect(config.radius == 0)
        }

        @Test("Glass-aware shadow adjusts based on intensity")
        func glassAwareShadow() {
            let subtleConfig = EduShadowConfiguration.glassAware(
                level: .md,
                glassIntensity: .subtle
            )
            let prominentConfig = EduShadowConfiguration.glassAware(
                level: .md,
                glassIntensity: .prominent
            )

            #expect(subtleConfig.radius < prominentConfig.radius)
        }
    }

    // MARK: - Shape Tests

    @Suite("Custom Shapes")
    struct ShapeTests {

        @Test("Liquid rounded rectangle creates valid path")
        func liquidRoundedRectangle() {
            let shape = EduLiquidRoundedRectangle(cornerRadius: 16, smoothness: 0.6)
            let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
            let path = shape.path(in: rect)

            #expect(!path.isEmpty)
        }

        @Test("Squircle shape creates valid path")
        func squircleShape() {
            let shape = EduSquircleShape(cornerRadius: 16, exponent: 4)
            let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
            let path = shape.path(in: rect)

            #expect(!path.isEmpty)
        }

        @Test("Blob shape creates valid path with seed")
        func blobShape() {
            let shape = EduBlobShape(seed: 42, complexity: 6)
            let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
            let path = shape.path(in: rect)

            #expect(!path.isEmpty)
        }

        @Test("Morphable shape corner factors")
        func morphableShapeCorners() {
            #expect(EduMorphableShape.rectangle.cornerFactor == 0)
            #expect(EduMorphableShape.roundedRectangle(cornerRadius: 16).cornerFactor == 16)
            #expect(EduMorphableShape.circle.cornerFactor == .infinity)
        }
    }

    // MARK: - Visual Effect Tests

    @Suite("Visual Effects")
    struct VisualEffectTests {

        @Test("Visual effect factory creates glass effect")
        func glassEffect() {
            let effect = EduVisualEffectFactory.glass(cornerRadius: 20, opacity: 0.9)
            #expect(effect.style == .thin)
            #expect(effect.opacity == 0.9)
        }

        @Test("Visual effect factory creates frosted effect")
        func frostedEffect() {
            let effect = EduVisualEffectFactory.frosted(cornerRadius: 12)
            #expect(effect.style == .ultraThin)
        }

        @Test("Visual effect factory creates prominent effect")
        func prominentEffect() {
            let effect = EduVisualEffectFactory.prominent()
            #expect(effect.style == .thick)
        }
    }

    // MARK: - Transition Tests

    @Suite("Liquid Transitions")
    struct TransitionTests {

        @Test("All transition styles produce transitions")
        func transitionStyles() {
            let styles: [EduLiquidTransitionStyle] = [
                .fade,
                .slide(edge: .leading),
                .scale,
                .liquid,
                .dissolve
            ]

            // Just verify we can create transitions for all styles
            #expect(styles.count == 5)
            for style in styles {
                _ = style.transition()
            }
        }
    }
}
