import SwiftUI
import Binding

/// SecureField para contraseñas con toggle show/hide y validación integrada.
///
/// Características:
/// - Toggle para mostrar/ocultar contraseña (iOS, macOS, visionOS)
/// - Validación de seguridad integrada
/// - Estados: normal, error, disabled, focused
/// - Integración con FormState
/// - Feedback visual de fortaleza de contraseña
@MainActor
public struct EduSecureField: View {
    // MARK: - Properties

    private let title: String
    private let placeholder: String
    @Binding private var text: String
    private let helperText: String?
    private let validation: (@Sendable (String) -> ValidationResult)?
    private let formState: FormState?
    private let fieldKey: String?
    private let showPasswordToggle: Bool
    private let showStrengthIndicator: Bool
    private let onCommit: (() -> Void)?

    @State private var validationState: ValidationState
    @State private var isFocused: Bool = false
    @State private var isPasswordVisible: Bool = false

    private var isDisabled: Bool

    // MARK: - Initializers

    /// Inicializa un EduSecureField con validación completa.
    ///
    /// - Parameters:
    ///   - title: Título del campo (label)
    ///   - text: Binding al texto de la contraseña
    ///   - placeholder: Texto placeholder cuando está vacío
    ///   - helperText: Texto de ayuda opcional debajo del campo
    ///   - validation: Closure de validación opcional
    ///   - formState: FormState opcional para integración con formularios
    ///   - fieldKey: Clave única para registro en FormState
    ///   - showPasswordToggle: Mostrar botón para revelar contraseña (default: true)
    ///   - showStrengthIndicator: Mostrar indicador de fortaleza (default: false)
    ///   - isDisabled: Si el campo está deshabilitado
    ///   - onCommit: Closure que se ejecuta al presionar return/enter
    public init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        helperText: String? = nil,
        validation: (@Sendable (String) -> ValidationResult)? = nil,
        formState: FormState? = nil,
        fieldKey: String? = nil,
        showPasswordToggle: Bool = true,
        showStrengthIndicator: Bool = false,
        isDisabled: Bool = false,
        onCommit: (() -> Void)? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.helperText = helperText
        self.validation = validation
        self.formState = formState
        self.fieldKey = fieldKey
        self.showPasswordToggle = showPasswordToggle
        self.showStrengthIndicator = showStrengthIndicator
        self.isDisabled = isDisabled
        self.onCommit = onCommit
        self._validationState = State(initialValue: ValidationState())

        // Registrar en FormState si está disponible
        if let formState = formState, let fieldKey = fieldKey, let validation = validation {
            formState.registerField(fieldKey) { [text] in
                validation(text.wrappedValue)
            }
        }
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isDisabled ? .secondary : .primary)

            // Campo de contraseña con toggle
            HStack(spacing: 8) {
                Group {
                    if isPasswordVisible {
                        TextField(placeholder, text: $text, onCommit: {
                            validateField()
                            onCommit?()
                        })
                    } else {
                        SecureField(placeholder, text: $text, onCommit: {
                            validateField()
                            onCommit?()
                        })
                    }
                }
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                #endif
                .disabled(isDisabled)
                .onChange(of: text) { _, newValue in
                    validateField()
                }
                .onFocusChange { focused in
                    isFocused = focused
                }

                // Toggle button (solo en plataformas aplicables)
                #if os(iOS) || os(macOS) || os(visionOS)
                if showPasswordToggle {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
                    .accessibilityLabel(isPasswordVisible ? "Ocultar contraseña" : "Mostrar contraseña")
                }
                #endif
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
            )

            // Indicador de fortaleza
            if showStrengthIndicator && !text.isEmpty {
                PasswordStrengthIndicator(password: text)
            }

            // Helper text o error message
            if let error = validationState.errorMessage {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if let helper = helperText {
                Text(helper)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(isDisabled ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: validationState.errorMessage)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    // MARK: - Helper Methods

    private var borderColor: Color {
        if isDisabled {
            return .secondary.opacity(0.3)
        }
        if !validationState.isValid {
            return .red
        }
        if isFocused {
            return .accentColor
        }
        return .secondary.opacity(0.5)
    }

    private func validateField() {
        guard let validation = validation else {
            validationState.isValid = true
            validationState.errorMessage = nil
            return
        }

        let result = validation(text)
        validationState.isValid = result.isValid
        validationState.errorMessage = result.errorMessage

        // Actualizar FormState si está disponible
        if let formState = formState, let fieldKey = fieldKey {
            formState.validateField(fieldKey)
        }
    }
}

// MARK: - Password Strength Indicator

@MainActor
private struct PasswordStrengthIndicator: View {
    let password: String

    private var strength: PasswordStrength {
        calculateStrength(password)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index < strength.level ? strength.color : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }

            Text(strength.text)
                .font(.caption)
                .foregroundStyle(strength.color)
        }
    }

    private func calculateStrength(_ password: String) -> PasswordStrength {
        var score = 0

        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }

        switch score {
        case 0...2:
            return PasswordStrength(level: 1, text: "Débil", color: .red)
        case 3...4:
            return PasswordStrength(level: 2, text: "Media", color: .orange)
        case 5:
            return PasswordStrength(level: 3, text: "Buena", color: .yellow)
        default:
            return PasswordStrength(level: 4, text: "Fuerte", color: .green)
        }
    }
}

private struct PasswordStrength {
    let level: Int
    let text: String
    let color: Color
}

// MARK: - Previews

#Preview("Basic SecureField") {
    @Previewable @State var password = ""

    EduSecureField(
        "Contraseña",
        text: $password,
        placeholder: "Ingresa tu contraseña",
        helperText: "Mínimo 8 caracteres"
    )
    .padding()
}

#Preview("SecureField con Validación") {
    @Previewable @State var password = "123"

    EduSecureField(
        "Contraseña",
        text: $password,
        placeholder: "Mínimo 8 caracteres",
        validation: Validators.password(minLength: 8)
    )
    .padding()
}

#Preview("SecureField con Indicador de Fortaleza") {
    @Previewable @State var password = "MyP@ssw0rd!"

    EduSecureField(
        "Contraseña",
        text: $password,
        placeholder: "Ingresa contraseña segura",
        showStrengthIndicator: true
    )
    .padding()
}

#Preview("SecureField sin Toggle") {
    @Previewable @State var password = "secreto"

    EduSecureField(
        "PIN Seguro",
        text: $password,
        placeholder: "****",
        showPasswordToggle: false
    )
    .padding()
}

#Preview("SecureField con FormState") {
    @Previewable @State var password = ""
    @Previewable @State var formState = FormState()

    VStack(spacing: 16) {
        EduSecureField(
            "Contraseña",
            text: $password,
            placeholder: "Mínimo 8 caracteres",
            validation: Validators.password(minLength: 8),
            formState: formState,
            fieldKey: "password",
            showStrengthIndicator: true
        )

        Text("Formulario válido: \(formState.isValid ? "Sí" : "No")")
            .foregroundStyle(formState.isValid ? .green : .red)
    }
    .padding()
}
