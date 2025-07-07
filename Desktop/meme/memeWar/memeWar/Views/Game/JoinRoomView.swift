//
//  JoinRoomView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct JoinRoomView: View {
    @EnvironmentObject var roomViewModel: RoomViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var roomCode = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("Присоединиться к комнате")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Введите код комнаты")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Код комнаты")
                            .font(.headline)
                        
                        TextField("Введите код", text: $roomCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await roomViewModel.joinRoomByCode(code: roomCode)
                        dismiss()
                    }
                }) {
                    HStack {
                        if roomViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.right")
                        }
                        Text("Присоединиться")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(roomCode.isEmpty || roomViewModel.isLoading)
            }
            .padding()
            .navigationTitle("Присоединиться")
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

#Preview {
    JoinRoomView()
        .environmentObject(RoomViewModel())
} 