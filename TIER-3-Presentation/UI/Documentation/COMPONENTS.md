# EduGo UI Components

Documentacion completa de los componentes SwiftUI disponibles en el modulo UI.

## Plataformas Soportadas

| Plataforma | Version Minima |
|------------|----------------|
| iOS        | 26+            |
| macOS      | 26+            |

## Indice

- [Input Components](#input-components)
- [Container Components](#container-components)
- [List Components](#list-components)
- [Feedback Components](#feedback-components)
- [Loading Components](#loading-components)
- [Navigation Components](#navigation-components)
- [Utilities](#utilities)

---

## Input Components

### EduButton

Boton generico con variantes de estilo y soporte multi-plataforma.

**Ubicacion:** `Sources/UI/Input/EduButton.swift`

**Propiedades:**

| Propiedad | Tipo | Default | Descripcion |
|-----------|------|---------|-------------|
| title | String | requerido | Texto del boton |
| icon | String? | nil | Nombre del SF Symbol |
| iconPosition | IconPosition | .leading | Posicion del icono |
| style | Style | .primary | Estilo visual |
| size | Size | .medium | Tamano del boton |
| isLoading | Bool | false | Estado de carga |
| isDisabled | Bool | false | Estado deshabilitado |
| action | () -> Void | requerido | Accion al presionar |

**Estilos disponibles:**
- `.primary` - Fondo de color accent, texto blanco
- `.secondary` - Borde de color accent, fondo transparente
- `.destructive` - Borde rojo, para acciones peligrosas
- `.link` - Sin fondo ni borde, solo texto

**Tamanos:**
- `.small` - Padding reducido
- `.medium` - Tamano estandar
- `.large` - Padding amplio

**Ejemplo:**

```swift
// Boton primary basico
EduButton.primary("Guardar") {
    saveData()
}

// Boton con icono
EduButton(
    "Compartir",
    icon: "square.and.arrow.up",
    style: .secondary
) {
    shareContent()
}

// Boton en estado de carga
EduButton.primary("Enviando...", isLoading: true) { }
```

---

### EduTextField

Campo de texto con validacion integrada.

**Ubicacion:** `Sources/UI/Input/EduTextField.swift`

**Propiedades:**

| Propiedad | Tipo | Default | Descripcion |
|-----------|------|---------|-------------|
| placeholder | String | requerido | Texto placeholder |
| text | Binding<String> | requerido | Binding del texto |
| icon | String? | nil | Icono leading |
| isSecure | Bool | false | Campo de contrasena |
| validation | Validation? | nil | Regla de validacion |

**Ejemplo:**

```swift
@State private var email = ""

EduTextField("Email", text: $email, icon: "envelope")
```

---

### EduSecureField

Campo de contrasena con toggle de visibilidad.

**Ubicacion:** `Sources/UI/Input/EduSecureField.swift`

**Ejemplo:**

```swift
@State private var password = ""

EduSecureField("Contrasena", text: $password)
```

---

### EduSearchField

Campo de busqueda con icono y boton de limpiar.

**Ubicacion:** `Sources/UI/Input/EduSearchField.swift`

**Ejemplo:**

```swift
@State private var query = ""

EduSearchField("Buscar...", text: $query)
```

---

## Container Components

### EduCard

Contenedor tarjeta estilizada con sombra y esquinas redondeadas.

**Ubicacion:** `Sources/UI/Containers/EduCard.swift`

**Propiedades:**

| Propiedad | Tipo | Default | Descripcion |
|-----------|------|---------|-------------|
| padding | CGFloat | 16 | Padding interno |
| cornerRadius | CGFloat | 12 | Radio de esquinas |
| content | View | requerido | Contenido de la tarjeta |

**Ejemplo:**

```swift
EduCard {
    VStack {
        Text("Titulo")
            .font(.headline)
        Text("Descripcion del contenido")
    }
}
```

---

### EduSection

Seccion de contenido con titulo y separadores.

**Ubicacion:** `Sources/UI/Containers/EduSection.swift`

**Ejemplo:**

```swift
EduSection(title: "Configuracion") {
    Toggle("Notificaciones", isOn: $notificationsEnabled)
    Toggle("Modo oscuro", isOn: $darkModeEnabled)
}
```

---

### EduGroupBox

Caja de grupo con estilo nativo.

**Ubicacion:** `Sources/UI/Containers/EduGroupBox.swift`

---

## List Components

### EduListView

Lista principal con gestion de estados (loading, success, error, empty).

**Ubicacion:** `Sources/UI/Lists/EduListView.swift`

**Propiedades:**

| Propiedad | Tipo | Default | Descripcion |
|-----------|------|---------|-------------|
| state | ViewState<[Item]> | requerido | Estado de la lista |
| emptyTitle | String | "Sin resultados" | Titulo estado vacio |
| emptyDescription | String | "No hay elementos" | Descripcion estado vacio |
| onRetry | (() -> Void)? | nil | Accion de reintento |
| content | (Item) -> View | requerido | Vista por item |

**Estados:**
- `.loading` - Muestra skeleton loader
- `.success([Item])` - Muestra lista de items
- `.error(String)` - Muestra vista de error con retry
- `.empty` - Muestra vista de estado vacio

**Ejemplo:**

```swift
EduListView(
    state: viewModel.state,
    emptyTitle: "Sin cursos",
    emptyDescription: "No tienes cursos inscritos",
    onRetry: { viewModel.loadCourses() }
) { course in
    EduRow(title: course.name, subtitle: course.instructor)
}
```

---

### EduRow

Fila personalizable con swipe actions.

**Ubicacion:** `Sources/UI/Lists/EduRow.swift`

**Propiedades:**

| Propiedad | Tipo | Default | Descripcion |
|-----------|------|---------|-------------|
| title | String | requerido | Titulo principal |
| subtitle | String? | nil | Subtitulo |
| icon | String? | nil | Icono leading |
| accessory | Accessory | .chevron | Accesorio trailing |
| swipeActions | [SwipeAction] | [] | Acciones de swipe |

**Ejemplo:**

```swift
EduRow(
    title: "Matematicas",
    subtitle: "Prof. Garcia",
    icon: "book"
)
```

---

### EduEmptyStateView

Vista de estado vacio con icono, titulo y accion opcional.

**Ubicacion:** `Sources/UI/Lists/EduEmptyStateView.swift`

**Ejemplo:**

```swift
EduEmptyStateView(
    icon: "tray",
    title: "Sin mensajes",
    description: "No tienes mensajes nuevos",
    actionTitle: "Actualizar"
) {
    refreshMessages()
}
```

---

### EduLoadingStateView

Vista de carga con skeleton animado.

**Ubicacion:** `Sources/UI/Lists/EduLoadingStateView.swift`

---

### EduErrorStateView

Vista de error con mensaje y boton de reintento.

**Ubicacion:** `Sources/UI/Lists/EduErrorStateView.swift`

**Ejemplo:**

```swift
EduErrorStateView(
    title: "Error de conexion",
    message: "No se pudo cargar la informacion",
    retryTitle: "Reintentar"
) {
    viewModel.retry()
}
```

---

## Feedback Components

### EduBanner

Banner informativo con diferentes estilos.

**Ubicacion:** `Sources/UI/Feedback/EduBanner.swift`

**Estilos:**
- `.info` - Azul, informativo
- `.success` - Verde, exito
- `.warning` - Naranja, advertencia
- `.error` - Rojo, error

**Ejemplo:**

```swift
EduBanner(
    message: "Cambios guardados exitosamente",
    style: .success
)
```

---

### EduToast

Notificacion tipo toast con auto-dismiss.

**Ubicacion:** `Sources/UI/Feedback/EduToast.swift`

**Uso con ToastManager:**

```swift
// Mostrar toast
ToastManager.shared.show("Guardado", style: .success)

// En la vista raiz
.eduToastOverlay()
```

---

### EduAlert

Sistema de alertas nativas con acciones.

**Ubicacion:** `Sources/UI/Feedback/EduAlert.swift`

**Ejemplo:**

```swift
// Usando el modifier
.eduAlert(
    isPresented: $showAlert,
    content: EduAlertContent(
        title: "Confirmar",
        message: "Deseas continuar?",
        actions: [
            EduAlertAction(title: "Cancelar", role: .cancel) { },
            EduAlertAction(title: "Confirmar") { confirm() }
        ]
    )
)

// Usando AlertManager
EduAlertManager.shared.showConfirmation(
    title: "Eliminar",
    message: "Esta accion no se puede deshacer",
    onConfirm: { delete() }
)
```

---

### EduActionSheet

Action sheet adaptativo por plataforma.

**Ubicacion:** `Sources/UI/Feedback/EduActionSheet.swift`

**Ejemplo:**

```swift
.eduActionSheet(
    isPresented: $showOptions,
    content: EduActionSheetContent(
        title: "Opciones",
        actions: [
            EduActionSheetAction(title: "Editar", icon: "pencil") { edit() },
            EduActionSheetAction(title: "Eliminar", role: .destructive) { delete() },
            EduActionSheetAction(title: "Cancelar", role: .cancel) { }
        ]
    )
)
```

---

### EduModal

Sistema de modales con diferentes tamanos.

**Ubicacion:** `Sources/UI/Feedback/EduModal.swift`

**Tamanos:**
- `.small` - 300pt
- `.medium` - 500pt
- `.large` - 700pt
- `.fullScreen` - Pantalla completa

**Ejemplo:**

```swift
.eduModal(isPresented: $showModal) {
    EduModalContent(title: "Configuracion", size: .medium) {
        // Contenido del modal
    }
}
```

---

### EduOverlayManager

Gestor centralizado de overlays (toasts, alerts, modals).

**Ubicacion:** `Sources/UI/Feedback/EduOverlayManager.swift`

**Uso:**

```swift
// En la vista raiz
ContentView()
    .eduOverlay()
```

---

## Loading Components

### EduActivityIndicator

Indicador de actividad adaptativo por plataforma.

**Ubicacion:** `Sources/UI/Loading/EduActivityIndicator.swift`

**Tamanos:** `.small`, `.medium`, `.large`

**Ejemplo:**

```swift
EduActivityIndicator(style: .medium, color: .blue)

// Con loading overlay
.loadingOverlay(isLoading: true, message: "Procesando...")
```

---

### EduProgressBar

Barra de progreso lineal.

**Ubicacion:** `Sources/UI/Loading/EduProgressBar.swift`

**Modos:**
- `.determinate(Double)` - Progreso especifico (0.0 a 1.0)
- `.indeterminate` - Progreso continuo

**Estilos:** `.linear`, `.rounded`, `.thin`

**Ejemplo:**

```swift
// Barra con progreso
EduProgressBar(mode: .determinate(0.75), style: .rounded)

// Con etiqueta
EduLabeledProgressBar(progress: 0.5, label: "Descargando...")

// Segmentado
EduSegmentedProgressBar(totalSteps: 5, currentStep: 3)
```

---

### EduProgressCircle

Indicador de progreso circular.

**Ubicacion:** `Sources/UI/Loading/EduProgressCircle.swift`

**Variantes:**
- `EduProgressCircle` - Circulo basico
- `EduIndeterminateCircle` - Animacion continua
- `EduCircularProgressWithIcon` - Con icono central
- `EduMultiRingProgress` - Multiples anillos
- `EduGaugeProgress` - Estilo gauge (semi-circulo)

**Ejemplo:**

```swift
EduProgressCircle(progress: 0.75, showPercentage: true)
    .frame(width: 100, height: 100)
```

---

### EduSkeletonLoader

Skeleton loader con efecto shimmer.

**Ubicacion:** `Sources/UI/Loading/EduSkeletonLoader.swift`

**Formas:**
- `.rectangle`
- `.roundedRectangle(CGFloat)`
- `.circle`
- `.capsule`

**Componentes prefabricados:**
- `EduSkeletonText` - Para texto
- `EduSkeletonImage` - Para imagenes
- `EduSkeletonCard` - Para tarjetas
- `EduSkeletonList` - Para listas
- `EduSkeletonListRow` - Para filas

**Ejemplo:**

```swift
EduSkeletonCard(showImage: true, lines: 3)

// Con efecto shimmer
EduSkeletonGroup {
    EduSkeletonListRow()
    EduSkeletonListRow()
}
```

---

## Navigation Components

### EduNavigationBar

Barra de navegacion personalizada y native.

**Ubicacion:** `Sources/UI/Navigation/EduNavigationBar.swift`

**Ejemplo personalizado:**

```swift
EduNavigationBar(
    title: "Perfil",
    leadingItem: EduNavigationBarItem(icon: "chevron.left") { goBack() },
    trailingItem: EduNavigationBarItem(icon: "gear") { openSettings() }
) {
    // Contenido
}
```

**Ejemplo nativo:**

```swift
.eduNavigationBar(title: "Dashboard", displayMode: .large)
.eduNavigationBarItems(
    leading: EduNavigationBarItem(icon: "chevron.left") { },
    trailing: EduNavigationBarItem(icon: "plus") { }
)
```

---

### EduTabBar

TabBar multi-plataforma adaptativo.

**Ubicacion:** `Sources/UI/Navigation/EduTabBar.swift`

**Limites:** 2-5 tabs (segun iOS Human Interface Guidelines)

**Ejemplo:**

```swift
@State var selection = "home"

let items = [
    EduTabItem(id: "home", title: "Inicio", icon: "house", selectedIcon: "house.fill"),
    EduTabItem(id: "search", title: "Buscar", icon: "magnifyingglass"),
    EduTabItem(id: "profile", title: "Perfil", icon: "person", badge: "3")
]

EduTabBar(selection: $selection, items: items) { tabId in
    switch tabId {
    case "home": HomeView()
    case "search": SearchView()
    case "profile": ProfileView()
    default: EmptyView()
    }
}
```

---

### EduNavigationLink

NavigationLink mejorado con lazy loading y estado disabled.

**Ubicacion:** `Sources/UI/Navigation/EduNavigationLink.swift`

**Variantes:**
- `EduNavigationLink` - Basico con lazy loading
- `EduStyledNavigationLink` - Con estilos predefinidos (.plain, .card, .row)
- `EduTrackedNavigationLink` - Con tracking de navegacion

**Ejemplo:**

```swift
// Basico
EduNavigationLink {
    DetailView()
} label: {
    Text("Ver detalles")
}

// Styled
EduStyledNavigationLink(
    title: "Configuracion",
    subtitle: "Ajustes de la app",
    icon: "gear",
    style: .row
) {
    SettingsView()
}
```

---

### EduBreadcrumbs

Navegacion por migas de pan (solo macOS).

**Ubicacion:** `Sources/UI/Navigation/EduBreadcrumbs.swift`

**Ejemplo:**

```swift
#if os(macOS)
EduBreadcrumbs(
    items: [
        EduBreadcrumbItem(id: "home", title: "Inicio", destination: "home"),
        EduBreadcrumbItem(id: "docs", title: "Documentos", destination: "docs"),
        EduBreadcrumbItem(id: "file", title: "Archivo.pdf")
    ]
) { destination in
    navigateTo(destination)
}
#endif
```

---

## Utilities

### PreviewHelpers

Helpers para facilitar Xcode Previews.

**Ubicacion:** `Sources/UI/Utilities/PreviewHelpers.swift`

**Dispositivos disponibles:**
- iOS: `.iPhone15Pro`, `.iPhone15ProMax`, `.iPhoneSE`, `.iPadPro13`, `.iPadAir`
- macOS: `.macOS`
- visionOS: `.appleVisionPro`
- watchOS: `.appleWatchSeries9_41mm`, `.appleWatchSeries9_45mm`, `.appleWatchUltra2`
- tvOS: `.appleTV4K`

**Extensiones de View:**
- `.previewDevice(_:)` - Dispositivo especifico
- `.previewAllColorSchemes()` - Modo claro y oscuro
- `.previewSizeClasses(horizontal:vertical:)` - Size classes (iOS)
- `.previewDynamicTypeSize(_:)` - Tamano de fuente
- `.previewCommonLocales()` - Locales comunes

**Ejemplo:**

```swift
#Preview("All Platforms") {
    MyView()
        .previewAllColorSchemes()
}

#Preview("Dynamic Type") {
    MyView()
        .previewCommonDynamicTypeSizes()
}
```

---

### PreviewMocks

Datos mock y bindings para Previews.

**Ubicacion:** `Sources/UI/Utilities/PreviewMocks.swift`

**Datos disponibles:**
- Textos: `.shortText`, `.mediumText`, `.longText`, `.loremIpsum`
- Usuario: `.userName`, `.userEmail`
- Listas: `.shortList`, `.mediumList`, `.longList`, `.emptyList`
- Numeros: `.smallNumber`, `.mediumNumber`, `.largeNumber`
- Fechas: `.today`, `.yesterday`, `.tomorrow`, `.lastWeek`
- Errores: `.genericError`, `.networkError`, `.validationError`

**Mock ViewModels:**
- `MockLoadingViewModel` - Para estados de carga
- `MockFormViewModel` - Para formularios
- `MockListViewModel` - Para listas con estados

**Bindings mock:**

```swift
@State var text = PreviewMocks.userName
@State var isOn: Bool = .mock(true)
```

---

## Mejores Practicas

### 1. Usar estados consistentes

```swift
// Preferir ViewState para listas
EduListView(state: viewModel.state) { item in
    EduRow(title: item.name)
}
```

### 2. Combinar componentes

```swift
EduCard {
    EduSection(title: "Informacion") {
        EduTextField("Nombre", text: $name)
        EduTextField("Email", text: $email)
    }
    EduButton.primary("Guardar") { save() }
}
```

### 3. Usar managers centralizados

```swift
// En la vista raiz
ContentView()
    .eduOverlay()

// En cualquier parte de la app
ToastManager.shared.show("Exito", style: .success)
EduAlertManager.shared.showConfirmation(title: "Confirmar", onConfirm: { })
```

### 4. Previews comprehensivos

```swift
#Preview("Normal") { MyComponent() }
#Preview("Loading") { MyComponent(isLoading: true) }
#Preview("Error") { MyComponent(error: "Error") }
#Preview("Dark Mode") { MyComponent().preferredColorScheme(.dark) }
```
