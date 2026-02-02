# Guia de Integracion - EduGo UI Components

Esta guia explica como integrar y usar los componentes UI de EduGo en tu proyecto.

## Requisitos

- Swift 6.0+
- iOS 26+ / macOS 26+
- Xcode 16+

## Instalacion

### Swift Package Manager

Agrega el paquete como dependencia local en tu `Package.swift`:

```swift
dependencies: [
    .package(path: "../TIER-3-Presentation/UI")
]
```

O en Xcode:
1. File > Add Packages...
2. Selecciona el directorio local del paquete UI

### Importar el modulo

```swift
import UI
```

## Configuracion Inicial

### 1. Configurar Overlays Globales

Para usar Toast, Alert y Modal managers de forma global, agrega el modifier en tu vista raiz:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .eduOverlay()  // Habilita toasts, alerts y modals globales
        }
    }
}
```

### 2. Configurar TabBar (si aplica)

```swift
struct ContentView: View {
    @State private var selectedTab = "home"
    
    let tabs = [
        EduTabItem(id: "home", title: "Inicio", icon: "house", selectedIcon: "house.fill"),
        EduTabItem(id: "courses", title: "Cursos", icon: "book", selectedIcon: "book.fill"),
        EduTabItem(id: "profile", title: "Perfil", icon: "person", selectedIcon: "person.fill")
    ]
    
    var body: some View {
        EduTabBar(selection: $selectedTab, items: tabs) { tabId in
            switch tabId {
            case "home": HomeView()
            case "courses": CoursesView()
            case "profile": ProfileView()
            default: EmptyView()
            }
        }
    }
}
```

## Patrones de Uso Comunes

### Pantalla con Lista y Estados

```swift
struct CoursesView: View {
    @State private var viewModel = CoursesViewModel()
    
    var body: some View {
        NavigationStack {
            EduListView(
                state: viewModel.state,
                emptyTitle: "Sin cursos",
                emptyDescription: "No tienes cursos inscritos aun",
                onRetry: { Task { await viewModel.loadCourses() } }
            ) { course in
                EduStyledNavigationLink(
                    title: course.name,
                    subtitle: course.instructor,
                    icon: "book",
                    style: .row
                ) {
                    CourseDetailView(course: course)
                }
            }
            .eduNavigationBar(title: "Mis Cursos", displayMode: .large)
            .refreshable {
                await viewModel.loadCourses()
            }
        }
    }
}
```

### Formulario con Validacion

```swift
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 24) {
            EduCard {
                VStack(spacing: 16) {
                    EduTextField("Email", text: $email, icon: "envelope")
                    EduSecureField("Contrasena", text: $password)
                }
            }
            
            EduButton.primary("Iniciar Sesion", isLoading: isLoading) {
                Task {
                    isLoading = true
                    await login()
                    isLoading = false
                }
            }
            
            EduButton.link("Olvidaste tu contrasena?") {
                // Navegar a recuperacion
            }
        }
        .padding()
    }
}
```

### Modal con Formulario

```swift
struct ProfileView: View {
    @State private var showEditModal = false
    
    var body: some View {
        VStack {
            // Contenido del perfil
            
            EduButton.secondary("Editar Perfil") {
                showEditModal = true
            }
        }
        .eduModal(isPresented: $showEditModal) {
            EduModalContent(
                title: "Editar Perfil",
                size: .medium,
                onDismiss: { showEditModal = false }
            ) {
                EditProfileForm()
            }
        }
    }
}
```

### Action Sheet con Opciones

```swift
struct DocumentRow: View {
    let document: Document
    @State private var showActions = false
    
    var body: some View {
        EduRow(
            title: document.name,
            subtitle: document.formattedDate,
            icon: "doc"
        )
        .onTapGesture {
            showActions = true
        }
        .eduActionSheet(
            isPresented: $showActions,
            content: EduActionSheetContent(
                title: document.name,
                actions: [
                    EduActionSheetAction(title: "Abrir", icon: "eye") { open() },
                    EduActionSheetAction(title: "Compartir", icon: "square.and.arrow.up") { share() },
                    EduActionSheetAction(title: "Eliminar", icon: "trash", role: .destructive) { delete() },
                    EduActionSheetAction(title: "Cancelar", role: .cancel) { }
                ]
            )
        )
    }
}
```

### Indicadores de Progreso

```swift
struct UploadView: View {
    @State private var progress: Double = 0
    @State private var isUploading = false
    
