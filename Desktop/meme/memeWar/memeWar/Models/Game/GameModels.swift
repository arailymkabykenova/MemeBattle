//
//  GameModels.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

// Import CardResponse from CardModels
// This will be resolved when CardModels.swift is compiled

// MARK: - Game Models

struct GameResponse: Codable, Identifiable {
    let id: Int
    let room_id: Int
    let status: GameStatus
    let created_at: Date
    let updated_at: Date
    let current_round: Int?
    let total_rounds: Int
    let winner_id: Int?
    let winner_nickname: String?
}

enum GameStatus: String, Codable, CaseIterable {
    case waiting = "waiting"
    case playing = "playing"
    case finished = "finished"
    
    var displayName: String {
        switch self {
        case .waiting:
            return "Ожидание"
        case .playing:
            return "Игра"
        case .finished:
            return "Завершена"
        }
    }
}

// MARK: - Round Models

struct RoundResponse: Codable, Identifiable {
    let id: Int
    let game_id: Int
    let round_number: Int
    let status: RoundStatus
    let situation: String
    let created_at: Date
    let updated_at: Date
    let voting_started_at: Date?
    let voting_ended_at: Date?
    let winner_id: Int?
    let winner_nickname: String?
}

enum RoundStatus: String, Codable, CaseIterable {
    case waiting = "waiting"
    case collecting_choices = "collecting_choices"
    case voting = "voting"
    case finished = "finished"
    
    var displayName: String {
        switch self {
        case .waiting:
            return "Ожидание"
        case .collecting_choices:
            return "Выбор карт"
        case .voting:
            return "Голосование"
        case .finished:
            return "Завершен"
        }
    }
}

// MARK: - Choice Models

struct ChoiceResponse: Codable, Identifiable {
    let id: Int
    let round_id: Int
    let user_id: Int
    let user_nickname: String
    let card_id: String
    let card_name: String
    let card_image_url: String
    let is_anonymous: Bool
    let created_at: Date
}

struct ChoiceRequest: Codable {
    let card_id: String
    let is_anonymous: Bool
}

// MARK: - Vote Models

struct VoteResponse: Codable, Identifiable {
    let id: Int
    let round_id: Int
    let voter_id: Int
    let voter_nickname: String
    let voted_for_id: Int
    let voted_for_nickname: String
    let created_at: Date
}

struct VoteRequest: Codable {
    let voted_for_user_id: Int
}

// MARK: - Round Results

struct RoundResultsResponse: Codable {
    let round: RoundResponse
    let choices: [ChoiceResponse]
    let votes: [VoteResponse]
    let winner: ChoiceResponse?
    let vote_counts: [Int: Int] // user_id: vote_count
}

// MARK: - Game State

struct GameStateResponse: Codable {
    let game: GameResponse
    let current_round: RoundResponse?
    let players: [GamePlayerResponse]
    let my_cards: [CardResponse]
    let round_choices: [ChoiceResponse]?
    let round_votes: [VoteResponse]?
    let time_remaining: Int? // seconds
}

struct GamePlayerResponse: Codable, Identifiable {
    let id: Int
    let nickname: String
    let is_ready: Bool
    let has_submitted_choice: Bool
    let has_voted: Bool
    let is_winner: Bool?
}

// MARK: - Game Requests

struct CreateRoundRequest: Codable {
    let game_id: Int
}

struct StartVotingRequest: Codable {
    let round_id: Int
}

// MARK: - Game Statistics

struct GameStatsResponse: Codable {
    let total_games: Int
    let games_won: Int
    let games_lost: Int
    let total_rounds: Int
    let rounds_won: Int
    let average_rating: Double
    let best_score: Int
}

// MARK: - WebSocket Game Events

struct GameEvent: Codable {
    let type: GameEventType
    let data: [String: Any]
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case type
        case data
        case timestamp
    }
    
    init(type: GameEventType, data: [String: Any] = [:]) {
        self.type = type
        self.data = data
        self.timestamp = Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(GameEventType.self, forKey: .type)
        
        // Decode data as JSON and convert to [String: Any]
        let jsonData = try container.decode(Data.self, forKey: .data)
        if let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            data = jsonObject
        } else {
            data = [:]
        }
        
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        // Convert [String: Any] to JSON Data
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        try container.encode(jsonData, forKey: .data)
        
        try container.encode(timestamp, forKey: .timestamp)
    }
}

enum GameEventType: String, Codable, CaseIterable {
    case gameStarted = "game_started"
    case roundStarted = "round_started"
    case choiceSubmitted = "choice_submitted"
    case votingStarted = "voting_started"
    case voteSubmitted = "vote_submitted"
    case roundEnded = "round_ended"
    case gameEnded = "game_ended"
    case playerJoined = "player_joined"
    case playerLeft = "player_left"
    case timeoutWarning = "timeout_warning"
    case playerTimeout = "player_timeout"
} 