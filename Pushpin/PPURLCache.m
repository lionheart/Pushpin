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

#import "NSString+Additions.h"
#import "NSString+URLEncoding2.h"
#import <FMDB/FMDatabaseQueue.h>
#import <RNCryptor/RNDecryptor.h>
#import <RNCryptor/RNCryptor.h>
#import <LHSCategoryCollection/NSData+Base64.h>

@interface PPURLCache ()

@property (nonatomic, strong) NSString *path;
@property (nonatomic) NSUInteger _currentDiskUsage;
@property (nonatomic, strong) NSCache *cache;
@property (nonatomic) BOOL isBackgroundSessionInvalidated;

@property (nonatomic, strong) NSString *currentAssetURLString;
@property (nonatomic, strong) NSString *currentURLString;

@property (nonatomic, strong) NSMutableArray *urlsToDownload;
@property (nonatomic, strong) NSMutableSet *assetURLs;
@property (nonatomic, strong) NSMutableSet *htmlURLs;
@property (nonatomic, strong) NSMutableSet *completedHTMLURLs;
@property (nonatomic, strong) NSMutableSet *completedAssetURLs;

@property (nonatomic, copy) void (^ProgressBlock)(NSString *, NSString *, NSInteger, NSInteger, NSInteger, NSInteger);

+ (NSString *)directoryPath;
+ (NSString *)databasePath;
+ (NSString *)directoryPathForChecksum:(NSString *)checksum;
+ (NSString *)filePathForChecksum:(NSString *)checksum;
+ (NSString *)md5ChecksumForData:(NSData *)data;

+ (NSOperationQueue *)operationQueue;

- (NSCache *)cache;

- (NSURLSession *)offlineSession;
- (NSURLSession *)readerViewOfflineSession;
- (NSURLSession *)offlineSessionForeground;
- (NSURLSession *)readerViewOfflineSessionForeground;
- (void)downloadCompletedForURL:(NSURL *)url;
- (void)queueNextHTMLDownload;

@end

@implementation PPURLCache

#pragma mark - Singletons

+ (FMDatabaseQueue *)databaseQueue {
    static dispatch_once_t onceToken;
    static FMDatabaseQueue *queue;
    dispatch_once(&onceToken, ^{
        queue = [FMDatabaseQueue databaseQueueWithPath:[self databasePath]];
    });
    return queue;
}

+ (NSOperationQueue *)operationQueue {
    static NSOperationQueue *queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 5;
    });
    return queue;
}

- (NSURLSession *)offlineSession {
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"io.aurora.Pushpin.OfflineFetchIdentifier"];
        sessionConfiguration.sessionSendsLaunchEvents = YES;

        session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[PPURLCache operationQueue]];
    });

    return session;
}

- (NSURLSession *)readerViewOfflineSession {
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"io.aurora.Pushpin.SecondaryOfflineFetchIdentifier"];
        sessionConfiguration.sessionSendsLaunchEvents = YES;

        NSString *authorizationString = @"pushpin:9346edb36e542dab1e7861227f9222b7";
        NSData *authorizationData = [authorizationString dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authorizationValue = [NSString stringWithFormat:@"Basic %@", [authorizationData base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength]];

        sessionConfiguration.HTTPAdditionalHeaders = @{@"Authorization": authorizationValue};

        session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[PPURLCache operationQueue]];
    });
    return session;
}

- (NSURLSession *)offlineSessionForeground {
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[PPURLCache operationQueue]];
    });

    return session;
}

- (NSURLSession *)readerViewOfflineSessionForeground {
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

        NSString *authorizationString = @"pushpin:9346edb36e542dab1e7861227f9222b7";
        NSData *authorizationData = [authorizationString dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authorizationValue = [NSString stringWithFormat:@"Basic %@", [authorizationData base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength]];

        sessionConfiguration.HTTPAdditionalHeaders = @{@"Authorization": authorizationValue};

        session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[PPURLCache operationQueue]];
    });
    return session;
}


