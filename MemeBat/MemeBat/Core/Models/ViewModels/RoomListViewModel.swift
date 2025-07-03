import Foundation
import Combine

@MainActor
class RoomListViewModel: ObservableObject {
    @Published var rooms: [Room] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedRoom: Room?
    
    private let roomService: RoomServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(roomService: RoomServiceProtocol = RoomService()) {
        self.roomService = roomService
    }
    
    func fetchRooms(ageGroup: AgeGroup? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedRooms = try await roomService.getPublicRooms(ageGroup: ageGroup)
            self.rooms = fetchedRooms
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func joinRoom(room: Room) async {
        isLoading = true
        errorMessage = nil
        do {
            let joinedRoom = try await roomService.joinRoom(roomId: room.id)
            self.selectedRoom = joinedRoom
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func createRoom(maxPlayers: Int, isPublic: Bool, ageGroup: AgeGroup) async {
        isLoading = true
        errorMessage = nil
        do {
            let newRoom = try await roomService.createRoom(maxPlayers: maxPlayers, isPublic: isPublic, ageGroup: ageGroup)
            self.selectedRoom = newRoom
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
} 