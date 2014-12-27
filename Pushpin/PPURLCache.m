//
//  PPURLCache.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/26/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "PPURLCache.h"
#import "PPAppDelegate.h"

#import <FMDB/FMDatabaseQueue.h>

@interface PPURLCache ()

@property (nonatomic, strong) NSString *path;
@property (nonatomic) NSUInteger _currentDiskUsage;
@property (nonatomic, strong) NSCache *cache;

+ (NSString *)directoryPath;
+ (NSString *)databasePath;
+ (NSString *)directoryPathForChecksum:(NSString *)checksum;
+ (NSString *)filePathForChecksum:(NSString *)checksum;
+ (NSString *)md5ChecksumForData:(NSData *)data;

- (NSCache *)cache;

@end

@implementation PPURLCache

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request {
    if (cachedResponse.data) {
        NSData *responseData = [NSKeyedArchiver archivedDataWithRootObject:cachedResponse];
        NSString *checksum = [PPURLCache md5ChecksumForData:responseData];
        
        // Update the database entry
        // insert response size, md5, url, date
        NSString *urlString = request.URL.absoluteString;
        __block BOOL urlExistsInCache;
        
        // Multiple URLs might share the same response data
        __block BOOL responseDataInCache = YES;
        
        BOOL cacheIsFull = self.currentDiskUsage >= self.diskCapacity;
        
        // Before we do anything, we check if the cache is full.
        if (!cacheIsFull) {
            [[PPURLCache databaseQueue] inDatabase:^(FMDatabase *db) {
                FMResultSet *result = [db executeQuery:@"SELECT COUNT(*) FROM cache WHERE url=?" withArgumentsInArray:@[urlString]];
                [result next];
                urlExistsInCache = [result intForColumnIndex:0] > 0;
                [result close];
                
                result = [db executeQuery:@"SELECT COUNT(*) FROM cache WHERE url!=? AND md5=?" withArgumentsInArray:@[urlString, checksum]];
                [result next];
                responseDataInCache = [result intForColumnIndex:0] > 0;
                [result close];
                
                if (!urlExistsInCache || responseDataInCache) {
                    [db executeUpdate:@"INSERT INTO cache (url, md5, size) VALUES (?, ?, ?)" withArgumentsInArray:@[urlString, checksum, @(responseData.length)]];
                }
            }];
        }
        
        // Only update the cache if the file previously did not exist
        if (!cacheIsFull && !responseDataInCache) {
            NSString *filePath = [PPURLCache filePathForChecksum:checksum];
            
            BOOL isDirectory;
            BOOL directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:[PPURLCache directoryPathForChecksum:checksum] isDirectory:&isDirectory];
            if (!directoryExists) {
                [[NSFileManager defaultManager] createDirectoryAtPath:[PPURLCache directoryPathForChecksum:checksum]
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:nil];
            }
            [responseData writeToFile:filePath atomically:YES];
            self._currentDiskUsage += responseData.length;
        }
    }
}

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    NSData *data = [self.cache objectForKey:request.URL.absoluteString];
    
    if (data) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    else {
        __block NSString *path;
        __block NSInteger count;
        [[PPURLCache databaseQueue] inDatabase:^(FMDatabase *db) {
            FMResultSet *result = [db executeQuery:@"SELECT COUNT(*), * FROM cache WHERE url=?" withArgumentsInArray:@[request.URL.absoluteString]];
            [result next];
            count = [result intForColumnIndex:0];
            if (count > 0) {
                NSString *checksum = [result stringForColumn:@"md5"];
                path = [PPURLCache filePathForChecksum:checksum];
            }
            [result close];
        }];

        if (count > 0) {
            NSError *error;
            data = [NSData dataWithContentsOfFile:path options:0 error:&error];

            // Save the object to the cache for future retrieval.
            if (data) {
                [self.cache setObject:data forKey:request.URL.absoluteString cost:data.length];
                return [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
        }
    }
    return nil;
}

- (void)removeCachedResponseForRequest:(NSURLRequest *)request {
    __block NSString *filePath;
    __block NSUInteger size;
    [[PPURLCache databaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:@"SELECT md5 FROM cache WHERE url=?" withArgumentsInArray:@[request.URL.absoluteString]];
        [result next];
        NSString *checksum = [result stringForColumn:@"md5"];

        result = [db executeQuery:@"SELECT COUNT(*), size FROM cache WHERE md5=?"];
        [result next];
        NSInteger count = [result intForColumnIndex:0];
        size = [result intForColumnIndex:1];
        [result close];

        if (count > 0) {
            // There is more than one entry for this data, so we won't delete the cached response, only the DB row
            [db executeUpdate:@"DELETE FROM cache WHERE url=?" withArgumentsInArray:@[request.URL.absoluteString]];

            if (count == 1) {
                filePath = [PPURLCache filePathForChecksum:checksum];
            }
        }
        else {
            // No-op if the DB doesn't have an entry for the request.
        }
    }];
    
    if (filePath) {
        NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:nil];
        NSCachedURLResponse *response = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSMutableSet *assetURLStrings = [PPAppDelegate staticAssetURLsForCachedURLResponse:response];

        // Before we delete the data, we need to extract all URLs this file might be associated with (i.e., static assets, like CSS & JS)]
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        self._currentDiskUsage -= size;
        
        for (NSString *assetURLString in assetURLStrings) {
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:assetURLString]];
            [self removeCachedResponseForRequest:request];
        }
    }
}

