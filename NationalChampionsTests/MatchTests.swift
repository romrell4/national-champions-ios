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
	
	override func setUp() {
		[Player]().save()
		[Match]().save()
	}
	
	override func tearDown() {
		[Player]().save()
		[Match]().save()
	}
	
	func testSinglesNoHistory() {
		let match = m(players: ([p(4.65)], [p(4.20)]), score: [6, 4, 6, 4])
		XCTAssertEqual(4.44, match.winnerMatchRatings[0])
		XCTAssertEqual(4.59, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.44, match.winnerCompRating)
		XCTAssertEqual(4.45, match.loserMatchRatings[0])
		XCTAssertEqual(4.26, match.loserDynamicRatings[0])
		XCTAssertEqual(4.45, match.loserCompRating)
	}
	
	func testDoublesNoHistory() {
		let match = m(players: ([p(4.00), p(4.01)], [p(4.02), p(4.03)]), score: [6, 1])
		XCTAssertEqual(4.34, match.winnerMatchRatings[0])
		XCTAssertEqual(4.08, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.35, match.winnerMatchRatings[1])
		XCTAssertEqual(4.09, match.winnerDynamicRatings[1])
		XCTAssertEqual(8.69, match.winnerCompRating)
		XCTAssertEqual(3.73, match.loserMatchRatings[0])
		XCTAssertEqual(3.94, match.loserDynamicRatings[0])
		XCTAssertEqual(3.74, match.loserMatchRatings[1])
		XCTAssertEqual(3.95, match.loserDynamicRatings[1])
		XCTAssertEqual(7.47, match.loserCompRating)
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
		XCTAssertEqual(3.85, match.loserMatchRatings[0])
		XCTAssertEqual(3.79, match.loserDynamicRatings[0])
		XCTAssertEqual(3.85, match.loserCompRating)
		XCTAssertEqual("""
			Dynamic Rating Changes:
			- 4.05: 4.05 -> 4.01
			- 3.76: 3.76 -> 3.79

			Match Ratings:
			- 4.05: 4.0
			- 3.76: 3.85
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
		XCTAssertEqual(3.86, match.loserMatchRatings[0])
		XCTAssertEqual(3.76, match.loserDynamicRatings[0])
		XCTAssertEqual(3.81, match.loserMatchRatings[1])
		XCTAssertEqual(3.75, match.loserDynamicRatings[1])
		XCTAssertEqual(7.67, match.loserCompRating)
		XCTAssertEqual("""
			Dynamic Rating Changes:
			- 4.01: 4.01 -> 3.98
			- 3.78: 3.78 -> 3.78
			- 3.78: 3.78 -> 3.76
			- 3.73: 3.73 -> 3.75

			Match Ratings:
			- 4.01: 3.97
			- 3.78: 3.74
			- 3.78: 3.86
			- 3.73: 3.81
			""", match.getChangeDescription())
	}
	
	func testDoublesRegression() {
		let kk = p(3.82)
		let ss = p(3.69)
		let po = p(3.62)
		let bc = p(3.99)
		setUpMatchHistory(
			[
				(kk, [], [3.71, 3.60, 3.82]),
				(ss, [], [3.87, 3.88, 3.69]),
				(po, [], [3.90, 3.73, 3.62]),
				(bc, [], [3.80, 3.88, 3.99])
			]
		)
		
		let match = m(players: ([kk, ss], [po, bc]), score: [7, 6, 7, 6])
		XCTAssertEqual(4.04, match.winnerMatchRatings[0])
		XCTAssertEqual(3.79, match.winnerDynamicRatings[0])
		XCTAssertEqual(3.91, match.winnerMatchRatings[1])
		XCTAssertEqual(3.83, match.winnerDynamicRatings[1])
		XCTAssertEqual(3.42, match.loserMatchRatings[0])
		XCTAssertEqual(3.66, match.loserDynamicRatings[0])
		XCTAssertEqual(3.79, match.loserMatchRatings[1])
		XCTAssertEqual(3.86, match.loserDynamicRatings[1])
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
		
		XCTAssertEqual([4.65, 4.65, 4.65], jihoon.previousSinglesRatings())
		XCTAssertEqual([4.20, 4.20, 4.20], eric.previousSinglesRatings())
		
		var match = m(players: ([Player.find(jihoon)], [Player.find(eric)]), score: [6, 4, 6, 4])
		XCTAssertEqual(4.44, match.winnerMatchRatings[0])
		XCTAssertEqual(4.59, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.45, match.loserMatchRatings[0])
		XCTAssertEqual(4.26, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual(4.59, Player.find(jihoon).singlesRating)
		XCTAssertEqual(4.26, Player.find(eric).singlesRating)
		XCTAssertEqual([4.59, 4.65, 4.65], jihoon.previousSinglesRatings())
		XCTAssertEqual([4.26, 4.20, 4.20], eric.previousSinglesRatings())
		
		match = m(players: ([Player.find(jihoon)], [Player.find(eric)]), score: [5, 7, 6, 4, 1, 0])
		XCTAssertEqual(4.32, match.winnerMatchRatings[0])
		XCTAssertEqual(4.55, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.54, match.loserMatchRatings[0])
		XCTAssertEqual(4.30, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual(4.55, Player.find(jihoon).singlesRating)
		XCTAssertEqual(4.30, Player.find(eric).singlesRating)
		XCTAssertEqual([4.55, 4.59, 4.65], jihoon.previousSinglesRatings())
		XCTAssertEqual([4.30, 4.26, 4.20], eric.previousSinglesRatings())
		
		match = m(players: ([Player.find(eric)], [Player.find(jihoon)]), score: [1, 0])
		XCTAssertEqual(4.61, match.winnerMatchRatings[0])
		XCTAssertEqual(4.34, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.25, match.loserMatchRatings[0])
		XCTAssertEqual(4.51, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual(4.51, Player.find(jihoon).singlesRating)
		XCTAssertEqual(4.34, Player.find(eric).singlesRating)
		XCTAssertEqual([4.51, 4.55, 4.59], jihoon.previousSinglesRatings())
		XCTAssertEqual([4.34, 4.30, 4.26], eric.previousSinglesRatings())

		match = m(players: ([Player.find(jihoon)], [Player.find(eric)]), score: [6, 0, 6, 1])
        XCTAssertEqual(5.00, match.winnerMatchRatings[0])
		XCTAssertEqual(4.66, match.winnerDynamicRatings[0])
		XCTAssertEqual(3.96, match.loserMatchRatings[0])
		XCTAssertEqual(4.21, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual(4.66, Player.find(jihoon).singlesRating)
		XCTAssertEqual(4.21, Player.find(eric).singlesRating)
		XCTAssertEqual([4.66, 4.51, 4.55], jihoon.previousSinglesRatings())
		XCTAssertEqual([4.21, 4.34, 4.30], eric.previousSinglesRatings())

		match = m(players: ([Player.find(jihoon)], [Player.find(eric)]), score: [6, 2, 6, 1])
		XCTAssertEqual(4.75, match.winnerMatchRatings[0])
		XCTAssertEqual(4.61, match.winnerDynamicRatings[0])
		XCTAssertEqual(4.21, match.loserMatchRatings[0])
		XCTAssertEqual(4.26, match.loserDynamicRatings[0])
		match.insert()
		XCTAssertEqual(4.61, Player.find(jihoon).singlesRating)
		XCTAssertEqual(4.26, Player.find(eric).singlesRating)
		XCTAssertEqual([4.61, 4.66, 4.51], jihoon.previousSinglesRatings())
		XCTAssertEqual([4.26, 4.21, 4.34], eric.previousSinglesRatings())
	}
	
	func testDeletingMatch() {
		let p1 = p(4.0)
		let p2 = p(3.5)
		[p1, p2].save()
		
		let match = m(players: ([Player.find(p1)], [Player.find(p2)]), score: [6, 0, 6, 0])
		match.insert()
		XCTAssertEqual(4.05, Player.find(p1).singlesRating)
		XCTAssertEqual(3.47, Player.find(p2).singlesRating)
		XCTAssertEqual(1, Match.loadAll().count)
		
		match.delete()
		XCTAssertEqual(4.0, Player.find(p1).singlesRating)
		XCTAssertEqual(3.5, Player.find(p2).singlesRating)
		XCTAssertEqual(0, Match.loadAll().count)
	}
	
	func testEditingMostRecentMatch() {
		let p1 = p(4.0)
		let p2 = p(3.5)
		[p1, p2].save()
		
		var match = m(players: ([Player.find(p1)], [Player.find(p2)]), score: [6, 0, 6, 0])
		match.insert()
		XCTAssertEqual(4.05, Player.find(p1).singlesRating)
		XCTAssertEqual(3.47, Player.find(p2).singlesRating)
		XCTAssertEqual(1, Match.loadAll().count)
		
		match.edit(scores: [6, 1, 6, 0])

		XCTAssertEqual(4.04, Player.find(p1).singlesRating)
		XCTAssertEqual(3.48, Player.find(p2).singlesRating)
		XCTAssertEqual(1, Match.loadAll().count)
	}
	
	func testDeletingOldMatch() {
		let p1 = p(4.0)
		let p2 = p(3.5)
		let p3 = p(3.5)
		[p1, p2, p3].save()
		
		//Bad match reported for P1 and P2 that makes P1 look way bad
		let match = m(players: ([Player.find(p1)], [Player.find(p2)]), score: [0, 6, 0, 6])
		match.insert()
		XCTAssertEqual(3.69, Player.find(p1).singlesRating)
		XCTAssertEqual(3.77, Player.find(p2).singlesRating)
		
		//Normal match for P1 and P3
		m(players: ([Player.find(p1)], [Player.find(p3)]), score: [6, 0, 6, 0]).insert()
		XCTAssertEqual(3.97, Player.find(p1).singlesRating)
		XCTAssertEqual(3.39, Player.find(p3).singlesRating)
		
		//After deleting the bad match, P1 and P3 should have updated ratings. P2 should be as it started
		match.delete()
		XCTAssertEqual(4.05, Player.find(p1).singlesRating)
		XCTAssertEqual(3.5, Player.find(p2).singlesRating)
		XCTAssertEqual(3.47, Player.find(p3).singlesRating)
	}
	
	func testEditingOldMatch() {
		let p1 = p(4.0)
		let p2 = p(3.5)
		let p3 = p(3.5)
		
		[p1, p2, p3].save()
		
		var match = m(players: ([Player.find(p1)], [Player.find(p2)]), score: [0, 6, 0, 6])
		match.insert()
		XCTAssertEqual(3.69, Player.find(p1).singlesRating)
		XCTAssertEqual(3.77, Player.find(p2).singlesRating)
		
		m(players: ([Player.find(p1)], [Player.find(p3)]), score: [6, 0, 6, 0]).insert()
		XCTAssertEqual(3.97, Player.find(p1).singlesRating)
		XCTAssertEqual(3.39, Player.find(p3).singlesRating)
		
		//Update the first match to be between P1 and P3. P2 should no longer have been updated, and P1/P3 will change
		match.edit(winners: [Player.find(p1)], losers: [Player.find(p3)], scores: [6, 3, 6, 3])
		//After first match updates, before applying second: P1 = 3.96, P3 = 3.53
		XCTAssertEqual(4.05, Player.find(p1).singlesRating)
		XCTAssertEqual(3.5, Player.find(p2).singlesRating)
		XCTAssertEqual(3.47, Player.find(p3).singlesRating)
		
		XCTAssertEqual(2, Match.loadAll().count)
	}
	
	func testDeletingDoublesMatchWithHistory() {
		let kk = p(3.82)
		let ss = p(3.69)
		let po = p(3.62)
		let bc = p(3.99)
		[kk, ss, po, bc].save()
		setUpMatchHistory(
			[
				(kk, [], [3.71, 3.60, 3.82]),
				(ss, [], [3.87, 3.88, 3.69]),
				(po, [], [3.90, 3.73, 3.62]),
				(bc, [], [3.80, 3.88, 3.99])
			]
		)
		
		XCTAssertEqual(3.82, Player.find(kk).doublesRating)
		let match = m(players: ([kk, ss], [po, bc]), score: [7, 6, 7, 6])
		match.insert()
		XCTAssertEqual(3.79, Player.find(kk).doublesRating)
		match.delete()
		XCTAssertEqual(3.82, Player.find(kk).doublesRating)
	}
	
	func testEditingDoublesMatchWithHistory() {
		let kk = p(3.71)
		let ss = p(3.87)
		let po = p(3.90)
		let bc = p(3.80)
		[kk, ss, po, bc].save()
		setUpMatchHistory(
			[
				(kk, [], [3.79, 3.66, 3.77, 3.71]),
				(ss, [], [3.84, 3.64, 3.75, 3.87]),
				(po, [], [3.95, 3.84, 3.73, 3.90]),
				(bc, [], [3.76, 3.73, 3.80, 3.80])
			]
		)
		var match = m(players: ([Player.find(bc), Player.find(ss)], [Player.find(kk), Player.find(po)]), score: [6, 1, 6, 3])
		match.insert()
		m(players: ([Player.find(bc), Player.find(kk)], [Player.find(ss), Player.find(po)]), score: [6, 1, 6, 3]).insert()
		m(players: ([Player.find(kk), Player.find(ss)], [Player.find(po), Player.find(bc)]), score: [7, 6, 7, 6]).insert()
		XCTAssertEqual(3.80, Player.find(kk).doublesRating)
		XCTAssertEqual(3.84, Player.find(ss).doublesRating)
		XCTAssertEqual(3.68, Player.find(po).doublesRating)
		XCTAssertEqual(3.86, Player.find(bc).doublesRating)
		match.edit(scores: [6, 0, 6, 0])
		XCTAssertEqual(3.77, Player.find(kk).doublesRating)
		XCTAssertEqual(3.87, Player.find(ss).doublesRating)
		XCTAssertEqual(3.66, Player.find(po).doublesRating)
		XCTAssertEqual(3.89, Player.find(bc).doublesRating)
	}
	
	func testFindPlayer() {
		let p1 = p(0.1)
		let p2 = p(0.2)
		let match = m(players: ([p1], [p2]), score: [6, 0, 6, 0])
		XCTAssertEqual(p1, match.findPlayer(player: p1))
		XCTAssertEqual(p2, match.findPlayer(player: p2))
	}
	
	func testFindCompanion() {
		let p1 = p(0.1)
		let p2 = p(0.2)
		let p3 = p(0.3)
		let p4 = p(0.4)
		let p5 = p(0.5)
		let match = m(players: ([p1, p2], [p3, p4]), score: [6, 0, 6, 0])
		XCTAssertEqual(p2, match.findCompanion(for: p1))
		XCTAssertEqual(p1, match.findCompanion(for: p2))
		XCTAssertEqual(p4, match.findCompanion(for: p3))
		XCTAssertEqual(p3, match.findCompanion(for: p4))
		XCTAssertNil(match.findCompanion(for: p5))
	}
}
