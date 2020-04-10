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
	let initialSinglesRating: Double
	let initialDoublesRating: Double
	var previousSinglesRatings: [Double] {
		Array((Match.loadAll().filter { $0.isSingles }.compactMap {
			if let winnerIndex = $0.winners.firstIndex(of: self) {
				return $0.winnerDynamicRatings[winnerIndex]
			} else if let loserIndex = $0.losers.firstIndex(of: self) {
				return $0.loserDynamicRatings[loserIndex]
			} else {
				return nil
			}
		} + Array(repeating: initialSinglesRating, count: 3)).prefix(3))
	}
	var previousDoublesRatings: [Double] {
		Array((Match.loadAll().filter { $0.isDoubles }.compactMap {
			if let winnerIndex = $0.winners.firstIndex(of: self) {
				return $0.winnerDynamicRatings[winnerIndex]
			} else if let loserIndex = $0.losers.firstIndex(of: self) {
				return $0.loserDynamicRatings[loserIndex]
			} else {
				return nil
			}
		} + Array(repeating: initialDoublesRating, count: 3)).prefix(3))
	}
	
	init(playerId: String, name: String, singlesRating: Double, doublesRating: Double) {
		self.playerId = playerId
		self.name = name
		self.singlesRating = singlesRating
		self.doublesRating = doublesRating
		self.initialSinglesRating = singlesRating
		self.initialDoublesRating = doublesRating
	}
	
	func update() {
		var players = Player.loadAll()
		if let index = players.firstIndex(where: { $0.playerId == playerId }) {
			players[index] = self
			players.save()
		}
	}
	
	func displayName(isSingles: Bool) -> String {
		"\(name) (\(isSingles ? singlesRating : doublesRating))"
	}
	
	static func loadAll() -> [Player] {
		guard
			let data = UserDefaults.standard.data(forKey: DEFAULTS_KEY),
			let array = try? JSONDecoder().decode([Player].self, from: data)
			else { return [] }
		
		return array
	}
	
	static func loadFromUrl(url urlString: String, completionHandler: @escaping (Result<Player>) -> Void) {
		URL(string: urlString).get(completionHandler: completionHandler) { dictArray in
			let newPlayers = dictArray.compactMap { dict -> Player? in
				if let name = dict["name"] as? String,
					let singlesRating = dict["singles_rating"] as? Double,
					let doublesRating = dict["doubles_rating"] as? Double {
					
					return Player(
						playerId: UUID().uuidString,
						name: name,
						singlesRating: singlesRating,
						doublesRating: doublesRating
					)
				} else {
					return nil
				}
			}
			
			//Combine old players with new players by name
			var allPlayers = Player.loadAll()
			for newPlayer in newPlayers {
				if let oldPlayerIndex = allPlayers.firstIndex(where: { $0.name == newPlayer.name }) {
					allPlayers[oldPlayerIndex] = newPlayer
				} else {
					allPlayers.append(newPlayer)
				}
			}
			allPlayers.save()
			return allPlayers
		}
	}
	
	static func == (lhs: Player, rhs: Player) -> Bool {
		return lhs.playerId == rhs.playerId
	}
}

extension Array where Element == Player {
	func save() {
		try? UserDefaults.standard.set(JSONEncoder().encode(self), forKey: DEFAULTS_KEY)
	}
}