- (void)initiateBackgroundDownloadsWithCompletion:(void (^)(NSInteger))completion progress:(void (^)(NSString *urlString, NSString *assetURLString, NSInteger, NSInteger, NSInteger, NSInteger))progress {
    NSMutableSet *candidateUrlsToCache = [NSMutableSet set];
    NSMutableSet *candidateReaderUrlsToCache = [NSMutableSet set];
    NSMutableArray *urlsToCache = [NSMutableArray array];
    NSMutableArray *readerUrlsToCache = [NSMutableArray array];

    self.currentURLString = @"";
    self.currentAssetURLString = @"";
    self.urlsToDownload = [NSMutableArray array];
    self.assetURLs = [NSMutableSet set];
    self.htmlURLs = [NSMutableSet set];
    self.completedAssetURLs = [NSMutableSet set];
    self.completedHTMLURLs = [NSMutableSet set];

    if (progress) {
        self.ProgressBlock = progress;
    }
    self.backgroundURLSessionCompletionHandlers = [NSMutableDictionary dictionary];
    BOOL hasAvailableSpace = self.currentDiskUsage < self.diskCapacity * 0.99;

    if (hasAvailableSpace) {
        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
            PPSettings *settings = [PPSettings sharedSettings];

            NSString *query;

            // Timestamp for last 30 days.
            NSInteger timestamp = [[NSDate date] timeIntervalSince1970] - (60 * 60 * 24 * 30);

            switch (settings.offlineFetchCriteria) {
                case PPOfflineFetchCriteriaUnread:
                    query = @"SELECT url FROM bookmark WHERE unread=1";
                    break;

                case PPOfflineFetchCriteriaRecent:
                    query = [NSString stringWithFormat:@"SELECT url FROM bookmark WHERE created_at>%lu", (long)timestamp];
                    break;

                case PPOfflineFetchCriteriaUnreadAndRecent:
                    query = [NSString stringWithFormat:@"SELECT url FROM bookmark WHERE created_at>%lu OR unread=1", (long)timestamp];
                    break;

                case PPOfflineFetchCriteriaEverything:
                    query = @"SELECT url FROM bookmark";
                    break;
            }
            FMResultSet *results = [db executeQuery:query];
            while ([results next]) {
                NSString *urlString = [results stringForColumn:@"url"];
                NSURL *url = [NSURL URLWithString:urlString];

                // https://pushpin-readability.herokuapp.com/v1/parser?url=%@&format=json&onerr=
                NSString *readerURLString = [NSString stringWithFormat:@"http://pushpin-readability.herokuapp.com/v1/parser?url=%@&format=json&onerr=", [url.absoluteString urlEncodeUsingEncoding:NSUTF8StringEncoding]];
                NSURL *readerURL = [NSURL URLWithString:readerURLString];

                if (url) {
                    [candidateUrlsToCache addObject:url];
                }

                if (readerURL) {
                    [candidateReaderUrlsToCache addObject:readerURL];
                }
            }
            [results close];
        }];

        [[PPURLCache databaseQueue] inDatabase:^(FMDatabase *db) {
            for (NSURL *url in candidateUrlsToCache) {
                FMResultSet *result = [db executeQuery:@"SELECT COUNT(*) FROM cache WHERE url=?" withArgumentsInArray:@[url.absoluteString]];
                [result next];
                NSInteger count = [result intForColumnIndex:0];
                [result close];
                if (count == 0) {
                    [urlsToCache addObject:url];
                }
            }

            for (NSURL *url in candidateReaderUrlsToCache) {
                FMResultSet *result = [db executeQuery:@"SELECT COUNT(*) FROM cache WHERE url=?" withArgumentsInArray:@[url.absoluteString]];
                [result next];
                NSInteger count = [result intForColumnIndex:0];
                [result close];
                if (count == 0) {
                    [readerUrlsToCache addObject:url];
                }
            }
        }];

        self.isBackgroundSessionInvalidated = NO;
        PPSettings *settings = [PPSettings sharedSettings];

        for (NSURL *url in readerUrlsToCache) {
            [self.htmlURLs addObject:url];
        }

        if (settings.downloadFullWebpageForOfflineCache) {
            for (NSURL *url in urlsToCache) {
                [self.htmlURLs addObject:url];
            }
        }

        self.urlsToDownload = [[self.htmlURLs allObjects] mutableCopy];
        [self queueNextHTMLDownload];
    }

    completion(self.htmlURLs.count);
}

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
        NSMutableSet *assetURLStrings = [PPUtilities staticAssetURLsForCachedURLResponse:response];

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

