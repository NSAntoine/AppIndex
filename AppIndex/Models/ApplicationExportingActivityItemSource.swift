//
//  ApplicationExportingActivityItemSource.swift
//  AppIndex
//
//  Created by Serena on 31/03/2023.
//  

import UIKit
import LinkPresentation

/// A UIActivityItemSource to use when exporting an app's .ipa
class ApplicationExportingActivityItemSource: NSObject, UIActivityItemSource {
	let app: Application
	let ipaDir: URL
	
	init(app: Application, ipaDir: URL) {
		self.app = app
		self.ipaDir = ipaDir
		super.init()
	}
	
	func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
		return app.name
	}
	
	func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
		return app.iconImage
	}
	
	func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
		return ipaDir.lastPathComponent
	}
	
	func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
		return ipaDir
	}

	func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
		let metadata = LPLinkMetadata()
		metadata.title = ipaDir.lastPathComponent
		if let image = app.iconImage {
			metadata.imageProvider = NSItemProvider(object: image)
		}
		
		return metadata
	}
}
