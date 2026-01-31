import Foundation

/// Helper para crear archivos de prueba con magic numbers correctos
enum FileTestHelper {

    /// Crea un archivo PDF de prueba válido con magic numbers correctos
    static func createValidPDF(name: String = "test-\(UUID().uuidString).pdf") throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(name)

        // PDF mínimo válido con magic numbers correctos (%PDF)
        let pdfContent = """
        %PDF-1.4
        1 0 obj
        <<
        /Type /Catalog
        /Pages 2 0 R
        >>
        endobj
        2 0 obj
        <<
        /Type /Pages
        /Kids [3 0 R]
        /Count 1
        >>
        endobj
        3 0 obj
        <<
        /Type /Page
        /Parent 2 0 R
        /MediaBox [0 0 612 792]
        >>
        endobj
        xref
        0 4
        0000000000 65535 f
        0000000009 00000 n
        0000000058 00000 n
        0000000115 00000 n
        trailer
        <<
        /Size 4
        /Root 1 0 R
        >>
        startxref
        190
        %%EOF
        """

        try pdfContent.data(using: .utf8)!.write(to: fileURL)
        return fileURL
    }

    /// Crea un archivo DOCX de prueba válido (ZIP con magic number PK)
    static func createValidDOCX(name: String = "test-\(UUID().uuidString).docx") throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(name)

        // DOCX es un ZIP, crear estructura mínima válida
        var zipData = Data()

        // ZIP local file header signature (PK\x03\x04)
        zipData.append(contentsOf: [0x50, 0x4B, 0x03, 0x04])
        zipData.append(contentsOf: [0x14, 0x00]) // Version needed to extract
        zipData.append(contentsOf: [0x00, 0x00]) // General purpose bit flag
        zipData.append(contentsOf: [0x00, 0x00]) // Compression method
        zipData.append(contentsOf: [0x00, 0x00]) // File modification time
        zipData.append(contentsOf: [0x00, 0x00]) // File modification date
        zipData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // CRC-32
        zipData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Compressed size
        zipData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Uncompressed size
        zipData.append(contentsOf: [0x05, 0x00]) // File name length
        zipData.append(contentsOf: [0x00, 0x00]) // Extra field length
        zipData.append(contentsOf: "word/".utf8) // File name

        // Central directory file header
        zipData.append(contentsOf: [0x50, 0x4B, 0x01, 0x02])
        zipData.append(contentsOf: [0x14, 0x00, 0x14, 0x00])
        zipData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        zipData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        zipData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        zipData.append(contentsOf: [0x05, 0x00, 0x00, 0x00])
        zipData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        zipData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        zipData.append(contentsOf: "word/".utf8)

        // End of central directory
        zipData.append(contentsOf: [0x50, 0x4B, 0x05, 0x06])
        zipData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        zipData.append(contentsOf: [0x01, 0x00, 0x01, 0x00])
        zipData.append(contentsOf: [0x2F, 0x00, 0x00, 0x00])
        zipData.append(contentsOf: [0x1E, 0x00, 0x00, 0x00])
        zipData.append(contentsOf: [0x00, 0x00])

        try zipData.write(to: fileURL)
        return fileURL
    }

    /// Crea un archivo PPTX de prueba válido (mismo formato que DOCX)
    static func createValidPPTX(name: String = "test-\(UUID().uuidString).pptx") throws -> URL {
        return try createValidDOCX(name: name)
    }

    /// Crea un archivo MP4 de prueba válido con magic number ftyp
    static func createValidMP4(name: String = "test-\(UUID().uuidString).mp4") throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(name)

        // MP4 mínimo válido con ftyp box
        var mp4Data = Data()

        mp4Data.append(contentsOf: [0x00, 0x00, 0x00, 0x20]) // ftyp box size
        mp4Data.append(contentsOf: [0x66, 0x74, 0x79, 0x70]) // ftyp signature
        mp4Data.append(contentsOf: "isom".utf8) // Major brand
        mp4Data.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Minor version
        mp4Data.append(contentsOf: "isommp42".utf8) // Compatible brands
        mp4Data.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])

        try mp4Data.write(to: fileURL)
        return fileURL
    }

    /// Crea un archivo de tamaño específico con magic numbers correctos
    static func createFileWithSize(
        extension ext: String,
        sizeInBytes: Int,
        name: String? = nil
    ) throws -> URL {
        let fileName = name ?? "test-size-\(UUID().uuidString).\(ext)"

        let baseURL: URL
        switch ext {
        case "pdf":
            baseURL = try createValidPDF(name: fileName)
        case "docx":
            baseURL = try createValidDOCX(name: fileName)
        case "pptx":
            baseURL = try createValidPPTX(name: fileName)
        case "mp4":
            baseURL = try createValidMP4(name: fileName)
        default:
            throw NSError(domain: "FileTestHelper", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Unsupported extension: \(ext)"])
        }

        let currentSize = try FileManager.default.attributesOfItem(atPath: baseURL.path)[.size] as! Int

        if sizeInBytes > currentSize {
            let handle = try FileHandle(forWritingTo: baseURL)
            defer { try? handle.close() }
            try handle.truncate(atOffset: UInt64(sizeInBytes))
        }

        return baseURL
    }

    /// Limpia un archivo temporal
    static func cleanup(_ fileURL: URL) {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
