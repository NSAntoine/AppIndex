//
//  FootableDataSource.swift
//  AppIndex
//
//  Created by Serena on 02/04/2023.
//  

import UIKit

protocol FootableItem {
	var footerTitle: String? { get }
}

class FootableDataSource<Section: Hashable & FootableItem, Item: Hashable>: UITableViewDiffableDataSource<Section, Item> {
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return snapshot().sectionIdentifiers[section].footerTitle
	}
}
