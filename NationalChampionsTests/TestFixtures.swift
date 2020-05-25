//
//  TestFixtures.swift
//  NationalChampionsTests
//
//  Created by Eric Romrell on 5/10/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import Foundation
@testable import National_Champs

func p(_ rating: Double) -> Player {
	Player(playerId: UUID().uuidString, name: "\(rating)", singlesRating: rating, doublesRating: rating, onCurrentTeam: false)
}

func m(players: ([Player], [Player]), score: [Int]) -> Match {
	Match(matchId: UUID().uuidString, matchDate: Date(), winners: players.0, losers: players.1, scores: score)
}
