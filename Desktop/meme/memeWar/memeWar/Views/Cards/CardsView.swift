//
//  CardsView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct CardsView: View {
    @EnvironmentObject var cardsViewModel: CardsViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                
                Text("Мои карты")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Здесь будут ваши карты")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Карты")
    }
}

#Preview {
    CardsView()
        .environmentObject(CardsViewModel())
} 