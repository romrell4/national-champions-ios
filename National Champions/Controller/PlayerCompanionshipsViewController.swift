//
//  PlayerCompanionshipsViewController.swift
//  National Champions
//
//  Created by Eric Romrell on 7/21/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

class PlayerCompanionshipsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	//MARK: Outlets
	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var filterButton: UIBarButtonItem!
	
	//MARK: Public properties
	var player: Player!
	
	//MARK: Private properties
	private var allCompanionships = [Companionship]()
	private var displayedCompanionships: [Companionship] {
		allCompanionships.filter { $0.matchesPlayed >= matchFilterCount }
	}
	private var matchFilterCount = 0 {
		didSet {
			filterButton.title = "Filter (\(matchFilterCount))"
			self.tableView.reloadData()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.allCompanionships = player.getCompanionships().sorted(by: { (lhs, rhs) -> Bool in
			lhs.averageRating > rhs.averageRating
		})
		self.tableView.tableFooterView = UIView()
		self.tableView.reloadData()
	}
	
	//MARK: UITableView
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return displayedCompanionships.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let companionship = displayedCompanionships[indexPath.row]
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		cell.textLabel?.text = companionship.player2.name
		cell.detailTextLabel?.text = "Avg: \(companionship.averageRating.trunc()) (\(companionship.matchesPlayed))"
		return cell
	}
	
	//MARK: Listeners
	
	@IBAction func filterButtonTapped(_ sender: Any) {
		let alert = UIAlertController(title: "Minimum Match Filter", message: "Select the minumum amount of matches a companionship should play in to be in the list", preferredStyle: .alert)
		alert.addTextField { (textField) in
			textField.text = "\(self.matchFilterCount)"
			textField.keyboardType = .numberPad
		}
		alert.addAction(UIAlertAction(title: "Apply", style: .default) { (_) in
			self.matchFilterCount = alert.textFields?.first?.text?.toInt() ?? 0
		})
		self.present(alert, animated: true)
	}
}
