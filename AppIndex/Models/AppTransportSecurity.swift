//
//  AppTransportSecurity.swift
//  AppIndex
//
//  Created by Serena on 01/04/2023.
//  

import Foundation

/// Represents an app transport security exception
public struct AppTransportSecurity: Hashable {
	public let domain: String
	
//	let allowsArbitraryLoads: Bool?
//	let allowsArbitraryLoadsForMedia: Bool?
//	let allowsArbitraryLoadsInWebContent: Bool?
//
	//let allowLocalNetworking: Bool?
	public let allowInsecureHTTPLoads: Bool?
	public let includesSubdomains: Bool?
	
	public let minTLSVersion: String?
	
	public init(domain: String, dictionary: [String: Any]) {
		self.domain = domain
		NSLog("dict = \(dictionary)")
		self.allowInsecureHTTPLoads = (dictionary["NSThirdPartyExceptionAllowsInsecureHTTPLoads"] as? Bool) ?? dictionary["NSExceptionAllowsInsecureHTTPLoads"] as? Bool
		self.includesSubdomains = dictionary["NSIncludesSubdomains"] as? Bool
		self.minTLSVersion = dictionary["NSThirdPartyExceptionMinimumTLSVersion"] as? String
	}
}
