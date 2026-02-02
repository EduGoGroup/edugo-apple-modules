# Guia de Contribucion - EduGo UI Components

Gracias por tu interes en contribuir al modulo UI de EduGo. Esta guia te ayudara a crear componentes consistentes y de alta calidad.

## Estructura del Proyecto

```
UI/
├── Sources/UI/
│   ├── Input/          # Campos de entrada (botones, text fields)
│   ├── Containers/     # Contenedores (cards, sections)
│   ├── Lists/          # Componentes de lista
│   ├── Feedback/       # Feedback al usuario (toasts, alerts)
│   ├── Loading/        # Indicadores de carga
│   ├── Navigation/     # Navegacion (tab bar, nav bar)
│   └── Utilities/      # Helpers y mocks para previews
├── Tests/UITests/      # Tests del modulo
├── Documentation/      # Documentacion
└── Package.swift
```

## Requisitos para Nuevos Componentes

### 1. Convenciones de Nombrado

- **Prefijo Edu**: Todos los componentes publicos deben usar el prefijo `Edu`
  - Correcto: `EduButton`, `EduCard`, `EduTextField`
  - Incorrecto: `Button`, `CustomButton`, `AppButton`

- **Nombres descriptivos**: El nombre debe indicar claramente la funcion
  - Correcto: `EduProgressCircle`, `EduEmptyStateView`
  - Incorrecto: `EduCircle`, `EduView`

### 2. Estructura del Archivo

```swift
import SwiftUI

// MARK: - [Nombre del Componente]

/// Descripcion breve del componente.
///
/// Caracteristicas principales:
/// - Feature 1
/// - Feature 2
///
/// Ejemplo de uso:
/// ```swift
/// EduComponent(param: value) {
///     // contenido
/// }
/// ```
@MainActor
public struct EduComponent: View {
    // MARK: - Types (si aplica)
    
    public enum Style {
        case primary
        case secondary
    }
    
    // MARK: - Properties
    
    private let title: String
    private let style: Style
    
    // MARK: - Initializer
    
    public init(
        title: String,
        style: Style = .primary
    ) {
        self.title = title
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        // Implementacion
    }
    
    // MARK: - Private Helpers (si aplica)
    
    private var computedProperty: Color {
        // ...
    }
}

// MARK: - Convenience Initializers (si aplica)

extension EduComponent {
    public static func primary(_ title: String) -> EduComponent {
        EduComponent(title: title, style: .primary)
    }
}

// MARK: - Previews

#Preview("Estado normal") {
    EduComponent(title: "Ejemplo")
}

#Preview("Estado loading") {
    EduComponent(title: "Cargando", isLoading: true)
}

#Preview("Dark Mode") {
    EduComponent(title: "Oscuro")
        .preferredColorScheme(.dark)
}
```

### 3. Previews Requeridos

Cada componente DEBE tener al menos 3 previews:

1. **Estado normal**: El componente en su estado por defecto
2. **Estados alternativos**: Loading, error, disabled, etc.
3. **Dark Mode**: El componente en modo oscuro

```swift
// MARK: - Previews

#Preview("Normal") {
    EduComponent(title: "Normal")
}

#Preview("Loading") {
    EduComponent(title: "Loading", isLoading: true)
}

#Preview("Disabled") {
    EduComponent(title: "Disabled", isDisabled: true)
}

#Preview("Dark Mode") {
    EduComponent(title: "Dark")
        .preferredColorScheme(.dark)
}

