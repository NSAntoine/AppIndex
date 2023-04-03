//
//  ApplicationListViewController.swift
//  AppIndex
//
//  Created by Serena on 27/03/2023.
//  

import UIKit

class ApplicationListViewController: UIViewController {
	
	typealias Section = ApplicationCollection.Section
	typealias DataSource = UICollectionViewDiffableDataSource<Section, Application>
	
	@available(iOS 14, *)
	typealias CellRegistration = UICollectionView.CellRegistration<ApplicationListViewCell, Application>
	@available(iOS 14, *)
	typealias SupplementaryRegistration = UICollectionView.SupplementaryRegistration<ApplicationListSectionHeaderView>
	
	var collectionView: UICollectionView!
	var dataSource: DataSource!
	
	lazy var allItemsSnapshot = makeSnapshot(for: appCollections(withSortMode: sortMode)) {
		didSet {
			setSidebarData()
		}
	}
	
	var sortMode: SortMode = .preferredMode() {
		willSet {
			UserDefaults.standard.set(newValue.rawValue, forKey: "PreferredSortMode")
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if UIDevice.current.userInterfaceIdiom != .pad {
			title = .localized("Applications")
		} else {
			navigationController?.navigationBar.prefersLargeTitles = false
		}
		
		navigationController?.navigationBar.prefersLargeTitles = true
		
		let searchController = UISearchController()
		searchController.searchBar.delegate = self
		navigationItem.searchController = searchController
		navigationItem.hidesSearchBarWhenScrolling = false
		
		collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout(mode: .vertical))
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		collectionView.backgroundColor = .secondarySystemBackground
		collectionView.delegate = self
		view.addSubview(collectionView)
		
		collectionView.constraintCompletely(to: view)
		
		if #available(iOS 14, *) {
			let cellRegistration = CellRegistration { cell, indexPath, itemIdentifier in
				cell.setup(with: itemIdentifier)
			}
			
			dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
				return collectionView.dequeueConfiguredReusableCell(using: cellRegistration,
																	for: indexPath,
																	item: itemIdentifier)
			}
			
			let supplementaryRegistration = SupplementaryRegistration(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
				let snapshot = self.dataSource.snapshot()
				let section = snapshot.sectionIdentifiers[indexPath.section]
				let amountOfItemsInThisSection = snapshot.numberOfItems(inSection: section)
				supplementaryView.setup(with: section, count: amountOfItemsInThisSection)
			}
			
			dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
				return collectionView.dequeueConfiguredReusableSupplementary(using: supplementaryRegistration, for: indexPath)
			}
		} else {
			dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ApplicationListViewCell.reuseIdentifier,
															  for: indexPath) as! ApplicationListViewCell
				cell.setup(with: itemIdentifier)
				return cell
			}
			
			dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
				let suppl = collectionView.dequeueReusableSupplementaryView(
					ofKind: kind,
					withReuseIdentifier: ApplicationListSectionHeaderView.reuseIdentifier,
					for: indexPath) as! ApplicationListSectionHeaderView
				let snapshot = self.dataSource.snapshot()
				let section = snapshot.sectionIdentifiers[indexPath.section]
				let amountOfItemsInThisSection = snapshot.numberOfItems(inSection: section)
				suppl.setup(with: section, count: amountOfItemsInThisSection)
				return suppl
			}
			
			collectionView.register(ApplicationListViewCell.self, forCellWithReuseIdentifier: ApplicationListViewCell.reuseIdentifier)
			collectionView.register(ApplicationListSectionHeaderView.self,
									forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
									withReuseIdentifier: ApplicationListSectionHeaderView.reuseIdentifier)
		}
		
		collectionView.dataSource = dataSource
		dataSource.apply(allItemsSnapshot)
		setRightNavigationBarItem()
	}
	
	// add sections to the sidebar
	func setSidebarData() {
		if UIDevice.current.userInterfaceIdiom == .pad {
			let sidebarVC = (splitViewController?.viewControllers[0] as? UINavigationController)?.visibleViewController as? ApplicationListSectionSidebarList
			guard let sidebarVC else { return }
			var snapshot = ApplicationListSectionSidebarList.Snapshot()
			snapshot.appendSections([.main])
			snapshot.appendItems(allItemsSnapshot.sectionIdentifiers)
			sidebarVC.dataSource.apply(snapshot)
		}
	}
}

extension ApplicationListViewController {
	// MARK: - Navigation Bar
	func setRightNavigationBarItem() {
		if #available(iOS 14, *) {
			let sortModeActions = SortMode.allCases.map { [self] mode in
				return UIAction(title: mode.description, state: sortMode == mode ? .on : .off) { [self] _ in
					changeToSortMode(sortMode: mode)
				}
			}
			
			let backupsAction = UIAction(title: .localized("Backups"), image: UIImage(systemName: "cloud")) { [self] _ in
				present(UINavigationController(rootViewController: BackupsListViewController()), animated: true)
			}
			
			let sortbyMenu = UIMenu(title: .localized("Sort By..."), children: sortModeActions)
			navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"),
																menu: UIMenu(children: [sortbyMenu, backupsAction]))
		}
	}
	
	func changeToSortMode(sortMode mode: SortMode) {
		sortMode = mode
		allItemsSnapshot = makeSnapshot(for: appCollections(withSortMode: sortMode))
		dataSource.apply(allItemsSnapshot)
		setRightNavigationBarItem()
	}
}

