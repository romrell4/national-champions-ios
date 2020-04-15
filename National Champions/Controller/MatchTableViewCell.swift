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
	
	private var match: Match!
	
	func setMatch(_ match: Match, forPlayer player: Player? = nil) {
		self.match = match
		
		winner1Label.setTextOrHide(text: getPlayerName(for: match.winner1, in: match))
		winner2Label.setTextOrHide(text: getPlayerName(for: match.winner2, in: match), additionalViewsToHide: [winnerDividerLabel])
		loser1Label.setTextOrHide(text: getPlayerName(for: match.loser1, in: match))
		loser2Label.setTextOrHide(text: getPlayerName(for: match.loser2, in: match), additionalViewsToHide: [loserDividerLabel])
		
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
		
		if let player = player, let (matchRating, dynamicRating) = match.findRatings(for: player) {
			ratingsStackView.isHidden = false
			matchRatingLabel.text = "Match: \(matchRating)"
			dynamicRatingLabel.text = "Dynamic: \(dynamicRating)"
		} else {
			ratingsStackView.isHidden = true
		}
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		let labelsWithPlayers = zip(
			[self.winner1Label, self.winner2Label, self.loser1Label, self.loser2Label],
			[self.match.winner1, self.match.winner2, self.match.loser1, self.match.loser2]
		)
		
		UIView.animate(withDuration: 0.5, animations: {
			labelsWithPlayers.forEach { (label, _) in
				label?.alpha = 0
			}
		}) { _ in
			labelsWithPlayers.forEach { (label, player) in
				label?.text = self.getPlayerName(for: player, in: self.match)
			}
			UIView.animate(withDuration: 0.5) {
				labelsWithPlayers.forEach { (label, _) in
					label?.alpha = 1
				}
			}
		}
	}
	
	private func getPlayerName(for player: Player?, in match: Match) -> String? {
		guard let player = player else { return nil }
		let rating: Double
		if isSelected, let newMatchRating = match.findRatings(for: player)?.0 {
			rating = newMatchRating
		} else {
			rating = match.isSingles ? player.singlesRating : player.doublesRating
		}
		return "\(player.name) (\(rating))"
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
