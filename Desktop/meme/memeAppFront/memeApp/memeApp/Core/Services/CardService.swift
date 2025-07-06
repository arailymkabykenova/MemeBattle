import Foundation
import os

// MARK: - Card Errors
enum CardError: Error, LocalizedError {
    case networkError
    case serverError
    case invalidResponse
    case noCardsAvailable
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Ошибка сети"
        case .serverError:
            return "Ошибка сервера"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .noCardsAvailable:
            return "Карты недоступны"
        }
    }
}

// MARK: - CardService
@MainActor
class CardService: ObservableObject {
    static let shared = CardService()
    
    @Published var myCards: MyCardsResponse?
    @Published var isLoading = false
    
    private let networkManager = NetworkManager.shared
    private let logger = Logger(subsystem: "com.memegame.app", category: "cards")
    
    private init() {}
    
    // MARK: - Public Methods
    
    func assignStarterCards(count: Int = 10) async throws -> AssignStarterCardsResponse {
        logger.debug("Assigning \(count) starter cards")
        isLoading = true
        
        defer { isLoading = false }
        
        do {
            let endpoint = "\(APIConfig.Endpoints.cards)/assign-starter-cards?count=\(count)"
            
            let response: AssignStarterCardsResponse = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .POST,
                body: nil
            )
            
            logger.debug("Assigned \(response.cards_assigned) starter cards")
            
            // Обновляем список карт
            try await fetchMyCards()
            
            return response
            
        } catch {
            logger.error("Failed to assign starter cards: \(error.localizedDescription)")
            throw CardError.networkError
        }
    }
    
    func fetchMyCards() async throws -> MyCardsResponse {
        logger.debug("Fetching user cards")
        isLoading = true
        
        defer { isLoading = false }
        
        do {
            let endpoint = "\(APIConfig.Endpoints.cards)/my-cards"
            
            let response: MyCardsResponse = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .GET,
                body: nil
            )
            
            logger.debug("Fetched \(response.total_cards) cards")
            
            // Обновляем состояние
            myCards = response
            
            return response
            
        } catch {
            logger.error("Failed to fetch user cards: \(error.localizedDescription)")
            throw CardError.networkError
        }
    }
    
    func getCardsForGameRound(roundCount: Int) async throws -> [GameCard] {
        logger.debug("Fetching cards for game round \(roundCount)")
        
        do {
            let endpoint = "\(APIConfig.Endpoints.cards)/for-game-round?round_count=\(roundCount)"
            
            let cards: [GameCard] = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .GET,
                body: nil
            )
            
            logger.debug("Fetched \(cards.count) cards for game round")
            
            return cards
            
        } catch {
            logger.error("Failed to fetch game cards: \(error.localizedDescription)")
            throw CardError.networkError
        }
    }
    
    // MARK: - Helper Methods
    
    func getAllCards() -> [UserCardResponse] {
        guard let myCards = myCards else { return [] }
        
        return myCards.cards_by_type.starter + 
               myCards.cards_by_type.standard + 
               myCards.cards_by_type.unique
    }
    
    func getCardsByType(_ type: CardType) -> [UserCardResponse] {
        guard let myCards = myCards else { return [] }
        
        switch type {
        case .starter:
            return myCards.cards_by_type.starter
        case .standard:
            return myCards.cards_by_type.standard
        case .unique:
            return myCards.cards_by_type.unique
        case .all:
            return getAllCards()
        }
    }
    
    func getCardStatistics() -> CardStatistics? {
        return myCards?.statistics
    }
    
    func hasStarterCards() -> Bool {
        return myCards?.statistics.starter_count ?? 0 > 0
    }
    
    func needsStarterCards() -> Bool {
        return myCards?.total_cards == 0
    }
}