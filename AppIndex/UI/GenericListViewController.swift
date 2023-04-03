//
//  GenericListViewController.swift
//  AppIndex
//
//  Created by Serena on 01/04/2023.
//  

import UIKit

class GenericListViewController<Section: Hashable>: UIViewController, UITableViewDelegate {
	
	/*let items: [CellItem]
	
	init(items: [CellItem]) {
		self.items = items
		super.init(nibName: nil, bundle: nil)
	}
	 */
	
	init(addItems: @escaping (GenericListViewController) -> Void) {
		self.addItemsCallback = addItems
		
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	typealias DataSource = UITableViewDiffableDataSource<Section, CellItem>
	var tableView: UITableView!
	lazy var dataSource: DataSource = makeDataSource()
	
	var addItemsCallback: ((GenericListViewController) -> Void)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.tableView = UITableView(frame: .zero, style: .insetGrouped)
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.delegate = self
		view.addSubview(tableView)
		tableView.constraintCompletely(to: view)
		
		addItemsCallback(self)
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
	
	func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		return false
//		return dataSource.itemIdentifier(for: indexPath)
	}
	
	func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
			return UIMenu(children: item.contextMenuProvider.actions(forItem: item))
		}
	}
}
