//
//  PlayerTests.swift
//  NationalChampionsTests
//
//  Created by Eric Romrell on 5/10/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import XCTest
@testable import National_Champs

class PlayerTests: XCTestCase {
	override func setUp() {
		[Player]().save()
		[Match]().save()
	}
	
	override func tearDown() {
		[Player]().save()
		[Match]().save()
	}
	
	func testSimplePlayerRecord() {
		let player = p(0.0)
		[
			m(players: ([player], [p(0.0)]), score: [6, 1, 6, 1]),
			m(players: ([p(0.0)], [p(0.0)]), score: [6, 1, 6, 1]),
			m(players: ([p(0.0)], [player]), score: [6, 1, 6, 1])
		].forEach { $0.insert() }
		XCTAssertEqual(1, player.record.0)
		XCTAssertEqual(1, player.record.1)
	}
	
	func testComplexRecord() {
		let player = p(0.0)
		[
			m(players: ([player], [p(0.0)]), score: [6, 0, 6, 0]),
			m(players: ([player, p(0.0)], [p(0.0), p(0.0)]), score: [6, 0, 6, 0]),
			m(players: ([p(0.0), player], [p(0.0), p(0.0)]), score: [6, 0, 6, 0]),
			m(players: ([p(0.0)], [player]), score: [6, 0, 6, 0]),
			m(players: ([p(0.0), p(0.0)], [player, p(0.0)]), score: [6, 0, 6, 0]),
			m(players: ([p(0.0), p(0.0)], [p(0.0), player]), score: [6, 0, 6, 0]),
			m(players: ([p(0.0)], [p(0.0)]), score: [6, 0, 6, 0]),
			m(players: ([p(0.0), p(0.0)], [p(0.0), p(0.0)]), score: [6, 0, 6, 0])
		].forEach { $0.insert() }
		XCTAssertEqual(3, player.record.0)
		XCTAssertEqual(3, player.record.1)
	}
	
	func testPreviousMatches() {
		let p1 = p(0.1)
		let p2 = p(0.2)
		let p3 = p(0.3)
		let p4 = p(0.4)
		let p5 = p(0.5)
		[p1, p2, p3, p4, p5].save()
		
		[
			([p1], [p2]),
			([p2], [p1]),
			([p5], [p1]),
			([p1, p3], [p2, p4]),
			([p1, p2], [p4, p3])
		].forEach {
			m(players: $0, score: [6, 0, 6, 0]).insert()
		}
		
		XCTAssertEqual(3, p1.previousSinglesMatches().count)
		XCTAssertEqual(2, p2.previousSinglesMatches().count)
		XCTAssertEqual(0, p3.previousSinglesMatches().count)
		XCTAssertEqual(0, p4.previousSinglesMatches().count)
		XCTAssertEqual(1, p5.previousSinglesMatches().count)
		XCTAssertEqual(2, p1.previousDoublesMatches().count)
		XCTAssertEqual(2, p2.previousDoublesMatches().count)
		XCTAssertEqual(2, p3.previousDoublesMatches().count)
		XCTAssertEqual(2, p4.previousDoublesMatches().count)
		XCTAssertEqual(0, p5.previousDoublesMatches().count)
	}
}
