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
        let streaks: [String: Int] = Dictionary(uniqueKeysWithValues: gameManager.players.map { ($0, gameManager.consecutiveWins(for: $0)) })
        let maxStreak: Int = streaks.values.max() ?? 0

        ZStack {
            VStack(spacing: 12 * M) {
                Text("Tour \(roundString)")
                    .font(.system(size: 28 * M, weight: .bold))

                // Player Names
                HStack {
                    ForEach(gameManager.players, id: \.self) { name in
                        ZStack {
                            let isDealer = gameManager.dealer == name
                            let isPerfect = gameManager.perfectStreak[name] == true

                            HStack(spacing: 8 * M) {
                                VStack {
                                    // Crown aligned above the dot
//                                    if gameManager.isMaster[name] == true {
//                                        Image(systemName: "crown.fill")
//                                            .font(.system(size: 12 * M))
//                                            .foregroundColor(.yellow)
//                                            .shadow(radius: 1 * M)
//                                            .accessibilityLabel(Text("Master of the month"))
//                                    }
                                    
                                    // Red dot (or spacer to keep alignment)
                                    if isPerfect {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8 * M, height: 8 * M)
                                    }
                                }

                                Text(name.uppercased())
                                    .font(.system(size: 18 * M, weight: .semibold))
                                    .foregroundColor(isDealer ? .white : .primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(.horizontal, 10 * M)
                            .padding(.vertical, 6 * M)
                            .frame(minWidth: 90 * M, maxWidth: .infinity, alignment: .center)
                            .padding(.trailing, isDealer ? (25 * M + 6 * M) : 0) // reserve space for the overlaid dealer button
                            .background(
                                isDealer ?
                                    RoundedRectangle(cornerRadius: 8 * M)
                                        .fill(Color.gray.opacity(0.8)) :
                                    nil
                            )
                            .overlay(alignment: .trailing) {
                                if isDealer {
                                    DealerButton(size: 25 * M)
                                        .padding(.trailing, 10 * M) // keep inside the grey background
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // Bonus cards
                HStack {
                    ForEach(gameManager.players, id: \.self) { name in
                        ZStack(alignment: .trailing) {
                            let isLastPlayer = (gameManager.lastPlayer ?? "") == name
                            if let bonus = gameManager.bonusCards[name] {
                                ZStack {
                                    if isLastPlayer {
                                        Circle()
                                            .fill(Color.red)
                                            .blur(radius: 10 * M)
                                            .frame(width: 40 * M, height: 40 * M)
                                    }
                                    if bonus == 1 {
                                        OneCardIcon(size: 40 * M)
                                    } else if bonus == 2 {
                                        TwoCardsIcon(size: 40 * M)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // Tricks and Scores
                tricksAndScoresRow(M: M, round: round, streaks: streaks, maxStreak: maxStreak)

                // Current round bets
                currentRoundBetsRow(M: M, round: round)
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
    // MARK: - Helper Views

    private func tricksAndScoresRow(M: CGFloat, round: Int, streaks: [String:Int], maxStreak: Int) -> some View {
        HStack {
            ForEach(gameManager.players, id: \.self) { player in
                let totalTricks = gameManager.playerBets[player]?.reduce(0, +) ?? 0
                let scoreArray = gameManager.scores[player] ?? []
                let score = round > 0 ? scoreArray[round-1] : 0
                HStack {
                    Text("\(totalTricks)")
                    Text("\(score)")
                        .bold()
                    if maxStreak > 3 && streaks[player] == maxStreak {
                        Text("+5")
                            .foregroundColor(.green)
                    }
                }
                .font(.system(size: 20 * M))
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func currentRoundBetsRow(M: CGFloat, round: Int) -> some View {
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
        .background(betsBackgroundColor(round: round))
        .cornerRadius(5 * M)
    }

    private func betsBackgroundColor(round: Int) -> Color {
        let expected = max(round - 1, 1)
        guard let total = gameManager.totalRoundBets() else { return .clear }
        let diff = total - expected
        if diff == 0 {
            return .clear
        } else if diff > 0 {
            return Color.red.opacity(0.2 * Double(abs(diff)))
        } else {
            return Color.blue.opacity(0.2 * Double(abs(diff)))
        }
    }
}

#Preview {
    let gameManager = GameManager()
    gameManager.loadPreviewData()
    return ScoreBoardView()
        .environmentObject(gameManager)
}