extension ApplicationListViewController: UICollectionViewDelegate {
	// MARK: - UICollectionView stuff
	func makeSnapshot(for appCollection: [ApplicationCollection]) -> NSDiffableDataSourceSnapshot<Section, Application> {
		var snapshot = NSDiffableDataSourceSnapshot<Section, Application>()
		for collection in appCollection {
			snapshot.appendSections([collection.section])
			snapshot.appendItems(collection.apps, toSection: collection.section)
		}
		return snapshot
	}
	
	/// What way to sort the collection view
	enum LayoutMode {
		case horizontal
		case vertical
	}
	
	/// How to sort the applications
	enum SortMode: String, Hashable, CaseIterable, CustomStringConvertible {
		static func preferredMode() -> SortMode {
			guard let value = UserDefaults.standard.string(forKey: "PreferredSortMode"), let mode = SortMode(rawValue: value) else {
				return .none
			}
			return mode
		}
		
		case alphabetically
		case type
		case genre
		case vendor
		case none
//		case dateInstalled /* TODO: FIX SORTING HERE ASAP! */
		
		var description: String {
			switch self {
			case .alphabetically:
				return .localized("Alphabetical Order")
			case .type:
				return .localized("Type")
			case .genre:
				return .localized("Genre")
			case .vendor:
				return .localized("Vendor")
			case .none:
				return .localized("None")
//			case .dateInstalled:
//				return .localized("Date Installed")
			}
		}
	}
	
	func appCollections(withSortMode sortMode: SortMode) -> [ApplicationCollection] {
		switch sortMode {
		case .none:
			return [ApplicationCollection(apps: Application.all, section: .none)]
		case .type:
			// not using a dictionary bc i need this to be sorted
			var systemApps: [Application] = []
			var userApps: [Application] = []
			var unknownTypes: [Application] = []
			
			for app in Application.all {
				switch app.type {
				case .system:
					systemApps.append(app)
				case .user:
					userApps.append(app)
				case nil:
					unknownTypes.append(app)
				}
			}
			
			var collections = [
				ApplicationCollection(apps: userApps, section: .type(.user)),
				ApplicationCollection(apps: systemApps, section: .type(.system))
			]
			
			if !unknownTypes.isEmpty {
				collections.append(ApplicationCollection(apps: unknownTypes, section: .type(nil)))
			}
			
			return collections
		case .alphabetically:
			let apps = Application.all.sorted { app1, app2 in
				app1.name < app2.name
			}
			return [ApplicationCollection(apps: apps, section: .none)]
		case .genre: // MARK: - Duplicated code ahead between multiple cases, to fix...
			var genresAndApplications: [String: [Application]] = [:]
			var noGenreApps: [Application] = [] // system apps don't have genres iirc
			
			for app in Application.all {
				if let genre = app.proxy.genre {
					if var existing = genresAndApplications[genre] {
						existing.append(app)
						genresAndApplications[genre] = existing
					} else {
						genresAndApplications[genre] = [app]
					}
				} else {
					noGenreApps.append(app)
				}
			}
			
			return genresAndApplications.map { (genre, apps) in
				return ApplicationCollection(apps: apps, section: .genre(genre))
			} + [ApplicationCollection(apps: noGenreApps, section: .genre(nil))]
		case .vendor:
			var vendorsAndApplications: [String: [Application]] = [:]
			var unknownVendorApps: [Application] = []
			
			for app in Application.all {
				if let genre = app.proxy.vendorName {
					if var existing = vendorsAndApplications[genre] {
						existing.append(app)
						vendorsAndApplications[genre] = existing
					} else {
						vendorsAndApplications[genre] = [app]
					}
				} else {
					unknownVendorApps.append(app)
				}
			}
			
			return vendorsAndApplications.map { (vendor, apps) in
				return ApplicationCollection(apps: apps, section: .vendor(vendor))
			} + [ApplicationCollection(apps: unknownVendorApps, section: .vendor(nil))]
			/*
		case .dateInstalled:
			let calender = Calendar.current
			let theComponentsWeWant: Set<Calendar.Component> = [.year, .month]
			var dict: [ApplicationInstallDate: [Application]] = [:]
			for app in Application.all {
				guard let installDate = ApplicationInstallDate(
					components: calender.dateComponents(theComponentsWeWant, from: app.proxy.registeredDate)
				) else { continue }
				
				if var existing = dict[installDate] {
					existing.append(app)
					dict[installDate] = existing
				} else {
					dict[installDate] = [app]
				}
			}
			
			return dict.sorted { (k, k2) in
				return k.key < k2.key
			}
			.map { (date, apps) in
				return ApplicationCollection(apps: apps, section: .date(date))
			}
			 */
		}
	}
	
