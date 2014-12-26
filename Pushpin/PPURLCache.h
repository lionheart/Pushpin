//
//  PPURLCache.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/26/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPURLCache : NSObject

@property (nonatomic) NSUInteger memoryCapacity;
@property (nonatomic) NSUInteger diskCapacity;
@property (nonatomic) BOOL removeStaleItemsWhenCacheIsFull;

- (instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity
                          diskCapacity:(NSUInteger)diskCapacity
                              diskPath:(NSString *)path;

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request;
- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request;
- (void)removeCachedResponseForRequest:(NSURLRequest *)request;
- (void)removeAllCachedResponses;
- (NSUInteger)currentDiskUsage;
- (NSUInteger)currentMemoryUsage;

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forDataTask:(NSURLSessionDataTask *)dataTask;
- (void)getCachedResponseForDataTask:(NSURLSessionDataTask *)dataTask completionHandler:(void (^) (NSCachedURLResponse *cachedResponse))completionHandler;
- (void)removeCachedResponseForDataTask:(NSURLSessionDataTask *)dataTask;

+ (FMDatabaseQueue *)databaseQueue;
+ (void)migrateDatabase;

@end
