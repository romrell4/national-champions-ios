//
//  Player.swift
//  Coach Toolbox
//
//  Created by Eric Romrell on 3/19/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import Foundation

struct Player: Codable {
	let playerId: String = UUID().uuidString
	let name: String
	let singlesRating: Double
	let doublesRating: Double
	
	static func loadAll() -> [Player] {
		guard
			let data = UserDefaults.standard.data(forKey: "players"),
			let array = try? JSONDecoder().decode([Player].self, from: data)
			else { return [] }
		
		return array
	}
}

extension Array where Element == Player {
	func save() {
		try? UserDefaults.standard.set(JSONEncoder().encode(self), forKey: "players")
	}
}
