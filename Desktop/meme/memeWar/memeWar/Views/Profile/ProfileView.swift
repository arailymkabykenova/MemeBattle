//
//  ProfileView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                if let user = authViewModel.currentUser {
                    Text(user.nickname ?? "Пользователь")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Рейтинг: \(Int(user.rating))")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    Text("Профиль")
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await authViewModel.logout()
                }
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Выйти")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .navigationTitle("Профиль")
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
} 