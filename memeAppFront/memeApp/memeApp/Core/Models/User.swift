import Foundation
import SwiftUI
import GameKit
import os
// import struct memeApp.Constants
// import struct memeApp.MainView

// Модель ответа аутентификации
struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let user: User
    let is_new_user: Bool
}

struct User: Codable {
    let id: Int
    let device_id: String
    let nickname: String?
    let birth_date: String?
    let gender: String?
    let rating: Double
    let created_at: String
    let last_seen: String?
    let statistics: UserStatistics?
    
    // Computed property для проверки завершенности профиля
    var isProfileComplete: Bool {
        return nickname != nil && birth_date != nil && gender != nil
    }
}

struct UserStatistics: Codable {
    let games_played: Int
    let games_won: Int
    let total_score: Int
    let cards_collected: Int
    let unique_cards: Int
    
    var winRate: Double {
        guard games_played > 0 else { return 0.0 }
        return Double(games_won) / Double(games_played) * 100.0
    }
}

enum AgeGroup: String, CaseIterable, Codable {
    case child = "child"
    case teen = "teen"
    case adult = "adult"
    case mixed = "mixed"
    
    var displayName: String {
        switch self {
        case .child:
            return "Дети (6-12 лет)"
        case .teen:
            return "Подростки (13-17 лет)"
        case .adult:
            return "Взрослые (18+)"
        case .mixed:
            return "Смешанная группа"
        }
    }
    
    var minAge: Int {
        switch self {
        case .child:
            return 6
        case .teen:
            return 13
        case .adult:
            return 18
        case .mixed:
            return 6
        }
    }
    
    var maxAge: Int {
        switch self {
        case .child:
            return 12
        case .teen:
            return 17
        case .adult:
            return 999
        case .mixed:
            return 999
        }
    }
} 