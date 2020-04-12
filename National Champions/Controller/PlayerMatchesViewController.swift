//
//  PlayerRatingsViewController.swift
//  National Champions
//
//  Created by Eric Romrell on 3/26/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

private let DATE_FORMATTER: DateFormatter = {
	let formatter = DateFormatter()
	formatter.dateStyle = .short
	formatter.timeStyle = .short
	return formatter
}()

class PlayerMatchesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	@IBOutlet private weak var filterControl: UISegmentedControl!
	@IBOutlet private weak var tableView: UITableView!
	
	var player: Player!
	
	private var allMatches = [Match]() {
		didSet {
			filterAndReload()
		}
	}
	private var filteredMatches = [Match]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = player.name
		
		allMatches = Match.loadAll().filter {
			$0.allPlayers.map { $0.playerId }.contains(player.playerId)
		}
		tableView.tableFooterView = UIView()
		tableView.reloadData()
    }
	
	//UITableView
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		filteredMatches.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		
		if let cell = cell as? MatchTableViewCell {
			let match = filteredMatches[indexPath.row]
			cell.setMatch(filteredMatches[indexPath.row], forPlayer: match.allPlayers.first { $0.playerId == player.playerId })
		}
		return cell
	}
	
	//Listeners
	
	@IBAction func filterAndReload(_ sender: Any? = nil) {
		filteredMatches = allMatches.filter {
			switch self.filterControl.selectedSegmentIndex {
			case 1: return $0.isSingles
			case 2: return $0.isDoubles
			default: return true
			}
		}
		tableView.reloadData()
	}
}
