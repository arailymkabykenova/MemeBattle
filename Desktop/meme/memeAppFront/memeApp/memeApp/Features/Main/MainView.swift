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
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Анимированный фон
                AnimatedBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        if let user = authViewModel.currentUser {
                            // Профиль пользователя
                            VStack(spacing: 20) {
                                // Аватар
                                Text("👤")
                                    .font(.system(size: 80))
                                    .scaleEffect(1.0)
                                
                                // Информация о пользователе
                                VStack(spacing: 12) {
                                    Text(user.nickname ?? "Пользователь")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                                    
                                    HStack(spacing: 20) {
                                        VStack {
                                            Text("\(Int(user.rating))")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.yellow)
                                                .shadow(color: .yellow, radius: 3)
                                            
                                            Text("Рейтинг")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        
                                        VStack {
                                            Text(user.displayAge)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                                .shadow(color: .blue, radius: 3)
                                            
                                            Text("Возраст")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        
                                        VStack {
                                            Text(user.displayGender)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.purple)
                                                .shadow(color: .purple, radius: 3)
                                            
                                            Text("Пол")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(GlassmorphismView())
                            .padding(.horizontal, 20)
                            
                            // Статистика
                            if let statistics = user.statistics {
                                VStack(spacing: 16) {
                                    Text("Статистика")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                    
                                    HStack(spacing: 20) {
                                        StatCard(
                                            title: "Игр сыграно",
                                            value: "\(statistics.games_played)",
                                            icon: "gamecontroller.fill",
                                            color: .blue
                                        )
                                        
                                        StatCard(
                                            title: "Побед",
                                            value: "\(statistics.games_won)",
                                            icon: "trophy.fill",
                                            color: .yellow
                                        )
                                    }
                                    
                                    HStack(spacing: 20) {
                                        StatCard(
                                            title: "Общий счет",
                                            value: "\(statistics.total_score)",
                                            icon: "star.fill",
                                            color: .orange
                                        )
                                        
                                        StatCard(
                                            title: "Карт собрано",
                                            value: "\(statistics.cards_collected)",
                                            icon: "rectangle.stack.fill",
                                            color: .purple
                                        )
                                    }
                                }
                                .padding()
                                .background(GlassmorphismView())
                                .padding(.horizontal, 20)
                            }
                            
                            // Действия
                            VStack(spacing: 16) {
                                Button("Редактировать профиль") {
                                    UIImpactFeedbackGenerator.playSelection()
                                    showingEditProfile = true
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                
                                Button("Выйти") {
                                    UIImpactFeedbackGenerator.playSelection()
                                    Task {
                                        await authViewModel.logout()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                            .padding(.horizontal, 20)
                            
                        } else {
                            // Загрузка профиля
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                
                                Text("Загрузка профиля...")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditProfile) {
                if let user = authViewModel.currentUser {
                    EditProfileView(user: user) { updatedUser in
                        authViewModel.currentUser = updatedUser
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .shadow(color: color, radius: 3)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct EditProfileView: View {
    let user: User
    let onProfileUpdated: (User) -> Void
    
    @StateObject private var viewModel = AuthenticationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var nickname: String
    @State private var birthDate: Date
    @State private var selectedGender: String
    @State private var showingError = false
    @State private var isFormValid = false
    
    private let minDate = Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date()
    private let maxDate = Calendar.current.date(byAdding: .year, value: -6, to: Date()) ?? Date()
    
    init(user: User, onProfileUpdated: @escaping (User) -> Void) {
        self.user = user
        self.onProfileUpdated = onProfileUpdated
        
        // Инициализируем состояние
        _nickname = State(initialValue: user.nickname ?? "")
        _selectedGender = State(initialValue: user.gender ?? "male")
        
        if let birthDateString = user.birth_date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            _birthDate = State(initialValue: formatter.date(from: birthDateString) ?? Date())
        } else {
            _birthDate = State(initialValue: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        VStack(spacing: 16) {
                            Text("✏️")
                                .font(.system(size: 60))
                            
                            Text("Редактировать профиль")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        }
                        .padding(.top, 40)
                        
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
                                            .fill(Color.clear)
                                            .background(.ultraThinMaterial)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .onChange(of: birthDate) { _ in
                                        validateForm()
                                    }
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
                                        .fill(Color.clear)
                                        .background(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .onChange(of: selectedGender) { _ in
                                    validateForm()
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        Button("Сохранить изменения") {
                            UIImpactFeedbackGenerator.playSelection()
                            saveProfile()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled(!isFormValid || viewModel.authState == .loading)
                        .padding(.horizontal, 32)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
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
                    onProfileUpdated(updatedUser)
                    dismiss()
                }
            } else if state == .error {
                showingError = true
            }
        }
    }
    
    private func validateForm() {
        // Проверяем длину никнейма
        let nicknameValid = nickname.count >= 3 && nickname.count <= 20
        
        // Проверяем формат никнейма
        let nicknameRegex = try! NSRegularExpression(pattern: "^[a-zA-Zа-яА-Я0-9_]+$")
        let nicknameMatches = nicknameRegex.firstMatch(in: nickname, range: NSRange(location: 0, length: nickname.count)) != nil
        
        // Проверяем возраст
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        let ageValid = (ageComponents.year ?? 0) >= 6
        
        // Проверяем, что никнейм не пустой
        let notEmpty = !nickname.isEmpty
        
        // Объединяем все проверки
        isFormValid = nicknameValid && nicknameMatches && ageValid && notEmpty
    }
    
    private func saveProfile() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let birthDateString = formatter.string(from: birthDate)
        
        Task {
            await viewModel.updateProfile(
                nickname: nickname,
                birthDate: birthDateString,
                gender: selectedGender
            )
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