//
//  BetInputView 2.swift
//  Whist Scores
//
//  Created by Tony Buffard on 2025-04-04.
//


import SwiftUI

struct ScoreInputView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @State private var tricks: [String: Int] = [:]

    var body: some View {
        ScoreBoardView()
            .environmentObject(gameManager)
            .onAppear {
                let defaults = gameManager.suggestedTricksForCurrentRoundFromBets()
                tricks = defaults
            }
            .onChange(of: gameManager.currentRound) { _, _ in
                let defaults = gameManager.suggestedTricksForCurrentRoundFromBets()
                tricks = defaults
            }
        
        VStack(alignment: .center, spacing: 16) {
            Text("Saisis les résultats").bold()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                // First player's picker
                Group {
                    Picker("", selection: Binding(
                        get: { tricks[gameManager.players[0]] ?? 0 },
                        set: { tricks[gameManager.players[0]] = $0 }
                    )) {
                        ForEach(0...gameManager.cardsForCurrentRound, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                }

                // Second player's picker (range constrained by first)
                Group {
                    let maxDD = max(0, gameManager.cardsForCurrentRound - (tricks[gameManager.players[0]] ?? 0))
                    Picker("", selection: Binding(
                        get: { tricks[gameManager.players[1]] ?? 0 },
                        set: { tricks[gameManager.players[1]] = $0 }
                    )) {
                        ForEach(0...maxDD, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                }

                // Third value (computed, not interactive)
                Group {
                    let totoTricks = gameManager.cardsForCurrentRound - (tricks[gameManager.players[0]] ?? 0) - (tricks[gameManager.players[1]] ?? 0)
                    Text("\(max(0, totoTricks))")
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onChange(of: tricks) { _, newValue in
            let gg = newValue["gg"] ?? 0
            let dd = newValue["dd"] ?? 0
            let remaining = gameManager.cardsForCurrentRound - gg - dd
            tricks["toto"] = remaining
        }

        Button("Confirme les résultats") {
            gameManager.submitTricks(tricks: tricks)
        }
        .padding()
        .disabled(["gg", "dd", "toto"].reduce(0) { $0 + (tricks[$1] ?? 0) } != gameManager.cardsForCurrentRound)
    }
}

#Preview {
    let gameManager = GameManager()
    gameManager.loadPreviewData(phase: .betInput)
    return ScoreInputView()
        .environmentObject(gameManager)
}
