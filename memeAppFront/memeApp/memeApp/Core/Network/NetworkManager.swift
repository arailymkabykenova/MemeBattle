import Foundation
import os

// MARK: - API Error Response
struct APIErrorResponse: Codable {
    let detail: String
    let code: String?
}

protocol NetworkManagerProtocol {
    func makeRequest<T: Codable>(endpoint: String, method: HTTPMethod, body: Data?) async throws -> T
    func makeRequest<T: Codable>(endpoint: String, method: HTTPMethod) async throws -> T
    func makeRequest<T: Codable, U: Codable>(endpoint: String, method: HTTPMethod, body: T) async throws -> U
    func makeRequest<T>(endpoint: String, method: HTTPMethod, body: Data?) async throws -> T where T == [String: Any]
    func makeRequest<T>(endpoint: String, method: HTTPMethod) async throws -> T where T == [String: Any]
    func checkServerHealth() async throws -> Bool
}

class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let logger = Logger(subsystem: "com.memegame.app", category: "network")
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        logger.debug("NetworkManager initialized with base URL: \(APIConfig.baseURL)")
    }
    
    func checkServerHealth() async throws -> Bool {
        logger.debug("Checking server health...")
        
        do {
            let response: [String: String] = try await makeRequest(
                endpoint: APIConfig.Endpoints.health,
                method: .GET
            )
            logger.debug("Server health check successful: \(response)")
            return true
        } catch {
            logger.error("Server health check failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func makeRequest<T: Codable>(endpoint: String, method: HTTPMethod, body: Data? = nil) async throws -> T {
        return try await performRequest(endpoint: endpoint, method: method, body: body)
    }
    
    func makeRequest<T: Codable>(endpoint: String, method: HTTPMethod) async throws -> T {
        return try await makeRequest(endpoint: endpoint, method: method, body: nil)
    }
    
    func makeRequest<T: Codable, U: Codable>(endpoint: String, method: HTTPMethod, body: T) async throws -> U {
        let bodyData = try JSONEncoder().encode(body)
        return try await makeRequest(endpoint: endpoint, method: method, body: bodyData)
    }
    
    func makeRequest<T>(endpoint: String, method: HTTPMethod, body: Data? = nil) async throws -> T where T == [String: Any] {
        return try await performRequestForDictionary(endpoint: endpoint, method: method, body: body)
    }
    
    func makeRequest<T>(endpoint: String, method: HTTPMethod) async throws -> T where T == [String: Any] {
        return try await makeRequest(endpoint: endpoint, method: method, body: nil)
    }
}

// MARK: - Private Methods
extension NetworkManager {
    private func performRequest<T: Codable>(endpoint: String, method: HTTPMethod, body: Data?) async throws -> T {
        let request = try createRequest(endpoint: endpoint, method: method, body: body)
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response: response, data: data)
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            logger.error("Failed to decode response: \(error.localizedDescription)")
            throw NetworkError.invalidResponse
        }
    }
    
    private func performRequestForDictionary<T>(endpoint: String, method: HTTPMethod, body: Data?) async throws -> T where T == [String: Any] {
        let request = try createRequest(endpoint: endpoint, method: method, body: body)
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response: response, data: data)
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NetworkError.invalidResponse
            }
            return json
        } catch {
            logger.error("Failed to parse JSON response: \(error.localizedDescription)")
            throw NetworkError.invalidResponse
        }
    }
    
    private func createRequest(endpoint: String, method: HTTPMethod, body: Data?) throws -> URLRequest {
        guard let url = URL(string: APIConfig.baseURL + endpoint) else {
            logger.error("Invalid URL: \(APIConfig.baseURL + endpoint)")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(APIConfig.Headers.contentTypeValue, forHTTPHeaderField: APIConfig.Headers.contentType)
        request.setValue(APIConfig.Headers.userAgentValue, forHTTPHeaderField: APIConfig.Headers.userAgent)
        request.setValue(APIConfig.Headers.acceptLanguageValue, forHTTPHeaderField: APIConfig.Headers.acceptLanguage)
        
        // Add authorization header if token exists
        if let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: APIConfig.Headers.authorization)
            logger.debug("Added authorization header")
        } else {
            logger.debug("No auth token found, skipping authorization header")
        }
        
        if let body = body {
            request.httpBody = body
            logger.debug("Request body size: \(body.count) bytes")
        }
        
        logger.debug("Making request: \(method.rawValue) \(endpoint)")
        
        return request
    }
            
    private func validateResponse(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response")
            throw NetworkError.invalidResponse
        }
        
        logger.debug("Response status: \(httpResponse.statusCode)")
        
        // Log response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            logger.debug("Response data: \(responseString)")
        } else {
            logger.debug("Response data: unable to decode as UTF-8")
        }
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 400:
            logger.error("Bad request (400)")
            // Попробуем получить детальное сообщение об ошибке
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw NetworkError.apiError(errorResponse.detail)
            } else {
                throw NetworkError.badRequest
            }
        case 401:
            logger.error("Unauthorized (401)")
            throw NetworkError.unauthorized
        case 403:
            logger.error("Forbidden (403)")
            throw NetworkError.forbidden
        case 404:
            logger.error("Not found (404)")
            throw NetworkError.notFound
        case 409:
            logger.error("Conflict (409)")
            throw NetworkError.conflict
        case 422:
            logger.error("Validation error (422)")
            throw NetworkError.validationError
        case 429:
            logger.error("Rate limited (429)")
            throw NetworkError.rateLimited
        case 500...599:
            logger.error("Server error (\(httpResponse.statusCode))")
            throw NetworkError.serverError
        default:
            logger.error("Unknown status code: \(httpResponse.statusCode)")
            throw NetworkError.unknown
        }
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case validationError
    case rateLimited
    case serverError
    case unknown
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .badRequest:
            return "Неверный запрос"
        case .unauthorized:
            return "Не авторизован"
        case .forbidden:
            return "Доступ запрещен"
        case .notFound:
            return "Ресурс не найден"
        case .conflict:
            return "Конфликт"
        case .validationError:
            return "Ошибка валидации"
        case .rateLimited:
            return "Слишком много запросов"
        case .serverError:
            return "Ошибка сервера"
        case .unknown:
            return "Неизвестная ошибка"
        case .apiError(let message):
            return message
        }
    }
} 