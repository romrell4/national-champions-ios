//
//  Coach_Toolbox_Tests.swift
//  Coach Toolbox Tests
//
//  Created by Eric Romrell on 3/25/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import XCTest
@testable import Coach_Toolbox

private let alex = Player(
	playerId: "1",
	name: "Alex",
	singlesRating: 4.05,
	doublesRating: 4.01,
	previousSinglesRatings: [4.10, 3.78, 4.16],
	previousDoublesRatings: [3.78, 4.16, 4.01]
)
private let sam = Player(
	playerId: "2",
	name: "Sam",
	singlesRating: 3.76,
	doublesRating: 3.78,
	previousSinglesRatings: [3.73, 3.85, 3.75],
	previousDoublesRatings: [3.85, 3.75, 3.78]
)

class MatchTests: XCTestCase {
	
    func testSinglesMatchRatings() {
		let match = Match(
			matchId: "1",
			matchDate: Date(),
			winners: [alex],
			losers: [sam],
			winnerSet1Score: 6,
			loserSet1Score: 4,
			winnerSet2Score: 6,
			loserSet2Score: 4,
			winnerSet3Score: nil,
			loserSet3Score: nil
		)
		let (alexRating, samRating) = match.computeRatingChanges()
		XCTAssertEqual(4.01, alexRating[0])
		XCTAssertEqual(3.78, samRating[0])
    }
	
	func testDoubleMatchesRatings() {
		//TODO: Do this once you can do doubles matches
	}
}
