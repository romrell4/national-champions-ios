//
//  Match.swift
//  National Champions
//
//  Created by Eric Romrell on 3/22/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import Foundation

private let DEFAULTS_KEY = "matches"
private let WINNER_GAME_VALUE = 0.06
private let LOSER_GAME_VALUE = 0.05

struct Match: Codable {
    let matchId: String
    let matchDate: Date
    var winners: [Player]
    var losers: [Player]
    var scores: [Int?] {
        get {
            [winnerSet1Score, loserSet1Score, winnerSet2Score, loserSet2Score, winnerSet3Score, loserSet3Score]
        }
        set {
            winnerSet1Score = newValue[safe: 0] ?? nil
            loserSet1Score = newValue[safe: 1] ?? nil
            winnerSet2Score = newValue[safe: 2] ?? nil
            loserSet2Score = newValue[safe: 3] ?? nil
            winnerSet3Score = newValue[safe: 4] ?? nil
            loserSet3Score = newValue[safe: 5] ?? nil
            
            computeAllDynamicRatings()
        }
    }
    private (set) var winnerSet1Score: Int?
    private (set) var loserSet1Score: Int?
    private (set) var winnerSet2Score: Int?
    private (set) var loserSet2Score: Int?
    private (set) var winnerSet3Score: Int?
    private (set) var loserSet3Score: Int?
    
    var winnerCompRating: Double { winnerMatchRatings.sum().trunc() }
    var loserCompRating: Double { loserMatchRatings.sum().trunc() }
    
    var winnerMatchRatings: [Double] { winners.map { computeMatchRating(for: $0, truncated: true) } }
    var loserMatchRatings: [Double] { losers.map { computeMatchRating(for: $0, truncated: true) } }
    
    var winnerDynamicRatings: [Double]
    var loserDynamicRatings: [Double]
    
    init(matchId: String, matchDate: Date, winners: [Player], losers: [Player], scores: [Int?]) {
        self.matchId = matchId
        self.matchDate = matchDate
        self.winners = winners
        self.losers = losers

        //Initialize to nothing, then compute them
        self.winnerDynamicRatings = []
        self.loserDynamicRatings = []

        self.scores = scores
    }
    
    private var set1: MatchSet { MatchSet(winnerScore: winnerSet1Score, loserScore: loserSet1Score) }
    private var set2: MatchSet { MatchSet(winnerScore: winnerSet2Score, loserScore: loserSet2Score) }
    private var set3: MatchSet { MatchSet(winnerScore: winnerSet3Score, loserScore: loserSet3Score) }
    
    var scoreText: String {
        [set1.scoreText, set2.scoreText, set3.scoreText].compactMap { $0 }.joined(separator: ", ")
    }
    
    var allPlayers: [Player] { winners + losers }
    
    var winner1: Player? { winners[safe: 0] }
    var winner2: Player? { winners[safe: 1] }
    var loser1: Player? { losers[safe: 0] }
    var loser2: Player? { losers[safe: 1] }
    
    func findPlayer(player: Player) -> Player? {
        if let index = allPlayers.firstIndex(of: player) {
            return allPlayers[index]
        }
        return nil
    }
    
    func findCompanion(for player: Player) -> Player? {
        switch player {
        case winner1:
            return winner2
        case winner2:
            return winner1
        case loser1:
            return loser2
        case loser2:
            return loser1
        default:
            return nil
        }
    }
    
    func findRatings(for player: Player) -> (Double, Double, Double)? {
        if let index = winners.firstIndex(of: player) {
            return (winnerMatchRatings[index], winnerCompRating, winnerDynamicRatings[index])
        } else if let index = losers.firstIndex(of: player) {
            return (loserMatchRatings[index], loserCompRating, loserDynamicRatings[index])
        } else {
            return nil
        }
    }
    
    static func loadAll() -> [Match] {
        guard
            let data = UserDefaults.standard.data(forKey: DEFAULTS_KEY),
            let array = try? JSONDecoder().decode([Match].self, from: data)
            else { return [] }
        
        return array.sorted { lhs, rhs in
            lhs.matchDate > rhs.matchDate
        }
    }
    
    var wasCompleted: Bool {
        if set1.wasCompleted, set2.wasCompleted {
            if set1.winnerWon == true && set2.winnerWon == true && !set3.wasPlayed {
                return true
            } else if set1.winnerWon != set2.winnerWon, set3.wasSet3Completed {
                return true
            }
        }
        return false
    }
    
    var isSingles: Bool {
        winners.count == 1 && losers.count == 1
    }
    
    var isDoubles: Bool {
        winners.count == 2 && losers.count == 2
    }
    
