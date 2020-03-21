//
//  ReportMatchViewController.swift
//  Coach Toolbox
//
//  Created by Eric Romrell on 3/18/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

class ReportMatchViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
	
	@IBOutlet private weak var winnerTextField: UITextField!
	@IBOutlet private weak var loserTextField: UITextField!
	
	private let players = Player.loadAll()

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let picker = UIPickerView()
		picker.delegate = self
		picker.dataSource = self
		[winnerTextField, loserTextField].forEach {
			$0?.inputView = picker
		}
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { players.count }
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		players[row].name
	}
	
	@IBAction func viewTapped(_ sender: Any) {
		winnerTextField.resignFirstResponder()
		loserTextField.resignFirstResponder()
	}
}
