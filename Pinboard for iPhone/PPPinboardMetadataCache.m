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

- (NSString *)cacheKeyForPost:(NSDictionary *)post compressed:(BOOL)compressed;

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

- (PostMetadata *)cachedMetadataForPost:(NSDictionary *)post compressed:(BOOL)compressed {
    return self.cache[[self cacheKeyForPost:post compressed:compressed]];
}

- (void)cacheMetadata:(PostMetadata *)metadata forPost:(NSDictionary *)post compressed:(BOOL)compressed {
    self.cache[[self cacheKeyForPost:post compressed:compressed]] = metadata;
}

- (NSString *)cacheKeyForPost:(NSDictionary *)post compressed:(BOOL)compressed {
    return [NSString stringWithFormat:@"%@:%@:%@", post[@"hash"], post[@"meta"], compressed ? @"1": @"0"];
}

@end
