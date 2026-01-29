import Foundation
#if canImport(os)
import os
#endif

/// Cliente de red con soporte para interceptors y retry automático.
///
/// Extiende las capacidades de `NetworkClient` agregando:
/// - Chain of interceptors para modificar requests/responses
/// - Retry automático con políticas configurables
/// - Logging integrado con interceptors
///
/// ## Uso básico
/// ```swift
/// let client = InterceptableNetworkClient(
///     interceptors: [
///         LoggingInterceptor.debug,
///         AuthenticationInterceptor(tokenProvider: myTokenProvider),
///         RetryInterceptor(policy: .standard)
///     ]
/// )
///
/// let users: [User] = try await client.request(
///     HTTPRequest.get("https://api.example.com/users")
/// )
/// ```
public actor InterceptableNetworkClient: NetworkClientProtocol {

    // MARK: - Properties

    /// Sesión URL para realizar requests.
    private let urlSession: URLSession

    /// Decoder JSON configurado.
    private let jsonDecoder: JSONDecoder

    /// Encoder JSON configurado.
    private let jsonEncoder: JSONEncoder

    /// Headers globales aplicados a todas las requests.
    private var globalHeaders: [String: String] = [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ]

    /// Cadena de interceptors.
    private let interceptorChain: InterceptorChain

    /// Política de retry por defecto.
    private let defaultRetryPolicy: (any RetryPolicy)?

    /// Timeout máximo para reintentos.
    private let maxRetryTimeout: TimeInterval

    #if canImport(os)
    private let logger = Logger(subsystem: "com.edugo.network", category: "InterceptableNetworkClient")
    #endif

    // MARK: - Initialization

    /// Inicializa el cliente con interceptors.
    /// - Parameters:
    ///   - interceptors: Array de interceptors a aplicar
    ///   - defaultRetryPolicy: Política de retry por defecto (nil = sin retry automático)
    ///   - maxRetryTimeout: Timeout máximo total para reintentos (default: 120s)
    ///   - configuration: Configuración de URLSession (default: .default)
    ///   - decoder: Decoder JSON (default: configurado para snake_case)
    ///   - encoder: Encoder JSON (default: configurado para snake_case)
    public init(
        interceptors: [any RequestInterceptor] = [],
        defaultRetryPolicy: (any RetryPolicy)? = nil,
        maxRetryTimeout: TimeInterval = 120,
        configuration: URLSessionConfiguration = .default,
        decoder: JSONDecoder? = nil,
        encoder: JSONEncoder? = nil
    ) {
        self.interceptorChain = InterceptorChain(interceptors)
        self.defaultRetryPolicy = defaultRetryPolicy
        self.maxRetryTimeout = maxRetryTimeout

        // Configurar URLSession
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.httpAdditionalHeaders = [
            "User-Agent": "EduGo-iOS/1.0"
        ]
        self.urlSession = URLSession(configuration: configuration)

        // Configurar decoder
        if let decoder {
            self.jsonDecoder = decoder
        } else {
            self.jsonDecoder = JSONDecoder()
            self.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            self.jsonDecoder.dateDecodingStrategy = .iso8601
        }

        // Configurar encoder
        if let encoder {
            self.jsonEncoder = encoder
        } else {
            self.jsonEncoder = JSONEncoder()
            self.jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
            self.jsonEncoder.dateEncodingStrategy = .iso8601
        }
    }

    /// Inicializa con configuración estándar incluyendo logging y retry.
    public static func standard(
        tokenProvider: (any TokenProvider)? = nil,
        retryPolicy: any RetryPolicy = ExponentialBackoffRetryPolicy.standard
    ) -> InterceptableNetworkClient {
        var interceptors: [any RequestInterceptor] = [
            LoggingInterceptor(level: .info)
        ]

        if let tokenProvider {
            interceptors.append(AuthenticationInterceptor.standard(tokenProvider: tokenProvider))
        }

        interceptors.append(RetryInterceptor(policy: retryPolicy))

        return InterceptableNetworkClient(
            interceptors: interceptors,
            defaultRetryPolicy: retryPolicy
        )
    }

    // MARK: - Header Management

    /// Establece un header global.
    public func setGlobalHeader(_ value: String, forKey key: String) {
        globalHeaders[key] = value
    }

    /// Remueve un header global.
    public func removeGlobalHeader(forKey key: String) {
        globalHeaders.removeValue(forKey: key)
    }

    /// Establece el token de autorización Bearer.
    public func setAuthorizationToken(_ token: String) {
        globalHeaders["Authorization"] = "Bearer \(token)"
    }

    /// Remueve el token de autorización.
    public func clearAuthorizationToken() {
        globalHeaders.removeValue(forKey: "Authorization")
    }

    // MARK: - NetworkClientProtocol Implementation

    public func request<T: Decodable & Sendable>(
        _ request: HTTPRequest
    ) async throws -> T {
        let (data, _) = try await requestData(request)

        if T.self == EmptyResponse.self {
            // swiftlint:disable:next force_cast
            return EmptyResponse() as! T
        }

        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decodingError(
                type: String(describing: T.self),
                underlyingError: describeDecodingError(error)
            )
        }
    }

    public func requestData(
        _ request: HTTPRequest
    ) async throws -> (Data, HTTPURLResponse) {
        let startTime = Date()
        var context = RequestContext(originalRequest: request)

        // Construir URLRequest inicial
        var urlRequest = try buildURLRequest(from: request)

        // Loop de retry
        while true {
            do {
                // Aplicar interceptors (adapt)
                urlRequest = try await interceptorChain.adapt(urlRequest, context: context)

                // Ejecutar request
                let (data, response) = try await executeRequest(urlRequest)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.networkFailure(underlyingError: "Invalid response type")
                }

                // Validar respuesta
                try validateResponse(httpResponse, data: data)

                // Notificar interceptors del éxito
                await interceptorChain.didReceive(
                    response: httpResponse,
                    data: data,
                    for: urlRequest,
                    context: context
                )

                return (data, httpResponse)

            } catch let error as NetworkError {
                // Verificar timeout global
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed >= maxRetryTimeout {
                    throw error
                }

                // Consultar interceptors para retry
                let decision = await interceptorChain.retry(
                    urlRequest,
                    dueTo: error,
                    context: context
                )

                switch decision {
                case .doNotRetry:
                    throw error

                case .retryImmediately:
                    context = context.nextAttempt(elapsedTime: elapsed)
                    continue

                case .retryAfter(let delay):
                    try await Task.sleep(for: .seconds(delay))
                    context = context.nextAttempt(elapsedTime: Date().timeIntervalSince(startTime))
                    continue

                case .retryWithRequest(let newRequest):
                    urlRequest = newRequest
                    context = context.nextAttempt(elapsedTime: elapsed)
                    continue
                }
            }
        }
    }

    public func upload<T: Decodable & Sendable>(
        data: Data,
        request: HTTPRequest
    ) async throws -> T {
        var urlRequest = try buildURLRequest(from: request)
        urlRequest.httpBody = data

        let context = RequestContext(originalRequest: request)
        urlRequest = try await interceptorChain.adapt(urlRequest, context: context)

        let (responseData, response) = try await urlSession.upload(for: urlRequest, from: data)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.networkFailure(underlyingError: "Invalid response type")
        }

        try validateResponse(httpResponse, data: responseData)

        await interceptorChain.didReceive(
            response: httpResponse,
            data: responseData,
            for: urlRequest,
            context: context
        )

        return try jsonDecoder.decode(T.self, from: responseData)
    }

    public func upload<T: Decodable & Sendable>(
        fileURL: URL,
        request: HTTPRequest
    ) async throws -> T {
        var urlRequest = try buildURLRequest(from: request)

        let context = RequestContext(originalRequest: request)
        urlRequest = try await interceptorChain.adapt(urlRequest, context: context)

        let (responseData, response) = try await urlSession.upload(for: urlRequest, fromFile: fileURL)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.networkFailure(underlyingError: "Invalid response type")
        }

        try validateResponse(httpResponse, data: responseData)

        return try jsonDecoder.decode(T.self, from: responseData)
    }

    public func download(_ request: HTTPRequest) async throws -> URL {
        var urlRequest = try buildURLRequest(from: request)

        let context = RequestContext(originalRequest: request)
        urlRequest = try await interceptorChain.adapt(urlRequest, context: context)

        let (fileURL, response) = try await urlSession.download(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.networkFailure(underlyingError: "Invalid response type")
        }

        try validateResponse(httpResponse, data: nil)

        return fileURL
    }

    public func downloadData(_ request: HTTPRequest) async throws -> Data {
        let (data, _) = try await requestData(request)
        return data
    }

    // MARK: - Private Helpers

    private func executeRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await urlSession.data(for: request)
        } catch let error as URLError {
            throw NetworkError.from(urlError: error)
        } catch {
            throw NetworkError.networkFailure(underlyingError: error.localizedDescription)
        }
    }

    private func buildURLRequest(from request: HTTPRequest) throws -> URLRequest {
        var urlRequest = try request.build()

        for (key, value) in globalHeaders {
            if urlRequest.value(forHTTPHeaderField: key) == nil {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        return urlRequest
    }

    private func validateResponse(_ response: HTTPURLResponse, data: Data?) throws {
        let statusCode = response.statusCode

        guard NetworkError.isSuccessStatusCode(statusCode) else {
            var serverMessage: String?
            if let data {
                serverMessage = extractErrorMessage(from: data)
            }

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

    private func extractErrorMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            let message: String?
            let error: String?
        }

        guard let errorResponse = try? jsonDecoder.decode(ErrorResponse.self, from: data) else {
            return nil
        }

        return errorResponse.message ?? errorResponse.error
    }

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
}

// MARK: - Builder Pattern

/// Builder para crear InterceptableNetworkClient de forma fluida.
public final class NetworkClientBuilder: @unchecked Sendable {
    private var interceptors: [any RequestInterceptor] = []
    private var retryPolicy: (any RetryPolicy)?
    private var maxRetryTimeout: TimeInterval = 120
    private var configuration: URLSessionConfiguration = .default
    private var decoder: JSONDecoder?
    private var encoder: JSONEncoder?

    public init() {}

    /// Agrega un interceptor.
    @discardableResult
    public func addInterceptor(_ interceptor: any RequestInterceptor) -> Self {
        interceptors.append(interceptor)
        return self
    }

    /// Agrega logging con nivel especificado.
    @discardableResult
    public func withLogging(level: LogLevel = .info) -> Self {
        interceptors.append(LoggingInterceptor(level: level))
        return self
    }

    /// Agrega autenticación con el token provider especificado.
    @discardableResult
    public func withAuthentication(tokenProvider: any TokenProvider) -> Self {
        interceptors.append(AuthenticationInterceptor.standard(tokenProvider: tokenProvider))
        return self
    }

    /// Agrega retry con la política especificada.
    @discardableResult
    public func withRetry(policy: any RetryPolicy = ExponentialBackoffRetryPolicy.standard) -> Self {
        interceptors.append(RetryInterceptor(policy: policy))
        self.retryPolicy = policy
        return self
    }

    /// Establece el timeout máximo para reintentos.
    @discardableResult
    public func maxRetryTimeout(_ timeout: TimeInterval) -> Self {
        self.maxRetryTimeout = timeout
        return self
    }

    /// Establece la configuración de URLSession.
    @discardableResult
    public func configuration(_ config: URLSessionConfiguration) -> Self {
        self.configuration = config
        return self
    }

    /// Establece el decoder JSON.
    @discardableResult
    public func decoder(_ decoder: JSONDecoder) -> Self {
        self.decoder = decoder
        return self
    }

    /// Establece el encoder JSON.
    @discardableResult
    public func encoder(_ encoder: JSONEncoder) -> Self {
        self.encoder = encoder
        return self
    }

    /// Construye el cliente.
    public func build() -> InterceptableNetworkClient {
        InterceptableNetworkClient(
            interceptors: interceptors,
            defaultRetryPolicy: retryPolicy,
            maxRetryTimeout: maxRetryTimeout,
            configuration: configuration,
            decoder: decoder,
            encoder: encoder
        )
    }
}

// MARK: - Convenience Extensions

extension InterceptableNetworkClient {
    /// Crea un builder para configurar el cliente.
    public static func builder() -> NetworkClientBuilder {
        NetworkClientBuilder()
    }
}
