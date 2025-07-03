import Foundation

struct Room: Codable, Identifiable {
    let id: Int
    let creator_id: Int
    let max_players: Int
    let status: String
    let room_code: String
    let is_public: Bool
    let age_group: String
    let created_at: String
    let current_players: Int
    let participants: [RoomParticipant]?
    let creator_nickname: String?
    let can_start_game: Bool?
    
    var roomStatus: RoomStatus {
        RoomStatus(rawValue: status) ?? .waiting
    }
    
    var ageGroup: AgeGroup {
        AgeGroup(rawValue: age_group) ?? .mixed
    }
    
    var isFull: Bool {
        current_players >= max_players
    }
    
    var canJoin: Bool {
        roomStatus == .waiting && !isFull
    }
}

struct RoomParticipant: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let user_nickname: String
    let joined_at: String
    let status: String
    
    var participantStatus: ParticipantStatus {
        ParticipantStatus(rawValue: status) ?? .active
    }
}

enum RoomStatus: String, CaseIterable, Codable {
    case waiting = "waiting"
    case playing = "playing"
    case finished = "finished"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .waiting: return "Ожидание"
        case .playing: return "Игра в процессе"
        case .finished: return "Завершена"
        case .cancelled: return "Отменена"
        }
    }
    
    var color: String {
        switch self {
        case .waiting: return "blue"
        case .playing: return "green"
        case .finished: return "gray"
        case .cancelled: return "red"
        }
    }
}

enum ParticipantStatus: String, CaseIterable, Codable {
    case active = "active"
    case ready = "ready"
    case spectating = "spectating"
    
    var displayName: String {
        switch self {
        case .active: return "Активен"
        case .ready: return "Готов"
        case .spectating: return "Наблюдает"
        }
    }
} 