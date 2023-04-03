//
//  ApplicationCollection.swift
//  AppIndex
//
//  Created by Serena on 28/03/2023.
//  

import UIKit

struct ApplicationCollection {
	let apps: [Application]
	let section: Section
	
	enum Section: Hashable {
		case none
		case type(Application.AppType?)
		case date(ApplicationInstallDate)
		case genre(String?)
		case vendor(String?)
		
		var showSectionHeader: Bool {
			switch self {
			case .none:
				return false
			default:
				return true
			}
		}
		
		var listConfiguration: BasicCellConfiguration {
			switch self {
			case .none:
				return BasicCellConfiguration(name: .localized("All Applications"), image: UIImage(systemName: "app"))
			case .type(let type):
				return BasicCellConfiguration(name: type?.headerDescription ?? .localized("Unknown Application Type"),
											  image: type?.image)
			case .date(let installDate):
				return BasicCellConfiguration(name: installDate.description, image: nil)
			case .genre(let genre):
				return BasicCellConfiguration(name: genre ?? .localized("No Genre"), image: nil)
			case .vendor(let vendor):
				return BasicCellConfiguration(name: vendor ?? .localized("Unknown Vendor"), image: nil)
			}
			
		}
	}
}
