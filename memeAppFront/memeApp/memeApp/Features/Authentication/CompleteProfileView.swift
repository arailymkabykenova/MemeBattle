import SwiftUI
import os

struct CompleteProfileView: View {
    let user: User
    let onComplete: (User) -> Void
    
    @State private var nickname = ""
    @State private var birthDate = Date()
    @State private var gender = "male"
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingWelcome = false
    @State private var starterCards: [UserCardResponse] = []
    
    private let logger = Logger(subsystem: "com.memegame.app", category: "profile")
    
    var body: some View {
        ZStack {
            // Анимированный фон
            AnimatedBackgroundView()
                .ignoresSafeArea()
            
            if showingWelcome {
                WelcomeView(
                    nickname: nickname,
                    starterCards: starterCards,
                    onContinue: {
                        let updatedUser = User(
                            id: user.id,
                            device_id: user.device_id,
                            nickname: nickname,
                            birth_date: DateFormatter.yyyyMMdd.string(from: birthDate),
                            gender: gender,
                            rating: user.rating,
                            created_at: user.created_at,
                            last_seen: nil,
                            statistics: nil
                        )
                        onComplete(updatedUser)
                    }
                )
            } else {
                profileFormView
            }
        }
        .alert("Ошибка создания профиля", isPresented: $showingError) {
            Button("OK") {
                showingError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var profileFormView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Заголовок
                VStack(spacing: 16) {
                    Text("👤")
                        .font(.system(size: 80))
                    
                    Text("Создание профиля")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    
                    Text("Расскажите о себе")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Форма
                VStack(spacing: 24) {
                    // Никнейм
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Никнейм")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Введите никнейм", text: $nickname)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    // Дата рождения
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Дата рождения")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        DatePicker("", selection: $birthDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .colorScheme(.dark)
                    }
                    
                    // Пол
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Пол")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Picker("Пол", selection: $gender) {
                            Text("Мужской").tag("male")
                            Text("Женский").tag("female")
                            Text("Не указан").tag("other")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .colorScheme(.dark)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                
                // Кнопка создания профиля
                Button(action: {
                    Task {
                        await createProfile()
                    }
                }) {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                        }
                        
                        Text(isLoading ? "Создание профиля..." : "Создать профиль")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isLoading || trimmedNickname.isEmpty)
                .opacity(trimmedNickname.isEmpty ? 0.6 : 1.0)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 32)
        }
    }
    
    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func createProfile() async {
        logger.debug("Starting profile creation")
        isLoading = true
        errorMessage = ""
        
        do {
            // 1. Валидация
            guard !trimmedNickname.isEmpty else {
                throw ProfileError.emptyNickname
            }
            
            guard trimmedNickname.count >= 3 && trimmedNickname.count <= 20 else {
                throw ProfileError.invalidNickname
            }
            
            // 2. Создаем профиль
            let birthDateString = DateFormatter.yyyyMMdd.string(from: birthDate)
            
            let profileData: [String: Any] = [
                "nickname": trimmedNickname,
                "birth_date": birthDateString,
                "gender": gender
            ]
            
            logger.debug("Profile data: \(profileData)")
            
            let networkManager = NetworkManager.shared
            
            // 3. Отправляем данные профиля
            logger.debug("Sending profile data to: \(APIConfig.Endpoints.users)/")
            let _: [String: Any] = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.users)/",
                method: .POST,
                body: try? JSONSerialization.data(withJSONObject: profileData)
            )
            
            logger.debug("Profile created successfully")
            
            // 4. Запрашиваем выдачу стартовых карт
            logger.debug("Requesting starter cards from: \(APIConfig.Endpoints.users)/assign-starter-cards")
            do {
                let _: [String: Any] = try await networkManager.makeRequest(
                    endpoint: "\(APIConfig.Endpoints.users)/assign-starter-cards",
                    method: .POST
                )
                logger.debug("Starter cards assigned successfully")
            } catch {
                logger.warning("Failed to assign starter cards: \(error.localizedDescription)")
                // Продолжаем выполнение, даже если стартовые карты не выдались
            }
            
            // 5. Получаем карты пользователя (включая стартовые)
            logger.debug("Fetching user cards from: \(APIConfig.Endpoints.users)/my-cards")
            let starterCardsResponse: CardsResponse = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.users)/my-cards",
                method: .GET
            )
            
            logger.debug("User cards fetched successfully - total: \(starterCardsResponse.total_cards), starter: \(starterCardsResponse.starter_cards.count), standard: \(starterCardsResponse.standard_cards.count), unique: \(starterCardsResponse.unique_cards.count)")
            
            starterCards = starterCardsResponse.cards
            
            // 6. Показываем экран приветствия
            withAnimation(.easeInOut(duration: 0.5)) {
                showingWelcome = true
            }
            
        } catch {
            logger.error("Profile creation failed: \(error.localizedDescription)")
            
            if let networkError = error as? NetworkError {
                switch networkError {
                case .conflict:
                    errorMessage = "Никнейм занят. Попробуйте другой никнейм."
                case .apiError(let message):
                    errorMessage = message
                default:
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
            
            showingError = true
        }
        
        isLoading = false
    }
}

struct WelcomeView: View {
    let nickname: String
    let starterCards: [UserCardResponse]
    let onContinue: () -> Void
    
    @State private var showCards = false
    @State private var currentCardIndex = 0
    
    var body: some View {
        VStack(spacing: 40) {
            // Приветствие
            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 100))
                    .scaleEffect(showCards ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showCards)
                
                Text("Добро пожаловать, \(nickname)!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    .multilineTextAlignment(.center)
                
                if starterCards.isEmpty {
                    Text("Профиль создан успешно!")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                } else {
                    Text("Вы получили стартовые карты!")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
            }
            
            // Карты
            if showCards && !starterCards.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(Array(starterCards.enumerated()), id: \.element.id) { index, card in
                            MiniCardView(card: card)
                                .scaleEffect(index == currentCardIndex ? 1.1 : 0.9)
                                .opacity(index == currentCardIndex ? 1.0 : 0.7)
                                .animation(.easeInOut(duration: 0.3), value: currentCardIndex)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.1),
                                    value: showCards
                                )
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .frame(height: 140)
                .onAppear {
                    // Автоматическая прокрутка карт
                    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentCardIndex = (currentCardIndex + 1) % starterCards.count
                        }
                    }
                }
            } else if showCards && starterCards.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Карты будут доступны в игре")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(height: 140)
            }
            
            Spacer()
            
            // Кнопка продолжения
            Button("Начать играть!") {
                onContinue()
            }
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(28)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .onAppear {
            // Показываем карты с задержкой
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showCards = true
                }
            }
        }
    }
}

struct MiniCardView: View {
    let card: UserCardResponse
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Изображение карты
            AsyncImage(url: URL(string: card.image_url)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    )
            }
            .frame(width: 120, height: 80)
            .clipped()
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            // Название карты
            Text(card.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 120, height: 40)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, corners: [.bottomLeft, .bottomRight])
                        .fill(.ultraThinMaterial)
                )
        }
        .frame(width: 120, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}

enum ProfileError: Error, LocalizedError {
    case emptyNickname
    case invalidNickname
    
    var errorDescription: String? {
        switch self {
        case .emptyNickname:
            return "Введите никнейм"
        case .invalidNickname:
            return "Никнейм должен содержать от 3 до 20 символов"
        }
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// Кастомный стиль для текстовых полей
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// Логгер
private let logger = Logger(subsystem: "com.memegame.app", category: "profile") 