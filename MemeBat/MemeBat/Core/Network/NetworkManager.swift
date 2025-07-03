import Foundation
import os

// MARK: - Network Manager Protocol
protocol NetworkManagerProtocol {
    func makeRequest<T: Codable>(endpoint: String, method: HTTPMethod, body: Data?) async throws -> T
    func makeRequest<T: Codable>(endpoint: String, method: HTTPMethod) async throws -> T
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case unauthorized
    case forbidden
    case notFound
    case tooManyRequests
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .noData:
            return "Нет данных"
        case .decodingError:
            return "Ошибка декодирования"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .unauthorized:
            return "Не авторизован"
        case .forbidden:
            return "Доступ запрещен"
        case .notFound:
            return "Не найдено"
        case .tooManyRequests:
            return "Слишком много запросов"
        case .unknown:
            return "Неизвестная ошибка"
        }
    }
}

// MARK: - Network Manager
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
    }
    
    // MARK: - Public Methods
    func makeRequest<T: Codable>(endpoint: String, method: HTTPMethod, body: Data?) async throws -> T {
        guard let url = URL(string: APIConfig.baseURL + endpoint) else {
            logger.error("Invalid URL: \(endpoint)")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(APIConfig.Headers.contentTypeValue, forHTTPHeaderField: APIConfig.Headers.contentType)
        request.setValue(APIConfig.Headers.userAgentValue, forHTTPHeaderField: APIConfig.Headers.userAgent)
        request.setValue(APIConfig.Headers.acceptLanguageValue, forHTTPHeaderField: APIConfig.Headers.acceptLanguage)
        
        // Add authorization header if token exists
        if let token = KeychainManager.shared.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: APIConfig.Headers.authorization)
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        logger.debug("Making request: \(method.rawValue) \(endpoint)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                throw NetworkError.unknown
            }
            
            logger.debug("Response status: \(httpResponse.statusCode)")
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case APIConfig.StatusCodes.ok, APIConfig.StatusCodes.created:
                return try decodeResponse(data: data)
            case APIConfig.StatusCodes.unauthorized:
                logger.error("Unauthorized request")
                throw NetworkError.unauthorized
            case APIConfig.StatusCodes.forbidden:
                logger.error("Forbidden request")
                throw NetworkError.forbidden
            case APIConfig.StatusCodes.notFound:
                logger.error("Resource not found")
                throw NetworkError.notFound
            case APIConfig.StatusCodes.tooManyRequests:
                logger.error("Too many requests")
                throw NetworkError.tooManyRequests
            case APIConfig.StatusCodes.badRequest, APIConfig.StatusCodes.unprocessableEntity:
                logger.error("Bad request: \(String(data: data, encoding: .utf8) ?? "")")
                throw NetworkError.serverError(httpResponse.statusCode)
            case APIConfig.StatusCodes.internalServerError...599:
                logger.error("Server error: \(httpResponse.statusCode)")
                throw NetworkError.serverError(httpResponse.statusCode)
            default:
                logger.error("Unexpected status code: \(httpResponse.statusCode)")
                throw NetworkError.unknown
            }
        } catch {
            logger.error("Network request failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func makeRequest<T: Codable>(endpoint: String, method: HTTPMethod) async throws -> T {
        return try await makeRequest(endpoint: endpoint, method: method, body: nil)
    }
    
    // MARK: - Private Methods
    private func decodeResponse<T: Codable>(data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("Decoding error: \(error.localizedDescription)")
            logger.error("Response data: \(String(data: data, encoding: .utf8) ?? "")")
            throw NetworkError.decodingError
        }
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.memegame.app"
    private let account = "auth_token"
    
    private init() {}
    
    func saveAuthToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getAuthToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    func deleteAuthToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
} 