    func applyRatingChanges() {
        let allDynamicRatings = winnerDynamicRatings + loserDynamicRatings
        for i in 0 ..< allPlayers.count {
            var player = allPlayers[i]
            let newRating = allDynamicRatings[i]
            if isSingles {
                player.singlesRating = newRating
            } else {
                player.doublesRating = newRating
            }
            player.update()
        }
    }
    
    func undoRatingChanges() {
        for i in 0 ..< allPlayers.count {
            var player = allPlayers[i]
            if isSingles, let previousRating = player.previousSinglesRatings().first {
                player.singlesRating = previousRating
            } else if isDoubles, let previousRating = player.previousDoublesRatings().first {
                player.doublesRating = previousRating
            }
            player.update()
        }
    }
    
    func insert() {
        //Apply rating changes BEFORE saving that match, so that it doesn't show up in the player's previous matches during the calculation
        applyRatingChanges()
        
        (Match.loadAll() + [self]).save()
    }
    
    func delete(progressCallback: ((Double) -> Void)? = nil, unwindCompletionHandler: () -> Void = {}) {
        //Delete all future matches in descending order
        let matches = Match.loadAll().filter { $0.matchDate > matchDate }.sorted { (lhs, rhs) -> Bool in
            lhs.matchDate > rhs.matchDate
        }
        
        //The total number of operation that need to be completed
        // (double the matches in front of us, plus 2 for our own undo and the unwindCompletionHandler)
        let totalProgress = Double(matches.count) * 2.0 + 2.0
        var currentProgress = 0.0
        
        let step = {
            currentProgress += 1
            progressCallback?(currentProgress / totalProgress)
        }
        
        matches.enumerated().forEach { (index, match) in
            match.undo()
            step()
        }
        
        //Delete this match
        self.undo()
        step()
        
        //Allow the caller to specify an action to be done after unwinding
        unwindCompletionHandler()
        step()
        
        //Re-insert all other future matches, in ascending order
        matches.reversed().enumerated().forEach { (index, oldMatch) in
            //Reload the players each time, so that their new scores are reflected
            let players = Player.loadAll()
            
            //Call the constructor so that everything gets set up as it should
            Match(
                matchId: oldMatch.matchId,
                matchDate: oldMatch.matchDate,
                winners: oldMatch.winners.map { Player.find($0, playerList: players) },
                losers: oldMatch.losers.map { Player.find($0, playerList: players) },
                scores: oldMatch.scores
            ).insert()
            step()
        }
    }
        
    mutating func edit(winners: [Player]? = nil, losers: [Player]? = nil, scores: [Int?], progressCallback: ((Double) -> Void)? = nil) {
        self.delete(progressCallback: progressCallback) {
            //Apply score changes
            let players = Player.loadAll()
            if let winners = winners {
                self.winners = winners.map { Player.find($0, playerList: players) }
            }
            if let losers = losers {
                self.losers = losers.map { Player.find($0, playerList: players) }
            }
            self.scores = scores
            
            //Re-insert this match with the updated values
            self.insert()
        }
    }
    
    private func undo() {
        var allMatches = Match.loadAll()
        allMatches.removeAll { $0.matchId == matchId }
        allMatches.save()
        
        //Undo the rating change AFTER deleting the match, so that this match won't display in each player's previous matches
        undoRatingChanges()
    }

    
    func getChangeDescription() -> String {
        let getPlayerChangeDesc: (Player, Double) -> String = { (player, newRating) in
            if self.isSingles {
                return "- \(player.name): \(player.singlesRating) -> \(newRating)"
            } else if self.isDoubles {
                return "- \(player.name): \(player.doublesRating) -> \(newRating)"
            } else {
                return "Shouldn't ever hit this..."
            }
        }
        
        return """
        Dynamic Rating Changes:
        \(zip(self.winners + self.losers, winnerDynamicRatings + loserDynamicRatings).map { (player, newRating) in
            getPlayerChangeDesc(player, newRating)
        }.joined(separator: "\n"))
        
        Match Ratings:
        \(zip(self.winners + self.losers, winnerMatchRatings + loserMatchRatings).map { (player, matchRating) in
            "- \(player.name): \(matchRating)"
        }.joined(separator: "\n"))
        """
    }
    
    //MARK: Private
    
    private mutating func computeAllDynamicRatings() {
        self.winnerDynamicRatings = winners.map { self.computeDynamicRating(for: $0) }
        self.loserDynamicRatings = losers.map { self.computeDynamicRating(for: $0) }
    }
    
    private func computeDynamicRating(for player: Player) -> Double {
        guard let player = findPlayer(player: player) else { fatalError("This player did not play in this match") }
        
        let matchRating = computeMatchRating(for: player)
        let previousRatings = isSingles ? player.previousSinglesRatings() : player.previousDoublesRatings()
        return (previousRatings + [matchRating]).average().trunc()
    }
    
