import Testing
import Foundation
@testable import UseCases
import Models
import EduGoCommon

// MARK: - Mock Repositories

/// Mock de MaterialUploadRepository para testing
actor MockMaterialUploadRepository: MaterialUploadRepositoryProtocol {
    var shouldFailCreate = false
    var shouldFailUploadURL = false
    var shouldFailS3Upload = false
    var shouldFailNotifyComplete = false
    var shouldFailGetMaterial = false
    var shouldFailDelete = false

    var createCallCount = 0
    var uploadURLCallCount = 0
    var s3UploadCallCount = 0
    var notifyCompleteCallCount = 0
    var getMaterialCallCount = 0
    var deleteCallCount = 0

    var mockMaterial: Material?
    var mockUploadURL = URL(string: "https://s3.amazonaws.com/bucket/materials/test.pdf?X-Amz-Algorithm=...")!
    var mockFileURL = URL(string: "https://s3.amazonaws.com/bucket/materials/test.pdf")!
    var mockExpiresIn = 900

    var materialStatuses: [UUID: MaterialStatus] = [:]

    func createMaterial(
        title: String,
        description: String?,
        subject: String?,
        grade: String?
    ) async throws -> Material {
        createCallCount += 1

        if shouldFailCreate {
            throw RepositoryError.saveFailed(reason: "Mock create error")
        }

        let material = try! Material(
            id: UUID(),
            title: title,
            description: description,
            status: .uploaded,
            schoolID: UUID()
        )

        mockMaterial = material
        materialStatuses[material.id] = .uploaded

        return material
    }

    func requestUploadURL(
        materialId: UUID,
        fileName: String,
        contentType: String
    ) async throws -> (uploadURL: URL, fileURL: URL, expiresIn: Int) {
        uploadURLCallCount += 1

        if shouldFailUploadURL {
            throw RepositoryError.fetchFailed(reason: "Mock upload URL error")
        }

        return (mockUploadURL, mockFileURL, mockExpiresIn)
    }

    func uploadToS3(
        fileURL: URL,
        uploadURL: URL,
        contentType: String,
        progressHandler: @escaping @Sendable (Int) -> Void
    ) async throws {
        s3UploadCallCount += 1

        if shouldFailS3Upload {
            throw RepositoryError.connectionError(reason: "Mock S3 upload error")
        }

        // Simulate progress
        for progress in stride(from: 0, through: 100, by: 25) {
            progressHandler(progress)
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    func notifyUploadComplete(
        materialId: UUID,
        fileURL: URL,
        fileType: String,
        fileSizeBytes: Int
    ) async throws {
        notifyCompleteCallCount += 1

        if shouldFailNotifyComplete {
            throw RepositoryError.saveFailed(reason: "Mock notify complete error")
        }

        // Transition to processing
        materialStatuses[materialId] = .processing
    }

    func getMaterial(id: UUID) async throws -> Material {
        getMaterialCallCount += 1

        if shouldFailGetMaterial {
            throw RepositoryError.fetchFailed(reason: "Mock get material error")
        }

        guard let material = mockMaterial else {
            throw RepositoryError.fetchFailed(reason: "Material not found")
        }

        let status = materialStatuses[id] ?? .processing

        // Simulate processing completion after 2 calls
        if getMaterialCallCount >= 2 && status == .processing {
            materialStatuses[id] = .ready
        }

        return material.with(status: materialStatuses[id] ?? .processing)
    }

    func deleteMaterial(id: UUID) async throws {
        deleteCallCount += 1

        if shouldFailDelete {
            throw RepositoryError.deleteFailed(reason: "Mock delete error")
        }

        materialStatuses.removeValue(forKey: id)
        mockMaterial = nil
    }

    func setMaterialStatus(_ materialId: UUID, status: MaterialStatus) {
        materialStatuses[materialId] = status
    }

    func reset() {
        shouldFailCreate = false
        shouldFailUploadURL = false
        shouldFailS3Upload = false
        shouldFailNotifyComplete = false
        shouldFailGetMaterial = false
        shouldFailDelete = false
        createCallCount = 0
        uploadURLCallCount = 0
        s3UploadCallCount = 0
        notifyCompleteCallCount = 0
        getMaterialCallCount = 0
        deleteCallCount = 0
        mockMaterial = nil
        materialStatuses = [:]
    }
}

/// Mock de FileValidator para testing
struct MockFileValidator: FileValidatorProtocol, Sendable {
    var fileExistsResult: Bool = true
    var fileSizeResult: Int = 1024 * 1024 // 1MB
    var mimeTypeResult: String = "application/pdf"
    var shouldThrowOnSize = false
    var shouldThrowOnMimeType = false

    func fileExists(at url: URL) -> Bool {
        fileExistsResult
    }

    func fileSize(at url: URL) throws -> Int {
        if shouldThrowOnSize {
            throw UploadMaterialError.fileReadError(reason: "Mock file size error")
        }
        return fileSizeResult
    }

    func mimeType(at url: URL) throws -> String {
        if shouldThrowOnMimeType {
            throw UploadMaterialError.fileReadError(reason: "Mock mime type error")
        }
        return mimeTypeResult
    }
}

// MARK: - UploadMaterialInput Tests

@Suite("UploadMaterialInput Tests")
struct UploadMaterialInputTests {

    @Test("init crea input correctamente con todos los parámetros")
    func initCreatesInputWithAllParameters() {
        let fileURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let subjectId = UUID()
        let unitId = UUID()

        let input = UploadMaterialInput(
            fileURL: fileURL,
            title: "Test Material",
            subjectId: subjectId,
            unitId: unitId,
            description: "Test description"
        )

        #expect(input.fileURL == fileURL)
        #expect(input.title == "Test Material")
        #expect(input.subjectId == subjectId)
        #expect(input.unitId == unitId)
        #expect(input.description == "Test description")
    }

    @Test("init crea input sin descripción")
    func initCreatesInputWithoutDescription() {
        let fileURL = URL(fileURLWithPath: "/tmp/test.pdf")

        let input = UploadMaterialInput(
            fileURL: fileURL,
            title: "Test",
            subjectId: UUID(),
            unitId: UUID()
        )

        #expect(input.description == nil)
    }
}

// MARK: - UploadProgress Tests

@Suite("UploadProgress Tests")
struct UploadProgressTests {

    @Test("UploadProgress.uploading incluye porcentaje")
    func uploadingIncludesPercentage() {
        let progress = UploadProgress.uploading(progress: 50)

        if case .uploading(let percent) = progress {
            #expect(percent == 50)
        } else {
            Issue.record("Expected .uploading state")
        }
    }

    @Test("UploadProgress.failed incluye razón")
    func failedIncludesReason() {
        let progress = UploadProgress.failed(reason: "Test error")

        if case .failed(let reason) = progress {
            #expect(reason == "Test error")
        } else {
            Issue.record("Expected .failed state")
        }
    }

    @Test("UploadProgress estados son equatable")
    func statesAreEquatable() {
        #expect(UploadProgress.validating == UploadProgress.validating)
        #expect(UploadProgress.creating == UploadProgress.creating)
        #expect(UploadProgress.processing == UploadProgress.processing)
        #expect(UploadProgress.ready == UploadProgress.ready)
        #expect(UploadProgress.uploading(progress: 50) == UploadProgress.uploading(progress: 50))
        #expect(UploadProgress.uploading(progress: 50) != UploadProgress.uploading(progress: 75))
    }
}

// MARK: - UploadMaterialError Tests

@Suite("UploadMaterialError Tests")
struct UploadMaterialErrorTests {

    @Test("invalidTitleLength tiene descripción correcta")
    func invalidTitleLengthHasCorrectDescription() {
        let error = UploadMaterialError.invalidTitleLength(actual: 2)
        #expect(error.errorDescription?.contains("3") == true)
        #expect(error.errorDescription?.contains("200") == true)
        #expect(error.errorDescription?.contains("2") == true)
    }

    @Test("unsupportedFileType tiene descripción correcta")
    func unsupportedFileTypeHasCorrectDescription() {
        let error = UploadMaterialError.unsupportedFileType(mimeType: "text/plain")
        #expect(error.errorDescription?.contains("text/plain") == true)
        #expect(error.errorDescription?.contains("PDF") == true)
    }

    @Test("fileTooLarge muestra tamaño en MB")
    func fileTooLargeShowsSizeInMB() {
        let error = UploadMaterialError.fileTooLarge(
            sizeBytes: 60 * 1024 * 1024,
            maxBytes: 50 * 1024 * 1024
        )
        #expect(error.errorDescription?.contains("60") == true)
        #expect(error.errorDescription?.contains("50") == true)
        #expect(error.errorDescription?.contains("MB") == true)
    }

    @Test("fileNotFound incluye path")
    func fileNotFoundIncludesPath() {
        let error = UploadMaterialError.fileNotFound(path: "/tmp/missing.pdf")
        #expect(error.errorDescription?.contains("/tmp/missing.pdf") == true)
    }

    @Test("processingTimeout incluye materialId")
    func processingTimeoutIncludesMaterialId() {
        let materialId = UUID()
        let error = UploadMaterialError.processingTimeout(materialId: materialId)
        #expect(error.errorDescription?.contains(materialId.uuidString) == true)
    }
}

// MARK: - UploadMaterialUseCase Tests

@Suite("UploadMaterialUseCase Tests")
struct UploadMaterialUseCaseTests {

    // MARK: - Validation Tests

    @Test("execute con título muy corto lanza invalidTitleLength")
    func executeWithShortTitleThrowsError() async {
        let uploadRepo = MockMaterialUploadRepository()
        let fileValidator = MockFileValidator()
        let useCase = UploadMaterialUseCase(
            uploadRepository: uploadRepo,
            fileValidator: fileValidator
        )

        let input = UploadMaterialInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            title: "AB",  // Solo 2 caracteres
            subjectId: UUID(),
            unitId: UUID()
        )

        await #expect(throws: UploadMaterialError.self) {
            try await useCase.execute(input: input)
        }
    }

    @Test("execute con título muy largo lanza invalidTitleLength")
    func executeWithLongTitleThrowsError() async {
        let uploadRepo = MockMaterialUploadRepository()
        let fileValidator = MockFileValidator()
        let useCase = UploadMaterialUseCase(
            uploadRepository: uploadRepo,
            fileValidator: fileValidator
        )

        let longTitle = String(repeating: "A", count: 201)
        let input = UploadMaterialInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            title: longTitle,
            subjectId: UUID(),
            unitId: UUID()
        )

        await #expect(throws: UploadMaterialError.self) {
            try await useCase.execute(input: input)
        }
    }

    @Test("execute con archivo inexistente lanza fileNotFound")
    func executeWithMissingFileThrowsError() async {
        let uploadRepo = MockMaterialUploadRepository()
        var fileValidator = MockFileValidator()
        fileValidator.fileExistsResult = false

        let useCase = UploadMaterialUseCase(
            uploadRepository: uploadRepo,
            fileValidator: fileValidator
        )

        let input = UploadMaterialInput(
            fileURL: URL(fileURLWithPath: "/tmp/missing.pdf"),
            title: "Test Material",
            subjectId: UUID(),
            unitId: UUID()
        )

        await #expect(throws: UploadMaterialError.self) {
            try await useCase.execute(input: input)
        }
    }

    @Test("execute con tipo MIME inválido lanza unsupportedFileType")
    func executeWithInvalidMimeTypeThrowsError() async {
        let uploadRepo = MockMaterialUploadRepository()
        var fileValidator = MockFileValidator()
        fileValidator.mimeTypeResult = "image/jpeg"

        let useCase = UploadMaterialUseCase(
            uploadRepository: uploadRepo,
            fileValidator: fileValidator
        )

        let input = UploadMaterialInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            title: "Test Material",
            subjectId: UUID(),
            unitId: UUID()
        )

        await #expect(throws: UploadMaterialError.self) {
            try await useCase.execute(input: input)
        }
    }

    @Test("execute con archivo demasiado grande lanza fileTooLarge")
    func executeWithLargeFileThrowsError() async {
        let uploadRepo = MockMaterialUploadRepository()
        var fileValidator = MockFileValidator()
        fileValidator.fileSizeResult = 60 * 1024 * 1024  // 60MB

        let useCase = UploadMaterialUseCase(
            uploadRepository: uploadRepo,
            fileValidator: fileValidator
        )

        let input = UploadMaterialInput(
            fileURL: URL(fileURLWithPath: "/tmp/large.pdf"),
            title: "Test Material",
            subjectId: UUID(),
            unitId: UUID()
        )

        await #expect(throws: UploadMaterialError.self) {
            try await useCase.execute(input: input)
        }
    }

    // MARK: - Success Flow Tests

    @Test("execute completa flujo exitosamente")
    func executeCompletesSuccessfully() async throws {
        let uploadRepo = MockMaterialUploadRepository()
        let fileValidator = MockFileValidator()
        let useCase = UploadMaterialUseCase(
            uploadRepository: uploadRepo,
            fileValidator: fileValidator,
            pollingTimeout: 5
        )

        let input = UploadMaterialInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            title: "Test Material",
            subjectId: UUID(),
            unitId: UUID()
        )

        let material = try await useCase.execute(input: input)

        #expect(material.title == "Test Material")
        #expect(material.status == .ready)

        // Verificar que se llamaron todos los pasos
        let createCalls = await uploadRepo.createCallCount
        let uploadURLCalls = await uploadRepo.uploadURLCallCount
        let s3UploadCalls = await uploadRepo.s3UploadCallCount
        let notifyCompleteCalls = await uploadRepo.notifyCompleteCallCount
        let getMaterialCalls = await uploadRepo.getMaterialCallCount

        #expect(createCalls == 1)
        #expect(uploadURLCalls == 1)
        #expect(s3UploadCalls == 1)
        #expect(notifyCompleteCalls == 1)
        #expect(getMaterialCalls >= 1)
    }

    @Test("execute con descripción la pasa al repositorio")
    func executePassesDescriptionToRepository() async throws {
        let uploadRepo = MockMaterialUploadRepository()
        let fileValidator = MockFileValidator()
        let useCase = UploadMaterialUseCase(
            uploadRepository: uploadRepo,
            fileValidator: fileValidator,
            pollingTimeout: 5
        )

        let input = UploadMaterialInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            title: "Test Material",
            subjectId: UUID(),
            unitId: UUID(),
            description: "Test description"
        )

        let material = try await useCase.execute(input: input)

        #expect(material.description == "Test description")
    }

    // MARK: - Error Handling Tests

    @Test("execute cuando createMaterial falla lanza materialCreationFailed")
    func executeWhenCreateFailsThrowsError() async {
        let uploadRepo = MockMaterialUploadRepository()
        await uploadRepo.setShouldFailCreate(true)
        let fileValidator = MockFileValidator()

        let useCase = UploadMaterialUseCase(
            uploadRepository: uploadRepo,
            fileValidator: fileValidator
        )

        let input = UploadMaterialInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            title: "Test Material",
            subjectId: UUID(),
            unitId: UUID()
        )

        await #expect(throws: UploadMaterialError.self) {
            try await useCase.execute(input: input)
        }
    }

    @Test("execute cuando requestUploadURL falla lanza uploadURLFailed y hace cleanup")
    func executeWhenUploadURLFailsDoesCleanup() async {
        let uploadRepo = MockMaterialUploadRepository()
        await uploadRepo.setShouldFailUploadURL(true)
        let fileValidator = MockFileValidator()

        let useCase = UploadMaterialUseCase(
            uploadRepository: uploadRepo,
            fileValidator: fileValidator
        )

        let input = UploadMaterialInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            title: "Test Material",
            subjectId: UUID(),
            unitId: UUID()
        )

        await #expect(throws: UploadMaterialError.self) {
            try await useCase.execute(input: input)
        }

        // Verificar que se intentó hacer cleanup
        let deleteCalls = await uploadRepo.deleteCallCount
        #expect(deleteCalls == 1)
    }

    @Test("execute cuando S3 upload falla lanza s3UploadFailed y hace cleanup")
    func executeWhenS3UploadFailsDoesCleanup() async {
        let uploadRepo = MockMaterialUploadRepository()
        await uploadRepo.setShouldFailS3Upload(true)
        let fileValidator = MockFileValidator()

        let useCase = UploadMaterialUseCase(
            uploadRepository: uploadRepo,
            fileValidator: fileValidator
        )

        let input = UploadMaterialInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            title: "Test Material",
            subjectId: UUID(),
            unitId: UUID()
        )

        await #expect(throws: UploadMaterialError.self) {
            try await useCase.execute(input: input)
        }

        // Verificar que se intentó hacer cleanup
        let deleteCalls = await uploadRepo.deleteCallCount
        #expect(deleteCalls == 1)
    }

    @Test("execute cuando notifyComplete falla lanza uploadCompleteFailed")
    func executeWhenNotifyCompleteFailsThrowsError() async {
        let uploadRepo = MockMaterialUploadRepository()
        await uploadRepo.setShouldFailNotifyComplete(true)
        let fileValidator = MockFileValidator()

        let useCase = UploadMaterialUseCase(
            uploadRepository: uploadRepo,
            fileValidator: fileValidator
        )

        let input = UploadMaterialInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            title: "Test Material",
            subjectId: UUID(),
            unitId: UUID()
        )

        await #expect(throws: UploadMaterialError.self) {
            try await useCase.execute(input: input)
        }
    }

    // MARK: - Polling Tests

    @Test("execute espera hasta que el material esté ready")
    func executeWaitsUntilMaterialIsReady() async throws {
        let uploadRepo = MockMaterialUploadRepository()
        let fileValidator = MockFileValidator()
        let useCase = UploadMaterialUseCase(
            uploadRepository: uploadRepo,
            fileValidator: fileValidator,
            pollingTimeout: 10
        )

        let input = UploadMaterialInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            title: "Test Material",
            subjectId: UUID(),
            unitId: UUID()
        )

        let material = try await useCase.execute(input: input)

        #expect(material.status == .ready)

        // Verificar que hubo múltiples llamadas de polling
        let getMaterialCalls = await uploadRepo.getMaterialCallCount
        #expect(getMaterialCalls >= 2)
    }

    // MARK: - Constants Tests

    @Test("constantes de configuración tienen valores esperados")
    func configurationConstantsHaveExpectedValues() {
        #expect(UploadMaterialUseCase.maxFileSizeBytes == 50 * 1024 * 1024)
        #expect(UploadMaterialUseCase.minTitleLength == 3)
        #expect(UploadMaterialUseCase.maxTitleLength == 200)
        #expect(UploadMaterialUseCase.allowedMimeTypes.contains("application/pdf"))
        #expect(UploadMaterialUseCase.defaultPollingTimeout == 30)
        #expect(UploadMaterialUseCase.pollingInterval == 1)
        #expect(UploadMaterialUseCase.maxS3Retries == 1)
    }
}

