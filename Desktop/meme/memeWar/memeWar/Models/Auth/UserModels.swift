//
//  UserModels.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

// MARK: - User Models

enum Gender: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .male:
            return "Мужской"
        case .female:
            return "Женский"
        case .other:
            return "Другой"
        }
    }
}

struct UserResponse: Codable {
    let id: Int
    let device_id: String
    let nickname: String?
    let birth_date: Date?
    let gender: Gender?
    let rating: Double
    let created_at: Date
    let age: Int?
    let is_profile_complete: Bool
}

struct UserProfileCreate: Codable {
    let nickname: String
    let birth_date: Date
    let gender: Gender
}

struct UserProfileUpdate: Codable {
    let nickname: String?
    let birth_date: Date?
    let gender: Gender?
}

struct UserStats: Codable {
    let games_played: Int
    let games_won: Int
    let total_score: Int
    let average_score: Double
    let cards_collected: Int
    let unique_cards: Int
    let win_rate: Double
    let rank: Int?
    let total_players: Int?
}

struct LeaderboardEntry: Codable, Identifiable {
    let id: Int
    let nickname: String
    let rating: Double
    let rank: Int
    let games_played: Int
    let games_won: Int
    let win_rate: Double
}

struct LeaderboardResponse: Codable {
    let players: [LeaderboardEntry]
    let total_count: Int
    let current_page: Int
    let total_pages: Int
}

// MARK: - User Validation Models

struct NicknameCheckRequest: Codable {
    let nickname: String
}

struct NicknameCheckResponse: Codable {
    let available: Bool
    let message: String?
}

// MARK: - Rating Models

struct RatingUpdateRequest: Codable {
    let rating: Double
}

struct RatingUpdateResponse: Codable {
    let new_rating: Double
    let rating_change: Double
    let rank: Int?
    let total_players: Int?
}

// MARK: - User Extensions

extension UserResponse {
    var displayName: String {
        return nickname ?? "Игрок \(id)"
    }
    
    var ageDisplay: String {
        if let age = age {
            return "\(age) лет"
        }
        return "Не указан"
    }
    
    var genderDisplay: String {
        return gender?.displayName ?? "Не указан"
    }
    
    var isProfileComplete: Bool {
        return is_profile_complete
    }
}

extension LeaderboardEntry {
    var winRateDisplay: String {
        return String(format: "%.1f%%", win_rate * 100)
    }
    
    var rankDisplay: String {
        return "#\(rank)"
    }
} 