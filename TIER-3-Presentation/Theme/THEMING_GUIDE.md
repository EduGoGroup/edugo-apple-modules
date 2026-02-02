# Guía de Theming - Sistema de Temas Adaptativo

Esta guía te ayudará a entender y usar el sistema de theming del proyecto EduGo. El sistema está diseñado para ser flexible, semántico y fácil de mantener.

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Conceptos Básicos](#conceptos-básicos)
3. [Uso Rápido](#uso-rápido)
4. [Color Tokens](#color-tokens)
5. [Semantic Colors](#semantic-colors)
6. [Creación de Custom Themes](#creación-de-custom-themes)
7. [Integración con ViewModifiers](#integración-con-viewmodifiers)
8. [Theme Switcher](#theme-switcher)
9. [Previews y Testing](#previews-y-testing)
10. [Best Practices](#best-practices)
11. [Migración desde Colores Legacy](#migración-desde-colores-legacy)

---

## Introducción

El sistema de theming de EduGo proporciona una arquitectura robusta y escalable para manejar temas visuales en aplicaciones multi-plataforma (iOS, macOS, watchOS, tvOS, visionOS).

### Características Principales

- **Semantic Colors**: 39 colores semánticos que se adaptan automáticamente al tema activo
- **Color Tokens**: 70 tokens de color organizados en 7 paletas con soporte light/dark
- **Multi-Platform**: Componentes adaptativos para todas las plataformas Apple
- **Type-Safe**: API completamente type-safe usando Swift 6.2
- **Thread-Safe**: @MainActor y actor para garantizar seguridad en concurrencia
- **Persistencia**: Preferencias guardadas automáticamente en UserDefaults
- **Preview Tools**: Herramientas avanzadas para visualizar y comparar temas

---

## Conceptos Básicos

### Arquitectura de 3 Capas

```
┌─────────────────────────────────────┐
│   Semantic Colors (UI Layer)       │  ← Usas esto en tu código
│   .background, .text, .interactive  │
├─────────────────────────────────────┤
│   Color Tokens (Design Layer)      │  ← Definido por diseño
│   .primary500, .error600, etc.     │
├─────────────────────────────────────┤
│   Raw Colors (Platform Layer)      │  ← Color(red:green:blue:)
│   UIColor, NSColor, etc.           │
└─────────────────────────────────────┘
```

**Regla de Oro**: Siempre usa `Color.theme.*` en tu código UI. Nunca uses Color Tokens directamente.

---

## Uso Rápido

### 1. Importar el Package

```swift
import Theme
```

### 2. Usar Semantic Colors

```swift
import SwiftUI
import Theme

struct MyView: View {
    var body: some View {
        VStack {
            Text("Hola Mundo")
                .foregroundStyle(Color.theme.text)
                .padding()
                .background(Color.theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.theme.border, lineWidth: 1)
                )
        }
        .background(Color.theme.background)
    }
}
```

### 3. Cambiar el Tema Programáticamente

```swift
// Cambiar el tema actual
ThemeManager.shared.setTheme(.highContrast)

// Cambiar el color scheme (light/dark/auto)
ThemeManager.shared.setColorScheme(.dark)

// Resetear a valores por defecto
ThemeManager.shared.reset()
```

### 4. Observar Cambios de Tema

```swift
import SwiftUI
import Theme

struct ContentView: View {
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack {
            Text("Tema actual: \(themeManager.currentTheme.name)")
            Text("Color scheme: \(themeManager.colorSchemePreference.rawValue)")
        }
        .foregroundStyle(Color.theme.text)
    }
}
```

---

## Color Tokens

Los Color Tokens son la base del sistema de colores. Están organizados en 7 paletas, cada una con 10 niveles (50-900).

### Paletas Disponibles

```swift
// Primary - Colores principales de la marca
ColorTokens.primary50   // Muy claro
ColorTokens.primary100
ColorTokens.primary200
...
ColorTokens.primary900  // Muy oscuro

// Secondary - Colores secundarios
ColorTokens.secondary50
...
ColorTokens.secondary900

// Error - Estados de error
ColorTokens.error50
...
ColorTokens.error900

// Warning - Advertencias
ColorTokens.warning50
...
ColorTokens.warning900

// Success - Estados exitosos
ColorTokens.success50
...
ColorTokens.success900

// Info - Información
ColorTokens.info50
...
ColorTokens.info900

// Neutral - Grises y neutrales
ColorTokens.neutral50
...
ColorTokens.neutral900
```

### Cómo Usar Color Tokens (Solo en Custom Themes)

```swift
import Theme

// INCORRECTO: No uses tokens directamente en UI
Text("Error")
    .foregroundStyle(ColorTokens.error600) // ❌ NO HACER

// CORRECTO: Usa semantic colors
Text("Error")
    .foregroundStyle(Color.theme.error) // ✅ HACER

// CORRECTO: Solo usa tokens al crear custom themes
let myTheme = Theme(
    name: "Mi Tema",
    description: "Tema personalizado",
    semanticColors: SemanticColors(
        // Aquí sí usas tokens
        error: ColorTokens.error600,
        errorSubtle: ColorTokens.error100,
        // ...
    )
)
```

---

## Semantic Colors

Los Semantic Colors son colores con nombres que describen **su propósito**, no su apariencia.

### Categorías de Semantic Colors

#### 1. Background Colors (Fondos)

```swift
Color.theme.background        // Fondo principal de la app
Color.theme.backgroundSubtle  // Fondo alternativo más sutil
Color.theme.surface           // Superficie de tarjetas/modales
Color.theme.surfaceSubtle     // Superficie alternativa
```

#### 2. Text Colors (Textos)

```swift
Color.theme.text              // Texto principal
Color.theme.textSecondary     // Texto secundario (menos énfasis)
Color.theme.textTertiary      // Texto terciario (mínimo énfasis)
Color.theme.textDisabled      // Texto deshabilitado
Color.theme.textOnPrimary     // Texto sobre color primary
Color.theme.textOnError       // Texto sobre color error
Color.theme.textOnWarning     // Texto sobre color warning
Color.theme.textOnSuccess     // Texto sobre color success
```

#### 3. Border Colors (Bordes)

```swift
Color.theme.border            // Borde estándar
Color.theme.borderSubtle      // Borde sutil
Color.theme.borderFocus       // Borde cuando tiene foco
```

#### 4. State Colors (Estados)

```swift
Color.theme.error             // Error principal
Color.theme.errorSubtle       // Error sutil (fondos)
Color.theme.warning           // Advertencia principal
Color.theme.warningSubtle     // Advertencia sutil
Color.theme.success           // Éxito principal
Color.theme.successSubtle     // Éxito sutil
Color.theme.info              // Información principal
Color.theme.infoSubtle        // Información sutil
```

#### 5. Interactive Colors (Interacción)

```swift
Color.theme.interactive       // Elemento interactivo (botones, links)
Color.theme.interactiveHover  // Estado hover
Color.theme.interactiveActive // Estado activo/pressed
Color.theme.interactiveDisabled // Estado deshabilitado
```

#### 6. Shadow Colors (Sombras)

```swift
Color.theme.shadowLight       // Sombra ligera
Color.theme.shadowMedium      // Sombra media
Color.theme.shadowHeavy       // Sombra fuerte
```

### Ejemplo Completo

```swift
struct UserCard: View {
    let user: User
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(user.name)
                .font(.headline)
                .foregroundStyle(Color.theme.text)
            
            Text(user.email)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
            
            if let status = user.status {
                HStack {
                    Image(systemName: statusIcon(for: status))
                    Text(status.rawValue)
                }
                .font(.caption)
                .foregroundStyle(statusColor(for: status))
            }
        }
        .padding()
        .background(Color.theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Color.theme.borderFocus : Color.theme.border,
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(
            color: Color.theme.shadowMedium,
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    private func statusColor(for status: UserStatus) -> Color {
        switch status {
        case .active: return Color.theme.success
        case .pending: return Color.theme.warning
        case .inactive: return Color.theme.error
        }
    }
    
    private func statusIcon(for status: UserStatus) -> String {
        switch status {
        case .active: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .inactive: return "xmark.circle.fill"
        }
    }
}
```

---

## Creación de Custom Themes

### Paso 1: Definir Custom Color Tokens (Opcional)

Si quieres usar una paleta de colores completamente personalizada, crea tus propios tokens:

```swift
import Theme
import SwiftUI

extension ColorTokens {
    // Paleta custom "Ocean"
    static let ocean50 = ColorToken(
        light: Color(hex: "#E0F7FA"),
        dark: Color(hex: "#006064")
    )
    static let ocean100 = ColorToken(
        light: Color(hex: "#B2EBF2"),
        dark: Color(hex: "#00838F")
    )
    // ... continúa con ocean200-900
}
```

### Paso 2: Crear Custom SemanticColors

```swift
import Theme

extension SemanticColors {
    static let ocean = SemanticColors(
        // Backgrounds
        background: ColorTokens.neutral50,
        backgroundSubtle: ColorTokens.neutral100,
        surface: .white,
        surfaceSubtle: ColorTokens.neutral50,
        
        // Text
        text: ColorTokens.neutral900,
        textSecondary: ColorTokens.neutral700,
        textTertiary: ColorTokens.neutral500,
        textDisabled: ColorTokens.neutral400,
        textOnPrimary: .white,
        textOnError: .white,
        textOnWarning: ColorTokens.neutral900,
        textOnSuccess: .white,
        
        // Borders
        border: ColorTokens.neutral300,
        borderSubtle: ColorTokens.neutral200,
        borderFocus: ColorTokens.ocean500,
        
        // State
        error: ColorTokens.error600,
        errorSubtle: ColorTokens.error100,
        warning: ColorTokens.warning600,
        warningSubtle: ColorTokens.warning100,
        success: ColorTokens.success600,
        successSubtle: ColorTokens.success100,
        info: ColorTokens.ocean600,
        infoSubtle: ColorTokens.ocean100,
        
        // Interactive
        interactive: ColorTokens.ocean600,
        interactiveHover: ColorTokens.ocean700,
        interactiveActive: ColorTokens.ocean800,
        interactiveDisabled: ColorTokens.neutral300,
        
        // Shadow
        shadowLight: ColorTokens.neutral900.opacity(0.05),
        shadowMedium: ColorTokens.neutral900.opacity(0.1),
        shadowHeavy: ColorTokens.neutral900.opacity(0.2)
    )
}
```

### Paso 3: Crear el Custom Theme

```swift
import Theme

extension Theme {
    static let ocean = Theme(
        name: "Ocean",
        description: "Tema inspirado en el océano con tonos azules y verdes",
        semanticColors: .ocean
    )
}
```

### Paso 4: Registrar y Usar el Custom Theme

```swift
import SwiftUI
import Theme

@main
struct MyApp: App {
    init() {
        // Opción 1: Cargar theme personalizado al inicio
        ThemeManager.shared.loadCustomTheme(.ocean)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.themeManager, ThemeManager.shared)
        }
    }
}
```

---

## Integración con ViewModifiers

El sistema de theming se integra perfectamente con los ViewModifiers del package Binding.

### ViewModifiers con Themed Variants

Todos estos modifiers tienen variantes `.themed` que usan semantic colors:

#### 1. ValidationFieldModifier

```swift
import Binding
import Theme

TextField("Email", text: $email)
    .validationField(
        style: .themed, // Usa Color.theme.success y Color.theme.error
        validation: emailValidation
    )

// Comparación con estilo legacy
TextField("Email", text: $email)
    .validationField(
        style: .standard, // Usa colores hardcoded
        validation: emailValidation
    )
```

#### 2. FormErrorBannerModifier

```swift
import Binding
import Theme

Form {
    // ...
}
.formErrorBanner(
    style: .themed, // Error rojo usando Color.theme.error
    errorMessages: $errorMessages
)

Form {
    // ...
}
.formErrorBanner(
    style: .themedWarning, // Warning usando Color.theme.warning
    errorMessages: $warningMessages
)
```

#### 3. ProgressBarModifier

```swift
import Binding
import Theme

VStack {
    Text("Cargando...")
}
.progressBar(
    style: .themed, // Usa Color.theme.interactive
    isVisible: $isLoading,
    progress: $progress
)
```

#### 4. LoadingOverlayModifier

```swift
import Binding
import Theme

VStack {
    // Contenido
}
.loadingOverlay(
    style: .themed, // Usa Color.theme.interactive y Color.theme.textSecondary
    isLoading: $isLoading,
    message: "Cargando datos..."
)
```

### Crear ViewModifiers Custom con Theming

```swift
import SwiftUI
import Theme

struct ThemedCardModifier: ViewModifier {
    let isHighlighted: Bool
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isHighlighted ? Color.theme.borderFocus : Color.theme.border,
                        lineWidth: isHighlighted ? 2 : 1
                    )
            )
            .shadow(
                color: Color.theme.shadowMedium,
                radius: 4,
                x: 0,
                y: 2
            )
    }
}

extension View {
    func themedCard(highlighted: Bool = false) -> some View {
        modifier(ThemedCardModifier(isHighlighted: highlighted))
    }
}

// Uso
Text("Contenido")
    .themedCard(highlighted: true)
```

---

## Theme Switcher

El componente `ThemeSwitcher` proporciona una UI lista para usar que permite a los usuarios cambiar temas y color schemes.

### Uso Básico

```swift
import SwiftUI
import Theme

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ThemeSwitcher()
                .navigationTitle("Configuración de Tema")
        }
    }
}
```

### Adaptación Multi-Plataforma

El `ThemeSwitcher` se adapta automáticamente a cada plataforma:

- **iOS**: Segmented control para color scheme + lista de temas
- **macOS**: Form con radio buttons
- **watchOS**: Pickers compactos
- **tvOS**: Cards navegables con focus
- **visionOS**: Grid con ornaments

### Customización del ThemeSwitcher

```swift
import SwiftUI
import Theme

struct CustomSettingsView: View {
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack {
            // Header personalizado
            Text("Personaliza tu experiencia")
                .font(.title)
                .foregroundStyle(Color.theme.text)
            
            // ThemeSwitcher estándar
            ThemeSwitcher()
                .padding()
        }
        .background(Color.theme.background)
    }
}
```

---

## Previews y Testing

El sistema incluye herramientas avanzadas para visualizar y probar temas.

### ThemePreview - Visualizar un Tema Completo

```swift
import SwiftUI
import Theme

#Preview("Default Theme - Light") {
    ThemePreview(theme: .default, colorScheme: .light)
}

#Preview("Default Theme - Dark") {
    ThemePreview(theme: .default, colorScheme: .dark)
}

#Preview("High Contrast Theme") {
    ThemePreview(theme: .highContrast, colorScheme: .light)
}
```

### PreviewHelpers - Utilidades para Previews

#### 1. Preview con Tema Específico

```swift
#Preview("Mi Componente - Ocean Theme") {
    MyComponent()
        .previewTheme(.ocean)
}

#Preview("Mi Componente - Dark") {
    MyComponent()
        .previewTheme(.default, colorScheme: .dark)
}
```

#### 2. Preview con Todos los Temas

```swift
#Preview("Comparar Todos los Temas") {
    MyComponent()
        .previewAllThemes()
}
```

#### 3. Comparar Dos Temas Side-by-Side

```swift
#Preview("Comparar Default vs High Contrast") {
    MyComponent()
        .compareThemes(.default, .highContrast)
}
```

#### 4. Comparar Light vs Dark

```swift
#Preview("Light vs Dark") {
    MyComponent()
        .compareLightDark(theme: .default)
}
```

#### 5. Debug Overlay

```swift
#Preview("Con Debug Info") {
    MyComponent()
        .previewTheme(.default)
        .debugTheme(position: .topTrailing)
}
```

#### 6. Preview con Tamaño Fijo

```swift
#Preview("Card 300x200") {
    MyCard()
        .previewTheme(.default)
        .previewSize(width: 300, height: 200)
}
```

### Testing de Temas

```swift
import XCTest
import Theme

final class CustomThemeTests: XCTestCase {
    func testOceanThemeColors() {
        let theme = Theme.ocean
        
        XCTAssertEqual(theme.name, "Ocean")
        XCTAssertNotNil(theme.semanticColors.interactive)
    }
    
    func testThemeManagerLoadsCustomTheme() {
        let manager = ThemeManager.shared
        manager.loadCustomTheme(.ocean)
        
        XCTAssertEqual(manager.currentTheme.name, "Ocean")
    }
    
    func testSemanticColorsConsistency() {
        let colors = SemanticColors.ocean
        
        // Verificar que todos los colores están definidos
        XCTAssertNotNil(colors.background)
        XCTAssertNotNil(colors.text)
        XCTAssertNotNil(colors.error)
        XCTAssertNotNil(colors.success)
        // ...
    }
}
```

---

## Best Practices

### ✅ DO (Hacer)

1. **Siempre usa Semantic Colors en UI**
   ```swift
   Text("Hola")
       .foregroundStyle(Color.theme.text) // ✅
   ```

2. **Usa ViewModifier Themed Variants**
   ```swift
   TextField("Email", text: $email)
       .validationField(style: .themed, validation: emailValidation) // ✅
   ```

3. **Observa el ThemeManager en views reactivos**
   ```swift
   @Environment(\.themeManager) private var themeManager // ✅
   ```

4. **Crea temas usando Color Tokens**
   ```swift
   SemanticColors(
       error: ColorTokens.error600, // ✅
       // ...
   )
   ```

5. **Documenta tus custom themes**
   ```swift
   /// Tema Ocean: Inspirado en el mar, usa tonos azules y verdes.
   /// Ideal para apps de salud y bienestar.
   static let ocean = Theme(/* ... */) // ✅
   ```

6. **Usa ThemePreview en desarrollo**
   ```swift
   #Preview {
       ThemePreview(theme: .myCustomTheme)
   } // ✅
   ```

### ❌ DON'T (No Hacer)

1. **No uses Color Tokens directamente en UI**
   ```swift
   Text("Error")
       .foregroundStyle(ColorTokens.error600) // ❌
   ```

2. **No uses colores hardcoded**
   ```swift
   Text("Hola")
       .foregroundStyle(.red) // ❌
   ```

3. **No uses hex colors directamente**
   ```swift
   .background(Color(hex: "#FF0000")) // ❌
   ```

4. **No modifiques SemanticColors.default directamente**
   ```swift
   SemanticColors.default.error = ColorTokens.warning600 // ❌ Inmutable
   ```

5. **No crees themes sin descripción**
   ```swift
   Theme(name: "Mi Tema", description: "", semanticColors: .default) // ❌
   ```

6. **No ignores el color scheme en previews**
   ```swift
   #Preview {
       MyView() // ❌ Falta .previewTheme() o colorScheme
   }
   ```

### Patrones Recomendados

#### 1. Organización de Custom Themes

```
Theme/
├── Sources/
│   └── Theme/
│       ├── CustomThemes/
│       │   ├── OceanTheme.swift
│       │   ├── ForestTheme.swift
│       │   └── DesertTheme.swift
│       └── CustomTokens/
│           ├── OceanTokens.swift
│           ├── ForestTokens.swift
│           └── DesertTokens.swift
```

#### 2. Extensiones Semánticas

Agrupa semantic colors por funcionalidad:

```swift
extension SemanticColors {
    // Form-specific colors
    var formBackground: ColorToken { surface }
    var formLabel: ColorToken { textSecondary }
    var formFieldBorder: ColorToken { border }
    var formFieldBorderFocused: ColorToken { borderFocus }
    
    // Button-specific colors
    var buttonPrimary: ColorToken { interactive }
    var buttonPrimaryHover: ColorToken { interactiveHover }
    var buttonPrimaryDisabled: ColorToken { interactiveDisabled }
}
```

#### 3. Theme Presets por Contexto

```swift
extension Theme {
    // Temas por tipo de app
    static let education = Theme(/* ... */)
    static let finance = Theme(/* ... */)
    static let health = Theme(/* ... */)
    
    // Temas por accesibilidad
    static let highContrastDark = Theme(/* ... */)
    static let largeText = Theme(/* ... */)
    static let colorBlind = Theme(/* ... */)
}
```

---

## Migración desde Colores Legacy

Si estás migrando código existente que usa colores hardcoded, usa `ThemeMigration`.

### Antes (Legacy)

```swift
struct OldView: View {
    var body: some View {
        Text("Error")
            .foregroundStyle(.red)
            .padding()
            .background(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.gray, lineWidth: 1)
            )
    }
}
```

### Después (Con Theming)

```swift
import Theme

struct NewView: View {
    var body: some View {
        Text("Error")
            .foregroundStyle(Color.theme.error)
            .padding()
            .background(Color.theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.theme.border, lineWidth: 1)
            )
    }
}
```

### Helper de Migración Automática

```swift
import Theme

let legacyColor: Color = .red
let semanticColor = ThemeMigration.migrateColor(legacyColor)
// Retorna Color.theme.error

#if DEBUG
// En debug mode, se imprime advertencia:
// "⚠️ Migrating legacy color .red to Color.theme.error"
#endif
```

### Guía de Mapeo de Colores

| Color Legacy | Semantic Color Recomendado |
|-------------|---------------------------|
| `.red` | `Color.theme.error` |
| `.green` | `Color.theme.success` |
| `.yellow` | `Color.theme.warning` |
| `.blue` | `Color.theme.interactive` o `Color.theme.info` |
| `.gray` | `Color.theme.textSecondary` o `Color.theme.border` |
| `.black` | `Color.theme.text` |
| `.white` | `Color.theme.surface` o `Color.theme.background` |
| `.orange` | `Color.theme.warning` |
| `.purple` | `Color.theme.interactive` (si es acción) |

### ViewModifier Migration Guide

```swift
// ValidationFieldModifier
// Antes:
.validationField(style: .standard, validation: emailValidation)

// Después:
.validationField(style: .themed, validation: emailValidation)

// FormErrorBannerModifier
// Antes:
.formErrorBanner(style: .standard, errorMessages: $errors)

// Después:
.formErrorBanner(style: .themed, errorMessages: $errors)
// o para warnings:
.formErrorBanner(style: .themedWarning, errorMessages: $warnings)

// ProgressBarModifier
// Antes:
.progressBar(style: .standard, isVisible: $isLoading, progress: $progress)

// Después:
.progressBar(style: .themed, isVisible: $isLoading, progress: $progress)

// LoadingOverlayModifier
// Antes:
.loadingOverlay(style: .standard, isLoading: $isLoading, message: "Cargando...")

// Después:
.loadingOverlay(style: .themed, isLoading: $isLoading, message: "Cargando...")
```

---

## Soporte y Recursos

### Documentación Adicional

- **API Reference**: Ver código fuente en `Theme/Sources/Theme/`
- **Tests**: Ver ejemplos en `Theme/Tests/ThemeTests/`
- **Previews**: Ver ejemplos en `ThemePreview.swift`

### Troubleshooting

#### Problema: Los colores no cambian cuando cambio el tema

**Solución**: Asegúrate de que tu view observa el ThemeManager:

```swift
@Environment(\.themeManager) private var themeManager
```

#### Problema: "Cannot find 'Color.theme' in scope"

**Solución**: Importa el módulo Theme:

```swift
import Theme
```

#### Problema: Colores aparecen incorrectos en dark mode

**Solución**: Verifica que tus ColorTokens tengan variantes `dark` definidas:

```swift
ColorToken(
    light: Color(hex: "#FFFFFF"),
    dark: Color(hex: "#000000") // ← Asegúrate de definir esto
)
```

#### Problema: ThemeSwitcher no aparece en watchOS

**Solución**: El ThemeSwitcher usa componentes adaptivos. En watchOS, verifica que tengas NavigationStack:

```swift
NavigationStack {
    ThemeSwitcher()
}
```

### Preguntas Frecuentes

**P: ¿Puedo usar Color Tokens directamente en mi UI?**  
R: No recomendado. Siempre usa `Color.theme.*` (semantic colors) en tu UI. Los Color Tokens solo se usan al crear custom themes.

**P: ¿Cómo creo un tema con soporte para daltonismo?**  
R: Crea un theme que use patrones además de colores, y evita combinaciones rojo-verde. Ejemplo:

```swift
static let colorBlindFriendly = Theme(
    name: "Color Blind Friendly",
    description: "Tema optimizado para usuarios con daltonismo",
    semanticColors: SemanticColors(
        error: ColorTokens.error600, // Rojo + icon ❌
        warning: ColorTokens.warning600, // Amarillo + icon ⚠️
        success: ColorTokens.info600, // Azul (en vez de verde) + icon ✓
        // ...
    )
)
```

**P: ¿El theming afecta el rendimiento?**  
R: No. Los semantic colors se resuelven en compile-time cuando es posible, y en runtime usan lookups O(1). El ThemeManager es @MainActor y thread-safe.

**P: ¿Puedo animar cambios de tema?**  
R: Sí, los cambios de tema automáticamente usan animaciones implícitas de SwiftUI. Para animaciones custom:

```swift
withAnimation(.easeInOut(duration: 0.3)) {
    ThemeManager.shared.setTheme(.highContrast)
}
```

**P: ¿Cómo testeo que mi componente funciona en todos los temas?**  
R: Usa `.previewAllThemes()` en tus previews, y crea snapshot tests para cada tema:

```swift
func testMyComponentInAllThemes() {
    for theme in [Theme.default, .highContrast, .grayscale] {
        ThemeManager.shared.loadCustomTheme(theme)
        // Assert visual correctness
    }
}
```

---

## Conclusión

El sistema de theming de EduGo está diseñado para ser:

- **Fácil de usar**: `Color.theme.text` en vez de colores hardcoded
- **Mantenible**: Cambios de diseño en un solo lugar (SemanticColors)
- **Escalable**: Agrega custom themes sin modificar código existente
- **Type-safe**: Errores en compile-time, no en runtime
- **Accesible**: Soporte para high contrast, dark mode, y más

**Siguiente Paso**: Empieza reemplazando colores hardcoded en tus views con `Color.theme.*` y usa `.themed` variants en tus ViewModifiers.

¡Feliz theming! 🎨
