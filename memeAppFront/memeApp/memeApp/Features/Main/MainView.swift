import SwiftUI

struct MainView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .idle:
                AuthenticationView(viewModel: authViewModel)
            case .loading:
                AuthenticationView(viewModel: authViewModel)
            case .needsProfile:
                if let user = authViewModel.currentUser {
                    CompleteProfileView(user: user) { updatedUser in
                        authViewModel.currentUser = updatedUser
                        authViewModel.authState = .authenticated
                    }
                } else {
                    AuthenticationView(viewModel: authViewModel)
                }
            case .authenticated:
                if let user = authViewModel.currentUser, user.isProfileComplete {
                    MainTabView(authViewModel: authViewModel)
                } else {
                    // Если профиль не завершён, показываем экран создания профиля
                    if let user = authViewModel.currentUser {
                        CompleteProfileView(user: user) { updatedUser in
                            authViewModel.currentUser = updatedUser
                            authViewModel.authState = .authenticated
                        }
                    } else {
                        AuthenticationView(viewModel: authViewModel)
                    }
                }
            case .error:
                AuthenticationView(viewModel: authViewModel)
            }
        }
    }
}

struct MainTabView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        TabView {
            RoomsView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Комнаты")
                }
            
            CardsView()
                .tabItem {
                    Image(systemName: "rectangle.stack.fill")
                    Text("Карты")
                }
            
            ProfileView(authViewModel: authViewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
        }
        .accentColor(.blue)
    }
}

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = authViewModel.currentUser {
                    VStack(spacing: 16) {
                        Text("👤")
                            .font(.system(size: 80))
                        
                        Text(user.nickname ?? "Пользователь")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Рейтинг: \(Int(user.rating))")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("ID: \(user.device_id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                }
                
                Spacer()
                
                Button("Выйти") {
                    Task {
                        await authViewModel.logout()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
            .navigationTitle("Профиль")
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}

#Preview {
    MainView()
} 