    var body: some View {
        VStack(spacing: 24) {
            if isUploading {
                EduLabeledProgressBar(
                    progress: progress,
                    label: "Subiendo archivo..."
                )
                
                // O circular
                EduProgressCircle(progress: progress, showPercentage: true)
                    .frame(width: 100, height: 100)
            }
            
            EduButton.primary(isUploading ? "Cancelar" : "Subir") {
                isUploading.toggle()
            }
        }
        .padding()
    }
}
```

### Estados de Carga con Skeleton

```swift
struct ContentView: View {
    @State private var isLoading = true
    @State private var items: [Item] = []
    
    var body: some View {
        Group {
            if isLoading {
                EduSkeletonGroup {
                    VStack(spacing: 12) {
                        EduSkeletonCard()
                        EduSkeletonList(count: 3)
                    }
                }
            } else {
                // Contenido real
                List(items) { item in
                    ItemRow(item: item)
                }
            }
        }
        .task {
            await loadContent()
            isLoading = false
        }
    }
}
```

## Integracion con ViewModels

### ViewModel con ViewState

```swift
@Observable
@MainActor
final class CoursesViewModel {
    var state: ViewState<[Course]> = .loading
    
    func loadCourses() async {
        state = .loading
        
        do {
            let courses = try await courseRepository.fetchCourses()
            if courses.isEmpty {
                state = .empty
            } else {
                state = .success(courses)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
```

### Uso en Vista

```swift
struct CoursesView: View {
    @State private var viewModel = CoursesViewModel()
    
    var body: some View {
        EduListView(state: viewModel.state) { course in
            CourseRow(course: course)
        }
        .task {
            await viewModel.loadCourses()
        }
    }
}
```

## Notificaciones con Toast

### Mostrar Toast Programaticamente

```swift
// Exito
ToastManager.shared.show("Guardado exitosamente", style: .success)

// Error
ToastManager.shared.show("Error al guardar", style: .error)

// Advertencia
ToastManager.shared.show("Conexion inestable", style: .warning)

// Informacion
ToastManager.shared.show("Nueva version disponible", style: .info)
```

### Toast con Duracion Personalizada

```swift
ToastManager.shared.show(
    "Procesando...",
    style: .info,
    duration: 5.0  // 5 segundos
)
```

## Alertas Programaticas

### Confirmacion Simple

```swift
EduAlertManager.shared.showConfirmation(
    title: "Guardar cambios",
    message: "Deseas guardar los cambios realizados?",
    confirmTitle: "Guardar",
    cancelTitle: "Descartar"
) {
    saveChanges()
}
```

### Alerta Destructiva

```swift
EduAlertManager.shared.showDestructive(
    title: "Eliminar curso",
    message: "Esta accion no se puede deshacer",
    destructiveTitle: "Eliminar"
) {
    deleteCourse()
}
```

## Navegacion

### Con NavigationStack

```swift
struct ContentView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: Course.self) { course in
                    CourseDetailView(course: course)
                }
        }
    }
}
```

### Con EduNavigationRouter

```swift
@Observable
@MainActor
final class AppRouter {
    let router = EduNavigationRouter()
    
    func goToDetail(id: String) {
        router.navigate(to: .detail(id: id))
    }
    
    func goToSettings() {
        router.navigate(to: .settings)
    }
    
    func goBack() {
        router.goBack()
    }
}
```

## Temas y Personalizacion

### Colores Personalizados

Los componentes usan `Color.accentColor` por defecto. Personaliza el accent color en tu Asset Catalog o programaticamente:

```swift
ContentView()
    .tint(.purple)  // Cambia el accent color
```

### Modo Oscuro

Todos los componentes soportan modo oscuro automaticamente. Para forzar un esquema:

```swift
ContentView()
    .preferredColorScheme(.dark)  // o .light
```

## Accesibilidad

Los componentes incluyen soporte de accesibilidad:

- Labels descriptivos
- Traits apropiados (`.button`, `.link`, etc.)
- Soporte de VoiceOver
- Dynamic Type

### Verificar Accesibilidad en Previews

```swift
#Preview("Accessibility") {
    MyView()
        .previewCommonDynamicTypeSizes()
}
```

## Soluccion de Problemas

### El Toast no aparece

Verifica que hayas agregado `.eduOverlay()` en la vista raiz de tu app.

### El TabBar tiene mas de 5 items

El componente lanzara un error en tiempo de ejecucion. Segun iOS HIG, usa maximo 5 tabs.

### Los Previews no cargan

1. Limpia la build folder (Cmd+Shift+K)
2. Reinicia Xcode
3. Verifica que todas las dependencias esten correctamente vinculadas

### Componentes no se actualizan

Asegurate de usar `@State`, `@Binding` o `@Observable` correctamente para el estado reactivo.

## Recursos Adicionales

- [COMPONENTS.md](./COMPONENTS.md) - Documentacion detallada de cada componente
- [CONTRIBUTING.md](./CONTRIBUTING.md) - Guia para contribuir al proyecto
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
