//
//  PlayersViewController.swift
//  Coach Toolbox
//
//  Created by Eric Romrell on 3/19/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

class PlayersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	@IBOutlet private weak var sortControl: UISegmentedControl!
	@IBOutlet private weak var tableView: UITableView!
	
	private var players = Player.loadAll() {
		didSet {
			tableView.reloadData()
		}
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.tableView.tableFooterView = UIView()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		updateSort()
	}
	
	//MARK: UITableViewDelegate/DataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return players.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		if let cell = cell as? PlayerTableViewCell {
			cell.player = players[indexPath.row]
		}
		return cell
	}
	
	//MARK: Actions
	
	@IBAction func addPlayer(_ sender: Any) {
		let alert = UIAlertController(title: "Add Player", message: nil, preferredStyle: .alert)
		["Name", "Singles Rating", "Doubles Rating"].forEach { placeholder in
			alert.addTextField { textField in
				textField.placeholder = placeholder
			}
		}
		alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] (_) in
			guard
				let name = alert.textFields?[0].text,
				let singlesRating = alert.textFields?[1].text?.toDouble(),
				let doublesRating = alert.textFields?[2].text?.toDouble()
			else { return }
			
			self?.players.append(Player(name: name, singlesRating: singlesRating, doublesRating: doublesRating))
			self?.players.save()
			self?.updateSort()
		})
		self.present(alert, animated: true)
	}
	
	@IBAction func updateSort(_ sender: Any? = nil) {
		players = players.sorted { (lhs, rhs) -> Bool in
			if self.sortControl.selectedSegmentIndex == 0 {
				return lhs.singlesRating > rhs.singlesRating
			} else {
				return lhs.doublesRating > rhs.doublesRating
			}
		}
	}
}
