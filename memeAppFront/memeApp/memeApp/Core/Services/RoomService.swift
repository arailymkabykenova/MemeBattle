import Foundation
import os

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
    private let networkManager: NetworkManagerProtocol
    private let logger = Logger(subsystem: "com.memegame.app", category: "room-service")
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    // MARK: - Get Available Rooms
    func getRooms() async throws -> [Room] {
        logger.debug("Fetching available rooms")
        
        do {
            let response: [Room] = try await networkManager.makeRequest(
                endpoint: "/api/v1/rooms",
                method: .GET
            )
            logger.debug("Successfully fetched \(response.count) available rooms")
            return response
        } catch {
            logger.error("Failed to fetch available rooms: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Get Current Room (alias for getMyRoom)
    func getCurrentRoom() async throws -> Room? {
        logger.debug("Fetching current user's room")
        
        do {
            let response: Room? = try await networkManager.makeRequest(
                endpoint: "/api/v1/rooms/my",
                method: .GET
            )
            logger.debug("Successfully fetched user's room")
            return response
        } catch {
            logger.error("Failed to fetch user's room: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Create Room
    func createRoom(ageGroup: AgeGroup, isPublic: Bool, maxPlayers: Int) async throws -> Room {
        logger.debug("Creating room with maxPlayers: \(maxPlayers), isPublic: \(isPublic), ageGroup: \(ageGroup.rawValue)")
        
        // Сначала проверим, есть ли у пользователя уже активная комната
        if let existingRoom = try? await getCurrentRoom() {
            logger.warning("User already has an active room: \(existingRoom.id)")
            // Попробуем покинуть существующую комнату
            try? await leaveRoom(roomId: existingRoom.id)
            logger.debug("Left existing room before creating new one")
        }
        
        let requestBody = CreateRoomRequest(
            max_players: maxPlayers,
            is_public: isPublic,
            age_group: ageGroup.rawValue
        )
        
        do {
            let response: Room = try await networkManager.makeRequest(
                endpoint: "/api/v1/rooms",
                method: .POST,
                body: requestBody
            )
            logger.debug("Successfully created room with ID: \(response.id)")
            return response
        } catch {
            logger.error("Failed to create room: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Join Room
    func joinRoom(roomId: Int) async throws -> Room {
        logger.debug("Joining room with ID: \(roomId)")
        
        do {
            let response: Room = try await networkManager.makeRequest(
                endpoint: "/api/v1/rooms/\(roomId)/join",
                method: .POST
            )
            logger.debug("Successfully joined room")
            return response
        } catch {
            logger.error("Failed to join room: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Join Room By Code
    func joinRoomByCode(code: String) async throws -> Room {
        logger.debug("Joining room by code: \(code)")
        
        let requestBody = JoinRoomByCodeRequest(room_code: code)
        
        do {
            let response: Room = try await networkManager.makeRequest(
                endpoint: "/api/v1/rooms/join-by-code",
                method: .POST,
                body: requestBody
            )
            logger.debug("Successfully joined room by code")
            return response
        } catch {
            logger.error("Failed to join room by code: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Leave Room
    func leaveRoom(roomId: Int) async throws -> Void {
        logger.debug("Leaving room with ID: \(roomId)")
        
        do {
            let _: EmptyResponse = try await networkManager.makeRequest(
                endpoint: "/api/v1/rooms/\(roomId)/leave",
                method: .POST
            )
            logger.debug("Successfully left room")
        } catch {
            logger.error("Failed to leave room: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getRoomDetails(roomId: Int) async throws -> Room {
        logger.debug("Fetching room details for ID: \(roomId)")
        
        do {
            let response: Room = try await networkManager.makeRequest(
                endpoint: "/api/v1/rooms/\(roomId)",
                method: .GET
            )
            logger.debug("Successfully fetched room details")
            return response
        } catch {
            logger.error("Failed to fetch room details: \(error.localizedDescription)")
            throw error
        }
    }
    
    func quickMatch() async throws -> Room {
        logger.debug("Starting quick match")
        
        do {
            let response: Room = try await networkManager.makeRequest(
                endpoint: "/api/v1/rooms/quick-match",
                method: .POST
            )
            logger.debug("Successfully started quick match")
            return response
        } catch {
            logger.error("Failed to start quick match: \(error.localizedDescription)")
            throw error
        }
    }
    
    func startGame(roomId: Int) async throws {
        logger.debug("Starting game in room with ID: \(roomId)")
        
        do {
            let _: [String: Any] = try await networkManager.makeRequest(
                endpoint: "/api/v1/rooms/\(roomId)/start-game",
                method: .POST
            )
            logger.debug("Successfully started game")
        } catch {
            logger.error("Failed to start game: \(error.localizedDescription)")
            throw error
        }
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
            throw NetworkError.invalidResponse
        }
        
        return try await createRoom(
            ageGroup: ageGroupEnum,
            isPublic: isPublic,
            maxPlayers: maxPlayers
        )
    }
} 