// MARK: - DefaultFileValidator Tests

@Suite("DefaultFileValidator Tests")
struct DefaultFileValidatorTests {

    @Test("mimeType retorna application/pdf para archivos .pdf")
    func mimeTypeReturnsCorrectForPDF() throws {
        let validator = DefaultFileValidator()
        let mimeType = try validator.mimeType(at: URL(fileURLWithPath: "/tmp/test.pdf"))
        #expect(mimeType == "application/pdf")
    }

    @Test("mimeType retorna application/octet-stream para extensiones desconocidas")
    func mimeTypeReturnsOctetStreamForUnknown() throws {
        let validator = DefaultFileValidator()
        let mimeType = try validator.mimeType(at: URL(fileURLWithPath: "/tmp/test.xyz"))
        #expect(mimeType == "application/octet-stream")
    }
}

// MARK: - MockMaterialUploadRepository Helper Extensions

extension MockMaterialUploadRepository {
    func setShouldFailCreate(_ value: Bool) {
        shouldFailCreate = value
    }

    func setShouldFailUploadURL(_ value: Bool) {
        shouldFailUploadURL = value
    }

    func setShouldFailS3Upload(_ value: Bool) {
        shouldFailS3Upload = value
    }

    func setShouldFailNotifyComplete(_ value: Bool) {
        shouldFailNotifyComplete = value
    }

    func setShouldFailGetMaterial(_ value: Bool) {
        shouldFailGetMaterial = value
    }

    func setShouldFailDelete(_ value: Bool) {
        shouldFailDelete = value
    }
}
