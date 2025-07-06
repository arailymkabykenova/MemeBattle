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
    func getCurrentGame(roomId: Int) async throws -> GameDetailResponse?
    func getGameDetails(gameId: Int) async throws -> GameDetailResponse
    func createRound(gameId: Int) async throws -> RoundResponse
    func submitChoice(roundId: Int, cardId: String, isAnonymous: Bool) async throws -> SubmitChoiceResponse
    func startVoting(roundId: Int) async throws -> StartVotingResponse
    func submitVote(roundId: Int, votedForUserId: Int) async throws -> SubmitVoteResponse
    func getRoundResults(roundId: Int) async throws -> RoundResultResponse
    func getRoundChoices(roundId: Int) async throws -> [CardChoiceResponse]
    func endGame(gameId: Int) async throws -> EndGameResponse
    func pingRoom(roomId: Int) async throws -> SuccessResponse
    func getPlayersStatus(roomId: Int) async throws -> [GamePlayerResponse]
    func checkTimeouts(roomId: Int) async throws -> [String]
    func getActionStatus(roundId: Int) async throws -> GameState
}

class GameRepository: GameRepositoryProtocol {
    private let networkManager = NetworkManager.shared
    
    // MARK: - Game Setup
    
    func getMyCardsForGame() async throws -> [CardResponse] {
        let response: [CardResponse] = try await networkManager.get(APIConstants.Endpoints.myCardsForGame)
        return response
    }
    
    func generateSituations() async throws -> [String] {
        let response: [String] = try await networkManager.post(APIConstants.Endpoints.generateSituations, body: EmptyRequest())
        return response
    }
    
    // MARK: - Game State
    
    func getCurrentGame(roomId: Int) async throws -> GameDetailResponse? {
        let endpoint = APIConstants.Endpoints.currentGame.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let response: GameDetailResponse? = try await networkManager.get(endpoint)
        return response
    }
    
    func getGameDetails(gameId: Int) async throws -> GameDetailResponse {
        let endpoint = APIConstants.Endpoints.gameDetails.replacingOccurrences(of: "{game_id}", with: "\(gameId)")
        let response: GameDetailResponse = try await networkManager.get(endpoint)
        return response
    }
    
    // MARK: - Round Management
    
    func createRound(gameId: Int) async throws -> RoundResponse {
        let endpoint = APIConstants.Endpoints.createRound.replacingOccurrences(of: "{game_id}", with: "\(gameId)")
        let response: RoundResponse = try await networkManager.post(endpoint, body: EmptyRequest())
        return response
    }
    
    // MARK: - Card Choices
    
    func submitChoice(roundId: Int, cardId: String, isAnonymous: Bool) async throws -> SubmitChoiceResponse {
        let endpoint = APIConstants.Endpoints.submitChoice.replacingOccurrences(of: "{round_id}", with: "\(roundId)")
        let request = SubmitChoiceRequest(card_id: cardId, is_anonymous: isAnonymous)
        let response: SubmitChoiceResponse = try await networkManager.post(endpoint, body: request)
        return response
    }
    
    func getRoundChoices(roundId: Int) async throws -> [CardChoiceResponse] {
        let endpoint = APIConstants.Endpoints.roundChoices.replacingOccurrences(of: "{round_id}", with: "\(roundId)")
        let response: [CardChoiceResponse] = try await networkManager.get(endpoint)
        return response
    }
    
    // MARK: - Voting
    
    func startVoting(roundId: Int) async throws -> StartVotingResponse {
        let endpoint = APIConstants.Endpoints.startVoting.replacingOccurrences(of: "{round_id}", with: "\(roundId)")
        let request = StartVotingRequest(round_id: roundId)
        let response: StartVotingResponse = try await networkManager.post(endpoint, body: request)
        return response
    }
    
    func submitVote(roundId: Int, votedForUserId: Int) async throws -> SubmitVoteResponse {
        let endpoint = APIConstants.Endpoints.submitVote.replacingOccurrences(of: "{round_id}", with: "\(roundId)")
        let request = SubmitVoteRequest(voted_for_user_id: votedForUserId)
        let response: SubmitVoteResponse = try await networkManager.post(endpoint, body: request)
        return response
    }
    
    func getRoundResults(roundId: Int) async throws -> RoundResultResponse {
        let endpoint = APIConstants.Endpoints.roundResults.replacingOccurrences(of: "{round_id}", with: "\(roundId)")
        let response: RoundResultResponse = try await networkManager.get(endpoint)
        return response
    }
    
    // MARK: - Game Management
    
    func endGame(gameId: Int) async throws -> EndGameResponse {
        let endpoint = APIConstants.Endpoints.endGame.replacingOccurrences(of: "{game_id}", with: "\(gameId)")
        let request = EndGameRequest(game_id: gameId)
        let response: EndGameResponse = try await networkManager.post(endpoint, body: request)
        return response
    }
    
