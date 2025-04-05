import SwiftUI

struct ScoreBoardView: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        let round = gameManager.currentRound
        let roundString = round < 3 ? "\(round+1)/3" : "\(round - 1)"

        VStack(spacing: 12) {
            Text("Tour \(roundString)")
                .font(.title)
                .fontWeight(.bold)

            // Player Names
            HStack {
                ForEach(gameManager.players, id: \.self) { name in
                    Text(name.uppercased())
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }

            // Tricks and Scores
            HStack {
                ForEach(gameManager.players, id: \.self) { player in
                    let totalTricks = gameManager.playerTricks[player]?.reduce(0, +) ?? 0
                    let scoreArray = gameManager.scores[player] ?? []
                    let score = round > 0 ? scoreArray[round-1] : 0
                    HStack {
                        Text("\(totalTricks)")
                        Text("\(score)")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Current round bets
            HStack {
                ForEach(gameManager.players, id: \.self) { player in
                    let bets = gameManager.playerBets[player] ?? []
                    let bet = round < bets.count ? bets[round] : -1
                    if bet > -1 {
                        Text("\(bet)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("–")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(4)
            .background {
                let expected = max(round - 1, 1)
                if let total = gameManager.totalRoundBets() {
                    let diff = total - expected
                    if diff == 0 {
                        Color.clear
                    } else if diff > 0 {
                        Color.red.opacity(0.2 * Double(abs(diff)))
                    } else if diff < 0 {
                        Color.blue.opacity(0.2 * Double(abs(diff)))
                    }
                } else {
                    Color.clear
                }
            }
            .cornerRadius(5)
        }
        .padding()
    }
}

#Preview {
    let gameManager = GameManager()
    gameManager.loadPreviewData()
    return ScoreBoardView()
        .environmentObject(gameManager)
}
