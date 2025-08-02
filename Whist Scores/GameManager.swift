//
//  GameManager.swift
//  Whist Scores
//
//  Created by Tony Buffard on 2025-04-03.
//

// TODO: back button when inputing scores, in case of a mistake in input bets.
// TODO: save state and reload in case of crash

import Foundation
import CloudKit

enum GamePhase: String, Codable {
    case betInput
    case scoreInput
    case gameOver
}

struct GameState: Codable {
    var dealer: String
    var loser: Loser
    var players: [String]
    var currentRound: Int
    var phase: GamePhase
    var bonusCards: [String: Int]
    var scores: [String: [Int]]
    var playerBets: [String: [Int]]
    var playerTricks: [String: [Int]]
    var lastPlayer: String?
    var perfectStreak: [String: Bool]
    var isMaster: [String: Bool]
}

class GameManager: ObservableObject {
    @Published var players: [String] = ["gg", "dd", "toto"]
    @Published var dealer: String = ["gg", "dd", "toto"].randomElement() ?? "gg"
    @Published var needsLeftPlayerSelection = true
    
    @Published var currentRound: Int = 0 // The first round is 0, the last one is 11
    @Published var phase: GamePhase = .betInput
    @Published var bonusCards: [String: Int] = [:]
    
    @Published var scores: [String: [Int]] = [:]
    @Published var playerBets: [String: [Int]] = [:]
    @Published var playerTricks: [String: [Int]] = [:]
    @Published var lastPlayer: String?
    @Published var perfectStreak: [String: Bool] = ["gg": true, "dd": true, "toto": true]
    
    var loser: Loser?
    @Published var needsLoser: Bool = false
    
    @Published var isMaster: [String: Bool] = [:]
    
