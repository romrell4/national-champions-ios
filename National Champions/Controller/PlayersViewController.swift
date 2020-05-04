//
//  PlayersViewController.swift
//  National Champions
//
//  Created by Eric Romrell on 3/19/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

class PlayersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	@IBOutlet private weak var importPlayersButton: UIBarButtonItem!
	@IBOutlet private weak var addPlayerButton: UIBarButtonItem!
	@IBOutlet private weak var sortControl: UISegmentedControl!
	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var spinner: UIActivityIndicatorView!
	
	private var players = Player.loadAll()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.tableView.tableFooterView = UIView()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		players = Player.loadAll()
		sortAndReload()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? PlayerMatchesViewController,
			let cell = sender as? UITableViewCell,
			let indexPath = tableView.indexPath(for: cell) {
			vc.player = players[indexPath.row]
		}
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
	
	func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, _ in
			self.displayPlayerPopUp(title: "Edit Player", playerIndex: indexPath.row) { _ in
				self.tableView.reloadRows(at: [indexPath], with: .automatic)
			}
		}
		editAction.backgroundColor = .blue
		return UISwipeActionsConfiguration(actions: [editAction])
	}
	
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		UISwipeActionsConfiguration(actions: [
			UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
				let player = self.players[indexPath.row]
				
				//Find any matches this player played
				let matches = Match.loadAll().filter {
					($0.winners.map { $0.playerId } + $0.losers.map { $0.playerId }).contains(player.playerId)
				}
				if matches.count > 0 {
					self.displayAlert(title: "Error", message: "This player cannot be deleted, because this player has been involved in matches already saved.") { _ in
						self.tableView.reloadRows(at: [indexPath], with: .automatic)
					}
				} else {
					self.players.remove(at: indexPath.row)
					self.players.save()
					self.tableView.deleteRows(at: [indexPath], with: .automatic)
				}
			}
		])
	}
	
	//MARK: Actions
	
	@IBAction func addPlayer(_ sender: Any) {
		displayPlayerPopUp(title: "Add Player")
	}
	
	@IBAction func importPlayers(_ sender: Any) {
		let alert = UIAlertController(title: "Import Players", message: "Are you sure you'd like to import players? This will add new players and update any existing players that already exist in your system.", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Import", style: .default, handler: { (_) in
			self.spinner.startAnimating()
			// Uncomment out the next line to test with another import file
			// Player.loadFromUrl(url: "https://romrell4.github.io/national-champions-ios/test_players.json") {
			Player.loadFromUrl(url: "https://romrell4.github.io/national-champions-ios/players.json") {
				self.spinner.stopAnimating()
				switch $0 {
				case .Success(let list):
					self.players = list
					self.sortAndReload()
				case .Error(let message):
					self.displayAlert(title: "Error", message: message)
				}
			}
		}))
		alert.addAction(UIAlertAction(title: "Export", style: .default, handler: { (_) in
			UIPasteboard.general.string = try? String(data: JSONEncoder().encode(self.players), encoding: .utf8)
			self.displayAlert(title: "Success", message: "The data has been copied to your clipboard. Feel free to paste it wherever.")
			//TODO: Allow multiple formats
		}))
		alert.addAction(UIAlertAction(title: "Delete All", style: .default, handler: { (_) in
			self.players = []
			self.players.save()
			self.sortAndReload()
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(alert, animated: true)
	}
	
	@IBAction func sortAndReload(_ sender: Any? = nil) {
		players = players.sorted { (lhs, rhs) -> Bool in
			if self.sortControl.selectedSegmentIndex == 0 {
				return lhs.singlesRating > rhs.singlesRating
			} else {
				return lhs.doublesRating > rhs.doublesRating
			}
		}
		tableView.reloadData()
	}
	
	//MARK: Private functions
	
	private func displayPlayerPopUp(title: String, playerIndex: Int? = nil, completionHandler: ((UIAlertAction) -> Void)? = nil) {
		let player = players[safe: playerIndex]
		let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
		alert.addTextField {
			$0.placeholder = "Name"
			$0.autocapitalizationType = .words
			$0.text = player?.name
			$0.returnKeyType = .next
		}
		alert.addTextField {
			$0.placeholder = "Singles Rating"
			$0.keyboardType = .decimalPad
			$0.text = player?.singlesRating.description
			$0.returnKeyType = .next
		}
		alert.addTextField {
			$0.placeholder = "Doubles Rating"
			$0.keyboardType = .decimalPad
			$0.text = player?.doublesRating.description
			$0.returnKeyType = .done
		}
		alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
			guard
				let name = alert.textFields?[0].text,
				let singlesRating = alert.textFields?[1].text?.toDouble(),
				let doublesRating = alert.textFields?[2].text?.toDouble()
			else { return }
			
			if let playerIndex = playerIndex, var player = player {
				player.name = name
				player.singlesRating = singlesRating
				player.doublesRating = doublesRating
				self?.players[playerIndex] = player
			} else {
				self?.players.append(
					Player(
						playerId: UUID().uuidString,
						name: name,
						singlesRating: singlesRating,
						doublesRating: doublesRating
					)
				)
			}
			self?.players.save()
			self?.sortAndReload()
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: completionHandler))
		self.present(alert, animated: true)
	}
}
