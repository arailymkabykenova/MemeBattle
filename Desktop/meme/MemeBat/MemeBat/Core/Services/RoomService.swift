import Foundation
import os

// MARK: - Room Service Errors
enum RoomError: LocalizedError {
    case roomNotFound
    case roomFull
    case roomNotJoinable
    case invalidAgeGroup
    case networkError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .roomNotFound:
            return "Комната не найдена"
        case .roomFull:
            return "Комната заполнена"
        case .roomNotJoinable:
            return "Нельзя присоединиться к комнате"
        case .invalidAgeGroup:
            return "Неверная возрастная группа"
        case .networkError:
            return "Ошибка сети"
        case .unauthorized:
            return "Не авторизован"
        }
    }
}

// MARK: - Room Service Protocol
protocol RoomServiceProtocol {
    func getPublicRooms(ageGroup: AgeGroup?, page: Int, size: Int) async throws -> [Room]
    func createRoom(maxPlayers: Int, isPublic: Bool, ageGroup: AgeGroup) async throws -> Room
    func joinRoom(roomId: Int) async throws -> Room
    func leaveRoom(roomId: Int) async throws
    func startGame(roomId: Int) async throws
    func getRoomDetails(roomId: Int) async throws -> Room
}

// MARK: - Room Service
class RoomService: RoomServiceProtocol {
    private let networkManager: NetworkManagerProtocol
    private let logger = Logger(subsystem: "com.memegame.app", category: "room")
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    // MARK: - Public Methods
    func getPublicRooms(ageGroup: AgeGroup? = nil, page: Int = 1, size: Int = 20) async throws -> [Room] {
        logger.debug("Fetching public rooms: ageGroup=\(ageGroup?.rawValue ?? "any"), page=\(page), size=\(size)")
        
        var endpoint = APIConfig.Endpoints.rooms
        var queryItems: [String] = []
        
        // Add pagination parameters
        queryItems.append("page=\(page)")
        queryItems.append("size=\(min(size, APIConfig.Pagination.maxPageSize))")
        
        // Add age group filter if specified
        if let ageGroup = ageGroup {
            queryItems.append("age_group=\(ageGroup.rawValue)")
        }
        
        // Add public rooms filter
        queryItems.append("is_public=true")
        
        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }
        
        do {
            let rooms: [Room] = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .GET
            )
            
            logger.debug("Fetched \(rooms.count) public rooms")
            return rooms
            
        } catch {
            logger.error("Failed to fetch public rooms: \(error.localizedDescription)")
            throw RoomError.networkError
        }
    }
    
    func createRoom(maxPlayers: Int, isPublic: Bool, ageGroup: AgeGroup) async throws -> Room {
        logger.debug("Creating room: maxPlayers=\(maxPlayers), isPublic=\(isPublic), ageGroup=\(ageGroup.rawValue)")
        
        let roomData = CreateRoomRequest(
            max_players: maxPlayers,
            is_public: isPublic,
            age_group: ageGroup.rawValue
        )
        
        do {
            let encoder = JSONEncoder()
            let body = try encoder.encode(roomData)
            
            let room: Room = try await networkManager.makeRequest(
                endpoint: APIConfig.Endpoints.createRoom,
                method: .POST,
                body: body
            )
            
            logger.debug("Room created successfully: \(room.id)")
            return room
            
        } catch {
            logger.error("Failed to create room: \(error.localizedDescription)")
            throw RoomError.networkError
        }
    }
    
    func joinRoom(roomId: Int) async throws -> Room {
        logger.debug("Joining room: \(roomId)")
        
        let endpoint = APIConfig.Endpoints.joinRoom.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        
        do {
            let room: Room = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .POST
            )
            
            logger.debug("Successfully joined room: \(roomId)")
            return room
            
        } catch NetworkError.notFound {
            logger.error("Room not found: \(roomId)")
            throw RoomError.roomNotFound
        } catch NetworkError.unauthorized {
            logger.error("Unauthorized to join room: \(roomId)")
            throw RoomError.unauthorized
        } catch {
            logger.error("Failed to join room: \(error.localizedDescription)")
            throw RoomError.networkError
        }
    }
    
    func leaveRoom(roomId: Int) async throws {
        logger.debug("Leaving room: \(roomId)")
        
        let endpoint = APIConfig.Endpoints.leaveRoom.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        
        do {
            let _: EmptyResponse = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .POST
            )
            
            logger.debug("Successfully left room: \(roomId)")
            
        } catch {
            logger.error("Failed to leave room: \(error.localizedDescription)")
            throw RoomError.networkError
        }
    }
    
    func startGame(roomId: Int) async throws {
        logger.debug("Starting game in room: \(roomId)")
        
        let endpoint = APIConfig.Endpoints.startGame.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        
        do {
            let _: EmptyResponse = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .POST
            )
            
            logger.debug("Game started successfully in room: \(roomId)")
            
        } catch {
            logger.error("Failed to start game: \(error.localizedDescription)")
            throw RoomError.networkError
        }
    }
    
    func getRoomDetails(roomId: Int) async throws -> Room {
        logger.debug("Getting room details: \(roomId)")
        
        let endpoint = "\(APIConfig.Endpoints.rooms)/\(roomId)"
        
        do {
            let room: Room = try await networkManager.makeRequest(
                endpoint: endpoint,
                method: .GET
            )
            
            logger.debug("Room details fetched successfully: \(roomId)")
            return room
            
        } catch NetworkError.notFound {
            logger.error("Room not found: \(roomId)")
            throw RoomError.roomNotFound
        } catch {
            logger.error("Failed to get room details: \(error.localizedDescription)")
            throw RoomError.networkError
        }
    }
}

// MARK: - Request/Response Models
struct CreateRoomRequest: Codable {
    let max_players: Int
    let is_public: Bool
    let age_group: String
}

struct EmptyResponse: Codable {} 