- (void)removeAllCachedResponses {
    NSMutableSet *filePaths;
    [[PPURLCache databaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:@"SELECT md5 FROM cache"];
        while ([result next]) {
            NSString *checksum = [result stringForColumn:@"md5"];
            NSString *filePath = [PPURLCache filePathForChecksum:checksum];
            [filePaths addObject:filePath];
        }
        [result close];
        
        [db executeUpdate:@"DELETE FROM cache"];
    }];
    
    for (NSString *filePath in filePaths) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }

    self._currentDiskUsage = 0;
}

- (NSUInteger)currentDiskUsage {
    if (!self._currentDiskUsage) {
        [[PPURLCache databaseQueue] inDatabase:^(FMDatabase *db) {
            FMResultSet *result = [db executeQuery:@"SELECT SUM(size) FROM cache"];
            [result next];
            self._currentDiskUsage = [result intForColumnIndex:0];
            [result close];
        }];
    }

    return self._currentDiskUsage;
}

- (NSUInteger)currentMemoryUsage {
    return 0;
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forDataTask:(NSURLSessionDataTask *)dataTask {
    [self storeCachedResponse:cachedResponse forRequest:dataTask.originalRequest];

    if (![dataTask.originalRequest isEqual:dataTask.currentRequest]) {
        [self storeCachedResponse:cachedResponse forRequest:dataTask.currentRequest];
    }
}

- (void)removeCachedResponseForDataTask:(NSURLSessionDataTask *)dataTask {
    [self removeCachedResponseForRequest:dataTask.originalRequest];
    
    if (![dataTask.originalRequest isEqual:dataTask.currentRequest]) {
        [self removeCachedResponseForRequest:dataTask.currentRequest];
    }
}

- (void)getCachedResponseForDataTask:(NSURLSessionDataTask *)dataTask completionHandler:(void (^)(NSCachedURLResponse *))completionHandler {
    NSCachedURLResponse *response = [self cachedResponseForRequest:dataTask.currentRequest];
    completionHandler(response);
}

+ (void)migrateDatabase {
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[self directoryPath] isDirectory:&isDirectory];
    if (!exists) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[self directoryPath]
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:nil];
    }

    FMDatabase *db = [FMDatabase databaseWithPath:[self databasePath]];
    [db open];
    [db close];
    
    [[self databaseQueue] inDatabase:^(FMDatabase *db) {
        // http://stackoverflow.com/a/875422/39155
        [db executeUpdate:@"PRAGMA cache_size=100;"];
        
        // http://stackoverflow.com/a/875422/39155
        [db executeUpdate:@"PRAGMA syncronous=OFF;"];
        
        FMResultSet *s = [db executeQuery:@"PRAGMA user_version"];
        BOOL success = [s next];
        if (success) {
            int version = [s intForColumnIndex:0];
            [s close];
            
            [db beginTransaction];
            
            switch (version) {
                case 0:
                    [db executeUpdate:
                     @"CREATE TABLE cache("
                         "url TEXT UNIQUE,"
                         "md5 TEXT,"
                         "size INTEGER,"
                         "created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
                     ");"];

                    [db executeUpdate:@"CREATE INDEX cache_created_at_idx ON cache (created_at);"];
                    [db executeUpdate:@"CREATE INDEX cache_url_idx ON cache (url);"];
                    [db executeUpdate:@"CREATE INDEX cache_size_idx ON cache (size);"];
                    [db executeUpdate:@"CREATE INDEX cache_md5_idx ON cache (md5);"];

                    [db executeUpdate:@"PRAGMA user_version=1;"];
                    
                default:
                    break;
            }
            
            [db commit];
        }
    }];
}

+ (NSString *)directoryPath {
    NSString *pathComponent = @"/urlcache/";
#if TARGET_IPHONE_SIMULATOR
    return [@"/tmp" stringByAppendingString:pathComponent];
#else
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    if (paths.count > 0) {
        return [paths[0] stringByAppendingPathComponent:pathComponent];
    }
    else {
        return pathComponent;
    }
#endif
}

+ (NSString *)directoryPathForChecksum:(NSString *)checksum {
    return [[self directoryPath] stringByAppendingFormat:@"/data/%@/", [checksum substringToIndex:2]];
}

+ (NSString *)filePathForChecksum:(NSString *)checksum {
    return [[self directoryPathForChecksum:checksum] stringByAppendingString:[checksum substringFromIndex:2]];
}

+ (NSString *)databasePath {
    return [[self directoryPath] stringByAppendingString:@"/Cache.db"];
}

+ (NSString *)md5ChecksumForData:(NSData *)data {
    void *cData = malloc([data length]);
    unsigned char resultCString[16];
    [data getBytes:cData length:[data length]];
    
    CC_MD5(cData, (unsigned int)[data length], resultCString);
    free(cData);
    
    NSString *result = [NSString stringWithFormat:
                        @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                        resultCString[0], resultCString[1], resultCString[2], resultCString[3],
                        resultCString[4], resultCString[5], resultCString[6], resultCString[7],
                        resultCString[8], resultCString[9], resultCString[10], resultCString[11],
                        resultCString[12], resultCString[13], resultCString[14], resultCString[15]
                        ];
    return result;
}

+ (FMDatabaseQueue *)databaseQueue {
    static dispatch_once_t onceToken;
    static FMDatabaseQueue *queue;
    dispatch_once(&onceToken, ^{
        queue = [FMDatabaseQueue databaseQueueWithPath:[self databasePath]];
    });
    return queue;
}

- (NSCache *)cache {
    static NSCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.totalCostLimit = self.memoryCapacity;
    });
    return cache;
}

@end
