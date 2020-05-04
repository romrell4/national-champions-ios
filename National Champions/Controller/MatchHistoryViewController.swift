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
	@IBOutlet private weak var spinner: UIActivityIndicatorView!
	
	private var matches = Match.loadAll().sorted { (lhs, rhs) -> Bool in
		return lhs.matchDate > rhs.matchDate
	} {
		didSet {
			self.tableView.reloadData()
		}
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
			cell.setMatch(matches[indexPath.row])
		}
		return cell
	}
	
	//MARK: Listeners
	
	@IBAction func importTapped(_ sender: Any) {
		let alert = UIAlertController(title: "Import Matches", message: "Are you sure you'd like to import matches? This will add these new matches to the matches you already have tracked in your system.", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Import", style: .default, handler: { (_) in
			self.spinner.startAnimating()
			// Uncomment out the next line to test with another import file
			// Match.loadFromUrl(url: "https://romrell4.github.io/national-champions-ios/test_matches.json") {
			Match.loadFromUrl(url: "https://romrell4.github.io/national-champions-ios/matches.json") {
				self.spinner.stopAnimating()
				switch $0 {
				case .Success(let list):
					self.matches = list.sorted { (lhs, rhs) -> Bool in
						return lhs.matchDate > rhs.matchDate
					}
				case .Error(let message):
					self.displayAlert(title: "Error", message: message)
				}
			}
		}))
		alert.addAction(UIAlertAction(title: "Export", style: .default, handler: { (_) in
			UIPasteboard.general.string = try? String(data: JSONEncoder().encode(self.matches), encoding: .utf8)
			self.displayAlert(title: "Success", message: "The data has been copied to your clipboard. Feel free to paste it wherever.")
			//TODO: CSV format?
		}))
		alert.addAction(UIAlertAction(title: "Delete All", style: .default, handler: { (_) in
			self.matches = []
			self.matches.save()
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(alert, animated: true)
	}
}
