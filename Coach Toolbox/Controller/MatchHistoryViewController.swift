//
//  MatchHistoryViewController.swift
//  Coach Toolbox
//
//  Created by Eric Romrell on 3/23/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

class MatchHistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	@IBOutlet private weak var tableView: UITableView!
	
	let matches = Match.loadAll().sorted { (lhs, rhs) -> Bool in
		return lhs.matchDate > rhs.matchDate
	}
	let players = Player.loadAll()

    override func viewDidLoad() {
        super.viewDidLoad()
        
		tableView.tableFooterView = UIView()
    }
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return matches.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		if let cell = cell as? MatchTableViewCell {
			let match = matches[indexPath.row]
			cell.winnerLabel.text = players.first { $0.playerId == match.winnerId }?.name
			cell.loserLabel.text = players.first { $0.playerId == match.loserId }?.name
			cell.scoreLabel.text = match.scoreText
		}
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		//TODO: Edit or delete?
	}
}
