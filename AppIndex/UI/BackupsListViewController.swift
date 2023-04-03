//
//  BackupsListViewController.swift
//  AppIndex
//
//  Created by Serena on 01/04/2023.
//  

import UIKit

class BackupsListViewController: UIViewController {
	var allBackups = BackupServices.shared.savedBackups()
	
	typealias DataSource = UITableViewDiffableDataSource<GenericDiffableDataSourceSection, BackupItem>
	var tableView: UITableView!
	var dataSource: DataSource!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.tableView = UITableView(frame: .zero, style: .insetGrouped)
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.delegate = self
		view.addSubview(tableView)
		tableView.constraintCompletely(to: view)
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MMM d, yyyy h:mm a"
		dataSource = DataSource(tableView: tableView) { tableView, indexPath, backup in
			let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
			if let imageData = backup.iconImageData {
				cell.imageView?.image = UIImage(data: imageData)
				
				let itemSize = CGSize.init(width: 40, height: 40)
				UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.main.scale)
				let imageRect = CGRect.init(origin: CGPoint.zero, size: itemSize)
				cell.imageView?.image?.draw(in: imageRect)
				cell.imageView?.image? = UIGraphicsGetImageFromCurrentImageContext()!
				UIGraphicsEndImageContext()
			}
			
			cell.textLabel?.text = backup.applicationIdentifier
			cell.detailTextLabel?.text = .localizedStringWithFormat("Created at %@", dateFormatter.string(from: backup.creationDate))
			cell.detailTextLabel?.textColor = .secondaryLabel
			return cell
		}
		
		addItems()
		
		title = .localized("Backups")
		navigationController?.navigationBar.prefersLargeTitles = true
	}
	
	func addItems() {
		var snapshot = NSDiffableDataSourceSnapshot<GenericDiffableDataSourceSection, BackupItem>()
		snapshot.appendSections([.main])
		snapshot.appendItems(allBackups, toSection: .main)
		dataSource.apply(snapshot)
	}
}

extension BackupsListViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
		let removeAction = UIContextualAction(style: .destructive, title: nil) { _, _, completion in
			do {
				try	BackupServices.shared.removeBackup(item)
				self.allBackups = BackupServices.shared.savedBackups()
				self.addItems()
				completion(true)
			} catch {
				self.errorAlert(title: "Error", message: error.localizedDescription)
				completion(false)
			}
		}
		
		removeAction.image = UIImage(systemName: "trash")
		
		return UISwipeActionsConfiguration(actions: [removeAction])
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
		tableView.deselectRow(at: indexPath, animated: true)
		let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		let restoreBackupAction = UIAlertAction(title: .localized("Restore"), style: .default) { [unowned self] _ in
			restoreBackup(item)
		}
		
		let deleteBackup = UIAlertAction(title: .localized("Delete"), style: .destructive) { [unowned self] _ in
			do {
				try	BackupServices.shared.removeBackup(item)
				allBackups = BackupServices.shared.savedBackups()
				addItems()
			} catch {
				self.errorAlert(title: "Error", message: error.localizedDescription)
			}
		}
		
		alertController.addAction(restoreBackupAction)
		alertController.addAction(deleteBackup)
		alertController.addAction(UIAlertAction(title: .localized("Cancel"), style: .cancel))
		present(alertController, animated: true)
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
