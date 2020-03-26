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
	
	private var matches = Match.loadAll().sorted { (lhs, rhs) -> Bool in
		return lhs.matchDate > rhs.matchDate
	}
	private let players = Player.loadAll()

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
			cell.winnerLabel.text = players.first { $0.playerId == match.winner.playerId }?.name
			cell.loserLabel.text = players.first { $0.playerId == match.loser.playerId }?.name
			cell.scoreLabel.text = match.scoreText
		}
		return cell
	}
	
	func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return UISwipeActionsConfiguration(actions: [
			UIContextualAction(style: .destructive, title: "Delete") { (_, _, _) in
				self.matches.remove(at: indexPath.row)
				self.matches.save()
				self.tableView.deleteRows(at: [indexPath], with: .automatic)
			}
		])
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		//TODO: Edit?
	}
}
