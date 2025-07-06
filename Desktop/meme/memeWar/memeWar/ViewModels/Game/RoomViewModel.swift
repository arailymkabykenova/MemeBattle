//
//  RoomViewModel.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

@MainActor
class RoomViewModel: BaseViewModel {
    private let roomRepository: RoomRepositoryProtocol
    private let webSocketManager = WebSocketManager.shared
    
    @Published var availableRooms: [RoomResponse] = []
    @Published var myRoom: RoomDetailResponse?
    @Published var selectedRoom: RoomDetailResponse?
    @Published var roomCode: String = ""
    @Published var showCreateRoom = false
    @Published var showJoinByCode = false
    
    // Create room form
    @Published var createRoomMaxPlayers = 6
    @Published var createRoomIsPublic = true
    @Published var createRoomAgeGroup: String = ""
    
    // Quick match form
    @Published var quickMatchMaxPlayers: Int?
    @Published var quickMatchAgeGroup: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init(roomRepository: RoomRepositoryProtocol = RoomRepository()) {
        self.roomRepository = roomRepository
        super.init()
        
        setupWebSocketObservers()
    }
    
    // MARK: - Room Loading
    
    func loadAvailableRooms() async {
        let result = await performAsyncTask {
            try await self.roomRepository.getAvailableRooms()
        }
        
        if let rooms = result {
            availableRooms = rooms
        }
    }
    
    func loadMyRoom() async {
        let result = await performAsyncTask {
            try await self.roomRepository.getMyRoom()
        }
        
        if let room = result {
            myRoom = room
            selectedRoom = room
            
            // Connect to WebSocket for this room
            try? await webSocketManager.connect(roomId: room?.room.id ?? 0)
        }
    }
    
    func loadRoomDetails(roomId: Int) async {
        let result = await performAsyncTask {
            try await self.roomRepository.getRoomDetails(roomId: roomId)
        }
        
        if let room = result {
            selectedRoom = room
        }
    }
    
    // MARK: - Room Creation
    
    func createRoom() async {
        let result = await performAsyncTask {
            try await self.roomRepository.createRoom(
                maxPlayers: self.createRoomMaxPlayers,
                isPublic: self.createRoomIsPublic,
                ageGroup: self.createRoomAgeGroup.isEmpty ? nil : self.createRoomAgeGroup
            )
        }
        
        if let response = result {
            myRoom = RoomDetailResponse(
                room: response.room,
                participants: [],
                creator_nickname: "Вы",
                can_start_game: false
            )
            selectedRoom = myRoom
            roomCode = response.room_code
            
            // Connect to WebSocket for the new room
            try? await webSocketManager.connect(roomId: response.room.id)
            
            showCreateRoom = false
        }
    }
    
    // MARK: - Room Joining
    
    func joinRoom(_ room: RoomResponse) async {
        let result = await performAsyncTask {
            try await self.roomRepository.joinRoom(roomId: room.id)
        }
        
        if let response = result {
            myRoom = response.room
            selectedRoom = response.room
            
            // Connect to WebSocket for this room
            try? await webSocketManager.connect(roomId: room.id)
        }
    }
    
