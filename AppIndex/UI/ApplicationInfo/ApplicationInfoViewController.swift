//
//  ApplicationInfoViewController.swift
//  AppIndex
//
//  Created by Serena on 27/03/2023.
//  

import UIKit
import CustomLaunchServicesBridge

class ApplicationInfoViewController: UIViewController {
	let app: Application
	
	lazy var tableHeaderView: ApplicationInfoTableHeaderView = ApplicationInfoTableHeaderView(app: app)
	var scrollableHeight: CGFloat = 0
	
	var navigationBarView: UIStackView!
	var tableView: UITableView!
	
	// need to fetch sizes on a bg queue because they sometimes take a bit of time to show
	let fetchSizesQueue = DispatchQueue(label: "com.serena.appindex.fetchSizesQueue")
	
	init(app: Application) {
		self.app = app
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	typealias DataSource = FootableDataSource<Section, CellItem>
	lazy var dataSource = makeDataSource()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.largeTitleDisplayMode = .never
		tableView = UITableView(frame: .zero, style: .insetGrouped)
		tableView.backgroundColor = .systemGroupedBackground
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.dataSource = dataSource
		dataSource.defaultRowAnimation = .fade
		tableView.delegate = self
		//tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GeneralCell")
		view.addSubview(tableView)
		
		tableView.constraintCompletely(to: view)
//		tableHeaderView.translatesAutoresizingMaskIntoConstraints = false
		tableView.tableHeaderView = tableHeaderView
		
		let titleViewLabel = UILabel()
		titleViewLabel.text = app.name
		titleViewLabel.font = .systemFont(ofSize: 16, weight: .semibold)
		
		let imageView = UIImageView(image: app.iconImage(forFormat: 9))
		let stackView = UIStackView(arrangedSubviews: [imageView, titleViewLabel])
		stackView.spacing = 5
		
		navigationBarView = stackView
		navigationBarView.isHidden = true
		
		navigationItem.titleView = navigationBarView
		addDataSourceItems()
		setActionsButton()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if let headerView = tableView.tableHeaderView as? ApplicationInfoTableHeaderView {
			let height = headerView.systemLayoutSizeFitting(CGSize(width: tableView.bounds.width, height: 0)).height
			var headerFrame = headerView.frame
			self.tableHeaderView = headerView
			
			//Comparison necessary to avoid infinite loop
			if height != headerFrame.size.height {
				headerFrame.size.height = height
				headerView.frame = headerFrame
				//tableView.tableHeaderView?.frame = headerView.frame
				tableView.tableHeaderView = headerView
				scrollableHeight = _calculateHeaderScrollableHeight()
			}
		}
	}
	
	deinit {
		print("ApplicationInfoViewController thankfully de-initialized, see you.")
	}
	
	@objc
	func openRightBarMenuActionSheet() {
		let exportAsIPAction = UIAlertAction(title: .localized("Export as .ipa"), style: .default) { [unowned self] _ in
			app.exportAsIpa(senderViewController: self)
		}
		
		let deleteAction = UIAlertAction(title: .localized("Delete"), style: .destructive) { [unowned self] _ in
			deleteApp()
		}
		
		let backupAction = UIAlertAction(title: .localized("Backup"), style: .default) { [unowned self] _ in
			backupApp()
		}
		
		let restoreBackupActions = BackupServices.shared.backups(for: app).map { backup in
			return UIAlertAction(
				title: .localizedStringWithFormat("Restore backup from %@", backup.displayName),
				style: .default) { [unowned self] _ in
				restoreBackup(backup)
			}
		}
		
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		alert.addAction(exportAsIPAction)
		for action in restoreBackupActions {
			alert.addAction(action)
		}
		alert.addAction(backupAction)
		if app.proxy.isDeletable {
			alert.addAction(deleteAction)
		}
		
		alert.addAction(UIAlertAction(title: .localized("Cancel"), style: .cancel))
		present(alert, animated: true)
	}
	
