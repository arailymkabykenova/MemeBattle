import SwiftUI
import os

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var authState: AuthState = .idle
    @Published var errorMessage: String = ""
    @Published var currentUser: User?
    @Published var profileCompleted: Bool = false
    
    private let authService = AuthService.shared
    private let logger = Logger(subsystem: "com.memegame.app", category: "auth")
    
    enum AuthState: String, CaseIterable {
        case idle = "Ожидание"
        case loading = "Загрузка"
        case authenticated = "Аутентифицирован"
        case needsProfile = "Требует профиль"
        case error = "Ошибка"
    }
    
    func authenticateWithDeviceId() async {
        logger.debug("Starting device authentication")
        authState = .loading
        errorMessage = ""
        
        do {
            let authResponse = try await authService.authenticateWithDeviceId()
            
            logger.debug("Auth response received - profile_completed: \(authResponse.profile_completed)")
            logger.debug("User profile complete: \(authResponse.user.isProfileComplete)")
            
            currentUser = authResponse.user
            profileCompleted = authResponse.profile_completed
            
            // Проверяем, нужно ли создавать профиль
            if !authResponse.profile_completed || !authResponse.user.isProfileComplete {
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
    
    func completeProfile(nickname: String, birthDate: String, gender: String) async {
        logger.debug("Completing profile")
        authState = .loading
        errorMessage = ""
        
        do {
            let updatedUser = try await authService.completeProfile(
                nickname: nickname,
                birthDate: birthDate,
                gender: gender
            )
            
            logger.debug("Profile completed successfully")
            
            currentUser = updatedUser
            profileCompleted = true
            authState = .authenticated
            
        } catch {
            logger.error("Profile completion failed: \(error.localizedDescription)")
            
            if let authError = error as? AuthError {
                errorMessage = authError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            
            authState = .error
        }
    }
    
    func updateProfile(nickname: String, birthDate: String, gender: String) async {
        logger.debug("Updating profile")
        authState = .loading
        errorMessage = ""
        
        do {
            let updatedUser = try await authService.updateProfile(
                nickname: nickname,
                birthDate: birthDate,
                gender: gender
            )
            
            logger.debug("Profile updated successfully")
            
            currentUser = updatedUser
            profileCompleted = true
            authState = .authenticated
            
        } catch {
            logger.error("Profile update failed: \(error.localizedDescription)")
            
            if let authError = error as? AuthError {
                errorMessage = authError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            
            authState = .error
        }
    }
    
    func getCurrentUser() async {
        logger.debug("Fetching current user")
        
        do {
            let user = try await authService.getCurrentUser()
            
            currentUser = user
            profileCompleted = user.isProfileComplete
            
            if user.isProfileComplete {
                authState = .authenticated
            } else {
                authState = .needsProfile
            }
            
        } catch {
            logger.error("Failed to fetch current user: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            authState = .error
        }
    }
    
    func logout() async {
        logger.debug("Logging out")
        await authService.logout()
        
        // Сбрасываем состояние
        currentUser = nil
        profileCompleted = false
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

 