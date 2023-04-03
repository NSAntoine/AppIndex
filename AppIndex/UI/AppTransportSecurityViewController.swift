//
//  AppTransportSecurityViewController.swift
//  AppIndex
//
//  Created by Serena on 01/04/2023.
//  

import UIKit

class AppTransportSecurityViewController: UIViewController {
	typealias DataSource = UITableViewDiffableDataSource<AppTransportSecurity, CellItem>
	lazy var dataSource: DataSource = makeDataSource()
	var tableView: UITableView!
	
	let securityItems: [AppTransportSecurity]
	
	init(securityItems: [AppTransportSecurity]) {
		self.securityItems = securityItems
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = .localized("Transport Security Exceptions")
		
		self.tableView = UITableView(frame: .zero, style: .insetGrouped)
		tableView.delegate = self
		tableView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(tableView)
		tableView.constraintCompletely(to: view)
		
		var snapshot = NSDiffableDataSourceSnapshot<AppTransportSecurity, CellItem>()
		snapshot.appendSections(securityItems)
		
		for item in securityItems {
			snapshot.appendItems(cellItems(for: item), toSection: item)
		}
		
		dataSource.apply(snapshot)
		
	}
	
	func cellItems(for security: AppTransportSecurity) -> [CellItem] {
		var items: [CellItem] = [
			CellItem(localizedPrimaryText: "Domain", secondaryText: security.domain)
		]
		
		if let includesSubdomains = security.includesSubdomains {
			items.append(CellItem(localizedPrimaryText: "Includes Subdomains", secondaryText: includesSubdomains.yesOrNoDescription))
		}
		
		if let allowInsecureHTTPLoads = security.allowInsecureHTTPLoads {
			items.append(CellItem(localizedPrimaryText: "Allows Insecure HTTP Loads", secondaryText: allowInsecureHTTPLoads.yesOrNoDescription))
		}
		
		return items
	}
	
	func makeDataSource() -> DataSource {
		// use content configurations on iOS 14+
		if #available(iOS 14, *) {
			return DataSource(tableView: tableView) { tableView, indexPath, itemIdentifier in
				let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
				if let primaryText = itemIdentifier.primaryText {
					var conf = cell.defaultContentConfiguration()
					conf.text = primaryText
					conf.secondaryText = itemIdentifier.secondaryText
					
					if itemIdentifier.isPath {
						conf.secondaryTextProperties.lineBreakMode = .byTruncatingMiddle
						conf.secondaryTextProperties.numberOfLines = 3
					}
					
					cell.contentConfiguration = conf
				}
				
				itemIdentifier.provider?(cell)
				return cell
			}
		}
		
		return DataSource(tableView: tableView) { tableView, indexPath, itemIdentifier in
			let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
			cell.textLabel?.text = itemIdentifier.primaryText
			cell.detailTextLabel?.text = itemIdentifier.secondaryText
			itemIdentifier.provider?(cell)
			return cell
		}
	}
}

extension AppTransportSecurityViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
			return UIMenu(children: item.contextMenuProvider.actions(forItem: item))
		}
	}
	
	func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		return dataSource.itemIdentifier(for: indexPath)!.isPath
	}
}
