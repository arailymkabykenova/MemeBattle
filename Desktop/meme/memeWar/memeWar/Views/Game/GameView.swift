//
//  GameView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var roomViewModel: RoomViewModel
    @State private var showingCreateRoom = false
    @State private var showingJoinRoom = false
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Meme War")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Найдите игру или создайте свою")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                Button(action: {
                    showingCreateRoom = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Создать комнату")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showingJoinRoom = true
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Присоединиться к комнате")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Игра")
        .sheet(isPresented: $showingCreateRoom) {
            CreateRoomView()
                .environmentObject(roomViewModel)
        }
        .sheet(isPresented: $showingJoinRoom) {
            JoinRoomView()
                .environmentObject(roomViewModel)
        }
    }
}

#Preview {
    GameView()
        .environmentObject(RoomViewModel())
} 