    func joinByCode() async {
        guard !roomCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let result = await performAsyncTask {
            try await self.roomRepository.joinByCode(roomCode: self.roomCode.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        if let response = result {
            myRoom = response.room
            selectedRoom = response.room
            
            // Connect to WebSocket for this room
            try? await webSocketManager.connect(roomId: response.room.room.id)
            
            showJoinByCode = false
            roomCode = ""
        }
    }
    
    // MARK: - Quick Match
    
    func quickMatch() async {
        let result = await performAsyncTask {
            try await self.roomRepository.quickMatch(
                maxPlayers: self.quickMatchMaxPlayers,
                ageGroup: self.quickMatchAgeGroup.isEmpty ? nil : self.quickMatchAgeGroup
            )
        }
        
        if let response = result, let room = response.room {
            myRoom = RoomDetailResponse(
                room: room,
                participants: [],
                creator_nickname: "Система",
                can_start_game: false
            )
            selectedRoom = myRoom
            
            // Connect to WebSocket for this room
            try? await webSocketManager.connect(roomId: room.id)
        }
    }
    
    // MARK: - Room Management
    
    func leaveRoom() async {
        guard let room = myRoom else { return }
        
        let result = await performAsyncTask {
            try await self.roomRepository.leaveRoom(roomId: room.room.id)
        }
        
        if result != nil {
            // Disconnect from WebSocket
            webSocketManager.disconnect()
            
            myRoom = nil
            selectedRoom = nil
        }
    }
    
    func startGame() async {
        guard let room = myRoom else { return }
        
        let result = await performAsyncTask {
            try await self.roomRepository.startGame(roomId: room.room.id)
        }
        
        if result != nil {
            // Game started, room status will be updated via WebSocket
        }
    }
    
    // MARK: - WebSocket Event Handling
    
    private func setupWebSocketObservers() {
        // Room state changed
        NotificationCenter.default.publisher(for: .roomStateChanged)
            .sink { [weak self] notification in
                self?.handleRoomStateChanged(notification.object as? [String: Any])
            }
            .store(in: &cancellables)
        
        // Player joined
        NotificationCenter.default.publisher(for: .playerJoined)
            .sink { [weak self] notification in
                self?.handlePlayerJoined(notification.object as? [String: Any])
            }
            .store(in: &cancellables)
        
        // Player left
        NotificationCenter.default.publisher(for: .playerLeft)
            .sink { [weak self] notification in
                self?.handlePlayerLeft(notification.object as? [String: Any])
            }
            .store(in: &cancellables)
        
        // Game started
        NotificationCenter.default.publisher(for: .gameStarted)
            .sink { [weak self] notification in
                self?.handleGameStarted(notification.object as? [String: Any])
            }
            .store(in: &cancellables)
    }
    
    private func handleRoomStateChanged(_ data: [String: Any]?) {
        // Refresh room details
        Task {
            if let room = myRoom {
                await loadRoomDetails(roomId: room.room.id)
            }
        }
    }
    
    private func handlePlayerJoined(_ data: [String: Any]?) {
        // Refresh room details
        Task {
            if let room = myRoom {
                await loadRoomDetails(roomId: room.room.id)
            }
        }
    }
    
    private func handlePlayerLeft(_ data: [String: Any]?) {
        // Refresh room details
        Task {
            if let room = myRoom {
                await loadRoomDetails(roomId: room.room.id)
            }
        }
    }
    
    private func handleGameStarted(_ data: [String: Any]?) {
        // Game started, update room status
        Task {
            if let room = myRoom {
                await loadRoomDetails(roomId: room.room.id)
            }
        }
    }
    
    // MARK: - Form Validation
    
    var isCreateRoomFormValid: Bool {
        return createRoomMaxPlayers >= 2 && createRoomMaxPlayers <= 8
    }
    
    var isJoinByCodeFormValid: Bool {
        return !roomCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Computed Properties
    
    var isInRoom: Bool {
        return myRoom != nil
    }
    
    var canStartGame: Bool {
        return myRoom?.can_start_game ?? false
    }
    
    var isRoomCreator: Bool {
        guard let room = myRoom else { return false }
        // This should be compared with current user ID
        return room.creator_nickname == "Вы"
    }
    
    var roomStatusDisplay: String {
        return myRoom?.room.status.displayName ?? "Неизвестно"
    }
    
    var roomPlayersDisplay: String {
        return myRoom?.room.playersDisplay ?? "0/0"
    }
    
    var roomCodeDisplay: String {
        return myRoom?.room.displayCode ?? "N/A"
    }
    
    var roomAgeGroupDisplay: String {
        return myRoom?.room.ageGroupDisplay ?? "Любой возраст"
    }
    
    var roomTypeDisplay: String {
        return myRoom?.room.isPublicDisplay ?? "Неизвестно"
    }
    
    var participantsCount: Int {
        return myRoom?.participants.count ?? 0
    }
    
    var availableRoomsCount: Int {
        return availableRooms.count
    }
    
    var waitingRoomsCount: Int {
        return availableRooms.filter { $0.status == .waiting }.count
    }
    
    var activeRoomsCount: Int {
        return availableRooms.filter { $0.status == .playing }.count
    }
    
    // MARK: - Room Filtering
    
    var waitingRooms: [RoomResponse] {
        return availableRooms.filter { $0.status == .waiting && $0.canJoin }
    }
    
    var playingRooms: [RoomResponse] {
        return availableRooms.filter { $0.status == .playing }
    }
    
    var publicRooms: [RoomResponse] {
        return availableRooms.filter { $0.is_public }
    }
    
    var privateRooms: [RoomResponse] {
        return availableRooms.filter { !$0.is_public }
    }
    
    // MARK: - Cleanup
    
    override func cleanup() {
        webSocketManager.disconnect()
        cancellables.removeAll()
        super.cleanup()
    }
    
    deinit {
        // Cleanup will be handled by the parent class
        // No need to capture self in deinit
    }
} 