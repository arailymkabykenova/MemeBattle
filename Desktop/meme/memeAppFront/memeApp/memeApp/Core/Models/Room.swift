import Foundation

struct Room: Codable, Identifiable {
    let id: Int
    let creator_id: Int
    var max_players: Int
    var status: String
    var room_code: String?
    var is_public: Bool
    var age_group: String?
    var created_at: String
    var current_players: Int
    var participants: [RoomParticipant]?
    var creator_nickname: String?
    var can_start_game: Bool?
    
    var roomStatus: RoomStatus {
        RoomStatus(rawValue: status) ?? .waiting
    }
    
    var ageGroup: AgeGroup {
        guard let ageGroupString = age_group else { return .mixed }
        return AgeGroup(rawValue: ageGroupString) ?? .mixed
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
    var user_nickname: String
    var joined_at: String
    var status: String
    
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
        case .waiting:
            return "Ожидание игроков"
        case .playing:
            return "Игра в процессе"
        case .finished:
            return "Игра завершена"
        case .cancelled:
            return "Игра отменена"
        }
    }
    
    var color: String {
        switch self {
        case .waiting:
            return "blue"
        case .playing:
            return "green"
        case .finished:
            return "gray"
        case .cancelled:
            return "red"
        }
    }
}

enum ParticipantStatus: String, CaseIterable, Codable {
    case active = "active"
    case disconnected = "disconnected"
    case left = "left"
    
    var displayName: String {
        switch self {
        case .active:
            return "Активен"
        case .disconnected:
            return "Отключен"
        case .left:
            return "Покинул игру"
        }
    }
    
    var color: String {
        switch self {
        case .active:
            return "green"
        case .disconnected:
            return "orange"
        case .left:
            return "red"
        }
    }
} 