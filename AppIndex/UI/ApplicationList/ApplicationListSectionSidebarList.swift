//
//  ApplicationListSectionSidebarList.swift
//  AppIndex
//
//  Created by Serena on 31/03/2023.
//  

import UIKit

/// A View Controller showing a list of sections that can be selected on the sidebar
class ApplicationListSectionSidebarList: UIViewController {
	var tableView: UITableView!
	
	typealias Item = ApplicationListViewController.Section
	typealias DataSource = UITableViewDiffableDataSource<GenericDiffableDataSourceSection, Item>
	typealias Snapshot = NSDiffableDataSourceSnapshot<GenericDiffableDataSourceSection, Item>
	
	var dataSource: DataSource!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		print("here")
		self.tableView = UITableView(frame: .zero, style: .insetGrouped)
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.delegate = self
		view.addSubview(tableView)
		tableView.constraintCompletely(to: view)
		
		if #available(iOS 14, *) {
			dataSource = DataSource(tableView: tableView) { tableView, indexPath, itemIdentifier in
				let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
				var conf = cell.defaultContentConfiguration()
				let listConf = itemIdentifier.listConfiguration
				conf.text = listConf.name
				conf.image = listConf.image
				cell.contentConfiguration = conf
				return cell
			}
		} else {
			dataSource = DataSource(tableView: tableView) { tableView, indexPath, itemIdentifier in
				let cell = UITableViewCell()
				let listConf = itemIdentifier.listConfiguration
				cell.textLabel?.text = listConf.name
				cell.imageView?.image = listConf.image
				return cell
			}
		}
		
		title = .localized("Applications")
		navigationController?.navigationBar.prefersLargeTitles = true
		let listVC = (splitViewController?.viewControllers[1] as? UINavigationController)?.visibleViewController as? ApplicationListViewController
		listVC?.setSidebarData()
//
//		var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
//		snapshot.appendSections([.main])
//		snapshot.appendItems([.none])
//		dataSource.apply(snapshot)
	}
}

extension ApplicationListSectionSidebarList: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let section = dataSource.itemIdentifier(for: indexPath) else { return }
		let listVC = splitViewController?.viewControllers[1] as? UINavigationController
		listVC?.popToRootViewController(animated: true)
		
		let visible = listVC?.visibleViewController as? ApplicationListViewController
		guard let sectionIndx = visible?.dataSource.snapshot().indexOfSection(section) else { return }
		visible?.collectionView.scrollToItem(at: IndexPath(row: 0, section: sectionIndx), at: [.centeredHorizontally, .top], animated: true)
	}
}
