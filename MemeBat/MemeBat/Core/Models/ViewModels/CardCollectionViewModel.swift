import Foundation
import Combine

@MainActor
class CardCollectionViewModel: ObservableObject {
    @Published var userCards: [UserCard] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let cardService: CardServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(cardService: CardServiceProtocol = CardService()) {
        self.cardService = cardService
    }
    
    func fetchUserCards(page: Int = 1, size: Int = 20) async {
        isLoading = true
        errorMessage = nil
        do {
            let cards = try await cardService.getUserCards(page: page, size: size)
            self.userCards = cards
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
} 