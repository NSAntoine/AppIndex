//
//  PropertyListItemViewController.swift
//  Santander
//
//  Created by Serena on 17/08/2022.
//

import UIKit

class SerializedItemViewController: UITableViewController {
    var item: SerializedItemType
    var itemKey: String
    
    weak var delegate: SerializedItemViewControllerDelegate?
    
    init(item: SerializedItemType, itemKey: String) {
        self.item = item
        self.itemKey = itemKey
        
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setItem(to newValue: SerializedItemType) {
        if self.delegate?.didChangeValue(ofItem: itemKey, to: newValue) ?? false {
            item = newValue
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = itemKey
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
//        var conf = cell.defaultContentConfiguration()
        
        switch indexPath.section {
        case 0:
			cell.textLabel?.text = itemKey

            return cell
        case 1:
            switch item {
            case .bool(let bool):
				cell.textLabel?.text = "Value"
				cell.detailTextLabel?.text = bool.description
				return cell
            case .string(let string):
                let textView = UITextView(frame: cell.frame)
                textView.text = string
                textView.font = .systemFont(ofSize: UIFont.systemFontSize)
                textView.backgroundColor = cell.backgroundColor
                textView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                textView.isScrollEnabled = true
				textView.isEditable = false
                
                cell.contentView.addSubview(textView)
                return cell
			case .int(let int):
				cell.textLabel?.text = "Value"
				cell.detailTextLabel?.text = int.description
			case .float(let float):
				cell.textLabel?.text = "Value"
				cell.detailTextLabel?.text = float.description
            case .date(let date):
                let datePicker = UIDatePicker()
				datePicker.isEnabled = false
                datePicker.date = date
				cell.accessoryView = datePicker
                return cell
            default:
				cell.textLabel?.text = "Vale"
				cell.detailTextLabel?.text = item.description
            }
        case 2:
			cell.textLabel?.text = "Type"
			cell.detailTextLabel?.text = item.typeDescription
        default:
            fatalError()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Key"
        case 1:
            return "Value"
        case 2:
            return "Type"
        default:
            return nil
        }
    }
    
    func valueTextField(atIndexPath indexPath: IndexPath) -> UITextField {
        let textField = UITextField()
        
//        let action = UIAction {
//            self.valueTextFieldDone(textField, atIndexPath: indexPath)
//        }
        
		return textField
//        switch item {
//        case .string(let string):
//            textField.text = string
//            textField.returnKeyType = .done
//            textField.addAction(action, for: .editingDidEndOnExit)
//        case .int(let int):
//            textField.keyboardType = .numberPad
//            textField.text = int.description
//            textField.inputAccessoryView = toolbarDoneView(doneAction: action, textFieldOrView: textField)
//        case .float(let float):
//            textField.text = float.description
//            textField.keyboardType = .decimalPad
//            textField.inputAccessoryView = toolbarDoneView(doneAction: action, textFieldOrView: textField)
//        default:
//            fatalError() // should never get here
//        }
//
//        return textField
    }
    
    /// A toolbar with a bar button item saying 'done'
    /// this is needed for non-string type textfields
    func toolbarDoneView(doneAction: UIAction, textFieldOrView: UIResponder) -> UIToolbar {
        let toolbar = UIToolbar()
        
        return toolbar
    }
    
    
    func valueTextFieldDone(_ textField: UITextField, atIndexPath indexPath: IndexPath) {
        guard let text = textField.text, !text.isEmpty else {
            return
        }
        
        switch item {
        case .string(_):
            setItem(to: .string(text))
        case .int(_):
            guard let num = Int(text) else { return }
            setItem(to: .int(num))
        case .float(_):
            guard let num = Float(text) else { return }
            setItem(to: .float(num))
        default:
            break
        }
        
        textField.resignFirstResponder()
    }
    
    func itemKeyTextFieldDone(_ textField: UITextField, indexPath: IndexPath) {
        guard let text = textField.text, !text.isEmpty else {
            return
        }
        
        if self.delegate?.didChangeName(ofItem: itemKey, to: text) ?? false {
            self.itemKey = text
            self.title = self.itemKey
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }
        
        textField.resignFirstResponder()
    }
    
}

protocol SerializedItemViewControllerDelegate: AnyObject {
    func didChangeName(ofItem item: String, to newName: String) -> Bool
    func didChangeValue(ofItem item: String, to newValue: SerializedItemType) -> Bool
}
