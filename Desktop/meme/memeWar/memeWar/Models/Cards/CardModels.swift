//
//  CardModels.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

// MARK: - Card Type Enum

enum CardType: String, Codable, CaseIterable {
    case all = "all"
    case starter = "starter"
    case standard = "standard"
    case unique = "unique"
    
    var displayName: String {
        switch self {
        case .all:
            return "Все"
        case .starter:
            return "Стартовые"
        case .standard:
            return "Обычные"
        case .unique:
            return "Уникальные"
        }
    }
    
    var description: String {
        switch self {
        case .starter:
            return "Базовые карточки для начала игры"
        case .standard:
            return "Обычные карточки из коллекции"
        case .unique:
            return "Редкие и уникальные карточки"
        }
    }
}

// MARK: - Card Response

struct CardResponse: Codable, Identifiable {
    let id: String
    let name: String
    let image_url: String
    let card_type: CardType
    let is_unique: Bool
    let description: String?
    let created_at: Date
    let is_starter_card: Bool
    let is_standard_card: Bool
    let is_unique_card: Bool
}

// MARK: - My Cards Response

struct MyCardsResponse: Codable {
    let cards: [CardResponse]
    let total_count: Int
    let starter_cards_count: Int
    let standard_cards_count: Int
    let unique_cards_count: Int
}

struct CardsByTypeResponse: Codable {
    let cards: [CardResponse]
    let total_count: Int
    let card_type: CardType
}

struct GameRoundCardsResponse: Codable {
    let cards: [CardResponse]
    let round_id: Int
    let situation: String
    let time_limit: TimeInterval
}

// MARK: - Azure Integration Models

struct AzureStatusResponse: Codable {
    let is_loading: Bool
    let loaded_types: [CardType]
    let total_cards: Int
    let progress_percentage: Double
}

struct AzureLoadRequest: Codable {
    let card_type: CardType?
}

struct AzureLoadResponse: Codable {
    let message: String
    let loaded_cards: Int
    let card_type: CardType?
}

// MARK: - Card Statistics

struct CardStatisticsResponse: Codable {
    let total_cards: Int
    let cards_by_type: [CardTypeStatistics]
    let unique_cards_percentage: Double
    let average_cards_per_user: Double
}

struct CardTypeStatistics: Codable {
    let card_type: CardType
    let count: Int
    let percentage: Double
}

// MARK: - Admin Models

struct AdminCreateBatchRequest: Codable {
    let card_type: CardType
    let count: Int
    let names: [String]
    let descriptions: [String]?
    let image_urls: [String]?
}

struct AdminCreateBatchResponse: Codable {
    let created_cards: Int
    let card_type: CardType
    let message: String
}

// MARK: - Winner Card Award

struct AwardWinnerCardRequest: Codable {
    let game_id: Int
    let user_id: Int
    let card_id: String
}

struct AwardWinnerCardResponse: Codable {
    let awarded: Bool
    let card: CardResponse?
    let message: String
}

// MARK: - Card Extensions

extension CardResponse {
    var displayName: String {
        return name
    }
    
    var displayDescription: String {
        return description ?? "Описание отсутствует"
    }
    
    var rarityColor: String {
        switch card_type {
        case .starter:
            return "gray"
        case .standard:
            return "blue"
        case .unique:
            return "purple"
        }
    }
    
    var isRare: Bool {
        return card_type == .unique || is_unique
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: created_at)
    }
}

// MARK: - Card Collection Models

struct CardCollection: Codable {
    let user_id: Int
    let cards: [CardResponse]
    let total_cards: Int
    let unique_cards: Int
    let completion_percentage: Double
}

struct CardCollectionStats: Codable {
    let total_cards: Int
    let unique_cards: Int
    let starter_cards: Int
    let standard_cards: Int
    let unique_rare_cards: Int
    let completion_percentage: Double
    let rank: Int?
    let total_collectors: Int?
} 