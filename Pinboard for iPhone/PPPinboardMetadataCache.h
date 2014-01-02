//
//  PPPinboardMetadataCache.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/2/14.
//
//

#import <Foundation/Foundation.h>

@class PostMetadata;

@interface PPPinboardMetadataCache : NSObject

+ (instancetype)sharedCache;

- (PostMetadata *)cachedMetadataForPost:(NSDictionary *)post compressed:(BOOL)compressed;
- (void)cacheMetadata:(PostMetadata *)metadata forPost:(NSDictionary *)post compressed:(BOOL)compressed;

@end
