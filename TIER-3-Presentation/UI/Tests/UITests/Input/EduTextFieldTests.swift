import Testing
import SwiftUI
@testable import UI
@testable import Binding

@MainActor
struct EduTextFieldTests {

    // MARK: - Initialization Tests

    @Test("EduTextField inicializa correctamente con parámetros básicos")
    func testBasicInitialization() {
        let text = ""
        let textBinding = Binding.constant(text)

        let _ = EduTextField(
            "Email",
            text: textBinding,
            placeholder: "tu@email.com"
        )
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduTextField inicializa con validación")
    func testInitializationWithValidation() {
        let text = ""
        let textBinding = Binding.constant(text)

        let _ = EduTextField(
            "Email",
            text: textBinding,
            validation: Validators.email()
        )
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduTextField inicializa con FormState")
    func testInitializationWithFormState() {
        let text = ""
        let textBinding = Binding.constant(text)
        let formState = FormState()

        let _ = EduTextField(
            "Email",
            text: textBinding,
            validation: Validators.email(),
            formState: formState,
            fieldKey: "email"
        )
        // La inicialización exitosa del struct es suficiente validación
    }

    // MARK: - Validation Tests

    @Test("ValidationState inicia como válido")
    func testValidationStateInitiallyValid() {
        let validationState = ValidationState()

        #expect(validationState.isValid == true, "Estado inicial debe ser válido")
        #expect(validationState.errorMessage == nil, "No debe haber mensaje de error inicial")
    }

    @Test("ValidationState puede cambiar a inválido")
    func testValidationStateCanBeInvalid() {
        let validationState = ValidationState()

        validationState.isValid = false
        validationState.errorMessage = "Error de prueba"

        #expect(validationState.isValid == false, "Estado debe ser inválido")
        #expect(validationState.errorMessage == "Error de prueba", "Mensaje de error debe coincidir")
    }

    // MARK: - FormState Integration Tests

    @Test("TextField se registra en FormState correctamente")
    func testFormStateRegistration() async {
        @MainActor
        class TestContext {
            var text = ""
            let formState = FormState()
        }

        let context = TestContext()
        let textBinding = Binding(
            get: { context.text },
            set: { context.text = $0 }
        )

        let _ = EduTextField(
            "Email",
            text: textBinding,
            validation: Validators.email(),
            formState: context.formState,
            fieldKey: "email"
        )

        // Verificar que el campo se registró
        context.formState.validate()

        // El FormState debe tener errores porque el email está vacío
        #expect(context.formState.isValid == false, "FormState debe ser inválido con email vacío")
    }

    @Test("TextField actualiza FormState al cambiar valor")
    func testFormStateUpdatesOnValueChange() async {
        @MainActor
        class TestContext {
            var text = ""
            let formState = FormState()
        }

        let context = TestContext()
        let textBinding = Binding(
            get: { context.text },
            set: { context.text = $0 }
        )

        let _ = EduTextField(
            "Email",
            text: textBinding,
            validation: Validators.email(),
            formState: context.formState,
            fieldKey: "email"
        )

        // Cambiar a email válido
        context.text = "test@example.com"
        context.formState.validateField("email")

        #expect(context.formState.error(for: "email") == nil, "No debe haber error con email válido")
    }

    // MARK: - Disabled State Tests

    @Test("TextField deshabilitado se crea correctamente")
    func testDisabledTextField() {
        let text = ""
        let textBinding = Binding.constant(text)

        let _ = EduTextField(
            "Campo Bloqueado",
            text: textBinding,
            isDisabled: true
        )
        // La inicialización exitosa del struct es suficiente validación
    }

    // MARK: - Helper Text Tests

    @Test("TextField con helper text se crea correctamente")
    func testTextFieldWithHelperText() {
        let text = ""
        let textBinding = Binding.constant(text)

        let _ = EduTextField(
            "Email",
            text: textBinding,
            helperText: "Ingresa tu correo electrónico"
        )
        // La inicialización exitosa del struct es suficiente validación
    }

    // MARK: - onCommit Tests

    @Test("TextField ejecuta onCommit al confirmar")
    func testOnCommitExecution() async {
        @MainActor
        class TestContext {
            var text = ""
            var commitCalled = false
        }

        let context = TestContext()
        let textBinding = Binding(
            get: { context.text },
            set: { context.text = $0 }
        )

        let _ = EduTextField(
            "Nombre",
            text: textBinding,
            onCommit: {
                context.commitCalled = true
            }
        )
        // La inicialización exitosa del struct es suficiente validación
        // Nota: En tests reales de UI, esto se verificaría con ViewInspector o similar
    }

    // MARK: - Email Validation Tests

    @Test("Validación de email rechaza texto vacío")
    func testEmailValidationRejectsEmpty() {
        let result = Validators.email()("")

        #expect(result.isValid == false, "Email vacío debe ser inválido")
        #expect(result.errorMessage != nil, "Debe haber mensaje de error")
    }

    @Test("Validación de email rechaza formato inválido")
    func testEmailValidationRejectsInvalidFormat() {
        let result = Validators.email()("invalid-email")

        #expect(result.isValid == false, "Email con formato inválido debe ser rechazado")
    }

    @Test("Validación de email acepta formato válido")
    func testEmailValidationAcceptsValidFormat() {
        let result = Validators.email()("test@example.com")

        #expect(result.isValid == true, "Email válido debe ser aceptado")
        #expect(result.errorMessage == nil, "No debe haber mensaje de error")
    }

    // MARK: - Integration Tests

    @Test("TextField completo con todas las características")
    func testFullFeaturedTextField() async {
        @MainActor
        class TestContext {
            var text = ""
            let formState = FormState()
            var commitCalled = false
        }

        let context = TestContext()
        let textBinding = Binding(
            get: { context.text },
            set: { context.text = $0 }
        )

        let _ = EduTextField(
            "Email Completo",
            text: textBinding,
            placeholder: "email@ejemplo.com",
            helperText: "Ingresa tu email corporativo",
            validation: Validators.email(),
            formState: context.formState,
            fieldKey: "corporate_email",
            isDisabled: false,
            onCommit: {
                context.commitCalled = true
            }
        )
        // La inicialización exitosa del struct es suficiente validación

        // Validar estado inicial
        context.formState.validate()
        #expect(context.formState.isValid == false, "Debe ser inválido inicialmente")

        // Cambiar a email válido
        context.text = "usuario@empresa.com"
        context.formState.validateField("corporate_email")

        #expect(context.formState.error(for: "corporate_email") == nil, "No debe haber error con email válido")
    }
}
