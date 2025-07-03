import SwiftUI
import GameKit

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        ZStack {
            LinearGradient.animatedBackground
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "gamecontroller.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .sfSymbolGradient([.accentBlue, .accentPurple])
                    .neonGlow(color: .accentBlue, radius: 12)
                    .padding(.bottom, 8)
                    .animation(.juicySpring, value: viewModel.isAuthenticated)
                
                Text("MemeBat")
                    .titleStyle()
                    .shadow(color: .accentPurple.opacity(0.2), radius: 8, x: 0, y: 4)
                
                if viewModel.isAuthenticated, let user = viewModel.user {
                    VStack(spacing: 12) {
                        Text("Добро пожаловать, \(user.nickname)!")
                            .subtitleStyle()
                        Text("Рейтинг: \(Int(user.rating))")
                            .bodyStyle()
                        Text("Возраст: \(user.age)")
                            .captionStyle()
                        Button(action: {
                            viewModel.logout()
                        }) {
                            Text("Выйти")
                                .frame(maxWidth: .infinity)
                        }
                        .primaryButtonStyle()
                        .hapticFeedback(.medium)
                        .padding(.top, 8)
                    }
                    .glassmorphism()
                    .padding()
                    .transition(.juicyAppear)
                } else {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentBlue))
                            .scaleEffect(1.5)
                            .padding()
                            .transition(.opacity)
                    } else {
                        Button(action: {
                            Task { await viewModel.authenticate() }
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                Text("Войти через Game Center")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .primaryButtonStyle()
                        .hapticFeedback(.medium)
                        .padding(.horizontal, 32)
                        .transition(.juicyAppear)
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.errorColor)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .transition(.slideDown)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .animation(.juicySpring, value: viewModel.isAuthenticated)
        }
    }
}

#Preview {
    AuthView()
} 