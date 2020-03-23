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
	private var winner: Player?
	private var loser: Player?

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let picker = UIPickerView()
		picker.delegate = self
		picker.dataSource = self
		playerTextFields.forEach {
			$0.inputView = picker
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
				winnerTextField.text = winner?.name
			} else {
				loser = players[row]
				loserTextField.text = loser?.name
			}

		}
	}
	
	//UITextField delegate
	
	private let KEYBOARD_OFFSET: CGFloat = 150
	private let OFFSET_ANIMATION_DURATION: TimeInterval = 0.3
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		UIView.animate(withDuration: OFFSET_ANIMATION_DURATION) {
			self.view.frame = CGRect(
				x: self.view.frame.origin.x,
				y: self.view.frame.origin.y - self.KEYBOARD_OFFSET,
				width: self.view.frame.size.width,
				height: self.view.frame.size.height
			)
		}
	}

	func textFieldDidEndEditing(_ textField: UITextField) {
		UIView.animate(withDuration: OFFSET_ANIMATION_DURATION) {
			self.view.frame = CGRect(
				x: self.view.frame.origin.x,
				y: self.view.frame.origin.y + self.KEYBOARD_OFFSET,
				width: self.view.frame.size.width,
				height: self.view.frame.size.height
			)
		}
		self.navigationController?.navigationItem.rightBarButtonItem?.isEnabled = getMatch() != nil
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
			if match.wasCompleted {
				match.save()
			} else {
				
			}
			
			displayAlert(title: "Success", message: "Match was saved successfully")
		} else {
			displayAlert(title: "Error", message: "An error occurred while trying to save your match. Please make sure all fields are entered properly.")
		}
	}
	
	private func getMatch() -> Match? {
		if let winnerId = self.winner?.playerId, let loserId = self.loser?.playerId {
			
			return Match(
				winnerId: winnerId,
				loserId: loserId,
				winnerSet1Score: self.winnerSet1.toInt(),
				loserSet1Score: self.loserSet1.toInt(),
				winnerSet2Score: self.winnerSet2.toInt(),
				loserSet2Score: self.loserSet2.toInt(),
				winnerSet3Score: self.winnerSet3.toInt(),
				loserSet3Score: self.loserSet3.toInt()
			)
		} else {
			return nil
		}
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
