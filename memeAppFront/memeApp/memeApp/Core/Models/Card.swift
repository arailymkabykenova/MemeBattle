import Foundation
import SwiftUI

// MARK: - Основная модель карты
struct Card: Codable, Identifiable {
    let id: Int
    let name: String
    let image_url: String
    let type: String
    let rarity: String
    let is_unique: Bool
    let created_at: String
}

// MARK: - Модель карты пользователя (формат сервера)
struct UserCardResponse: Codable, Identifiable {
    let user_id: Int
    let card_type: String
    let card_number: Int
    let obtained_at: String
    let card_url: String
    
    // Computed property для совместимости с UserCard
    var id: Int { card_number }
    var name: String { 
        // Извлекаем имя из URL
        let url = URL(string: card_url)
        let filename = url?.lastPathComponent.replacingOccurrences(of: ".jpg", with: "")
            .replacingOccurrences(of: ".JPG", with: "")
            .replacingOccurrences(of: ".png", with: "")
            .replacingOccurrences(of: ".PNG", with: "")
        return filename?.replacingOccurrences(of: "-", with: " ").capitalized ?? "Card \(card_number)"
    }
    var image_url: String { card_url }
    var type: String { card_type }
    var rarity: String { "common" } // Стартовые карты обычно common
    var is_unique: Bool { false } // Стартовые карты не уникальные
}

// MARK: - Модель карты пользователя (для обратной совместимости)
struct UserCard: Codable, Identifiable {
    let id: Int
    let name: String
    let image_url: String
    let type: String
    let rarity: String
    let is_unique: Bool
    let obtained_at: String
}

// MARK: - Модель ответа API для карт пользователя
struct CardsResponse: Codable {
    let starter_cards: [UserCardResponse]
    let standard_cards: [UserCardResponse]
    let unique_cards: [UserCardResponse]
    let total_cards: Int
    
    // Computed property для получения всех карт
    var cards: [UserCardResponse] {
        return starter_cards + standard_cards + unique_cards
    }
    
    // Computed property для обратной совместимости
    var total_count: Int {
        return total_cards
    }
}

// MARK: - Enum для типов карт
enum CardType: String, CaseIterable {
    case reaction = "reaction"
    case situation = "situation"
    case action = "action"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .reaction: return "Reaction"
        case .situation: return "Situation"
        case .action: return "Action"
        case .all: return "All Cards"
        }
    }
    
    var icon: String {
        switch self {
        case .reaction: return "face.smiling"
        case .situation: return "exclamationmark.bubble"
        case .action: return "bolt.fill"
        case .all: return "rectangle.stack.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .reaction: return .blue
        case .situation: return .green
        case .action: return .orange
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
        case .common: return "Common"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        case .all: return "All"
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