//
//  RoomViewModel.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

@MainActor
class RoomViewModel: ObservableObject {
    private let roomRepository: RoomRepositoryProtocol
    private let webSocketManager: WebSocketManager
    
    @Published var availableRooms: [RoomResponse] = []
    @Published var currentRoom: RoomDetailResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(roomRepository: RoomRepositoryProtocol = RoomRepository(),
         webSocketManager: WebSocketManager = WebSocketManager.shared) {
        self.roomRepository = roomRepository
        self.webSocketManager = webSocketManager
    }
    
    // MARK: - Room Management
    
    func loadAvailableRooms() async {
        isLoading = true
        errorMessage = nil
        
        do {
            availableRooms = try await roomRepository.getAvailableRooms()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createRoom(maxPlayers: Int, isPublic: Bool, ageGroup: String?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = CreateRoomRequest(
                max_players: maxPlayers,
                is_public: isPublic,
                age_group: ageGroup
            )
            
            let room = try await roomRepository.createRoom(request: request)
            currentRoom = room
            
            // Connect to WebSocket for this room
            try await webSocketManager.connect(roomId: room.room.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func joinRoom(roomId: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let room = try await roomRepository.joinRoom(roomId: roomId)
            currentRoom = room
            
            // Connect to WebSocket for this room
            try await webSocketManager.connect(roomId: roomId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func joinRoomByCode(code: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = JoinRoomRequest(room_code: code)
            let room = try await roomRepository.joinRoomByCode(request: request)
            currentRoom = room
            
            // Connect to WebSocket for this room
            try await webSocketManager.connect(roomId: room.room.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func leaveRoom() async {
        guard let room = currentRoom else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await roomRepository.leaveRoom(roomId: room.room.id)
            try await webSocketManager.leaveRoom(room.room.id)
            currentRoom = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func startGame() async {
        guard let room = currentRoom else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await roomRepository.startGame(roomId: room.room.id)
            try await webSocketManager.startGame(room.room.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
} 