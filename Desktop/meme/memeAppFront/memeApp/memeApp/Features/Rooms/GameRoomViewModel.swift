import Foundation
import SwiftUI

@MainActor
class GameRoomViewModel: ObservableObject {
    @Published var room: Room
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let roomService: RoomServiceProtocol
    
    init(room: Room, roomService: RoomServiceProtocol = RoomService()) {
        self.room = room
        self.roomService = roomService
    }
    
    func refreshRoom() async {
        isLoading = true
        errorMessage = nil
        do {
            // В мок-режиме просто ничего не делаем, в реальном — обновляем room по id
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func leaveRoom() async {
        isLoading = true
        errorMessage = nil
        do {
            try await roomService.leaveRoom(roomId: room.id)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
} 