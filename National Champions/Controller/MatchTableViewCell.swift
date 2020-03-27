//
//  MatchTableViewCell.swift
//  National Champions
//
//  Created by Eric Romrell on 3/23/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

class MatchTableViewCell: UITableViewCell {
	@IBOutlet var winnerLabels: [UILabel]!
	@IBOutlet var loserLabels: [UILabel]!
	@IBOutlet weak var scoreLabel: UILabel!
}
