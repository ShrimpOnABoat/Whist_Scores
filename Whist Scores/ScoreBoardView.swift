import SwiftUI

struct ScoreBoardView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showHistory = false

    var body: some View {
        let round = gameManager.currentRound
        let roundString = round < 3 ? "\(round+1)/3" : round < 11 ? "\(round - 1)" : "10"

        ZStack {
            VStack(spacing: 12) {
                Text("Tour \(roundString)")
                    .font(.title)
                    .fontWeight(.bold)

                // Player Names
                HStack {
                    ForEach(gameManager.players, id: \.self) { name in
                        ZStack(alignment: .trailing) {
                            HStack(spacing: 4) {
                                Text(name.uppercased())
                                    .font(.headline)
                                    .foregroundColor(gameManager.dealer == name ? .white : .black)

                                if gameManager.dealer == name {
                                    DealerButton(size: 25)
                                        .offset(x: 5)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(6)
                            .background(
                                gameManager.dealer == name ?
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.8)) :
                                    nil
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // Bonus cards
                HStack {
                    ForEach(gameManager.players, id: \.self) { name in
                        ZStack(alignment: .trailing) {
                            if let bonus = gameManager.bonusCards[name] {
                                if bonus == 1 {
                                    OneCardIcon(size: 40)
                                } else if bonus == 2 {
                                    TwoCardsIcon(size: 40)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // Tricks and Scores
                HStack {
                    ForEach(gameManager.players, id: \.self) { player in
                        let totalTricks = gameManager.playerBets[player]?.reduce(0, +) ?? 0
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
        .onTapGesture {
            if gameManager.currentRound > 0 {
                showHistory = true
            }
        }
        .sheet(isPresented: $showHistory) {
            RoundHistoryView(isPresented: $showHistory)
                .environmentObject(gameManager)
        }
    }
}

#Preview {
    let gameManager = GameManager()
    gameManager.loadPreviewData()
    return ScoreBoardView()
        .environmentObject(gameManager)
}
