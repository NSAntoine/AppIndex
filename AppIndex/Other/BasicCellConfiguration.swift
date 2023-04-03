//
//  BasicCellConfiguration.swift
//  AppIndex
//
//  Created by Serena on 31/03/2023.
//  

import UIKit

struct BasicCellConfiguration: Hashable {
	let name: String
	let image: UIImage?
	
	init(name: String, image: UIImage?) {
		self.name = name
		self.image = image
	}
	
}
