//
//  PlayersViewController.swift
//  Coach Toolbox
//
//  Created by Eric Romrell on 3/19/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

class PlayersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	private var players = Player.loadAll() {
		didSet {
			players.save()
		}
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.tableView.tableFooterView = UIView()
    }
	
	//MARK: UITableViewDelegate/DataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return players.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let player = players[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		cell.textLabel?.text = player.name
		cell.detailTextLabel?.text = "\(player.rating)"
		return cell
	}
	
	//MARK: Actions
	
	@IBAction func addPlayer(_ sender: Any) {
		let alert = UIAlertController(title: "Add Player", message: nil, preferredStyle: .alert)
		alert.addTextField { (textField) in
			textField.placeholder = "Name"
		}
		alert.addTextField { (textField) in
			textField.placeholder = "Rating"
		}
		alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] (_) in
			guard
				let name = alert.textFields?[0].text,
				let rating = alert.textFields?[1].text?.toDouble()
			else { return }
			
			self?.players.append(Player(name: name, rating: rating))
						
			self?.tableView.reloadData()
		})
		self.present(alert, animated: true)
	}
}
