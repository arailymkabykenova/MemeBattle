import Foundation
import os

// MARK: - Room Errors
enum RoomError: Error, LocalizedError {
    case notFound
    case invalidResponse
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Комната не найдена"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .networkError:
            return "Ошибка сети"
        }
    }
}

protocol RoomServiceProtocol {
    func getRooms() async throws -> [Room]
    func getCurrentRoom() async throws -> Room?
    func getRoomDetails(roomId: Int) async throws -> Room
    func createRoom(ageGroup: AgeGroup, isPublic: Bool, maxPlayers: Int) async throws -> Room
    func joinRoom(roomId: Int) async throws -> Room
    func joinRoomByCode(code: String) async throws -> Room
    func quickMatch() async throws -> Room
    func leaveRoom(roomId: Int) async throws -> Void
    func startGame(roomId: Int) async throws
}

class RoomService: RoomServiceProtocol {
    private let networkManager: NetworkManager
    private let logger = Logger(subsystem: "com.memegame.app", category: "room-service")
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    // MARK: - Get Available Rooms
    func getRooms() async throws -> [Room] {
        logger.debug("Fetching available rooms - TEMPORARILY DISABLED")
        // Временно возвращаем пустой массив для тестирования основных функций
        return []
    }
    
    // MARK: - Get Current Room (alias for getMyRoom)
    func getCurrentRoom() async throws -> Room? {
        logger.debug("Fetching current user's room - TEMPORARILY DISABLED")
        return nil
    }
    
    // MARK: - Create Room
    func createRoom(ageGroup: AgeGroup, isPublic: Bool, maxPlayers: Int) async throws -> Room {
        logger.debug("Creating room - TEMPORARILY DISABLED")
        throw RoomError.notFound
    }
    
    // MARK: - Join Room
    func joinRoom(roomId: Int) async throws -> Room {
        logger.debug("Joining room - TEMPORARILY DISABLED")
        throw RoomError.notFound
    }
    
    // MARK: - Join Room By Code
    func joinRoomByCode(code: String) async throws -> Room {
        logger.debug("Joining room by code - TEMPORARILY DISABLED")
        throw RoomError.notFound
    }
    
    // MARK: - Leave Room
    func leaveRoom(roomId: Int) async throws -> Void {
        logger.debug("Leaving room - TEMPORARILY DISABLED")
    }
    
    func getRoomDetails(roomId: Int) async throws -> Room {
        logger.debug("Getting room details - TEMPORARILY DISABLED")
        throw RoomError.notFound
    }
    
    func quickMatch() async throws -> Room {
        logger.debug("Quick match - TEMPORARILY DISABLED")
        throw RoomError.notFound
    }
    
    func startGame(roomId: Int) async throws {
        logger.debug("Starting game - TEMPORARILY DISABLED")
    }
}

// MARK: - Request Models
struct CreateRoomRequest: Codable {
    let max_players: Int
    let is_public: Bool
    let age_group: String
}

struct JoinRoomByCodeRequest: Codable {
    let room_code: String
}

struct EmptyResponse: Codable {}

// MARK: - Legacy Methods (for backward compatibility)
extension RoomService {
    func getAvailableRooms() async throws -> [Room] {
        return try await getRooms()
    }
    
    func getMyRoom() async throws -> Room? {
        return try await getCurrentRoom()
    }
    
    func createRoom(maxPlayers: Int, isPublic: Bool, ageGroup: String) async throws -> Room {
        guard let ageGroupEnum = AgeGroup(rawValue: ageGroup) else {
            throw RoomError.invalidResponse
        }
        
        return try await createRoom(
            ageGroup: ageGroupEnum,
            isPublic: isPublic,
            maxPlayers: maxPlayers
        )
    }
} 