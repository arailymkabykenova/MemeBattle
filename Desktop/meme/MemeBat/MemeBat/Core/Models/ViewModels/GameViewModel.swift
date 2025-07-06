import Foundation
import Combine

@MainActor
class GameViewModel: ObservableObject {
    @Published var game: Game?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var connectionLost: Bool = false
    
    private let webSocketManager: WebSocketManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private var roomId: Int?
    
    init(webSocketManager: WebSocketManagerProtocol = WebSocketManager.shared) {
        self.webSocketManager = webSocketManager
        setupWebSocketCallbacks()
    }
    
    func connectToGame(roomId: Int, token: String) async {
        self.roomId = roomId
        isLoading = true
        errorMessage = nil
        do {
            try await webSocketManager.connect(roomId: roomId, token: token)
            connectionLost = false
        } catch {
            errorMessage = error.localizedDescription
            connectionLost = true
        }
        isLoading = false
    }
    
    func disconnect() {
        webSocketManager.disconnect()
        connectionLost = true
    }
    
    func sendMessage(_ message: WebSocketMessage) async {
        do {
            try await webSocketManager.sendMessage(message)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func setupWebSocketCallbacks() {
        webSocketManager.onMessageReceived = { [weak self] message in
            self?.handleWebSocketMessage(message)
        }
        webSocketManager.onConnectionStatusChanged = { [weak self] isConnected in
            self?.connectionLost = !isConnected
        }
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        // Handle game state updates, player actions, etc.
        // This should be expanded based on the server protocol
        switch message.action {
        case WebSocketAction.gameStarted.rawValue:
            // Update game state
            break
        case WebSocketAction.roundStarted.rawValue:
            // Update round info
            break
        case WebSocketAction.cardPlayed.rawValue:
            // Update cards played
            break
        case WebSocketAction.votingStarted.rawValue:
            // Update voting state
            break
        case WebSocketAction.roundEnded.rawValue:
            // Update round results
            break
        case WebSocketAction.gameEnded.rawValue:
            // Handle game end
            break
        case WebSocketAction.error.rawValue:
            if let errorMsg = message.data["message"]?.value as? String {
                errorMessage = errorMsg
            }
        default:
            break
        }
    }
} 