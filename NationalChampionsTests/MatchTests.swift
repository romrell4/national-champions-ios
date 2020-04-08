//
//  MatchTests.swift
//  National Champions Tests
//
//  Created by Eric Romrell on 3/25/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import XCTest
@testable import National_Champs

class MatchTests: XCTestCase {
	
	private func p(_ rating: Double) -> Player {
		Player(playerId: UUID().uuidString, name: "\(rating)", singlesRating: rating, doublesRating: rating)
	}
	
	private func m(players: ([Player], [Player]), score: [Int]) -> Match {
		Match(matchId: UUID().uuidString, matchDate: Date(), winners: players.0, losers: players.1, winnerSet1Score: score[safe: 0], loserSet1Score: score[safe: 1], winnerSet2Score: score[safe: 2], loserSet2Score: score[safe: 3], winnerSet3Score: score[safe: 4], loserSet3Score: score[safe: 5])
	}
	
	private func setUpMatchHistory(_ playerRatings: [(Player, [Double], [Double])]) {
		let createFakeMatch: (Player, Double, Bool) -> Match = { (player, dynamicRating, singles) in
			//Create a fake match, then override the rating
			let players = singles ? ([player], [self.p(0.0)]) : ([player, self.p(0.0)], [self.p(0.0), self.p(0.0)])
			var match = self.m(players: players, score: [])
			match.winnerDynamicRatings[0] = dynamicRating
			return match
		}
		
		playerRatings.flatMap { (player, singlesRatings, doublesRatings) in
			singlesRatings.map {
				createFakeMatch(player, $0, true)
			} + doublesRatings.map {
				createFakeMatch(player, $0, false)
			}
		}.save()
	}
	
	override func tearDown() {
		[Match]().save()
	}
	
	func testSinglesNoHistory() {
		let match = m(players: ([p(4.65)], [p(4.20)]), score: [6, 4, 6, 4])
		XCTAssertEqual(4.44, match.winnerMatchRatings[0])
		XCTAssertEqual(4.44, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.41, match.loserMatchRatings[0])
		XCTAssertEqual(4.41, match.loserDynamicRatings[0])
	}
	
	func testDoublesNoHistory() {
		let match = m(players: ([p(4.00), p(4.01)], [p(4.02), p(4.03)]), score: [6, 1])
		XCTAssertEqual(4.34, match.winnerMatchRatings[0])
		XCTAssertEqual(4.34, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.35, match.winnerMatchRatings[1])
		XCTAssertEqual(4.35, match.winnerDynamicRatings[1])
		XCTAssertEqual(3.68, match.loserMatchRatings[0])
		XCTAssertEqual(3.68, match.loserDynamicRatings[0])
		XCTAssertEqual(3.69, match.loserMatchRatings[1])
		XCTAssertEqual(3.69, match.loserDynamicRatings[1])
	}
	
	func testSinglesWithHistory() {
		let p4_05 = p(4.05)
		let p3_76 = p(3.76)
		setUpMatchHistory(
			[
				(p4_05, [4.10, 3.78, 4.16], []),
				(p3_76, [3.73, 3.85, 3.75], [])
			]
		)
		let match = m(players: ([p4_05], [p3_76]), score: [6, 4, 6, 4])

		XCTAssertEqual(4.00, match.winnerMatchRatings[0])
		XCTAssertEqual(4.01, match.winnerDynamicRatings[0])
		XCTAssertEqual(3.81, match.loserMatchRatings[0])
		XCTAssertEqual(3.78, match.loserDynamicRatings[0])
		XCTAssertEqual("""
			Changes:
			- 4.05: 4.05 -> 4.01
			- 3.76: 3.76 -> 3.78
			""", match.getChangeDescription())
	}