	func setActionsButton() {
		if #available(iOS 14, *) {
			let exportAsIPAction = UIAction(title: .localized("Export as .ipa")) { [unowned self] _ in
				app.exportAsIpa(senderViewController: self)
			}
			
			let backupAction = UIAction(title: .localized("Backup")) { [unowned self] _ in
				backupApp()
			}
			
			let restoreBackupsActions = BackupServices.shared.backups(for: app).map { item in
				return UIAction(title: .localizedStringWithFormat("Restore backup from %@", item.displayName)) { [unowned self] _ in
					restoreBackup(item)
				}
			}
		
			var children = [
				UIMenu(options: .displayInline, children: [exportAsIPAction]),
				UIMenu(options: .displayInline, children: [backupAction]),
				UIMenu(options: .displayInline, children: restoreBackupsActions)
			]
			
			if app.proxy.isDeletable {
				let deleteAction = UIAction(title: .localized("Delete"), attributes: .destructive) { [unowned self] _ in
					deleteApp()
				}
				
				children.append(UIMenu(options: .displayInline, children: [deleteAction]))
			}
			
			tableHeaderView.actionsButton.showsMenuAsPrimaryAction = true
			tableHeaderView.actionsButton.menu = UIMenu(children: children)
			
		} else {
			tableHeaderView.actionsButton.addTarget(self, action: #selector(openRightBarMenuActionSheet), for: .touchUpInside)
		}
	}
}

// Action button actions stuff
extension ApplicationInfoViewController {
	func deleteApp() {
		do {
			try app.uninstall()
			
			// we deleted, go back to the root vc
			// and refresh apps
			navigationController?.popToRootViewController(animated: true)
			if let rootVC = (navigationController?.topViewController as? ApplicationListViewController) {
				print("rootVC")
				Application.refreshAllApps()
				rootVC.allItemsSnapshot = rootVC.makeSnapshot(for: rootVC.appCollections(withSortMode: rootVC.sortMode))
				rootVC.dataSource.apply(rootVC.allItemsSnapshot)
			}
		} catch {
			errorAlert(title: .localizedStringWithFormat(.localized("Failed to delete %@"), app.name),
					   message: error.localizedDescription)
		}
	}
	
	func backupApp() {
		let alertController = presentAlertWithSpinner(title: .localized("Backing up.."),
													  heightAnchor: 100)
		
		DispatchQueue.global(qos: .background).async { [unowned self] in
			do {
				try BackupServices.shared.backup(application: app, rootHelper: true) { url in
					DispatchQueue.main.async {
						alertController.message = url.lastPathComponent
					}
				}
				
				DispatchQueue.main.async { [unowned self] in
					alertController.dismiss(animated: true)
					setActionsButton()
				}
			} catch {
				DispatchQueue.main.async {
					alertController.dismiss(animated: true) { [unowned self] in
						errorAlert(title: "Error", message: error.localizedDescription)
					}
				}
			}
		}
	}
	
	func restoreBackup(_ backup: BackupItem) {
		let spinner = presentAlertWithSpinner(title: .localized("Restoring..."), heightAnchor: 120)
		
		DispatchQueue.global(qos: .background).async {
			do {
				try BackupServices.shared.restoreBackup(backup)
				
				DispatchQueue.main.async {
					spinner.dismiss(animated: true)
				}
			} catch {
				DispatchQueue.main.async {
					spinner.dismiss(animated: true) { [unowned self] in
						errorAlert(title: "Error", message: error.localizedDescription)
					}
				}
			}
		}
	}
}

extension ApplicationInfoViewController {
	// MARK: - Diffable Data Source models
	enum Section: Hashable, CustomStringConvertible, FootableItem {
		case generalInfo
		case versionInformation
		case appStatus // info such as if the app is containerized, beta, deletable, etc
		case advancedInfo
		case sizeInformation
		case itunesMetadata
		case infoPlistInfo
		case paths
		
		var description: String {
			switch self {
			case .generalInfo:
				return .localized("General")
			case .versionInformation:
				return .localized("Version")
			case .appStatus:
				return .localized("Status")
			case .advancedInfo:
				return .localized("Advanced")
			case .sizeInformation:
				return .localized("Size")
			case .itunesMetadata:
				return .localized("Store Metadata")
			case .infoPlistInfo:
				return .localized("Info.plist declared info")
			case .paths:
				return .localized("Paths")
			}
		}
		