    @Published var debugString: String = "" {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.debugString = ""
            }
        }
    }
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    var cardsForCurrentRound: Int {
        currentRound < 3 ? 1 : currentRound - 1
    }
    
    static let SM = ScoresManager.shared
    
    func totalRoundBets() -> Int? {
        var total = 0
        for player in players {
            guard let bets = playerBets[player], bets.count > currentRound else {
                return nil
            }
            total += bets[currentRound]
        }
        return total
    }
    
    var betsCompleted: Bool {
        for player in players {
            guard let bets = playerBets[player], bets.count > currentRound else {
                return false
            }
        }
        return true
    }
    
    init() {
        // Load the saved state if there's one
        if let data = UserDefaults.standard.data(forKey: "savedGameState"),
           let loadedState = try? JSONDecoder().decode(GameState.self, from: data) {
            self.dealer = loadedState.dealer
            self.loser = loadedState.loser
            self.players = loadedState.players
            self.currentRound = loadedState.currentRound
            self.phase = loadedState.phase
            self.bonusCards = loadedState.bonusCards
            self.scores = loadedState.scores
            self.playerBets = loadedState.playerBets
            self.playerTricks = loadedState.playerTricks
            self.lastPlayer = loadedState.lastPlayer
            self.perfectStreak = loadedState.perfectStreak
            self.isMaster = loadedState.isMaster
            return
        } else {
            // Else find the previous month loser
            Task {
                if let foundLoser = await GameManager.SM.findLoser() {
                    self.loser = foundLoser
                    print("Updated \(foundLoser.player)'s monthlyLosses to \(foundLoser.losingMonths)")
                } else {
                    print("No loser identified or loser had 0 losing months.")
                }
                let masters = await GameManager.SM.setMaster()
                await MainActor.run {
                    self.isMaster = masters
                    print("isMaster for current month: \(masters)")
                }
            }
        }
    }
    
    //MARK: Game Logic
    func newGame() {
        UserDefaults.standard.removeObject(forKey: "savedGameState")
        lastPlayer = nil
        perfectStreak = ["gg": true, "dd": true, "toto": true]
        advanceDealer()
        self.currentRound = -1
        self.scores = [:]
        self.playerBets = [:]
        self.playerTricks = [:]
        self.bonusCards = [:]
        self.phase = .betInput
        
        advanceToNextRound()
    }
    
    func advanceToNextRound() {
        currentRound += 1
        advanceDealer()
        assignBonusCards()
        
        if currentRound >= 12 {
            uploadFinalScores { success in
            }
            phase = .gameOver
        } else {
            phase = .betInput
        }
    }
    
    func goBack() {
        switch phase {
        case .scoreInput:
            // Going back to bets: switch phase and remove last recorded data
            for player in players {
                playerBets[player]?.removeLast()
            }
            phase = .betInput

        case .betInput:
            if currentRound > 0 {
                currentRound -= 1
                for player in players {
                    playerTricks[player]?.removeLast()
                    scores[player]?.removeLast()
                }
                phase = .scoreInput
            }

        default:
            break
        }

        saveState()
    }
    
    func advanceDealer() {
        if let currentIndex = players.firstIndex(of: dealer) {
            let nextIndex = (currentIndex + 1) % players.count
            dealer = players[nextIndex]
        }
    }
    
    func selectLeftPlayer(player: String) {
        if player == "dd" {
            players = ["dd", "gg", "toto"]
        }
    }
    
    func updateScores() {
        for player in players {
            let bet = playerBets[player]?[currentRound] ?? 0
            let tricks = playerTricks[player]?[currentRound] ?? 0
            let previousScore: Int = scores[player]?.last ?? 0
            let score: Int
            
            if tricks == bet {
                if tricks == cardsForCurrentRound {
                    score = tricks * 10 + 10
                } else {
                    score = tricks * 5 + 10
                }
            } else {
                score = -abs(tricks - bet) * 5
            }
            
            if scores[player] == nil {
                scores[player] = [score + previousScore]
            } else {
                scores[player]?.append(score + previousScore)
            }
        }
        
        if currentRound == 11 {
            let totalBets: [String: Int] = players.reduce(into: [:]) { result, player in
                result[player] = playerBets[player]?.reduce(0, +) ?? 0
            }
            
            let sorted = totalBets.sorted { $0.value > $1.value }
            if sorted.count >= 2, sorted[0].value > sorted[1].value {
                let winner = sorted[0].key
                if var roundScores = scores[winner], currentRound < roundScores.count {
                    roundScores[currentRound] += 15
                    scores[winner] = roundScores
                }
            }
        }
    }
    
    //MARK: Inputs
    func submitBets(bets: [String: Int]) {
        var processedBets = bets
        
        // Assign random bet to first player
        for player in players {
            if processedBets[player] == -1 {
                processedBets[player] = Int.random(in: 0...cardsForCurrentRound)
            }
        }
        
        // Store the bets for this round
        for player in players {
            if playerBets[player] == nil {
                playerBets[player] = []
            }
            playerBets[player]?.append(processedBets[player] ?? 0)
        }
        
        self.phase = .scoreInput
        saveState()
    }
    
    func submitTricks(tricks: [String: Int]) {
        for player in players {
            if playerTricks[player] == nil {
                playerTricks[player] = []
            }
            playerTricks[player]?.append(tricks[player] ?? 0)

            // Update the perfectStreak for each player
            if let bet = playerBets[player]?.last, let trick = playerTricks[player]?.last {
                if bet != trick {
                    perfectStreak[player] = false
                }
            }
        }
        
        updateScores()
        saveState()
        advanceToNextRound()
    }
    
    //MARK: Upload score
    func uploadFinalScores(completion: @escaping (Bool) -> Void) {
        let ggScore = scores["gg"]?.last ?? 0
        let ddScore = scores["dd"]?.last ?? 0
        let totoScore = scores["toto"]?.last ?? 0

        let positions: [String: Int] = Dictionary(uniqueKeysWithValues: players.map {
            ($0, determinePosition(for: $0))
        })

        let gameScore = GameScore(
            date: Date(),
            ggScore: ggScore,
            ddScore: ddScore,
            totoScore: totoScore,
            ggPosition: positions["gg"],
            ddPosition: positions["dd"],
            totoPosition: positions["toto"],
            ggConsecutiveWins: consecutiveWins(for: "gg"),
            ddConsecutiveWins: consecutiveWins(for: "dd"),
            totoConsecutiveWins: consecutiveWins(for: "toto")
        )

        // Save the updated scores array.
        Task {
            do {
                try await ScoresManager.shared.saveScore(gameScore)
                // Log success on the main thread if necessary, though logger should handle it
                await MainActor.run { // Ensure logging happens on main thread if it interacts with UI state implicitly
                     print("Score saved successfully for game ending \(gameScore.date)")
                }
            } catch {
                 // Handle the error (e.g., display an alert to the user).
                await MainActor.run {
                     print("Failed to save score: \(error.localizedDescription)")
                     print("Score data that failed to save: \(gameScore)")
                }
            }
        }
    }
    
    private func consecutiveWins(for player: String) -> Int {
        guard let bets = playerBets[player], let tricks = playerTricks[player] else { return 0 }

        var count = 0
        for i in (0..<min(bets.count, tricks.count)) {
            if bets[i] == tricks[i] {
                count += 1
            } else {
                break
            }
        }
        return count
    }
    
    // MARK: Bonus cards
    
    func assignBonusCards() {
        guard currentRound >= 3 else {
            for player in players {
                bonusCards[player] = 0
            }
            return
        }

        var positionToPlayers: [Int: [String]] = [:]

        for player in players {
            let position = determinePosition(for: player)
            positionToPlayers[position, default: []].append(player)
        }

        for player in players {
            let position = determinePosition(for: player)
            
            switch position {
            case 1:
                bonusCards[player] = 0
            case 2:
                bonusCards[player] = 1
                if let loser = loser, player == loser.player, loser.losingMonths > 1 {
                    bonusCards[player] = 2
                }
            case 3:
                lastPlayer = player
                bonusCards[player] = 1
                if let loser = loser, player == loser.player {
                    bonusCards[player] = 2
                } else if
                    let score = scores[player]?.last,
                    let second = positionToPlayers[2]?.first,
                    let secondScore = scores[second]?.last,
                    score <= secondScore / 2 {
                    bonusCards[player] = 2
                }
            default:
                bonusCards[player] = 0
            }
        }
    }
    
    func determinePosition(for player: String) -> Int {
        /// Returns 1 if the player has the highest score (even in case of tie),
        /// 2 if in the middle, and 3 if last based on current and historical scores.
        
        let currentScores = players.map { ($0, scores[$0]?.last ?? 0) }
        let sortedByScore = currentScores.sorted { $0.1 > $1.1 }
        let highestScore = sortedByScore.first?.1 ?? 0
        let lowestScore = sortedByScore.last?.1 ?? 0
        let playerScore = scores[player]?.last ?? 0

        if playerScore == highestScore {
            return 1
        }

        if playerScore == lowestScore {
            let playersWithLowest = currentScores.filter { $0.1 == lowestScore }.map { $0.0 }

            if playersWithLowest.count > 1 {
                let otherPlayer = playersWithLowest.first { $0 != player }

                for round in stride(from: currentRound - 1, through: 0, by: -1) {
                    let playerScoreAtRound = scores[player]?[round] ?? Int.min
                    let otherScoreAtRound = scores[otherPlayer ?? ""]?[round] ?? Int.min

                    if playerScoreAtRound != otherScoreAtRound {
                        return playerScoreAtRound < otherScoreAtRound ? 3 : 2
                    }
                }

                // Fallback to dealer order
                if let dealerIndex = players.firstIndex(of: dealer),
                   let playerIndex = players.firstIndex(of: player),
                   let otherIndex = players.firstIndex(of: otherPlayer ?? "") {

                    let leftOfDealerIndex = (dealerIndex + 1) % players.count

                    if playerIndex == dealerIndex {
                        return 3
                    } else if otherIndex == dealerIndex {
                        return 2
                    } else if playerIndex == leftOfDealerIndex {
                        return 3
                    } else {
                        return 2
                    }
                }
            } else {
                return 3
            }
        }

        return 2
    }
    
    func suggestedTricksForCurrentRoundFromBets() -> [String: Int] {
        let round = currentRound
        // 1 card for rounds 0..2, then grows: 2 at 3, 3 at 4, etc.
        let cardsThisRound = max(round - 1, 1)

        func betFor(_ name: String) -> Int {
            let arr = playerBets[name] ?? []
            return (round < arr.count) ? max(0, arr[round]) : 0
        }

        var result: [String: Int] = [:]
        var remaining = cardsThisRound

        for i in 0..<(players.count) {
            let name = players[i]
            if i == players.count - 1 {
                result[name] = max(0, remaining)
            } else {
                let desired = betFor(name)
                let take = max(0, min(desired, remaining))
                result[name] = take
                remaining -= take
            }
        }
        return result
    }
    
    func setManualLoser(player: String?, months: Int) {
        if let name = player {
            loser = Loser(player: name, losingMonths: months)
        } else {
            loser = nil
        }
    }
    
    func loadPreviewData(phase: GamePhase = .betInput) {
        players = ["gg", "dd", "toto"]
        dealer = "gg"
        currentRound = 4
        self.phase = phase
        scores  = [
            "gg": [5, 0, 10, 30],
            "dd": [0, 10, 30, 15],
            "toto": [10, 0, 10, 15]
        ]
        playerBets = [
            "gg": [1, 0, 1, 0],
            "dd": [0, 0, 0, 0],
            "toto": [1, 0, 1, 1]
        ]
        playerTricks = [
            "gg": [1, 0, 1, 0],
            "dd": [0, 1, 0, 2],
            "toto": [0, 0, 0, 0]
        ]
        bonusCards = [
            "gg": 0,
            "dd": 1,
            "toto": 2
        ]
    }
    // MARK: Save and Load State
    func saveState() {
        let gameState = GameState(
            dealer: dealer,
            loser: loser ?? Loser(player: "", losingMonths: 0),
            players: players,
            currentRound: currentRound,
            phase: phase,
            bonusCards: bonusCards,
            scores: scores,
            playerBets: playerBets,
            playerTricks: playerTricks,
            lastPlayer: lastPlayer ?? nil,
            perfectStreak: perfectStreak,
            isMaster: isMaster
        )
        
        do {
            let data = try JSONEncoder().encode(gameState)
            UserDefaults.standard.set(data, forKey: "savedGameState")
        } catch {
            print("Failed to save game state: \(error)")
        }
    }
}
