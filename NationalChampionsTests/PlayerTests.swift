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
}
