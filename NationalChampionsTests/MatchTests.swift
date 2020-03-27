//
//  MatchTests.swift
//  National Champions Tests
//
//  Created by Eric Romrell on 3/25/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import XCTest
@testable import National_Champs

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
		let (winners, losers) = match.computeRatingChanges()
		XCTAssertEqual(4.01, winners[0].singlesRating)
		XCTAssertEqual([3.78, 4.16, 4.01], winners[0].previousSinglesRatings)
		XCTAssertEqual(3.78, losers[0].singlesRating)
		XCTAssertEqual([3.85, 3.75, 3.78], losers[0].previousSinglesRatings)
		XCTAssertEqual("""
			Changes:
			- Alex: 4.05 -> 4.01
			- Sam: 3.76 -> 3.78
			""", match.getChangeDescription())
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
		let (winners, losers) = match.computeRatingChanges()
		XCTAssertEqual(3.98, winners[0].doublesRating)
		XCTAssertEqual([4.16, 4.01, 3.98], winners[0].previousDoublesRatings)
		XCTAssertEqual(3.78, winners[1].doublesRating)
		XCTAssertEqual([3.75, 3.78, 3.78], winners[1].previousDoublesRatings)
		XCTAssertEqual(3.75, losers[0].doublesRating)
		XCTAssertEqual([3.79, 3.68, 3.75], losers[0].previousDoublesRatings)
		XCTAssertEqual(3.74, losers[1].doublesRating)
		XCTAssertEqual([3.72, 3.79, 3.74], losers[1].previousDoublesRatings)
		XCTAssertEqual("""
			Changes:
			- Alex: 4.01 -> 3.98
			- Sam: 3.78 -> 3.78
			- Brad: 3.78 -> 3.75
			- Adam: 3.73 -> 3.74
			""", match.getChangeDescription())
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
		let (winners, losers) = match.computeRatingChanges()
		XCTAssertEqual(0.06, winners[0].singlesRating)
		XCTAssertEqual([0.06], winners[0].previousSinglesRatings)
		XCTAssertEqual(-0.06, losers[0].singlesRating)
		XCTAssertEqual([-0.06], losers[0].previousSinglesRatings)
		XCTAssertEqual("""
			Changes:
			- Brad: 0.0 -> 0.06
			- Adam: 0.0 -> -0.06
			""", match.getChangeDescription())
	}
}
