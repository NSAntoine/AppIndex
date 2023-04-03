//
//  ApplicationInstallDate.swift
//  AppIndex
//
//  Created by Serena on 31/03/2023.
//  

import Foundation

struct ApplicationInstallDate: Hashable, Comparable, CustomStringConvertible {
	static func < (lhs: ApplicationInstallDate, rhs: ApplicationInstallDate) -> Bool {
		return lhs.year < rhs.year && lhs.month < rhs.year
	}
	
	let year: Int
	let month: Int
	
	init(year: Int, month: Int) {
		self.year = year
		self.month = month
	}
	
	init?(components: DateComponents) {
		guard let year = components.year, let month = components.month else {
			return nil
		}
		
		self.year = year
		self.month = month
	}
	
	var description: String {
		"\(Calendar.current.monthSymbols[month - 1]), \(year)"
	}
}