- (NSCache *)cache {
    static NSCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.totalCostLimit = self.memoryCapacity;
    });
    return cache;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        void (^completionHandler)() = self.backgroundURLSessionCompletionHandlers[session.configuration.identifier];
        if (completionHandler) {
            completionHandler();
        }
    }];
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]) {
        if (challenge.previousFailureCount == 0) {
            NSURLCredential *credential = [NSURLCredential credentialWithUser:@"pushpin"
                                                                     password:@"9346edb36e542dab1e7861227f9222b7"
                                                                  persistence:NSURLCredentialPersistenceNone];

            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        }
        else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    }
    else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSURL *url = task.originalRequest.URL;
        [self downloadCompletedForURL:url];

        if ([self.htmlURLs containsObject:url]) {
            [self queueNextHTMLDownload];
        }
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {

}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSURL *originalURL = downloadTask.originalRequest.URL;
    [self downloadCompletedForURL:originalURL];

    if ([self.assetURLs containsObject:downloadTask.originalRequest.URL]) {
        self.currentAssetURLString = downloadTask.originalRequest.URL.absoluteString;
        if (!self.currentAssetURLString) {
            self.currentAssetURLString = @"";
        }
    }

    NSError *error;
    NSData *data = [NSData dataWithContentsOfURL:location options:NSDataReadingUncached error:&error];
    if (data && data.length > 0 && downloadTask.response) {
        BOOL isReaderURL = [originalURL.absoluteString isReadabilityURL];
        NSCachedURLResponse *cachedURLResponse = [[NSCachedURLResponse alloc] initWithResponse:downloadTask.response data:data];

        NSMutableSet *assets;
        if (isReaderURL) {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSData *encodedData = [NSData dataWithBase64EncodedString:string];
            NSData *decryptedData = [RNDecryptor decryptData:encodedData
                                                withPassword:@"Isabelle and Dante"
                                                       error:nil];
            id article = [NSJSONSerialization JSONObjectWithData:decryptedData
                                                         options:NSJSONReadingAllowFragments
                                                           error:nil];

            assets = [PPUtilities staticAssetURLsForHTML:article[@"content"]];
        }
        else {
            assets = [PPUtilities staticAssetURLsForCachedURLResponse:cachedURLResponse];
        }

        if (assets.count > 0) {
            for (NSString *urlString in assets) {
                NSString *finalURLString = [urlString copy];
                if (originalURL.scheme && ![self.completedAssetURLs containsObject:[NSURL URLWithString:urlString]]) {
                    if ([finalURLString hasPrefix:@"//"]) {
                        finalURLString = [NSString stringWithFormat:@"%@:%@", originalURL.scheme, finalURLString];
                    }
                    else if ([finalURLString hasPrefix:@"/"]) {
                        finalURLString = [NSString stringWithFormat:@"%@://%@%@", originalURL.scheme, originalURL.host, finalURLString];
                    }
                    else if (![finalURLString hasPrefix:originalURL.scheme] && ![finalURLString hasPrefix:@"http://"] && ![finalURLString hasPrefix:@"https://"]) {
                        // This is a relative URL
                        NSMutableArray *trimmedComponents = [originalURL.pathComponents mutableCopy];
                        if ([[trimmedComponents firstObject] isEqualToString:@"/"]) {
                            [trimmedComponents removeObjectAtIndex:0];
                        }

                        if (![[trimmedComponents lastObject] hasSuffix:@"/"]) {
                            [trimmedComponents removeLastObject];
                        }

                        while ([finalURLString hasPrefix:@"../"]) {
                            finalURLString = [finalURLString stringByReplacingCharactersInRange:NSMakeRange(0, 3) withString:@""];
                            [trimmedComponents removeLastObject];
                        }

                        if (![finalURLString hasPrefix:@"/"]) {
                            // Add an extra component on the end of the trimmed components so that a / is added at the end of the string.
                            [trimmedComponents removeLastObject];
                            [trimmedComponents addObject:@""];
                        }
                        NSString *paths = [trimmedComponents componentsJoinedByString:@"/"];

                        // http://www.atgbrewery.com/../res/uploads/media/TSK.JPG
                        finalURLString = [NSString stringWithFormat:@"%@://%@/%@%@", originalURL.scheme, originalURL.host, paths, finalURLString];
                    }

                    NSURL *url = [NSURL URLWithString:finalURLString];
                    NSURLRequest *request = [NSURLRequest requestWithURL:url];

                    if (url && ![self cachedResponseForRequest:request] && !self.isBackgroundSessionInvalidated) {
                        [self.assetURLs addObject:url];
                    }
                }
            }

            self.currentAssetURLString = @"-";
            self.ProgressBlock(self.currentURLString, self.currentAssetURLString, self.completedHTMLURLs.count, self.htmlURLs.count, self.completedAssetURLs.count, self.assetURLs.count);

            // Since one of the tasks might complete before this is done looping, we make a copy of the list.
            for (NSURL *url in [self.assetURLs copy]) {
                NSURLSessionDownloadTask *task = [self.offlineSession downloadTaskWithURL:url];
                [task resume];
            }
        }

        BOOL hasAvailableSpace = self.currentDiskUsage < self.diskCapacity * 0.99;
        if (hasAvailableSpace && downloadTask.response) {
            // Only save if current usage is less than 99% of capacity.
            NSURLRequest *finalRequest = [NSURLRequest requestWithURL:originalURL];
            [self storeCachedResponse:cachedURLResponse forRequest:finalRequest];

            if (![downloadTask.originalRequest.URL.absoluteString isEqualToString:originalURL.absoluteString]) {
                NSURLRequest *request = [NSURLRequest requestWithURL:originalURL];
                [self storeCachedResponse:cachedURLResponse forRequest:request];
            }
        }
        else {
            [self stopAllDownloads];
        }
    }

    if (self.completedAssetURLs.count == self.assetURLs.count) {
        [self queueNextHTMLDownload];
    }
}

