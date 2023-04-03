//
//  StoredUTType.swift
//  AppIndex
//
//  Created by Serena on 02/04/2023.
//  

import Foundation
import CoreServices

/// Represents a `UTType` from a given Info.plist
struct StoredUTType: Hashable {
	/// The types that this UTType conforms to, ie, `[""com.apple.package""]`
	let conformsTo: [String]?
	
	/// A description of this type, ie `"Photos Library"`
	let description: String?
	
	/// The name for the icon used for this type
//	let iconName: String?
	
	/// The identifier of this Uniform Type Identifier, ie `com.apple.photos.library`
	let identifier: String?
	
	/// The filename extensions belonging to this `UTType`.
	let filenameExtensions: [String]?
	
	init(dictionary: [String: Any]) {
		self.description = dictionary["UTTypeDescription"] as? String
		//self.iconName = dictionary["UTTypeIconName"] as? String
		self.conformsTo = dictionary["UTTypeConformsTo"] as? [String]
		self.identifier = dictionary["UTTypeIdentifier"] as? String
		
		if let tagSpecification = dictionary["UTTypeTagSpecification"] as? [String: Any] {
			filenameExtensions = tagSpecification["public.filename-extension"] as? [String]
		} else {
			filenameExtensions = nil
		}
	}
}
