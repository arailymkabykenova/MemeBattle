//
//  CardsRepository.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

protocol CardsRepositoryProtocol {
    func getAllCards() async throws -> [CardResponse]
    func getMyCards() async throws -> MyCardsResponse
    func getCardsByType(_ type: CardType) async throws -> CardsByTypeResponse
    func getCardsForGameRound() async throws -> GameRoundCardsResponse
    func assignStarterCards() async throws -> MyCardsResponse
    func getAzureStatus() async throws -> AzureStatusResponse
    func loadCardsFromAzure(type: CardType?) async throws -> AzureLoadResponse
    func getCardStatistics() async throws -> CardStatisticsResponse
    func awardWinnerCard(gameId: Int, userId: Int, cardId: String) async throws -> AwardWinnerCardResponse
}

class CardsRepository: CardsRepositoryProtocol {
    private let networkManager = NetworkManager.shared
    
    // MARK: - Card Retrieval
    
    func getAllCards() async throws -> [CardResponse] {
        let response: [CardResponse] = try await networkManager.get(APIConstants.Endpoints.allCards)
        return response
    }
    
    func getMyCards() async throws -> MyCardsResponse {
        let response: MyCardsResponse = try await networkManager.get(APIConstants.Endpoints.myCards)
        return response
    }
    
    func getCardsByType(_ type: CardType) async throws -> CardsByTypeResponse {
        let queryItems = [URLQueryItem(name: "card_type", value: type.rawValue)]
        let response: CardsByTypeResponse = try await networkManager.get(APIConstants.Endpoints.cardsByType, queryItems: queryItems)
        return response
    }
    
    func getCardsForGameRound() async throws -> GameRoundCardsResponse {
        let response: GameRoundCardsResponse = try await networkManager.get(APIConstants.Endpoints.forGameRound)
        return response
    }
    
    // MARK: - Card Assignment
    
    func assignStarterCards() async throws -> MyCardsResponse {
        let response: MyCardsResponse = try await networkManager.post(APIConstants.Endpoints.assignStarterCards, body: EmptyRequest())
        return response
    }
    
    // MARK: - Azure Integration
    
    func getAzureStatus() async throws -> AzureStatusResponse {
        let response: AzureStatusResponse = try await networkManager.get(APIConstants.Endpoints.azureStatus)
        return response
    }
    
    func loadCardsFromAzure(type: CardType?) async throws -> AzureLoadResponse {
        let request = AzureLoadRequest(card_type: type)
        let response: AzureLoadResponse = try await networkManager.post(APIConstants.Endpoints.azureLoadByType, body: request)
        return response
    }
    
    // MARK: - Statistics
    
    func getCardStatistics() async throws -> CardStatisticsResponse {
        let response: CardStatisticsResponse = try await networkManager.get(APIConstants.Endpoints.cardStatistics)
        return response
    }
    
    // MARK: - Winner Card Award
    
    func awardWinnerCard(gameId: Int, userId: Int, cardId: String) async throws -> AwardWinnerCardResponse {
        let request = AwardWinnerCardRequest(game_id: gameId, user_id: userId, card_id: cardId)
        let response: AwardWinnerCardResponse = try await networkManager.post(APIConstants.Endpoints.awardWinnerCard, body: request)
        return response
    }
}

// MARK: - Helper Models

private struct EmptyRequest: Codable {}

// MARK: - Mock Repository for Testing

class MockCardsRepository: CardsRepositoryProtocol {
    var shouldSucceed = true
    var mockCards: [CardResponse] = []
    var mockMyCards: MyCardsResponse?
    
    func getAllCards() async throws -> [CardResponse] {
        if shouldSucceed {
            return mockCards.isEmpty ? generateMockCards() : mockCards
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getMyCards() async throws -> MyCardsResponse {
        if shouldSucceed {
            return mockMyCards ?? MyCardsResponse(
                cards: generateMockCards(),
                total_count: 10,
                starter_cards_count: 3,
                standard_cards_count: 5,
                unique_cards_count: 2
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getCardsByType(_ type: CardType) async throws -> CardsByTypeResponse {
        if shouldSucceed {
            let filteredCards = generateMockCards().filter { $0.card_type == type }
            return CardsByTypeResponse(
                cards: filteredCards,
                total_count: filteredCards.count,
                card_type: type
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getCardsForGameRound() async throws -> GameRoundCardsResponse {
        if shouldSucceed {
            return GameRoundCardsResponse(
                cards: generateMockCards(),
                round_id: 1,
                situation: "Что бы вы сделали в этой ситуации?",
                time_limit: 60
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func assignStarterCards() async throws -> MyCardsResponse {
        if shouldSucceed {
            return MyCardsResponse(
                cards: generateMockCards().filter { $0.card_type == .starter },
                total_count: 3,
                starter_cards_count: 3,
                standard_cards_count: 0,
                unique_cards_count: 0
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getAzureStatus() async throws -> AzureStatusResponse {
        if shouldSucceed {
            return AzureStatusResponse(
                is_loading: false,
                loaded_types: [.starter, .standard],
                total_cards: 100,
                progress_percentage: 75.0
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func loadCardsFromAzure(type: CardType?) async throws -> AzureLoadResponse {
        if shouldSucceed {
            return AzureLoadResponse(
                message: "Cards loaded successfully",
                loaded_cards: 10,
                card_type: type
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getCardStatistics() async throws -> CardStatisticsResponse {
        if shouldSucceed {
            return CardStatisticsResponse(
                total_cards: 100,
                cards_by_type: [
                    CardTypeStatistics(card_type: .starter, count: 20, percentage: 20.0),
                    CardTypeStatistics(card_type: .standard, count: 60, percentage: 60.0),
                    CardTypeStatistics(card_type: .unique, count: 20, percentage: 20.0)
                ],
                unique_cards_percentage: 20.0,
                average_cards_per_user: 15.5
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func awardWinnerCard(gameId: Int, userId: Int, cardId: String) async throws -> AwardWinnerCardResponse {
        if shouldSucceed {
            return AwardWinnerCardResponse(
                awarded: true,
                card: generateMockCards().first,
                message: "Card awarded successfully"
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateMockCards() -> [CardResponse] {
        return [
            CardResponse(
                id: "1",
                name: "Мем 1",
                image_url: "https://example.com/meme1.jpg",
                card_type: .starter,
                is_unique: false,
                description: "Описание мема 1",
                created_at: Date(),
                is_starter_card: true,
                is_standard_card: false,
                is_unique_card: false
            ),
            CardResponse(
                id: "2",
                name: "Мем 2",
                image_url: "https://example.com/meme2.jpg",
                card_type: .standard,
                is_unique: false,
                description: "Описание мема 2",
                created_at: Date(),
                is_starter_card: false,
                is_standard_card: true,
                is_unique_card: false
            ),
            CardResponse(
                id: "3",
                name: "Редкий мем",
                image_url: "https://example.com/rare_meme.jpg",
                card_type: .unique,
                is_unique: true,
                description: "Редкий мем",
                created_at: Date(),
                is_starter_card: false,
                is_standard_card: false,
                is_unique_card: true
            )
        ]
    }
} 