- (void)stopAllDownloads {
    [[self offlineSessionForeground] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for (NSURLSessionDataTask *task in dataTasks) {
            [task cancel];
        }

        for (NSURLSessionUploadTask *task in uploadTasks) {
            [task cancel];
        }

        for (NSURLSessionDownloadTask *task in downloadTasks) {
            [task cancel];
        }
    }];

    self.isBackgroundSessionInvalidated = YES;
    [[PPURLCache operationQueue] cancelAllOperations];

    // Set everything to 100%.
    self.ProgressBlock(@"", @"", 1, 1, 1, 1);
}

- (void)downloadCompletedForURL:(NSURL *)url {
    if ([self.htmlURLs containsObject:url]) {
        [self.completedHTMLURLs addObject:url];
    }
    else {
        if ([self.assetURLs containsObject:url]) {
            [self.completedAssetURLs addObject:url];
        }
    }

    self.ProgressBlock(self.currentURLString, self.currentAssetURLString, self.completedHTMLURLs.count, self.htmlURLs.count, self.completedAssetURLs.count, self.assetURLs.count);
}

- (void)queueNextHTMLDownload {
    if (!self.isBackgroundSessionInvalidated) {
        [self.completedAssetURLs removeAllObjects];
        [self.assetURLs removeAllObjects];

        NSURL *url = [self.urlsToDownload firstObject];
        if (url) {
            NSURLSession *session;
            if ([url.absoluteString isReadabilityURL]) {
                if (self.ProgressBlock) {
                    session = self.readerViewOfflineSessionForeground;
                }
                else {
                    session = self.readerViewOfflineSession;
                }
            }
            else {
                if (self.ProgressBlock) {
                    session = self.offlineSessionForeground;
                }
                else {
                    session = self.offlineSession;
                }
            }

            self.currentURLString = url.absoluteString;
            [self.urlsToDownload removeObjectAtIndex:0];
            NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
            [task resume];
        }

        self.ProgressBlock(self.currentURLString, self.currentAssetURLString, self.completedHTMLURLs.count, self.htmlURLs.count, self.completedAssetURLs.count, self.assetURLs.count);
    }
}

@end
