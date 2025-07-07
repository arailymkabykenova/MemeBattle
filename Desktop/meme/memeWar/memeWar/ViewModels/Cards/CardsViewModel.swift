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
    @Published var myCards: [CardResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Placeholder initialization
    }
    
    func loadMyCards() async {
        // Placeholder method
    }
} 