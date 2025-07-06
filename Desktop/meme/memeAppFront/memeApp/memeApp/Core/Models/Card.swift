import Foundation
import SwiftUI

// MARK: - Основная модель карты
struct Card: Codable, Identifiable {
    let id: Int
    let name: String
    let image_url: String
    let card_type: String
    let description: String
    let created_at: String
    let is_unique: Bool
}

// MARK: - Модель карты для игры
struct GameCard: Codable, Identifiable {
    let id: Int
    let name: String
    let image_url: String
    let card_type: String
    let description: String
    let created_at: String
    let is_unique: Bool
}

// MARK: - Модель карты пользователя (формат сервера)
struct UserCardResponse: Codable, Identifiable {
    let id: String
    let name: String
    let image_url: String
    let card_type: String
    let description: String
    let created_at: String
    let is_starter_card: Bool
    let is_standard_card: Bool
    let is_unique_card: Bool
    
    // Computed property для совместимости с Card
    var cardId: Int {
        // Извлекаем ID из строки (например, "starter_1" -> 1)
        let components = id.split(separator: "_")
        return Int(components.last ?? "0") ?? 0
    }
}

// MARK: - Модель ответа API для карт пользователя
struct MyCardsResponse: Codable {
    let user_id: Int
    let total_cards: Int
    let cards_by_type: CardsByType
    let statistics: CardStatistics
}

struct CardsByType: Codable {
    let starter: [UserCardResponse]
    let standard: [UserCardResponse]
    let unique: [UserCardResponse]
}

struct CardStatistics: Codable {
    let starter_count: Int
    let standard_count: Int
    let unique_count: Int
}

// MARK: - Модель ответа для выдачи стартовых карт
struct AssignStarterCardsResponse: Codable {
    let message: String
    let cards_assigned: Int
    let cards: [Card]
}

// MARK: - Enum для типов карт
enum CardType: String, CaseIterable {
    case starter = "starter"
    case standard = "standard"
    case unique = "unique"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .starter: return "Стартовые"
        case .standard: return "Обычные"
        case .unique: return "Уникальные"
        case .all: return "Все карты"
        }
    }
    
    var icon: String {
        switch self {
        case .starter: return "star.fill"
        case .standard: return "rectangle.stack.fill"
        case .unique: return "crown.fill"
        case .all: return "rectangle.stack.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .starter: return .yellow
        case .standard: return .blue
        case .unique: return .purple
        case .all: return .gray
        }
    }
}

// MARK: - Enum для редкости карт
enum CardRarity: String, CaseIterable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .common: return "Обычные"
        case .rare: return "Редкие"
        case .epic: return "Эпические"
        case .legendary: return "Легендарные"
        case .all: return "Все"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        case .all: return .primary
        }
    }
} 