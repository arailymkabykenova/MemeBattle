import SwiftUI
import os

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var authState: AuthState = .idle
    @Published var errorMessage: String = ""
    @Published var currentUser: User?
    @Published var isNewUser: Bool = false
    
    private let authService = AuthService.shared
    private let logger = Logger(subsystem: "com.memegame.app", category: "auth")
    
    enum AuthState {
        case idle
        case loading
        case authenticated
        case needsProfile
        case error
    }
    
    func authenticateWithDeviceId() async {
        logger.debug("Starting device authentication")
        authState = .loading
        errorMessage = ""
        
        do {
            let authResponse = try await authService.authenticateWithDeviceId()
            
            logger.debug("Auth response received - is_new_user: \(authResponse.is_new_user)")
            logger.debug("User profile complete: \(authResponse.user.isProfileComplete)")
            
            currentUser = authResponse.user
            isNewUser = authResponse.is_new_user
            
            // Проверяем, нужно ли создавать профиль
            if authResponse.is_new_user || !authResponse.user.isProfileComplete {
                logger.debug("Setting state to needsProfile")
                authState = .needsProfile
            } else {
                logger.debug("Setting state to authenticated")
                authState = .authenticated
            }
            
        } catch {
            logger.error("Authentication failed: \(error.localizedDescription)")
            logger.error("Error type: \(type(of: error))")
            logger.error("Error details: \(error)")
            
            if let authError = error as? AuthError {
                logger.error("Auth error type: \(String(describing: authError))")
                errorMessage = authError.localizedDescription
            } else if let networkError = error as? NetworkError {
                logger.error("Network error type: \(String(describing: networkError))")
                errorMessage = networkError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            
            authState = .error
        }
    }
    
    func logout() async {
        logger.debug("Logging out")
        await authService.logout()
        
        // Сбрасываем состояние
        currentUser = nil
        isNewUser = false
        authState = .idle
        errorMessage = ""
    }
    
    func checkAuthenticationStatus() {
        // Безопасно: не сбрасываем состояние, если уже не idle
        if authState == .idle {
            logger.debug("Authentication status check - starting from idle state")
        }
    }
}

 