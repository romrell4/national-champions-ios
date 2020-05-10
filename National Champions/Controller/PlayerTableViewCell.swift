//
//  PlayerTableViewCell.swift
//  National Champions
//
//  Created by Eric Romrell on 3/19/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

class PlayerTableViewCell: UITableViewCell {
	@IBOutlet private weak var nameLabel: UILabel!
	@IBOutlet private weak var recordLabel: UILabel!
	@IBOutlet private weak var singlesRatingLabel: UILabel!
	@IBOutlet private weak var doublesRatingLabel: UILabel!
	
	var player: Player! {
		didSet {
			nameLabel.text = player.name
			let (wins, losses) = player.record
			recordLabel.text = "Record: \(wins)-\(losses)"
			singlesRatingLabel.text = "\(player.singlesRating)"
			doublesRatingLabel.text = "\(player.doublesRating)"
		}
	}
}
