import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let game_center_player_id: String
    let nickname: String
    let birth_date: String
    let gender: String
    let rating: Double
    let created_at: String
    let last_seen: String?
    let statistics: UserStatistics?
    
    var age: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let birthDate = formatter.date(from: birth_date) else { return 0 }
        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }
    
    var ageGroup: AgeGroup {
        switch age {
        case 6...12:
            return .child
        case 13...17:
            return .teen
        case 18...:
            return .adult
        default:
            return .adult
        }
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
        return Double(games_won) / Double(games_played) * 100
    }
}

enum AgeGroup: String, CaseIterable, Codable {
    case child = "child"
    case teen = "teen"
    case adult = "adult"
    case mixed = "mixed"
    
    var displayName: String {
        switch self {
        case .child: return "Дети (6-12 лет)"
        case .teen: return "Подростки (13-17 лет)"
        case .adult: return "Взрослые (18+)"
        case .mixed: return "Смешанная группа"
        }
    }
    
    var minAge: Int {
        switch self {
        case .child: return 6
        case .teen: return 13
        case .adult: return 18
        case .mixed: return 6
        }
    }
    
    var maxAge: Int {
        switch self {
        case .child: return 12
        case .teen: return 17
        case .adult: return 999
        case .mixed: return 999
        }
    }
} 