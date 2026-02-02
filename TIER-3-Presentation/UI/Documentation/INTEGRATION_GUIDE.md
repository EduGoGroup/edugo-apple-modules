# Guía de Integración - EduGo UI Components

Esta guía te ayudará a integrar y utilizar los componentes de EduGo UI en tu proyecto SwiftUI.

## Tabla de Contenidos

1. [Instalación](#instalación)
2. [Configuración Inicial](#configuración-inicial)
3. [Uso Básico](#uso-básico)
4. [Patrones Comunes](#patrones-comunes)
5. [Formularios y Validación](#formularios-y-validación)
6. [Listas y Estados](#listas-y-estados)
7. [Navegación](#navegación)
8. [Feedback y Notificaciones](#feedback-y-notificaciones)
9. [Testing y Previews](#testing-y-previews)
10. [Mejores Prácticas](#mejores-prácticas)

---

## Instalación

### Swift Package Manager

El módulo UI es parte del workspace EduGo Apple Modules. Ya está incluido en el `Package.swift` del proyecto.

```swift
dependencies: [
    .package(path: "../UI")
]
```

### Importar en tu código

```swift
import UI
import Styling  // Para colores y tipografía
import StateManagement  // Para FormState
import Binding  // Para validación
```

---

## Configuración Inicial

### 1. Configurar el Theme

Asegúrate de que tu aplicación use los colores y estilos de EduGo:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)  // O .dark según preferencia
        }
    }
}
```

### 2. Configurar Navigation

Para apps con navegación:

```swift
NavigationStack {
    HomeView()
}
```

### 3. Configurar Overlays

En tu view principal, agrega el modifier de overlays:

```swift
struct ContentView: View {
    @State private var overlayItem: EduOverlayItem?
    
    var body: some View {
        MainView()
            .eduOverlay(item: $overlayItem)
    }
}
```

---

## Uso Básico

### Botones

```swift
// Botón primario simple
EduButton.primary("Guardar") {
    save()
}

// Botón con icono
EduButton(
    "Eliminar",
    icon: "trash",
    style: .destructive
) {
    delete()
}

// Botón con estado de carga
@State var isLoading = false

EduButton.primary(
    "Enviar",
    isLoading: isLoading
) {
    submit()
}
```

### Text Fields

```swift
@State var email = ""
@State var password = ""

VStack(spacing: 16) {
    EduTextField(
        "Email",
        text: $email,
        placeholder: "tu@email.com",
        validation: Validators.email()
    )
    
    EduSecureField(
        "Contraseña",
        text: $password,
        showPassword: $showPassword
    )
}
```

### Contenedores

```swift
EduCard(title: "Estudiantes", subtitle: "Total: 25") {
    VStack(spacing: 12) {
        ForEach(students) { student in
            EduRow(
                title: student.name,
                subtitle: student.grade,
                icon: "person.fill"
            )
        }
    }
}
```

---

## Patrones Comunes

### 1. Lista con Estados

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
            emptyIcon: "person.2.slash",
            retryAction: { viewModel.loadStudents() }
        ) { student in
            EduRow(
                title: student.name,
                subtitle: student.grade,
                icon: "person.fill",
                action: { viewModel.selectStudent(student) }
            )
        }
        .onAppear {
            viewModel.loadStudents()
        }
    }
}
```

### 2. Formulario con Validación

```swift
struct CreateStudentView: View {
    @StateObject var formState = FormState()
    @State var name = ""
    @State var email = ""
    @State var grade = ""
    
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
            
            EduTextField(
                "Grado",
                text: $grade,
                validation: Validators.required("Grado requerido"),
                formState: formState,
                fieldKey: "grade"
            )
            
            EduButton.primary(
                "Crear Estudiante",
                isDisabled: !formState.isValid
            ) {
                createStudent()
            }
        }
        .padding()
    }
}
```

### 3. Modal con Confirmación

```swift
struct DeleteConfirmationView: View {
    @Binding var isPresented: Bool
    let studentName: String
    let onConfirm: () -> Void
    
    var body: some View {
        EduModal(
            title: "Eliminar Estudiante",
            content: {
                VStack(spacing: 16) {
                    Image(systemName: "trash")
                        .font(.system(size: 50))
                        .foregroundStyle(.red)
                    
                    Text("¿Estás seguro de eliminar a \(studentName)?")
                        .multilineTextAlignment(.center)
                    
                    Text("Esta acción no se puede deshacer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            },
            actions: {
                HStack(spacing: 12) {
                    EduButton.secondary("Cancelar") {
                        isPresented = false
                    }
                    
                    EduButton.destructive("Eliminar") {
                        onConfirm()
                        isPresented = false
                    }
                }
            }
        )
    }
}
```

### 4. Navigation Menu

```swift
struct MenuView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                EduNavigationLink(
                    "Mi Perfil",
                    icon: "person.fill"
                ) {
                    ProfileView()
                }
                
                EduNavigationLink(
                    "Cursos",
                    icon: "book.fill"
                ) {
                    CoursesView()
                }
                
                EduNavigationLink(
                    "Configuración",
                    icon: "gearshape.fill"
                ) {
                    SettingsView()
                }
            }
            .padding()
        }
    }
}
```

---

## Formularios y Validación

### Crear Validadores Personalizados

```swift
extension Validators {
    static func gradeLevel() -> (String) -> ValidationResult {
        return { value in
            guard let grade = Int(value), grade >= 1, grade <= 12 else {
                return ValidationResult(
                    isValid: false,
                    errorMessage: "Grado debe ser entre 1 y 12"
                )
            }
            return ValidationResult(isValid: true)
        }
    }
}
```

### Usar FormState

```swift
@StateObject var formState = FormState()

// Registrar campos
formState.registerField("email") { value in
    Validators.email()(value)
}

formState.registerField("password") { value in
    Validators.minLength(6)(value)
}

// Validar todo el formulario
if formState.isValid {
    // Enviar formulario
}
```

---

## Listas y Estados

### ViewModel Típico

```swift
@MainActor
@Observable
final class ListViewModel {
    enum State {
        case idle
        case loading
        case loaded([Item])
        case empty
        case error(Error)
    }
    
    var state: State = .idle
    
    func load() async {
        state = .loading
        
        do {
            let items = try await fetchItems()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            state = .error(error)
        }
    }
}
```

### Vista con Estados

```swift
struct ListView: View {
    @StateObject var viewModel = ListViewModel()
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Color.clear.onAppear {
                    Task { await viewModel.load() }
                }
            case .loading:
                EduLoadingStateView()
            case .loaded(let items):
                List(items) { item in
                    ItemRow(item: item)
                }
            case .empty:
                EduEmptyStateView(
                    title: "No hay elementos",
                    message: "Comienza agregando elementos",
                    icon: "tray"
                )
            case .error(let error):
                EduErrorStateView(
                    message: error.localizedDescription,
                    retryAction: {
                        Task { await viewModel.load() }
                    }
                )
            }
        }
    }
}
```

---

## Navegación

### Navigation Stack

```swift
struct MainView: View {
    var body: some View {
        NavigationStack {
            HomeView()
                .navigationTitle("Inicio")
        }
    }
}
```

### Custom Navigation Bar

```swift
struct DetailView: View {
    @Environment(\.dismiss) var dismiss
    @State var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            EduNavigationBar(
                title: "Detalles",
                subtitle: "Vista de detalles",
                leadingAction: { dismiss() },
                trailingIcon: "gearshape.fill",
                trailingAction: { showSettings = true }
            )
            
            ScrollView {
                // Contenido
            }
        }
    }
}
```

### Tab Bar

```swift
struct MainTabView: View {
    @State var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            TabContentView(selectedTab: selectedTab)
            
            EduTabBar(
                selectedTab: $selectedTab,
                tabs: [
                    TabItem(title: "Inicio", icon: "house"),
                    TabItem(title: "Buscar", icon: "magnifyingglass"),
                    TabItem(title: "Perfil", icon: "person")
                ]
            )
        }
    }
}
```

---

## Feedback y Notificaciones

### Toasts

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

### Banners

```swift
@State var showBanner = false

VStack {
    if showBanner {
        EduBanner(
            message: "Nueva actualización disponible",
            style: .info,
            action: { installUpdate() },
            onDismiss: { showBanner = false }
        )
    }
    
    // Contenido principal
}
```

### Alerts

```swift
@State var showAlert = false

Button("Eliminar") {
    showAlert = true
}
.alert(isPresented: $showAlert) {
    EduAlert(
        title: "Confirmar",
        message: "¿Estás seguro?",
        primaryButton: .init(title: "Eliminar", style: .destructive) {
            delete()
        },
        secondaryButton: .init(title: "Cancelar", style: .cancel) {}
    )
}
```

### Overlays Centralizados

```swift
@State var overlayItem: EduOverlayItem?

MyView()
    .eduOverlay(item: $overlayItem)

// Mostrar diferentes overlays
overlayItem = .toast(message: "Guardado", style: .success)
overlayItem = .banner(message: "Error", style: .error)
overlayItem = .loading(message: "Procesando...")

// Ocultar
overlayItem = nil
```

---

## Testing y Previews

### Previews con Estados

```swift
#Preview("Loading") {
    ListView(viewModel: .loading)
}

#Preview("With Data") {
    ListView(viewModel: .loaded(PreviewMocks.students))
}

#Preview("Empty") {
    ListView(viewModel: .empty)
}

#Preview("Error") {
    ListView(viewModel: .error)
}
```

### Usar PreviewHelpers

```swift
#Preview("iPhone 15 Pro") {
    MyView()
        .previewDevice(.iPhone15Pro)
}

#Preview("All Color Schemes") {
    MyView()
        .previewAllColorSchemes()
}

#Preview("Dynamic Type Sizes") {
    MyView()
        .previewCommonDynamicTypeSizes()
}
```

### Usar PreviewMocks

```swift
#Preview {
    @Previewable @State var text = PreviewMocks.userEmail
    @Previewable @State var isLoading = false
    
    VStack {
        EduTextField("Email", text: $text)
        EduButton.primary("Submit", isLoading: isLoading) {
            isLoading = true
        }
    }
}
```

---

## Mejores Prácticas

### 1. Estado y Observabilidad

```swift
// ✅ CORRECTO: Usar @Observable para ViewModels
@MainActor
@Observable
final class MyViewModel {
    var items: [Item] = []
    var isLoading = false
    var error: Error?
}

// ❌ INCORRECTO: No usar @Published con @Observable
```

### 2. Composición de Componentes

```swift
// ✅ CORRECTO: Componentes pequeños y reutilizables
struct StudentCard: View {
    let student: Student
    
    var body: some View {
        EduCard(title: student.name, subtitle: student.grade) {
            StudentDetails(student: student)
        }
    }
}

// ❌ INCORRECTO: Componentes monolíticos
```

### 3. Manejo de Estado

```swift
// ✅ CORRECTO: Estado mínimo en la View
@State private var selectedStudent: Student?

// ❌ INCORRECTO: Lógica compleja en la View
```

### 4. Validación

```swift
// ✅ CORRECTO: Validación declarativa
EduTextField(
    "Email",
    text: $email,
    validation: Validators.email()
)

// ❌ INCORRECTO: Validación imperativa en callbacks
```

### 5. Previews

```swift
// ✅ CORRECTO: Múltiples previews con estados
#Preview("Normal") { MyView() }
#Preview("Loading") { MyView(isLoading: true) }
#Preview("Error") { MyView(error: PreviewError.network) }

// ❌ INCORRECTO: Un solo preview sin variaciones
```

### 6. Accesibilidad

```swift
// ✅ CORRECTO: Labels descriptivos
EduButton("Guardar cambios") { save() }

// ❌ INCORRECTO: Labels genéricos
EduButton("OK") { save() }
```

### 7. Performance

```swift
// ✅ CORRECTO: Lazy loading de listas
EduListView(items: students) { student in
    StudentRow(student: student)
}

// ❌ INCORRECTO: Cargar todo de una vez
ForEach(allStudents) { student in ... }
```

### 8. Theming

```swift
// ✅ CORRECTO: Usar colores del theme
.foregroundStyle(Color.eduPrimary)

// ❌ INCORRECTO: Hard-coded colors
.foregroundStyle(.blue)
```

---

## Ejemplos Completos

### App de Gestión de Estudiantes

Ver `/Examples/StudentManagementApp/` para un ejemplo completo de:
- Autenticación con formularios
- Listas con estados
- Navegación multinivel
- CRUD operations
- Manejo de errores
- Feedback con toasts y alerts

### App de E-learning

Ver `/Examples/ELearningApp/` para un ejemplo de:
- Tab navigation
- Cursos y materiales
- Progreso con círculos y barras
- Skeleton loaders
- Búsqueda y filtros

---

## Troubleshooting

### Problema: "No such module 'UI'"

**Solución:** Verifica que el paquete esté agregado en `Package.swift`:

```swift
.product(name: "UI", package: "UI")
```

### Problema: Previews no se actualizan

**Solución:** 
1. Limpia build folder (Cmd+Shift+K)
2. Rebuild (Cmd+B)
3. Restart Xcode Previews

### Problema: Validación no funciona

**Solución:** Verifica que hayas registrado el campo en FormState:

```swift
formState.registerField("email") { value in
    Validators.email()(value)
}
```

### Problema: Overlays no se muestran

**Solución:** Asegúrate de tener `.eduOverlay(item: $overlayItem)` en la jerarquía de views.

---

## Recursos Adicionales

- [Documentación de Componentes](COMPONENTS.md)
- [Guía de Contribución](CONTRIBUTING.md)
- [Changelog](../CHANGELOG.md)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

---

## Soporte

Si tienes preguntas o problemas:
1. Consulta esta guía y `COMPONENTS.md`
2. Revisa los ejemplos en `/Examples/`
3. Consulta los previews de los componentes
4. Contacta al equipo de desarrollo
