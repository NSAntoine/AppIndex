//
//  Foundation.swift
//  AppIndex
//
//  Created by Serena on 27/03/2023.
//  

import Foundation

extension String {
	static func localized(_ key: String) -> String {
		return NSLocalizedString(key, comment: "")
	}
}

// Not Foundation but oh well
extension Bool {
	var yesOrNoDescription: String {
		self ? .localized("Yes") : .localized("No")
	}
}
