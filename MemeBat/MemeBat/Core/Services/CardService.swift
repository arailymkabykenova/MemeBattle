import Foundation
import os

// MARK: - Card Service Errors
enum CardError: LocalizedError {
    case cardsNotFound
    case invalidCardData
    case networkError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .cardsNotFound:
            return "Карты не найдены"
        case .invalidCardData:
            return "Неверные данные карты"
        case .networkError:
            return "Ошибка сети"
        case .unauthorized:
            return "Не авторизован"
        }
    }
}

// MARK: - Card Service Protocol
protocol CardServiceProtocol {
    func getAllCards(page: Int, size: Int) async throws -> [Card]
    func getCardsByType(type: CardType, page: Int, size: Int) async throws -> [Card]
    func getCardsByRarity(rarity: CardRarity, page: Int, size: Int) async throws -> [Card]
    func getUserCards(page: Int, size: Int) async throws -> [UserCard]
    func getCardDetails(cardId: Int) async throws -> Card
}

// MARK: - Card Service
class CardService: CardServiceProtocol {
    private let networkManager: NetworkManagerProtocol
    private let logger = Logger(subsystem: "com.memegame.app", category: "card")
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    // MARK: - Public Methods
    func getAllCards(page: Int = 1, size: Int = 20) async throws -> [Card] {
        logger.debug("Fetching all cards: page=\(page), size=\(size)")
        
        let endpoint = buildCardsEndpoint(page: page, size: size)
        
        do {
            let cards: [Card] = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .GET
            )
            
            logger.debug("Fetched \(cards.count) cards")
            return cards
            
        } catch {
            logger.error("Failed to fetch cards: \(error.localizedDescription)")
            throw CardError.networkError
        }
    }
    
    func getCardsByType(type: CardType, page: Int = 1, size: Int = 20) async throws -> [Card] {
        logger.debug("Fetching cards by type: \(type.rawValue), page=\(page), size=\(size)")
        
        let endpoint = buildCardsEndpoint(page: page, size: size, type: type.rawValue)
        
        do {
            let cards: [Card] = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .GET
            )
            
            logger.debug("Fetched \(cards.count) cards of type: \(type.rawValue)")
            return cards
            
        } catch {
            logger.error("Failed to fetch cards by type: \(error.localizedDescription)")
            throw CardError.networkError
        }
    }
    
    func getCardsByRarity(rarity: CardRarity, page: Int = 1, size: Int = 20) async throws -> [Card] {
        logger.debug("Fetching cards by rarity: \(rarity.rawValue), page=\(page), size=\(size)")
        
        let endpoint = buildCardsEndpoint(page: page, size: size, rarity: rarity.rawValue)
        
        do {
            let cards: [Card] = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .GET
            )
            
            logger.debug("Fetched \(cards.count) cards of rarity: \(rarity.rawValue)")
            return cards
            
        } catch {
            logger.error("Failed to fetch cards by rarity: \(error.localizedDescription)")
            throw CardError.networkError
        }
    }
    
    func getUserCards(page: Int = 1, size: Int = 20) async throws -> [UserCard] {
        logger.debug("Fetching user cards: page=\(page), size=\(size)")
        
        let endpoint = buildUserCardsEndpoint(page: page, size: size)
        
        do {
            let userCards: [UserCard] = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .GET
            )
            
            logger.debug("Fetched \(userCards.count) user cards")
            return userCards
            
        } catch NetworkError.unauthorized {
            logger.error("Unauthorized to fetch user cards")
            throw CardError.unauthorized
        } catch {
            logger.error("Failed to fetch user cards: \(error.localizedDescription)")
            throw CardError.networkError
        }
    }
    
    func getCardDetails(cardId: Int) async throws -> Card {
        logger.debug("Fetching card details: \(cardId)")
        
        let endpoint = "\(APIConfig.Endpoints.cards)/\(cardId)"
        
        do {
            let card: Card = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .GET
            )
            
            logger.debug("Card details fetched successfully: \(cardId)")
            return card
            
        } catch NetworkError.notFound {
            logger.error("Card not found: \(cardId)")
            throw CardError.cardsNotFound
        } catch {
            logger.error("Failed to get card details: \(error.localizedDescription)")
            throw CardError.networkError
        }
    }
    
    // MARK: - Private Methods
    private func buildCardsEndpoint(page: Int, size: Int, type: String? = nil, rarity: String? = nil) -> String {
        var endpoint = APIConfig.Endpoints.cards
        var queryItems: [String] = []
        
        // Add pagination parameters
        queryItems.append("page=\(page)")
        queryItems.append("size=\(min(size, APIConfig.Pagination.maxPageSize))")
        
        // Add type filter if specified
        if let type = type {
            queryItems.append("type=\(type)")
        }
        
        // Add rarity filter if specified
        if let rarity = rarity {
            queryItems.append("rarity=\(rarity)")
        }
        
        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }
        
        return endpoint
    }
    
    private func buildUserCardsEndpoint(page: Int, size: Int) -> String {
        var endpoint = APIConfig.Endpoints.userCards
        var queryItems: [String] = []
        
        // Add pagination parameters
        queryItems.append("page=\(page)")
        queryItems.append("size=\(min(size, APIConfig.Pagination.maxPageSize))")
        
        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }
        
        return endpoint
    }
}

// MARK: - Card Collection Extensions
extension Array where Element == UserCard {
    var byRarity: [CardRarity: [UserCard]] {
        Dictionary(grouping: self) { $0.cardRarity }
    }
    
    var byType: [CardType: [UserCard]] {
        Dictionary(grouping: self) { $0.cardType }
    }
    
    var uniqueCards: [UserCard] {
        Array(Set(self.map { $0.id })).compactMap { id in
            self.first { $0.id == id }
        }
    }
    
    var totalCards: Int {
        self.count
    }
    
    var uniqueCardsCount: Int {
        Set(self.map { $0.id }).count
    }
    
    func cards(of rarity: CardRarity) -> [UserCard] {
        self.filter { $0.cardRarity == rarity }
    }
    
    func cards(of type: CardType) -> [UserCard] {
        self.filter { $0.cardType == type }
    }
} 