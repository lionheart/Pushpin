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

- (NSString *)cacheKeyForPost:(NSDictionary *)post compressed:(BOOL)compressed orientation:(UIInterfaceOrientation)orientation;

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

- (PostMetadata *)cachedMetadataForPost:(NSDictionary *)post compressed:(BOOL)compressed orientation:(UIInterfaceOrientation)orientation {
    return self.cache[[self cacheKeyForPost:post compressed:compressed orientation:orientation]];
}

- (void)cacheMetadata:(PostMetadata *)metadata forPost:(NSDictionary *)post compressed:(BOOL)compressed orientation:(UIInterfaceOrientation)orientation {
    self.cache[[self cacheKeyForPost:post compressed:compressed orientation:orientation]] = metadata;
}

- (NSString *)cacheKeyForPost:(NSDictionary *)post compressed:(BOOL)compressed orientation:(UIInterfaceOrientation)orientation {
    BOOL portrait = UIInterfaceOrientationIsPortrait(orientation);
    if (post[@"hash"]) {
        return [NSString stringWithFormat:@"%@:%@:%@:%@", post[@"hash"], post[@"meta"], compressed ? @"1": @"0", portrait ? @"1" : @"0"];
    }
    else {
        // It's a network item
        return [NSString stringWithFormat:@"%@:%@:%@", post[@"url"], compressed ? @"1": @"0", portrait ? @"1" : @"0"];
    }
}

@end
