# EduGo UI Components

Biblioteca de componentes SwiftUI reutilizables para las aplicaciones EduGo en plataformas Apple (iOS y macOS).

## Caracteristicas

- **Diseno Consistente** - Sistema de diseno unificado con colores, tipografia y espaciado
- **Multi-plataforma** - Soporte nativo para iOS y macOS
- **Accesible** - Dynamic Type, VoiceOver y alto contraste
- **Modular** - Componentes pequenos y composables
- **Testeado** - Tests unitarios y previews completos
- **Documentado** - Documentacion completa y ejemplos de uso

## Design Tokens

Este modulo utiliza un sistema centralizado de Design Tokens para mantener consistencia visual y facilitar el theming.

Ver documentacion completa: [DesignTokens.md](Documentation/DesignTokens.md)

### Quick Start

```swift
import UI

// Spacing
.padding(DesignTokens.Spacing.large)        // 16pt
.padding(DesignTokens.Spacing.medium)       // 12pt

// Corner Radius
.cornerRadius(DesignTokens.CornerRadius.medium)  // 8pt
.cornerRadius(DesignTokens.CornerRadius.xl)      // 12pt

// Shadow
.shadow(radius: DesignTokens.Shadow.medium)      // 4pt

// Border Width
.overlay(RoundedRectangle(cornerRadius: 8)
    .stroke(color, lineWidth: DesignTokens.BorderWidth.thin))  // 1pt

// Icon Size
Image(systemName: "star")
    .frame(width: DesignTokens.IconSize.medium,    // 24pt
           height: DesignTokens.IconSize.medium)

// Insets predefinidos
EduCard(padding: DesignTokens.Insets.cardHero)   // (24, 24, 24, 24)
```

## Componentes Disponibles

### Input
- `EduButton` - Botones con variantes (primary, secondary, destructive, link)
- `EduTextField` - Campos de texto con validacion
- `EduSecureField` - Campos de contrasena con toggle de visibilidad
- `EduSearchField` - Campo de busqueda con icono

### Containers
- `EduCard` - Tarjetas con titulo y sombra
- `EduGroupBox` - Agrupacion visual con borde
- `EduSection` - Secciones con header y footer

### Lists
- `EduListView` - Lista con estados automaticos (loading, error, empty)
- `EduRow` - Filas reutilizables con icono, titulo y badge
- `EduEmptyStateView` - Vista de estado vacio
- `EduErrorStateView` - Vista de estado de error
- `EduLoadingStateView` - Vista de estado de carga

### Navigation
- `EduNavigationBar` - Barra de navegacion personalizada
- `EduNavigationLink` - Links de navegacion con estilo
- `EduTabBar` - Barra de pestanas
- `EduBreadcrumbs` - Navegacion breadcrumb

### Feedback
- `EduToast` - Notificaciones toast temporales
- `EduBanner` - Banners informativos persistentes
- `EduAlert` - Alertas modales
- `EduModal` - Modales personalizados
- `EduActionSheet` - Action sheets
- `EduOverlayManager` - Gestor centralizado de overlays

### Loading
- `EduActivityIndicator` - Spinner circular
- `EduProgressBar` - Barra de progreso lineal
- `EduProgressCircle` - Progreso circular
- `EduSkeletonLoader` - Skeleton loaders

### Utilities
- `DesignTokens` - Tokens centralizados de diseno
- `PreviewHelpers` - Helpers para Xcode Previews
- `PreviewMocks` - Datos mock para previews

## Instalacion

Este modulo es parte del workspace EduGo Apple Modules.

```swift
// Package.swift
dependencies: [
    .package(path: "../UI")
]
```

## Uso Rapido

```swift
import SwiftUI
import UI

struct MyView: View {
    @State var email = ""
    @State var password = ""
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            EduTextField(
                "Email",
                text: $email,
                placeholder: "tu@email.com",
                validation: Validators.email()
            )
            
            EduSecureField(
                "Contrasena",
                text: $password
            )
            
            EduButton.primary("Iniciar Sesion") {
                login()
            }
        }
        .padding(DesignTokens.Spacing.large)
    }
}
```

## Documentacion

- **[DesignTokens.md](Documentation/DesignTokens.md)** - Sistema de Design Tokens
- **[COMPONENTS.md](Documentation/COMPONENTS.md)** - Documentacion completa de todos los componentes
- **[INTEGRATION_GUIDE.md](Documentation/INTEGRATION_GUIDE.md)** - Guia de integracion y patrones de uso
- **[CONTRIBUTING.md](Documentation/CONTRIBUTING.md)** - Guia para contribuir con nuevos componentes

## Ejemplos