#Preview("Todos los estilos") {
    VStack(spacing: 16) {
        EduComponent.primary("Primary")
        EduComponent.secondary("Secondary")
    }
}
```

### 4. Accesibilidad

Todos los componentes deben ser accesibles:

```swift
public var body: some View {
    Button(action: action) {
        // contenido
    }
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint(accessibilityHint)
    .accessibilityAddTraits(.isButton)
}
```

Elementos a considerar:
- `accessibilityLabel`: Descripcion del elemento
- `accessibilityHint`: Que pasa al activarlo
- `accessibilityValue`: Valor actual (para sliders, progress, etc.)
- `accessibilityAddTraits`: Rasgos del elemento

### 5. Soporte Multi-Plataforma

Usa compilacion condicional cuando sea necesario:

```swift
public var body: some View {
    #if os(iOS) || os(visionOS)
    // Implementacion iOS/visionOS
    NavigationStack {
        content
    }
    #elseif os(macOS)
    // Implementacion macOS
    NavigationSplitView {
        sidebar
    } detail: {
        content
    }
    #endif
}
```

### 6. Concurrencia y Thread Safety

Todos los componentes de UI deben estar aislados al MainActor:

```swift
@MainActor
public struct EduComponent: View {
    // ...
}

@MainActor
@Observable
public final class EduManager: Sendable {
    // ...
}
```

### 7. Documentacion

Documenta todas las propiedades y metodos publicos:

```swift
/// Boton personalizado con multiples estilos.
///
/// - Parameters:
///   - title: Texto del boton
///   - style: Estilo visual (.primary, .secondary)
///   - isLoading: Si esta en estado de carga
///   - action: Closure ejecutado al presionar
///
/// - Note: El boton se deshabilita automaticamente durante la carga.
public init(
    _ title: String,
    style: Style = .primary,
    isLoading: Bool = false,
    action: @escaping () -> Void
) {
    // ...
}
```

## Proceso de Contribucion

### 1. Antes de Empezar

1. Revisa los componentes existentes para evitar duplicacion
2. Verifica que el componente sigue el diseno de Apple HIG
3. Considera si el componente es realmente necesario

### 2. Desarrollo

1. Crea el componente siguiendo la estructura indicada
2. Agrega previews comprehensivos
3. Asegurate de que compila en iOS y macOS
4. Agrega tests si el componente tiene logica compleja

### 3. Antes del PR

Lista de verificacion:

- [ ] El componente tiene prefijo `Edu`
- [ ] El archivo sigue la estructura estandar
- [ ] Tiene al menos 3 previews (normal, alternativo, dark mode)
- [ ] Soporta accesibilidad
- [ ] Esta anotado con `@MainActor`
- [ ] Tipos son `Sendable` cuando aplica
- [ ] Documentacion en comentarios
- [ ] Compila sin warnings en iOS y macOS
- [ ] Se actualizo COMPONENTS.md si es necesario

### 4. Review

El PR sera revisado por:
- Consistencia con otros componentes
- Cumplimiento de convenciones
- Calidad de previews
- Accesibilidad
- Performance

## Guias de Estilo

### Colores

Usa colores semanticos del sistema:

```swift
// Bien
.foregroundStyle(.primary)
.foregroundStyle(.secondary)
.background(Color.accentColor)

// Evitar
.foregroundColor(.black)
.background(Color.blue)
```

### Espaciado

Usa valores consistentes:

```swift
// Espaciado estandar
.padding()           // 16pt default
.padding(.small)     // 8pt
.padding(.medium)    // 16pt
.padding(.large)     // 24pt

// O valores explicitos multiplos de 4
.padding(8)
.padding(12)
.padding(16)
```

### Tipografia

Usa fuentes del sistema:

```swift
.font(.title)
.font(.headline)
.font(.body)
.font(.caption)
```

### Animaciones

Usa animaciones suaves y rapidas:

```swift
.animation(.easeInOut(duration: 0.2), value: isExpanded)
```

## Testing

### Tests Unitarios

Para componentes con logica:

```swift
@Test func testProgressCalculation() {
    let progress = EduProgressBar(mode: .determinate(0.5))
    #expect(progress.normalizedValue == 0.5)
}
```

### Tests de Snapshot (opcional)

Para verificar cambios visuales:

```swift
@Test func testButtonAppearance() {
    let button = EduButton.primary("Test")
    // Snapshot test
}
```

## Recursos

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [COMPONENTS.md](./COMPONENTS.md) - Referencia de componentes existentes
- [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md) - Guia de integracion

## Contacto

Si tienes preguntas sobre como contribuir, contacta al equipo de desarrollo.