		var footerTitle: String? {
			switch self {
			case .sizeInformation:
				return .localized("If the Application Size shows up here as 'zero', this most likey means that the Application is a System one, and it may not be possible to measure accurately.")
			default:
				return nil
			}
		}
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
	
	func addDataSourceItems() {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MMM d, yyyy h:mm a"
		var snapshot = NSDiffableDataSourceSnapshot<Section, CellItem>()
		snapshot.appendSections([.generalInfo])
		snapshot.appendItems([
			CellItem(localizedPrimaryText: "Name", secondaryText: app.name),
			CellItem(localizedPrimaryText: "Bundle Identifier", secondaryText: app.bundleID),
			CellItem(localizedPrimaryText: "Download Date", secondaryText: dateFormatter.string(from: app.proxy.registeredDate)),
			CellItem(localizedPrimaryText: "Type", secondaryText: app.type?.description ?? app.proxy.applicationType),
		], toSection: .generalInfo)
		
		
		var itunesMetadataItems: [CellItem] = []
		if let vendor = app.proxy.vendorName {
			itunesMetadataItems.append(CellItem(localizedPrimaryText: "Vendor", secondaryText: vendor))
		}
		
		if let genre = app.proxy.genre {
			itunesMetadataItems.append(CellItem(localizedPrimaryText: "Genre", secondaryText: genre))
		}
		
		if let ratingLabel = app.proxy.ratingLabel {
			itunesMetadataItems.append(CellItem(localizedPrimaryText: "Age Rating", secondaryText: ratingLabel))
		}
		
		if !itunesMetadataItems.isEmpty {
			snapshot.appendSections([.itunesMetadata])
			snapshot.appendItems(itunesMetadataItems, toSection: .itunesMetadata)
		}
		
		
		let bundle = Bundle(url: app.proxy.bundleURL())
		let unlocalizedInfoDict = bundle?.infoDictionary
		
		snapshot.appendSections([.versionInformation])
		snapshot.appendItems([
			CellItem(localizedPrimaryText: "Application Version", secondaryText: app.proxy.shortVersionString),
			CellItem(localizedPrimaryText: "SDK Version Built with", secondaryText: app.proxy.sdkVersion),
			CellItem(localizedPrimaryText: "Mininium iOS Version Required", secondaryText: app.proxy.minimumSystemVersion),
		], toSection: .versionInformation)
		
		let byteCountFormatter = ByteCountFormatter()
		byteCountFormatter.countStyle = .file
		byteCountFormatter.allowedUnits = .useAll
		
		var sizeInfoItems: [CellItem] = []
		
		let diskUsage = app.proxy.diskUsage
		let sizeInfoNamesAndKeyPaths: [(String, KeyPath<_LSDiskUsage, NSNumber?>)] = [
			(.localized("Application (.app) Size"), \.staticUsage),
			(.localized("Documents & Data"), \.dynamicUsage),
			(.localized("Size in Group Containers"), \.sharedUsage)
		]
		
		for (text, keyPath) in sizeInfoNamesAndKeyPaths {
			sizeInfoItems.append(
				CellItem(localizedPrimaryText: text, secondaryText: nil) { [unowned self] cell in
					fetchSizeAndConfigure(forCell: cell,
										  primaryText: text,
										  formatter: byteCountFormatter,
										  diskUsage: diskUsage,
										  sizePropertyKeyPath: keyPath)
				}
			)
		}
		
//
//		if let staticSize = diskUsage.staticUsage?.int64Value {
//			sizeInfoItems.append(CellItem(localizedPrimaryText: "Application Size", secondaryText: byteCountFormatter.string(fromByteCount: staticSize)))
//		}
//
//		if let dynamicUsage = diskUsage.dynamicUsage?.int64Value {
//			sizeInfoItems.append(CellItem(localizedPrimaryText: "Documents & Data", secondaryText: byteCountFormatter.string(fromByteCount: dynamicUsage)))
//		}
//
//		if let sharedSize = diskUsage.sharedUsage?.int64Value {
//			sizeInfoItems.append(CellItem(localizedPrimaryText: "Size in Group Containers", secondaryText: byteCountFormatter.string(fromByteCount: sharedSize)))
//		}
		
		snapshot.appendSections([.sizeInformation])
		snapshot.appendItems(sizeInfoItems, toSection: .sizeInformation)
		
		snapshot.appendSections([.appStatus])
		snapshot.appendItems([
			CellItem(localizedPrimaryText: "Deletable", secondaryText: app.proxy.isDeletable.yesOrNoDescription),
			CellItem(localizedPrimaryText: "Containerized", secondaryText: app.proxy.isContainerized.yesOrNoDescription),
			CellItem(localizedPrimaryText: "Beta App", secondaryText: app.proxy.isBetaApp.yesOrNoDescription),
			CellItem(localizedPrimaryText: "Restricted", secondaryText: app.proxy.isRestricted.yesOrNoDescription),
		], toSection: .appStatus)
		
		snapshot.appendSections([.advancedInfo])
		snapshot.appendItems([
			CellItem(localizedPrimaryText: "Supports iTunes File Sharing", secondaryText: app.proxy.fileSharingEnabled.yesOrNoDescription),
			CellItem(localizedPrimaryText: "Came from App Store", secondaryText: app.proxy.isAppStoreVendable.yesOrNoDescription),
			CellItem(localizedPrimaryText: "Has Settings Bundle", secondaryText: app.proxy.hasSettingsBundle.yesOrNoDescription),
			CellItem(localizedPrimaryText: "Launch Prohibited", secondaryText: app.proxy.isLaunchProhibited.yesOrNoDescription),
		], toSection: .advancedInfo)
		// context menu for paths
		let pathsContextMenu = CellItem.ContextMenuKind.other { item in
			guard let path = item.secondaryText else {
				return []
			}
			
			var items: [UIAction] = []
			if UIApplication.shared.canOpenURL(URL(string: "filza://")!) {
				let openInFilzaAction = UIAction(title: .localized("Open in Filza")) { _ in
					UIApplication.shared.open(URL(string: "filza://\(path)")!)
				}
				
				items.append(openInFilzaAction)
			}
			
			if UIApplication.shared.canOpenURL(URL(string: "santander://")!) {
				let openInSantanderAction = UIAction(title: .localized("Open in Santander")) { _ in
					UIApplication.shared.open(URL(string: "santander://\(path)")!)
				}
				items.append(openInSantanderAction)
			}
			
			let copyPathAction = UIAction(title: .localized("Copy"), image: UIImage(systemName: "doc.on.doc")) { _ in
				UIPasteboard.general.string = path
			}
			
			items.append(copyPathAction)
			return items
		}
		
		var infoPlistSectionItems: [CellItem] = []
		
		if let infoPlist = (bundle?.localizedInfoDictionary ?? unlocalizedInfoDict) {
			let stringToLookFor = "UsageDescription"
			
			let items: [CellItem] = infoPlist.compactMap { (key, value) in
				guard key.hasSuffix(stringToLookFor), let valueString = value as? String else {
					return nil
				}

				return CellItem(primaryText: key, secondaryText: valueString)
			}
			
			if !items.isEmpty {
				infoPlistSectionItems.append(
					CellItem(localizedPrimaryText: "Usage Descriptions", secondaryText: nil) { cell in
						cell.accessoryType = .disclosureIndicator
					} tapAction: { [unowned self] in
						let vc = GenericListViewController<GenericDiffableDataSourceSection> { vc in
							var snapshot = NSDiffableDataSourceSnapshot<GenericDiffableDataSourceSection, CellItem>()
							snapshot.appendSections([.main])
							snapshot.appendItems(items)
							vc.dataSource.apply(snapshot)
						}
						vc.title = .localized("Usage Descriptions")
						navigationController?.pushViewController(vc, animated: true)
					})
			}
		}
		
		let exportedUTTypes = unlocalizedInfoDict?["UTExportedTypeDeclarations"] as? [[String: Any]]
		if let exportedUTTypes {
			let item = CellItem(localizedPrimaryText: "Exported Types", secondaryText: nil) { cell in
				cell.accessoryType = .disclosureIndicator
			} tapAction: { [unowned self] in
				let types = exportedUTTypes.map { dict in
					return StoredUTType(dictionary: dict)
				}
				
				let vc = GenericListViewController<StoredUTType> { vc in
					var snapshot = NSDiffableDataSourceSnapshot<StoredUTType, CellItem>()
					for type in types {
						snapshot.appendSections([type])
						var items: [CellItem] = [
							CellItem(localizedPrimaryText: "Identifier", secondaryText: type.identifier ?? "N/A"),
							CellItem(localizedPrimaryText: "Description", secondaryText: type.description ?? "N/A")
						]
						
						if let conformingTypes = type.conformsTo {
							let item = CellItem(localizedPrimaryText: "Conforms to", secondaryText: conformingTypes.joined(separator: ", "))
							items.append(item)
						}
						
						items.append(CellItem(localizedPrimaryText: "File Extension(s)", secondaryText: type.filenameExtensions?.joined(separator: ", ") ?? "N/A"))
						snapshot.appendItems(items, toSection: type)
					}
					
					vc.dataSource.apply(snapshot)
				}
				
				vc.title = .localized("Exported Types")
				navigationController?.pushViewController(vc, animated: true)
			}
			
			infoPlistSectionItems.append(item)
		}
		
		// entitlements aren't infoplist things but oh well
		infoPlistSectionItems.append(CellItem(localizedPrimaryText: "Entitlements", secondaryText: nil) { cell in
			cell.accessoryType = .disclosureIndicator
		} tapAction: { [unowned self] in
			let vc = SerializedDocumentViewController(
				dictionary: app.proxy.entitlements.asSerializedDictionary(),
				type: .plist(format: nil),
				title: .localized("Entitlements"),
				parentController: nil,
				canEdit: false)
			navigationController?.pushViewController(vc, animated: true)
		})
		
		let domains = (bundle?.infoDictionary?["NSAppTransportSecurity"] as? [String: Any])?["NSExceptionDomains"] as? [String: [String: Any]]
		if let domains {
			infoPlistSectionItems.append(
				CellItem(localizedPrimaryText: "Transport Security Exceptions", secondaryText: nil) { cell in
					cell.accessoryType = .disclosureIndicator
				} tapAction: { [unowned self] in
					let secItems = domains.map { (key, value) in
						return AppTransportSecurity(domain: key, dictionary: value)
					}
					
					navigationController?.pushViewController(AppTransportSecurityViewController(securityItems: secItems),
															 animated: true)
				})
		}
		
		if !app.proxy.claimedURLSchemes.isEmpty {
			let item = CellItem(localizedPrimaryText: "Registered URL Schemes", secondaryText: nil) { cell in
				cell.accessoryType = .disclosureIndicator
			} tapAction: { [unowned self] in
				let vc = GenericListViewController<GenericDiffableDataSourceSection> { [unowned self] vc in
					var snapshot = NSDiffableDataSourceSnapshot<GenericDiffableDataSourceSection, CellItem>()
					snapshot.appendSections([.main])
					snapshot.appendItems(app.proxy.claimedURLSchemes.map { CellItem(localizedPrimaryText: $0, secondaryText: nil) })
					vc.dataSource.apply(snapshot)
				}
				
				vc.title = .localized("Registered URL Schemes")
				navigationController?.pushViewController(vc, animated: true)
			}
			
			infoPlistSectionItems.append(item)
		}
		
		if !infoPlistSectionItems.isEmpty {
			snapshot.appendSections([.infoPlistInfo])
			snapshot.appendItems(infoPlistSectionItems, toSection: .infoPlistInfo)
		}
		
		snapshot.appendSections([.paths])
		snapshot.appendItems([
			CellItem(localizedPrimaryText: "Bundle Path", secondaryText: app.proxy.bundleURL().path,
					 contextMenuProvider: pathsContextMenu, isPath: true),
			CellItem(localizedPrimaryText: "Container Path", secondaryText: app.proxy.containerURL().path,
					 contextMenuProvider: pathsContextMenu, isPath: true)
		], toSection: .paths)
		
		let appGroups = app.proxy.groupContainerURLs().map { (key, value) in
			return CellItem(localizedPrimaryText: key, secondaryText: value.path, contextMenuProvider: pathsContextMenu, isPath: true)
		}
		
		snapshot.appendItems(appGroups, toSection: .paths)
		dataSource.apply(snapshot)
	}
	
