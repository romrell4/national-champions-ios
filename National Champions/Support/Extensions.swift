//
//  Extensions.swift
//  National Champions
//
//  Created by Eric Romrell on 3/19/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

extension Bundle {
	var fullVersionNumber: String {
		"Version \(versionNumber) (\(buildNumber))"
	}
	
    private var versionNumber: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    private var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}

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

extension UINavigationItem {
	func setTitle(_ title: String, subtitle: String) {
		let one = UILabel()
		one.text = title
		one.font = UIFont.systemFont(ofSize: 17)
		one.textColor = .white
		one.sizeToFit()

		let two = UILabel()
		two.text = subtitle
		two.font = UIFont.systemFont(ofSize: 12)
		two.textAlignment = .center
		two.textColor = .white
		two.sizeToFit()

		let stackView = UIStackView(arrangedSubviews: [one, two])
		stackView.distribution = .equalCentering
		stackView.axis = .vertical
		stackView.alignment = .center

		let width = max(one.frame.size.width, two.frame.size.width)
		stackView.frame = CGRect(x: 0, y: 0, width: width, height: 35)
		
		self.titleView = stackView
	}
}

extension UIViewController {
	func displayAlert(title: String, message: String? = nil, handler: ((UIAlertAction) -> Void)? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))
		present(alert, animated: true)
	}
	
	func displayConfirmDialog(title: String, message: String? = nil, confirmHandler: ((UIAlertAction) -> Void)? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: confirmHandler))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(alert, animated: true)
	}
}
