import Foundation
import SwiftUI
import CQRS
import Models
import EduGoCommon

/// ViewModel para gestionar la carga de materiales educativos usando CQRS Mediator.
///
/// Este ViewModel gestiona la subida de archivos con validación previa,
/// progreso de carga en tiempo real y manejo de errores específicos.
///
/// ## Responsabilidades
/// - Validar archivos antes de la subida (extensión, tamaño)
/// - Ejecutar UploadMaterialCommand via Mediator
/// - Gestionar progreso de carga en tiempo real
/// - Publicar MaterialUploadedEvent después de subida exitosa
///
/// ## Integración con CQRS
/// - **Commands**: UploadMaterialCommand (con validación pre-ejecución)
/// - **Events**: MaterialUploadedEvent (publicado automáticamente por handler)
///
/// ## Validaciones
/// - Extensiones permitidas: pdf, docx, pptx, mp4
/// - Tamaño máximo: 50MB
///
/// ## Ejemplo de uso
/// ```swift
/// @StateObject private var viewModel = MaterialUploadViewModel(
///     mediator: mediator,
///     eventBus: eventBus
/// )
///
/// // Validar archivo seleccionado
/// if viewModel.validateFile(selectedFileURL) {
///     await viewModel.uploadMaterial(
///         title: "Introducción",
///         description: "Material introductorio",
///         subjectId: subjectId,
///         unitId: unitId
///     )
/// }
/// ```
@MainActor
@Observable
public final class MaterialUploadViewModel {

    // MARK: - Published State

    /// Progreso de la carga (0.0 - 1.0)
    public var uploadProgress: Double = 0.0

    /// Indica si está subiendo un archivo
    public var isUploading: Bool = false

    /// Error actual si lo hay
    public var error: Error?

    /// Material subido exitosamente
    public var uploadedMaterial: Models.Material?

    // MARK: - Validation State

    /// Archivo seleccionado para subir
    public var selectedFile: URL?

    /// Error de validación del archivo
    public var fileValidationError: String?

    // MARK: - Dependencies

    /// Mediator CQRS para dispatch de commands
    private let mediator: Mediator

    /// EventBus para suscripción a eventos
    private let eventBus: EventBus

    /// IDs de suscripciones a eventos (para cleanup)
    private var subscriptionIds: [UUID] = []

    // MARK: - Constants

    /// Tamaño máximo de archivo en bytes (50MB)
    private let maxFileSize: Int = 50 * 1024 * 1024

    /// Extensiones de archivo permitidas
    private let allowedExtensions: Set<String> = ["pdf", "docx", "pptx", "mp4"]

    // MARK: - Initialization

    /// Crea un nuevo MaterialUploadViewModel.
    ///
    /// - Parameters:
    ///   - mediator: Mediator CQRS para ejecutar commands
    ///   - eventBus: EventBus para suscribirse a eventos de dominio
    public init(
        mediator: Mediator,
        eventBus: EventBus
    ) {
        self.mediator = mediator
        self.eventBus = eventBus
    }

    // MARK: - Public Methods

    /// Valida un archivo antes de la subida.
    ///
    /// Verifica que el archivo tenga una extensión permitida y no exceda
    /// el tamaño máximo de 50MB.
    ///
    /// - Parameter fileURL: URL del archivo a validar
    /// - Returns: `true` si el archivo es válido, `false` en caso contrario
    public func validateFile(_ fileURL: URL) -> Bool {
        // Limpiar estado previo
        fileValidationError = nil

        // Validar extensión
        let ext = fileURL.pathExtension.lowercased()
        guard allowedExtensions.contains(ext) else {
            fileValidationError = "Tipo de archivo no permitido. Use: \(allowedExtensions.sorted().joined(separator: ", "))"
            return false
        }

        // Validar existencia del archivo
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else {
            fileValidationError = "El archivo no existe en la ruta especificada"
            return false
        }

        // Validar tamaño
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int {
                guard fileSize <= maxFileSize else {
                    let maxSizeMB = maxFileSize / (1024 * 1024)
                    fileValidationError = "El archivo excede el tamaño máximo de \(maxSizeMB)MB"
                    return false
                }
            }
        } catch {
            fileValidationError = "No se pudo leer el archivo: \(error.localizedDescription)"
            return false
        }

