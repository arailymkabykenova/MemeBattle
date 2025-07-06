import SwiftUI

struct CardsView: View {
    @StateObject private var viewModel = CardsViewModel()
    @State private var selectedCardType: CardType = .all
    @State private var showingStarterCardsAlert = false
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Анимированный фон
                AnimatedBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок и фильтры
                    VStack(spacing: 16) {
                        // Заголовок
                        HStack {
                            Text("🃏")
                                .font(.system(size: 40))
                                .scaleEffect(1.0)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Мои карты")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                                
                                if let statistics = viewModel.cardStatistics {
                                    Text("Всего: \(statistics.starter_count + statistics.standard_count + statistics.unique_count)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                            
                            // Кнопка получения стартовых карт
                            if viewModel.needsStarterCards {
                                Button(action: {
                                    UIImpactFeedbackGenerator.playSelection()
                                    showingStarterCardsAlert = true
                                }) {
                                                                    Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                    .shadow(color: .green, radius: 3)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Фильтры по типу карт
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(CardType.allCases, id: \.self) { cardType in
                                    CardTypeFilterButton(
                                        cardType: cardType,
                                        isSelected: selectedCardType == cardType,
                                        count: viewModel.getCardCount(for: cardType)
                                    ) {
                                        UIImpactFeedbackGenerator.playSelection()
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedCardType = cardType
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Список карт
                    if viewModel.isLoading {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("Загрузка карт...")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    } else if viewModel.getAllCards().isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Text("📭")
                                .font(.system(size: 80))
                                .opacity(0.6)
                            
                            Text("У вас пока нет карт")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            
                            Text("Получите стартовые карты, чтобы начать играть")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                            
                            Button("Получить стартовые карты") {
                                UIImpactFeedbackGenerator.playSelection()
                                showingStarterCardsAlert = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        .padding(.horizontal, 40)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 20) {
                                ForEach(viewModel.getCardsByType(selectedCardType), id: \.id) { card in
                                    CardView(card: card)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("Карты")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await viewModel.fetchMyCards()
                }
            }
            .refreshable {
                Task {
                    await viewModel.fetchMyCards()
                }
            }
            .alert("Получить стартовые карты?", isPresented: $showingStarterCardsAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Получить") {
                    Task {
                        await viewModel.assignStarterCards()
                    }
                }
            } message: {
                Text("Вы получите 10 стартовых карт для начала игры")
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK") {
                    showingError = false
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onChange(of: viewModel.errorMessage) { message in
                if !message.isEmpty {
                    showingError = true
                }
            }
        }
    }
}

struct CardTypeFilterButton: View {
    let cardType: CardType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: cardType.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : cardType.color)
                
                Text(cardType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? cardType.color : Color.clear)
                    .background(.ultraThinMaterial)
                    .stroke(isSelected ? cardType.color : .white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

struct CardView: View {
    let card: UserCardResponse
    @State private var isPressed = false
    @State private var showingCardDetail = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator.playSelection()
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            showingCardDetail = true
        }) {
            VStack(spacing: 0) {
                // Изображение карты
                AsyncImage(url: URL(string: card.image_url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                        )
                }
                .frame(height: 160)
                .clipped()
                .cornerRadius(12, corners: [.topLeft, .topRight])
                
                // Информация о карте
                VStack(spacing: 8) {
                    Text(card.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        // Тип карты
                        HStack(spacing: 4) {
                            Image(systemName: getCardTypeIcon(card.card_type))
                                .font(.caption2)
                                .foregroundColor(getCardTypeColor(card.card_type))
                            
                            Text(getCardTypeDisplayName(card.card_type))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Уникальность
                        if card.is_unique_card {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                                .shadow(color: .yellow, radius: 2)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, corners: [.bottomLeft, .bottomRight])
                        .fill(Color.clear)
                        .background(.ultraThinMaterial)
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.clear)
                    .background(.ultraThinMaterial)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingCardDetail) {
            CardDetailView(card: card)
        }
    }
    
    private func getCardTypeIcon(_ type: String) -> String {
        switch type {
        case "starter":
            return "star.fill"
        case "standard":
            return "rectangle.stack.fill"
        case "unique":
            return "crown.fill"
        default:
            return "rectangle.stack.fill"
        }
    }
    
    private func getCardTypeColor(_ type: String) -> Color {
        switch type {
        case "starter":
            return .yellow
        case "standard":
            return .blue
        case "unique":
            return .purple
        default:
            return .gray
        }
    }
    
    private func getCardTypeDisplayName(_ type: String) -> String {
        switch type {
        case "starter":
            return "Старт"
        case "standard":
            return "Обыч"
        case "unique":
            return "Уник"
        default:
            return type
        }
    }
}

struct CardDetailView: View {
    let card: UserCardResponse
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Изображение карты
                        AsyncImage(url: URL(string: card.image_url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 300, maxHeight: 300)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.clear)
                                .background(.ultraThinMaterial)
                                .frame(width: 300, height: 300)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.white)
                                )
                        }
                        
                        // Информация о карте
                        VStack(spacing: 20) {
                            VStack(spacing: 8) {
                                Text(card.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                                    .multilineTextAlignment(.center)
                                
                                Text(card.description)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Характеристики карты
                            VStack(spacing: 16) {
                                HStack(spacing: 20) {
                                    CardDetailItem(
                                        title: "Тип",
                                        value: getCardTypeDisplayName(card.card_type),
                                        icon: getCardTypeIcon(card.card_type),
                                        color: getCardTypeColor(card.card_type)
                                    )
                                    
                                    CardDetailItem(
                                        title: "Уникальность",
                                        value: card.is_unique_card ? "Уникальная" : "Обычная",
                                        icon: card.is_unique_card ? "crown.fill" : "rectangle.stack.fill",
                                        color: card.is_unique_card ? .yellow : .gray
                                    )
                                }
                                
                                HStack(spacing: 20) {
                                    CardDetailItem(
                                        title: "ID",
                                        value: card.id,
                                        icon: "number",
                                        color: .blue
                                    )
                                    
                                    CardDetailItem(
                                        title: "Получена",
                                        value: formatDate(card.created_at),
                                        icon: "calendar",
                                        color: .green
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(GlassmorphismView())
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Детали карты")
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
    
    private func getCardTypeIcon(_ type: String) -> String {
        switch type {
        case "starter":
            return "star.fill"
        case "standard":
            return "rectangle.stack.fill"
        case "unique":
            return "crown.fill"
        default:
            return "rectangle.stack.fill"
        }
    }
    
    private func getCardTypeColor(_ type: String) -> Color {
        switch type {
        case "starter":
            return .yellow
        case "standard":
            return .blue
        case "unique":
            return .purple
        default:
            return .gray
        }
    }
    
    private func getCardTypeDisplayName(_ type: String) -> String {
        switch type {
        case "starter":
            return "Стартовая"
        case "standard":
            return "Обычная"
        case "unique":
            return "Уникальная"
        default:
            return type
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct CardDetailItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .shadow(color: color, radius: 3)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
                .background(.ultraThinMaterial)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    CardsView()
} 