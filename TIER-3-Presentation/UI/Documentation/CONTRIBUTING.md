# Guía de Contribución - EduGo UI Components

¡Gracias por tu interés en contribuir a EduGo UI Components! Esta guía te ayudará a entender cómo crear, modificar y mantener componentes de UI de manera consistente.

## Tabla de Contenidos

1. [Principios de Diseño](#principios-de-diseño)
2. [Estructura de Componentes](#estructura-de-componentes)
3. [Crear un Nuevo Componente](#crear-un-nuevo-componente)
4. [Testing y Previews](#testing-y-previews)
5. [Documentación](#documentación)
6. [Pull Requests](#pull-requests)
7. [Code Review](#code-review)

---

## Principios de Diseño

### 1. Consistencia

- Usa el sistema de diseño EduGo (`Styling` module)
- Sigue los patrones existentes
- Mantén la API consistente con otros componentes

### 2. Reusabilidad

- Componentes pequeños y enfocados
- Props configurables pero con buenos defaults
- Evita lógica de negocio específica

### 3. Accesibilidad

- Soporte para Dynamic Type
- Labels de VoiceOver descriptivos
- Contraste de colores adecuado
- Tamaños táctiles de 44x44 pts mínimo

### 4. Performance

- Lazy loading cuando sea apropiado
- Evitar cálculos pesados en el body
- Usar @Observable para estado

### 5. Multi-plataforma

- Diseñar para iOS y macOS
- Usar `#if os()` cuando sea necesario
- Adaptar automáticamente según la plataforma

---

## Estructura de Componentes

### Anatomía de un Componente

```swift
import SwiftUI
import Styling  // Si usa colores/tipografía del theme

/// Descripción breve del componente.
///
/// Características:
/// - Feature 1
/// - Feature 2
/// - Feature 3
@MainActor
public struct EduMyComponent: View {
    // MARK: - Types
    
    public enum Style {
        case primary
        case secondary
    }
    
    // MARK: - Properties
    
    private let title: String
    private let style: Style
    @Binding private var value: String
    
    // MARK: - Initializer
    
    /// Inicializa un EduMyComponent con opciones de personalización.
    ///
    /// - Parameters:
    ///   - title: Título del componente
    ///   - value: Binding al valor
    ///   - style: Estilo visual
    public init(
        title: String,
        value: Binding<String>,
        style: Style = .primary
    ) {
        self.title = title
        self._value = value
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        // Implementación
    }
    
    // MARK: - Helper Methods
    
    private var foregroundColor: Color {
        // Lógica de color
    }
}

// MARK: - Convenience Initializers

extension EduMyComponent {
    /// Crea un componente primary sin opciones.
    public static func primary(_ title: String) -> EduMyComponent {
        // Implementación
    }
}

// MARK: - Previews

#Preview("Estado Normal") {
    @Previewable @State var value = ""
    
    EduMyComponent(
        title: "Ejemplo",
        value: $value
    )
    .padding()
}

#Preview("Con Variantes") {
    @Previewable @State var value = ""
    
    VStack(spacing: 20) {
        EduMyComponent(title: "Primary", value: $value, style: .primary)
        EduMyComponent(title: "Secondary", value: $value, style: .secondary)
    }
    .padding()
}

#Preview("Dark Mode") {
    @Previewable @State var value = ""
    
    EduMyComponent(title: "Ejemplo", value: $value)
        .padding()
        .preferredColorScheme(.dark)
}
```

---

## Crear un Nuevo Componente

### Paso 1: Planificación

1. Define el propósito del componente
2. Lista las props necesarias
3. Identifica estados posibles (normal, loading, error, disabled)
4. Considera casos edge (texto largo, listas vacías, etc.)

### Paso 2: Ubicación

Coloca el componente en la categoría apropiada:

```
Sources/UI/
├── Input/          # Campos, botones, pickers
├── Containers/     # Cards, groups, sections
├── Lists/          # Rows, list views, states
├── Navigation/     # Nav bars, links, breadcrumbs
├── Feedback/       # Toasts, alerts, banners
├── Loading/        # Spinners, progress, skeletons
└── Utilities/      # Helpers, mocks
```

### Paso 3: Implementación

```swift
// 1. Crear el archivo
// Sources/UI/Input/EduMyComponent.swift

import SwiftUI
import Styling

/// Tu componente aquí
@MainActor
public struct EduMyComponent: View {
    // Implementación
}
```

### Paso 4: Tests

Crear test en `Tests/UITests/Input/EduMyComponentTests.swift`:

```swift
import Testing
@testable import UI

@Suite("EduMyComponent Tests")
struct EduMyComponentTests {
    
    @Test("Renders with default values")
    func testDefaultRender() {
        let component = EduMyComponent(title: "Test")
        #expect(component.title == "Test")
    }
    
    @Test("Changes style correctly")
    func testStyleChange() {
        let component = EduMyComponent(title: "Test", style: .secondary)
        #expect(component.style == .secondary)
    }
}
```

### Paso 5: Previews

Crear mínimo 3 previews:

```swift
#Preview("Normal State") {
    // Estado normal
}

#Preview("All Variants") {
    // Todas las variantes (styles, sizes, etc.)
}

#Preview("Edge Cases") {
    // Casos edge (texto largo, disabled, error, etc.)
}

#Preview("Dark Mode") {
    // Modo oscuro
}

#Preview("Interactive") {
    // Preview interactivo si aplica
}
```

### Paso 6: Documentación

1. Agregar comentarios de documentación (///)
2. Actualizar `COMPONENTS.md`
3. Agregar ejemplo en `INTEGRATION_GUIDE.md`

---

## Testing y Previews

### Testing Requirements

Cada componente debe tener:

1. **Unit Tests** - Lógica y estado
2. **Preview Tests** - Renderizado visual
3. **Accessibility Tests** - VoiceOver, Dynamic Type

### Preview Best Practices

```swift
// ✅ CORRECTO: Múltiples estados
#Preview("Loading") {
    MyComponent(isLoading: true)
}

#Preview("Error") {
    MyComponent(error: PreviewError.network)
}

#Preview("Success") {
    MyComponent(data: PreviewMocks.sampleData)
}

// ❌ INCORRECTO: Solo un preview
#Preview {
    MyComponent()
}
```

### Usar PreviewHelpers

```swift
#Preview("All Devices") {
    MyComponent()
        .previewDevice(.iPhone15Pro)
}

#Preview("Dynamic Type") {
    MyComponent()
        .previewCommonDynamicTypeSizes()
}

#Preview("All Color Schemes") {
    MyComponent()
        .previewAllColorSchemes()
}
```

### Usar PreviewMocks

```swift
#Preview("With Mock Data") {
    @Previewable @State var text = PreviewMocks.mediumText
    
    MyComponent(text: $text)
}

#Preview("With Mock ViewModel") {
    MyComponent(viewModel: MockListViewModel.loaded)
}
```

---

## Documentación

### Comentarios de Código

```swift
/// Descripción breve (una línea).
///
/// Descripción detallada (múltiples líneas si es necesario).
///
/// Características:
/// - Feature 1
/// - Feature 2
///
/// - Parameters:
///   - title: Descripción del parámetro
///   - action: Closure que se ejecuta cuando...
///
/// - Returns: Descripción del retorno
///
/// - Note: Información adicional importante
/// - Warning: Advertencias sobre uso
///
/// Ejemplo:
/// ```swift
/// EduButton.primary("Save") {
///     save()
/// }
/// ```
public func myFunction(title: String, action: @escaping () -> Void) {
    // Implementación
}
```

### Actualizar COMPONENTS.md

Para cada nuevo componente, agregar sección en `COMPONENTS.md`:

```markdown
### EduMyComponent

Descripción breve del componente.

**Props:**
- `title: String` - Descripción
- `style: Style` - Descripción

**Estilos disponibles:**
- `primary` - Descripción
- `secondary` - Descripción

**Ejemplo:**
\`\`\`swift
EduMyComponent(title: "Ejemplo", style: .primary)
\`\`\`

**Archivo:** `Sources/UI/Category/EduMyComponent.swift`
```

### Actualizar INTEGRATION_GUIDE.md

Agregar ejemplo de uso en contexto real.

---

## Pull Requests

### Antes de Crear el PR

1. ✅ Ejecutar tests: `swift test`
2. ✅ Verificar previews funcionen
3. ✅ Lint código (si aplica)
4. ✅ Actualizar documentación
5. ✅ Commits descriptivos

### Template de PR

```markdown
## Descripción

[Descripción clara de los cambios]

## Tipo de Cambio

- [ ] Nuevo componente
- [ ] Bug fix
- [ ] Mejora de componente existente
- [ ] Documentación
- [ ] Refactor

## Componentes Afectados

- EduMyComponent
- EduOtherComponent (si aplica)

## Testing

- [ ] Tests unitarios agregados/actualizados
- [ ] Previews agregados (mínimo 3)
- [ ] Probado en iOS
- [ ] Probado en macOS
- [ ] Probado con Dynamic Type
- [ ] Probado en Dark Mode

## Documentación

- [ ] COMPONENTS.md actualizado
- [ ] INTEGRATION_GUIDE.md actualizado
- [ ] Comentarios de código agregados

## Screenshots/Videos

[Si aplica, agregar screenshots de previews]

## Checklist

- [ ] Código sigue las guías de estilo
- [ ] Tests pasan
- [ ] Documentación completa
- [ ] Sin warnings de compilación
- [ ] Componente es multi-plataforma
- [ ] Accesibilidad implementada
```

---

## Code Review

### Como Autor

1. Auto-review antes de publicar
2. Responde a comentarios promptamente
3. Explica decisiones de diseño
4. Itera basándote en feedback

### Como Reviewer

Verificar:

1. **Funcionalidad**
   - ✅ Componente funciona según especificación
   - ✅ No tiene bugs obvios
   - ✅ Maneja casos edge

2. **Código**
   - ✅ Sigue las convenciones del proyecto
   - ✅ Es legible y mantenible
   - ✅ No tiene duplicación innecesaria
   - ✅ Performance es adecuada

3. **Testing**
   - ✅ Tests existen y son completos
   - ✅ Previews muestran todos los estados
   - ✅ Coverage es adecuado

4. **Documentación**
   - ✅ Comentarios son claros
   - ✅ COMPONENTS.md actualizado
   - ✅ INTEGRATION_GUIDE.md tiene ejemplos

5. **Accesibilidad**
   - ✅ Soporta Dynamic Type
   - ✅ VoiceOver funciona
   - ✅ Contraste es adecuado

6. **Multi-plataforma**
   - ✅ Funciona en iOS
   - ✅ Funciona en macOS
   - ✅ Adaptaciones apropiadas

---

## Convenciones de Código

### Naming

```swift
// ✅ CORRECTO
public struct EduButton: View { }
private func foregroundColor() -> Color { }
let isLoading: Bool

// ❌ INCORRECTO
public struct Button: View { }  // Falta prefijo Edu
private func GetForegroundColor() -> Color { }  // PascalCase
let loading: Bool  // No descriptivo
```

### Organization

```swift
// Orden de secciones en archivo:
// 1. Imports
// 2. Type definition
// 3. MARK: - Types (enums, structs anidados)
// 4. MARK: - Properties
// 5. MARK: - Initializer(s)
// 6. MARK: - Body
// 7. MARK: - Helper Methods
// 8. Extensions
// 9. MARK: - Previews
```

### Modifiers

```swift
// ✅ CORRECTO: Un modifier por línea cuando son muchos
Text("Hello")
    .font(.title)
    .foregroundStyle(.primary)
    .padding()
    .background(.blue)

// ✅ CORRECTO: En una línea cuando son pocos
Text("Hello").font(.title).foregroundStyle(.primary)
```

### Bindings

```swift
// ✅ CORRECTO
@Binding private var text: String

public init(text: Binding<String>) {
    self._text = text
}

// ❌ INCORRECTO
@Binding var text: String  // Falta private

public init(text: Binding<String>) {
    self.text = text  // Falta underscore
}
```

---

## Mejores Prácticas

### 1. Props y Defaults

```swift
// ✅ CORRECTO: Buenos defaults
public init(
    title: String,
    icon: String? = nil,
    style: Style = .primary,
    isDisabled: Bool = false
) {
    // ...
}

// ❌ INCORRECTO: Sin defaults
public init(
    title: String,
    icon: String?,
    style: Style,
    isDisabled: Bool
) {
    // ...
}
```

### 2. Computed Properties

```swift
// ✅ CORRECTO: Computed properties para lógica
private var foregroundColor: Color {
    switch style {
    case .primary: return .white
    case .secondary: return .accentColor
    }
}

// ❌ INCORRECTO: Lógica inline en body
Text("Hello")
    .foregroundStyle(
        style == .primary ? .white : .accentColor
    )
```

### 3. Convenience Initializers

```swift
// ✅ CORRECTO: Convenience para casos comunes
extension EduButton {
    public static func primary(_ title: String, action: @escaping () -> Void) -> EduButton {
        EduButton(title, style: .primary, action: action)
    }
}

// Uso: EduButton.primary("Save") { save() }
```

### 4. Observable State

```swift
// ✅ CORRECTO: @Observable para ViewModels
@MainActor
@Observable
final class MyViewModel {
    var items: [Item] = []
}

// ❌ INCORRECTO: ObservableObject (legacy)
class MyViewModel: ObservableObject {
    @Published var items: [Item] = []
}
```

---

## Ejemplos de Componentes Bien Implementados

Revisa estos componentes como referencia:

1. **EduButton** - Buen ejemplo de variantes y estados
2. **EduTextField** - Buen ejemplo de validación
3. **EduListView** - Buen ejemplo de estados automáticos
4. **EduNavigationBar** - Buen ejemplo de acciones opcionales

---

## Recursos

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [EduGo Styling Guide](../TIER-1-Core/Styling/README.md)

---

## Preguntas Frecuentes

**P: ¿Debo crear un componente para esto?**

R: Crea un componente si:
- Lo usarás en 3+ lugares
- Tiene lógica reutilizable
- Es una abstracción útil

**P: ¿Cuántos previews necesito?**

R: Mínimo 3:
- Estado normal
- Variantes (si las hay)
- Dark mode o caso edge

**P: ¿Debo soportar watchOS/tvOS?**

R: Por ahora solo iOS y macOS. Se puede extender después.

**P: ¿Cómo manejo estado complejo?**

R: Usa un ViewModel observable en lugar de state en la view.

**P: ¿Puedo usar librerías externas?**

R: Preferiblemente no. Consulta antes de agregar dependencias.

---

¡Gracias por contribuir a EduGo UI Components! 🎉
