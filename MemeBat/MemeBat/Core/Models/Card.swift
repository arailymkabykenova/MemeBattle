import Foundation

struct Card: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let image_url: String
    let type: String
    let rarity: String
    let is_unique: Bool
    let created_at: String
    
    var cardType: CardType {
        CardType(rawValue: type) ?? .standard
    }
    
    var cardRarity: CardRarity {
        CardRarity(rawValue: rarity) ?? .common
    }
}

struct UserCard: Codable, Identifiable {
    let id: Int
    let name: String
    let image_url: String
    let type: String
    let rarity: String
    let is_unique: Bool
    let obtained_at: String
    
    var cardType: CardType {
        CardType(rawValue: type) ?? .standard
    }
    
    var cardRarity: CardRarity {
        CardRarity(rawValue: rarity) ?? .common
    }
}

enum CardType: String, CaseIterable, Codable {
    case standard = "standard"
    case unique = "unique"
    
    var displayName: String {
        switch self {
        case .standard: return "Обычная"
        case .unique: return "Уникальная"
        }
    }
}

enum CardRarity: String, CaseIterable, Codable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var displayName: String {
        switch self {
        case .common: return "Обычная"
        case .rare: return "Редкая"
        case .epic: return "Эпическая"
        case .legendary: return "Легендарная"
        }
    }
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
    
    var dropChance: Double {
        switch self {
        case .common: return 0.6
        case .rare: return 0.3
        case .epic: return 0.08
        case .legendary: return 0.02
        }
    }
} 