    // MARK: - Room Management
    
    func pingRoom(roomId: Int) async throws -> SuccessResponse {
        let endpoint = APIConstants.Endpoints.pingRoom.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let response: SuccessResponse = try await networkManager.post(endpoint, body: EmptyRequest())
        return response
    }
    
    func getPlayersStatus(roomId: Int) async throws -> [GamePlayerResponse] {
        let endpoint = APIConstants.Endpoints.playersStatus.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let response: [GamePlayerResponse] = try await networkManager.get(endpoint)
        return response
    }
    
    func checkTimeouts(roomId: Int) async throws -> [String] {
        let endpoint = APIConstants.Endpoints.checkTimeouts.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let response: [String] = try await networkManager.get(endpoint)
        return response
    }
    
    func getActionStatus(roundId: Int) async throws -> GameState {
        let endpoint = APIConstants.Endpoints.actionStatus.replacingOccurrences(of: "{round_id}", with: "\(roundId)")
        let response: GameState = try await networkManager.get(endpoint)
        return response
    }
}

// MARK: - Helper Models

private struct EmptyRequest: Codable {}

// MARK: - Mock Repository for Testing

class MockGameRepository: GameRepositoryProtocol {
    var shouldSucceed = true
    var mockGame: GameDetailResponse?
    var mockCards: [CardResponse] = []
    var mockSituations: [String] = []
    
