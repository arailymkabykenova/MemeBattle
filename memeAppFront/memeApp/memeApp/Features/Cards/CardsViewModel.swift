import Foundation
import SwiftUI
import os

@MainActor
class CardsViewModel: ObservableObject {
    @Published var cards: [UserCardResponse] = []
    @Published var loadingState: LoadingState = .idle
    @Published var errorMessage: String = ""
    
    // Отдельные массивы для разных типов карт
    @Published var starterCards: [UserCardResponse] = []
    @Published var standardCards: [UserCardResponse] = []
    @Published var uniqueCards: [UserCardResponse] = []
    
    private let networkManager = NetworkManager.shared
    private let logger = Logger(subsystem: "com.memegame.app", category: "cards")
    
    enum LoadingState {
        case idle
        case loading
        case loaded
        case error
    }
    
    func loadCards() async {
        logger.debug("Loading user cards")
        loadingState = .loading
        errorMessage = ""
        
        do {
            let response: CardsResponse = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.users)/my-cards",
                method: .GET
            )
            
            // Заполняем отдельные массивы
            self.starterCards = response.starter_cards
            self.standardCards = response.standard_cards
            self.uniqueCards = response.unique_cards
            self.cards = response.cards // Общий массив всех карт
            
            loadingState = .loaded
            logger.debug("Successfully loaded cards - total: \(response.total_cards), starter: \(response.starter_cards.count), standard: \(response.standard_cards.count), unique: \(response.unique_cards.count)")
            
        } catch {
            logger.error("Failed to load cards: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            loadingState = .error
        }
    }
    
    func getStarterCards() async {
        logger.debug("Getting starter cards")
        loadingState = .loading
        errorMessage = ""
        
        do {
            // Получаем стартовые карты (они автоматически добавляются в коллекцию пользователя)
            let _: [String: Any] = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.users)/assign-starter-cards",
                method: .POST
            )
            
            logger.debug("Starter cards assigned successfully")
            
            // Перезагружаем карты пользователя
            await loadCards()
            
        } catch {
            logger.error("Failed to get starter cards: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            loadingState = .error
        }
    }
    
    func refresh() async {
        await loadCards()
    }
} 

 