	func fetchSizeAndConfigure(forCell cell: UITableViewCell,
							   primaryText: String,
							   formatter byteCountFormatter: ByteCountFormatter,
							   diskUsage: _LSDiskUsage,
							   sizePropertyKeyPath: KeyPath<_LSDiskUsage, NSNumber?>) {
		if #available(iOS 14, *) {
			cell.contentConfiguration = nil
		}
		
		cell.textLabel?.text = primaryText
		
		let spinner = UIActivityIndicatorView()
		spinner.translatesAutoresizingMaskIntoConstraints = false
		spinner.startAnimating()
		cell.contentView.addSubview(spinner)
		
		NSLayoutConstraint.activate([
			spinner.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
			spinner.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
		])
		
		fetchSizesQueue.async { [unowned self] in
			let size = app.proxy.diskUsage[keyPath: sizePropertyKeyPath]?.int64Value
			DispatchQueue.main.async {
				spinner.removeFromSuperview()
				
				if let size {
					cell.detailTextLabel?.text = byteCountFormatter.string(fromByteCount: size)
				} else {
					cell.detailTextLabel?.text = .localized("N/A")
				}
			}
		}
	}
}

extension ApplicationInfoViewController: UITableViewDelegate {
	
	private func _calculateHeaderScrollableHeight() -> CGFloat {
		let navigationBarHeight = (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0) + (navigationController?.navigationBar.frame.height ?? 0)
		let height = (tableHeaderView.frame.size.height - navigationBarHeight) - 70
		return height
	}
	
