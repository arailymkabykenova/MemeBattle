import Foundation
import UIKit
import os

// MARK: - Auth Models
struct DeviceAuthRequest: Codable {
    let device_id: String
}

// MARK: - Auth Errors
enum AuthError: Error, LocalizedError {
    case deviceIdGenerationFailed
    case networkError
    case serverError
    case invalidResponse
    case tokenExpired
    
    var errorDescription: String? {
        switch self {
        case .deviceIdGenerationFailed:
            return "Не удалось создать идентификатор устройства"
        case .networkError:
            return "Ошибка сети"
        case .serverError:
            return "Ошибка сервера"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .tokenExpired:
            return "Токен истёк"
        }
    }
}

// MARK: - AuthService
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private let networkManager = NetworkManager.shared
    private let keychainManager = KeychainManager.shared
    private let logger = Logger(subsystem: "com.memegame.app", category: "auth")
    
    private init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Public Methods
    
    func authenticateWithDeviceId() async throws -> AuthResponse {
        logger.debug("Starting device authentication")
        isLoading = true
        
        defer { isLoading = false }
        
        do {
            // 1. Получаем device_id
            let deviceId = try getDeviceId()
            logger.debug("Device ID: \(deviceId)")
        
            // 2. Создаем запрос
            let authRequest = DeviceAuthRequest(device_id: deviceId)
            logger.debug("Auth request created for device: \(deviceId)")
        
            // 3. Отправляем запрос
            let endpoint = "\(APIConfig.Endpoints.auth)/device"
            let requestBody = try JSONEncoder().encode(authRequest)
            
            logger.debug("Sending auth request to: \(endpoint)")
            logger.debug("Full URL: \(APIConfig.baseURL + endpoint)")
            logger.debug("Request body: \(String(data: requestBody, encoding: .utf8) ?? "nil")")
            
            let authResponse: AuthResponse = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .POST,
                body: requestBody
            )
        
            logger.debug("Authentication successful - user ID: \(authResponse.user.id)")
            logger.debug("Is new user: \(authResponse.is_new_user)")
            logger.debug("User profile complete: \(authResponse.user.isProfileComplete)")
            
            // 4. Сохраняем токен
            try keychainManager.save(authResponse.access_token, forKey: "auth_token")
            logger.debug("Auth token saved to keychain")
            
            // 5. Обновляем состояние
            currentUser = authResponse.user
            isAuthenticated = true
            
            return authResponse
            
        } catch {
            logger.error("Authentication failed: \(error.localizedDescription)")
            logger.error("Error type: \(type(of: error))")
            
            if let networkError = error as? NetworkError {
                logger.error("Network error type: \(String(describing: networkError))")
                switch networkError {
                case .invalidURL, .invalidResponse, .badRequest, .unauthorized, .forbidden, .notFound, .validationError, .rateLimited, .unknown, .conflict:
                    throw AuthError.networkError
                case .serverError:
                    throw AuthError.serverError
                case .apiError(let message):
                    logger.error("API error: \(message)")
                    throw AuthError.networkError
                }
            } else {
                logger.error("Unknown error type: \(type(of: error))")
                logger.error("Error details: \(error)")
                throw AuthError.networkError
            }
        }
    }
    
    func logout() async {
        logger.debug("Logging out")
        
        do {
            // 1. Отправляем запрос на сервер
            let _: [String: Any] = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.auth)/logout",
                method: .POST
            )
        } catch {
            logger.error("Logout request failed: \(error.localizedDescription)")
        }
        
        // 2. Очищаем локальные данные
        keychainManager.delete(forKey: "auth_token")
        keychainManager.delete(forKey: "device_id")
        
        // 3. Обновляем состояние
        currentUser = nil
        isAuthenticated = false
        
        logger.debug("Logout completed")
    }
    
    func checkAuthenticationStatus() {
        // Проверяем наличие токена
        if let token = keychainManager.retrieve(forKey: "auth_token"), !token.isEmpty {
            isAuthenticated = true
            logger.debug("Found existing auth token")
        } else {
            isAuthenticated = false
            logger.debug("No auth token found")
        }
    }
    
    // MARK: - Private Methods
    
    private func getDeviceId() throws -> String {
        // Сначала проверяем, есть ли сохранённый device_id
        if let savedDeviceId = keychainManager.retrieve(forKey: "device_id"), !savedDeviceId.isEmpty {
            return savedDeviceId
    }
    
        // Генерируем новый device_id
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        // Сохраняем в Keychain
        do {
            try keychainManager.save(deviceId, forKey: "device_id")
            return deviceId
        } catch {
            logger.error("Failed to save device_id: \(error.localizedDescription)")
            throw AuthError.deviceIdGenerationFailed
        }
    }
} 