//
//  LaunchServices.h
//  AppIndex
//
//  Created by Serena on 27/03/2023.
//  

#ifndef LaunchServices_h
#define LaunchServices_h

#import "_LSDiskUsage.h"
#import "LSPluginKitProxy.h"

#define UIKIT_AVAILABLE __has_include(<UIKit/UIKit.h>)
#define SWIFT_THROWING __attribute__((__swift_error__(nonnull_error)))

#if UIKIT_AVAILABLE
@import UIKit;
#elif __has_include(<AppKit/AppKit.h>)
@import AppKit;
#endif

@import Darwin;

NS_ASSUME_NONNULL_BEGIN

@interface LSApplicationProxy

@property (readonly, nonatomic) NSString *applicationType;

@property (getter=isBetaApp, readonly, nonatomic) BOOL betaApp;
@property (getter=isDeletable, readonly, nonatomic) BOOL deletable;
@property (getter=isRestricted, readonly, nonatomic) BOOL restricted;
@property (getter=isContainerized, readonly, nonatomic) BOOL containerized;
@property (getter=isAdHocCodeSigned, readonly, nonatomic) BOOL adHocCodeSigned;
@property (getter=isAppStoreVendable, readonly, nonatomic) BOOL appStoreVendable;
@property (getter=isLaunchProhibited, readonly, nonatomic) BOOL launchProhibited;

@property (readonly, nonatomic) NSSet <NSString *> *claimedURLSchemes;
@property (readonly, nonatomic) NSString *teamID;
@property (copy, nonatomic) NSString *sdkVersion;
@property (readonly, nonatomic) NSDictionary <NSString *, id> *entitlements;
@property (readonly, nonatomic) NSURL* _Nullable bundleContainerURL;
@property (nonatomic, readonly) _LSDiskUsage *diskUsage;
@property (nonatomic, readonly) NSDate *registeredDate;
@property (nullable, nonatomic, readonly) NSString * vendorName;
@property (nonatomic, readonly) NSString *minimumSystemVersion;
@property (nonatomic, readonly) NSString *shortVersionString;
@property (nonatomic, readonly) BOOL fileSharingEnabled;
@property (nonatomic, readonly) BOOL hasSettingsBundle;
@property (readonly, nonatomic) NSArray <LSPlugInKitProxy *> *plugInKitPlugins;
@property (nullable, nonatomic, readonly) NSString *ratingLabel;
@property (nullable, nonatomic, readonly) NSString *applicationVariant;
@property (nullable, nonatomic, readonly) NSString *genre;
@property (nonatomic, readonly) NSString *signerIdentity;
@property (nonatomic, readonly) NSNumber *itemID;

+ (LSApplicationProxy*)applicationProxyForIdentifier:(id)identifier;
- (NSString *)applicationIdentifier;
- (NSURL *)containerURL;
- (NSURL *)bundleURL;
- (NSDictionary<NSString *, NSURL*> *)groupContainerURLs;
- (NSString *)localizedName;
- (NSData *)iconDataForVariant:(id)variant;
- (NSData *)iconDataForVariant:(id)variant withOptions:(id)options;
@end


@interface LSApplicationWorkspace
+ (instancetype) defaultWorkspace;
- (NSArray <LSApplicationProxy *> *)allInstalledApplications;
- (NSArray <LSApplicationProxy *> *)allApplications;
- (BOOL)openApplicationWithBundleID:(NSString *)arg0 ;
- (BOOL)uninstallApplication:(NSString *)bundleID withOptions:(NSDictionary<NSString *, id> *_Nullable)arg1 error:(NSError **)arg2 usingBlock:(_Nullable id)arg3 __attribute__((swift_error(nonnull_error)));
@end

#if UIKIT_AVAILABLE


@interface UIImage (Private)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier
											   format:(int)format;
+ (instancetype)_applicationIconImageForBundleIdentifier:(NSString*)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end
#endif

NS_ASSUME_NONNULL_END


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness" // Shut the fuck up about 'Pointer is missing a nullability type specifier (_Nonnull, _Nullable, or _Null_unspecified)'
#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);
int proc_pidpath(pid_t pid, void *buffer, uint32_t buffersize);
#pragma clang diagnostic pop

// additional posix_spawn stuff
#endif /* LaunchServices_h */
