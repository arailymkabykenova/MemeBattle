//
//  RoomViewModel.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine
import UIKit

@MainActor
class RoomViewModel: ObservableObject {
    private let roomRepository: RoomRepositoryProtocol
    private let webSocketManager: WebSocketManager
    
    @Published var availableRooms: [RoomResponse] = []
    @Published var myRoom: RoomResponse?
    @Published var roomDetails: RoomDetailResponse?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var isInRoom = false
    @Published var currentGame: GameResponse?
    
    // Room creation
    @Published var maxPlayers = 4
    @Published var isPublic = true
    @Published var ageGroup = "all"
    
    // Join by code
    @Published var roomCode = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init(roomRepository: RoomRepositoryProtocol = RoomRepository(),
         webSocketManager: WebSocketManager = WebSocketManager.shared) {
        self.roomRepository = roomRepository
        self.webSocketManager = webSocketManager
        
        setupWebSocketObservers()
    }
    
    // MARK: - Room Management
    
    func loadAvailableRooms() async {
        isLoading = true
        showError = false
        
        do {
            availableRooms = try await roomRepository.getAvailableRooms()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func loadMyRoom() async {
        do {
            myRoom = try await roomRepository.getMyRoom()
            isInRoom = myRoom != nil
            
            if let room = myRoom {
                await loadRoomDetails(roomId: room.id)
            }
        } catch {
            handleError(error)
        }
    }
    
    func loadRoomDetails(roomId: Int) async {
        do {
            roomDetails = try await roomRepository.getRoomDetails(roomId: roomId)
        } catch {
            handleError(error)
        }
    }
    
    func createRoom() async {
        isLoading = true
        showError = false
        
        do {
            let request = CreateRoomRequest(
                max_players: maxPlayers,
                is_public: isPublic,
                generate_code: true
            )
            
            myRoom = try await roomRepository.createRoom(request: request)
            isInRoom = true
            
            // Connect to WebSocket
            try await webSocketManager.connect(roomId: myRoom?.id)
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func joinRoom(roomId: Int) async {
        isLoading = true
        showError = false
        
        do {
            myRoom = try await roomRepository.joinRoom(roomId: roomId)
            isInRoom = true
            
            // Connect to WebSocket
            try await webSocketManager.connect(roomId: roomId)
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func joinByCode() async {
        guard !roomCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError = true
            errorMessage = "Введите код комнаты"
            return
        }
        
        isLoading = true
        showError = false
        
        do {
            let code = roomCode.trimmingCharacters(in: .whitespacesAndNewlines)
            myRoom = try await roomRepository.joinByCode(code: code)
            isInRoom = true
            
            // Connect to WebSocket
            try await webSocketManager.connect(roomId: myRoom?.id)
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func quickMatch() async {
        isLoading = true
        showError = false
        
        do {
            myRoom = try await roomRepository.quickMatch()
            isInRoom = true
            
            // Connect to WebSocket
            try await webSocketManager.connect(roomId: myRoom?.id)
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func leaveRoom() async {
        guard let roomId = myRoom?.id else { return }
        
        isLoading = true
        showError = false
        
        do {
            try await roomRepository.leaveRoom(roomId: roomId)
            webSocketManager.disconnect()
            
            myRoom = nil
            roomDetails = nil
            isInRoom = false
            currentGame = nil
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func startGame() async {
        guard let roomId = myRoom?.id else { return }
        
        isLoading = true
        showError = false
        
        do {
            currentGame = try await roomRepository.startGame(roomId: roomId)
            
            // Send start game message via WebSocket
            try await webSocketManager.startGame(roomId: roomId)
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - WebSocket Observers
    
    private func setupWebSocketObservers() {
        NotificationCenter.default.publisher(for: Notification.Name.roomStateChanged)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handleRoomStateChanged(notification)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.gameStarted)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handleGameStarted(notification)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.playerJoined)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handlePlayerJoined(notification)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.playerLeft)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handlePlayerLeft(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleRoomStateChanged(_ notification: Notification) async {
        // Reload room details when room state changes
        if let roomId = myRoom?.id {
            await loadRoomDetails(roomId: roomId)
        }
    }
    
    private func handleGameStarted(_ notification: Notification) async {
        // Handle game started event
        if let roomId = myRoom?.id {
            await loadRoomDetails(roomId: roomId)
        }
    }
    
    private func handlePlayerJoined(_ notification: Notification) async {
        // Reload room details when player joins
        if let roomId = myRoom?.id {
            await loadRoomDetails(roomId: roomId)
        }
    }
    
    private func handlePlayerLeft(_ notification: Notification) async {
        // Reload room details when player leaves
        if let roomId = myRoom?.id {
            await loadRoomDetails(roomId: roomId)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) {
        showError = true
        errorMessage = error.localizedDescription
    }
} 