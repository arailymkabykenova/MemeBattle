import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var showingError = false
    @State private var showingDebug = false
    @State private var isButtonPressed = false
    
    var body: some View {
        ZStack {
            // Анимированный фон
            AnimatedBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Заголовок с анимацией
                VStack(spacing: 16) {
                    Text("🎮")
                        .font(.system(size: 80))
                        .scaleEffect(viewModel.authState == .loading ? 1.2 : 1.0)
                        .rotationEffect(.degrees(viewModel.authState == .loading ? 360 : 0))
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: false),
                            value: viewModel.authState == .loading
                        )
                    
                    Text("Мем Карточная Игра")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        .opacity(viewModel.authState == .loading ? 0.7 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.authState == .loading)
                    
                    Text("Собирай мемы, играй с друзьями!")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                .transition(.scale.combined(with: .opacity))
                
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
            UIImpactFeedbackGenerator.playSelection()
            withAnimation(.easeInOut(duration: 0.1)) {
                isButtonPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isButtonPressed = false
                }
            }
            
            Task {
                await viewModel.authenticateWithDeviceId()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "iphone")
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(color: .blue, radius: 3)
                
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
            .scaleEffect(isButtonPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isButtonPressed)
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            // Кастомный спиннер с анимацией
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .linear(duration: 1.0)
                        .repeatForever(autoreverses: false),
                        value: viewModel.authState == .loading
                    )
            }
            
            Text("Входим в игру...")
                .font(.title3)
                .foregroundColor(.white)
                .opacity(0.9)
        }
        .frame(height: 80)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .shadow(color: .red, radius: 5)
            
            Text("Не удалось войти")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(viewModel.errorMessage)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("Попробовать снова") {
                UIImpactFeedbackGenerator.playSelection()
                Task {
                    await viewModel.authenticateWithDeviceId()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(
            GlassmorphismView()
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Debug View
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
                            
                            Button("Проверить") {
                                checkServerHealth()
                            }
                            .buttonStyle(.bordered)
                            .disabled(isCheckingHealth)
                        }
                        
                        Divider()
                        
                        Text("Состояние аутентификации")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Статус: \(viewModel.authState.rawValue)")
                            Text("Ошибка: \(viewModel.errorMessage.isEmpty ? "Нет" : viewModel.errorMessage)")
                            if let user = viewModel.currentUser {
                                Text("Пользователь ID: \(user.id)")
                                Text("Device ID: \(user.device_id)")
                                Text("Профиль завершен: \(user.isProfileComplete ? "Да" : "Нет")")
                            }
                        }
                        .font(.caption)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
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
    
    private func checkServerHealth() {
        isCheckingHealth = true
        serverHealth = "Проверяется..."
        
        Task {
            do {
                let isHealthy = try await NetworkManager.shared.checkServerHealth()
                await MainActor.run {
                    serverHealth = isHealthy ? "Работает" : "Ошибка"
                    isCheckingHealth = false
                }
            } catch {
                await MainActor.run {
                    serverHealth = "Ошибка: \(error.localizedDescription)"
                    isCheckingHealth = false
                }
            }
        }
    }
}

struct GlassmorphismView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    AuthenticationView(viewModel: AuthenticationViewModel())
} 