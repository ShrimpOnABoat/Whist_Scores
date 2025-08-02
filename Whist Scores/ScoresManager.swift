//
//  ScoresManager.swift
//  Whist Scores
//
//  Created by Tony Buffard on 2025-07-25.
//


//
//  ScoresManager.swift
//  Whist
//
//  Created by Tony Buffard on 2024-11-22.
//

import Foundation
import FirebaseFirestore

struct GameScore: Codable, Identifiable {
    var id = UUID() // Keep UUID for Identifiable conformance and potential local use
    let date: Date
    let ggScore: Int
    let ddScore: Int
    let totoScore: Int
    let ggPosition: Int?
    let ddPosition: Int?
    let totoPosition: Int?
    let ggConsecutiveWins: Int?
    let ddConsecutiveWins: Int?
    let totoConsecutiveWins: Int?

    init(date: Date, ggScore: Int, ddScore: Int, totoScore: Int,
         ggPosition: Int? = nil, ddPosition: Int? = nil, totoPosition: Int? = nil,
         ggConsecutiveWins: Int? = nil, ddConsecutiveWins: Int? = nil, totoConsecutiveWins: Int? = nil) {
        self.date = date
        self.ggScore = ggScore
        self.ddScore = ddScore
        self.totoScore = totoScore
        self.ggPosition = ggPosition
        self.ddPosition = ddPosition
        self.totoPosition = totoPosition
        self.ggConsecutiveWins = ggConsecutiveWins
        self.ddConsecutiveWins = ddConsecutiveWins
        self.totoConsecutiveWins = totoConsecutiveWins
    }

    enum CodingKeys: String, CodingKey {
        case date
        case ggScore = "gg_score"
        case ddScore = "dd_score"
        case totoScore = "toto_score"
        case ggPosition = "gg_position"
        case ddPosition = "dd_position"
        case totoPosition = "toto_position"
        case ggConsecutiveWins = "gg_consecutive_wins"
        case ddConsecutiveWins = "dd_consecutive_wins"
        case totoConsecutiveWins = "toto_consecutive_wins"
    }
}

struct Loser: Codable {
    let player: String
    let losingMonths: Int
}

enum ScoresManagerError: Error {
    case directoryCreationFailed
    case encodingFailed
    case decodingFailed
    case fileWriteFailed
    case fileReadFailed
    case firebaseError(Error)
    case backupOperationFailed(String)
}

class ScoresManager {
    static let shared = ScoresManager()
    private let firebaseService = FirebaseService.shared
    private let fileManager = FileManager.default
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    init() {}

    func saveScore(_ gameScore: GameScore) async throws {
        do {
            try await firebaseService.saveGameScore(gameScore)
            print("✅ Successfully saved GameScore with id: \(gameScore.id)")
        } catch {
            print("❌ Error saving GameScore: \(error.localizedDescription)")
            throw ScoresManagerError.firebaseError(error)
        }
    }

    func loadScores(for year: Int? = Calendar.current.component(.year, from: Date())) async throws -> [GameScore] {
        do {
            let scores = try await firebaseService.loadScores(for: year)
            print("✅ Successfully loaded \(scores.count) scores from Firebase\(year == nil ? "" : " for year \(year!)").")
            return scores
        } catch {
            print("❌ Error loading scores from Firebase: \(error.localizedDescription)")
            throw ScoresManagerError.firebaseError(error)
        }
    }

    func loadScoresSafely(for year: Int? = Calendar.current.component(.year, from: Date())) async -> [GameScore] {
        do {
            return try await loadScores(for: year)
        } catch {
            print("Error loading scores safely: \(error)")
            return []
        }
    }

