//
//  CardsView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct CardsView: View {
    @EnvironmentObject var cardsViewModel: CardsViewModel
    @State private var selectedCardType: CardType = .starter
    
    var body: some View {
        VStack(spacing: AppConstants.padding) {
            // Header
            VStack(spacing: AppConstants.smallPadding) {
                Text("Мои карты")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(cardsViewModel.myCards.count) карт в коллекции")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.top, AppConstants.padding)
            
            // Card Type Selector
            Picker("Тип карт", selection: $selectedCardType) {
                Text("Стартовые").tag(CardType.starter)
                Text("Обычные").tag(CardType.standard)
                Text("Уникальные").tag(CardType.unique)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, AppConstants.largePadding)
            .onChange(of: selectedCardType) { _ in
                Task {
                    await cardsViewModel.loadCardsByType(selectedCardType)
                }
            }
            
            // Cards Grid
            if cardsViewModel.isLoading {
                Spacer()
                ProgressView("Загрузка карт...")
                Spacer()
            } else if cardsForSelectedType.isEmpty {
                Spacer()
                VStack(spacing: AppConstants.padding) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Нет карт этого типа")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Играйте больше, чтобы получить новые карты!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppConstants.padding), count: 2), spacing: AppConstants.padding) {
                        ForEach(cardsForSelectedType) { card in
                            CardView(card: card)
                        }
                    }
                    .padding(AppConstants.largePadding)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await cardsViewModel.loadMyCards()
            }
        }
        .refreshable {
            await cardsViewModel.loadMyCards()
        }
    }
    
    private var cardsForSelectedType: [CardResponse] {
        switch selectedCardType {
        case .starter:
            return cardsViewModel.starterCards
        case .standard:
            return cardsViewModel.myCards.filter { $0.card_type == .standard }
        case .unique:
            return cardsViewModel.myCards.filter { $0.card_type == .unique }
        }
    }
}

struct CardView: View {
    let card: CardResponse
    @State private var showingCardDetail = false
    
    var body: some View {
        Button(action: {
            showingCardDetail = true
        }) {
            VStack(spacing: AppConstants.smallPadding) {
                AsyncImage(url: URL(string: card.image_url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius))
                
                VStack(spacing: AppConstants.smallPadding) {
                    Text(card.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    if let description = card.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Card type badge
                    HStack {
                        Image(systemName: cardTypeIcon)
                            .font(.caption)
                        Text(cardTypeText)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(cardTypeColor)
                    .padding(.horizontal, AppConstants.smallPadding)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(cardTypeColor.opacity(0.1))
                    )
                }
            }
            .padding(AppConstants.smallPadding)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingCardDetail) {
            CardDetailView(card: card)
        }
    }
    
    private var cardTypeIcon: String {
        switch card.card_type {
        case .starter:
            return "star.fill"
        case .standard:
            return "circle.fill"
        case .unique:
            return "diamond.fill"
        }
    }
    
    private var cardTypeText: String {
        switch card.card_type {
        case .starter:
            return "Стартовая"
        case .standard:
            return "Обычная"
        case .unique:
            return "Уникальная"
        }
    }
    
    private var cardTypeColor: Color {
        switch card.card_type {
        case .starter:
            return .orange
        case .standard:
            return .blue
        case .unique:
            return .purple
        }
    }
}

struct CardDetailView: View {
    let card: CardResponse
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppConstants.largePadding) {
                    // Card Image
                    AsyncImage(url: URL(string: card.image_url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                            )
                    }
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius))
                    
                    // Card Info
                    VStack(spacing: AppConstants.padding) {
                        Text(card.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        if let description = card.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Card Stats
                        VStack(spacing: AppConstants.smallPadding) {
                            HStack {
                                Text("Тип:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(cardTypeText)
                                    .foregroundColor(cardTypeColor)
                            }
                            
                            HStack {
                                Text("Уникальная:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(card.is_unique ? "Да" : "Нет")
                                    .foregroundColor(card.is_unique ? .green : .secondary)
                            }
                            
                            HStack {
                                Text("Дата создания:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(card.created_at, style: .date)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                .padding(AppConstants.largePadding)
            }
            .navigationTitle("Детали карты")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var cardTypeText: String {
        switch card.card_type {
        case .starter:
            return "Стартовая"
        case .standard:
            return "Обычная"
        case .unique:
            return "Уникальная"
        }
    }
    
    private var cardTypeColor: Color {
        switch card.card_type {
        case .starter:
            return .orange
        case .standard:
            return .blue
        case .unique:
            return .purple
        }
    }
}

#Preview {
    NavigationView {
        CardsView()
            .environmentObject(CardsViewModel())
    }
} 