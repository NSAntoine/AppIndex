//
//  UIKitExtensions.swift
//  AppIndex
//
//  Created by Serena on 27/03/2023.
//  

import UIKit

extension UIFont {
//	static let subtitleFont: UIFont = UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
	static let subtitleFont: UIFont = UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: 13.4, weight: .regular))
}

extension UIViewController {
	func errorAlert(title: String, message: String?) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: .localized("Cancel"), style: .cancel))
		present(alert, animated: true)
	}
	
	func presentAlertWithSpinner(title: String, heightAnchor: CGFloat) -> UIAlertController {
		let alertController = UIAlertController(title: title,
												message: nil,
												preferredStyle: .alert)
		let spinner = UIActivityIndicatorView()
		spinner.translatesAutoresizingMaskIntoConstraints = false
		spinner.startAnimating()
		alertController.view.addSubview(spinner)
		
		NSLayoutConstraint.activate([
			alertController.view.heightAnchor.constraint(equalToConstant: heightAnchor),
			spinner.centerXAnchor.constraint(equalTo: alertController.view.centerXAnchor),
			spinner.bottomAnchor.constraint(equalTo: alertController.view.bottomAnchor, constant: -20),
		])
		present(alertController, animated: true)
		return alertController
	}
}
