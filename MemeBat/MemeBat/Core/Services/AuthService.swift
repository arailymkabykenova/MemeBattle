import Foundation
import GameKit
import os

// MARK: - Authentication Errors
enum AuthError: LocalizedError {
    case gameCenterNotAvailable
    case gameCenterAuthenticationFailed
    case invalidPlayerData
    case serverAuthenticationFailed
    case tokenExpired
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .gameCenterNotAvailable:
            return "Game Center недоступен"
        case .gameCenterAuthenticationFailed:
            return "Ошибка аутентификации Game Center"
        case .invalidPlayerData:
            return "Неверные данные игрока"
        case .serverAuthenticationFailed:
            return "Ошибка аутентификации на сервере"
        case .tokenExpired:
            return "Токен истек"
        case .networkError:
            return "Ошибка сети"
        }
    }
}

// MARK: - Game Center Auth Request
struct GameCenterAuthRequest: Codable {
    let player_id: String
    let public_key_url: String
    let signature: String
    let salt: String
    let timestamp: String
}

// MARK: - Auth Response
struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let user: User
}

// MARK: - Auth Service Protocol
protocol AuthServiceProtocol {
    func authenticateWithGameCenter() async throws -> User
    func refreshToken() async throws -> String
    func logout()
    var currentUser: User? { get }
}

// MARK: - Auth Service
class AuthService: AuthServiceProtocol {
    private let networkManager: NetworkManagerProtocol
    private let logger = Logger(subsystem: "com.memegame.app", category: "auth")
    
    @Published private(set) var currentUser: User?
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    // MARK: - Public Methods
    func authenticateWithGameCenter() async throws -> User {
        logger.debug("Starting Game Center authentication")
        
        // Check if Game Center is available
        guard GKLocalPlayer.local.isAuthenticated else {
            logger.error("Game Center not authenticated")
            throw AuthError.gameCenterNotAvailable
        }
        
        let localPlayer = GKLocalPlayer.local
        
        // Get Game Center authentication data
        let authData = try await getGameCenterAuthData(for: localPlayer)
        
        // Send authentication request to server
        let authResponse = try await authenticateWithServer(authData: authData)
        
        // Save token and user data
        KeychainManager.shared.saveAuthToken(authResponse.access_token)
        currentUser = authResponse.user
        
        logger.debug("Authentication successful for user: \(authResponse.user.nickname)")
        
        return authResponse.user
    }
    
    func refreshToken() async throws -> String {
        logger.debug("Refreshing authentication token")
        
        guard let currentUser = currentUser else {
            throw AuthError.tokenExpired
        }
        
        // Re-authenticate with Game Center
        let user = try await authenticateWithGameCenter()
        return KeychainManager.shared.getAuthToken() ?? ""
    }
    
    func logout() {
        logger.debug("Logging out user")
        
        KeychainManager.shared.deleteAuthToken()
        currentUser = nil
        
        // Disconnect WebSocket if connected
        WebSocketManager.shared.disconnect()
    }
    
    // MARK: - Private Methods
    private func getGameCenterAuthData(for player: GKLocalPlayer) async throws -> GameCenterAuthRequest {
        logger.debug("Getting Game Center auth data for player: \(player.gamePlayerID)")
        
        // Get player's public key URL
        guard let publicKeyURL = player.publicKeyURL?.absoluteString else {
            logger.error("Failed to get public key URL")
            throw AuthError.invalidPlayerData
        }
        
        // Generate signature data
        let playerID = player.gamePlayerID
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let salt = UUID().uuidString
        
        let signatureData = "\(playerID).\(bundleID).\(timestamp).\(salt)"
        
        // Get signature from Game Center
        let signature = try await player.generateIdentityVerificationSignature(
            withCompletionHandler: { signature, publicKeyURL, salt, timestamp, error in
                if let error = error {
                    self.logger.error("Game Center signature generation failed: \(error.localizedDescription)")
                }
            }
        )
        
        guard let signature = signature else {
            logger.error("Failed to generate Game Center signature")
            throw AuthError.gameCenterAuthenticationFailed
        }
        
        return GameCenterAuthRequest(
            player_id: playerID,
            public_key_url: publicKeyURL,
            signature: signature.base64EncodedString(),
            salt: salt,
            timestamp: timestamp
        )
    }
    
    private func authenticateWithServer(authData: GameCenterAuthRequest) async throws -> AuthResponse {
        logger.debug("Authenticating with server")
        
        do {
            let encoder = JSONEncoder()
            let body = try encoder.encode(authData)
            
            let response: AuthResponse = try await networkManager.makeRequest(
                endpoint: APIConfig.Endpoints.gameCenterAuth,
                method: .POST,
                body: body
            )
            
            logger.debug("Server authentication successful")
            return response
            
        } catch {
            logger.error("Server authentication failed: \(error.localizedDescription)")
            throw AuthError.serverAuthenticationFailed
        }
    }
}

// MARK: - Game Center Extensions
extension GKLocalPlayer {
    func generateIdentityVerificationSignature(
        withCompletionHandler completionHandler: @escaping (Data?, URL?, String?, UInt64, Error?) -> Void
    ) async throws -> Data? {
        return try await withCheckedThrowingContinuation { continuation in
            self.generateIdentityVerificationSignature { signature, publicKeyURL, salt, timestamp, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: signature)
                }
            }
        }
    }
} 