//
//  Application.swift
//  AppIndex
//
//  Created by Serena on 27/03/2023.
//  

import UIKit
import CustomLaunchServicesBridge
import CompressionWrapper

/// Represents a general application.
public struct Application: Hashable {
	public static func == (lhs: Application, rhs: Application) -> Bool {
		return lhs.bundleID == rhs.bundleID
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(bundleID)
	}
	
	public static var all = LSApplicationWorkspace.default().allApplications().map {
		Application(applicationProxy: $0)
	}
	
	public static func refreshAllApps() {
		all = LSApplicationWorkspace.default().allApplications().map {
			Application(applicationProxy: $0)
	 }
	}
	
	public let name: String
	public let bundleID: String
	
	public var iconImage: UIImage? {
		._applicationIconImage(forBundleIdentifier: proxy.applicationIdentifier(),
													   format: 12, scale: UIScreen.main.scale)
	}
	
	public let proxy: LSApplicationProxy
	
	public var type: AppType? {
		AppType(rawValue: proxy.applicationType)
	}
	
	func iconImage(forFormat fmt: CInt) -> UIImage? {
		return UIImage._applicationIconImage(forBundleIdentifier: bundleID, format: fmt, scale: UIScreen.main.scale)
	}
	
	init(applicationProxy: LSApplicationProxy) {
		self.name = applicationProxy.localizedName()
		self.bundleID = applicationProxy.applicationIdentifier()
		self.proxy = applicationProxy
	}
	
	public enum AppType: String, CustomStringConvertible {
		case user = "User"
		case system = "System"
		
		public var description: String {
			switch self {
			case .user:
				return .localized("User")
			case .system:
				return .localized("System")
			}
		}
		
		public var headerDescription: String {
			switch self {
			case .user:
				return .localized("User Applications")
			case .system:
				return .localized("System Applications")
			}
		}
		
		public var image: UIImage? {
			switch self {
			case .system:
				return UIImage(systemName: "gear")
			case .user:
				return UIImage(systemName: "app")
			}
		}
	}
	
	func exportAsIpa(senderViewController: UIViewController) {
		let alertController = senderViewController.presentAlertWithSpinner(title: .localized("Exporting..."), heightAnchor: 120)

		DispatchQueue.global(qos: .background).async {
			do {
				let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
					.appendingPathComponent("create-ipa-\(bundleID)-\(UUID().uuidString.prefix(5))")
				let payloadDir = tmpDir.appendingPathComponent("Payload")
				try FileManager.default.createDirectory(at: payloadDir, withIntermediateDirectories: true)
				try FileManager.default.copyItem(at: proxy.bundleURL(),
												 to: payloadDir.appendingPathComponent(proxy.bundleURL().lastPathComponent))
				let ipaDir = tmpDir.appendingPathComponent(proxy.localizedName()).appendingPathExtension("ipa")
				try Compression.shared.compress(paths: [payloadDir], outputPath: ipaDir, format: .zip) { url in
					DispatchQueue.main.async {
						alertController.message = url.lastPathComponent
					}
				}
				
				DispatchQueue.main.async {
					NSLog("We got here")
					alertController.dismiss(animated: true) {
						let vc = UIActivityViewController(activityItems: [
							ApplicationExportingActivityItemSource(app: self, ipaDir: ipaDir)
						], applicationActivities: [])
						
						vc.popoverPresentationController?.sourceView = senderViewController.view
						let bounds = senderViewController.view.bounds
						
						vc.popoverPresentationController?.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
						senderViewController.present(vc, animated: true)
					}
				}
			} catch {
				DispatchQueue.main.async {
					alertController.dismiss(animated: true)
					senderViewController.errorAlert(title: .localized("Error"), message: nil)
				}
			}
		}
	}
	
	@discardableResult
	func open() -> Bool {
		return LSApplicationWorkspace.default().openApplication(withBundleID: bundleID)
	}
	
	func uninstall() throws {
		let err: NSErrorPointer = nil
		LSApplicationWorkspace.default().uninstallApplication(bundleID, error: err, usingBlock: nil)
		if let error = err?.pointee {
			throw error
		}
	}
}
