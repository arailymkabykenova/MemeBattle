import Foundation
import os

// MARK: - Health Response
struct HealthResponse: Codable {
    let status: String
    let timestamp: String?
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case validationError
    case rateLimited
    case serverError
    case conflict
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
            return "Необходима авторизация"
        case .forbidden:
            return "Доступ запрещен"
        case .notFound:
            return "Ресурс не найден"
        case .validationError:
            return "Ошибка валидации данных"
        case .rateLimited:
            return "Слишком много запросов"
        case .serverError:
            return "Ошибка сервера"
        case .conflict:
            return "Конфликт данных"
        case .unknown:
            return "Неизвестная ошибка"
        case .apiError(let message):
            return message
        }
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - NetworkManager Protocol
protocol NetworkManagerProtocol {
    func makeRequest<T: Codable>(endpoint: String, method: HTTPMethod, body: Data?) async throws -> T
    func makeRequestWithCodable<T: Codable>(endpoint: String, method: HTTPMethod, body: Codable) async throws -> T
    func makeJSONRequest(endpoint: String, method: HTTPMethod, body: Data?) async throws -> [String: Any]
    func checkServerHealth() async throws -> Bool
}

// MARK: - NetworkManager
class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let logger = Logger(subsystem: "com.memegame.app", category: "network")
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        config.timeoutIntervalForResource = APIConfig.requestTimeout * 2
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    func makeRequest<T: Codable>(endpoint: String, method: HTTPMethod = .GET, body: Data? = nil) async throws -> T {
        guard let url = URL(string: APIConfig.baseURL + endpoint) else {
            logger.error("Invalid URL: \(APIConfig.baseURL + endpoint)")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = APIConfig.requestTimeout
        
        // Добавляем заголовки
        for (key, value) in APIConfig.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Добавляем токен авторизации, если есть
        if let token = KeychainManager.shared.retrieve(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Добавляем тело запроса
        if let body = body {
            request.httpBody = body
        }
        
        // Логируем запрос
        if APIConfig.enableNetworkLogging {
            logger.debug("🌐 \(method.rawValue) \(endpoint)")
            logger.debug("URL: \(url)")
            logger.debug("Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let body = body, let bodyString = String(data: body, encoding: .utf8) {
                logger.debug("Body: \(bodyString)")
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Логируем ответ
            if APIConfig.enableNetworkLogging {
                if let httpResponse = response as? HTTPURLResponse {
                    logger.debug("📥 Response: \(httpResponse.statusCode)")
                    logger.debug("Response Headers: \(httpResponse.allHeaderFields)")
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    logger.debug("Response Body: \(responseString)")
                }
            }
            
            // Проверяем HTTP статус код
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                throw NetworkError.invalidResponse
            }
            
            // Обрабатываем ошибки HTTP
            switch httpResponse.statusCode {
            case 200...299:
                // Успешный ответ
                break
            case 400:
                logger.error("Bad Request: \(String(data: data, encoding: .utf8) ?? "")")
                throw NetworkError.badRequest
            case 401:
                logger.error("Unauthorized")
                throw NetworkError.unauthorized
            case 403:
                logger.error("Forbidden")
                throw NetworkError.forbidden
            case 404:
                logger.error("Not Found")
                throw NetworkError.notFound
            case 409:
                logger.error("Conflict")
                throw NetworkError.conflict
            case 422:
                logger.error("Validation Error: \(String(data: data, encoding: .utf8) ?? "")")
                throw NetworkError.validationError
            case 429:
                logger.error("Rate Limited")
                throw NetworkError.rateLimited
            case 500...599:
                logger.error("Server Error: \(httpResponse.statusCode)")
                throw NetworkError.serverError
            default:
                logger.error("Unknown HTTP status: \(httpResponse.statusCode)")
                throw NetworkError.unknown
            }
            
            // Декодируем ответ
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                
                let result = try decoder.decode(T.self, from: data)
                return result
            } catch {
                logger.error("JSON Decoding Error: \(error)")
                logger.error("Response Data: \(String(data: data, encoding: .utf8) ?? "")")
                throw NetworkError.invalidResponse
            }
            
        } catch {
            if let networkError = error as? NetworkError {
                throw networkError
            } else {
                logger.error("Network Error: \(error.localizedDescription)")
                throw NetworkError.unknown
            }
        }
    }
    
    func checkServerHealth() async throws -> Bool {
        do {
            let _: HealthResponse = try await makeRequest(endpoint: "/health", method: .GET)
            return true
        } catch {
            logger.error("Server health check failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func makeRequestWithCodable<T: Codable>(endpoint: String, method: HTTPMethod, body: Codable) async throws -> T {
        let jsonData = try JSONEncoder().encode(body)
        return try await makeRequest(endpoint: endpoint, method: method, body: jsonData)
    }
    
    func makeJSONRequest(endpoint: String, method: HTTPMethod = .GET, body: Data? = nil) async throws -> [String: Any] {
        guard let url = URL(string: APIConfig.baseURL + endpoint) else {
            logger.error("Invalid URL: \(APIConfig.baseURL + endpoint)")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = APIConfig.requestTimeout
        
        // Добавляем заголовки
        for (key, value) in APIConfig.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Добавляем токен авторизации, если есть
        if let token = KeychainManager.shared.retrieve(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Добавляем тело запроса
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Проверяем HTTP статус код
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                throw NetworkError.invalidResponse
            }
            
            // Обрабатываем ошибки HTTP
            switch httpResponse.statusCode {
            case 200...299:
                // Успешный ответ
                break
            case 400:
                logger.error("Bad Request: \(String(data: data, encoding: .utf8) ?? "")")
                throw NetworkError.badRequest
            case 401:
                logger.error("Unauthorized")
                throw NetworkError.unauthorized
            case 403:
                logger.error("Forbidden")
                throw NetworkError.forbidden
            case 404:
                logger.error("Not Found")
                throw NetworkError.notFound
            case 409:
                logger.error("Conflict")
                throw NetworkError.conflict
            case 422:
                logger.error("Validation Error: \(String(data: data, encoding: .utf8) ?? "")")
                throw NetworkError.validationError
            case 429:
                logger.error("Rate Limited")
                throw NetworkError.rateLimited
            case 500...599:
                logger.error("Server Error: \(httpResponse.statusCode)")
                throw NetworkError.serverError
            default:
                logger.error("Unknown HTTP status: \(httpResponse.statusCode)")
                throw NetworkError.unknown
            }
            
            // Парсим JSON
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw NetworkError.invalidResponse
                }
                return json
            } catch {
                logger.error("JSON Parsing Error: \(error)")
                logger.error("Response Data: \(String(data: data, encoding: .utf8) ?? "")")
                throw NetworkError.invalidResponse
            }
            
        } catch {
            if let networkError = error as? NetworkError {
                throw networkError
            } else {
                logger.error("Network Error: \(error.localizedDescription)")
                throw NetworkError.unknown
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    func get<T: Codable>(endpoint: String) async throws -> T {
        return try await makeRequest(endpoint: endpoint, method: .GET)
    }
    
    func post<T: Codable>(endpoint: String, body: Data) async throws -> T {
        return try await makeRequest(endpoint: endpoint, method: .POST, body: body)
    }
    
    func put<T: Codable>(endpoint: String, body: Data) async throws -> T {
        return try await makeRequest(endpoint: endpoint, method: .PUT, body: body)
    }
    
    func delete<T: Codable>(endpoint: String) async throws -> T {
        return try await makeRequest(endpoint: endpoint, method: .DELETE)
    }
    
    func patch<T: Codable>(endpoint: String, body: Data) async throws -> T {
        return try await makeRequest(endpoint: endpoint, method: .PATCH, body: body)
    }
}

// MARK: - Extensions
extension NetworkManager {
    // Метод для работы с JSON объектами
    func makeRequestWithJSON<T: Codable>(endpoint: String, method: HTTPMethod, body: [String: Any]) async throws -> T {
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        return try await makeRequest(endpoint: endpoint, method: method, body: jsonData)
    }
} 