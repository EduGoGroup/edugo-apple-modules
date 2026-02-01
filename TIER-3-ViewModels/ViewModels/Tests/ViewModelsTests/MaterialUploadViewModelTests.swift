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

        // Crear archivos temporales con extensiones permitidas usando FileTestHelper
        let testFiles: [(ext: String, creator: () throws -> URL)] = [
            ("pdf", { try FileTestHelper.createValidPDF() }),
            ("docx", { try FileTestHelper.createValidDOCX() }),
            ("pptx", { try FileTestHelper.createValidPPTX() }),
            ("mp4", { try FileTestHelper.createValidMP4() })
        ]

        for (ext, creator) in testFiles {
            let fileURL = try creator()
            defer { FileTestHelper.cleanup(fileURL) }

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

        // Crear archivo PDF pequeño (< 50MB) usando FileTestHelper
        let fileURL = try FileTestHelper.createValidPDF()
        defer { FileTestHelper.cleanup(fileURL) }

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

        // Crear archivo PDF grande (> 50MB) usando FileTestHelper
        let fileURL = try FileTestHelper.createFileWithSize(extension: "pdf", sizeInBytes: 51 * 1024 * 1024)
        defer { FileTestHelper.cleanup(fileURL) }

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

        // Crear archivo PDF válido usando FileTestHelper
        let fileURL = try FileTestHelper.createValidPDF()
        defer { FileTestHelper.cleanup(fileURL) }

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

        // Crear archivo PDF válido usando FileTestHelper
        let fileURL = try FileTestHelper.createValidPDF()
        defer { FileTestHelper.cleanup(fileURL) }

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

        // Crear archivo y subir usando FileTestHelper
        let fileURL = try FileTestHelper.createValidPDF()
        defer { FileTestHelper.cleanup(fileURL) }

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

        // Crear archivo y seleccionar usando FileTestHelper
        let fileURL = try FileTestHelper.createValidPDF()
        defer { FileTestHelper.cleanup(fileURL) }

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

        // Crear URL de archivo no existente
        let nonExistentFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("non-existent-\(UUID().uuidString).pdf")

        // Act
        let isValid = viewModel.validateFile(nonExistentFile)

        // Assert
        #expect(!isValid, "Archivo no existente debe ser rechazado")
        #expect(viewModel.fileValidationError != nil, "Debe haber un error de validación")
        #expect(viewModel.selectedFile == nil, "selectedFile debe ser nil")
    }

    // MARK: - Test: Validación de título vacío

    @Test("Rejects empty title")
    @MainActor
    func testRejectsEmptyTitle() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear y seleccionar archivo válido
        let fileURL = try FileTestHelper.createValidPDF()
        defer { FileTestHelper.cleanup(fileURL) }
        _ = viewModel.validateFile(fileURL)

        // Execute: Intentar subir con título vacío
        await viewModel.uploadMaterial(
            title: "",
            description: nil,
            subjectId: UUID(),
            unitId: UUID()
        )

        // Verify
        #expect(!viewModel.isUploading)
        #expect(viewModel.error != nil)
        #expect(viewModel.uploadedMaterial == nil)
    }

    // MARK: - Test: Validación de título solo espacios

    @Test("Rejects title with only whitespace")
    @MainActor
    func testRejectsTitleWithOnlyWhitespace() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear y seleccionar archivo válido
        let fileURL = try FileTestHelper.createValidPDF()
        defer { FileTestHelper.cleanup(fileURL) }
        _ = viewModel.validateFile(fileURL)

        // Execute: Intentar subir con título de solo espacios
        await viewModel.uploadMaterial(
            title: "   ",
            description: nil,
            subjectId: UUID(),
            unitId: UUID()
        )

        // Verify
        #expect(!viewModel.isUploading)
        #expect(viewModel.error != nil)
        #expect(viewModel.uploadedMaterial == nil)
    }

    // MARK: - Test: Validación de título muy corto

    @Test("Rejects title too short")
    @MainActor
    func testRejectsTitleTooShort() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear y seleccionar archivo válido
        let fileURL = try FileTestHelper.createValidPDF()
        defer { FileTestHelper.cleanup(fileURL) }
        _ = viewModel.validateFile(fileURL)

        // Execute: Intentar subir con título de 2 caracteres (mínimo es 3)
        await viewModel.uploadMaterial(
            title: "AB",
            description: nil,
            subjectId: UUID(),
            unitId: UUID()
        )

        // Verify
        #expect(!viewModel.isUploading)
        #expect(viewModel.error != nil)
        #expect(viewModel.uploadedMaterial == nil)
    }

    // MARK: - Test: Validación de título muy largo

    @Test("Rejects title too long")
    @MainActor
    func testRejectsTitleTooLong() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear y seleccionar archivo válido
        let fileURL = try FileTestHelper.createValidPDF()
        defer { FileTestHelper.cleanup(fileURL) }
        _ = viewModel.validateFile(fileURL)

        // Execute: Intentar subir con título de 201 caracteres (máximo es 200)
        let longTitle = String(repeating: "a", count: 201)
        await viewModel.uploadMaterial(
            title: longTitle,
            description: nil,
            subjectId: UUID(),
            unitId: UUID()
        )

        // Verify
        #expect(!viewModel.isUploading)
        #expect(viewModel.error != nil)
        #expect(viewModel.uploadedMaterial == nil)
    }

    // MARK: - Test: Validación de descripción muy larga

    @Test("Rejects description too long")
    @MainActor
    func testRejectsDescriptionTooLong() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear y seleccionar archivo válido
        let fileURL = try FileTestHelper.createValidPDF()
        defer { FileTestHelper.cleanup(fileURL) }
        _ = viewModel.validateFile(fileURL)

        // Execute: Intentar subir con descripción de 1001 caracteres (máximo es 1000)
        let longDescription = String(repeating: "a", count: 1001)
        await viewModel.uploadMaterial(
            title: "Valid Title",
            description: longDescription,
            subjectId: UUID(),
            unitId: UUID()
        )

        // Verify
        #expect(!viewModel.isUploading)
        #expect(viewModel.error != nil)
        #expect(viewModel.uploadedMaterial == nil)
    }

    // MARK: - Test: Título válido con espacios al inicio y final

    @Test("Trims whitespace from title")
    @MainActor
    func testTrimsWhitespaceFromTitle() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let eventBus = EventBus()
        let mockHandler = MockUploadMaterialCommandHandler()
        try await mediator.registerCommandHandler(mockHandler)
        let viewModel = MaterialUploadViewModel(mediator: mediator, eventBus: eventBus)

        // Crear y seleccionar archivo válido
        let fileURL = try FileTestHelper.createValidPDF()
        defer { FileTestHelper.cleanup(fileURL) }
        _ = viewModel.validateFile(fileURL)

        // Execute: Subir con título que tiene espacios al inicio y final
        await viewModel.uploadMaterial(
            title: "  Valid Title  ",
            description: "  Valid Description  ",
            subjectId: UUID(),
            unitId: UUID()
        )

        // Verify: El upload debe ser exitoso con el título trimmed
        #expect(!viewModel.isUploading)
        #expect(viewModel.error == nil)
        #expect(viewModel.uploadedMaterial != nil)
        #expect(viewModel.uploadedMaterial?.title == "Valid Title")
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
