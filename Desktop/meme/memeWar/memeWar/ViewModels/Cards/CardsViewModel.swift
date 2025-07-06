//
//  CardsViewModel.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

@MainActor
class CardsViewModel: ObservableObject {
    private let cardsRepository: CardsRepositoryProtocol
    
    @Published var myCards: [CardResponse] = []
    @Published var allCards: [CardResponse] = []
    @Published var gameCards: [CardResponse] = []
    @Published var starterCards: [CardResponse] = []
    @Published var selectedCardType: CardType = .all
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var statistics: CardStatisticsResponse?
    @Published var hasStarterCards = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(cardsRepository: CardsRepositoryProtocol = CardsRepository()) {
        self.cardsRepository = cardsRepository
    }
    
    // MARK: - Cards Management
    
    func loadMyCards() async {
        isLoading = true
        showError = false
        
        do {
            myCards = try await cardsRepository.getMyCards()
            hasStarterCards = myCards.contains { $0.is_starter_card }
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func loadAllCards() async {
        isLoading = true
        showError = false
        
        do {
            allCards = try await cardsRepository.getAllCards()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func loadGameCards() async {
        isLoading = true
        showError = false
        
        do {
            gameCards = try await cardsRepository.getCardsForGameRound()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func loadCardsByType(_ type: CardType) async {
        isLoading = true
        showError = false
        
        do {
            let cards = try await cardsRepository.getCardsByType(type: type)
            switch type {
            case .all:
                myCards = cards
            case .starter:
                myCards = cards
            case .standard:
                myCards = cards
            case .unique:
                myCards = cards
            }
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func assignStarterCards() async {
        isLoading = true
        showError = false
        
        do {
            let newCards = try await cardsRepository.assignStarterCards()
            myCards.append(contentsOf: newCards)
            hasStarterCards = true
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func checkStarterCards() async {
        isLoading = true
        showError = false
        
        do {
            let cards = try await cardsRepository.getCardsByType(type: .starter)
            starterCards = cards
            hasStarterCards = !cards.isEmpty
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func loadStatistics() async {
        do {
            statistics = try await cardsRepository.getCardStatistics()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Filtering
    
    var filteredCards: [CardResponse] {
        switch selectedCardType {
        case .all:
            return myCards
        case .starter:
            return myCards.filter { $0.is_starter_card }
        case .standard:
            return myCards.filter { $0.is_standard_card }
        case .unique:
            return myCards.filter { $0.is_unique_card }
        }
    }
    
    var starterCardsCount: Int {
        myCards.filter { $0.is_starter_card }.count
    }
    
    var standardCardsCount: Int {
        myCards.filter { $0.is_standard_card }.count
    }
    
    var uniqueCardsCount: Int {
        myCards.filter { $0.is_unique_card }.count
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) {
        showError = true
        errorMessage = error.localizedDescription
    }
} 