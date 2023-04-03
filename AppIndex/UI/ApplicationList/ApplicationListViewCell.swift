//
//  ApplicationListViewCell.swift
//  AppIndex
//
//  Created by Serena on 27/03/2023.
//  

import UIKit

class ApplicationListViewCell: UICollectionViewCell {
	static let reuseIdentifier = "ApplicationListViewCell"
	
	let iconImageView = UIImageView()
	let nameLabel = UILabel()
	let subtitleLabel = UILabel()
	
	static let cellBackgroundColor = UIColor { traitCollection in
		switch traitCollection.userInterfaceStyle {
		case .dark:
			return .tertiarySystemBackground
		default:
			return .systemBackground
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		layer.cornerCurve = .circular
		layer.cornerRadius = 10
		backgroundColor = Self.cellBackgroundColor
		
		iconImageView.translatesAutoresizingMaskIntoConstraints = false
		iconImageView.layer.cornerRadius = 10
		iconImageView.layer.masksToBounds = true
		contentView.addSubview(iconImageView)
		
		nameLabel.translatesAutoresizingMaskIntoConstraints = false
		nameLabel.font = .preferredFont(forTextStyle: .title3)
		contentView.addSubview(nameLabel)
		
		subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
		subtitleLabel.font = .subtitleFont
		subtitleLabel.numberOfLines = 0
		subtitleLabel.textColor = .secondaryLabel
		subtitleLabel.adjustsFontSizeToFitWidth = true
		contentView.addSubview(subtitleLabel)
		
		NSLayoutConstraint.activate([
			iconImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
			iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
			iconImageView.heightAnchor.constraint(equalTo: contentView.layoutMarginsGuide.heightAnchor),
			iconImageView.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.heightAnchor),
			
			nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 7.384),
			nameLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
			nameLabel.centerYAnchor.constraint(equalTo: contentView.layoutMarginsGuide.centerYAnchor, constant: -10),
			
			subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
			subtitleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
			subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
			subtitleLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
		])
		
		/*
		nameLabel.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(nameLabel)
		
		NSLayoutConstraint.activate([
			nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
			nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
		])
		*/
		
		
//		layer.borderColor = UIColor.systemRed.cgColor
//		layer.borderWidth = 1.0
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	func setup(with application: Application) {
		// rawValue = 10
		iconImageView.image = application.iconImage(forFormat: 10)
		nameLabel.text = application.name
		subtitleLabel.text = application.bundleID
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		iconImageView.image = nil
		nameLabel.text = nil
	}
	
	override var reuseIdentifier: String? {
		Self.reuseIdentifier
	}
}
