//
//  PPPinboardMetadataCache.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/2/14.
//
//

#import "PPPinboardMetadataCache.h"

#import "PostMetadata.h"

@interface PPPinboardMetadataCache ()

@property (nonatomic, strong) NSMutableDictionary *cache;

- (NSString *)cacheKeyForPost:(NSDictionary *)post compressed:(BOOL)compressed dimmed:(BOOL)dimmed width:(CGFloat)width;

@end

@implementation PPPinboardMetadataCache

- (id)init {
    self = [super init];
    if (self) {
        self.cache = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)sharedCache {
    static PPPinboardMetadataCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[PPPinboardMetadataCache alloc] init];
    });
    return cache;
}

- (void)reset {
    [self.cache removeAllObjects];
}

- (void)removeAllObjects {
    [self reset];
}

- (void)removeCachedMetadataForPost:(NSDictionary *)post width:(CGFloat)width {
    [self.cache removeObjectForKey:[self cacheKeyForPost:post compressed:YES dimmed:YES width:width]];
    [self.cache removeObjectForKey:[self cacheKeyForPost:post compressed:YES dimmed:NO width:width]];
    [self.cache removeObjectForKey:[self cacheKeyForPost:post compressed:NO dimmed:YES width:width]];
    [self.cache removeObjectForKey:[self cacheKeyForPost:post compressed:NO dimmed:NO width:width]];
}

- (PostMetadata *)cachedMetadataForPost:(NSDictionary *)post compressed:(BOOL)compressed dimmed:(BOOL)dimmed width:(CGFloat)width {
    return self.cache[[self cacheKeyForPost:post compressed:compressed dimmed:dimmed width:width]];
}

- (void)cacheMetadata:(PostMetadata *)metadata forPost:(NSDictionary *)post compressed:(BOOL)compressed dimmed:(BOOL)dimmed width:(CGFloat)width {
    self.cache[[self cacheKeyForPost:post compressed:compressed dimmed:dimmed width:width]] = metadata;
}

- (NSString *)cacheKeyForPost:(NSDictionary *)post compressed:(BOOL)compressed dimmed:(BOOL)dimmed width:(CGFloat)width {
    if (post[@"hash"]) {
        return [NSString stringWithFormat:@"%@:%@:%@:%@:%ld", post[@"hash"], post[@"meta"], compressed ? @"1": @"0", dimmed ? @"1" : @"0", (long)width];
    } else {
        // It's a network item
        return [NSString stringWithFormat:@"%@:%@:%@:%ld", post[@"url"], compressed ? @"1": @"0", dimmed ? @"1" : @"0", (long)width];
    }
}

@end