    func getMyCardsForGame() async throws -> [CardResponse] {
        if shouldSucceed {
            return mockCards.isEmpty ? generateMockCards() : mockCards
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func generateSituations() async throws -> [String] {
        if shouldSucceed {
            return mockSituations.isEmpty ? generateMockSituations() : mockSituations
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getCurrentGame(roomId: Int) async throws -> GameDetailResponse? {
        if shouldSucceed {
            return mockGame
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getGameDetails(gameId: Int) async throws -> GameDetailResponse {
        if shouldSucceed {
            return mockGame ?? generateMockGameDetails(gameId: gameId)
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func createRound(gameId: Int) async throws -> RoundResponse {
        if shouldSucceed {
            return RoundResponse(
                id: Int.random(in: 1...1000),
                game_id: gameId,
                round_number: 1,
                status: .choosing,
                situation: "Что бы вы сделали в этой ситуации?",
                time_limit: 60,
                started_at: Date(),
                finished_at: nil,
                winner_id: nil,
                winner_nickname: nil,
                winning_card_id: nil,
                winning_card_name: nil
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func submitChoice(roundId: Int, cardId: String, isAnonymous: Bool) async throws -> SubmitChoiceResponse {
        if shouldSucceed {
            let choice = CardChoiceResponse(
                id: Int.random(in: 1...1000),
                round_id: roundId,
                user_id: 1,
                user_nickname: "Player1",
                card_id: cardId,
                card_name: "Test Card",
                card_image_url: "https://example.com/card.jpg",
                submitted_at: Date(),
                is_anonymous: isAnonymous
            )
            
            return SubmitChoiceResponse(
                choice: choice,
                message: "Choice submitted successfully",
                submitted: true
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getRoundChoices(roundId: Int) async throws -> [CardChoiceResponse] {
        if shouldSucceed {
            return [
                CardChoiceResponse(
                    id: 1,
                    round_id: roundId,
                    user_id: 1,
                    user_nickname: "Player1",
                    card_id: "1",
                    card_name: "Card 1",
                    card_image_url: "https://example.com/card1.jpg",
                    submitted_at: Date(),
                    is_anonymous: false
                ),
                CardChoiceResponse(
                    id: 2,
                    round_id: roundId,
                    user_id: 2,
                    user_nickname: "Player2",
                    card_id: "2",
                    card_name: "Card 2",
                    card_image_url: "https://example.com/card2.jpg",
                    submitted_at: Date(),
                    is_anonymous: true
                )
            ]
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func startVoting(roundId: Int) async throws -> StartVotingResponse {
        if shouldSucceed {
            let choices = try await getRoundChoices(roundId: roundId)
            return StartVotingResponse(
                message: "Voting started successfully",
                voting_started: true,
                choices: choices
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func submitVote(roundId: Int, votedForUserId: Int) async throws -> SubmitVoteResponse {
        if shouldSucceed {
            let vote = VoteResponse(
                id: Int.random(in: 1...1000),
                round_id: roundId,
                voter_id: 1,
                voter_nickname: "Player1",
                voted_for_user_id: votedForUserId,
                voted_for_nickname: "Player2",
                voted_at: Date()
            )
            
            return SubmitVoteResponse(
                vote: vote,
                message: "Vote submitted successfully",
                submitted: true
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getRoundResults(roundId: Int) async throws -> RoundResultResponse {
        if shouldSucceed {
            return RoundResultResponse(
                round_id: roundId,
                winner_id: 2,
                winner_nickname: "Player2",
                winning_card_id: "2",
                winning_card_name: "Card 2",
                winning_card_image_url: "https://example.com/card2.jpg",
                total_votes: 3,
                vote_breakdown: [
                    VoteBreakdown(user_id: 1, nickname: "Player1", votes_received: 0, percentage: 0.0),
                    VoteBreakdown(user_id: 2, nickname: "Player2", votes_received: 3, percentage: 100.0)
                ],
                points_awarded: 10
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func endGame(gameId: Int) async throws -> EndGameResponse {
        if shouldSucceed {
            return EndGameResponse(
                message: "Game ended successfully",
                game_ended: true,
                winner: GamePlayerResponse(
                    id: 1,
                    user_id: 1,
                    nickname: "Player1",
                    score: 30,
                    cards_played: 3,
                    votes_received: 5,
                    is_winner: true,
                    joined_at: Date()
                ),
                final_scores: [
                    PlayerScore(user_id: 1, nickname: "Player1", final_score: 30, rank: 1),
                    PlayerScore(user_id: 2, nickname: "Player2", final_score: 20, rank: 2)
                ]
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func pingRoom(roomId: Int) async throws -> SuccessResponse {
        if shouldSucceed {
            return SuccessResponse(message: "Ping successful", success: true)
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getPlayersStatus(roomId: Int) async throws -> [GamePlayerResponse] {
        if shouldSucceed {
            return [
                GamePlayerResponse(
                    id: 1,
                    user_id: 1,
                    nickname: "Player1",
                    score: 10,
                    cards_played: 1,
                    votes_received: 2,
                    is_winner: false,
                    joined_at: Date()
                ),
                GamePlayerResponse(
                    id: 2,
                    user_id: 2,
                    nickname: "Player2",
                    score: 15,
                    cards_played: 1,
                    votes_received: 1,
                    is_winner: false,
                    joined_at: Date()
                )
            ]
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func checkTimeouts(roomId: Int) async throws -> [String] {
        if shouldSucceed {
            return []
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getActionStatus(roundId: Int) async throws -> GameState {
        if shouldSucceed {
            return GameState(
                game: GameResponse(
                    id: 1,
                    room_id: 1,
                    status: .playing,
                    current_round: 1,
                    total_rounds: 3,
                    created_at: Date(),
                    started_at: Date(),
                    finished_at: nil,
                    winner_id: nil,
                    winner_nickname: nil
                ),
                current_round: RoundResponse(
                    id: roundId,
                    game_id: 1,
                    round_number: 1,
                    status: .choosing,
                    situation: "Test situation",
                    time_limit: 60,
                    started_at: Date(),
                    finished_at: nil,
                    winner_id: nil,
                    winner_nickname: nil,
                    winning_card_id: nil,
                    winning_card_name: nil
                ),
                my_cards: generateMockCards(),
                round_choices: [],
                round_votes: [],
                round_results: nil,
                time_remaining: 45,
                can_submit_choice: true,
                can_vote: false,
                can_start_voting: false,
                can_end_game: false
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
            )
        ]
    }
    
    private func generateMockSituations() -> [String] {
        return [
            "Что бы вы сделали, если бы встретили инопланетянина?",
            "Как бы вы отреагировали на внезапное богатство?",
            "Что бы вы сказали президенту за ужином?",
            "Как бы вы провели последний день на Земле?",
            "Что бы вы сделали с машиной времени?"
        ]
    }
    
    private func generateMockGameDetails(gameId: Int) -> GameDetailResponse {
        let game = GameResponse(
            id: gameId,
            room_id: 1,
            status: .playing,
            current_round: 1,
            total_rounds: 3,
            created_at: Date(),
            started_at: Date(),
            finished_at: nil,
            winner_id: nil,
            winner_nickname: nil
        )
        
        let players = [
            GamePlayerResponse(
                id: 1,
                user_id: 1,
                nickname: "Player1",
                score: 10,
                cards_played: 1,
                votes_received: 2,
                is_winner: false,
                joined_at: Date()
            ),
            GamePlayerResponse(
                id: 2,
                user_id: 2,
                nickname: "Player2",
                score: 15,
                cards_played: 1,
                votes_received: 1,
                is_winner: false,
                joined_at: Date()
            )
        ]
        
        let currentRound = RoundResponse(
            id: 1,
            game_id: gameId,
            round_number: 1,
            status: .choosing,
            situation: "Что бы вы сделали в этой ситуации?",
            time_limit: 60,
            started_at: Date(),
            finished_at: nil,
            winner_id: nil,
            winner_nickname: nil,
            winning_card_id: nil,
            winning_card_name: nil
        )
        
        return GameDetailResponse(
            game: game,
            players: players,
            current_round: currentRound,
            rounds: [currentRound],
            winner: nil
        )
    }
} 