//
//  Player.swift
//  National Champions
//
//  Created by Eric Romrell on 3/19/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import Foundation

private let DEFAULTS_KEY = "players"

struct Player: Codable, Equatable {
	let playerId: String
	var name: String
	var singlesRating: Double
	var doublesRating: Double
	var onCurrentTeam: Bool
	let initialSinglesRating: Double
	let initialDoublesRating: Double
	func previousSinglesRatings() -> [Double] {
		Array(Match.loadAll().filter { $0.isSingles }.compactMap {
			if let winnerIndex = $0.winners.firstIndex(of: self) {
				return $0.winnerDynamicRatings[winnerIndex]
			} else if let loserIndex = $0.losers.firstIndex(of: self) {
				return $0.loserDynamicRatings[loserIndex]
			} else {
				return nil
			}
		}.prefix(3))
	}
	func previousDoublesRatings() -> [Double] {
		Array(Match.loadAll().filter { $0.isDoubles }.compactMap {
			if let winnerIndex = $0.winners.firstIndex(of: self) {
				return $0.winnerDynamicRatings[winnerIndex]
			} else if let loserIndex = $0.losers.firstIndex(of: self) {
				return $0.loserDynamicRatings[loserIndex]
			} else {
				return nil
			}
		}.prefix(3))
	}
	var record: (Int, Int) {
		let matches = Match.loadAll()
		let wins = matches.filter {
			$0.winners.contains(self)
		}.count
		let losses = matches.filter {
			$0.losers.contains(self)
		}.count
		return (wins, losses)
	}
	
	init(playerId: String, name: String, singlesRating: Double, doublesRating: Double, onCurrentTeam: Bool) {
		self.playerId = playerId
		self.name = name
		self.singlesRating = singlesRating
		self.doublesRating = doublesRating
		self.initialSinglesRating = singlesRating
		self.initialDoublesRating = doublesRating
		self.onCurrentTeam = onCurrentTeam
	}
	
	func update() {
		var players = Player.loadAll()
		if let index = players.firstIndex(where: { $0.playerId == playerId }) {
			players[index] = self
			players.save()
		}
	}
	
	static func loadAll() -> [Player] {
		guard
			let data = UserDefaults.standard.data(forKey: DEFAULTS_KEY),
			let array = try? JSONDecoder().decode([Player].self, from: data)
			else { return [] }
		
		return array
	}
	
	static func find(_ player: Player, playerList: [Player] = Player.loadAll()) -> Player {
		return playerList.first { $0 == player }!
	}
	
	static func == (lhs: Player, rhs: Player) -> Bool {
		return lhs.playerId == rhs.playerId
	}
}

extension Player {
	init?(dict: [String: Any]) {
		if let name = dict["name"] as? String,
			let singlesRating = dict["singles_rating"] as? Double,
			let doublesRating = dict["doubles_rating"] as? Double,
			let onCurrentTeam = dict["current_team"] as? String {
			
			self.init(
				playerId: UUID().uuidString,
				name: name,
				singlesRating: singlesRating,
				doublesRating: doublesRating,
				onCurrentTeam: onCurrentTeam.lowercased() == "y"
			)
		} else {
			return nil
		}
	}
}

extension Array where Element == Player {
	func save() {
		try? UserDefaults.standard.set(JSONEncoder().encode(self), forKey: DEFAULTS_KEY)
	}
}