	func makeLayout(mode: LayoutMode) -> UICollectionViewCompositionalLayout {
		let group: NSCollectionLayoutGroup
		let spacing: CGFloat = 10
		
		switch mode {
		case .horizontal:
			let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
												  heightDimension: .fractionalHeight(1.0))
			
			let item = NSCollectionLayoutItem(layoutSize: itemSize)
			
			let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
												   heightDimension: .fractionalWidth(1/1.8))
			
			group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
			group.interItemSpacing = .fixed(spacing)
		case .vertical:
			let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
												  heightDimension: .fractionalHeight(1.0))
			let item = NSCollectionLayoutItem(layoutSize: itemSize)
			let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
												   heightDimension: .absolute(60))
			
			group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
			let spacing = CGFloat(10)
			group.interItemSpacing = .fixed(spacing)
			
//			let section = NSCollectionLayoutSection(group: group)
//			section.interGroupSpacing = spacing
//			section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: spacing, bottom: 0, trailing: spacing)
		}
		
		let titleHeaderSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1.0),
			heightDimension: .absolute(55)
		)
		
		let titleSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
			layoutSize: titleHeaderSize,
			elementKind: UICollectionView.elementKindSectionHeader,
			alignment: /*layoutMode == .horizantal ? .top : .topLeading*/.topLeading
		)
		
		let sectionContentInsets = NSDirectionalEdgeInsets(top: 0,
														   leading: spacing,
														   bottom: 8,
														   trailing: spacing)
		
		return UICollectionViewCompositionalLayout { sect, env in
			let section = NSCollectionLayoutSection(group: group)
			section.interGroupSpacing = spacing
			section.contentInsets = sectionContentInsets
			if self.dataSource.snapshot().sectionIdentifiers[sect].showSectionHeader {
				section.boundarySupplementaryItems = [titleSupplementary]
			}
			return section
		}
		
//		let section = NSCollectionLayoutSection(group: group)
//		section.interGroupSpacing = spacing
//		section.contentInsets = NSDirectionalEdgeInsets(top: 0,
//														leading: 13.2,
//														bottom: 0,
//														trailing: 13.2)
//		return UICollectionViewCompositionalLayout(section: section)
		
		/*
		let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/2), heightDimension: .fractionalHeight(1.0))
		let item = NSCollectionLayoutItem(layoutSize: itemSize)
		let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1/2))
		let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
		
		let section = NSCollectionLayoutSection(group: group)
//		section.contentInsets = .init(top: -40, leading: 0, bottom: 0, trailing: 0)
		let layout = UICollectionViewCompositionalLayout(section: section)
		return layout
		 */
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
		navigationController?.pushViewController(ApplicationInfoViewController(app: item), animated: true)
	}
	
	func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let app = dataSource.itemIdentifier(for: indexPath) else {
			return nil
		}
		
		return UIContextMenuConfiguration(identifier: nil) { [unowned self] in
			let vc = ApplicationContextMenuPreview(app: app)
			let height = (traitCollection.horizontalSizeClass == .regular || UIDevice.current.orientation.isLandscape) ? 300 : 120
			vc.preferredContentSize = CGSize(width: UIScreen.main.bounds.width,
											 height: CGFloat(height))
			
			return vc
		} actionProvider: { _ in
			let openAction = UIAction(title: .localized("Open"), image: UIImage(systemName: "arrow.up.forward.app.fill")) { _ in
				app.open()
			}
			
			let copyNameAction = UIAction(title: .localized("Name")) { _ in
				UIPasteboard.general.string = app.name
			}
			
			let copyBundleIDAction = UIAction(title: .localized("Bundle Identifier")) { _ in
				UIPasteboard.general.string = app.bundleID
			}
			
			let copyImageAction = UIAction(title: .localized("Icon")) { _ in
				UIPasteboard.general.image = app.iconImage(forFormat: 12)
			}
			
			let copyMenu = UIMenu(title: .localized("Copy..."), children: [copyNameAction, copyBundleIDAction, copyImageAction])
			return UIMenu(children: [openAction, copyMenu])
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
		guard let contextMenuPreview = animator.previewViewController as? ApplicationContextMenuPreview else { return }
		navigationController?.pushViewController(ApplicationInfoViewController(app: contextMenuPreview.app), animated: true)
	}
	
}

extension ApplicationListViewController: UISearchBarDelegate {
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		guard !searchText.isEmpty else {
			dataSource.apply(allItemsSnapshot)
			return
		}
		
		let newCollections: [ApplicationCollection] = allItemsSnapshot.sectionIdentifiers.compactMap { section in
			let newApps = allItemsSnapshot.itemIdentifiers(inSection: section).filter { app in
				return app.name.localizedCaseInsensitiveContains(searchText) || app.bundleID.localizedCaseInsensitiveContains(searchText)
			}
			
			if newApps.isEmpty {
				return nil
			}
			return ApplicationCollection(apps: newApps, section: section)
		}
		
		dataSource.apply(makeSnapshot(for: newCollections))
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		dataSource.apply(allItemsSnapshot)
	}
}
