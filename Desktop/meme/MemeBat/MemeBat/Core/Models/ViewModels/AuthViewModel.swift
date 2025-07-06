import Foundation
import Combine
import GameKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
        self.user = authService.currentUser
        self.isAuthenticated = self.user != nil
    }
    
    func authenticate() async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await authService.authenticateWithGameCenter()
            self.user = user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAuthenticated = false
        }
        isLoading = false
    }
    
    func logout() {
        authService.logout()
        self.user = nil
        self.isAuthenticated = false
    }
} 