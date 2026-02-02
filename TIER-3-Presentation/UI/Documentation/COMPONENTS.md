# EduGo UI Components - Documentación Completa

## Tabla de Contenidos

1. [Input Components](#input-components)
2. [Containers](#containers)
3. [Lists](#lists)
4. [Navigation](#navigation)
5. [Feedback](#feedback)
6. [Loading](#loading)
7. [Utilities](#utilities)

---

## Input Components

### EduButton

Botón genérico con variantes de estilo y soporte multi-plataforma.

**Props:**
- `title: String` - Texto del botón
- `icon: String?` - Nombre del SF Symbol opcional
- `iconPosition: IconPosition` - Posición del icono (.leading o .trailing)
- `style: Style` - Estilo visual (.primary, .secondary, .destructive, .link)
- `size: Size` - Tamaño del botón (.small, .medium, .large)
- `isLoading: Bool` - Estado de carga (muestra spinner)
- `isDisabled: Bool` - Si el botón está deshabilitado
- `action: () -> Void` - Closure que se ejecuta al presionar

**Estilos disponibles:**
- `primary` - Botón principal con fondo de color acento
- `secondary` - Botón secundario con borde
- `destructive` - Botón destructivo en rojo
- `link` - Botón de texto sin fondo

**Ejemplo:**
```swift
EduButton.primary("Guardar", size: .medium) {
    print("Guardado")
}

EduButton(
    "Eliminar",
    icon: "trash",
    style: .destructive,
    action: { print("Eliminado") }
)
```

**Archivo:** `Sources/UI/Input/EduButton.swift`

---

### EduTextField

TextField genérico con validación integrada y soporte multi-plataforma.

**Props:**
- `title: String` - Título del campo (label)
- `text: Binding<String>` - Binding al texto del campo
- `placeholder: String` - Texto placeholder cuando está vacío
- `helperText: String?` - Texto de ayuda opcional
- `validation: ((String) -> ValidationResult)?` - Closure de validación
- `formState: FormState?` - FormState opcional para integración
- `fieldKey: String?` - Clave única para registro en FormState
- `isDisabled: Bool` - Si el campo está deshabilitado
- `onCommit: (() -> Void)?` - Closure al presionar enter

**Estados:**
- Normal
- Focused (borde azul)
- Error (borde rojo + mensaje)
- Disabled (opacidad reducida)

**Ejemplo:**
```swift
@State var email = ""

EduTextField(
    "Email",
    text: $email,
    placeholder: "tu@email.com",
    validation: Validators.email()
)
```

**Archivo:** `Sources/UI/Input/EduTextField.swift`

---

### EduSecureField

Campo de contraseña con visibilidad toggle.

**Props:**
- Similares a `EduTextField`
- `showPassword: Binding<Bool>` - Control de visibilidad

**Ejemplo:**
```swift
@State var password = ""
@State var showPassword = false

EduSecureField(
    "Contraseña",
    text: $password,
    showPassword: $showPassword
)
```

**Archivo:** `Sources/UI/Input/EduSecureField.swift`

---

### EduSearchField

Campo de búsqueda con icono y botón de limpiar.

**Props:**
- `text: Binding<String>` - Binding al texto de búsqueda
- `placeholder: String` - Placeholder
- `onSearch: ((String) -> Void)?` - Callback al buscar

**Ejemplo:**
```swift
@State var searchText = ""

EduSearchField(
    text: $searchText,
    placeholder: "Buscar estudiantes..."
) { query in
    print("Buscando: \(query)")
}
```

**Archivo:** `Sources/UI/Input/EduSearchField.swift`

---

## Containers

### EduCard

Contenedor tipo tarjeta con sombra y bordes redondeados.

**Props:**
- `title: String?` - Título opcional
- `subtitle: String?` - Subtítulo opcional
- `content: () -> Content` - Contenido de la tarjeta

**Ejemplo:**
```swift
EduCard(title: "Estudiantes", subtitle: "Total: 25") {
    Text("Contenido de la tarjeta")
}
```

**Archivo:** `Sources/UI/Containers/EduCard.swift`

---

### EduGroupBox

Agrupación visual de contenido con título.

**Props:**
- `title: String` - Título del grupo
- `content: () -> Content` - Contenido agrupado

**Ejemplo:**
```swift
EduGroupBox(title: "Información Personal") {
    VStack {
        Text("Nombre: Juan")
        Text("Email: juan@example.com")
    }
}
```

**Archivo:** `Sources/UI/Containers/EduGroupBox.swift`

---

### EduSection

Sección de contenido con header y footer opcionales.

**Props:**
- `header: String?` - Texto del header
- `footer: String?` - Texto del footer
- `content: () -> Content` - Contenido de la sección

**Ejemplo:**
```swift
EduSection(
    header: "Ajustes",
    footer: "Personaliza tu experiencia"
) {
    Toggle("Notificaciones", isOn: $enabled)
}
```

**Archivo:** `Sources/UI/Containers/EduSection.swift`

---

## Lists

### EduListView

Lista genérica con estados de carga, error y vacío.

**Props:**
- `items: [Item]` - Array de items Identifiable
- `isLoading: Bool` - Estado de carga
- `error: Error?` - Error opcional
- `emptyTitle: String` - Título cuando está vacío
- `emptyMessage: String` - Mensaje cuando está vacío
- `emptyIcon: String` - Icono cuando está vacío
- `retryAction: (() -> Void)?` - Acción de reintentar
- `content: (Item) -> Content` - Builder del contenido

**Estados automáticos:**
- Loading: Muestra `EduLoadingStateView`
- Error: Muestra `EduErrorStateView`
- Empty: Muestra `EduEmptyStateView`
- Loaded: Muestra la lista

**Ejemplo:**
```swift
EduListView(
    items: students,
    isLoading: viewModel.isLoading,
    error: viewModel.error,
    emptyTitle: "No hay estudiantes",
    emptyMessage: "Comienza agregando estudiantes",
    retryAction: { viewModel.retry() }
) { student in
    EduRow(
        title: student.name,
        subtitle: student.grade
    )
}
```

**Archivo:** `Sources/UI/Lists/EduListView.swift`

---

### EduRow

Fila reutilizable para listas.

**Props:**
- `title: String` - Título principal
- `subtitle: String?` - Subtítulo opcional
- `icon: String?` - Icono SF Symbol opcional
- `iconColor: Color` - Color del icono
- `badge: String?` - Badge opcional
- `action: (() -> Void)?` - Acción al tocar

**Ejemplo:**
```swift
EduRow(
    title: "María González",
    subtitle: "5to Grado",
    icon: "person.fill",
    iconColor: .blue,
    badge: "Nuevo",
    action: { print("Tapped") }
)
```

**Archivo:** `Sources/UI/Lists/EduRow.swift`

---

### EduEmptyStateView

Vista de estado vacío para listas.

**Props:**
- `title: String` - Título
- `message: String` - Mensaje descriptivo
- `icon: String` - Icono SF Symbol
- `action: (() -> Void)?` - Acción opcional
- `actionTitle: String?` - Título del botón de acción

**Ejemplo:**
```swift
EduEmptyStateView(
    title: "No hay estudiantes",
    message: "Comienza agregando tu primer estudiante",
    icon: "person.2.slash",
    action: { print("Add tapped") },
    actionTitle: "Agregar Estudiante"
)
```

**Archivo:** `Sources/UI/Lists/EduEmptyStateView.swift`

---

### EduErrorStateView

Vista de estado de error para listas.

**Props:**
- `title: String` - Título del error
- `message: String` - Mensaje descriptivo
- `retryAction: (() -> Void)?` - Acción de reintentar

**Ejemplo:**
```swift
EduErrorStateView(
    title: "Error de Conexión",
    message: "No se pudo conectar al servidor",
    retryAction: { viewModel.retry() }
)
```

**Archivo:** `Sources/UI/Lists/EduErrorStateView.swift`

---

### EduLoadingStateView

Vista de estado de carga para listas.

**Props:**
- `message: String` - Mensaje de carga

**Ejemplo:**
```swift
EduLoadingStateView(message: "Cargando estudiantes...")
```

**Archivo:** `Sources/UI/Lists/EduLoadingStateView.swift`

---

## Navigation

### EduNavigationBar

Barra de navegación personalizada con acciones.

**Props:**
- `title: String` - Título principal
- `subtitle: String?` - Subtítulo opcional
- `leadingIcon: String?` - Icono izquierdo
- `trailingIcon: String?` - Icono derecho
- `leadingAction: (() -> Void)?` - Acción izquierda
- `trailingAction: (() -> Void)?` - Acción derecha

**Ejemplo:**
```swift
EduNavigationBar(
    title: "Mi Perfil",
    subtitle: "Estudiante activo",
    leadingAction: { dismiss() },
    trailingIcon: "gearshape.fill",
    trailingAction: { showSettings() }
)
```

**Archivo:** `Sources/UI/Navigation/EduNavigationBar.swift`

---

### EduNavigationLink

Link de navegación con estilo EduGo.

**Props:**
- `title: String` - Título del link
- `icon: String?` - Icono opcional
- `showChevron: Bool` - Mostrar chevron
- `destination: () -> Destination` - Vista de destino

**Ejemplo:**
```swift
EduNavigationLink(
    "Mi Perfil",
    icon: "person.fill"
) {
    ProfileView()
}
```

**Archivo:** `Sources/UI/Navigation/EduNavigationLink.swift`

---

### EduTabBar

Barra de pestañas personalizada.

**Props:**
- `selectedTab: Binding<Int>` - Tab seleccionado
- `tabs: [TabItem]` - Array de tabs

**TabItem:**
- `title: String`
- `icon: String`
- `selectedIcon: String?`

**Ejemplo:**
```swift
@State var selectedTab = 0

EduTabBar(
    selectedTab: $selectedTab,
    tabs: [
        TabItem(title: "Inicio", icon: "house"),
        TabItem(title: "Buscar", icon: "magnifyingglass"),
        TabItem(title: "Perfil", icon: "person")
    ]
)
```

**Archivo:** `Sources/UI/Navigation/EduTabBar.swift`

---

### EduBreadcrumbs

Componente de navegación breadcrumb.

**Props:**
- `items: [BreadcrumbItem]` - Items del breadcrumb
- `onItemTap: (BreadcrumbItem) -> Void` - Callback al tocar

**BreadcrumbItem:**
- `id: String`
- `title: String`

**Ejemplo:**
```swift
EduBreadcrumbs(items: [
    BreadcrumbItem(id: "home", title: "Inicio"),
    BreadcrumbItem(id: "courses", title: "Cursos"),
    BreadcrumbItem(id: "math", title: "Matemáticas")
]) { item in
    navigateTo(item)
}
```

**Archivo:** `Sources/UI/Navigation/EduBreadcrumbs.swift`

---

## Feedback

### EduToast

Notificación toast temporal.

**Props:**
- `message: String` - Mensaje del toast
- `style: Style` - Estilo (.success, .error, .warning, .info)

**Uso con ToastManager:**
```swift
ToastManager.shared.show(
    "Guardado exitosamente",
    style: .success,
    duration: 3.0
)
```

**Archivo:** `Sources/UI/Feedback/EduToast.swift`

---

### EduBanner

Banner informativo persistente.

**Props:**
- `message: String` - Mensaje del banner
- `style: Style` - Estilo (.success, .error, .warning, .info)
- `action: (() -> Void)?` - Acción opcional
- `onDismiss: (() -> Void)?` - Callback al cerrar

**Ejemplo:**
```swift
EduBanner(
    message: "Nueva actualización disponible",
    style: .info,
    action: { install() },
    onDismiss: { hideBanner() }
)
```

**Archivo:** `Sources/UI/Feedback/EduBanner.swift`

---

### EduAlert

Alerta modal con botones.

**Props:**
- `title: String` - Título de la alerta
- `message: String` - Mensaje descriptivo
- `primaryButton: AlertButton` - Botón primario
- `secondaryButton: AlertButton?` - Botón secundario opcional

**Ejemplo:**
```swift
.alert(isPresented: $showAlert) {
    EduAlert(
        title: "Eliminar",
        message: "¿Estás seguro?",
        primaryButton: .init(title: "Eliminar", style: .destructive) {
            delete()
        },
        secondaryButton: .init(title: "Cancelar", style: .cancel) {}
    )
}
```

**Archivo:** `Sources/UI/Feedback/EduAlert.swift`

---

### EduModal

Modal personalizado.

**Props:**
- `title: String` - Título del modal
- `content: () -> Content` - Contenido del modal
- `actions: (() -> Actions)?` - Acciones opcionales

**Ejemplo:**
```swift
.sheet(isPresented: $showModal) {
    EduModal(
        title: "Crear Estudiante",
        content: {
            CreateStudentForm()
        },
        actions: {
            HStack {
                Button("Cancelar") { dismiss() }
                Button("Guardar") { save() }
            }
        }
    )
}
```

**Archivo:** `Sources/UI/Feedback/EduModal.swift`

---

### EduActionSheet

Action sheet personalizado.

**Props:**
- `title: String` - Título
- `message: String?` - Mensaje opcional
- `actions: [ActionSheetAction]` - Array de acciones

**Ejemplo:**
```swift
.actionSheet(isPresented: $showActions) {
    EduActionSheet(
        title: "Opciones",
        message: "Selecciona una acción",
        actions: [
            .init(title: "Editar", style: .default) { edit() },
            .init(title: "Eliminar", style: .destructive) { delete() },
            .init(title: "Cancelar", style: .cancel) {}
        ]
    )
}
```

**Archivo:** `Sources/UI/Feedback/EduActionSheet.swift`

---

### EduOverlayManager

Gestor centralizado de overlays.

**Uso:**
```swift
@State var overlayItem: EduOverlayItem?

MyView()
    .eduOverlay(item: $overlayItem)

// Mostrar overlay
overlayItem = .toast(message: "Guardado", style: .success)
overlayItem = .banner(message: "Error", style: .error)
overlayItem = .loading(message: "Procesando...")
```

**Archivo:** `Sources/UI/Feedback/EduOverlayManager.swift`

---

## Loading

### EduActivityIndicator

Indicador de actividad circular.

**Props:**
- `size: Size` - Tamaño (.small, .medium, .large)
- `color: Color` - Color del indicador

**Ejemplo:**
```swift
EduActivityIndicator(size: .medium, color: .blue)
```

**Archivo:** `Sources/UI/Loading/EduActivityIndicator.swift`

---

### EduProgressBar

Barra de progreso lineal.

**Props:**
- `progress: Double` - Progreso (0.0 a 1.0)
- `height: CGFloat` - Altura de la barra
- `progressColor: Color` - Color del progreso
- `trackColor: Color` - Color del track

**Ejemplo:**
```swift
@State var progress = 0.5

EduProgressBar(
    progress: progress,
    height: 8,
    progressColor: .blue
)
```

**Archivo:** `Sources/UI/Loading/EduProgressBar.swift`

---

### EduProgressCircle

Indicador de progreso circular.

**Props:**
- `progress: Double` - Progreso (0.0 a 1.0)
- `size: CGFloat` - Tamaño del círculo
- `lineWidth: CGFloat` - Grosor de la línea
- `progressColor: Color` - Color del progreso
- `trackColor: Color` - Color del track

**Ejemplo:**
```swift
@State var progress = 0.75

EduProgressCircle(
    progress: progress,
    size: 100,
    lineWidth: 10,
    progressColor: .green
)
```

**Archivo:** `Sources/UI/Loading/EduProgressCircle.swift`

---

### EduSkeletonLoader

Skeleton loader para contenido en carga.

**Props:**
- `lines: Int` - Número de líneas
- `height: CGFloat` - Altura de cada línea
- `spacing: CGFloat` - Espacio entre líneas
- `cornerRadius: CGFloat` - Radio de esquinas

**Ejemplo:**
```swift
EduSkeletonLoader(
    lines: 3,
    height: 16,
    spacing: 8
)
```

**Archivo:** `Sources/UI/Loading/EduSkeletonLoader.swift`

---

## Utilities

### PreviewHelpers

Utilidades para Xcode Previews.

**Funciones disponibles:**

**Dispositivos:**
```swift
MyView().previewDevice(.iPhone15Pro)
MyView().previewDevice(.iPadPro13)
MyView().previewDevice(.macOS)
```

**Color Schemes:**
```swift
MyView().previewAllColorSchemes()
```

**Dynamic Type:**
```swift
MyView().previewDynamicTypeSize(.extraLarge)
MyView().previewCommonDynamicTypeSizes()
```

**Locales:**
```swift
MyView().previewLocale("es_ES")
MyView().previewCommonLocales()
```

**Containers:**
```swift
PreviewContainer {
    MyView()
}

PreviewGrid(columns: 3) {
    ForEach(items) { item in
        ItemView(item)
    }
}
```

**Archivo:** `Sources/UI/Utilities/PreviewHelpers.swift`

---

### PreviewMocks

Datos mock para previews.

**Datos disponibles:**
- `PreviewMocks.shortText`
- `PreviewMocks.mediumText`
- `PreviewMocks.longText`
- `PreviewMocks.userName`
- `PreviewMocks.userEmail`
- `PreviewMocks.shortList`
- `PreviewMocks.mediumList`
- `PreviewMocks.today`
- `PreviewMocks.genericError`

**ViewModels mock:**
- `MockLoadingViewModel`
- `MockFormViewModel`
- `MockListViewModel`

**Bindings mock:**
```swift
@Previewable @State var text = PreviewMocks.userEmail
TextField("Email", text: $text)
```

**Archivo:** `Sources/UI/Utilities/PreviewMocks.swift`

---

## Plataformas Soportadas

- iOS 26+
- macOS 26+

Todos los componentes están diseñados para funcionar en ambas plataformas con adaptaciones automáticas según el contexto.

---

## Temas y Estilos

Los componentes utilizan el sistema de diseño EduGo definido en el módulo `Styling`, que incluye:

- Colores: `Color.eduPrimary`, `Color.eduTextPrimary`, etc.
- Tipografía: `.eduFont(.h1)`, `.eduFont(.body, weight: .bold)`
- Espaciado: `.eduSpacing(.sm)`, `.eduSpacing(.lg)`
- Radios: `.eduRadius(.md)`

---

## Accesibilidad

Todos los componentes incluyen:
- Soporte para Dynamic Type
- VoiceOver labels
- Contraste adecuado
- Tamaños táctiles mínimos de 44x44 pts

---

## Testing

Cada componente tiene:
- Tests unitarios en `/Tests/UITests/`
- Previews completos con múltiples estados
- Cobertura de casos edge

---

## Contribuir

Ver `CONTRIBUTING.md` para guías de contribución.
