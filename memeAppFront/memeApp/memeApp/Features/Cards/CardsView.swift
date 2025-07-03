import SwiftUI

struct CardsView: View {
    @StateObject private var viewModel = CardsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Анимированный фон
                AnimatedBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Заголовок
                    VStack(spacing: 8) {
                        Text("🃏")
                            .font(.system(size: 60))
                        
                        Text("Мои карты")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        
                        if !viewModel.cards.isEmpty {
                            Text("У вас \(viewModel.cards.count) карт")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.top, 20)
                    
                    // Кнопка для получения стартовых карт (если карт нет)
                    if viewModel.cards.isEmpty && viewModel.loadingState == .loaded {
                        Button("Получить стартовые карты") {
                            Task {
                                await viewModel.getStarterCards()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(viewModel.loadingState == .loading)
                        .padding(.horizontal)
                    }
                    
                    // Контент
                    switch viewModel.loadingState {
                    case .idle:
                        EmptyView()
                    case .loading:
                        loadingView
                    case .loaded:
                        if viewModel.cards.isEmpty {
                            emptyStateView
                        } else {
                            cardsGridView
                        }
                    case .error:
                        errorView
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.loadCards()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Загружаем ваши карты...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.6))
            
            Text("У вас пока нет карт")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Играйте в игры, чтобы получить новые карты!")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("Получить стартовые карты") {
                Task {
                    await viewModel.getStarterCards()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .padding()
    }
    
    private var cardsGridView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Стартовые карты
                if !viewModel.starterCards.isEmpty {
                    cardSection(title: "Стартовые карты", cards: viewModel.starterCards, icon: "star.fill", color: .yellow)
                }
                
                // Стандартные карты
                if !viewModel.standardCards.isEmpty {
                    cardSection(title: "Стандартные карты", cards: viewModel.standardCards, icon: "rectangle.stack.fill", color: .blue)
                }
                
                // Уникальные карты
                if !viewModel.uniqueCards.isEmpty {
                    cardSection(title: "Уникальные карты", cards: viewModel.uniqueCards, icon: "crown.fill", color: .orange)
                }
            }
            .padding()
        }
    }
    
    private func cardSection(title: String, cards: [UserCardResponse], icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                Text("\(cards.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.3))
                    .cornerRadius(8)
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160, maximum: 160), spacing: 16)
            ], spacing: 16) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    CardItemView(card: card)
                        .scaleEffect(1.0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(Double(index) * 0.1),
                            value: cards.count
                        )
                }
            }
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Ошибка загрузки")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(viewModel.errorMessage)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("Попробовать снова") {
                Task {
                    await viewModel.loadCards()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .padding()
    }
}

struct CardItemView: View {
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            }
            .frame(width: 160, height: 120)
            .clipped()
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // Информация о карте
            VStack(spacing: 8) {
                Text(card.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 40)
                
                HStack {
                    Text(card.type.capitalized)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text(card.rarity.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(rarityColor(card.rarity).opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, corners: [.bottomLeft, .bottomRight])
                    .fill(.ultraThinMaterial)
            )
        }
        .frame(width: 160, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
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
    
    private func rarityColor(_ rarity: String) -> Color {
        switch rarity.lowercased() {
        case "common":
            return .gray
        case "rare":
            return .blue
        case "epic":
            return .purple
        case "legendary":
            return .orange
        default:
            return .white
        }
    }
}

#Preview {
    CardsView()
} 