//
//  MatchTableViewCell.swift
//  National Champions
//
//  Created by Eric Romrell on 3/23/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

protocol MatchTableViewCellDelegate {
	func displayCompRating(me: Player, comp: Player)
}

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
	
	@IBOutlet private weak var ratingsStackView: UIStackView?
	@IBOutlet private weak var matchRatingLabel: UILabel?
	@IBOutlet private weak var companionshipRatingButton: UIButton?
	@IBOutlet private weak var dynamicRatingLabel: UILabel?
	
	private var match: Match!
	private var player: Player?
	private var delegate: MatchTableViewCellDelegate?
	
	func setMatch(_ match: Match, forPlayer player: Player? = nil, delegate: MatchTableViewCellDelegate? = nil) {
		self.match = match
		self.player = player
		self.delegate = delegate
		
		winner1Label.setTextOrHide(text: getPlayerName(for: match.winner1))
		winner2Label.setTextOrHide(text: getPlayerName(for: match.winner2), additionalViewsToHide: [winnerDividerLabel])
		loser1Label.setTextOrHide(text: getPlayerName(for: match.loser1))
		loser2Label.setTextOrHide(text: getPlayerName(for: match.loser2), additionalViewsToHide: [loserDividerLabel])
		
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
		
		//Only display the personal ratings if they're viewing from a player's perspective
		if let player = player, let (matchRating, compRating, dynamicRating) = match.findRatings(for: player) {
			ratingsStackView?.isHidden = false
			//Only display the comp rating if it's a double match
			companionshipRatingButton?.isHidden = !match.isDoubles
			matchRatingLabel?.text = "Match: \(matchRating)"
			companionshipRatingButton?.setTitle("Comp: \(compRating)", for: .normal)
			dynamicRatingLabel?.text = "Dynamic: \(dynamicRating)"
		} else {
			ratingsStackView?.isHidden = true
		}
		
		let background = UIView()
		background.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.3)
		selectedBackgroundView = background
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		let changing = selected != isSelected
		super.setSelected(selected, animated: animated)
		
		guard changing else { return }
		
		let labels = [self.winner1Label, self.winner2Label, self.loser1Label, self.loser2Label]
		
		UIView.animate(withDuration: 0.5, animations: {
			labels.forEach { $0?.alpha = 0 }
		}) { _ in
			//Make sure this doesn't happen immediately (wait until after delay), or else the old, reycled match's players will be used
			zip(labels, [self.match.winner1, self.match.winner2, self.match.loser1, self.match.loser2]).forEach { (label, player) in
				label?.text = self.getPlayerName(for: player)
			}
			UIView.animate(withDuration: 0.5) {
				labels.forEach { $0?.alpha = 1 }
			}
		}
	}
	
	@IBAction func companionshipRatingButtonTapped(_ sender: Any) {
		if let me = player, let comp = match.findCompanion(for: me) {
			delegate?.displayCompRating(me: me, comp: comp)
		}
	}
	
	private func getPlayerName(for player: Player?) -> String? {
		guard let player = player else { return nil }
		let rating: Double
		if isSelected, let newDynamicRating = self.match.findRatings(for: player)?.2 {
			rating = newDynamicRating
		} else {
			rating = self.match.isSingles ? player.singlesRating : player.doublesRating
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
