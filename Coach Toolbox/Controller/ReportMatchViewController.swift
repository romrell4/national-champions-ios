//
//  ReportMatchViewController.swift
//  Coach Toolbox
//
//  Created by Eric Romrell on 3/18/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

class ReportMatchViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
	
	@IBOutlet private weak var winnerTextField: UITextField!
	@IBOutlet private weak var loserTextField: UITextField!
	@IBOutlet private weak var winnerSet1: UITextField!
	@IBOutlet private weak var loserSet1: UITextField!
	@IBOutlet private weak var winnerSet2: UITextField!
	@IBOutlet private weak var loserSet2: UITextField!
	@IBOutlet private weak var winnerSet3: UITextField!
	@IBOutlet private weak var loserSet3: UITextField!
	
	private var playerTextFields: [UITextField] {
		[winnerTextField, loserTextField]
	}
	private var scoreTextFields: [UITextField] {
		[winnerSet1, loserSet1, winnerSet2, loserSet2, winnerSet3, loserSet3]
	}
	private var allTextFields: [UITextField] {
		playerTextFields + scoreTextFields
	}
	
	private var players = [Player]()
	private var winner: Player? {
		didSet {
			winnerTextField.text = winner?.name
		}
	}
	private var loser: Player? {
		didSet {
			loserTextField.text = loser?.name
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		playerTextFields.forEach {
			$0.inputView = UIPickerView(delegate: self)
		}
		allTextFields.forEach {
			$0.delegate = self
		}
		
		scoreTextFields.forEach {
			$0.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		players = Player.loadAll().sorted { (lhs, rhs) -> Bool in
			lhs.name < rhs.name
		}
	}
	
	//UIPickerView delegate
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { players.count }
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		players[row].name
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		if !players.isEmpty {
			if winnerTextField.isFirstResponder {
				winner = players[row]
			} else if loserTextField.isFirstResponder {
				loser = players[row]
			}
		}
	}
	
	//UITextField delegate
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		if textField.text?.isEmpty != false {
			if textField == winnerTextField {
				winner = players[0]
			} else if textField == loserTextField {
				loser = players[0]
			}
		}
	}

	func textFieldDidEndEditing(_ textField: UITextField) {
		self.navigationItem.rightBarButtonItem?.isEnabled = getMatch() != nil
	}
	
	//Listeners
	
	@objc private func textFieldDidChange(textField: UITextField) {
		if let index = scoreTextFields.firstIndex(of: textField) {
			if let nextTextField = scoreTextFields[safe: index + 1] {
				nextTextField.becomeFirstResponder()
			} else {
				textField.resignFirstResponder()
			}
		}
	}
	
	@IBAction func viewTapped(_ sender: Any) {
		allTextFields.forEach {
			$0.resignFirstResponder()
		}
	}
	
	@IBAction func saveMatch(_ sender: Any) {
		if let match = getMatch() {
			let save = {
				match.save()
				//TODO: Reset UI
			}
			
			if !match.wasCompleted {
				let alert = UIAlertController(title: "Warning", message: "This match is incomplete. Are you sure you'd like to record it anyway?", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "Save", style: .default) { (_) in
					save()
				})
				alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
				present(alert, animated: true)
			} else {
				save()
			}
			
			displayAlert(title: "Success", message: "Match was saved successfully")
		} else {
			displayAlert(title: "Error", message: "An error occurred while trying to save your match. Please make sure all fields are entered properly.")
		}
	}
	
	private func getMatch() -> Match? {
		if let winnerId = self.winner?.playerId, let loserId = self.loser?.playerId, winnerId != loserId {
			return Match(
				matchDate: Date(),
				winnerId: winnerId,
				loserId: loserId,
				winnerSet1Score: self.winnerSet1.toInt(),
				loserSet1Score: self.loserSet1.toInt(),
				winnerSet2Score: self.winnerSet2.toInt(),
				loserSet2Score: self.loserSet2.toInt(),
				winnerSet3Score: self.winnerSet3.toInt(),
				loserSet3Score: self.loserSet3.toInt()
			)
		}
		return nil
	}
}

private extension UITextField {
	func toInt() -> Int? {
		if let text = self.text {
			return Int(text)
		}
		return nil
	}
}

private extension UIPickerView {
	convenience init(delegate: UIPickerViewDelegate & UIPickerViewDataSource) {
		self.init()
		self.delegate = delegate
		self.dataSource = dataSource
	}
}