	func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		let item = dataSource.itemIdentifier(for: indexPath)!
		return item.isPath || item.tapAction != nil
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		// for paths, present an action sheet to open the paths in either Santander or Filza
		guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
		
		tableView.deselectRow(at: indexPath, animated: true)
		
		if let action = item.tapAction {
			action()
		} else if let path = item.secondaryText, item.isPath {
			
			let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			let santanderURL = URL(string: "santander://\(path)")
			let filzaURL = URL(string: "filza://\(path)")
			
			if let santanderURL, UIApplication.shared.canOpenURL(santanderURL) {
				let openSantanderAction = UIAlertAction(title: .localized("Open in Santander"), style: .default) { _ in
					UIApplication.shared.open(santanderURL)
				}
				actionSheet.addAction(openSantanderAction)
			}
			
			if let filzaURL, UIApplication.shared.canOpenURL(filzaURL) {
				let openFilzaAction = UIAlertAction(title: .localized("Open in Filza"), style: .default) { _ in
					UIApplication.shared.open(filzaURL)
				}
				actionSheet.addAction(openFilzaAction)
			}
			
			// no actions, don't present action sheet
			if actionSheet.actions.isEmpty {
				return
			}
			
			actionSheet.popoverPresentationController?.sourceView = view
			let bounds = (tableView.cellForRow(at: indexPath) ?? view).bounds
			actionSheet.popoverPresentationController?.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
			
			actionSheet.addAction(UIAlertAction(title: .localized("Cancel"), style: .cancel))
			present(actionSheet, animated: true)
		}
	}
	
	func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
			return UIMenu(children: item.contextMenuProvider.actions(forItem: item))
		}
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let newAlpha = (scrollView.contentOffset.y - scrollableHeight) / 100
		let didScrollEnough = newAlpha >= 0
		
		UIView.animate(withDuration: 0.5, delay: 0, options: didScrollEnough ? .curveEaseIn : .curveEaseOut) {
			self.navigationBarView.isHidden = !didScrollEnough
			self.navigationBarView.alpha = newAlpha
		}
	}
}


