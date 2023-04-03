//
//  BackupItem.swift
//  AppIndex
//
//  Created by Serena on 30/03/2023.
//  

import UIKit
import CustomLaunchServicesBridge

struct BackupItem: Codable, Hashable {
	let applicationIdentifier: String
	let name: String
	let creationDate: Date
	let iconImageData: Data?
	let backupFilename: String
	let stagingDirectoryName: String
	var displayName: String
	
	init(application: Application, stagingDirectoryName: String) {
		self.applicationIdentifier = application.bundleID
		self.name = application.name
		self.creationDate = Date() // initialized now, created now.
		self.iconImageData = application.iconImage?.pngData()
		self.backupFilename = "\(applicationIdentifier)-\(creationDate).zip"
		self.stagingDirectoryName = stagingDirectoryName
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
		displayName = dateFormatter.string(from: creationDate)
	}
}
