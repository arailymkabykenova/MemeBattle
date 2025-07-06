import SwiftUI
import os

struct CompleteProfileView: View {
    let user: User
    let onProfileCompleted: (User) -> Void
    
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var nickname = ""
    @State private var birthDate = Date()
    @State private var selectedGender = "male"
    @State private var showingError = false
    @State private var isFormValid = false
    
    private let minDate = Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date()
    private let maxDate = Calendar.current.date(byAdding: .year, value: -6, to: Date()) ?? Date()
    
    var body: some View {
        ZStack {
            // Анимированный фон
            AnimatedBackgroundView()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Заголовок
                    VStack(spacing: 16) {
                        Text("👤")
                            .font(.system(size: 60))
                            .scaleEffect(viewModel.authState == .loading ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5), value: viewModel.authState == .loading)
                        
                        Text("Заполните профиль")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        
                        Text("Расскажите о себе, чтобы начать играть")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                    .padding(.top, 40)
                    
                    // Форма
                    VStack(spacing: 24) {
                        // Никнейм
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                    .shadow(color: .blue, radius: 3)
                                
                                Text("Никнейм")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            TextField("Введите никнейм", text: $nickname)
                                .textFieldStyle(CustomTextFieldStyle())
                                .onChange(of: nickname) { _ in
                                    validateForm()
                                }
                            
                            Text("3-20 символов, только буквы, цифры и подчеркивания")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Дата рождения
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.green)
                                    .shadow(color: .green, radius: 3)
                                
                                Text("Дата рождения")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            DatePicker("", selection: $birthDate, in: minDate...maxDate, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                                .onChange(of: birthDate) { _ in
                                    validateForm()
                                }
                            
                            Text("Минимальный возраст: 6 лет")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Пол
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.purple)
                                    .shadow(color: .purple, radius: 3)
                                
                                Text("Пол")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            Picker("Пол", selection: $selectedGender) {
                                Text("Мужской").tag("male")
                                Text("Женский").tag("female")
                                Text("Другой").tag("other")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .onChange(of: selectedGender) { _ in
                                validateForm()
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Кнопка сохранения
                    VStack(spacing: 16) {
                        Button(action: {
                            UIImpactFeedbackGenerator.playSelection()
                            saveProfile()
                        }) {
                            HStack(spacing: 12) {
                                if viewModel.authState == .loading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .shadow(color: .green, radius: 3)
                                }
                                
                                Text(viewModel.authState == .loading ? "Сохранение..." : "Сохранить профиль")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: isFormValid ? [.green, .blue] : [.gray, .gray.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(!isFormValid || viewModel.authState == .loading)
                        .scaleEffect(isFormValid ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.2), value: isFormValid)
                        
                        if !isFormValid && !nickname.isEmpty {
                            Text("Проверьте правильность заполнения полей")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            // Заполняем существующие данные
            if let existingNickname = user.nickname {
                nickname = existingNickname
            }
            if let existingBirthDate = user.birth_date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: existingBirthDate) {
                    birthDate = date
                }
            }
            if let existingGender = user.gender {
                selectedGender = existingGender
            }
            
            validateForm()
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") {
                showingError = false
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.authState) { state in
            if state == .authenticated {
                if let updatedUser = viewModel.currentUser {
                    onProfileCompleted(updatedUser)
                }
            } else if state == .error {
                showingError = true
            }
        }
    }
    
    private func validateForm() {
        let nicknameValid = nickname.count >= 3 && nickname.count <= 20
        let nicknameRegex = try! NSRegularExpression(pattern: "^[a-zA-Zа-яА-Я0-9_]+$")
        let nicknameMatches = nicknameRegex.firstMatch(in: nickname, range: NSRange(location: 0, length: nickname.count)) != nil
        
        let ageValid = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0 >= 6
        
        isFormValid = nicknameValid && nicknameMatches && ageValid && !nickname.isEmpty
    }
    
    private func saveProfile() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let birthDateString = formatter.string(from: birthDate)
        
        Task {
            await viewModel.completeProfile(
                nickname: nickname,
                birthDate: birthDateString,
                gender: selectedGender
            )
        }
    }
}

// MARK: - Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .foregroundColor(.white)
            .accentColor(.blue)
    }
}

#Preview {
    CompleteProfileView(
        user: User(
            id: 1,
            device_id: "test_device",
            nickname: nil,
            birth_date: nil,
            gender: nil,
            rating: 1000,
            created_at: "2024-01-01T10:00:00Z",
            last_seen: nil,
            statistics: nil,
            age: nil
        )
    ) { _ in }
} 