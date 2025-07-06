//
//  StarterCardsView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct StarterCardsView: View {
    @EnvironmentObject var cardsViewModel: CardsViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.largePadding) {
            Spacer()
            
            // Header
            VStack(spacing: AppConstants.padding) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Получите стартовые карты!")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Каждый игрок получает набор стартовых карт для начала игры")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Cards Preview
            if !cardsViewModel.starterCards.isEmpty {
                VStack(spacing: AppConstants.padding) {
                    Text("Ваши стартовые карты:")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppConstants.padding) {
                            ForEach(cardsViewModel.starterCards.prefix(3)) { card in
                                CardPreviewView(card: card)
                            }
                        }
                        .padding(.horizontal, AppConstants.largePadding)
                    }
                }
            }
            
            Spacer()
            
            // Action Button
            Button(action: {
                Task {
                    await cardsViewModel.assignStarterCards()
                }
            }) {
                HStack {
                    if cardsViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "gift.fill")
                    }
                    
                    Text(cardsViewModel.isLoading ? "Получение карт..." : "Получить стартовые карты")
                        .fontWeight(.medium)
                }
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppConstants.padding)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .fill(Color.accentColor)
                )
            }
            .disabled(cardsViewModel.isLoading)
            .padding(.horizontal, AppConstants.largePadding)
            
            // Error Message
            if cardsViewModel.showError {
                Text(cardsViewModel.errorMessage ?? "Произошла ошибка")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppConstants.largePadding)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            Task {
                await cardsViewModel.checkStarterCards()
            }
        }
    }
}

struct CardPreviewView: View {
    let card: CardResponse
    
    var body: some View {
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
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.smallCornerRadius))
            
            Text(card.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100)
    }
}

#Preview {
    StarterCardsView()
        .environmentObject(CardsViewModel())
} 