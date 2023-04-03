//
//  ApplicationContextMenuPreviewView.swift
//  AppIndex
//
//  Created by Serena on 30/03/2023.
//  

import UIKit

/// The preview for an application in a context menu.
class ApplicationContextMenuPreview: UIViewController {
	let app: Application
	
	init(app: Application) {
		self.app = app
		super.init(nibName: nil, bundle: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = .systemGroupedBackground
		let imageView = UIImageView(image: app.iconImage(forFormat: 10))
		imageView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(imageView)
		
		let titleLabel = UILabel()
		titleLabel.font = .preferredFont(forTextStyle: .headline)
		titleLabel.text = app.name
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(titleLabel)
		
		let subtitleLabel = UILabel()
		subtitleLabel.numberOfLines = 0
		subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
		subtitleLabel.font = .subtitleFont
		subtitleLabel.text = app.bundleID
		subtitleLabel.textColor = .secondaryLabel
		view.addSubview(subtitleLabel)
		
		let chevronImage = UIImage(systemName: "chevron.right")?
			.withConfiguration(UIImage.SymbolConfiguration(pointSize: 15))
			.withTintColor(.systemGray, renderingMode: .alwaysOriginal)
		
		let chevron = UIImageView(image: chevronImage)
		chevron.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(chevron)
		
		NSLayoutConstraint.activate([
			imageView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
			imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			
			chevron.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
			chevron.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
			
			titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12.3),
			titleLabel.topAnchor.constraint(equalTo: imageView.layoutMarginsGuide.topAnchor),
			
			subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
			subtitleLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor),
			subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
