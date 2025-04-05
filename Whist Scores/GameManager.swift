//
//  GameManager.swift
//  Whist Scores
//
//  Created by Tony Buffard on 2025-04-03.
//

// TODO: add a reset button
// TODO: Show the bonus cards for each player
// TODO: Show who's the dealer, or the starting player for the round

import Foundation
import CloudKit

enum GamePhase {
    case betInput
    case scoreInput
    case gameOver
}

class GameManager: ObservableObject {
    @Published var players: [String] = ["gg", "dd", "toto"]
    @Published var startingPlayer: String = ["gg", "dd", "toto"].randomElement() ?? "gg"
    @Published var currentRound: Int = 0 // The first round is 0, the last one is 11
    @Published var phase: GamePhase = .betInput
    
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
    
    func startGame(with players: [String], starting: String) {
        self.players = players
        self.startingPlayer = starting
        self.currentRound = 0
        self.scores = Dictionary(uniqueKeysWithValues: players.map { ($0, []) })
        self.phase = .betInput
    }
    
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
    
    func advanceToNextRound() {
        currentRound += 1
        
        if currentRound >= 12 {
            phase = .gameOver
        } else {
            phase = .betInput
        }
    }
    
    func resetGame() {
        players = []
        startingPlayer = players.randomElement() ?? "gg"
        currentRound = 0
        scores = [:]
        playerBets = [:]
        playerTricks = [:]
        phase = .betInput
    }
    
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
    
    func loadPreviewData(phase: GamePhase = .betInput) {
        players = ["gg", "dd", "toto"]
        startingPlayer = "gg"
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
    }
}
