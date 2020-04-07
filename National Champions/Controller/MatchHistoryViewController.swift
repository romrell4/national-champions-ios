//
//  MatchHistoryViewController.swift
//  National Champions
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
	
	//UITableView functions
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return matches.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		if let cell = cell as? MatchTableViewCell {
			let match = matches[indexPath.row]
			//Start them all as nil (so that they only become visible if they have data)
			(cell.winnerLabels + cell.loserLabels).forEach {
				$0.isHidden = true
			}
			(zip(cell.winnerLabels, match.winners).map { $0 } + zip(cell.loserLabels, match.losers).map { $0 }).forEach { (label, player) in
				label.isHidden = false
				label.text = player.name
			}
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
	
	//MARK: Listeners
	
	@IBAction func importTapped(_ sender: Any) {
		let alert = UIAlertController(title: "Import Matches", message: "Are you sure you'd like to import matches? This will add these new matches to the matches you already have tracked in your system.", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Import", style: .default, handler: { (_) in
			Match.loadFromUrl(url: "https://romrell4.github.io/national-champions-ios/matches.json") {
				switch $0 {
				case .Success(let list):
					self.matches = list.sorted { (lhs, rhs) -> Bool in
						return lhs.matchDate > rhs.matchDate
					}
					self.tableView.reloadData()
				case .Error(let message):
					self.displayAlert(title: "Error", message: message)
				}
			}
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(alert, animated: true)
	}
}
