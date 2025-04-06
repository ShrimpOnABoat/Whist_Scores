//
//  RoundHistoryView.swift
//  Whist Scores
//
//  Created by Tony Buffard on 2025-04-06.
//

//
//  RoundHistoryView.swift
//  Whist
//
//  Created by Tony Buffard on 2025-02-07.
//

import SwiftUI

struct RoundHistoryView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            ScrollView {
                VStack(spacing: 5) {
                    headerRow()
                    
                    ForEach(0...gameManager.currentRound - 1, id: \.self) { round in
                        roundRow(round: round)
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 500)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
    
    // MARK: - Header Row
    func headerRow() -> some View {
        HStack {
            Text("Tour").frame(width: 50).bold().foregroundColor(.primary)
 
            ForEach(gameManager.players, id: \.self) { name in
                Text(name).frame(width: 100).bold().foregroundColor(.primary)
            }
        }
        .padding(.vertical, 5)
        .cornerRadius(5)
    }
    
    // MARK: - Round Row
    func roundRow(round: Int) -> some View {

        let cardsForCurrentRound = round < 3 ? 1 : round - 1
        let announcedTotal = gameManager.players.reduce(0) {
            $0 + (gameManager.playerBets[$1]?[round] ?? 0)
        }
        
        let backgroundColor: Color? = {
            if announcedTotal < cardsForCurrentRound {
                    let opacity = CGFloat(cardsForCurrentRound - announcedTotal) * 0.2
                    return Color.blue.opacity(opacity)
                }
                if announcedTotal > cardsForCurrentRound {
                    let opacity = CGFloat(announcedTotal - cardsForCurrentRound) * 0.2
                    return Color.red.opacity(opacity)
                }
            return nil
        }()
        
        return HStack {
            Text(round < 3 ? "1" : "\(cardsForCurrentRound)")
                .frame(width: 50)
                .bold()
                .padding(.vertical, 5)
            
            ForEach(gameManager.players, id: \.self) { player in
                HStack {
                    HStack() {
                        Text("\(gameManager.playerTricks[player]?[round] ?? 0) / \(gameManager.playerBets[player]?[round] ?? 0)")
                    }

                    Text("\(gameManager.scores[player]?[round] ?? 0)")
                        .bold()
                }
                .frame(width: 100)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor ?? Color.clear)
        )
        .cornerRadius(5)
    }
}

#Preview {
    let gameManager = GameManager()
    gameManager.loadPreviewData(phase: .scoreInput)
    return RoundHistoryView(isPresented: .constant(true))
        .environmentObject(gameManager)
}
