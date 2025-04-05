import SwiftUI

struct BetInputView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @State private var bets: [String: Int] = [:]

    var body: some View {
        ScoreBoardView()
            .environmentObject(gameManager)
        
            Form {
                Section(header: Text("Entre les mises").bold()) {
                ForEach(gameManager.players, id: \.self) { player in
                    HStack {
                        Text(player)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if shouldShowDice(for: player) {
                            Text("🎲")
                                .frame(height: 80)
                                .frame(maxWidth: .infinity)
                                .onAppear {
                                    bets[player] = -1
                                }
                        } else {
                            Picker("Bet", selection: Binding(
                                get: { bets[player] ?? -1 },
                                set: { bets[player] = $0 }
                            )) {
                                if bets[player] == nil {
                                    Text("–").tag(-1)
                                }
                                ForEach(0...gameManager.cardsForCurrentRound, id: \.self) { value in
                                    Text("\(value)").tag(value)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 80)
                            .clipped()
                        }
                    }
                }
            }
        }

        Text("GG: \(String(describing: bets["gg"]))  DD: \(String(describing: bets["dd"]))  Toto: \(String(describing: bets["toto"]))")
        
        Button("Confirme les mises") {
            gameManager.submitBets(bets: bets)
        }
        .padding()
        .disabled(gameManager.players.contains { bets[$0] == nil })
    }

    func shouldShowDice(for player: String) -> Bool {
        guard gameManager.currentRound > 2 else { return false }
        let roundIndex = max(gameManager.currentRound - 1, 0)
        let roundScores: [(player: String, score: Int)] = gameManager.players.compactMap {
            if let score = gameManager.scores[$0]?[roundIndex] {
                return ($0, score)
            } else {
                return nil
            }
        }

        guard let playerScore = roundScores.first(where: { $0.player == player })?.score,
              playerScore > 0 else {
            return false
        }

        let sortedScores = roundScores.sorted { $0.score > $1.score }

        guard let highest = sortedScores.first, highest.player == player,
              let secondHighest = sortedScores.dropFirst().first else {
            return false
        }

        return playerScore >= 2 * secondHighest.score
    }
}

#Preview {
    let gameManager = GameManager()
    gameManager.loadPreviewData(phase: .betInput)
    return BetInputView()
        .environmentObject(gameManager)
}
