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
    
    private var firstPlayer: String? { gameManager.players.indices.contains(0) ? gameManager.players[0] : nil }
    private var secondPlayer: String? { gameManager.players.indices.contains(1) ? gameManager.players[1] : nil }
    private var thirdPlayer: String? { gameManager.players.indices.contains(2) ? gameManager.players[2] : nil }
    
    private var maxForSecondPlayer: Int {
        guard let firstPlayer else { return 0 }
        let firstValue = tricks[firstPlayer] ?? 0
        return max(0, gameManager.cardsForCurrentRound - firstValue)
    }
    
    private var canSubmit: Bool {
        let normalized = gameManager.normalizedTricksForCurrentRound(from: tricks)
        let total = gameManager.players.reduce(0) { $0 + (normalized[$1] ?? 0) }
        return total == gameManager.cardsForCurrentRound
    }

    var body: some View {
        ScoreBoardView()
            .environmentObject(gameManager)
            .onAppear {
                resetTricksForRound()
            }
            .onChange(of: gameManager.currentRound) { _, _ in
                resetTricksForRound()
            }
        
        VStack(alignment: .center, spacing: 16) {
            Text("Saisis les résultats").bold()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                // First player's picker
                Group {
                    if let firstPlayer {
                        Picker("", selection: Binding(
                            get: { tricks[firstPlayer] ?? 0 },
                            set: { newValue in updateTrick(for: firstPlayer, value: newValue) }
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
                }

                // Second player's picker (range constrained by first)
                Group {
                    if let secondPlayer {
                        Picker("", selection: Binding(
                            get: { min(tricks[secondPlayer] ?? 0, maxForSecondPlayer) },
                            set: { newValue in updateTrick(for: secondPlayer, value: newValue) }
                        )) {
                            ForEach(0...maxForSecondPlayer, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .clipped()
                    }
                }

                // Third value (computed, not interactive)
                Group {
                    let normalized = gameManager.normalizedTricksForCurrentRound(from: tricks)
                    Text("\(thirdPlayer.map { normalized[$0] ?? 0 } ?? 0)")
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .foregroundColor(.secondary)
                }
            }
        }

        Button("Confirme les résultats") {
            let normalized = gameManager.normalizedTricksForCurrentRound(from: tricks)
            gameManager.submitTricks(tricks: normalized)
        }
        .padding()
        .disabled(!canSubmit)
    }
    
    private func resetTricksForRound() {
        let defaults = gameManager.suggestedTricksForCurrentRoundFromBets()
        tricks = gameManager.normalizedTricksForCurrentRound(from: defaults)
    }
    
    private func updateTrick(for player: String, value: Int) {
        var updated = tricks
        updated[player] = value
        tricks = gameManager.normalizedTricksForCurrentRound(from: updated)
    }
}

#Preview {
    let gameManager = GameManager()
    gameManager.loadPreviewData(phase: .betInput)
    return ScoreInputView()
        .environmentObject(gameManager)
}