### Lista con Estados Automaticos

```swift
struct StudentsView: View {
    @StateObject var viewModel = StudentsViewModel()
    
    var body: some View {
        EduListView(
            items: viewModel.students,
            isLoading: viewModel.isLoading,
            error: viewModel.error,
            emptyTitle: "No hay estudiantes",
            emptyMessage: "Comienza agregando estudiantes",
            retryAction: { viewModel.retry() }
        ) { student in
            EduRow(
                title: student.name,
                subtitle: student.grade,
                icon: "person.fill"
            )
        }
    }
}
```

### Formulario con Validacion

```swift
struct CreateStudentView: View {
    @StateObject var formState = FormState()
    @State var name = ""
    @State var email = ""
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            EduTextField(
                "Nombre",
                text: $name,
                validation: Validators.required("Nombre requerido"),
                formState: formState,
                fieldKey: "name"
            )
            
            EduTextField(
                "Email",
                text: $email,
                validation: Validators.email(),
                formState: formState,
                fieldKey: "email"
            )
            
            EduButton.primary(
                "Crear",
                isDisabled: !formState.isValid
            ) {
                create()
            }
        }
    }
}
```

### Feedback con Toasts

```swift
// Mostrar toast de exito
ToastManager.shared.show(
    "Guardado exitosamente",
    style: .success,
    duration: 3.0
)

// Mostrar toast de error
ToastManager.shared.show(
    "Error al guardar",
    style: .error,
    duration: 5.0
)
```

## Previews

Cada componente incluye multiples previews para facilitar el desarrollo:

```swift
#Preview("Normal State") {
    @Previewable @State var text = ""
    
    EduTextField("Email", text: $text)
        .padding()
}

#Preview("Dark Mode") {
    @Previewable @State var text = "test@example.com"
    
    EduTextField("Email", text: $text)
        .padding()
        .preferredColorScheme(.dark)
}
```

### Preview Helpers

```swift
// Dispositivos especificos
MyView()
    .previewDevice(.iPhone15Pro)

// Todos los color schemes
MyView()
    .previewAllColorSchemes()

// Dynamic Type sizes
MyView()
    .previewCommonDynamicTypeSizes()

// Locales
MyView()
    .previewCommonLocales()
```

## Testing

Ejecutar tests:

```bash
swift test
```

Cada componente tiene:
- Tests unitarios
- Previews completos
- Tests de accesibilidad

## Requisitos

- iOS 26.0+
- macOS 26.0+
- Swift 6.2+
- Xcode 16.0+

## Dependencias

- `Styling` - Sistema de diseno EduGo
- `StateManagement` - Gestion de estado
- `Binding` - Validacion de formularios

## Arquitectura

```
UI/
├── Sources/
│   └── UI/
│       ├── Input/          # Componentes de entrada
│       ├── Containers/     # Contenedores
│       ├── Lists/          # Componentes de listas
│       ├── Navigation/     # Navegacion
│       ├── Feedback/       # Notificaciones y alerts
│       ├── Loading/        # Indicadores de carga
│       └── Utilities/      # DesignTokens, helpers y mocks
├── Tests/
│   └── UITests/           # Tests unitarios
├── Documentation/         # Documentacion
│   ├── DesignTokens.md
│   ├── COMPONENTS.md
│   ├── INTEGRATION_GUIDE.md
│   └── CONTRIBUTING.md
└── Package.swift
```

## Plataformas Soportadas

| Plataforma | Version Minima | Estado |
|-----------|----------------|--------|
| iOS       | 26.0           | Soportado |
| macOS     | 26.0           | Soportado |
| watchOS   | -              | Futuro |
| tvOS      | -              | Futuro |
| visionOS  | -              | Futuro |

## Accesibilidad

Todos los componentes incluyen:

- Soporte para Dynamic Type
- VoiceOver labels
- Contraste de colores WCAG AA
- Tamanos tactiles minimos de 44x44 pts
- Soporte para Reduce Motion
- Soporte para High Contrast

## Contribuir

Quieres agregar un nuevo componente o mejorar uno existente?

1. Lee [CONTRIBUTING.md](Documentation/CONTRIBUTING.md)
2. Crea un branch desde `main`
3. Implementa el componente con tests y previews
4. Actualiza la documentacion
5. Crea un Pull Request

## Licencia

Propiedad de EduGo. Todos los derechos reservados.

## Soporte

Para preguntas o problemas:
1. Consulta la documentacion en `/Documentation/`
2. Revisa los previews de los componentes
3. Contacta al equipo de desarrollo

---

**Version:** 1.1.0  
**Ultima actualizacion:** Febrero 2026
