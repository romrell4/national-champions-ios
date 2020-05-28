//
//  Match.swift
//  National Champions
//
//  Created by Eric Romrell on 3/22/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import Foundation

private let DEFAULTS_KEY = "matches"
private let GAME_VALUE = 0.06

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
	
	var winnerCompRating: Double { trunc(winnerMatchRatings.sum()) }
	var loserCompRating: Double { trunc(loserMatchRatings.sum()) }
	
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
	
	static func loadFromUrl(url: String, completionHandler: @escaping (Result<Match>) -> Void) {
		URL(string: url).get(completionHandler: completionHandler) { data in
			//First try deserializing with the JSONDecoder. This will only succeed if the data was exported using the encoder
			if let matches = try? JSONDecoder().decode([Match].self, from: data) {
				matches.save()
				return matches
			}
			
			let dictArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? []
			
			try dictArray.forEach { dict in
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
					else { return }
				
				let scores = score.split(separator: ",").flatMap {
					$0.trimmingCharacters(in: .whitespaces).split(separator: "-").map {
						Int($0.trimmingCharacters(in: .whitespaces)) ?? 0
					}
				}
				
				Match(
					matchId: UUID().uuidString,
					matchDate: Date(),
					winners: [winner1, try getPlayerByKey("winner2")].compactMap { $0 },
					losers: [loser1, try getPlayerByKey("loser2")].compactMap { $0 },
					scores: scores
				).insert()
			}
			return Match.loadAll()
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
			if isSingles, let previousRating = player.previousSinglesRatings().last {
				player.singlesRating = previousRating
			} else if isDoubles, let previousRating = player.previousDoublesRatings().last {
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
	
	func delete(unwindCompletionHandler: () -> Void = {}) {
		//Delete all future matches in descending order
		let matches = Match.loadAll().filter { $0.matchDate > matchDate }.sorted { (lhs, rhs) -> Bool in
			lhs.matchDate > rhs.matchDate
		}
		matches.forEach { $0.undo() }
		
		//Delete this match
		self.undo()
		
		//Allow the caller to specify an action to be done after unwinding
		unwindCompletionHandler()
		
		//Re-insert all other future matches, in ascending order
		let players = Player.loadAll()
		matches.reversed().forEach { oldMatch in
			//Call the constructor so that everything gets set up as it should
			Match(
				matchId: oldMatch.matchId,
				matchDate: oldMatch.matchDate,
				winners: oldMatch.winners.map { Player.find($0, playerList: players) },
				losers: oldMatch.losers.map { Player.find($0, playerList: players) },
				scores: oldMatch.scores
			).insert()
		}
	}
		
	mutating func edit(winners: [Player]? = nil, losers: [Player]? = nil, scores: [Int?]) {
		self.delete {
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
		let getPlayerChangeDesc: (Player, Double) -> String = { (old, newRating) in
			if self.isSingles {
				return "- \(old.name): \(old.singlesRating) -> \(newRating)"
			} else if self.isDoubles {
				return "- \(old.name): \(old.doublesRating) -> \(newRating)"
			} else {
				return "Shouldn't ever hit this..."
			}
		}
		
		return """
		Changes:
		\(zip(self.winners + self.losers, winnerDynamicRatings + loserDynamicRatings).map { (old, new) in
			getPlayerChangeDesc(old, new)
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
		return trunc((previousRatings + [matchRating]).average())
	}
	
	private func computeMatchRating(for player: Player, truncated: Bool = false) -> Double {
		let isWinner = winners.contains(player)
		let (myTeam, opponents) = isWinner ? (winners, losers) : (losers, winners)
		let ratingDiff = Double(gameDiff) * (isWinner ? GAME_VALUE : -GAME_VALUE)
		let teamMatchRating = opponents.map { isSingles ? $0.singlesRating : $0.doublesRating }.sum() + ratingDiff
		let myRating = teamMatchRating - myTeam.filter { $0 != player }.map { isSingles ? $0.singlesRating : $0.doublesRating }.sum()
		return truncated ? trunc(myRating) : myRating
	}

	private var gameDiff: Int {
		let winnerTotalGames = [winnerSet1Score, winnerSet2Score, winnerSet3Score].compactMap { $0 }.reduce(0, { $0 + $1 })
		let loserTotalGames = [loserSet1Score, loserSet2Score, loserSet3Score].compactMap { $0 }.reduce(0, { $0 + $1 })
		return winnerTotalGames - loserTotalGames
	}
	
	private func trunc(_ value: Double) -> Double {
		//Round to the nearest thousands place, then truncate to the hundreds palce
		floor(round(value * 1000) / 10) / 100.0
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
