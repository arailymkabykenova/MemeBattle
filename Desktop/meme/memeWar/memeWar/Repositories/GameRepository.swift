//
//  GameRepository.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

protocol GameRepositoryProtocol {
    func getMyCardsForGame() async throws -> [CardResponse]
    func generateSituations() async throws -> [String]
    func getCurrentGame(roomId: Int) async throws -> GameResponse?
    func getGameDetails(gameId: Int) async throws -> GameResponse
    func createRound(gameId: Int) async throws -> RoundResponse
    func submitChoice(roundId: Int, request: ChoiceRequest) async throws -> ChoiceResponse
    func startVoting(roundId: Int) async throws
    func submitVote(roundId: Int, request: VoteRequest) async throws -> VoteResponse
    func getRoundResults(roundId: Int) async throws -> RoundResultsResponse
    func getRoundChoices(roundId: Int) async throws -> [ChoiceResponse]
    func endGame(gameId: Int) async throws -> GameResponse
    func getGameState(roomId: Int) async throws -> GameStateResponse
}

class GameRepository: GameRepositoryProtocol {
    private let networkManager: NetworkManagerProtocol
    private let tokenManager: TokenManagerProtocol
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared,
         tokenManager: TokenManagerProtocol = TokenManager.shared) {
        self.networkManager = networkManager
        self.tokenManager = tokenManager
    }
    
    // MARK: - Game Setup
    
    func getMyCardsForGame() async throws -> [CardResponse] {
        let response: [CardResponse] = try await networkManager.get(
            endpoint: APIConstants.Endpoints.myCardsForGame
        )
        
        return response
    }
    
    func generateSituations() async throws -> [String] {
        let response: [String] = try await networkManager.post(
            endpoint: APIConstants.Endpoints.generateSituations,
            body: EmptyRequest()
        )
        
        return response
    }
    
    // MARK: - Game State
    
    func getCurrentGame(roomId: Int) async throws -> GameResponse? {
        let endpoint = APIConstants.Endpoints.currentGame.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let response: GameResponse? = try await networkManager.get(endpoint: endpoint)
        
        return response
    }
    
    func getGameDetails(gameId: Int) async throws -> GameResponse {
        let endpoint = APIConstants.Endpoints.gameDetails.replacingOccurrences(of: "{game_id}", with: "\(gameId)")
        let response: GameResponse = try await networkManager.get(endpoint: endpoint)
        
        return response
    }
    
    // MARK: - Round Management
    
    func createRound(gameId: Int) async throws -> RoundResponse {
        let endpoint = APIConstants.Endpoints.createRound.replacingOccurrences(of: "{game_id}", with: "\(gameId)")
        let response: RoundResponse = try await networkManager.post(
            endpoint: endpoint,
            body: EmptyRequest()
        )
        
        return response
    }
    
    // MARK: - Card Choices
    
    func submitChoice(roundId: Int, request: ChoiceRequest) async throws -> ChoiceResponse {
        let endpoint = APIConstants.Endpoints.submitChoice.replacingOccurrences(of: "{round_id}", with: "\(roundId)")
        let response: ChoiceResponse = try await networkManager.post(
            endpoint: endpoint,
            body: request
        )
        
        return response
    }
    
    func getRoundChoices(roundId: Int) async throws -> [ChoiceResponse] {
        let endpoint = APIConstants.Endpoints.roundChoices.replacingOccurrences(of: "{round_id}", with: "\(roundId)")
        let response: [ChoiceResponse] = try await networkManager.get(endpoint: endpoint)
        
        return response
    }
    
    // MARK: - Voting
    
    func startVoting(roundId: Int) async throws {
        let endpoint = APIConstants.Endpoints.startVoting.replacingOccurrences(of: "{round_id}", with: "\(roundId)")
        try await networkManager.post(
            endpoint: endpoint,
            body: EmptyRequest()
        )
    }
    
    func submitVote(roundId: Int, request: VoteRequest) async throws -> VoteResponse {
        let endpoint = APIConstants.Endpoints.submitVote.replacingOccurrences(of: "{round_id}", with: "\(roundId)")
        let response: VoteResponse = try await networkManager.post(
            endpoint: endpoint,
            body: request
        )
        
        return response
    }
    
    func getRoundResults(roundId: Int) async throws -> RoundResultsResponse {
        let endpoint = APIConstants.Endpoints.roundResults.replacingOccurrences(of: "{round_id}", with: "\(roundId)")
        let response: RoundResultsResponse = try await networkManager.get(endpoint: endpoint)
        
        return response
    }
    
    // MARK: - Game Management
    
    func endGame(gameId: Int) async throws -> GameResponse {
        let endpoint = APIConstants.Endpoints.endGame.replacingOccurrences(of: "{game_id}", with: "\(gameId)")
        let response: GameResponse = try await networkManager.post(
            endpoint: endpoint,
            body: EmptyRequest()
        )
        
        return response
    }
    
    // MARK: - Room Management
    
    func getGameState(roomId: Int) async throws -> GameStateResponse {
        let endpoint = APIConstants.Endpoints.pingRoom.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let response: GameStateResponse = try await networkManager.get(endpoint: endpoint)
        
        return response
    }
}

// MARK: - Helper Models

private struct EmptyRequest: Codable {}

// MARK: - Mock Repository for Testing

class MockGameRepository: GameRepositoryProtocol {
    var shouldSucceed = true
    var mockGame: GameResponse?
    var mockCards: [CardResponse] = []
    var mockSituations: [String] = []
    
    func getMyCardsForGame() async throws -> [CardResponse] {
        if shouldSucceed {
            return mockCards
        } else {
            throw NetworkError.serverError
        }
    }
    
