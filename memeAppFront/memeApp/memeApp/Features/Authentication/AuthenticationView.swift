import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var showingError = false
    @State private var showingDebug = false
    
    var body: some View {
        ZStack {
            // Анимированный фон
            AnimatedBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Заголовок
                VStack(spacing: 16) {
                    Text("🎮")
                        .font(.system(size: 80))
                        .scaleEffect(viewModel.authState == .loading ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.authState == .loading)
                    
                    Text("Мем Карточная Игра")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    
                    Text("Собирай мемы, играй с друзьями!")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                
                Spacer()
                
                // Основной контент
                VStack(spacing: 24) {
                    switch viewModel.authState {
                    case .idle:
                        enterButton
                    case .loading:
                        loadingView
                    case .error:
                        errorView
                    case .authenticated, .needsProfile:
                        EmptyView() // Будет обработано в MainView
                    }
                }
                
                Spacer()
                
                // Нижний текст
                VStack(spacing: 8) {
                    Text("Безопасный вход через Device ID")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Ваши данные защищены")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            viewModel.checkAuthenticationStatus()
        }
        .alert("Ошибка входа", isPresented: $showingError) {
            Button("OK") {
                showingError = false
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.authState) { state in
            if state == .error {
                showingError = true
            }
        }
        .sheet(isPresented: $showingDebug) {
            DebugView(viewModel: viewModel)
        }
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    Button("Debug") {
                        showingDebug = true
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
                }
                Spacer()
            }
        )
    }
    
    // MARK: - Subviews
    
    private var enterButton: some View {
        Button(action: {
            Task {
                await viewModel.authenticateWithDeviceId()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "iphone")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("Войти в игру")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(28)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: viewModel.authState)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Входим в игру...")
                .font(.title3)
                .foregroundColor(.white)
                .opacity(0.9)
        }
        .frame(height: 80)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("Не удалось войти")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(viewModel.errorMessage)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("Попробовать снова") {
                Task {
                    await viewModel.authenticateWithDeviceId()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

struct DebugView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var serverHealth: String = "Не проверено"
    @State private var isCheckingHealth = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Состояние сервера")
                            .font(.headline)
                        
                        HStack {
                            Text("Сервер: \(serverHealth)")
                                .font(.body)
                            
                            Spacer()
                            
                            if isCheckingHealth {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        
                        Button("Проверить сервер") {
                            Task {
                                await checkServerHealth()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isCheckingHealth)
                    }
                    
                    Divider()
                    
                    Group {
                        Text("Состояние аутентификации")
                            .font(.headline)
                        
                        Text("Auth State: \(String(describing: viewModel.authState))")
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        
                        Text("Is New User: \(viewModel.isNewUser)")
                            .font(.body)
                        
                        if let token = KeychainManager.shared.getToken() {
                            Text("Token: \(String(token.prefix(20)))...")
                                .font(.body)
                                .foregroundColor(.green)
                        } else {
                            Text("Token: Отсутствует")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                        
                        if let user = viewModel.currentUser {
                            Text("User ID: \(user.id)")
                                .font(.body)
                            
                            Text("Device ID: \(user.device_id)")
                                .font(.body)
                            
                            Text("Nickname: \(user.nickname ?? "Не указан")")
                                .font(.body)
                            
                            Text("Profile Complete: \(user.isProfileComplete)")
                                .font(.body)
                        } else {
                            Text("User: nil")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                        
                        if !viewModel.errorMessage.isEmpty {
                            Text("Error: \(viewModel.errorMessage)")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Divider()
                    
                    Group {
                        Text("Действия")
                            .font(.headline)
                        
                        Button("Проверить статус") {
                            viewModel.checkAuthenticationStatus()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Аутентификация") {
                            Task {
                                await viewModel.authenticateWithDeviceId()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Выйти") {
                            Task {
                                await viewModel.logout()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Отладка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func checkServerHealth() async {
        isCheckingHealth = true
        serverHealth = "Проверяется..."
        
        do {
            let isHealthy = try await NetworkManager.shared.checkServerHealth()
            serverHealth = isHealthy ? "✅ Работает" : "❌ Не работает"
        } catch {
            serverHealth = "❌ Ошибка: \(error.localizedDescription)"
        }
        
        isCheckingHealth = false
    }
}

#Preview {
    AuthenticationView(viewModel: AuthenticationViewModel())
} 