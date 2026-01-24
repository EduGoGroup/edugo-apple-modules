import Foundation

/// Network - HTTP networking module
///
/// Provides HTTP client, request/response handling, and network utilities.
/// TIER-2 Infrastructure module.
public actor NetworkClient: Sendable {
    public static let shared = NetworkClient()

    private let urlSession: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        self.urlSession = URLSession(configuration: configuration)
    }

    /// Perform a network request
    public func request<T: Decodable>(
        _ url: URL,
        method: HTTPMethod = .get
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

/// HTTP methods
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
