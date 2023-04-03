//
//  SerializedArrayViewController.swift
//  Santander
//
//  Created by Serena on 18/08/2022.
//

import UIKit

class SerializedArrayViewController: UITableViewController {
    var array: Array<Any>
    let type: SerializedDocumentViewerType
    let fileURL: URL?
    let canEdit: Bool
    var parentController: SerializedControllerParent?
    
    init(
        array: Array<Any>,
        type: SerializedDocumentViewerType,
        parentController: SerializedControllerParent?,
        title: String?,
        fileURL: URL?,
        canEdit: Bool
    ) {
        self.array = array
        self.type = type
        self.fileURL = fileURL
        self.canEdit = canEdit
        self.parentController = parentController
        
        super.init(style: .insetGrouped)
        self.title = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let item = array[indexPath.row]
		
		if #available(iOS 14, *) {
			var conf = cell.defaultContentConfiguration()
			if item as? Array<Any> != nil {
				conf.text = "Array (Index \(indexPath.row))"
				cell.accessoryType = .disclosureIndicator
			} else if item as? [String: Any] != nil {
				conf.text = "Dictionary (Index \(indexPath.row))"
				cell.accessoryType = .disclosureIndicator
			} else {
				conf.text = SerializedItemType(item: item).description
			}
			
			cell.contentConfiguration = conf
		} else {
			if item as? Array<Any> != nil {
				cell.textLabel?.text = "Array (Index \(indexPath.row))"
			} else if item as? [String: Any] != nil {
				cell.textLabel?.text = "Dictionary (Index \(indexPath.row))"
				cell.accessoryType = .disclosureIndicator
			} else {
				cell.textLabel?.text = SerializedItemType(item: item).description
			}
		}
		
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let arr = array[indexPath.row] as? Array<Any> {
            let title = "Array (Index \(indexPath.row))"
            let vc = SerializedArrayViewController(
                array: arr,
                type: type,
                parentController: .array(self),
                title: title,
                fileURL: fileURL,
                canEdit: canEdit
            )
            
            navigationController?.pushViewController(vc, animated: true)
        } else if let dict = array[indexPath.row] as? [String: Any] {
            let serializedDict = dict.asSerializedDictionary()
            
            let title = "Dictionary (Index \(indexPath.row))"
            let vc = SerializedDocumentViewController(dictionary: serializedDict, type: type, title: title, fileURL: fileURL, parentController: .array(self), canEdit: true)
            navigationController?.pushViewController(vc, animated: true)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard canEdit else {
            return nil
        }
        
        let removeAction = UIContextualAction(style: .destructive, title: nil) { _, _, completion in
            var newArr = self.array
            newArr.remove(at: indexPath.row)
            
            if self.writeToFile(newArray: newArr) {
                tableView.deleteRows(at: [indexPath], with: .fade)
                completion(true)
            } else {
                completion(false)
            }
        }
        
        removeAction.image = .remove
        return UISwipeActionsConfiguration(actions: [removeAction])
    }
    
    func writeToFile(newArray: Array<Any>) -> Bool {
		fatalError("Can't get here in AppIndex")
    }
}
