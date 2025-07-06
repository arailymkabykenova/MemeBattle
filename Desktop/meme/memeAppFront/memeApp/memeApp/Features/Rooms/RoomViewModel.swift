import Foundation
import SwiftUI
import Combine

@MainActor
class RoomViewModel: ObservableObject {
    @Published var rooms: [Room] = []
    @Published var currentRoom: Room? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showCreateRoomSheet: Bool = false
    @Published var showJoinByCodeSheet: Bool = false
    @Published var showHelpSheet: Bool = false
    @Published var createdRoom: Room? = nil
    
    private let roomService: RoomServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(roomService: RoomServiceProtocol = RoomService()) {
        self.roomService = roomService
    }
    
    func loadRooms() async {
        isLoading = true
        errorMessage = nil
        do {
            // Сначала проверяем текущую комнату пользователя
            if let currentRoom = try await roomService.getCurrentRoom() {
                self.currentRoom = currentRoom
            }
            
            // Затем загружаем доступные комнаты
            let availableRooms = try await roomService.getRooms()
            self.rooms = availableRooms.filter { room in
                // Исключаем комнату пользователя из списка доступных
                room.id != currentRoom?.id
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func createRoom(ageGroup: AgeGroup, isPublic: Bool, maxPlayers: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            // Если у пользователя уже есть активная комната, сначала покидаем её
            if let currentRoom = currentRoom {
                try await roomService.leaveRoom(roomId: currentRoom.id)
                self.currentRoom = nil
            }
            
            let newRoom = try await roomService.createRoom(
                ageGroup: ageGroup,
                isPublic: isPublic,
                maxPlayers: maxPlayers
            )
            
            self.currentRoom = newRoom
            await loadRooms() // Обновляем список комнат
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func joinRoom(roomId: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            // Если у пользователя уже есть активная комната, сначала покидаем её
            if let currentRoom = currentRoom {
                try await roomService.leaveRoom(roomId: currentRoom.id)
                self.currentRoom = nil
            }
            
            let joinedRoom = try await roomService.joinRoom(roomId: roomId)
            self.currentRoom = joinedRoom
            await loadRooms() // Обновляем список комнат
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func joinRoomByCode(code: String) async {
        isLoading = true
        errorMessage = nil
        do {
            // Если у пользователя уже есть активная комната, сначала покидаем её
            if let currentRoom = currentRoom {
                try await roomService.leaveRoom(roomId: currentRoom.id)
                self.currentRoom = nil
            }
            
            let joinedRoom = try await roomService.joinRoomByCode(code: code)
            self.currentRoom = joinedRoom
            await loadRooms() // Обновляем список комнат
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func quickMatch() async {
        isLoading = true
        errorMessage = nil
        do {
            // Если у пользователя уже есть активная комната, сначала покидаем её
            if let currentRoom = currentRoom {
                try await roomService.leaveRoom(roomId: currentRoom.id)
                self.currentRoom = nil
            }
            
            // Ищем подходящую комнату для быстрого поиска
            let availableRooms = try await roomService.getRooms()
            let suitableRooms = availableRooms.filter { room in
                room.status == "waiting" && 
                room.current_players < room.max_players &&
                room.is_public
            }
            
            if let bestRoom = suitableRooms.first {
                let joinedRoom = try await roomService.joinRoom(roomId: bestRoom.id)
                self.currentRoom = joinedRoom
                await loadRooms()
            } else {
                // Если нет подходящих комнат, создаем новую
                let newRoom = try await roomService.createRoom(
                    ageGroup: .teen, // По умолчанию для быстрого поиска
                    isPublic: true,
                    maxPlayers: 3
                )
                self.currentRoom = newRoom
                await loadRooms()
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func leaveRoom(roomId: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            try await roomService.leaveRoom(roomId: roomId)
            self.currentRoom = nil
            await loadRooms() // Обновляем список комнат
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func resetCreatedRoom() {
        self.createdRoom = nil
    }
    
    func refresh() async {
        await loadRooms()
    }
} 