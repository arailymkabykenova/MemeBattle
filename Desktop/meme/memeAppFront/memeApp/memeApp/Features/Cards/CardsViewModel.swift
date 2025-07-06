import Foundation
import SwiftUI
import os

@MainActor
class CardsViewModel: ObservableObject {
    @Published var myCards: MyCardsResponse?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let cardService = CardService.shared
    private let logger = Logger(subsystem: "com.memegame.app", category: "cards")
    
    var cardStatistics: CardStatistics? {
        return myCards?.statistics
    }
    
    var needsStarterCards: Bool {
        return myCards?.total_cards == 0
    }
    
    func fetchMyCards() async {
        logger.debug("Fetching user cards")
        isLoading = true
        errorMessage = ""
        
        do {
            let response = try await cardService.fetchMyCards()
            myCards = response
            
            logger.debug("Fetched \(response.total_cards) cards")
            logger.debug("Starter: \(response.statistics.starter_count), Standard: \(response.statistics.standard_count), Unique: \(response.statistics.unique_count)")
            
        } catch {
            logger.error("Failed to fetch user cards: \(error.localizedDescription)")
            
            if let cardError = error as? CardError {
                errorMessage = cardError.localizedDescription
            } else if let networkError = error as? NetworkError {
                errorMessage = networkError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func assignStarterCards() async {
        logger.debug("Assigning starter cards")
        isLoading = true
        errorMessage = ""
        
        do {
            let response = try await cardService.assignStarterCards(count: 10)
            
            logger.debug("Assigned \(response.cards_assigned) starter cards")
            
            // Обновляем список карт
            await fetchMyCards()
            
        } catch {
            logger.error("Failed to assign starter cards: \(error.localizedDescription)")
            
            if let cardError = error as? CardError {
                errorMessage = cardError.localizedDescription
            } else if let networkError = error as? NetworkError {
                errorMessage = networkError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func getCardsForGameRound(roundCount: Int) async -> [GameCard] {
        logger.debug("Getting cards for game round \(roundCount)")
        
        do {
            let cards = try await cardService.getCardsForGameRound(roundCount: roundCount)
            logger.debug("Got \(cards.count) cards for game round")
            return cards
        } catch {
            logger.error("Failed to get game cards: \(error.localizedDescription)")
            return []
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
    
    func getCardCount(for type: CardType) -> Int {
        guard let myCards = myCards else { return 0 }
        
        switch type {
        case .starter:
            return myCards.statistics.starter_count
        case .standard:
            return myCards.statistics.standard_count
        case .unique:
            return myCards.statistics.unique_count
        case .all:
            return myCards.total_cards
        }
    }
    
    func hasCards() -> Bool {
        return myCards?.total_cards ?? 0 > 0
    }
    
    func hasStarterCards() -> Bool {
        return myCards?.statistics.starter_count ?? 0 > 0
    }
    
    func hasStandardCards() -> Bool {
        return myCards?.statistics.standard_count ?? 0 > 0
    }
    
    func hasUniqueCards() -> Bool {
        return myCards?.statistics.unique_count ?? 0 > 0
    }
} 

 