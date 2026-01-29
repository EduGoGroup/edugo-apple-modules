import Foundation
#if canImport(os)
import os
#endif

/// Network - HTTP networking module
///
/// Provides HTTP client, request/response handling, and network utilities.
/// TIER-2 Infrastructure module.
///
/// ## Overview
/// `NetworkClient` es un actor thread-safe que proporciona funcionalidades
/// de networking usando `URLSession` con soporte completo para async/await.
///
/// ## Uso básico
/// ```swift
/// let client = NetworkClient.shared
///
/// // Request GET simple
/// let users: [User] = try await client.request(
///     HTTPRequest.get("https://api.example.com/users")
/// )
///
/// // Request POST con body
/// let newUser: User = try await client.request(
///     try HTTPRequest.post("https://api.example.com/users")
///         .body(CreateUserRequest(name: "John"))
/// )
/// ```
///
/// ## Thread Safety
/// Como actor de Swift 6.2, todas las operaciones son automáticamente
/// thread-safe sin necesidad de locks o dispatch queues.
public actor NetworkClient: NetworkClientProtocol {

    // MARK: - Singleton

    /// Instancia compartida del cliente de red.
    public static let shared = NetworkClient()

    // MARK: - Properties

    /// Sesión URL para realizar requests.
    private let urlSession: URLSession

    /// Decoder JSON configurado para la aplicación.
    private let jsonDecoder: JSONDecoder

    /// Encoder JSON configurado para la aplicación.
    private let jsonEncoder: JSONEncoder

    /// Headers globales aplicados a todas las requests.
    private var globalHeaders: [String: String] = [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ]

    #if canImport(os)
    /// Logger para debugging.
    private let logger = Logger(subsystem: "com.edugo.network", category: "NetworkClient")
    #endif

    #if DEBUG
    /// Flag para habilitar logging detallado.
    public var isLoggingEnabled: Bool = true
    #else
    public let isLoggingEnabled: Bool = false
    #endif

    // MARK: - Initialization

    /// Inicializa el cliente con la configuración por defecto.
    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.httpAdditionalHeaders = [
            "User-Agent": "EduGo-iOS/1.0"
        ]

        self.urlSession = URLSession(configuration: configuration)

        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        self.jsonDecoder.dateDecodingStrategy = .iso8601

        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        self.jsonEncoder.dateEncodingStrategy = .iso8601
    }

    /// Inicializa el cliente con una configuración personalizada.
    /// - Parameters:
    ///   - configuration: Configuración de URLSession
    ///   - decoder: Decoder JSON personalizado
    ///   - encoder: Encoder JSON personalizado
    public init(
        configuration: URLSessionConfiguration,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.urlSession = URLSession(configuration: configuration)
        self.jsonDecoder = decoder
        self.jsonEncoder = encoder
    }

    // MARK: - Header Management

    /// Establece un header global que se aplicará a todas las requests.
    /// - Parameters:
    ///   - value: Valor del header
    ///   - key: Nombre del header
    public func setGlobalHeader(_ value: String, forKey key: String) {
        globalHeaders[key] = value
    }

    /// Remueve un header global.
    /// - Parameter key: Nombre del header a remover
    public func removeGlobalHeader(forKey key: String) {
        globalHeaders.removeValue(forKey: key)
    }

    /// Establece el token de autorización Bearer.
    /// - Parameter token: Token de autorización
    public func setAuthorizationToken(_ token: String) {
        globalHeaders["Authorization"] = "Bearer \(token)"
    }

    /// Remueve el token de autorización.
    public func clearAuthorizationToken() {
        globalHeaders.removeValue(forKey: "Authorization")
    }

    // MARK: - NetworkClientProtocol Implementation

    /// Ejecuta una request HTTP y decodifica la respuesta.
    /// - Parameter request: Configuración de la request
    /// - Returns: Respuesta decodificada del tipo especificado
    /// - Throws: `NetworkError` si la request falla
    public func request<T: Decodable & Sendable>(
        _ request: HTTPRequest
    ) async throws -> T {
        let (data, _) = try await requestData(request)

        // Manejar respuesta vacía para EmptyResponse
        if T.self == EmptyResponse.self {
            // swiftlint:disable:next force_cast
            return EmptyResponse() as! T
        }

        do {
            let decoded = try jsonDecoder.decode(T.self, from: data)
            return decoded
        } catch let decodingError as DecodingError {
            let errorDescription = describeDecodingError(decodingError)
            logError("Decoding error for \(T.self): \(errorDescription)")
            throw NetworkError.decodingError(
                type: String(describing: T.self),
                underlyingError: errorDescription
            )
        }
    }

    /// Ejecuta una request HTTP y retorna los datos crudos.
    /// - Parameter request: Configuración de la request
    /// - Returns: Tupla con los datos y la respuesta HTTP
    /// - Throws: `NetworkError` si la request falla
    public func requestData(
        _ request: HTTPRequest
    ) async throws -> (Data, HTTPURLResponse) {
        let urlRequest = try buildURLRequest(from: request)

        logRequest(urlRequest)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await urlSession.data(for: urlRequest)
        } catch let error as URLError {
            logError("URL error: \(error.localizedDescription)")
            throw NetworkError.from(urlError: error)
        } catch {
            logError("Unknown error: \(error.localizedDescription)")
            throw NetworkError.networkFailure(underlyingError: error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.networkFailure(underlyingError: "Invalid response type")
        }

        logResponse(httpResponse, data: data)

        try validateResponse(httpResponse, data: data)

        return (data, httpResponse)
    }

    /// Sube datos al servidor.
    /// - Parameters:
    ///   - data: Datos a subir
    ///   - request: Configuración de la request
    /// - Returns: Respuesta decodificada
    /// - Throws: `NetworkError` si la subida falla
    public func upload<T: Decodable & Sendable>(
        data: Data,
        request: HTTPRequest
    ) async throws -> T {
        var urlRequest = try buildURLRequest(from: request)
        urlRequest.httpBody = data

        logRequest(urlRequest)

        let responseData: Data
        let response: URLResponse

        do {
            (responseData, response) = try await urlSession.upload(for: urlRequest, from: data)
        } catch let error as URLError {
            throw NetworkError.from(urlError: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.networkFailure(underlyingError: "Invalid response type")
        }

        logResponse(httpResponse, data: responseData)
        try validateResponse(httpResponse, data: responseData)

        return try jsonDecoder.decode(T.self, from: responseData)
    }

    /// Sube un archivo al servidor.
    /// - Parameters:
    ///   - fileURL: URL local del archivo
    ///   - request: Configuración de la request
    /// - Returns: Respuesta decodificada
    /// - Throws: `NetworkError` si la subida falla
    public func upload<T: Decodable & Sendable>(
        fileURL: URL,
        request: HTTPRequest
    ) async throws -> T {
        let urlRequest = try buildURLRequest(from: request)

        logRequest(urlRequest)

        let responseData: Data
        let response: URLResponse

        do {
            (responseData, response) = try await urlSession.upload(for: urlRequest, fromFile: fileURL)
        } catch let error as URLError {
            throw NetworkError.from(urlError: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.networkFailure(underlyingError: "Invalid response type")
        }

        logResponse(httpResponse, data: responseData)
        try validateResponse(httpResponse, data: responseData)

        return try jsonDecoder.decode(T.self, from: responseData)
    }

    /// Descarga un archivo del servidor.
    /// - Parameter request: Configuración de la request
    /// - Returns: URL del archivo descargado
    /// - Throws: `NetworkError` si la descarga falla
    public func download(_ request: HTTPRequest) async throws -> URL {
        let urlRequest = try buildURLRequest(from: request)

        logRequest(urlRequest)

        let fileURL: URL
        let response: URLResponse

        do {
            (fileURL, response) = try await urlSession.download(for: urlRequest)
        } catch let error as URLError {
            throw NetworkError.from(urlError: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.networkFailure(underlyingError: "Invalid response type")
        }

        logResponse(httpResponse, data: nil)
        try validateResponse(httpResponse, data: nil)

        return fileURL
    }

    /// Descarga datos del servidor.
    /// - Parameter request: Configuración de la request
    /// - Returns: Datos descargados
    /// - Throws: `NetworkError` si la descarga falla
    public func downloadData(_ request: HTTPRequest) async throws -> Data {
        let (data, _) = try await requestData(request)
        return data
    }

    // MARK: - Legacy Support

    /// Ejecuta una request simple por URL (compatibilidad hacia atrás).
    /// - Parameters:
    ///   - url: URL de la request
    ///   - method: Método HTTP
    /// - Returns: Respuesta decodificada
    /// - Throws: Error si la request falla
    public func request<T: Decodable & Sendable>(
        _ url: URL,
        method: HTTPMethod = .get
    ) async throws -> T {
        let httpRequest = HTTPRequest(url: url.absoluteString).method(method)
        return try await request(httpRequest)
    }

    // MARK: - Private Helpers

    /// Construye un URLRequest a partir de HTTPRequest aplicando headers globales.
    private func buildURLRequest(from request: HTTPRequest) throws -> URLRequest {
        var urlRequest = try request.build()

        // Aplicar headers globales (los headers específicos tienen prioridad)
        for (key, value) in globalHeaders {
            if urlRequest.value(forHTTPHeaderField: key) == nil {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        return urlRequest
    }

    /// Valida la respuesta HTTP y lanza error si es necesario.
    private func validateResponse(_ response: HTTPURLResponse, data: Data?) throws {
        let statusCode = response.statusCode

        guard NetworkError.isSuccessStatusCode(statusCode) else {
            // Intentar extraer mensaje de error del servidor
            var serverMessage: String?
            if let data {
                serverMessage = extractErrorMessage(from: data)
            }

            // Extraer Retry-After para rate limiting
            var retryAfter: TimeInterval?
            if statusCode == 429,
               let retryAfterString = response.value(forHTTPHeaderField: "Retry-After"),
               let seconds = TimeInterval(retryAfterString) {
                retryAfter = seconds
            }

            throw NetworkError.from(
                statusCode: statusCode,
                message: serverMessage,
                retryAfter: retryAfter
            )
        }
    }

    /// Extrae el mensaje de error del body de la respuesta.
    private func extractErrorMessage(from data: Data) -> String? {
        // Intentar decodificar como JSON con campo "message" o "error"
        struct ErrorResponse: Decodable {
            let message: String?
            let error: String?
        }

        guard let errorResponse = try? jsonDecoder.decode(ErrorResponse.self, from: data) else {
            return nil
        }

        return errorResponse.message ?? errorResponse.error
    }

    /// Describe un error de decodificación de forma legible.
    private func describeDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .typeMismatch(let type, let context):
            return "Type mismatch for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        case .valueNotFound(let type, let context):
            return "Value not found for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        case .keyNotFound(let key, let context):
            return "Key '\(key.stringValue)' not found at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        case .dataCorrupted(let context):
            return "Data corrupted at \(context.codingPath.map(\.stringValue).joined(separator: ".")): \(context.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }

    // MARK: - Logging

    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        guard isLoggingEnabled else { return }

        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown"

        #if canImport(os)
        logger.debug("→ \(method) \(url)")
        #else
        print("→ \(method) \(url)")
        #endif
        #endif
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data?) {
        #if DEBUG
        guard isLoggingEnabled else { return }

        let statusCode = response.statusCode
        let url = response.url?.absoluteString ?? "unknown"
        let dataSize = data?.count ?? 0

        #if canImport(os)
        logger.debug("← \(statusCode) \(url) (\(dataSize) bytes)")
        #else
        print("← \(statusCode) \(url) (\(dataSize) bytes)")
        #endif
        #endif
    }

    private func logError(_ message: String) {
        #if DEBUG
        guard isLoggingEnabled else { return }

        #if canImport(os)
        logger.error("✗ \(message)")
        #else
        print("✗ \(message)")
        #endif
        #endif
    }
}
