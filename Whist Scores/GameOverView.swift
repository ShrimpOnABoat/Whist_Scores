import SwiftUI

struct GameOverView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var uploadStatus: String?

    var body: some View {
        VStack {
            Text("Game Over")
                .font(.largeTitle)
                .padding()

            List {
                ForEach(gameManager.players.sorted { (gameManager.scores[$0]?[gameManager.currentRound] ?? 0) > (gameManager.scores[$1]?[gameManager.currentRound] ?? 0) }, id: \.self) { player in
                    HStack {
                        Text(player)
                        Spacer()
                        Text("\(gameManager.scores[player]?[gameManager.currentRound] ?? 0)")
                    }
                }
            }

            if let status = uploadStatus {
                Text(status)
                    .foregroundColor(.gray)
                    .padding()
            }

            Button("Upload Scores to iCloud") {
                uploadStatus = "Uploading..."
                gameManager.uploadFinalScores { success in
                    uploadStatus = success ? "Upload Successful!" : "Upload Failed"
                }
            }
            .padding()

            Button("Play Again") {
                gameManager.resetGame()
            }
            .padding()
        }
    }
}

#Preview {
    GameOverView()
        .environmentObject(GameManager())
}
