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
	
	private func setUpMatchHistory(_ playerRatings: [(Player, [Double], [Double])]) {
		let createFakeMatch: (Player, Double, Bool) -> Match = { (player, dynamicRating, singles) in
			//Create a fake match, then override the rating
			let players = singles ? ([player], [p(0.0)]) : ([player, p(0.0)], [p(0.0), p(0.0)])
			var match = m(players: players, score: [])
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
		XCTAssertEqual(4.59, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.44, match.winnerCompRating)
		XCTAssertEqual(4.41, match.loserMatchRatings[0])
		XCTAssertEqual(4.25, match.loserDynamicRatings[0])
		XCTAssertEqual(4.41, match.loserCompRating)
	}
	
	func testDoublesNoHistory() {
		let match = m(players: ([p(4.00), p(4.01)], [p(4.02), p(4.03)]), score: [6, 1])
		XCTAssertEqual(4.34, match.winnerMatchRatings[0])
		XCTAssertEqual(4.08, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.35, match.winnerMatchRatings[1])
		XCTAssertEqual(4.09, match.winnerDynamicRatings[1])
		XCTAssertEqual(8.69, match.winnerCompRating)
		XCTAssertEqual(3.68, match.loserMatchRatings[0])
		XCTAssertEqual(3.93, match.loserDynamicRatings[0])
		XCTAssertEqual(3.69, match.loserMatchRatings[1])
		XCTAssertEqual(3.94, match.loserDynamicRatings[1])
		XCTAssertEqual(7.37, match.loserCompRating)
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
		XCTAssertEqual(4.00, match.winnerCompRating)
		XCTAssertEqual(3.81, match.loserMatchRatings[0])
		XCTAssertEqual(3.78, match.loserDynamicRatings[0])
		XCTAssertEqual(3.81, match.loserCompRating)
		XCTAssertEqual("""
			Changes:
			- 4.05: 4.05 -> 4.01
			- 3.76: 3.76 -> 3.78
			""", match.getChangeDescription())
	}

	func testDoublesWithHistory() {
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
		XCTAssertEqual(7.71, match.winnerCompRating)
		XCTAssertEqual(3.82, match.loserMatchRatings[0])
		XCTAssertEqual(3.75, match.loserDynamicRatings[0])
		XCTAssertEqual(3.77, match.loserMatchRatings[1])
		XCTAssertEqual(3.74, match.loserDynamicRatings[1])
		XCTAssertEqual(7.59, match.loserCompRating)
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
		let jihoon = p(4.65)
		let eric = p(4.20)
		[jihoon, eric].save()
		
		let findPlayer: (Player) -> Player = { player in
			return Player.loadAll().first { $0 == player }!
		}
		
		XCTAssertEqual([4.65, 4.65, 4.65], jihoon.previousSinglesRatings())
		XCTAssertEqual([4.20, 4.20, 4.20], eric.previousSinglesRatings())
		
		var match = m(players: ([findPlayer(jihoon)], [findPlayer(eric)]), score: [6, 4, 6, 4])
		XCTAssertEqual(4.44, match.winnerMatchRatings[0])
		XCTAssertEqual(4.59, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.41, match.loserMatchRatings[0])
		XCTAssertEqual(4.25, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual(4.59, findPlayer(jihoon).singlesRating)
		XCTAssertEqual(4.25, findPlayer(eric).singlesRating)
		XCTAssertEqual([4.59, 4.65, 4.65], jihoon.previousSinglesRatings())
		XCTAssertEqual([4.25, 4.20, 4.20], eric.previousSinglesRatings())
		
		match = m(players: ([findPlayer(jihoon)], [findPlayer(eric)]), score: [5, 7, 6, 4, 1, 0])
		XCTAssertEqual(4.31, match.winnerMatchRatings[0])
		XCTAssertEqual(4.55, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.53, match.loserMatchRatings[0])
		XCTAssertEqual(4.29, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual(4.55, findPlayer(jihoon).singlesRating)
		XCTAssertEqual(4.29, findPlayer(eric).singlesRating)
		XCTAssertEqual([4.55, 4.59, 4.65], jihoon.previousSinglesRatings())
		XCTAssertEqual([4.29, 4.25, 4.20], eric.previousSinglesRatings())
		
		match = m(players: ([findPlayer(eric)], [findPlayer(jihoon)]), score: [1, 0])
		XCTAssertEqual(4.61, match.winnerMatchRatings[0])
		XCTAssertEqual(4.33, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.23, match.loserMatchRatings[0])
		XCTAssertEqual(4.50, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual(4.50, findPlayer(jihoon).singlesRating)
		XCTAssertEqual(4.33, findPlayer(eric).singlesRating)
		XCTAssertEqual([4.50, 4.55, 4.59], jihoon.previousSinglesRatings())
		XCTAssertEqual([4.33, 4.29, 4.25], eric.previousSinglesRatings())

		match = m(players: ([findPlayer(jihoon)], [findPlayer(eric)]), score: [6, 0, 6, 1])
		XCTAssertEqual(4.99, match.winnerMatchRatings[0])
		XCTAssertEqual(4.65, match.winnerDynamicRatings[0])
		XCTAssertEqual(3.84, match.loserMatchRatings[0])
		XCTAssertEqual(4.17, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual(4.65, findPlayer(jihoon).singlesRating)
		XCTAssertEqual(4.17, findPlayer(eric).singlesRating)
		XCTAssertEqual([4.65, 4.50, 4.55], jihoon.previousSinglesRatings())
		XCTAssertEqual([4.17, 4.33, 4.29], eric.previousSinglesRatings())

		match = m(players: ([findPlayer(jihoon)], [findPlayer(eric)]), score: [6, 2, 6, 1])
		XCTAssertEqual(4.71, match.winnerMatchRatings[0])
		XCTAssertEqual(4.60, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.11, match.loserMatchRatings[0])
		XCTAssertEqual(4.22, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual(4.60, findPlayer(jihoon).singlesRating)
		XCTAssertEqual(4.22, findPlayer(eric).singlesRating)
		XCTAssertEqual([4.60, 4.65, 4.50], jihoon.previousSinglesRatings())
		XCTAssertEqual([4.22, 4.17, 4.33], eric.previousSinglesRatings())
	}
}
