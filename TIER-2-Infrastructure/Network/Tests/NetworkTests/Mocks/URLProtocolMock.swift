import Foundation
@testable import Network

/// Mock de URLProtocol para interceptar requests HTTP en tests de integración.
///
/// Permite configurar respuestas predefinidas a nivel de URLSession,
/// útil para tests que necesitan verificar el comportamiento real del cliente.
///
/// ## Ejemplo de uso
/// ```swift
/// // Configurar respuesta
/// URLProtocolMock.mockResponse = (
///     data: jsonData,
///     response: HTTPURLResponse(url: url, statusCode: 200, ...),
///     error: nil
/// )
///
/// // Configurar URLSession con el mock
/// let config = URLSessionConfiguration.ephemeral
/// config.protocolClasses = [URLProtocolMock.self]
/// let session = URLSession(configuration: config)
/// ```
final class URLProtocolMock: URLProtocol, @unchecked Sendable {
    // MARK: - Static Configuration

    /// Handler para procesar requests y retornar respuestas.
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (Data, HTTPURLResponse))?

    /// Respuesta mock estática para todas las requests.
    nonisolated(unsafe) static var mockResponse: (data: Data?, response: HTTPURLResponse?, error: Error?)?

    /// Historial de requests interceptadas.
    nonisolated(unsafe) static var requestHistory: [URLRequest] = []

    /// Delay artificial para simular latencia de red.
    nonisolated(unsafe) static var artificialDelay: TimeInterval = 0

    // MARK: - URLProtocol Override

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.requestHistory.append(request)

        if Self.artificialDelay > 0 {
            Thread.sleep(forTimeInterval: Self.artificialDelay)
        }

        // Usar handler personalizado si está configurado
        if let handler = Self.requestHandler {
            do {
                let (data, response) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
            return
        }

        // Usar respuesta estática
        if let mockResponse = Self.mockResponse {
            if let error = mockResponse.error {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }

            if let response = mockResponse.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let data = mockResponse.data {
                client?.urlProtocol(self, didLoad: data)
            }

            client?.urlProtocolDidFinishLoading(self)
            return
        }

        // Sin configuración, retornar error
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorUnknown,
            userInfo: [NSLocalizedDescriptionKey: "URLProtocolMock not configured"]
        )
        client?.urlProtocol(self, didFailWithError: error)
    }

    override func stopLoading() {
        // No-op
    }

    // MARK: - Configuration Helpers

    /// Resetea toda la configuración del mock.
    static func reset() {
        requestHandler = nil
        mockResponse = nil
        requestHistory.removeAll()
        artificialDelay = 0
    }

    /// Configura una respuesta JSON exitosa.
    static func setJSONResponse<T: Encodable>(
        _ object: T,
        statusCode: Int = 200,
        url: URL = URL(string: "https://api.test.com")!
    ) throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(object)
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        mockResponse = (data: data, response: response, error: nil)
    }

    /// Configura un error de red.
    static func setNetworkError(_ code: URLError.Code = .notConnectedToInternet) {
        let error = URLError(code)
        mockResponse = (data: nil, response: nil, error: error)
    }

    /// Configura una respuesta HTTP con código de error.
    static func setHTTPError(
        statusCode: Int,
        message: String? = nil,
        url: URL = URL(string: "https://api.test.com")!
    ) {
        var data: Data?
        if let message {
            data = "{\"error\": \"\(message)\"}".data(using: .utf8)
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        mockResponse = (data: data, response: response, error: nil)
    }

    /// Crea una URLSession configurada con este mock.
    static func createMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        return URLSession(configuration: config)
    }
}

// MARK: - Verification Helpers

extension URLProtocolMock {
    /// Verifica que se realizó al menos una request.
    static var wasRequested: Bool {
        !requestHistory.isEmpty
    }

    /// Obtiene la última request realizada.
    static var lastRequest: URLRequest? {
        requestHistory.last
    }

    /// Verifica que se llamó con una URL específica.
    static func wasRequestedWith(url: String) -> Bool {
        requestHistory.contains { $0.url?.absoluteString.contains(url) == true }
    }

    /// Verifica que se llamó con un método HTTP específico.
    static func wasRequestedWith(method: String) -> Bool {
        requestHistory.contains { $0.httpMethod == method }
    }

    /// Número total de requests interceptadas.
    static var requestCount: Int {
        requestHistory.count
    }
}
