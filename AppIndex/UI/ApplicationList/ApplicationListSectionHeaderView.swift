//
//  ApplicationListSectionHeaderView.swift
//  AppIndex
//
//  Created by Serena on 30/03/2023.
//  

import UIKit

class ApplicationListSectionHeaderView: UICollectionReusableView {
	static let reuseIdentifier = "ApplicationListSectionHeaderView"
	
	let primaryLabel = UILabel()
	let countLabel = UILabel() // "x Applications" label, where x is the amount of applications in the section
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		primaryLabel.translatesAutoresizingMaskIntoConstraints = false
		primaryLabel.font = .preferredFont(forTextStyle: .title2)
		addSubview(primaryLabel)
		
		countLabel.translatesAutoresizingMaskIntoConstraints = false
		countLabel.font = .systemFont(ofSize: 10.4)
		countLabel.textColor = .secondaryLabel
		addSubview(countLabel)
		
		NSLayoutConstraint.activate([
			primaryLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			primaryLabel.topAnchor.constraint(equalTo: topAnchor),
			
			countLabel.leadingAnchor.constraint(equalTo: primaryLabel.leadingAnchor),
			countLabel.topAnchor.constraint(equalTo: primaryLabel.bottomAnchor, constant: -5),
			countLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
		
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func setup(with section: ApplicationCollection.Section, count: Int) {
		countLabel.text = .localizedStringWithFormat("%d Applications", count)
		primaryLabel.text = section.listConfiguration.name
//		switch section {
//		case .none:
//			break // not even supposed to be here
//		case .type(let appType):
//			primaryLabel.text = appType?.headerDescription ?? .localized("Unknown Application Type")
//		case .date(let date):
//			primaryLabel.text = date.description
//		case .genre(let genre):
//			primaryLabel.text = genre ?? .localized("No Genre")
//		}
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		primaryLabel.text = nil
		countLabel.text = nil
	}
	
	override var reuseIdentifier: String? {
		Self.reuseIdentifier
	}
}
