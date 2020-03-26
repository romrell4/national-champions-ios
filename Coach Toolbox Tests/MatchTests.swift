//
//  MatchTests.swift
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
private let brad = Player(
	playerId: "3",
	name: "Brad",
	singlesRating: 0.0,
	doublesRating: 3.78,
	previousSinglesRatings: [],
	previousDoublesRatings: [3.71, 3.79, 3.68]
)
private let adam = Player(
	playerId: "4",
	name: "Adam",
	singlesRating: 0.0,
	doublesRating: 3.73,
	previousSinglesRatings: [],
	previousDoublesRatings: [3.69, 3.72, 3.79]
)


class MatchTests: XCTestCase {
	
    func testNormalSinglesMatchRatings() {
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
		let (winnerRatings, loserRatings) = match.computeRatingChanges()
		XCTAssertEqual(4.01, winnerRatings[0])
		XCTAssertEqual(3.78, loserRatings[0])
    }
	
	func testNormalDoubleMatchesRatings() {
		let match = Match(
			matchId: "1",
			matchDate: Date(),
			winners: [alex, sam],
			losers: [brad, adam],
			winnerSet1Score: 6,
			loserSet1Score: 4,
			winnerSet2Score: 6,
			loserSet2Score: 4,
			winnerSet3Score: nil,
			loserSet3Score: nil
		)
		let (winnerRatings, loserRatings) = match.computeRatingChanges()
		XCTAssertEqual(3.98, winnerRatings[0])
		XCTAssertEqual(3.78, winnerRatings[1])
		XCTAssertEqual(3.75, loserRatings[0])
		XCTAssertEqual(3.74, loserRatings[1])
	}
	
	func testSinglesWithNoHistory() {
		let match = Match(
			matchId: "1",
			matchDate: Date(),
			winners: [brad],
			losers: [adam],
			winnerSet1Score: 6,
			loserSet1Score: 4,
			winnerSet2Score: 4,
			loserSet2Score: 6,
			winnerSet3Score: 1,
			loserSet3Score: 0
		)
		let (winnerRatings, loserRatings) = match.computeRatingChanges()
		XCTAssertEqual(0.06, winnerRatings[0])
		XCTAssertEqual(-0.06, loserRatings[0])
	}
}
