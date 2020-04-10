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
	let winnerSet1Score: Int?
	let loserSet1Score: Int?
	let winnerSet2Score: Int?
	let loserSet2Score: Int?
	let winnerSet3Score: Int?
	let loserSet3Score: Int?
	
	var winnerMatchRatings: [Double]
	var loserMatchRatings: [Double]
	
	var winnerDynamicRatings: [Double]
	var loserDynamicRatings: [Double]
	
	init(matchId: String, matchDate: Date, winners: [Player], losers: [Player], winnerSet1Score: Int?, loserSet1Score: Int?, winnerSet2Score: Int?, loserSet2Score: Int?, winnerSet3Score: Int?, loserSet3Score: Int?) {
		self.matchId = matchId
		self.matchDate = matchDate
		self.winners = winners
		self.losers = losers
		self.winnerSet1Score = winnerSet1Score
		self.loserSet1Score = loserSet1Score
		self.winnerSet2Score = winnerSet2Score
		self.loserSet2Score = loserSet2Score
		self.winnerSet3Score = winnerSet3Score
		self.loserSet3Score = loserSet3Score
		
		//Initialize to nothing, then compute them
		self.winnerMatchRatings = []
		self.loserMatchRatings = []
		self.winnerDynamicRatings = []
		self.loserDynamicRatings = []
		
		self.winnerMatchRatings = winners.map { self.computeMatchRating(player: $0, truncated: true) }
		self.loserMatchRatings = losers.map { self.computeMatchRating(player: $0, truncated: true) }
		self.winnerDynamicRatings = winners.map { self.computeDynamicRating(player: $0) }
		self.loserDynamicRatings = losers.map { self.computeDynamicRating(player: $0) }
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
		URL(string: url).get(completionHandler: completionHandler) { dictArray in
			try dictArray.forEach { dict in
				let players = Player.loadAll()
				
				let getPlayerByKey: (String) throws -> Player? = {
					guard let name = dict[$0] as? String, !name.isEmpty else { return nil }
					
					guard let player = players.first(where: { $0.name == name }) else {
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
					winnerSet1Score: scores[safe: 0],
					loserSet1Score: scores[safe: 1],
					winnerSet2Score: scores[safe: 2],
					loserSet2Score: scores[safe: 3],
					winnerSet3Score: scores[safe: 4],
					loserSet3Score: scores[safe: 5]
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
		let allPlayers = winners + losers
		let allDynamicRatings = winnerDynamicRatings + loserDynamicRatings
		zip(allPlayers, allDynamicRatings).enumerated().forEach {
			var player = allPlayers[$0.offset]
			let newRating = allDynamicRatings[$0.offset]
			if isSingles {
				player.singlesRating = newRating
			} else {
				player.doublesRating = newRating
			}
			player.update()
		}
	}
	
	var gameDiff: Int {
		let winnerTotalGames = [winnerSet1Score, winnerSet2Score, winnerSet3Score].compactMap { $0 }.reduce(0, { $0 + $1 })
		let loserTotalGames = [loserSet1Score, loserSet2Score, loserSet3Score].compactMap { $0 }.reduce(0, { $0 + $1 })
		return winnerTotalGames - loserTotalGames
	}
	
	func computeMatchRating(player: Player, truncated: Bool = false) -> Double {
		let isWinner = winners.contains(player)
		let (myTeam, opponents) = isWinner ? (winners, losers) : (losers, winners)
		let ratingDiff = Double(gameDiff) * (isWinner ? GAME_VALUE : -GAME_VALUE)
		let teamMatchRating = opponents.map { isSingles ? $0.singlesRating : $0.doublesRating }.sum() + ratingDiff
		let myRating = teamMatchRating - myTeam.filter { $0 != player }.map { isSingles ? $0.singlesRating : $0.doublesRating }.sum()
		return truncated ? trunc(myRating) : myRating
	}

	func computeDynamicRating(player: Player) -> Double {
		guard let player = findPlayer(player: player) else { fatalError("This player did not play in this match") }
		
		let matchRating = computeMatchRating(player: player)
		let previousRatings = isSingles ? player.previousSinglesRatings : player.previousDoublesRatings
		return trunc((previousRatings + [matchRating]).average())
	}
	
	private func trunc(_ value: Double) -> Double {
		//Round to the nearest thousands place, then truncate to the hundreds palce
		floor(round(value * 1000) / 10) / 100.0
	}
	
	func insert() {
		applyRatingChanges()
		(Match.loadAll() + [self]).save()
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
}

extension Array where Element == Double {
	func sum() -> Double {
		reduce(0, { $0 + $1 })
	}
	
	func average() -> Double {
		sum() / Double(count)
	}
}
