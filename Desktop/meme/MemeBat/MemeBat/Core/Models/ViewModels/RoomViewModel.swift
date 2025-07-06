import Foundation
import Combine

@MainActor
class RoomViewModel: ObservableObject {
    @Published var room: Room?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let roomService: RoomServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(room: Room? = nil, roomService: RoomServiceProtocol = RoomService()) {
        self.room = room
        self.roomService = roomService
    }
    
    func fetchRoomDetails(roomId: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let updatedRoom = try await roomService.getRoomDetails(roomId: roomId)
            self.room = updatedRoom
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func leaveRoom() async {
        guard let room = room else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await roomService.leaveRoom(roomId: room.id)
            self.room = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func startGame() async {
        guard let room = room else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await roomService.startGame(roomId: room.id)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
} 