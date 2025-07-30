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
                tricks[gameManager.players[0]] = 0
                tricks[gameManager.players[1]] = 0
                tricks["toto"] = gameManager.cardsForCurrentRound
            }
        
        Form {
            Section(header: Text("Saisis les résultats").bold()) {
                HStack {
                    Text(gameManager.players[0])
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("Tricks", selection: Binding(
                        get: { tricks[gameManager.players[0]] ?? 0 },
                        set: { tricks[gameManager.players[0]] = $0 }
                    )) {
                        ForEach(0...gameManager.cardsForCurrentRound, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 80)
                    .clipped()
                }

                HStack {
                    Text(gameManager.players[1])
                        .frame(maxWidth: .infinity, alignment: .leading)

                    let maxDD = gameManager.cardsForCurrentRound - (tricks[gameManager.players[0]] ?? 0)
                    Picker("Tricks", selection: Binding(
                        get: { tricks[gameManager.players[1]] ?? 0 },
                        set: { tricks[gameManager.players[1]] = $0 }
                    )) {
                        ForEach(0...max(0, maxDD), id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 80)
                    .clipped()
                }

                HStack {
                    Text("toto")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    let totoTricks = gameManager.cardsForCurrentRound - (tricks[gameManager.players[0]] ?? 0) - (tricks[gameManager.players[1]] ?? 0)
                    Text("\(totoTricks)")
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
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
