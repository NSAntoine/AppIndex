//
//  _LSDiskUsage.h
//  AppIndex
//
//  Created by Serena on 29/03/2023.
//  

#ifndef _LSDiskUsage_h
#define _LSDiskUsage_h
@import Foundation;

//NS_ASSUME_NONNULL_BEGIN

@interface _LSDiskUsage : NSObject
@property (readonly, nullable, nonatomic) NSNumber *staticUsage;
@property (readonly, nullable, nonatomic) NSNumber *dynamicUsage;
@property (readonly, nullable, nonatomic) NSNumber *onDemandResourcesUsage;
@property (readonly, nullable, nonatomic) NSNumber *sharedUsage;
@end

//NS_ASSUME_NONNULL_END

#endif /* _LSDiskUsage_h */
