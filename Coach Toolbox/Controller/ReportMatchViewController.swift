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
	}
	
	override func viewWillAppear(_ animated: Bool) {
		players = Player.loadAll().sorted { (lhs, rhs) -> Bool in
			lhs.name < rhs.name
		}
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { players.count }
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		players[row].name
	}
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		UIView.animate(withDuration: 0.3, animations: {
			self.view.frame = CGRect(x:self.view.frame.origin.x, y:self.view.frame.origin.y - 200, width:self.view.frame.size.width, height:self.view.frame.size.height);

		})
	}

	func textFieldDidEndEditing(_ textField: UITextField) {
		UIView.animate(withDuration: 0.3, animations: {
			self.view.frame = CGRect(x:self.view.frame.origin.x, y:self.view.frame.origin.y + 200, width:self.view.frame.size.width, height:self.view.frame.size.height);

		})
	}
	
	@IBAction func viewTapped(_ sender: Any) {
		allTextFields.forEach {
			$0.resignFirstResponder()
		}
	}
}
