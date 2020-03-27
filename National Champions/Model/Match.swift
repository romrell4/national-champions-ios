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
	
	private var set1: MatchSet { MatchSet(winnerScore: winnerSet1Score, loserScore: loserSet1Score) }
	private var set2: MatchSet { MatchSet(winnerScore: winnerSet2Score, loserScore: loserSet2Score) }
	private var set3: MatchSet { MatchSet(winnerScore: winnerSet3Score, loserScore: loserSet3Score) }
	
	var scoreText: String {
		[set1.scoreText, set2.scoreText, set3.scoreText].compactMap { $0 }.joined(separator: ", ")
	}
	
	var allPlayers: [Player] { winners + losers }
	
	static func loadAll() -> [Match] {
		guard
			let data = UserDefaults.standard.data(forKey: DEFAULTS_KEY),
			let array = try? JSONDecoder().decode([Match].self, from: data)
			else { return [] }
		
		return array
	}
	
	static func loadFromUrl(url: String, completionHandler: @escaping ([Match]?) -> Void) {
		URL(string: url).get(completionHandler: completionHandler) { dictArray in
			let newMatches = dictArray.compactMap { dict -> Match? in
				let players = Player.loadAll()
				
				let getPlayerByKey: (String) -> Player? = {
					guard let name = dict[$0] as? String else { return nil }
					
					guard let player = players.first(where: { $0.name == name }) else {
						fatalError("Attempting to import \(name), but no player found with that name")
					}
					return player
				}
				
				guard let winner1 = getPlayerByKey("winner1"),
					let loser1 = getPlayerByKey("loser1"),
					let score = dict["score"] as? String
					else { return nil }
				
				let scores = score.split(separator: ",").flatMap {
					$0.trimmingCharacters(in: .whitespaces).split(separator: "-").map {
						Int($0.trimmingCharacters(in: .whitespaces)) ?? 0
					}
				}
				
				return Match(
					matchId: UUID().uuidString,
					matchDate: Date(),
					winners: [winner1, getPlayerByKey("winner2")].compactMap { $0 },
					losers: [loser1, getPlayerByKey("loser2")].compactMap { $0 },
					winnerSet1Score: scores[safe: 0],
					loserSet1Score: scores[safe: 1],
					winnerSet2Score: scores[safe: 2],
					loserSet2Score: scores[safe: 3],
					winnerSet3Score: scores[safe: 4],
					loserSet3Score: scores[safe: 5]
				)
			}
			let allMatches = Match.loadAll() + newMatches
			return allMatches
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
	
	mutating func applyRatingChanges() {
		(winners, losers) = computeRatingChanges()
		allPlayers.forEach { (player) in
			player.update()
		}
	}
	
	func computeRatingChanges() -> ([Player], [Player]) {
		let winnerTotalGames = [winnerSet1Score, winnerSet2Score, winnerSet3Score].compactMap { $0 }.reduce(0, { $0 + $1 })
		let loserTotalGames = [loserSet1Score, loserSet2Score, loserSet3Score].compactMap { $0 }.reduce(0, { $0 + $1 })
		return (
			computePlayerRatingChanges(for: winners, against: losers, gameDiff: winnerTotalGames - loserTotalGames),
			computePlayerRatingChanges(for: losers, against: winners, gameDiff: loserTotalGames - winnerTotalGames)
		)
	}
	
	private func computePlayerRatingChanges(for players: [Player], against opponents: [Player], gameDiff: Int) -> [Player] {
		let ratingDiff = Double(gameDiff) * GAME_VALUE
		if isSingles {
			var player = players[0]
			let matchRating = opponents[0].singlesRating + ratingDiff
			player.singlesRating = trunc((players[0].previousSinglesRatings.suffix(3) + [matchRating]).average())
			return [player]
		} else if isDoubles {
			var (player1, player2) = (players[0], players[1])
			let matchRating = opponents.map { $0.doublesRating }.sum() + ratingDiff
			let player1MatchRating = matchRating - player2.doublesRating
			let player2MatchRating = matchRating - player1.doublesRating
			player1.doublesRating = trunc((player1.previousDoublesRatings.suffix(3) + [player1MatchRating]).average())
			player2.doublesRating = trunc((player2.previousDoublesRatings.suffix(3) + [player2MatchRating]).average())
			return [player1, player2]
		} else {
			fatalError("You can only be playing singles or doubles")
		}
	}
	
	private func trunc(_ value: Double) -> Double {
		//Round to the nearest thousands place, then truncate to the hundreds palce
		Double(Int(round(value * 1000) / 1000 * 100)) / 100.0
	}
	
	mutating func insert() {
		applyRatingChanges()
		(Match.loadAll() + [self]).save()
	}
	
	func getChangeDescription() -> String {
		let getPlayerChangeDesc: (Player, Player) -> String = { (old, new) in
			if self.isSingles {
				return "- \(old.name): \(old.singlesRating) -> \(new.singlesRating)"
			} else if self.isDoubles {
				return "- \(old.name): \(old.doublesRating) -> \(new.doublesRating)"
			} else {
				return "Shouldn't ever hit this..."
			}
		}
		
		let (newWinners, newLosers) = computeRatingChanges()
		return """
		Changes:
		\(zip(self.winners + self.losers, newWinners + newLosers).map { (old, new) in
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
