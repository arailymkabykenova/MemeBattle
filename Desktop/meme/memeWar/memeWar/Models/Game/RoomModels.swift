//
//  RoomModels.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

// MARK: - Room Status Enum

enum RoomStatus: String, Codable {
    case waiting = "waiting"
    case playing = "playing"
    case finished = "finished"
    
    var displayName: String {
        switch self {
        case .waiting:
            return "Ожидание"
        case .playing:
            return "Игра"
        case .finished:
            return "Завершена"
        }
    }
    
    var color: String {
        switch self {
        case .waiting:
            return "orange"
        case .playing:
            return "green"
        case .finished:
            return "gray"
        }
    }
}

// MARK: - Room Response

struct RoomResponse: Codable, Identifiable {
    let id: Int
    let creator_id: Int
    let max_players: Int
    let status: RoomStatus
    let room_code: String?
    let is_public: Bool
    let age_group: String?
    let created_at: Date
    let current_players: Int
    let creator_nickname: String?
}

// MARK: - Room Detail Response

struct RoomDetailResponse: Codable {
    let room: RoomResponse
    let participants: [RoomParticipantResponse]
    let creator_nickname: String
    let can_start_game: Bool
}

// MARK: - Room Participant Response

struct RoomParticipantResponse: Codable, Identifiable {
    let id: Int
    let room_id: Int
    let user_id: Int
    let user_nickname: String
    let joined_at: Date
    let status: String
}

// MARK: - Create Room Request

struct CreateRoomRequest: Codable {
    let max_players: Int
    let is_public: Bool
    let generate_code: Bool
}

// MARK: - Join Room By Code Request

struct JoinRoomByCodeRequest: Codable {
    let room_code: String
}

// MARK: - Quick Match Request

struct QuickMatchRequest: Codable {
    let preferred_players: Int
    let max_wait_time: Int
}

// MARK: - Quick Match Response

struct QuickMatchResponse: Codable {
    let room: RoomResponse
    let wait_time: Int
}

// MARK: - Room Creation

struct CreateRoomResponse: Codable {
    let room: RoomResponse
    let room_code: String
    let message: String
}

// MARK: - Room Joining

struct JoinRoomRequest: Codable {
    let room_id: Int
}

struct JoinRoomResponse: Codable {
    let room: RoomDetailResponse
    let message: String
}

// MARK: - Room Management

struct LeaveRoomRequest: Codable {
    let room_id: Int
}

struct LeaveRoomResponse: Codable {
    let message: String
    let left_room: Bool
}

struct StartGameRequest: Codable {
    let room_id: Int
}

struct StartGameResponse: Codable {
    let game_id: Int
    let message: String
    let game_started: Bool
}

// MARK: - Room Statistics

struct RoomStatsResponse: Codable {
    let total_rooms: Int
    let active_rooms: Int
    let total_games: Int
    let average_players_per_room: Double
    let popular_age_groups: [AgeGroupStats]
}

struct AgeGroupStats: Codable {
    let age_group: String
    let room_count: Int
    let percentage: Double
}

// MARK: - Room Extensions

extension RoomResponse {
    var isFull: Bool {
        return current_players >= max_players
    }
    
    var canJoin: Bool {
        return status == .waiting && !isFull
    }
    
    var displayCode: String {
        return room_code ?? "N/A"
    }
    
    var ageGroupDisplay: String {
        return age_group ?? "Любой возраст"
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: created_at)
    }
    
    var playersDisplay: String {
        return "\(current_players)/\(max_players)"
    }
    
    var isPublicDisplay: String {
        return is_public ? "Публичная" : "Приватная"
    }
}

extension RoomParticipantResponse {
    var formattedJoinedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: joined_at)
    }
    
    var statusDisplay: String {
        switch status {
        case "active":
            return "Активен"
        case "inactive":
            return "Неактивен"
        case "ready":
            return "Готов"
        default:
            return status.capitalized
        }
    }
}

// MARK: - Room Filters

struct RoomFilters: Codable {
    var status: RoomStatus?
    var is_public: Bool?
    var age_group: String?
    var min_players: Int?
    var max_players: Int?
    var created_after: Date?
    var created_before: Date?
}

// MARK: - Room Search

struct RoomSearchRequest: Codable {
    let filters: RoomFilters?
    let page: Int?
    let limit: Int?
    let sort_by: String?
    let sort_order: String?
}

struct RoomSearchResponse: Codable {
    let rooms: [RoomResponse]
    let total_count: Int
    let current_page: Int
    let total_pages: Int
    let has_next: Bool
    let has_previous: Bool
} 