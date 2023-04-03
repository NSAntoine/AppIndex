//
//  GenericCellItem.swift
//  AppIndex
//
//  Created by Serena on 01/04/2023.
//  

import UIKit

struct CellItem: Hashable {
	static func == (lhs: CellItem, rhs: CellItem) -> Bool {
		return lhs.primaryText == rhs.primaryText && lhs.secondaryText == rhs.secondaryText
	}
	
	enum ContextMenuKind {
		case copy
		case other((CellItem) -> [UIAction])
		
		func actions(forItem item: CellItem) -> [UIAction] {
			switch self {
			case .copy:
				return [
					UIAction(title: .localized("Copy"), image: UIImage(systemName: "doc.on.doc")) { _ in
						UIPasteboard.general.string = item.secondaryText
					}
				]
			case .other(let handler):
				return handler(item)
			}
		}
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(primaryText)
		hasher.combine(secondaryText)
	}
	
	let primaryText: String?
	let secondaryText: String?
	let provider: ((UITableViewCell) -> Void)?
	var tapAction: (() -> Void)?
	let contextMenuProvider: ContextMenuKind
	let isPath: Bool
	
	init(primaryText: String?, secondaryText: String?, contextMenuProvider: ContextMenuKind = .copy, isPath: Bool = false, provider: ((UITableViewCell) -> Void)? = nil, tapAction: (() -> Void)? = nil) {
		self.primaryText = primaryText
		self.secondaryText = secondaryText
		self.provider = provider
		self.contextMenuProvider = contextMenuProvider
		self.isPath = isPath
		self.tapAction = tapAction
	}
	
	init(localizedPrimaryText: String, secondaryText: String?, provider: ((UITableViewCell) -> Void)? = nil, contextMenuProvider: ContextMenuKind = .copy, isPath: Bool = false, tapAction: (() -> Void)? = nil) {
		self.init(primaryText: .localized(localizedPrimaryText),
				  secondaryText: secondaryText,
				  contextMenuProvider: contextMenuProvider,
				  isPath: isPath,
				  provider: provider,
				  tapAction: tapAction)
	}
}
