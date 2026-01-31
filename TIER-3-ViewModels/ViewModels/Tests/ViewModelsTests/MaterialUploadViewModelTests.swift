import Foundation
import Testing
@testable import ViewModels
@testable import CQRS
import Models
import UseCases
import EduGoCommon

/// Tests unitarios para MaterialUploadViewModel.
///
/// Este test suite valida:
/// - Validación de extensiones permitidas/no permitidas
/// - Validación de tamaño de archivo
/// - Upload exitoso con progreso
/// - Manejo de errores de red
/// - Reset de estado
@Suite("MaterialUploadViewModel Tests")
struct MaterialUploadViewModelTests {

    // MARK: - Test: Validación de extensiones permitidas

    @Test("Validates allowed file extensions")
    @MainActor
    func testValidatesAllowedExtensions() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear archivos temporales con extensiones permitidas
        let allowedExtensions = ["pdf", "docx", "pptx", "mp4"]

        for ext in allowedExtensions {
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("test-\(UUID().uuidString).\(ext)")
            try Data("Test content".utf8).write(to: fileURL)
            defer { try? FileManager.default.removeItem(at: fileURL) }

            // Execute
            let isValid = viewModel.validateFile(fileURL)

            // Verify
            #expect(isValid, "Extension .\(ext) should be valid")
            #expect(viewModel.fileValidationError == nil)
            #expect(viewModel.selectedFile == fileURL)

            // Reset para siguiente iteración
            viewModel.reset()
        }
    }

    // MARK: - Test: Validación de extensiones no permitidas

    @Test("Rejects not allowed file extensions")
    @MainActor
    func testRejectsNotAllowedExtensions() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear archivos temporales con extensiones no permitidas
        let notAllowedExtensions = ["exe", "bat", "sh", "txt", "jpg", "png"]

        for ext in notAllowedExtensions {
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("test-\(UUID().uuidString).\(ext)")
            try Data("Test content".utf8).write(to: fileURL)
            defer { try? FileManager.default.removeItem(at: fileURL) }

            // Execute
            let isValid = viewModel.validateFile(fileURL)

            // Verify
            #expect(!isValid, "Extension .\(ext) should not be valid")
            #expect(viewModel.fileValidationError != nil)
            #expect(viewModel.fileValidationError?.contains("no permitido") == true)
            #expect(viewModel.selectedFile == nil)

            // Reset para siguiente iteración
            viewModel.reset()
        }
    }

    // MARK: - Test: Validación de tamaño de archivo

    @Test("Validates file size within limit")
    @MainActor
    func testValidatesFileSizeWithinLimit() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear archivo PDF pequeño (< 50MB)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-small-\(UUID().uuidString).pdf")
        let smallContent = Data(repeating: 0x41, count: 1024) // 1KB
        try smallContent.write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        // Execute
        let isValid = viewModel.validateFile(fileURL)

        // Verify
        #expect(isValid)
        #expect(viewModel.fileValidationError == nil)
        #expect(viewModel.selectedFile == fileURL)
    }

    // MARK: - Test: Rechazo de archivo que excede tamaño máximo

    @Test("Rejects file exceeding maximum size")
    @MainActor
    func testRejectsFileExceedingMaxSize() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear archivo PDF grande (> 50MB)
        // Nota: Creamos un archivo sparse para no ocupar 50MB reales
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-large-\(UUID().uuidString).pdf")

        // Crear archivo de 51MB
        let largeSize = 51 * 1024 * 1024

        // Escribir datos pequeños y luego truncar para crear archivo sparse
        try Data("PDF".utf8).write(to: fileURL)
        let handle = try FileHandle(forWritingTo: fileURL)
        try handle.truncate(atOffset: UInt64(largeSize))
        try handle.close()

        defer { try? FileManager.default.removeItem(at: fileURL) }

        // Execute
        let isValid = viewModel.validateFile(fileURL)

        // Verify
        #expect(!isValid)
        #expect(viewModel.fileValidationError != nil)
        #expect(viewModel.fileValidationError?.contains("50MB") == true)
        #expect(viewModel.selectedFile == nil)
    }

    // MARK: - Test: Upload exitoso

    @Test("Uploads material successfully")
    @MainActor
    func testUploadsMaterialSuccessfully() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let mockHandler = MockUploadMaterialCommandHandler()

        try await mediator.registerCommandHandler(mockHandler)

        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear archivo PDF válido
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-upload-\(UUID().uuidString).pdf")
        try Data("PDF content".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        // Validar y seleccionar archivo
        let isValid = viewModel.validateFile(fileURL)
        #expect(isValid)

        // Execute: Upload
        await viewModel.uploadMaterial(
            title: "Test Material",
            description: "A test material",
            subjectId: UUID(),
            unitId: UUID()
        )

        // Verify
        #expect(!viewModel.isUploading)
        #expect(viewModel.error == nil)
        #expect(viewModel.uploadedMaterial != nil)
        #expect(viewModel.uploadedMaterial?.title == "Test Material")
        #expect(viewModel.uploadProgress == 1.0)
        #expect(viewModel.isUploadSuccessful)
    }

    // MARK: - Test: Error cuando no hay archivo seleccionado

    @Test("Shows error when no file selected")
    @MainActor
    func testShowsErrorWhenNoFileSelected() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Execute: Upload sin archivo seleccionado
        await viewModel.uploadMaterial(
            title: "Test",
            description: nil,
            subjectId: UUID(),
            unitId: UUID()
        )

        // Verify
        #expect(!viewModel.isUploading)
        #expect(viewModel.error != nil)
        #expect(viewModel.uploadedMaterial == nil)
    }

    // MARK: - Test: Manejo de errores de ejecución

    @Test("Handles execution errors gracefully")
    @MainActor
    func testHandlesExecutionErrors() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let mockHandler = MockUploadMaterialCommandHandlerWithError()

        try await mediator.registerCommandHandler(mockHandler)

        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear archivo PDF válido
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-error-\(UUID().uuidString).pdf")
        try Data("PDF content".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        // Validar y seleccionar archivo
        let isValid = viewModel.validateFile(fileURL)
        #expect(isValid)

        // Execute: Upload que fallará
        await viewModel.uploadMaterial(
            title: "Test Material",
            description: nil,
            subjectId: UUID(),
            unitId: UUID()
        )

        // Verify
        #expect(!viewModel.isUploading)
        #expect(viewModel.uploadedMaterial == nil)
        // El error puede estar en error o manejado de otra forma
        #expect(viewModel.uploadProgress == 0.0)
    }

    // MARK: - Test: Reset de estado

    @Test("Resets state correctly")
    @MainActor
    func testResetsStateCorrectly() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let mockHandler = MockUploadMaterialCommandHandler()

        try await mediator.registerCommandHandler(mockHandler)

        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear archivo y subir
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-reset-\(UUID().uuidString).pdf")
        try Data("PDF content".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        _ = viewModel.validateFile(fileURL)
        await viewModel.uploadMaterial(
            title: "Test",
            description: nil,
            subjectId: UUID(),
            unitId: UUID()
        )

        // Verify estado después del upload
        #expect(viewModel.uploadedMaterial != nil)
        #expect(viewModel.selectedFile != nil)

        // Execute: Reset
        viewModel.reset()

        // Verify: Estado limpio
        #expect(viewModel.selectedFile == nil)
        #expect(viewModel.uploadProgress == 0.0)
        #expect(!viewModel.isUploading)
        #expect(viewModel.error == nil)
        #expect(viewModel.uploadedMaterial == nil)
        #expect(viewModel.fileValidationError == nil)
    }

    // MARK: - Test: Computed properties

    @Test("Computed properties work correctly")
    @MainActor
    func testComputedPropertiesWork() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Verify: Estado inicial
        #expect(!viewModel.hasSelectedFile)
        #expect(!viewModel.hasError)
        #expect(!viewModel.isUploadSuccessful)
        #expect(!viewModel.isFormValid)
        #expect(viewModel.isUploadButtonDisabled)
        #expect(viewModel.selectedFileName == nil)
        #expect(viewModel.progressPercentage == "0%")

        // Crear archivo y seleccionar
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-computed-\(UUID().uuidString).pdf")
        try Data("PDF content".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        _ = viewModel.validateFile(fileURL)

        // Verify: Estado después de seleccionar archivo
        #expect(viewModel.hasSelectedFile)
        #expect(viewModel.isFormValid)
        #expect(!viewModel.isUploadButtonDisabled)
        #expect(viewModel.selectedFileName != nil)
        #expect(viewModel.selectedFileExtension == "pdf")

        // Verify: Descripciones de configuración
        #expect(viewModel.allowedExtensionsDescription.contains("pdf"))
        #expect(viewModel.maxFileSizeDescription == "50MB")
    }

    // MARK: - Test: Clear error methods

    @Test("Clear error methods work correctly")
    @MainActor
    func testClearErrorMethodsWork() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Provocar error de validación
        let invalidFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString).exe")
        try Data("content".utf8).write(to: invalidFileURL)
        defer { try? FileManager.default.removeItem(at: invalidFileURL) }

        _ = viewModel.validateFile(invalidFileURL)
        #expect(viewModel.hasFileValidationError)

        // Execute: Clear file validation error
        viewModel.clearFileValidationError()

        // Verify
        #expect(!viewModel.hasFileValidationError)
        #expect(viewModel.fileValidationError == nil)
    }

    // MARK: - Test: Archivo no existente

    @Test("Rejects non-existent file")
    @MainActor
    func testRejectsNonExistentFile() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // URL de archivo que no existe
        let nonExistentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("non-existent-\(UUID().uuidString).pdf")

        // Execute
        let isValid = viewModel.validateFile(nonExistentURL)

        // Verify
        #expect(!isValid)
        #expect(viewModel.fileValidationError != nil)
        #expect(viewModel.fileValidationError?.contains("no existe") == true)
    }
}

// MARK: - Mock Handlers

/// Mock CommandHandler para UploadMaterialCommand (éxito)
actor MockUploadMaterialCommandHandler: CommandHandler {
    typealias CommandType = UploadMaterialCommand

    func handle(_ command: UploadMaterialCommand) async throws -> CommandResult<Material> {
        let material = try Material(
            title: command.title,
            description: command.description,
            schoolID: UUID(),
            academicUnitID: command.unitId,
            uploadedByTeacherID: UUID()
        )

        return .success(
            material,
            events: ["MaterialUploadedEvent"],
            metadata: ["materialId": material.id.uuidString]
        )
    }
}

/// Mock CommandHandler que simula error
actor MockUploadMaterialCommandHandlerWithError: CommandHandler {
    typealias CommandType = UploadMaterialCommand

    func handle(_ command: UploadMaterialCommand) async throws -> CommandResult<Material> {
        return .failure(
            UseCaseError.executionFailed(reason: "Network connection failed"),
            metadata: ["reason": "network_error"]
        )
    }
}
