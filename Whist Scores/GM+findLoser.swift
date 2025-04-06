//
//  GM+findLoser.swift
//  Whist Scores
//
//  Created by Tony Buffard on 2025-04-04.
//

import Foundation
import CloudKit

struct GameScore: Codable, Identifiable {
    let id = UUID() // Unique ID for each game
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
    
    // 🔹 Custom initializer to provide default values
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

extension GameScore {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Encode properties in the desired order:
        try container.encode(date, forKey: .date)
        try container.encode(ggScore, forKey: .ggScore)
        try container.encode(ddScore, forKey: .ddScore)
        try container.encode(totoScore, forKey: .totoScore)
        try container.encode(ggPosition, forKey: .ggPosition)
        try container.encode(ddPosition, forKey: .ddPosition)
        try container.encode(totoPosition, forKey: .totoPosition)
        try container.encode(ggConsecutiveWins, forKey: .ggConsecutiveWins)
        try container.encode(ddConsecutiveWins, forKey: .ddConsecutiveWins)
        try container.encode(totoConsecutiveWins, forKey: .totoConsecutiveWins)
    }
}

extension GameScore {
    /// Converts a GameScore instance into a CKRecord.
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "GameScore")
        record["date"] = date as CKRecordValue
        record["gg_score"] = ggScore as CKRecordValue
        record["dd_score"] = ddScore as CKRecordValue
        record["toto_score"] = totoScore as CKRecordValue
        if let ggPosition = ggPosition {
            record["gg_position"] = ggPosition as CKRecordValue
        }
        if let ddPosition = ddPosition {
            record["dd_position"] = ddPosition as CKRecordValue
        }
        if let totoPosition = totoPosition {
            record["toto_position"] = totoPosition as CKRecordValue
        }
        if let ggConsecutiveWins = ggConsecutiveWins {
            record["gg_consecutive_wins"] = ggConsecutiveWins as CKRecordValue
        }
        if let ddConsecutiveWins = ddConsecutiveWins {
            record["dd_consecutive_wins"] = ddConsecutiveWins as CKRecordValue
        }
        if let totoConsecutiveWins = totoConsecutiveWins {
            record["toto_consecutive_wins"] = totoConsecutiveWins as CKRecordValue
        }
        return record
    }
    
    /// Initializes a GameScore instance from a CKRecord.
    init?(record: CKRecord) {
        guard let date = record["date"] as? Date,
              let ggScore = record["gg_score"] as? Int,
              let ddScore = record["dd_score"] as? Int,
              let totoScore = record["toto_score"] as? Int else {
            return nil
        }
        
        self.date = date
        self.ggScore = ggScore
        self.ddScore = ddScore
        self.totoScore = totoScore
        self.ggPosition = record["gg_position"] as? Int
        self.ddPosition = record["dd_position"] as? Int
        self.totoPosition = record["toto_position"] as? Int
        self.ggConsecutiveWins = record["gg_consecutive_wins"] as? Int
        self.ddConsecutiveWins = record["dd_consecutive_wins"] as? Int
        self.totoConsecutiveWins = record["toto_consecutive_wins"] as? Int
    }
}

enum ScoresManagerError: Error {
    case directoryCreationFailed
    case encodingFailed
    case decodingFailed
    case fileWriteFailed
    case fileReadFailed
    case cloudKitError(Error)
}

extension GameManager {
    
    // MARK: Find Loser
    func findPreviousMonthLoser(currentYear: Int, completion: @escaping (Loser?) -> Void) {
        loadScoresSafely(for: currentYear) { scores in
            guard !scores.isEmpty else {
                completion(nil)
                return
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
                
                if loserName == loser {
                    losingMonths += 1
                    previousMonth -= 1
                } else {
                    break
                }
            }
            
            guard let loser = loserName else {
                completion(nil)
                return
            }
            
            completion(Loser(player: loser, losingMonths: losingMonths))
        }
    }
    // Add a non-throwing convenience method
    func loadScoresSafely(for year: Int = Calendar.current.component(.year, from: Date()),
                          completion: @escaping ([GameScore]) -> Void) {
        loadScores(for: year) { result in
            switch result {
            case .success(let scores):
                completion(scores)
            case .failure(let error):
                print("Error loading scores: \(error)")
                completion([])
            }
        }
    }

    /// Loads GameScore objects for a specified year from CloudKit.
    func loadScores(for year: Int = Calendar.current.component(.year, from: Date()),
                    completion: @escaping (Result<[GameScore], Error>) -> Void) {
        let container = CKContainer(identifier: "iCloud.com.Tony.WhistTest")
        let database = container.publicCloudDatabase
        
        // Calculate the start and end dates for the given year.
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31, hour: 23, minute: 59, second: 59)) else {
            completion(.failure(ScoresManagerError.decodingFailed))
            return
        }
        
        let predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as CVarArg, endDate as CVarArg)
        let query = CKQuery(recordType: "GameScore", predicate: predicate)
        
        var fetchedScores: [GameScore] = []
        let operation = CKQueryOperation(query: query)
        
        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .failure(let error):
                print("❌ Error matching record \(recordID): \(error.localizedDescription)")
            case .success(let record):
                if let score = GameScore(record: record) {
                    fetchedScores.append(score)
                }
            }
        }
        
        operation.queryResultBlock = { result in
            switch result {
            case .failure(let error):
                print("❌ Error loading scores: \(error.localizedDescription)")
                completion(.failure(ScoresManagerError.cloudKitError(error)))
            case .success:
                completion(.success(fetchedScores))
            }
        }
        
        database.add(operation)
    }
}
