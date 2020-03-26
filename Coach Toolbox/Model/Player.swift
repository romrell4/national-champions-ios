//
//  Player.swift
//  Coach Toolbox
//
//  Created by Eric Romrell on 3/19/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import Foundation

private let DEFAULTS_KEY = "players"

struct Player: Codable {
	let playerId: String
	var name: String
	var singlesRating: Double {
		didSet {
			previousSinglesRatings.safeRemoveFirst()
			previousSinglesRatings.append(singlesRating)
		}
	}
	var doublesRating: Double {
		didSet {
			previousDoublesRatings.safeRemoveFirst()
			previousDoublesRatings.append(doublesRating)
		}
	}
	var previousSinglesRatings: [Double]
	var previousDoublesRatings: [Double]
	
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
	
	static func loadFromUrl(url urlString: String, completionHandler: @escaping ([Player]?) -> Void) {
		if let url = URL(string: urlString) {
			URLSession.shared.dataTask(with: url) { data, _, _ in
				DispatchQueue.main.async {
					let decoder = JSONDecoder()
					decoder.keyDecodingStrategy = .convertFromSnakeCase
					do {
						if let data = data, let array = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
							let players = array.compactMap { (dict) -> Player? in
								if let name = dict["name"] as? String,
									let singlesRating = dict["singles_rating"] as? Double,
									let doublesRating = dict["doubles_rating"] as? Double {
									
									return Player(
										playerId: UUID().uuidString,
										name: name,
										singlesRating: singlesRating,
										doublesRating: doublesRating,
										previousSinglesRatings: dict["previous_singles_ratings"] as? [Double] ?? [],
										previousDoublesRatings: dict["previous_doubles_ratings"] as? [Double] ?? []
									)
								} else {
									return nil
								}
							}
							let allPlayers = Player.loadAll() + players
							allPlayers.save()
							completionHandler(allPlayers)
						} else {
							completionHandler(nil)
						}
					} catch {
						print("\(error)")
						completionHandler(nil)
					}

				}
			}.resume()
		} else {
			completionHandler(nil)
		}
	}
}

extension Array where Element == Player {
	func save() {
		try? UserDefaults.standard.set(JSONEncoder().encode(self), forKey: DEFAULTS_KEY)
	}
}

private extension Array {
	mutating func safeRemoveFirst() {
		if !isEmpty {
			removeFirst()
		}
	}
}
