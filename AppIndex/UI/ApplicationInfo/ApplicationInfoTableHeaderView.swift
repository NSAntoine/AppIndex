//
//  ApplicationInfoTableHeaderView.swift
//  AppIndex
//
//  Created by Serena on 27/03/2023.
//  

import UIKit
import CustomLaunchServicesBridge

class ApplicationInfoTableHeaderView: UIView {
	let app: Application
	
	var actionsButton: UIButton!
	
	init(app: Application) {
		self.app = app
		
		super.init(frame: .zero)
		setup()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func setup() {
		let iconImageView = UIImageView(image: app.iconImage(forFormat: 10))
		iconImageView.translatesAutoresizingMaskIntoConstraints = false
		iconImageView.contentMode = .scaleAspectFit
		addSubview(iconImageView)
		
		let nameLabel = UILabel()
		nameLabel.font = .boldSystemFont(ofSize: 20)
		nameLabel.text = app.name
		nameLabel.translatesAutoresizingMaskIntoConstraints = false
		nameLabel.numberOfLines = 0
		addSubview(nameLabel)
		
		let bundleIDLabel = UILabel()
		bundleIDLabel.text = app.bundleID
		bundleIDLabel.translatesAutoresizingMaskIntoConstraints = false
		bundleIDLabel.font = .subtitleFont
		bundleIDLabel.numberOfLines = 0
		bundleIDLabel.adjustsFontSizeToFitWidth = true
		bundleIDLabel.textColor = .secondaryLabel
		addSubview(bundleIDLabel)
		
		self.actionsButton = UIButton(type: .system)
		actionsButton.translatesAutoresizingMaskIntoConstraints = false
		actionsButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
		addSubview(actionsButton)
		
		NSLayoutConstraint.activate([
			actionsButton.topAnchor.constraint(equalTo: nameLabel.topAnchor),
			actionsButton.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor/*, constant: -16.7*/),
			actionsButton.widthAnchor.constraint(equalToConstant: 70),
			
			iconImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 15),
			iconImageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			iconImageView.widthAnchor.constraint(equalToConstant: iconImageView.image?.size.width ?? 0),
			iconImageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
			
//			nameLabel.centerYAnchor.constraint(equalTo: iconImageView.layoutMarginsGuide.topAnchor, constant: 6.5),
			nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 15),
			nameLabel.trailingAnchor.constraint(equalTo: actionsButton.leadingAnchor),
			nameLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			
			bundleIDLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
			bundleIDLabel.trailingAnchor.constraint(equalTo: actionsButton.leadingAnchor),
			bundleIDLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
			bundleIDLabel.bottomAnchor.constraint(equalTo: iconImageView.bottomAnchor)
		])
		
	}
	
	func makeGenericButton() -> UIButton {
		let button = UIButton(type: .system)
		button.backgroundColor = tintColor
		
		button.setTitleColor(.white, for: .normal)
		button.layer.cornerRadius = 15
		button.layer.cornerCurve = .continuous
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}
	
	@objc
	func openApp() {
		LSApplicationWorkspace.default().openApplication(withBundleID: app.bundleID)
	}
}
