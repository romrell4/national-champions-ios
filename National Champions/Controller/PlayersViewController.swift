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
	@IBOutlet private weak var filterTeamSwitch: UISwitch!
	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var spinner: UIActivityIndicatorView!
	
	private var allPlayers = Player.loadAll()
	private var displayedPlayers: [Player] {
		return allPlayers.filter {
			//Only filter if the switch is on
			!filterTeamSwitch.isOn || $0.onCurrentTeam
		}.sorted { (lhs, rhs) -> Bool in
			if self.sortControl.selectedSegmentIndex == 0 {
				return lhs.singlesRating > rhs.singlesRating
			} else {
				return lhs.doublesRating > rhs.doublesRating
			}
		}
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.tableView.tableFooterView = UIView()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		allPlayers = Player.loadAll()
		self.tableView.reloadData()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? PlayerMatchesViewController,
			let cell = sender as? UITableViewCell,
			let indexPath = tableView.indexPath(for: cell) {
			vc.player = displayedPlayers[indexPath.row]
		}
	}
	
	//MARK: UITableViewDelegate/DataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return displayedPlayers.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		if let cell = cell as? PlayerTableViewCell {
			cell.player = displayedPlayers[indexPath.row]
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
				let player = self.displayedPlayers[indexPath.row]
				
				//Find any matches this player played
				let matches = Match.loadAll().filter {
					($0.winners.map { $0.playerId } + $0.losers.map { $0.playerId }).contains(player.playerId)
				}
				if matches.count > 0 {
					self.displayAlert(title: "Error", message: "This player cannot be deleted, because this player has been involved in matches already saved.") { _ in
						self.tableView.reloadRows(at: [indexPath], with: .automatic)
					}
				} else {
					//Find the player in the unfiltered list and remove them
					if let index = self.allPlayers.firstIndex(of: player) {
						self.allPlayers.remove(at: index)
					}
					
					self.allPlayers.save()
					self.tableView.deleteRows(at: [indexPath], with: .automatic)
				}
			}
		])
	}
	
	//MARK: Actions
	
	@IBAction func addPlayer(_ sender: Any) {
		displayPlayerPopUp(title: "Add Player")
	}
	
	@IBAction func actionButtonTapped(_ sender: Any) {
		let actionSheet = UIAlertController(title: "What would you like to do with your data?", message: nil, preferredStyle: .actionSheet)
		actionSheet.addAction(UIAlertAction(title: "Import", style: .default, handler: { (_) in
			self.displayConfirmDialog(title: "Warning", message: "Are you sure you'd like to import data? This will delete all data currently saved on your device and replace it with the data from the server.") { (_) in
				
				self.spinner.startAnimating()
				// Uncomment out the next line to test with another import file
				// Player.loadFromUrl(url: "https://romrell4.github.io/national-champions-ios/test_players.json") {
				Player.loadFromUrl(url: "https://romrell4.github.io/national-champions-ios/players.json") {
					switch $0 {
					case .Success:
						//Load matches as well, after players have been downloaded
						// Uncomment out the next line to test with another import file
						// Match.loadFromUrl(url: "https://romrell4.github.io/national-champions-ios/test_matches.json") {
						Match.loadFromUrl(url: "https://romrell4.github.io/national-champions-ios/matches.json") {
							self.spinner.stopAnimating()
							switch $0 {
							case .Success:
								self.allPlayers = Player.loadAll()
								self.tableView.reloadData()
							case .Error(let message):
								self.displayAlert(title: "Error", message: message)
							}
						}
					case .Error(let message):
						self.spinner.stopAnimating()
						self.displayAlert(title: "Error", message: message)
					}
				}

			}
		}))
		actionSheet.addAction(UIAlertAction(title: "Export", style: .default, handler: { (_) in
			UIPasteboard.general.string = try? String(data: JSONEncoder().encode(self.allPlayers), encoding: .utf8)
			self.displayAlert(title: "Success", message: "The data has been copied to your clipboard. Feel free to paste it wherever.")
		}))
		actionSheet.addAction(UIAlertAction(title: "Delete All", style: .default, handler: { (_) in
			self.displayConfirmDialog(title: "Warning", message: "Are you sure you'd like to delete all data? This will remove all saved matches and players.") { (_) in
				
				self.allPlayers = []
				self.allPlayers.save()
				[Match]().save()
				self.tableView.reloadData()
			}
		}))
		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(actionSheet, animated: true)
	}
	
	@IBAction func reload(_ sender: Any? = nil) {
		tableView.reloadData()
	}
	
	//MARK: Private functions
	
	private func displayPlayerPopUp(title: String, playerIndex: Int? = nil, completionHandler: ((UIAlertAction) -> Void)? = nil) {
		let player = displayedPlayers[safe: playerIndex]
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
			$0.returnKeyType = .next
		}
		alert.addTextField {
			$0.placeholder = "On Current Team (y/n)"
			if let onCurrentTeam = player?.onCurrentTeam {
				$0.text = onCurrentTeam ? "y" : "n"
			}
			$0.returnKeyType = .done
		}
		alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
			guard
				let name = alert.textFields?[0].text,
				let singlesRating = alert.textFields?[1].text?.toDouble(),
				let doublesRating = alert.textFields?[2].text?.toDouble(),
				let onCurrentTeamStr = alert.textFields?[3].text
			else { return }
			
			let onCurrentTeam = onCurrentTeamStr.lowercased() == "y"
			
			if var player = player {
				player.name = name
				player.singlesRating = singlesRating
				player.doublesRating = doublesRating
				player.onCurrentTeam = onCurrentTeam
				
				//Find the player in the full, unfiltered, list, and updated it
				if let index = self?.allPlayers.firstIndex(of: player) {
					self?.allPlayers[index] = player
				}
			} else {
				self?.allPlayers.append(
					Player(
						playerId: UUID().uuidString,
						name: name,
						singlesRating: singlesRating,
						doublesRating: doublesRating,
						onCurrentTeam: onCurrentTeam
					)
				)
			}
			self?.allPlayers.save()
			self?.tableView.reloadData()
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: completionHandler))
		self.present(alert, animated: true)
	}
}
