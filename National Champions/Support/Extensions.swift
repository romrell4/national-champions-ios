//
//  Extensions.swift
//  National Champions
//
//  Created by Eric Romrell on 3/19/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

extension Collection {
    // Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index?) -> Element? {
		if let index = index {
			return indices.contains(index) ? self[index] : nil
		} else {
			return nil
		}
    }
}

extension String {
	func toDouble() -> Double? { Double(self) }
}

extension UITableView {
	func deselectSelectedRow() {
		if let indexPath = self.indexPathForSelectedRow {
			self.deselectRow(at: indexPath, animated: true)
		}
	}
}

extension UIViewController {
	func displayAlert(title: String, message: String? = nil, handler: ((UIAlertAction) -> Void)? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))
		present(alert, animated: true)
	}
}
