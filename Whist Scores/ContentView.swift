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

    var body: some View {
        NavigationView {
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
            }
            .navigationTitle("Whist Scores")
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
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GameManager())
}
