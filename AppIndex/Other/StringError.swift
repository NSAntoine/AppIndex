//
//  StringError.swift
//  AppIndex
//
//  Created by Serena on 31/03/2023.
//  

import Foundation

struct StringError: Error, LocalizedError, CustomStringConvertible {
	let description: String
	
	init(_ description: String) {
		self.description = description
	}
	
	var errorDescription: String? {
		description
	}
}