    func generateSituations() async throws -> [String] {
        if shouldSucceed {
            return mockSituations
        } else {
            throw NetworkError.serverError
        }
    }
    
    func getCurrentGame(roomId: Int) async throws -> GameResponse? {
        if shouldSucceed {
            return mockGame
        } else {
            throw NetworkError.serverError
        }
    }
    
    func getGameDetails(gameId: Int) async throws -> GameResponse {
        if shouldSucceed {
            return mockGame ?? generateMockGameDetails(gameId: gameId)
        } else {
            throw NetworkError.serverError
        }
    }
    
    func createRound(gameId: Int) async throws -> RoundResponse {
        if shouldSucceed {
            return RoundResponse(
                id: 1,
                game_id: gameId,
                round_number: 1,
                status: .waiting,
                situation: "Test situation",
                created_at: Date(),
                updated_at: Date(),
                voting_started_at: nil,
                voting_ended_at: nil,
                winner_id: nil,
                winner_nickname: nil
            )
        } else {
            throw NetworkError.serverError
        }
    }
    
    func submitChoice(roundId: Int, request: ChoiceRequest) async throws -> ChoiceResponse {
        if shouldSucceed {
            return ChoiceResponse(
                id: 1,
                round_id: roundId,
                user_id: 1,
                user_nickname: "Player1",
                card_id: request.card_id,
                card_name: "Test Card",
                card_image_url: "https://example.com/card.jpg",
                is_anonymous: request.is_anonymous,
                created_at: Date()
            )
        } else {
            throw NetworkError.serverError
        }
    }
    
    func getRoundChoices(roundId: Int) async throws -> [ChoiceResponse] {
        if shouldSucceed {
            return [
                ChoiceResponse(
                    id: 1,
                    round_id: roundId,
                    user_id: 1,
                    user_nickname: "Player1",
                    card_id: "card1",
                    card_name: "Test Card 1",
                    card_image_url: "https://example.com/card1.jpg",
                    is_anonymous: false,
                    created_at: Date()
                ),
                ChoiceResponse(
                    id: 2,
                    round_id: roundId,
                    user_id: 2,
                    user_nickname: "Player2",
                    card_id: "card2",
                    card_name: "Test Card 2",
                    card_image_url: "https://example.com/card2.jpg",
                    is_anonymous: false,
                    created_at: Date()
                )
            ]
        } else {
            throw NetworkError.serverError
        }
    }
    
    func startVoting(roundId: Int) async throws {
        if shouldSucceed {
            // Implementation of startVoting
        } else {
            throw NetworkError.serverError
        }
    }
    
    func submitVote(roundId: Int, request: VoteRequest) async throws -> VoteResponse {
        if shouldSucceed {
            return VoteResponse(
                id: 1,
                round_id: roundId,
                voter_id: 1,
                voter_nickname: "Player1",
                voted_for_id: request.voted_for_user_id,
                voted_for_nickname: "Player2",
                created_at: Date()
            )
        } else {
            throw NetworkError.serverError
        }
    }
    
    func getRoundResults(roundId: Int) async throws -> RoundResultsResponse {
        if shouldSucceed {
            return RoundResultsResponse(
                round: RoundResponse(
                    id: roundId,
                    game_id: 1,
                    round_number: 1,
                    status: .finished,
                    situation: "Test situation",
                    created_at: Date(),
                    updated_at: Date(),
                    voting_started_at: Date(),
                    voting_ended_at: Date(),
                    winner_id: 2,
                    winner_nickname: "Player2"
                ),
                choices: [],
                votes: [],
                winner: nil,
                vote_counts: [1: 0, 2: 1]
            )
        } else {
            throw NetworkError.serverError
        }
    }
    
    func endGame(gameId: Int) async throws -> GameResponse {
        if shouldSucceed {
            return GameResponse(
                id: gameId,
                room_id: 1,
                status: .finished,
                created_at: Date(),
                updated_at: Date(),
                current_round: 3,
                total_rounds: 3,
                winner_id: 1,
                winner_nickname: "Player1"
            )
        } else {
            throw NetworkError.serverError
        }
    }
    
    func getGameState(roomId: Int) async throws -> GameStateResponse {
        if shouldSucceed {
            return GameStateResponse(
                game: GameResponse(
                    id: 1,
                    room_id: roomId,
                    status: .playing,
                    created_at: Date(),
                    updated_at: Date(),
                    current_round: 1,
                    total_rounds: 3,
                    winner_id: nil,
                    winner_nickname: nil
                ),
                current_round: RoundResponse(
                    id: 1,
                    game_id: 1,
                    round_number: 1,
                    status: .collecting_choices,
                    situation: "Test situation",
                    created_at: Date(),
                    updated_at: Date(),
                    voting_started_at: nil,
                    voting_ended_at: nil,
                    winner_id: nil,
                    winner_nickname: nil
                ),
                players: [
                    GamePlayerResponse(
                        id: 1,
                        nickname: "Player1",
                        is_ready: true,
                        has_submitted_choice: false,
                        has_voted: false,
                        is_winner: nil
                    ),
                    GamePlayerResponse(
                        id: 2,
                        nickname: "Player2",
                        is_ready: true,
                        has_submitted_choice: false,
                        has_voted: false,
                        is_winner: nil
                    )
                ],
                my_cards: [],
                round_choices: nil,
                round_votes: nil,
                time_remaining: 60
            )
        } else {
            throw NetworkError.serverError
        }
    }
    
    private func generateMockGameDetails(gameId: Int) -> GameResponse {
        return GameResponse(
            id: gameId,
            room_id: 1,
            status: .playing,
            created_at: Date(),
            updated_at: Date(),
            current_round: 1,
            total_rounds: 3,
            winner_id: nil,
            winner_nickname: nil
        )
    }
} 