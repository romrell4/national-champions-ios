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

enum Result<T> {
	case Success(_ list: [T])
	case Error(_ message: String?)
}

extension Optional where Wrapped == URL {
	func get<T>(completionHandler: @escaping (Result<T>) -> Void, deserializer: @escaping ([[String: Any]]) throws -> [T]) -> Void {
		if let url = self {
			URLSession.shared.dataTask(with: url) { data, _, _ in
				DispatchQueue.main.async {
					do {
						if let data = data, let array = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
							do {
								completionHandler(.Success(try deserializer(array)))
							}
						} else {
							completionHandler(.Error("Unable to process data from \(url)"))
						}
					} catch {
						switch error as? MyError {
						case .unableToImport(let message):
							completionHandler(.Error(message))
						default:
							completionHandler(.Error("Error processing data from \(url): \(error)"))
						}
					}
				}
			}.resume()
		} else {
			completionHandler(.Error("Unable to connect to that URL"))
		}
	}
}
