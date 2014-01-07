//
//  PPMobilizerUtility.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/5/14.
//
//

#import <Foundation/Foundation.h>
#import "PPConstants.h"

@interface PPMobilizerUtility : NSObject

+ (instancetype)sharedInstance;

- (BOOL)canMobilizeURL:(NSURL *)url;

- (BOOL)isURLMobilized:(NSURL *)url;
- (NSString *)originalURLStringForURL:(NSURL *)url;
- (NSString *)urlStringForMobilizerForURL:(NSURL *)url;

- (BOOL)isURLMobilized:(NSURL *)url mobilizer:(PPMobilizerType)mobilizer;
- (NSString *)originalURLStringForURL:(NSURL *)url forMobilizer:(PPMobilizerType)mobilizer;
- (NSString *)urlStringForMobilizerForURL:(NSURL *)url forMobilizer:(PPMobilizerType)mobilizer;

@end
