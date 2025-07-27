import SwiftUI

struct GameOverView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var uploadStatus: String?

    var body: some View {
        VStack {
            Text("Game Over")
                .font(.largeTitle)
                .padding()
            
            ScoreBoardView()
                .environmentObject(gameManager)

            if let winnerName = gameManager.players.first(where: { gameManager.determinePosition(for: $0) == 1 }) {
                Text("BRAVO \(winnerName) !!")
                    .font(.title)
                    .foregroundColor(.green)
                    .padding(.bottom, 5)
            }

            if let status = uploadStatus {
                Text(status)
                    .foregroundColor(.gray)
                    .padding()
            }

            Button("Nouvelle partie") {
                gameManager.newGame()
            }
            .padding()
        }
    }
}

#Preview {
    GameOverView()
        .environmentObject(GameManager())
}
