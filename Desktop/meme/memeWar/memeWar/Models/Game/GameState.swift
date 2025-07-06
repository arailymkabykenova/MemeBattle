//
//  GameState.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

// Import CardResponse from CardModels
// This will be resolved when CardModels.swift is compiled

// MARK: - Game Status

enum GameStatus: String, Codable, CaseIterable {
    case waiting = "waiting"
    case playing = "playing"
    case voting = "voting"
    case finished = "finished"
    
    var displayName: String {
        switch self {
        case .waiting:
            return "Ожидание"
        case .playing:
            return "Игра"
        case .voting:
            return "Голосование"
        case .finished:
            return "Завершена"
        }
    }
}

// MARK: - Round Status

enum RoundStatus: String, Codable, CaseIterable {
    case waiting = "waiting"
    case choosing = "choosing"
    case voting = "voting"
    case finished = "finished"
    
    var displayName: String {
        switch self {
        case .waiting:
            return "Ожидание"
        case .choosing:
            return "Выбор карты"
        case .voting:
            return "Голосование"
        case .finished:
            return "Завершен"
        }
    }
}

// MARK: - Game Models

struct GameResponse: Codable, Identifiable {
    let id: Int
    let room_id: Int
    let status: GameStatus
    let current_round: Int?
    let total_rounds: Int
    let created_at: Date
    let started_at: Date?
    let finished_at: Date?
    let winner_id: Int?
    let winner_nickname: String?
}

struct GameDetailResponse: Codable {
    let game: GameResponse
    let players: [GamePlayerResponse]
    let current_round: RoundResponse?
    let rounds: [RoundResponse]
    let winner: GamePlayerResponse?
}

struct GamePlayerResponse: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let nickname: String
    let score: Int
    let cards_played: Int
    let votes_received: Int
    let is_winner: Bool
    let joined_at: Date
}

// MARK: - Round Models

struct RoundResponse: Codable, Identifiable {
    let id: Int
    let game_id: Int
    let round_number: Int
    let status: RoundStatus
    let situation: String
    let time_limit: TimeInterval
    let started_at: Date?
    let finished_at: Date?
    let winner_id: Int?
    let winner_nickname: String?
    let winning_card_id: String?
    let winning_card_name: String?
}

struct RoundDetailResponse: Codable {
    let round: RoundResponse
    let choices: [CardChoiceResponse]
    let votes: [VoteResponse]
    let results: RoundResultResponse?
}

// MARK: - Card Choice Models

struct CardChoiceResponse: Codable, Identifiable {
    let id: Int
    let round_id: Int
    let user_id: Int
    let user_nickname: String
    let card_id: String
    let card_name: String
    let card_image_url: String
    let submitted_at: Date
    let is_anonymous: Bool
}

struct SubmitChoiceRequest: Codable {
    let card_id: String
    let is_anonymous: Bool
}

struct SubmitChoiceResponse: Codable {
    let choice: CardChoiceResponse
    let message: String
    let submitted: Bool
}

// MARK: - Voting Models

struct VoteResponse: Codable, Identifiable {
    let id: Int
    let round_id: Int
    let voter_id: Int
    let voter_nickname: String
    let voted_for_user_id: Int
    let voted_for_nickname: String
    let voted_at: Date
}

struct SubmitVoteRequest: Codable {
    let voted_for_user_id: Int
}

struct SubmitVoteResponse: Codable {
    let vote: VoteResponse
    let message: String
    let submitted: Bool
}

// MARK: - Round Results

struct RoundResultResponse: Codable {
    let round_id: Int
    let winner_id: Int
    let winner_nickname: String
    let winning_card_id: String
    let winning_card_name: String
    let winning_card_image_url: String
    let total_votes: Int
    let vote_breakdown: [VoteBreakdown]
    let points_awarded: Int
}

struct VoteBreakdown: Codable {
    let user_id: Int
    let nickname: String
    let votes_received: Int
    let percentage: Double
}

// MARK: - Game Actions

struct StartVotingRequest: Codable {
    let round_id: Int
}

struct StartVotingResponse: Codable {
    let message: String
    let voting_started: Bool
    let choices: [CardChoiceResponse]
}

struct EndGameRequest: Codable {
    let game_id: Int
}

struct EndGameResponse: Codable {
    let message: String
    let game_ended: Bool
    let winner: GamePlayerResponse?
    let final_scores: [PlayerScore]
}

struct PlayerScore: Codable {
    let user_id: Int
    let nickname: String
    let final_score: Int
    let rank: Int
}

// MARK: - Game State Management

struct GameState: Codable {
    let game: GameResponse
    let current_round: RoundResponse?
    let my_cards: [CardResponse]
    let round_choices: [CardChoiceResponse]
    let round_votes: [VoteResponse]
    let round_results: RoundResultResponse?
    let time_remaining: TimeInterval?
    let can_submit_choice: Bool
    let can_vote: Bool
    let can_start_voting: Bool
    let can_end_game: Bool
}

// MARK: - Game Extensions

extension GameResponse {
    var isActive: Bool {
        return status == .playing || status == .voting
    }
    
    var isFinished: Bool {
        return status == .finished
    }
    
    var duration: TimeInterval? {
        guard let started = started_at else { return nil }
        let end = finished_at ?? Date()
        return end.timeIntervalSince(started)
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "N/A" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progressPercentage: Double {
        guard total_rounds > 0 else { return 0 }
        return Double(current_round ?? 0) / Double(total_rounds)
    }
}

extension RoundResponse {
    var isActive: Bool {
        return status == .choosing || status == .voting
    }
    
    var timeRemaining: TimeInterval? {
        guard let started = started_at else { return nil }
        let elapsed = Date().timeIntervalSince(started)
        return max(0, time_limit - elapsed)
    }
    
    var formattedTimeRemaining: String {
        guard let remaining = timeRemaining else { return "N/A" }
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension GamePlayerResponse {
    var isCurrentUser: Bool {
        // This should be compared with current user ID
        return false // Placeholder
    }
    
    var scoreDisplay: String {
        return "\(score) очков"
    }
    
    var cardsPlayedDisplay: String {
        return "\(cards_played) карт"
    }
    
    var votesReceivedDisplay: String {
        return "\(votes_received) голосов"
    }
} 