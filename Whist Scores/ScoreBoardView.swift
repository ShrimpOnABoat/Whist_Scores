import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ScoreBoardView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showHistory = false

    var body: some View {
        #if os(iOS)
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        #else
        let isPad = false
        #endif

        let M: CGFloat = isPad ? 2.0 : 1.0

        let round = gameManager.currentRound
        let roundString = round < 3 ? "\(round+1)/3" : round < 11 ? "\(round - 1)" : "10"

        ZStack {
            VStack(spacing: 12 * M) {
                Text("Tour \(roundString)")
                    .font(.system(size: 28 * M, weight: .bold))

                // Player Names
                HStack {
                    ForEach(gameManager.players, id: \.self) { name in
                        ZStack(alignment: .trailing) {
                            HStack(spacing: 4 * M) {
                                Text(name.uppercased())
                                    .font(.system(size: 18 * M, weight: .semibold))
                                    .foregroundColor(gameManager.dealer == name ? .white : .black)

                                if gameManager.dealer == name {
                                    DealerButton(size: 25 * M)
                                        .offset(x: 5 * M)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(6 * M)
                            .background(
                                gameManager.dealer == name ?
                                    RoundedRectangle(cornerRadius: 8 * M)
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
                                    OneCardIcon(size: 40 * M)
                                } else if bonus == 2 {
                                    TwoCardsIcon(size: 40 * M)
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
                        .font(.system(size: 20 * M))
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
                                .font(.system(size: 18 * M, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("–")
                                .font(.system(size: 18 * M))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(4 * M)
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
                .cornerRadius(5 * M)
            }
            .padding(12 * M)
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
