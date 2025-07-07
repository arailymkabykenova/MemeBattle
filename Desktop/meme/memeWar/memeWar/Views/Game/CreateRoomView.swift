//
//  CreateRoomView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct CreateRoomView: View {
    @EnvironmentObject var roomViewModel: RoomViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var maxPlayers = 4
    @State private var isPublic = true
    @State private var ageGroup = "18+"
    
    private let ageGroups = ["13+", "16+", "18+", "21+"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Создать комнату")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Максимум игроков")
                            .font(.headline)
                        
                        Stepper("\(maxPlayers) игроков", value: $maxPlayers, in: 2...8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Публичная комната")
                            .font(.headline)
                        
                        Toggle("Доступна для поиска", isOn: $isPublic)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Возрастная группа")
                            .font(.headline)
                        
                        Picker("Возрастная группа", selection: $ageGroup) {
                            ForEach(ageGroups, id: \.self) { group in
                                Text(group).tag(group)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await roomViewModel.createRoom(
                            maxPlayers: maxPlayers,
                            isPublic: isPublic,
                            ageGroup: ageGroup
                        )
                        dismiss()
                    }
                }) {
                    HStack {
                        if roomViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                        }
                        Text("Создать комнату")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(roomViewModel.isLoading)
            }
            .padding()
            .navigationTitle("Создать комнату")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

 