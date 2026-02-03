import Foundation
import CoreGraphics
import SwiftUI

/// Sistema centralizado de design tokens para EduUI.
///
/// Proporciona valores consistentes para spacing, sizing, corner radius,
/// shadows y otros valores de diseno reutilizables.
///
/// ## Uso
/// ```swift
/// .padding(.horizontal, DesignTokens.Spacing.large)
/// .padding(.vertical, DesignTokens.Spacing.medium)
/// .cornerRadius(DesignTokens.CornerRadius.medium)
/// .shadow(radius: DesignTokens.Shadow.medium)
/// ```
///
/// ## Beneficios
/// - Consistencia visual en toda la aplicacion
/// - Facilita theming y personalizacion
/// - Evita magic numbers dispersos
/// - Un solo punto de cambio para ajustes de diseno
public enum DesignTokens {

    // MARK: - Spacing

    /// Valores de espaciado (padding, spacing entre elementos).
    public enum Spacing {
        /// 4pt - Espaciado extra pequeno
        public static let xs: CGFloat = 4

        /// 8pt - Espaciado pequeno
        public static let small: CGFloat = 8

        /// 12pt - Espaciado mediano
        public static let medium: CGFloat = 12

        /// 16pt - Espaciado grande
        public static let large: CGFloat = 16

        /// 20pt - Espaciado extra grande
        public static let xl: CGFloat = 20

        /// 24pt - Espaciado extra extra grande
        public static let xxl: CGFloat = 24
    }

    // MARK: - Corner Radius

    /// Valores de radio de esquinas para componentes.
    public enum CornerRadius {
        /// 6pt - Radio pequeno (botones small)
        public static let small: CGFloat = 6

        /// 8pt - Radio mediano (botones medium, text fields)
        public static let medium: CGFloat = 8

        /// 10pt - Radio grande (botones large)
        public static let large: CGFloat = 10

        /// 12pt - Radio extra grande (cards)
        public static let xl: CGFloat = 12
    }

    // MARK: - Shadow

    /// Valores de sombra para elevacion de componentes.
    public enum Shadow {
        /// 0pt - Sin sombra
        public static let none: CGFloat = 0

        /// 2pt - Sombra pequena (elevation low)
        public static let small: CGFloat = 2

        /// 4pt - Sombra mediana (elevation medium)
        public static let medium: CGFloat = 4

        /// 8pt - Sombra grande (elevation high)
        public static let large: CGFloat = 8
    }

    // MARK: - Border Width

    /// Valores de ancho de borde.
    public enum BorderWidth {
        /// 1pt - Borde delgado (default)
        public static let thin: CGFloat = 1

        /// 2pt - Borde mediano (borders destacados, focus states)
        public static let medium: CGFloat = 2

        /// 3pt - Borde grueso (enfasis extra)
        public static let thick: CGFloat = 3
    }

    // MARK: - Icon Size

    /// Valores de tamano de iconos.
    public enum IconSize {
        /// 16pt - Icono pequeno
        public static let small: CGFloat = 16

        /// 24pt - Icono mediano
        public static let medium: CGFloat = 24

        /// 32pt - Icono grande
        public static let large: CGFloat = 32

        /// 48pt - Icono extra grande
        public static let xl: CGFloat = 48
    }
}

// MARK: - EdgeInsets Convenience

extension DesignTokens {
    /// EdgeInsets predefinidos para casos comunes.
    public enum Insets {
        /// EdgeInsets(6, 12, 6, 12) - Padding para botones small
        public static let buttonSmall = EdgeInsets(
            top: 6,
            leading: 12,
            bottom: 6,
            trailing: 12
        )

        /// EdgeInsets(10, 16, 10, 16) - Padding para botones medium
        public static let buttonMedium = EdgeInsets(
            top: 10,
            leading: 16,
            bottom: 10,
            trailing: 16
        )

        /// EdgeInsets(14, 20, 14, 20) - Padding para botones large
        public static let buttonLarge = EdgeInsets(
            top: 14,
            leading: 20,
            bottom: 14,
            trailing: 20
        )

        /// EdgeInsets(16, 16, 16, 16) - Padding estandar para cards
        public static let cardDefault = EdgeInsets(
            top: Spacing.large,
            leading: Spacing.large,
            bottom: Spacing.large,
            trailing: Spacing.large
        )

        /// EdgeInsets(24, 24, 24, 24) - Padding generoso para hero cards
        public static let cardHero = EdgeInsets(
            top: Spacing.xxl,
            leading: Spacing.xxl,
            bottom: Spacing.xxl,
            trailing: Spacing.xxl
        )

        /// EdgeInsets(12, 16, 12, 16) - Padding compacto para list cards
        public static let cardList = EdgeInsets(
            top: Spacing.medium,
            leading: Spacing.large,
            bottom: Spacing.medium,
            trailing: Spacing.large
        )
    }
}
