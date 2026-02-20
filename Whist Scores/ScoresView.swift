//
//  ScoresView.swift
//  Whist Scores
//
//  Created by Tony Buffard on 2025-07-30.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ScoresView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedTab: ScoreTab = .summary

    var body: some View {
        VStack {
            HStack {
                Button {
                    if selectedYear > firstYear {
                        selectedYear -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(selectedYear <= firstYear)

                Text(String(selectedYear))
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)

                Button {
                    if selectedYear < currentYear {
                        selectedYear += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(selectedYear >= currentYear)
            }
            .padding()

            Picker("Mode", selection: $selectedTab) {
                Text("Résumé").tag(ScoreTab.summary)
                Text("Détails").tag(ScoreTab.details)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            if selectedTab == .summary {
                SummaryView(year: selectedYear)
                    .id(selectedYear)
            } else {
                DetailedScoresView(year: selectedYear)
                    .id(selectedYear)
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 460, minHeight: 500)
        .background(Color(.systemBackground))
    }
}

enum ScoreTab {
    case summary, details
}

struct MonthlySummary: Identifiable {
    let id = UUID()
    let month: String
    let ggPoints: Int
    let ddPoints: Int
    let totoPoints: Int
    let ggTally: Int
    let ddTally: Int
    let totoTally: Int
}

struct SummaryView: View {
    let year: Int
    @State private var monthlySummaries: [MonthlySummary] = []

    var total: (gg: Int, dd: Int, toto: Int, ggTally: Int, ddTally: Int, totoTally: Int) {
        var total = (gg: 0, dd: 0, toto: 0, ggTally: 0, ddTally: 0, totoTally: 0)
        for summary in monthlySummaries {
            total.gg += summary.ggPoints
            total.dd += summary.ddPoints
            total.toto += summary.totoPoints
            total.ggTally += summary.ggTally
            total.ddTally += summary.ddTally
            total.totoTally += summary.totoTally
        }
        return total
    }

    private func podiumOrder() -> [String] {
        let candidates: [(id: String, tally: Int, points: Int)] = [
            ("GG", total.ggTally, total.gg),
            ("DD", total.ddTally, total.dd),
            ("Toto", total.totoTally, total.toto)
        ]

        return candidates
            .sorted {
                if $0.tally != $1.tally { return $0.tally > $1.tally }
                if $0.points != $1.points { return $0.points > $1.points }
                return $0.id < $1.id
            }
            .map { $0.id }
    }

    @ViewBuilder
    private func annualPodiumHeader() -> some View {
        if year < currentYear && !monthlySummaries.isEmpty {
            let order = podiumOrder()
            Image("palmares annuel")
                .resizable()
                .scaledToFit()
                .overlay(alignment: .topLeading) {
                    GeometryReader { geo in
                        let rect = aspectFitRect(container: geo.size, imageSize: palmaresSize)

                        let winnerX = rect.minX + rect.width  * 0.50
                        let winnerY = rect.minY + rect.height * 0.36
                        let leftX   = rect.minX + rect.width  * 0.28
                        let rightX  = rect.minX + rect.width  * 0.72
                        let othersY = rect.minY + rect.height * 0.63
                        let winnerSize = min(rect.width, rect.height) * 0.35
                        let otherSize  = min(rect.width, rect.height) * 0.28

                        avatarView(for: order[0], size: winnerSize)
                            .position(x: winnerX, y: winnerY)
                        avatarView(for: order[1], size: otherSize)
                            .position(x: leftX, y: othersY)
                        avatarView(for: order[2], size: otherSize)
                            .position(x: rightX, y: othersY)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
        }
    }

    private func avatarView(for player: String, size: CGFloat) -> some View {
        let assetName = player.lowercased()
        return Image(assetName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
            .background {
                Circle()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: size, height: size)
            }
        }
    

    var body: some View {
        ScrollView {
            annualPodiumHeader()

            VStack(alignment: .leading) {
                HStack {
                    Text("Mois").frame(width: 100, alignment: .leading).foregroundColor(.secondary)
                    Spacer()
                    Text("GG").frame(width: 40, alignment: .center).foregroundColor(.secondary)
                    Text("DD").frame(width: 40, alignment: .center).foregroundColor(.secondary)
                    Text("Toto").frame(width: 40, alignment: .center).foregroundColor(.secondary)
                    Rectangle()
                        .frame(width: 1, height: 20)
                        .foregroundColor(Color(.separator))
                    Text("GG").frame(width: 40, alignment: .center).foregroundColor(.secondary)
                    Text("DD").frame(width: 40, alignment: .center).foregroundColor(.secondary)
                    Text("Toto").frame(width: 40, alignment: .center).foregroundColor(.secondary)
                }
                .font(.subheadline)
                .padding(.vertical, 4)

                Divider()

                ForEach(monthlySummaries) { summary in
                    HStack {
                        Text(summary.month).frame(width: 100, alignment: .leading).foregroundColor(.primary)
                        Spacer()
                        Text("\(summary.ggPoints)").frame(width: 40, alignment: .center).foregroundColor(.primary)
                        Text("\(summary.ddPoints)").frame(width: 40, alignment: .center).foregroundColor(.primary)
                        Text("\(summary.totoPoints)").frame(width: 40, alignment: .center).foregroundColor(.primary)
                        Rectangle()
                            .frame(width: 1, height: 20)
                            .foregroundColor(Color(.separator))
                        Text("\(summary.ggTally)").frame(width: 40, alignment: .center)
                        Text("\(summary.ddTally)").frame(width: 40, alignment: .center)
                        Text("\(summary.totoTally)").frame(width: 40, alignment: .center)
                    }
                    .padding(.vertical, 2)
                }

                Divider()

                HStack {
                    Text("Total").frame(width: 100, alignment: .leading).foregroundColor(.primary)
                    Spacer()
                    Text("\(total.gg)").frame(width: 40, alignment: .center).foregroundColor(.primary)
                    Text("\(total.dd)").frame(width: 40, alignment: .center).foregroundColor(.primary)
                    Text("\(total.toto)").frame(width: 40, alignment: .center).foregroundColor(.primary)
                    Rectangle()
                        .frame(width: 1, height: 20)
                        .foregroundColor(Color(.separator))
                    Text("\(total.ggTally)").frame(width: 40, alignment: .center).foregroundColor(.primary)
                    Text("\(total.ddTally)").frame(width: 40, alignment: .center).foregroundColor(.primary)
                    Text("\(total.totoTally)").frame(width: 40, alignment: .center).foregroundColor(.primary)
                }
                .font(.headline)
                .padding(.vertical, 4)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator), lineWidth: 1))
        }
        .onAppear {
            Task { await loadData() }
        }
        .onChange(of: year) {
            monthlySummaries = []
            Task { await loadData() }
        }
    }

    private func loadData() async {
        let summaries = await computeMonthlySummaries(for: year)
        await MainActor.run {
            self.monthlySummaries = summaries
        }
    }
}

func computeMonthlySummaries(for year: Int) async -> [MonthlySummary] {
    let scores = await ScoresManager.shared.loadScoresSafely(for: year)

    let monthNames = [
        1: "Janvier", 2: "Février", 3: "Mars", 4: "Avril",
        5: "Mai", 6: "Juin", 7: "Juillet", 8: "Août",
        9: "Septembre", 10: "Octobre", 11: "Novembre", 12: "Décembre"
    ]

    var monthlyData: [Int: (gg: Int, dd: Int, toto: Int)] = [:]

    for score in scores {
        let calendar = Calendar.current
        guard calendar.component(.year, from: score.date) == year else { continue }
        let gameMonth = calendar.component(.month, from: score.date)

        if monthlyData[gameMonth] == nil {
            monthlyData[gameMonth] = (0, 0, 0)
        }

        let points = calculateGamePoints(for: score)
        monthlyData[gameMonth]!.gg += points.gg
        monthlyData[gameMonth]!.dd += points.dd
        monthlyData[gameMonth]!.toto += points.toto
    }

    var summaries: [MonthlySummary] = []
    for (month, points) in monthlyData {
        let tallies = calculateTallies(for: points)
        if let monthName = monthNames[month] {
            summaries.append(MonthlySummary(month: monthName,
                                            ggPoints: points.gg,
                                            ddPoints: points.dd,
                                            totoPoints: points.toto,
                                            ggTally: tallies.gg,
                                            ddTally: tallies.dd,
                                            totoTally: tallies.toto))
        }
    }

    let order = ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                 "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]
    summaries.sort { order.firstIndex(of: $0.month)! < order.firstIndex(of: $1.month)! }

    return summaries
}

func calculateGamePoints(for game: GameScore) -> (gg: Int, dd: Int, toto: Int) {
    if let ggPos = game.ggPosition, let ddPos = game.ddPosition, let totoPos = game.totoPosition {
        let positions = [("gg", ggPos), ("dd", ddPos), ("toto", totoPos)]
        let sorted = positions.sorted { $0.1 < $1.1 }
        var points = (gg: 0, dd: 0, toto: 0)

        switch sorted[0].0 {
        case "gg": points.gg = 2
        case "dd": points.dd = 2
        case "toto": points.toto = 2
        default: break
        }
        switch sorted[1].0 {
        case "gg": points.gg = 1
        case "dd": points.dd = 1
        case "toto": points.toto = 1
        default: break
        }
        return points
    } else {
        let scores: [(String, Int)] = [("gg", game.ggScore), ("dd", game.ddScore), ("toto", game.totoScore)]
        let sorted = scores.sorted { $0.1 > $1.1 }

        if sorted[0].1 == sorted[1].1 && sorted[1].1 == sorted[2].1 {
            return (gg: 2, dd: 2, toto: 2)
        } else if sorted[0].1 == sorted[1].1 {
            var points = (gg: 0, dd: 0, toto: 0)
            for entry in scores {
                if entry.1 == sorted[0].1 {
                    switch entry.0 {
                    case "gg": points.gg = 2
                    case "dd": points.dd = 2
                    case "toto": points.toto = 2
                    default: break
                    }
                }
            }
            return points
        } else if sorted[1].1 == sorted[2].1 {
            var points = (gg: 0, dd: 0, toto: 0)
            switch sorted[0].0 {
            case "gg": points.gg = 2
            case "dd": points.dd = 2
            case "toto": points.toto = 2
            default: break
            }
            for entry in sorted[1...2] {
                switch entry.0 {
                case "gg": points.gg = 1
                case "dd": points.dd = 1
                case "toto": points.toto = 1
                default: break
                }
            }
            return points
        } else {
            var points = (gg: 0, dd: 0, toto: 0)
            switch sorted[0].0 {
            case "gg": points.gg = 2
            case "dd": points.dd = 2
            case "toto": points.toto = 2
            default: break
            }
            switch sorted[1].0 {
            case "gg": points.gg = 1
            case "dd": points.dd = 1
            case "toto": points.toto = 1
            default: break
            }
            return points
        }
    }
}

func calculateTallies(for points: (gg: Int, dd: Int, toto: Int)) -> (gg: Int, dd: Int, toto: Int) {
    let values = [points.gg, points.dd, points.toto]
    let sorted = values.sorted(by: >)
    let tallyFor = { (score: Int) -> Int in
        if score == sorted[0] {
            return 2
        } else if score == sorted[1] {
            return 1
        } else {
            return 0
        }
    }
    return (gg: tallyFor(points.gg),
            dd: tallyFor(points.dd),
            toto: tallyFor(points.toto))
}

struct MonthGroup: Identifiable {
    let id = UUID()
    let monthName: String
    let tallies: (gg: Int, dd: Int, toto: Int)
    let scores: [GameScore]
}

struct DetailedScoresView: View {
    let year: Int
    @State private var monthGroups: [MonthGroup] = []
    @State private var longestStreakValue: Int = 0
    @State private var longestStreakPlayers: [String] = []

    private let dayColWidth: CGFloat = 70
    private let scoreColWidth: CGFloat = 62
    private let colSpacing: CGFloat = 10

    private var gridWidth: CGFloat {
        dayColWidth + (scoreColWidth * 3) + (colSpacing * 3)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 1)
                )

            VStack(spacing: 10) {
                if longestStreakValue > 0 {
                    HStack {
                        Spacer()
                        (Text("Plus longue série (") + Text("\(longestStreakValue)").bold() + Text("): ") + Text(longestStreakPlayers.joined(separator: ", ")).bold())
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.top, 6)
                    .padding(.horizontal, 12)
                }

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(monthGroups) { group in
                            VStack(spacing: 0) {
                                monthHeader(group)

                                let calendar = Calendar.current
                                let byDay = Dictionary(grouping: group.scores) {
                                    calendar.component(.day, from: $0.date)
                                }
                                let days = byDay.keys.sorted()

                                ForEach(days, id: \.self) { day in
                                    let dayScores = byDay[day]!.sorted { $0.date < $1.date }

                                    ForEach(Array(dayScores.enumerated()), id: \.element.id) { index, score in
                                        let pts = calculateGamePoints(for: score)

                                        HStack(alignment: .firstTextBaseline, spacing: colSpacing) {
                                            if index == 0 {
                                                Text("\(day)")
                                                    .font(.headline)
                                                    .frame(width: dayColWidth, alignment: .leading)
                                                    .foregroundColor(.secondary)
                                            } else {
                                                Text("")
                                                    .frame(width: dayColWidth, alignment: .leading)
                                            }

                                            ScoreValueCell(value: score.ggScore, rankPoints: pts.gg)
                                                .frame(width: scoreColWidth)
                                            ScoreValueCell(value: score.ddScore, rankPoints: pts.dd)
                                                .frame(width: scoreColWidth)
                                            ScoreValueCell(value: score.totoScore, rankPoints: pts.toto)
                                                .frame(width: scoreColWidth)
                                        }
                                        .frame(width: gridWidth, alignment: .leading)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 4)
                                    }

                                    Divider()
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding()
        .onAppear { Task { await loadData() } }
        .onChange(of: year) { Task { await loadData() } }
    }

    private func computeLongestStreaks(for year: Int, scores: [GameScore]) -> (value: Int, players: [String]) {
        let calendar = Calendar.current
        let yearScores = scores.filter { calendar.component(.year, from: $0.date) == year }

        var maxGG = 0
        var maxDD = 0
        var maxToto = 0

        for score in yearScores {
            if let gg = score.ggConsecutiveWins { maxGG = max(maxGG, gg) }
            if let dd = score.ddConsecutiveWins { maxDD = max(maxDD, dd) }
            if let tt = score.totoConsecutiveWins { maxToto = max(maxToto, tt) }
        }

        let best = max(maxGG, max(maxDD, maxToto))
        var players: [String] = []
        if best > 0 {
            if maxGG == best { players.append("GG") }
            if maxDD == best { players.append("DD") }
            if maxToto == best { players.append("Toto") }
        }
        return (best, players)
    }

    private func monthHeader(_ group: MonthGroup) -> some View {
        HStack(spacing: colSpacing) {
            Text(group.monthName)
                .font(.headline)
                .frame(width: dayColWidth, alignment: .leading)

            PlayerHeader(title: "GG", points: group.tallies.gg)
                .frame(width: scoreColWidth)
            PlayerHeader(title: "DD", points: group.tallies.dd)
                .frame(width: scoreColWidth)
            PlayerHeader(title: "Toto", points: group.tallies.toto)
                .frame(width: scoreColWidth)
        }
        .frame(width: gridWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
    }

    private func loadData() async {
        let allScores = await ScoresManager.shared.loadScoresSafely(for: year)
        let calendar = Calendar.current
        let yearScores = allScores.filter { calendar.component(.year, from: $0.date) == year }

        let longest = computeLongestStreaks(for: year, scores: allScores)
        await MainActor.run {
            self.longestStreakValue = longest.value
            self.longestStreakPlayers = longest.players
        }

        var byMonth: [Int: [GameScore]] = [:]
        for score in yearScores {
            let month = calendar.component(.month, from: score.date)
            byMonth[month, default: []].append(score)
        }

        let monthNames = ["Janvier","Février","Mars","Avril","Mai","Juin",
                          "Juillet","Août","Septembre","Octobre","Novembre","Décembre"]
        let groups: [MonthGroup] = byMonth.keys.sorted().compactMap { month in
            let scores = byMonth[month]!.sorted { $0.date < $1.date }
            var monthlyPoints = (gg: 0, dd: 0, toto: 0)
            for score in scores {
                let p = calculateGamePoints(for: score)
                monthlyPoints.gg += p.gg
                monthlyPoints.dd += p.dd
                monthlyPoints.toto += p.toto
            }
            return MonthGroup(
                monthName: monthNames[month - 1],
                tallies: monthlyPoints,
                scores: scores
            )
        }

        await MainActor.run {
            self.monthGroups = groups
        }
    }

    private struct PlayerHeader: View {
        let title: String
        let points: Int

        var body: some View {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(points)")
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private struct ScoreValueCell: View {
        let value: Int
        let rankPoints: Int

        @Environment(\.colorScheme) private var colorScheme

        private var background: Color {
            let isDark = (colorScheme == .dark)
            switch rankPoints {
            case 2:
                return Color.accentColor.opacity(isDark ? 0.35 : 0.20)
            case 1:
                return Color.accentColor.opacity(isDark ? 0.22 : 0.10)
            default:
                return Color.clear
            }
        }

        var body: some View {
            HStack(spacing: 6) {
                Text("\(value)")
                    .font(.body.monospacedDigit())
                    .fontWeight(rankPoints == 2 ? .bold : .regular)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(rankPoints == 2 ? 1 : 0), lineWidth: 1)
            )
        }
    }
}

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()

let dayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "d"
    return f
}()

private func aspectFitRect(container: CGSize, imageSize: CGSize) -> CGRect {
    guard container.width > 0, container.height > 0, imageSize.width > 0, imageSize.height > 0 else {
        return .zero
    }

    let scale = min(container.width / imageSize.width, container.height / imageSize.height)
    let fitted = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    let origin = CGPoint(
        x: (container.width - fitted.width) / 2,
        y: (container.height - fitted.height) / 2
    )
    return CGRect(origin: origin, size: fitted)
}

private let palmaresSize: CGSize = {
    #if canImport(UIKit)
    return UIImage(named: "palmares annuel")?.size ?? .init(width: 1, height: 1)
    #else
    return .init(width: 1, height: 1)
    #endif
}()

private let firstYear = 2017
private var currentYear: Int {
    Calendar.current.component(.year, from: Date())
}
