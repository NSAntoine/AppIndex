//
//  LSPlugInKitProxy.h
//  AppIndex
//
//  Created by Serena on 01/04/2023.
//  

#ifndef LSPlugInKitProxy_h
#define LSPlugInKitProxy_h
@import Foundation;

@interface LSPlugInKitProxy : NSObject
@property (nonatomic, readonly) NSString *localizedShortName;
@property (nonatomic, readonly) NSString *protocol;
@property (nonatomic, readonly) NSUUID *pluginUUID;
@property (nonatomic, readonly) NSString *pluginIdentifier;
@property (nonatomic, readonly) NSURL *bundleURL;
@end

#endif /* LSPlugInKitProxy_h */