        selectedFile = fileURL
        return true
    }

    /// Sube un material educativo.
    ///
    /// Crea un UploadMaterialCommand y lo ejecuta via Mediator.
    /// El progreso se actualiza en tiempo real si el handler lo soporta.
    ///
    /// - Parameters:
    ///   - title: Título del material (3-200 caracteres)
    ///   - description: Descripción opcional del material
    ///   - subjectId: ID de la materia asociada
    ///   - unitId: ID de la unidad académica
    public func uploadMaterial(
        title: String,
        description: String?,
        subjectId: UUID,
        unitId: UUID
    ) async {
        guard let fileURL = selectedFile else {
            error = ValidationError.emptyField(fieldName: "file")
            return
        }

        isUploading = true
        uploadProgress = 0.0
        error = nil

        do {
            // Crear command con datos del material
            let command = UploadMaterialCommand(
                fileURL: fileURL,
                title: title,
                subjectId: subjectId,
                unitId: unitId,
                description: description,
                metadata: [
                    "source": "MaterialUploadViewModel",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )

            // Ejecutar command via Mediator (con validación automática)
            let result = try await mediator.execute(command)

            // Verificar resultado del command
            if result.isSuccess, let material = result.getValue() {
                // Subida exitosa
                self.uploadedMaterial = material
                self.uploadProgress = 1.0
                self.isUploading = false

                print("✅ Material subido exitosamente: \(material.id)")
                print("📢 Eventos publicados: \(result.events)")

            } else if let resultError = result.getError() {
                // Subida falló
                self.error = resultError
                self.isUploading = false

                print("❌ Error al subir material: \(resultError.localizedDescription)")
            }

        } catch {
            // Manejar errores de validación o ejecución
            self.error = error
            self.isUploading = false

            print("❌ Error en uploadMaterial: \(error.localizedDescription)")
        }
    }

    /// Limpia el estado del ViewModel para una nueva carga.
    public func reset() {
        selectedFile = nil
        uploadProgress = 0.0
        isUploading = false
        error = nil
        uploadedMaterial = nil
        fileValidationError = nil
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    /// Limpia el error de validación de archivo.
    public func clearFileValidationError() {
        fileValidationError = nil
    }
}

// MARK: - Convenience Computed Properties

extension MaterialUploadViewModel {
    /// Indica si hay un archivo seleccionado
    public var hasSelectedFile: Bool {
        selectedFile != nil
    }

    /// Indica si hay un error
    public var hasError: Bool {
        error != nil
    }

    /// Indica si hay un error de validación de archivo
    public var hasFileValidationError: Bool {
        fileValidationError != nil
    }

    /// Indica si la subida fue exitosa
    public var isUploadSuccessful: Bool {
        uploadedMaterial != nil
    }

    /// Nombre del archivo seleccionado
    public var selectedFileName: String? {
        selectedFile?.lastPathComponent
    }

    /// Extensión del archivo seleccionado
    public var selectedFileExtension: String? {
        selectedFile?.pathExtension.lowercased()
    }

    /// Indica si el formulario es válido para enviar
    public var isFormValid: Bool {
        selectedFile != nil && fileValidationError == nil
    }

    /// Indica si el botón de subir debe estar deshabilitado
    public var isUploadButtonDisabled: Bool {
        isUploading || !isFormValid
    }

    /// Mensaje de error legible
    public var errorMessage: String? {
        guard let error = error else { return nil }

        // Personalizar mensajes según tipo de error
        if let validationError = error as? ValidationError {
            return validationError.localizedDescription
        }

        if let mediatorError = error as? MediatorError {
            switch mediatorError {
            case .handlerNotFound:
                return "Error de configuración del sistema. Contacte soporte."
            case .validationError(let message, _):
                return message
            case .executionError(let message, _):
                return "Error al subir: \(message)"
            case .registrationError:
                return "Error de configuración del sistema."
            }
        }

        return error.localizedDescription
    }

    /// Porcentaje de progreso formateado
    public var progressPercentage: String {
        let percentage = Int(uploadProgress * 100)
        return "\(percentage)%"
    }

    /// Lista de extensiones permitidas para mostrar al usuario
    public var allowedExtensionsDescription: String {
        allowedExtensions.sorted().joined(separator: ", ")
    }

    /// Tamaño máximo formateado para mostrar al usuario
    public var maxFileSizeDescription: String {
        let sizeMB = maxFileSize / (1024 * 1024)
        return "\(sizeMB)MB"
    }
}
