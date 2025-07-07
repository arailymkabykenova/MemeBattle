//
//  CardsRepository.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

protocol CardsRepositoryProtocol {
    func getAllCards() async throws -> [CardResponse]
    func getMyCards() async throws -> [CardResponse]
    func getCardsForGameRound() async throws -> [CardResponse]
    func getCardsByType(type: CardType) async throws -> [CardResponse]
    func assignStarterCards() async throws -> [CardResponse]
    func getCardStatistics() async throws -> CardStatisticsResponse
}

class CardsRepository: CardsRepositoryProtocol {
    private let networkManager: NetworkManagerProtocol
    private let tokenManager: TokenManagerProtocol
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared,
         tokenManager: TokenManagerProtocol = TokenManager.shared) {
        self.networkManager = networkManager
        self.tokenManager = tokenManager
    }
    
    func getAllCards() async throws -> [CardResponse] {
        let response: [CardResponse] = try await networkManager.get(
            endpoint: APIConstants.Endpoints.allCards
        )
        
        return response
    }
    
    func getMyCards() async throws -> [CardResponse] {
        let response: [CardResponse] = try await networkManager.get(
            endpoint: APIConstants.Endpoints.myCards
        )
        
        return response
    }
    
    func getCardsForGameRound() async throws -> [CardResponse] {
        let response: [CardResponse] = try await networkManager.get(
            endpoint: APIConstants.Endpoints.forGameRound
        )
        
        return response
    }
    
    func getCardsByType(type: CardType) async throws -> [CardResponse] {
        let endpoint = APIConstants.Endpoints.cardsByType.replacingOccurrences(of: "{type}", with: type.rawValue)
        let response: [CardResponse] = try await networkManager.get(endpoint: endpoint)
        
        return response
    }
    
    func assignStarterCards() async throws -> [CardResponse] {
        let response: [CardResponse] = try await networkManager.post(
            endpoint: APIConstants.Endpoints.assignStarterCards,
            body: EmptyRequest()
        )
        
        return response
    }
    
    func getCardStatistics() async throws -> CardStatisticsResponse {
        let response: CardStatisticsResponse = try await networkManager.get(
            endpoint: APIConstants.Endpoints.cardStatistics
        )
        
        return response
    }
}

// MARK: - Helper Models

private struct EmptyRequest: Codable {} 