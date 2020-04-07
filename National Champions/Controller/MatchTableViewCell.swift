//
//  MatchTableViewCell.swift
//  National Champions
//
//  Created by Eric Romrell on 3/23/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

class MatchTableViewCell: UITableViewCell {
	
	@IBOutlet private weak var winner1Label: UILabel!
	@IBOutlet private weak var winnerDividerLabel: UILabel!
	@IBOutlet private weak var winner2Label: UILabel!
	@IBOutlet private weak var loser1Label: UILabel!
	@IBOutlet private weak var loserDividerLabel: UILabel!
	@IBOutlet private weak var loser2Label: UILabel!
	
	@IBOutlet private weak var winnerSet1ScoreLabel: UILabel!
	@IBOutlet private weak var winnerSet2ScoreLabel: UILabel!
	@IBOutlet private weak var winnerSet3ScoreLabel: UILabel!
	@IBOutlet private weak var loserSet1ScoreLabel: UILabel!
	@IBOutlet private weak var loserSet2ScoreLabel: UILabel!
	@IBOutlet private weak var loserSet3ScoreLabel: UILabel!
	
	
	@IBOutlet private weak var ratingsStackView: UIStackView!
	@IBOutlet private weak var matchRatingLabel: UILabel!
	@IBOutlet private weak var dynamicRatingLabel: UILabel!
	
	func setMatch(_ match: Match, forPlayer player: Player? = nil) {
		winner1Label.setTextOrHide(text: match.winner1?.displayName(isSingles: match.isSingles))
		winner2Label.setTextOrHide(text: match.winner2?.displayName(isSingles: match.isSingles), additionalViewsToHide: [winnerDividerLabel])
		loser1Label.setTextOrHide(text: match.loser1?.displayName(isSingles: match.isSingles))
		loser2Label.setTextOrHide(text: match.loser2?.displayName(isSingles: match.isSingles), additionalViewsToHide: [loserDividerLabel])
		
		winnerSet1ScoreLabel.setTextOrHide(text: match.winnerSet1Score)
		winnerSet2ScoreLabel.setTextOrHide(text: match.winnerSet2Score)
		winnerSet3ScoreLabel.setTextOrHide(text: match.winnerSet3Score)
		loserSet1ScoreLabel.setTextOrHide(text: match.loserSet1Score)
		loserSet2ScoreLabel.setTextOrHide(text: match.loserSet2Score)
		loserSet3ScoreLabel.setTextOrHide(text: match.loserSet3Score)
		
		winner1Label.setBold(bold: player == match.winner1)
		winner2Label.setBold(bold: player == match.winner2)
		loser1Label.setBold(bold: player == match.loser1)
		loser2Label.setBold(bold: player == match.loser2)
		
		if let player = player {
			ratingsStackView.isHidden = false
			let matchRating = match.computeMatchRating(player: player, truncated: true)
			let dynamicRating = match.computeDynamicRating(player: player)
			matchRatingLabel.text = "Match: \(matchRating)"
			dynamicRatingLabel.text = "Dynamic: \(dynamicRating)"
		} else {
			ratingsStackView.isHidden = true
		}
	}
}

fileprivate extension Array where Element == Player {
	func nameString(isSingles: Bool) -> String {
		map { "\($0.name) \(isSingles ? $0.singlesRating : $0.doublesRating)" }.joined(separator: " / ")
	}
}

fileprivate extension UILabel {
	func setTextOrHide(text: Any?, additionalViewsToHide: [UIView] = []) {
		if let text = text {
			self.text = "\(text)"
		}
		([self] + additionalViewsToHide).forEach {
			$0.isHidden = text == nil
		}
	}
	
	func setBold(bold: Bool) {
		font = bold ? UIFont.boldSystemFont(ofSize: font.pointSize) : UIFont.systemFont(ofSize: font.pointSize)
	}
}
