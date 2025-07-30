//
//  ContentView.swift
//  Whist Scores
//
//  Created by Tony Buffard on 2025-04-03.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showRestartConfirmation = false
    @State private var selectedLoser: String? = nil
    @State private var selectedMonths: Int? = nil

    var body: some View {
        NavigationStack {
            VStack {
                Group {
                    switch gameManager.phase {
                    case .betInput:
                        BetInputView()
                    case .scoreInput:
                        ScoreInputView()
                    case .gameOver:
                        GameOverView()
                    }
                }
                Text("\(gameManager.debugString)")
            }
            .frame(maxWidth: 600)
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Redémarrer") {
                        showRestartConfirmation = true
                    }
                }
            }
            .alert(isPresented: $showRestartConfirmation) {
                Alert(
                    title: Text("Redémarrer la partie?"),
                    message: Text("Cette action effacera toutes les données de la partie en cours."),
                    primaryButton: .destructive(Text("Redémarrer")) {
                        gameManager.newGame()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $gameManager.needsLeftPlayerSelection) {
                VStack {
                    Text("Y a qui à ta gauche, Toto?")
                        .font(.headline)
                        .padding()

                    HStack {
                        Button("gg") {
                            gameManager.selectLeftPlayer(player: "gg")
                            gameManager.needsLeftPlayerSelection = false
                        }
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)

                        Button("dd") {
                            gameManager.selectLeftPlayer(player: "dd")
                            gameManager.needsLeftPlayerSelection = false
                        }
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .sheet(isPresented: $gameManager.needsLoser) {
                VStack(spacing: 20) {
                    Text("Qui a perdu le mois dernier?")
                        .font(.headline)

                    HStack(spacing: 16) {
                        ForEach(["gg", "dd", "toto", "personne"], id: \.self) { name in
                            Button(name) {
                                selectedLoser = name == "personne" ? nil : name
                            }
                            .padding()
                            .background(selectedLoser == name || (name == "personne" && selectedLoser == nil) ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }

                    if selectedLoser != nil {
                        Text("Combien de mois?")
                            .font(.subheadline)

                        HStack(spacing: 16) {
                            Button("1") {
                                selectedMonths = 1
                            }
                            .padding()
                            .background(selectedMonths == 1 ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                            .cornerRadius(8)

                            Button("2 ou plus") {
                                selectedMonths = 2
                            }
                            .padding()
                            .background(selectedMonths == 2 ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }

                    Button("Valider") {
                        if let name = selectedLoser, let months = selectedMonths {
                            gameManager.setManualLoser(player: name, months: months)
                        } else {
                            gameManager.setManualLoser(player: nil, months: 0)
                        }
                        gameManager.needsLoser = false
                    }
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GameManager())
}
