# EduGo UI Components

Biblioteca de componentes SwiftUI reutilizables para las aplicaciones EduGo en plataformas Apple (iOS y macOS).

## Características

- 🎨 **Diseño Consistente** - Sistema de diseño unificado con colores, tipografía y espaciado
- 📱 **Multi-plataforma** - Soporte nativo para iOS y macOS
- ♿️ **Accesible** - Dynamic Type, VoiceOver y alto contraste
- 🧩 **Modular** - Componentes pequeños y composables
- ✅ **Testeado** - Tests unitarios y previews completos
- 📚 **Documentado** - Documentación completa y ejemplos de uso

## Componentes Disponibles

### Input
- `EduButton` - Botones con variantes (primary, secondary, destructive, link)
- `EduTextField` - Campos de texto con validación
- `EduSecureField` - Campos de contraseña con toggle de visibilidad
- `EduSearchField` - Campo de búsqueda con icono

### Containers
- `EduCard` - Tarjetas con título y sombra
- `EduGroupBox` - Agrupación visual con borde
- `EduSection` - Secciones con header y footer

### Lists
- `EduListView` - Lista con estados automáticos (loading, error, empty)
- `EduRow` - Filas reutilizables con icono, título y badge
- `EduEmptyStateView` - Vista de estado vacío
- `EduErrorStateView` - Vista de estado de error
- `EduLoadingStateView` - Vista de estado de carga

### Navigation
- `EduNavigationBar` - Barra de navegación personalizada
- `EduNavigationLink` - Links de navegación con estilo
- `EduTabBar` - Barra de pestañas
- `EduBreadcrumbs` - Navegación breadcrumb

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
- `PreviewHelpers` - Helpers para Xcode Previews
- `PreviewMocks` - Datos mock para previews

## Instalación

Este módulo es parte del workspace EduGo Apple Modules.

```swift
// Package.swift
dependencies: [
    .package(path: "../UI")
]
```

## Uso Rápido

```swift
import SwiftUI
import UI

struct MyView: View {
    @State var email = ""
    @State var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            EduTextField(
                "Email",
                text: $email,
                placeholder: "tu@email.com",
                validation: Validators.email()
            )
            
            EduSecureField(
                "Contraseña",
                text: $password
            )
            
            EduButton.primary("Iniciar Sesión") {
                login()
            }
        }
        .padding()
    }
}
```

## Documentación

- **[COMPONENTS.md](Documentation/COMPONENTS.md)** - Documentación completa de todos los componentes
- **[INTEGRATION_GUIDE.md](Documentation/INTEGRATION_GUIDE.md)** - Guía de integración y patrones de uso
- **[CONTRIBUTING.md](Documentation/CONTRIBUTING.md)** - Guía para contribuir con nuevos componentes

## Ejemplos

### Lista con Estados Automáticos

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

### Formulario con Validación

```swift
struct CreateStudentView: View {
    @StateObject var formState = FormState()
    @State var name = ""
    @State var email = ""
    
    var body: some View {
        VStack(spacing: 20) {
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
// Mostrar toast de éxito
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

Cada componente incluye múltiples previews para facilitar el desarrollo:

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
// Dispositivos específicos
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

- `Styling` - Sistema de diseño EduGo
- `StateManagement` - Gestión de estado
- `Binding` - Validación de formularios

## Arquitectura

```
UI/
├── Sources/
│   └── UI/
│       ├── Input/          # Componentes de entrada
│       ├── Containers/     # Contenedores
│       ├── Lists/          # Componentes de listas
│       ├── Navigation/     # Navegación
│       ├── Feedback/       # Notificaciones y alerts
│       ├── Loading/        # Indicadores de carga
│       └── Utilities/      # Helpers y mocks
├── Tests/
│   └── UITests/           # Tests unitarios
├── Documentation/         # Documentación
│   ├── COMPONENTS.md
│   ├── INTEGRATION_GUIDE.md
│   └── CONTRIBUTING.md
└── Package.swift
```

## Plataformas Soportadas

| Plataforma | Versión Mínima | Estado |
|-----------|----------------|--------|
| iOS       | 26.0           | ✅ Soportado |
| macOS     | 26.0           | ✅ Soportado |
| watchOS   | -              | ⏳ Futuro |
| tvOS      | -              | ⏳ Futuro |
| visionOS  | -              | ⏳ Futuro |

## Accesibilidad

Todos los componentes incluyen:

- ✅ Soporte para Dynamic Type
- ✅ VoiceOver labels
- ✅ Contraste de colores WCAG AA
- ✅ Tamaños táctiles mínimos de 44x44 pts
- ✅ Soporte para Reduce Motion
- ✅ Soporte para High Contrast

## Contribuir

¿Quieres agregar un nuevo componente o mejorar uno existente?

1. Lee [CONTRIBUTING.md](Documentation/CONTRIBUTING.md)
2. Crea un branch desde `main`
3. Implementa el componente con tests y previews
4. Actualiza la documentación
5. Crea un Pull Request

## Licencia

Propiedad de EduGo. Todos los derechos reservados.

## Soporte

Para preguntas o problemas:
1. Consulta la documentación en `/Documentation/`
2. Revisa los previews de los componentes
3. Contacta al equipo de desarrollo

---

**Versión:** 1.0.0  
**Última actualización:** Febrero 2026
