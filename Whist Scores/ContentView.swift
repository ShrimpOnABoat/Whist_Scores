//
//  ContentView.swift
//  Whist Scores
//
//  Created by Tony Buffard on 2025-04-03.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
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
}

#Preview {
    ContentView()
        .environmentObject(GameManager())
}
