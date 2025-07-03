import Foundation
import os

class CardService {
    private let networkManager = NetworkManager.shared
    private let logger = Logger(subsystem: "com.memegame.app", category: "card-service")
    
    // MARK: - Получение карт пользователя
    func getUserCards(type: CardType = .all) async throws -> CardsResponse {
        logger.debug("Fetching user cards of type: \(type.rawValue)")
        
        do {
            let response: CardsResponse = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.users)/my-cards",
                method: .GET
            )
            logger.debug("Successfully fetched \(response.cards.count) cards")
            return response
        } catch {
            logger.error("Failed to fetch user cards: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Поиск карт
    func searchCards(query: String, type: CardType = .all) async throws -> [UserCardResponse] {
        logger.debug("Searching cards with query: '\(query)' and type: \(type.rawValue)")
        
        do {
            let endpoint = "\(APIConfig.Endpoints.users)/my-cards/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&type=\(type.rawValue)"
            let response: [UserCardResponse] = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .GET
            )
            logger.debug("Search found \(response.count) cards")
            return response
        } catch {
            logger.error("Failed to search cards: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Получение карт по типу
    func getCardsByType(_ type: CardType) async throws -> [UserCardResponse] {
        logger.debug("Fetching cards by type: \(type.rawValue)")
        
        do {
            let endpoint = "\(APIConfig.Endpoints.users)/my-cards?type=\(type.rawValue)"
            let response: CardsResponse = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .GET
            )
            logger.debug("Successfully fetched \(response.cards.count) cards of type \(type.rawValue)")
            return response.cards
        } catch {
            logger.error("Failed to fetch cards by type: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Получение стартовых карт
    func assignStarterCards() async throws {
        logger.debug("Assigning starter cards to user")
        
        do {
            let _: [String: Any] = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.users)/assign-starter-cards",
                method: .POST
            )
            logger.debug("Successfully assigned starter cards")
        } catch {
            logger.error("Failed to assign starter cards: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Получение детальной информации о карте
    func getCardDetail(cardId: Int) async throws -> Card {
        logger.debug("Fetching card detail for ID: \(cardId)")
        
        do {
            let response: Card = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.cards)/\(cardId)",
                method: .GET
            )
            logger.debug("Successfully fetched card detail")
            return response
        } catch {
            logger.error("Failed to fetch card detail: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Получение всех доступных карт
    func getAllCards() async throws -> [Card] {
        logger.debug("Fetching all available cards")
        
        do {
            let response: [Card] = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.cards)",
                method: .GET
            )
            logger.debug("Successfully fetched \(response.count) available cards")
            return response
        } catch {
            logger.error("Failed to fetch all cards: \(error.localizedDescription)")
            throw error
        }
    }
}