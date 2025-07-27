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

struct Loser {
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

    func saveScores(_ scores: [GameScore]) async throws {
        guard !scores.isEmpty else {
            print("No scores provided to save.")
            return
        }
        do {
            try await firebaseService.saveGameScores(scores)
            print("✅ Successfully saved \(scores.count) scores to Firebase.")
        } catch {
            print("❌ Error saving batch of scores: \(error.localizedDescription)")
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

    func deleteAllScores() async throws {
        do {
            try await firebaseService.deleteAllGameScores()
            print("✅ Successfully deleted all scores from Firebase.")
        } catch {
            print("❌ Error deleting all scores from Firebase: \(error.localizedDescription)")
            throw ScoresManagerError.firebaseError(error)
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

    func restoreBackup(from backupDirectory: URL) async throws {
        do {
            let backupFiles = try fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }

            if backupFiles.isEmpty {
                print("⚠️ No backup JSON files found in directory: \(backupDirectory.path). Aborting restore.")
                throw ScoresManagerError.backupOperationFailed("No JSON files found in backup directory.")
            }

            print("🔍 Found \(backupFiles.count) JSON backup files. Starting restore process...")

            var allScores: [GameScore] = []

            for fileURL in backupFiles {
                print("  Processing backup file: \(fileURL.lastPathComponent)")
                do {
                    let data = try Data(contentsOf: fileURL)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .custom { decoder in
                        let container = try decoder.singleValueContainer()
                        let dateString = try container.decode(String.self)

                        let isoFormatter = ISO8601DateFormatter()
                        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        if let date = isoFormatter.date(from: dateString) { return date }

                        isoFormatter.formatOptions = [.withInternetDateTime]
                        if let date = isoFormatter.date(from: dateString) { return date }

                        let fallbackFormatter = DateFormatter()
                        fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
                        fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                        if let date = fallbackFormatter.date(from: dateString) { return date }

                        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date string \(dateString) does not match expected formats")
                    }
                    let scores = try decoder.decode([GameScore].self, from: data)
                    print("    ✅ Decoded \(scores.count) scores from \(fileURL.lastPathComponent).")
                    allScores.append(contentsOf: scores)
                } catch {
                    print("    🚨 Error processing file \(fileURL.lastPathComponent): \(error.localizedDescription)")
                    throw ScoresManagerError.decodingFailed
                }
            }

            print("📊 Total scores decoded from backup files: \(allScores.count)")
            guard !allScores.isEmpty else {
                print("⚠️ No scores decoded from backup files. Restore aborted.")
                throw ScoresManagerError.backupOperationFailed("No scores found in backup files.")
            }

            print("🔥 Deleting existing scores from Firebase...")
            try await deleteAllScores()

            print("☁️ Uploading \(allScores.count) backup scores to Firebase...")
            try await saveScores(allScores)

            print("✅ Restore completed successfully!")

        } catch let error as ScoresManagerError {
            print("🚨 Restore failed: \(error)")
            throw error
        } catch {
            print("🚨 An unexpected error occurred during restore: \(error)")
            throw ScoresManagerError.backupOperationFailed(error.localizedDescription)
        }
    }

    func exportScoresToLocalDirectory(_ directory: URL) async throws {
        do {
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }

            print("☁️ Loading all scores from Firebase for export...")
            let scores = try await loadScores(for: nil)

            if scores.isEmpty {
                print("⚠️ No scores found in Firebase to export.")
                return
            }

            print("📊 Loaded \(scores.count) scores for export. Grouping by year...")

            let groupedByYear = Dictionary(grouping: scores) { score in
                Calendar.current.component(.year, from: score.date)
            }.mapValues { yearlyScores in
                yearlyScores.sorted { $0.date < $1.date }
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            encoder.dateEncodingStrategy = .formatted(formatter)

            print("💾 Writing scores to JSON files in \(directory.path)...")
            for (year, yearlyScores) in groupedByYear {
                let fileURL = directory.appendingPathComponent("scores_\(year).json")
                do {
                    let data = try encoder.encode(yearlyScores)
                    try data.write(to: fileURL, options: .atomic)
                    print("  ✅ Exported \(yearlyScores.count) scores for year \(year) to \(fileURL.lastPathComponent)")
                } catch {
                    print("  🚨 Error exporting scores for year \(year): \(error.localizedDescription)")
                    throw ScoresManagerError.fileWriteFailed
                }
            }

            print("✅ Export completed successfully!")

        } catch let error as ScoresManagerError {
            print("🚨 Export failed: \(error)")
            throw error
        } catch {
            print("🚨 An unexpected error occurred during export: \(error)")
            throw ScoresManagerError.backupOperationFailed("Export failed: \(error.localizedDescription)")
        }
    }
}

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private let currentGameStateDocumentId = "current"
//    private let gameStatesCollection = "gameStates"
//    private let currentGameActionDocumentId = "current"
//    private let gameActionsCollection = "gameActions"
    private let scoresCollection = "scores"

    // MARK: - GameScore

    func saveGameScore(_ score: GameScore) async throws {
        let id = score.id.uuidString
        try db.collection(scoresCollection)
            .document(id)
            .setData(from: score)
    }

    func saveGameScores(_ scores: [GameScore]) async throws {
        let batch = db.batch()
        let scoresRef = db.collection(scoresCollection)
        for score in scores {
            let docRef = scoresRef.document(score.id.uuidString)
            try batch.setData(from: score, forDocument: docRef)
        }
        try await batch.commit()
        print("Successfully saved \(scores.count) scores in a batch.")
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

    func deleteGameScore(id: String) async throws {
        try await db.collection(scoresCollection).document(id).delete()
        print("Successfully deleted score with ID: \(id)")
    }

    func deleteAllGameScores() async throws {
        let collectionRef = db.collection(scoresCollection)
        var count = 0
        var lastSnapshot: DocumentSnapshot? = nil

        repeat {
            let batch = db.batch()
            var query = collectionRef.limit(to: 400)
            if let lastSnapshot = lastSnapshot {
                query = query.start(afterDocument: lastSnapshot)
            }

            let snapshot = try await query.getDocuments()
            guard !snapshot.documents.isEmpty else { break }

            snapshot.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()

            count += snapshot.documents.count
            lastSnapshot = snapshot.documents.last

        } while lastSnapshot != nil

        print("Successfully deleted \(count) scores from collection \(scoresCollection).")
    }
}
