//
//  GameManager.swift
//  Whist Scores
//
//  Created by Tony Buffard on 2025-04-03.
//

// TODO: add a reset button
// TODO: add a RoundHistoryView
// TODO: save the score locally if there's no network
// TODO: ask for the loser and the months if there's no network

import Foundation
import CloudKit

enum GamePhase {
    case betInput
    case scoreInput
    case gameOver
}

struct Loser {
    let player: String
    let losingMonths: Int
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
    
    var loser: Loser?
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    var cardsForCurrentRound: Int {
        currentRound < 3 ? 1 : currentRound - 1
    }
    
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
        findPreviousMonthLoser(currentYear: currentYear) { loser in
            DispatchQueue.main.async {
                self.loser = loser
                print("Found previous month's loser: \(String(describing: loser?.player)) for \(String(describing: loser?.losingMonths)) consecutive months.")
            }
        }
    }
    
    //MARK: Game Logic
    func newGame() {
        advanceDealer()
        self.currentRound = -1
        self.scores = Dictionary(uniqueKeysWithValues: players.map { ($0, []) })
        self.playerBets = Dictionary(uniqueKeysWithValues: players.map { ($0, []) })
        self.playerTricks = Dictionary(uniqueKeysWithValues: players.map { ($0, []) })
        self.phase = .betInput
        
        advanceToNextRound()
    }
    
    func advanceToNextRound() {
        currentRound += 1
        advanceDealer()
        assignBonusCards()
        
        if currentRound >= 12 {
            phase = .gameOver
        } else {
            phase = .betInput
        }
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
            let previouscore: Int = scores[player]?.last ?? 0
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
                scores[player] = [score + previouscore]
            } else {
                scores[player]?.append(score + previouscore)
            }
        }
        
        if currentRound == 11 {
            let totalBets: [String: Int] = players.reduce(into: [:]) { result, player in
                result[player] = playerBets[player]?.reduce(0, +) ?? 0
            }
            
            let sorted = totalBets.sorted { $0.value > $1.value }
            if sorted.count >= 2, sorted[0].value > sorted[1].value {
                let winner = sorted[0].key
                scores[winner]?.append(15)
            }
        }
    }
    
    func resetGame() {
        players = []
        dealer = players.randomElement() ?? "gg"
        currentRound = 0
        scores = [:]
        playerBets = [:]
        playerTricks = [:]
        phase = .betInput
    }
    
    //MARK: Inputs
    func submitBets(bets: [String: Int]) {
        var processedBets = bets
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
    }
    
    func submitTricks(tricks: [String: Int]) {
        for player in players {
            if playerTricks[player] == nil {
                playerTricks[player] = []
            }
            playerTricks[player]?.append(tricks[player] ?? 0)
        }
        
        updateScores()
        advanceToNextRound()
    }
    
    //MARK: Upload score
    func uploadFinalScores(completion: @escaping (Bool) -> Void) {
        let record = CKRecord(recordType: "WhistGame")
        record["date"] = Date()
        for player in players {
            record["score_\(player)"] = scores[player]?.reduce(0, +)
        }
        
        CKContainer.default().publicCloudDatabase.save(record) { _, error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
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
    
    private func determinePosition(for player: String) -> Int {
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
            "gg": [1, 0, 1, 2],
            "dd": [0, 0, 0, 1],
            "toto": [1, 0, 1, 1]
        ]
        playerTricks = [
            "gg": [1, 0, 1, 1],
            "dd": [0, 1, 0, 2],
            "toto": [1, 1, 1, 1]
        ]
        bonusCards = [
            "gg": 0,
            "dd": 1,
            "toto": 2
        ]
    }
}
