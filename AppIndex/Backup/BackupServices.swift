//
//  BackupServices.swift
//  AppIndex
//
//  Created by Serena on 30/03/2023.
//  

import Foundation
import CompressionWrapper
import CustomLaunchServicesBridge

public class BackupServices {
	public static let shared = BackupServices()
	
	private init() {
#if targetEnvironment(simulator)
		self.libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("Backups")
#else
		self.libraryURL = URL(fileURLWithPath: "/var/mobile/Library/AppIndex/Backups/")
#endif
		self.backupsRegistryURL = libraryURL.appendingPathComponent("backups.json")
	}
	
	let libraryURL: URL
	let backupsRegistryURL: URL
	
	/// Backup the given app
	func backup(application: Application, rootHelper: Bool, urlHandler: @escaping (URL) -> Void) throws {
//		if rootHelper {
//			let url = Bundle.main.url(forAuxiliaryExecutable: "RootHelper")!
//			spawn(command: url.path, args: ["backup-app", application.bundleID], root: true)
//			return
//		}
		
		let applicationContainerURL = application.proxy.containerURL()
		if applicationContainerURL == URL(fileURLWithPath: "/var/mobile") || applicationContainerURL == URL(fileURLWithPath: "/var/root") {
			throw StringError(
				.localized("Can't backup app with a container URL of /var/mobile or /var/root (App likely has no container in the first place to back up), sorry")
			)
		}
		
		let stagingDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
			.appendingPathComponent("APPLICATION-STAGING-\(application.bundleID)-\(UUID().uuidString.prefix(5))")
		let containerURL = stagingDirectory.appendingPathComponent("Container")
		let groups = stagingDirectory.appendingPathComponent("Groups")
		
		let item = BackupItem(application: application,
							  stagingDirectoryName: stagingDirectory.pathComponents.suffix(2).joined(separator: "/"))
		let filename = item.backupFilename
		
		try FileManager.default.createDirectory(at: libraryURL, withIntermediateDirectories: true)
		
		try FileManager.default.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
		try FileManager.default.createDirectory(at: groups, withIntermediateDirectories: true)
		try FileManager.default.copyItem(at: applicationContainerURL, to: containerURL)
		
		for (groupID, groupContainerURL) in application.proxy.groupContainerURLs() {
			try FileManager.default.copyItem(at: groupContainerURL, to: groups.appendingPathComponent(groupID))
		}
		
		try Compression.shared.compress(paths: [stagingDirectory],
										outputPath: libraryURL.appendingPathComponent(filename),
										format: .zip,
										filenameExcludes: ["v0"] /* Stupid fucking dumbass directory always fails */,
										processHandler: urlHandler)
		
		var registry = savedBackups()
		
		registry.append(item)
		try JSONEncoder().encode(registry).write(to: backupsRegistryURL)
		try FileManager.default.removeItem(at: stagingDirectory)
	}
	
	// Retrieve previously saved backups
	func savedBackups() -> [BackupItem] {
		if let existingData = try? Data(contentsOf: backupsRegistryURL),
			let decoded = try? JSONDecoder().decode([BackupItem].self, from: existingData) {
			return decoded
		}
		
		return [] // couldn't get the saved backups
	}
	
	func backups(for application: Application) -> [BackupItem] {
		return savedBackups().filter { item in
			item.applicationIdentifier == application.bundleID
		}
	}
	
	func removeBackup(_ backup: BackupItem) throws {
		var all = savedBackups()
		all.removeAll { item in
			item == backup
		}
		
		try JSONEncoder().encode(all).write(to: backupsRegistryURL)
	}
	
	/*
	func exportBackup(_ backup: BackupItem) {
		
	}
	 */
	
	func restoreBackup(_ backup: BackupItem) throws {
		let appWeAreLookingFor = Application.all.first { $0.bundleID == backup.applicationIdentifier }
		guard let app = appWeAreLookingFor else {
			throw StringError(.localized("Couldn't find application on device with bundle ID \(backup.applicationIdentifier)"))
		}
		
		// Make sure we have the backup contents file
		let backupZIPURL = libraryURL.appendingPathComponent(backup.backupFilename)
		guard FileManager.default.fileExists(atPath: backupZIPURL.path) else {
			throw StringError(.localized("Couldn't find backup zip file at \(backupZIPURL.path)"))
		}
		
		print("Surgically operating on App \(app)")
		// get unique directory to do unzip in
		let temporaryUnzippingDir = URL(fileURLWithPath: NSTemporaryDirectory())
			.appendingPathComponent("BACKUP-\(app.bundleID)-\(UUID().uuidString.prefix(5))")
		
		try FileManager.default.createDirectory(at: temporaryUnzippingDir, withIntermediateDirectories: true)
		try Compression.shared.extract(path: backupZIPURL, to: temporaryUnzippingDir)
		
		// This is where the stuff we want is
		let enumr = FileManager.default.enumerator(at: temporaryUnzippingDir, includingPropertiesForKeys: nil)
		var parentDirWeWant: URL? = nil
		while let obj = enumr?.nextObject() as? URL {
			if obj.lastPathComponent.contains("APPLICATION-STAGING") {
				parentDirWeWant = obj
				break
			}
		}
		
		guard let parentDirWeWant, FileManager.default.fileExists(atPath: parentDirWeWant.path) else {
			throw StringError(.localized("Was unable to find parent directory containing containers & groups, sorry"))
		}
		let unzippedContainerURL = parentDirWeWant
			.appendingPathComponent("Container")
		
		NSLog("parentDirWeWant contents = \(try FileManager.default.contentsOfDirectory(at: parentDirWeWant, includingPropertiesForKeys: nil))")
		
		let unzippedGroupsURL = parentDirWeWant
			.appendingPathComponent("Groups")
		
		let applicationContainerURL = app.proxy.containerURL()
		// remove app's current container URL
		for item in try FileManager.default.contentsOfDirectory(at: applicationContainerURL,
																includingPropertiesForKeys: nil) {
			try FileManager.default.removeItem(at: item)
		}
		
		print("Cleared out app's containerURL, replacing with unzippedContainerURL")
		
		for item in try FileManager.default.contentsOfDirectory(at: unzippedContainerURL, includingPropertiesForKeys: nil) {
			try FileManager.default.copyItem(at: item,
											 to: applicationContainerURL.appendingPathComponent(item.lastPathComponent))
		}
		
		print("PART 2: Operating on the Groups dir")
		if FileManager.default.fileExists(atPath: unzippedGroupsURL.path) {
			for appGroupID in try FileManager.default.contentsOfDirectory(at: unzippedGroupsURL, includingPropertiesForKeys: nil) {
				if let existingContainerURL = app.proxy.groupContainerURLs()[appGroupID.lastPathComponent] {
					for item in try FileManager.default.contentsOfDirectory(at: existingContainerURL, includingPropertiesForKeys: nil) {
						try FileManager.default.removeItem(at: item)
					}
					
					for item in try FileManager.default.contentsOfDirectory(at: appGroupID, includingPropertiesForKeys: nil) {
						try FileManager.default.moveItem(at: item,
														 to: existingContainerURL.appendingPathComponent(item.lastPathComponent))
					}
				}
			}
		}
		
		print("WE ARE DONE. GOODNIGHT!")
		try FileManager.default.removeItem(at: temporaryUnzippingDir)
	}
}