    private func computeMatchRating(for player: Player, truncated: Bool = false) -> Double {
        let isWinner = winners.contains(player)
        let (myTeam, opponents) = isWinner ? (winners, losers) : (losers, winners)
        let ratingDiff = Double(gameDiff) * (isWinner ? WINNER_GAME_VALUE : -LOSER_GAME_VALUE)
        let teamMatchRating = opponents.map { isSingles ? $0.singlesRating : $0.doublesRating }.sum() + ratingDiff
        let myRating = teamMatchRating - myTeam.filter { $0 != player }.map { isSingles ? $0.singlesRating : $0.doublesRating }.sum()
        return truncated ? myRating.trunc() : myRating
    }

    private var gameDiff: Int {
        let winnerTotalGames = [winnerSet1Score, winnerSet2Score, winnerSet3Score].compactMap { $0 }.reduce(0, { $0 + $1 })
        let loserTotalGames = [loserSet1Score, loserSet2Score, loserSet3Score].compactMap { $0 }.reduce(0, { $0 + $1 })
        return winnerTotalGames - loserTotalGames
    }
}

extension Double {
    func trunc(places: Double = 2) -> Double {
        //Round to the nearest thousands place, then truncate to the hundreds place
        return floor((self * pow(10.0, places + 1)).rounded(.toNearestOrAwayFromZero) / 10) / pow(10.0, places)
    }
}
    
struct MatchSet {
    let winnerScore: Int?
    let loserScore: Int?
    
    var scoreText: String? {
        if let winnerScore = winnerScore, let loserScore = loserScore {
            return "\(winnerScore)-\(loserScore)"
        }
        return nil
    }
    
    var wasPlayed: Bool {
        return winnerScore != nil && loserScore != nil
    }
    
    var wasCompleted: Bool {
        let scores = [winnerScore, loserScore].compactMap { $0 }.sorted()
        if scores.count == 2 {
            return (scores[1] == 6 && scores[0] < 5) || (scores[1] == 7 && [5, 6].contains(scores[0]))
        }
        return false
    }
    
    var wasSet3Completed: Bool {
        if let winnerScore = winnerScore, let loserScore = loserScore {
            return (winnerScore == 7 && [5, 6].contains(loserScore)) || (winnerScore == 6 && loserScore < 5) || (winnerScore == 1 && loserScore == 0)
        }
        return false
    }
    
    var winnerWon: Bool? {
        if let winnerScore = winnerScore, let loserScore = loserScore {
            return winnerScore > loserScore
        }
        return nil
    }
}

extension Match {
    init?(dict: [String: Any]) throws {
        let getPlayerByKey: (String) throws -> Player? = {
            guard let name = dict[$0] as? String, !name.isEmpty else { return nil }
            
            guard let player = Player.loadAll().first(where: { $0.name == name }) else {
                throw MyError.unableToImport("Attempting to import \(name), but no player found with that name")
            }
            return player
        }
        
        guard let winner1 = try getPlayerByKey("winner1"),
            let loser1 = try getPlayerByKey("loser1"),
            let score = dict["score"] as? String
            else { return nil }
        
        let scores = score.split(separator: ",").flatMap {
            $0.trimmingCharacters(in: .whitespaces).split(separator: "-").map {
                Int($0.trimmingCharacters(in: .whitespaces)) ?? 0
            }
        }
        
        self.init(
            matchId: UUID().uuidString,
            matchDate: Date(),
            winners: [winner1, try getPlayerByKey("winner2")].compactMap { $0 },
            losers: [loser1, try getPlayerByKey("loser2")].compactMap { $0 },
            scores: scores
        )
    }
}

enum MyError: Error {
    case unableToImport(_ message: String)
}

extension Array where Element == Match {
    func save() {
        try? UserDefaults.standard.set(JSONEncoder().encode(self), forKey: DEFAULTS_KEY)
    }
    
    func toCSV() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy h:mm"
        return "Match Date,Winner 1,Winner 2,Loser 1,Loser 2,Score\n" +
            self.sorted { (lhs, rhs) in lhs.matchDate < rhs.matchDate }.map {
                "\(formatter.string(from: $0.matchDate)),\($0.winner1?.name ?? ""),\($0.winner2?.name ?? ""),\($0.loser1?.name ?? ""),\($0.loser2?.name ?? ""),\"\($0.scoreText)\""
            }.joined(separator: "\n")
    }
}

extension Array where Element == Double {
    func sum() -> Double {
        reduce(0, { $0 + $1 })
    }
    
    func average() -> Double {
        sum() / Double(count)
    }
}