    func findLoser() async -> Loser? {
        let scores = await loadScoresSafely(for: currentYear)
        guard !scores.isEmpty else {
            return nil
        }

        let currentMonth = Calendar.current.component(.month, from: Date())

        let calculatePlayerPoints: ([GameScore]) -> [String: Int] = { games in
            var points: [String: Int] = ["gg": 0, "dd": 0, "toto": 0]
            for game in games {
                let sortedScores = [
                    ("gg", game.ggScore),
                    ("dd", game.ddScore),
                    ("toto", game.totoScore)
                ].sorted { $0.1 > $1.1 }

                if sortedScores[0].1 > sortedScores[1].1 {
                    points[sortedScores[0].0, default: 0] += 2
                }
                if sortedScores[1].1 > sortedScores[2].1 {
                    points[sortedScores[1].0, default: 0] += 1
                }
            }
            return points
        }

        let getGamesForMonth: (Int) -> [GameScore] = { month in
            return scores.filter {
                let gameMonth = Calendar.current.component(.month, from: $0.date)
                return gameMonth == month
            }
        }

        let findLoserInMonth: ([String: Int]) -> String? = { points in
            let sortedPoints = points.sorted { $0.value < $1.value }
            if sortedPoints.count > 1 && sortedPoints[0].value != sortedPoints[1].value {
                return sortedPoints[0].key
            }
            return nil
        }

        var losingMonths = 0
        var loserName: String?
        var previousMonth = currentMonth - 1

        while previousMonth > 0 {
            let games = getGamesForMonth(previousMonth)
            if games.isEmpty {
                previousMonth -= 1
                continue
            }

            let points = calculatePlayerPoints(games)
            let loser = findLoserInMonth(points)

            if loserName == nil {
                loserName = loser
            }

            if loserName != nil && loserName == loser {
                losingMonths += 1
                previousMonth -= 1
            } else {
                break
            }
        }

        guard let loser = loserName, losingMonths > 0 else {
            return nil
        }

        return Loser(player: loser, losingMonths: losingMonths)
    }
    
    /// Scans all games from the **previous month** and returns who has the highest
    /// `_consecutive_wins` value. Multiple players can tie. If a player has no
    /// recorded value for that month, they are ignored. If no values exist,
    /// everyone is `false`.
    func setMaster() async -> [String: Bool] {
        var result: [String: Bool] = [
            "gg": false,
            "dd": false,
            "toto": false
        ]

        let calendar = Calendar.current
        let now = Date()
        guard let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: now) else {
            return result
        }
        let prevYear = calendar.component(.year, from: prevMonthDate)
        let prevMonth = calendar.component(.month, from: prevMonthDate)

        // Load scores for the previous month’s year, then filter by previous month
        let allScores = await loadScoresSafely(for: prevYear)
        let lastMonthScores = allScores.filter { calendar.component(.month, from: $0.date) == prevMonth }
        guard !lastMonthScores.isEmpty else {
            // No games last month
            return result
        }

        // Compute the maximum consecutive wins per player for that month
        var maxByPlayer: [String: Int] = ["gg": Int.min, "dd": Int.min, "toto": Int.min]
        for game in lastMonthScores {
            if let v = game.ggConsecutiveWins { maxByPlayer["gg"] = max(maxByPlayer["gg"] ?? Int.min, v) }
            if let v = game.ddConsecutiveWins { maxByPlayer["dd"] = max(maxByPlayer["dd"] ?? Int.min, v) }
            if let v = game.totoConsecutiveWins { maxByPlayer["toto"] = max(maxByPlayer["toto"] ?? Int.min, v) }
        }
        
        print("Max consecutive wins per player: \(maxByPlayer)")

        // Determine the global maximum among players that actually had a value
        let observedValues = maxByPlayer.values.filter { $0 != Int.min }
        guard let globalMax = observedValues.max() else {
            // No _consecutive_wins recorded for last month
            return result
        }

        // Mark all players who tie for the max as masters
        for (player, value) in maxByPlayer where value == globalMax {
            result[player] = true
        }

        return result
    }

}

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private let currentGameStateDocumentId = "current"
    private let scoresCollection = "scores"

    // MARK: - GameScore

    func saveGameScore(_ score: GameScore) async throws {
        let id = score.id.uuidString
        try db.collection(scoresCollection)
            .document(id)
            .setData(from: score)
    }

    func loadScores(for year: Int? = nil) async throws -> [GameScore] {
        var query: Query = db.collection(scoresCollection)
            .order(by: "date", descending: true)

        if let year = year,
           let calendar = Optional(Calendar.current),
           let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
           let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) {
             query = query.whereField("date", isGreaterThanOrEqualTo: startDate)
                          .whereField("date", isLessThan: endDate)
        }

        let snapshot = try await query.getDocuments()
        let scores = snapshot.documents.compactMap { document -> GameScore? in
            try? document.data(as: GameScore.self)
        }
        print("Successfully loaded \(scores.count) scores\(year == nil ? "" : " for year \(year!)").")
        return scores
    }
}
