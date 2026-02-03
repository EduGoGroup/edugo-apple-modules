# Sistema de Design Tokens - EduUI

## Introduccion

Los Design Tokens son valores centralizados que definen el lenguaje visual de la aplicacion. Reemplazan "magic numbers" dispersos por referencias semanticas y reutilizables.

## Beneficios

- **Consistencia visual**: Todos los componentes usan los mismos valores
- **Mantenibilidad**: Cambios globales desde un solo lugar
- **Theming**: Base para sistema de temas claro/oscuro personalizado
- **Documentacion viva**: Los nombres son auto-descriptivos
- **Escalabilidad**: Facil agregar nuevos tokens

## Categorias de Tokens

### Spacing

Valores para padding, margin y spacing entre elementos.

| Token | Valor | Uso tipico |
|-------|-------|------------|
| `DesignTokens.Spacing.xs` | 4pt | Separacion minima, padding interno compacto |
| `DesignTokens.Spacing.small` | 8pt | Spacing en HStack/VStack, padding pequeno |
| `DesignTokens.Spacing.medium` | 12pt | Padding vertical de botones medium |
| `DesignTokens.Spacing.large` | 16pt | Padding horizontal estandar, spacing principal |
| `DesignTokens.Spacing.xl` | 20pt | Padding de botones large |
| `DesignTokens.Spacing.xxl` | 24pt | Padding generoso de hero cards |

### Corner Radius

Valores para redondeo de esquinas.

| Token | Valor | Uso tipico |
|-------|-------|------------|
| `DesignTokens.CornerRadius.small` | 6pt | Botones small |
| `DesignTokens.CornerRadius.medium` | 8pt | Botones medium, text fields |
| `DesignTokens.CornerRadius.large` | 10pt | Botones large |
| `DesignTokens.CornerRadius.xl` | 12pt | Cards, group boxes |

### Shadow

Valores para sombras y elevacion.

| Token | Valor | Uso tipico |
|-------|-------|------------|
| `DesignTokens.Shadow.none` | 0pt | Sin elevacion |
| `DesignTokens.Shadow.small` | 2pt | Elevacion baja (list cards) |
| `DesignTokens.Shadow.medium` | 4pt | Elevacion media (cards estandar) |
| `DesignTokens.Shadow.large` | 8pt | Elevacion alta (hero cards, modals) |

### Border Width

Valores para grosor de bordes.

| Token | Valor | Uso tipico |
|-------|-------|------------|
| `DesignTokens.BorderWidth.thin` | 1pt | Bordes sutiles |
| `DesignTokens.BorderWidth.medium` | 2pt | Bordes destacados, focus states |
| `DesignTokens.BorderWidth.thick` | 3pt | Enfasis extra |

### Icon Size

Valores para tamanos de iconos.

| Token | Valor | Uso tipico |
|-------|-------|------------|
| `DesignTokens.IconSize.small` | 16pt | Iconos inline |
| `DesignTokens.IconSize.medium` | 24pt | Iconos de botones |
| `DesignTokens.IconSize.large` | 32pt | Iconos destacados |
| `DesignTokens.IconSize.xl` | 48pt | Iconos hero |

### Insets (EdgeInsets predefinidos)

EdgeInsets comunes para casos especificos.

| Token | Valor | Uso |
|-------|-------|-----|
| `DesignTokens.Insets.buttonSmall` | (6, 12, 6, 12) | Padding de botones small |
| `DesignTokens.Insets.buttonMedium` | (10, 16, 10, 16) | Padding de botones medium |
| `DesignTokens.Insets.buttonLarge` | (14, 20, 14, 20) | Padding de botones large |
| `DesignTokens.Insets.cardDefault` | (16, 16, 16, 16) | Padding de cards estandar |
| `DesignTokens.Insets.cardHero` | (24, 24, 24, 24) | Padding de hero cards |
| `DesignTokens.Insets.cardList` | (12, 16, 12, 16) | Padding de list cards |

## Ejemplos de Uso

### Antes (con magic numbers)

```swift
struct MyCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Titulo")
            Text("Descripcion")
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
```

### Despues (con design tokens)

```swift
struct MyCard: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            Text("Titulo")
            Text("Descripcion")
        }
        .padding(DesignTokens.Spacing.large)
        .background(Color.white)
        .cornerRadius(DesignTokens.CornerRadius.xl)
        .shadow(radius: DesignTokens.Shadow.medium)
    }
}
```

### Usando Insets predefinidos

```swift
EduCard(padding: DesignTokens.Insets.cardHero) {
    Text("Hero Content")
}
```

## Mejores Practicas

### DO

- Usar tokens para todos los valores de spacing, sizing y styling
- Elegir el token semanticamente correcto (small/medium/large)
- Mantener consistencia con componentes existentes
- Agregar nuevos tokens si un valor se repite 3+ veces

### DON'T

- No usar magic numbers directamente
- No crear tokens para valores unicos/especificos
- No modificar valores de tokens existentes sin discusion del equipo
- No usar tokens para valores que no son de diseno (durations, logic values)

## Extender el Sistema

### Agregar nuevos tokens

```swift
public enum DesignTokens {
    // ... tokens existentes
    
    // Nueva categoria
    public enum Animation {
        public static let fast: TimeInterval = 0.2
        public static let normal: TimeInterval = 0.3
        public static let slow: TimeInterval = 0.5
    }
}
```

## Theming Futuro

Este sistema es la base para implementar theming dinamico:

```swift
// Futuro: Tokens dinamicos por tema
public enum DesignTokens {
    public static var currentTheme: Theme = .light
    
    public enum Spacing {
        public static var large: CGFloat {
            currentTheme.spacingLarge
        }
    }
}
```

## Referencias

- [Apple HIG - Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Material Design - Design Tokens](https://m3.material.io/foundations/design-tokens/overview)
- [Design Tokens Community Group](https://www.w3.org/community/design-tokens/)

## Archivo Fuente

El archivo de DesignTokens se encuentra en:
`Sources/UI/Utilities/DesignTokens.swift`

## Soporte

Para dudas o sugerencias sobre design tokens, contacta al equipo de UI/UX.