	func testNormalDoubleMatchesRatings() {
		let p4_01 = p(4.01)
		let p3_78 = p(3.78)
		let p3_78_2 = p(3.78)
		let p3_73 = p(3.73)
		setUpMatchHistory(
			[
				(p4_01, [], [3.78, 4.16, 4.01]),
				(p3_78, [], [3.85, 3.75, 3.78]),
				(p3_78_2, [], [3.71, 3.79, 3.68]),
				(p3_73, [], [3.69, 3.72, 3.79])
			]
		)
		let match = m(players: ([p4_01, p3_78], [p3_78_2, p3_73]), score: [6, 4, 6, 4])
		XCTAssertEqual(3.97, match.winnerMatchRatings[0])
		XCTAssertEqual(3.98, match.winnerDynamicRatings[0])
		XCTAssertEqual(3.74, match.winnerMatchRatings[1])
		XCTAssertEqual(3.78, match.winnerDynamicRatings[1])
		XCTAssertEqual(3.82, match.loserMatchRatings[0])
		XCTAssertEqual(3.75, match.loserDynamicRatings[0])
		XCTAssertEqual(3.77, match.loserMatchRatings[1])
		XCTAssertEqual(3.74, match.loserDynamicRatings[1])
		XCTAssertEqual("""
			Changes:
			- 4.01: 4.01 -> 3.98
			- 3.78: 3.78 -> 3.78
			- 3.78: 3.78 -> 3.75
			- 3.73: 3.73 -> 3.74
			""", match.getChangeDescription())
	}

	func testSomeoneWithLargerHistory() {
		let p0_0 = p(0.0)
		setUpMatchHistory(
			[
				(p0_0, [500.0, 0.06, 0.06, 0.06], [])
			]
		)
		let match = m(players: ([p0_0], [p(0.0)]), score: [1, 0])
		XCTAssertEqual(0.06, match.winnerDynamicRatings[0])
	}
	
	func testMultipleSinglesMatches() {
		let p4_65 = p(4.65)
		let p4_20 = p(4.20)
		[p4_65, p4_20].save()
		
		let findPlayer: (Player) -> Player = { player in
			return Player.loadAll().first { $0 == player }!
		}
		
		var match = m(players: ([findPlayer(p4_65)], [findPlayer(p4_20)]), score: [6, 4, 6, 4])
		XCTAssertEqual(4.44, match.winnerMatchRatings[0])
		XCTAssertEqual(4.44, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.41, match.loserMatchRatings[0])
		XCTAssertEqual(4.41, match.loserDynamicRatings[0])
		XCTAssertEqual([], p4_65.previousSinglesRatings)
		XCTAssertEqual([], p4_20.previousSinglesRatings)
		match.insert()
		XCTAssertEqual([4.44], p4_65.previousSinglesRatings)
		XCTAssertEqual([4.41], p4_20.previousSinglesRatings)
		
		match = m(players: ([findPlayer(p4_65)], [findPlayer(p4_20)]), score: [5, 7, 6, 4, 1, 0])
		XCTAssertEqual(4.47, match.winnerMatchRatings[0])
		XCTAssertEqual(4.45, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.38, match.loserMatchRatings[0])
		XCTAssertEqual(4.39, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual([4.45, 4.44], p4_65.previousSinglesRatings)
		XCTAssertEqual([4.39, 4.41], p4_20.previousSinglesRatings)
		
		match = m(players: ([findPlayer(p4_20)], [findPlayer(p4_65)]), score: [1, 0])
		XCTAssertEqual(4.51, match.winnerMatchRatings[0])
		XCTAssertEqual(4.43, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.33, match.loserMatchRatings[0])
		XCTAssertEqual(4.40, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual([4.40, 4.45, 4.44], p4_65.previousSinglesRatings)
		XCTAssertEqual([4.43, 4.39, 4.41], p4_20.previousSinglesRatings)
		
		match = m(players: ([findPlayer(p4_65)], [findPlayer(p4_20)]), score: [6, 0, 6, 1])
		XCTAssertEqual(5.09, match.winnerMatchRatings[0])
		XCTAssertEqual(4.59, match.winnerDynamicRatings[0])
		XCTAssertEqual(3.74, match.loserMatchRatings[0])
		XCTAssertEqual(4.24, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual([4.59, 4.40, 4.45, 4.44], p4_65.previousSinglesRatings)
		XCTAssertEqual([4.24, 4.43, 4.39, 4.41], p4_20.previousSinglesRatings)
		
		match = m(players: ([findPlayer(p4_65)], [findPlayer(p4_20)]), score: [6, 2, 6, 1])
		XCTAssertEqual(4.78, match.winnerMatchRatings[0])
		XCTAssertEqual(4.55, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.05, match.loserMatchRatings[0])
		XCTAssertEqual(4.27, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual([4.55, 4.59, 4.40, 4.45, 4.44], p4_65.previousSinglesRatings)
		XCTAssertEqual([4.27, 4.24, 4.43, 4.39, 4.41], p4_20.previousSinglesRatings)
	}
}
