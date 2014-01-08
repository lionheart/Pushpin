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

- (NSString *)cacheKeyForPost:(NSDictionary *)post compressed:(BOOL)compressed width:(CGFloat)width;

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

- (PostMetadata *)cachedMetadataForPost:(NSDictionary *)post compressed:(BOOL)compressed width:(CGFloat)width {
    return self.cache[[self cacheKeyForPost:post compressed:compressed width:width]];
}

- (void)cacheMetadata:(PostMetadata *)metadata forPost:(NSDictionary *)post compressed:(BOOL)compressed width:(CGFloat)width {
    self.cache[[self cacheKeyForPost:post compressed:compressed width:width]] = metadata;
}

- (NSString *)cacheKeyForPost:(NSDictionary *)post compressed:(BOOL)compressed width:(CGFloat)width {
    if (post[@"hash"]) {
        return [NSString stringWithFormat:@"%@:%@:%@:%.2f", post[@"hash"], post[@"meta"], compressed ? @"1": @"0", width];
    }
    else {
        // It's a network item
        return [NSString stringWithFormat:@"%@:%@:%.2f", post[@"url"], compressed ? @"1": @"0", width];
    }
}

@end
