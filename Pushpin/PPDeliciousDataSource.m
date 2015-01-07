//
//  DeliciousDataSource.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/25/14.
//
//

#import "PPDeliciousDataSource.h"
#import "PostMetadata.h"
#import "PPPinboardMetadataCache.h"
#import "PPAddBookmarkViewController.h"
#import "PPUtilities.h"
#import "PPSettings.h"

#import <FMDB/FMDatabase.h>
#import <LHSDelicious/LHSDelicious.h>

static BOOL kPinboardSyncInProgress = NO;

@interface PPDeliciousDataSource ()

@property (nonatomic, strong) PPPinboardMetadataCache *cache;
@property (nonatomic) CGFloat mostRecentWidth;

- (void)generateQueryAndParameters:(void (^)(NSString *, NSArray *))callback;
- (NSDictionary *)paramsForPost:(NSDictionary *)post dateError:(BOOL)dateError;

@end

@implementation PPDeliciousDataSource

- (id)init {
    self = [super init];
    if (self) {
        self.totalNumberOfPosts = 0;
        
        // Keys are hash:meta pairs
        self.cache = [PPPinboardMetadataCache sharedCache];
        self.metadata = [NSMutableArray array];
        self.compressedMetadata = [NSMutableArray array];
        self.posts = [NSMutableArray array];
        
        self.tags = @[];
        self.untagged = kPushpinFilterNone;
        self.isPrivate = kPushpinFilterNone;
        self.unread = kPushpinFilterNone;
        self.offset = 0;
        self.limit = 50;
        self.orderBy = @"created_at DESC";
        self.searchQuery = nil;
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        self.locale = [NSLocale currentLocale];
        [self.dateFormatter setLocale:self.locale];
        [self.dateFormatter setDoesRelativeDateFormatting:YES];
        
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        self.enUSPOSIXDateFormatter = [[NSDateFormatter alloc] init];
        [self.enUSPOSIXDateFormatter setLocale:enUSPOSIXLocale];
        [self.enUSPOSIXDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [self.enUSPOSIXDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        self.tagsWithFrequency = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)filterWithParameters:(NSDictionary *)parameters {
    kPushpinFilterType isPrivate = kPushpinFilterNone;
    if (parameters[@"private"]) {
        isPrivate = [parameters[@"private"] boolValue];
    }
    
    kPushpinFilterType unread = kPushpinFilterNone;
    if (parameters[@"unread"]) {
        unread = [parameters[@"unread"] boolValue];
    }
    
    kPushpinFilterType untagged = kPushpinFilterNone;
    if (parameters[@"tagged"]) {
        untagged = ![parameters[@"tagged"] boolValue];
    }
    
    NSArray *tags = parameters[@"tags"];
    NSInteger offset = [parameters[@"offset"] integerValue];
    NSInteger limit = [parameters[@"limit"] integerValue];

    [self filterByPrivate:isPrivate
                 isUnread:unread
                 untagged:untagged
                     tags:tags
                   offset:offset
                    limit:limit];
}

- (void)filterWithQuery:(NSString *)query {
    query = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (self.shouldSearchFullText) {
        self.searchQuery = query;
    }
    else {
        NSError *error;
        NSRegularExpression *complexExpression = [NSRegularExpression regularExpressionWithPattern:@"((\\w+:\"[^\\\\\"]+\")|(\"[^ ]+\"))" options:0 error:&error];
        NSArray *complexExpressions = [complexExpression matchesInString:query options:0 range:NSMakeRange(0, query.length)];
        
        NSMutableOrderedSet *components = [NSMutableOrderedSet orderedSet];
        NSMutableArray *rangeValuesToDelete = [NSMutableArray array];
        
        for (NSTextCheckingResult *result in complexExpressions) {
            NSString *value = [query substringWithRange:result.range];
            [rangeValuesToDelete addObject:[NSValue valueWithRange:result.range]];
            [components addObject:value];
        }
        
        NSMutableString *remainingQuery = [NSMutableString stringWithString:query];
        for (NSValue *value in [rangeValuesToDelete reverseObjectEnumerator]) {
            [remainingQuery replaceCharactersInRange:[value rangeValue] withString:@""];
        }
        
        NSRegularExpression *simpleExpression = [NSRegularExpression regularExpressionWithPattern:@"((\\w+:[^\" ]+)|([^ \"]+))" options:0 error:&error];
        NSArray *simpleExpressions = [simpleExpression matchesInString:remainingQuery options:0 range:NSMakeRange(0, remainingQuery.length)];
        
        for (NSTextCheckingResult *result in simpleExpressions) {
            NSString *value = [query substringWithRange:result.range];
            
            BOOL isKeyword = NO;
            for (NSString *keyword in @[@"AND", @"OR", @"NOT"]) {
                if ([keyword isEqualToString:[value uppercaseString]]) {
                    isKeyword = YES;
                    break;
                }
            }
            
            if (isKeyword) {
                [components addObject:[value uppercaseString]];
            }
            else {
                if (![value hasSuffix:@"*"]) {
                    value = [value stringByAppendingString:@"*"];
                }
                
                [components addObject:value];
            }
            
        }
        
        NSMutableArray *finalArray = [NSMutableArray array];
        for (NSString *item in components) {
            [finalArray addObject:item];
        }
        
        self.searchQuery = [finalArray componentsJoinedByString:@" "];
    }
}

- (PPDeliciousDataSource *)searchDataSource {
    PPDeliciousDataSource *search = [self copy];
    search.searchQuery = @"*";
    return search;
}

- (PPDeliciousDataSource *)dataSourceWithAdditionalTag:(NSString *)tag {
    NSArray *newTags = [self.tags arrayByAddingObject:tag];
    PPDeliciousDataSource *dataSource = [self copy];
    dataSource.tags = newTags;
    return dataSource;
}

- (void)filterByPrivate:(kPushpinFilterType)isPrivate
               isUnread:(kPushpinFilterType)isUnread
               untagged:(kPushpinFilterType)untagged
                   tags:(NSArray *)tags
                 offset:(NSInteger)offset
                  limit:(NSInteger)limit {
    self.limit = limit;
    self.untagged = untagged;
    self.isPrivate = isPrivate;
    self.unread = isUnread;
    self.tags = tags;
    self.offset = offset;
    self.limit = limit;
}

- (void)willDisplayIndexPath:(NSIndexPath *)indexPath callback:(void (^)(BOOL))callback {
    BOOL needsUpdate = indexPath.row >= self.limit * 3. / 4.;
    if (needsUpdate) {
        if (self.searchQuery) {
            self.limit += 10;
        }
        else {
            self.limit += 50;
        }
    }
    callback(needsUpdate);
}

- (NSInteger)numberOfPosts {
    return self.metadata.count;
}

- (NSInteger)totalNumberOfPosts {
    if (!_totalNumberOfPosts) {
        __block NSInteger count;
        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
            FMResultSet *result = [db executeQuery:@"SELECT COUNT(*) FROM bookmark;"];
            [result next];
            count = [result intForColumnIndex:0];
            [result close];
        }];

        _totalNumberOfPosts = count;
    }
    return _totalNumberOfPosts;
}

- (void)syncBookmarksWithCompletion:(void (^)(BOOL updated, NSError *))completion
                           progress:(void (^)(NSInteger, NSInteger))progress {
    [self syncBookmarksWithCompletion:completion
                             progress:progress
                              options:nil];
}

- (void)syncBookmarksWithCompletion:(void (^)(BOOL updated, NSError *))completion
                           progress:(void (^)(NSInteger, NSInteger))progress
                            options:(NSDictionary *)options {
    if (!progress) {
        progress = ^(NSInteger current, NSInteger total) {};
    }

    // Dispatch serially to ensure that no two syncs happen simultaneously.
    dispatch_async(PPBookmarkUpdateQueue(), ^{
        LHSDelicious *delicious = [LHSDelicious sharedInstance];
        
        void (^BookmarksSuccessBlock)(NSArray *) = ^(NSArray *posts) {
            DLog(@"%@ - Received data", [NSDate date]);
            NSDate *startDate = [NSDate date];

            __block NSUInteger total;
            __block NSMutableArray *previousBookmarks;

            [[PPUtilities databaseQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
                [db executeUpdate:@"DELETE FROM bookmark WHERE hash IS NULL"];

                FMResultSet *results;
                
                NSMutableArray *tags = [NSMutableArray array];
                results = [db executeQuery:@"SELECT name FROM tag"];
                while ([results next]) {
                    [tags addObject:[results stringForColumn:@"name"]];
                }
                
                [results close];
                
                DLog(@"%@ - Getting local data", [NSDate date]);
                total = posts.count;
                results = [db executeQuery:@"SELECT meta, hash, url FROM bookmark ORDER BY created_at DESC"];
                
                previousBookmarks = [NSMutableArray array];
                while ([results next]) {
                    [previousBookmarks addObject:@{@"hash": [results stringForColumn:@"hash"],
                                                   @"meta": [results stringForColumn:@"meta"]}];
                }

                [results close];
            }];

            NSMutableDictionary *bookmarks = [NSMutableDictionary dictionary];
            for (NSDictionary *post in posts) {
                bookmarks[post[@"hash"]] = post;
            }

            NSNotificationQueue *queue = [NSNotificationQueue defaultQueue];

            [queue enqueueNotification:[NSNotification notificationWithName:kDeliciousDataSourceProgressNotification
                                                                     object:nil
                                                                   userInfo:@{@"current": @(0), @"total": @(total)}]
                          postingStyle:NSPostASAP];

            [PPUtilities generateDiffForPrevious:previousBookmarks
                                         updated:posts
                                            hash:^NSString *(id obj) { return obj[@"hash"]; }
                                            meta:^NSString *(id obj) { return obj[@"meta"]; }
                                      completion:^(NSSet *inserted, NSSet *updated, NSSet *deleted) {
                                          __block CGFloat index = 0;
                                          NSUInteger skipped = 0;
                                          __block NSUInteger updateCount = 0;
                                          __block NSUInteger addCount = 0;
                                          __block NSUInteger deleteCount = 0;
                                          __block NSUInteger tagAddCount = 0;
                                          __block NSUInteger tagDeleteCount = 0;
                                          
                                          [[PPUtilities databaseQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
                                              // Only track one date error per update
                                              BOOL dateError = NO;
                                              
                                              CGFloat amountToAdd = (CGFloat)inserted.count / posts.count;
                                              for (NSString *hash in inserted) {
                                                  NSDictionary *post = bookmarks[hash];

                                                  NSString *postTags = [PPUtilities stringByTrimmingWhitespace:post[@"tag"]];
                                                  NSDictionary *params = [self paramsForPost:post dateError:dateError];
                                                  if (!dateError && !params) {
                                                      dateError = YES;
                                                  }
                                                  
                                                  [db executeUpdate:@"INSERT INTO bookmark (title, description, url, private, unread, hash, tags, meta, created_at) VALUES (:title, :description, :url, :private, :unread, :hash, :tags, :meta, :created_at);" withParameterDictionary:params];
                                                  addCount++;
                                                  
                                                  [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[hash]];
                                                  tagDeleteCount++;
                                                  
                                                  for (NSString *tagName in [postTags componentsSeparatedByString:@" "]) {
                                                      NSString *cleanedTagName = [PPUtilities stringByTrimmingWhitespace:tagName];
                                                      if (![cleanedTagName isEqualToString:@""]) {
                                                          [db executeUpdate:@"INSERT OR IGNORE INTO tag (name) VALUES (?)" withArgumentsInArray:@[tagName]];
                                                          [db executeUpdate:@"INSERT INTO tagging (tag_name, bookmark_hash) VALUES (?, ?)" withArgumentsInArray:@[tagName, hash]];
                                                          tagAddCount++;
                                                      }
                                                  }
                                                  
                                                  index += amountToAdd;
                                                  progress((NSInteger)index, total);
                                                  NSNotification *note = [NSNotification notificationWithName:kDeliciousDataSourceProgressNotification
                                                                                                       object:nil
                                                                                                     userInfo:@{@"current": @(index), @"total": @(total)}];
                                                  [queue enqueueNotification:note postingStyle:NSPostASAP];
                                              }
                                              
                                              amountToAdd = (CGFloat)deleted.count / posts.count;
                                              for (NSString *hash in deleted) {
                                                  [db executeUpdate:@"DELETE FROM bookmark WHERE hash=?" withArgumentsInArray:@[hash]];
                                                  deleteCount++;
                                                  index += amountToAdd;
                                                  progress((NSInteger)index, total);
                                                  NSNotification *note = [NSNotification notificationWithName:kDeliciousDataSourceProgressNotification
                                                                                                       object:nil
                                                                                                     userInfo:@{@"current": @(index), @"total": @(total)}];
                                                  [queue enqueueNotification:note postingStyle:NSPostASAP];
                                              }
                                              
                                              amountToAdd = (CGFloat)updated.count / posts.count;
                                              for (NSString *hashmeta in updated) {
                                                  NSString *hash = [hashmeta componentsSeparatedByString:@"_"][0];
                                                  NSDictionary *post = bookmarks[hash];
                                                  
                                                  NSDate *date = [self.enUSPOSIXDateFormatter dateFromString:post[@"time"]];
                                                  if (!dateError && !date) {
                                                      date = [NSDate dateWithTimeIntervalSince1970:0];
                                                      [[Mixpanel sharedInstance] track:@"NSDate error in updateLocalDatabaseFromRemoteAPIWithSuccess" properties:@{@"Locale": [NSLocale currentLocale]}];
                                                      dateError = YES;
                                                  }
                                                  
                                                  NSString *postTags = [PPUtilities stringByTrimmingWhitespace:post[@"tag"]];
                                                  
                                                  NSDictionary *params = [self paramsForPost:post dateError:dateError];
                                                  if (!dateError && !params) {
                                                      dateError = YES;
                                                  }
                                                  
                                                  // Update this bookmark
                                                  [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, url=:url, private=:private, unread=:unread, tags=:tags, meta=:meta WHERE hash=:hash" withParameterDictionary:params];
                                                  updateCount++;
                                                  
                                                  [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[hash]];
                                                  tagDeleteCount++;
                                                  
                                                  for (NSString *tagName in [postTags componentsSeparatedByString:@" "]) {
                                                      NSString *cleanedTagName = [PPUtilities stringByTrimmingWhitespace:tagName];
                                                      if (![cleanedTagName isEqualToString:@""]) {
                                                          [db executeUpdate:@"INSERT OR IGNORE INTO tag (name) VALUES (?)" withArgumentsInArray:@[tagName]];
                                                          [db executeUpdate:@"INSERT INTO tagging (tag_name, bookmark_hash) VALUES (?, ?)" withArgumentsInArray:@[tagName, hash]];
                                                          tagAddCount++;
                                                      }
                                                  }
                                                  
                                                  index += amountToAdd;
                                                  progress((NSInteger)index, total);
                                                  NSNotification *note = [NSNotification notificationWithName:kDeliciousDataSourceProgressNotification
                                                                                                       object:nil
                                                                                                     userInfo:@{@"current": @(index), @"total": @(total)}];
                                                  [queue enqueueNotification:note postingStyle:NSPostASAP];
                                              }
                                              
                                              DLog(@"Updating tags");
                                              [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash NOT IN (SELECT hash FROM bookmark)"];
                                              [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_name=tag.name)"];
                                              [db executeUpdate:@"DELETE FROM tag WHERE count=0"];
                                          }];
                                          
                                          NSDate *endDate = [NSDate date];
                                          skipped = total - addCount - updateCount - deleteCount;
                                          
                                          DLog(@"%f", [endDate timeIntervalSinceDate:startDate]);
                                          DLog(@"added %lu", (unsigned long)addCount);
                                          DLog(@"updated %lu", (unsigned long)updateCount);
                                          DLog(@"skipped %lu", (unsigned long)skipped);
                                          DLog(@"removed %lu", (unsigned long)deleteCount);
                                          DLog(@"tags added %lu", (unsigned long)tagAddCount);
                                          
                                          self.totalNumberOfPosts = index;
                                          
                                          [[PPSettings sharedSettings] setLastUpdated:[NSDate date]];
                                          kPinboardSyncInProgress = NO;
                                          
                                          progress(total, total);
                                          
                                          NSNotification *note = [NSNotification notificationWithName:kDeliciousDataSourceProgressNotification
                                                                                               object:nil
                                                                                             userInfo:@{@"current": @(total), @"total": @(total)}];
                                          [queue enqueueNotification:note postingStyle:NSPostASAP];
                                          
                                          [[Mixpanel sharedInstance] track:@"Synced bookmarks" properties:@{@"Duration": @([endDate timeIntervalSinceDate:startDate])}];
                                          
                                          BOOL updatesMade = addCount > 0 || updateCount > 0 || deleteCount > 0;
                                          completion(updatesMade, nil);
                                      }];
        };

        void (^BookmarksFailureBlock)(NSError *) = ^(NSError *error) {
            completion(NO, error);
            kPinboardSyncInProgress = NO;
        };

        void (^BookmarksUpdatedTimeSuccessBlock)(NSDate *) = ^(NSDate *updateTime) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSDate *lastLocalUpdate = [[PPSettings sharedSettings] lastUpdated];
                BOOL neverUpdated = lastLocalUpdate == nil;
                BOOL outOfSyncWithAPI = [lastLocalUpdate compare:updateTime] == NSOrderedAscending;
                BOOL lastUpdatedMoreThanFiveMinutesAgo = abs([lastLocalUpdate timeIntervalSinceNow]) >= 300;

                if (neverUpdated || outOfSyncWithAPI || lastUpdatedMoreThanFiveMinutesAgo) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [delicious bookmarksWithTag:nil
                                             offset:-1
                                              count:100000
                                           fromDate:nil
                                             toDate:nil
                                        includeMeta:YES
                                         completion:^(NSArray *bookmarks, NSError *error) {
                                             if (error) {
                                                 BookmarksFailureBlock(error);
                                             }
                                             else {
                                                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                     BookmarksSuccessBlock(bookmarks);
                                                 });
                                             }
                                         }];
                    });
                }
                else {
                    kPinboardSyncInProgress = NO;
                    completion(NO, nil);
                }
            });
        };
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [delicious lastUpdateWithCompletion:^(NSDate *date, NSError *error) {
                if (error) {
                    completion(NO, error);
                }
                else {
                    BookmarksUpdatedTimeSuccessBlock(date);
                }
            }];
        });
    });
}

- (void)reloadBookmarksWithCompletion:(void (^)(NSArray *, NSArray *, NSArray *, NSError *))completion
                               cancel:(BOOL (^)())cancel
                                width:(CGFloat)width {

    dispatch_async(PPBookmarkReloadQueue(), ^{
        self.mostRecentWidth = width;

        void (^HandleSearch)(NSString *, NSArray *) = ^(NSString *query, NSArray *parameters) {
            __block NSInteger row = 0;
            NSArray *previousBookmarks = [self.posts copy];
            NSMutableArray *updatedBookmarks = [NSMutableArray array];
            NSMutableDictionary *oldHashesToIndexPaths = [NSMutableDictionary dictionary];
            NSMutableDictionary *newHashesToIndexPaths = [NSMutableDictionary dictionary];
            NSMutableDictionary *newHashmetasToHashes = [NSMutableDictionary dictionary];
            NSMutableDictionary *newTagsWithFrequencies = [NSMutableDictionary dictionary];

            if (cancel && cancel()) {
                DLog(@"Cancelling search for query (%@)", self.searchQuery);
                completion(nil, nil, nil, [NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                return;
            }

            [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                FMResultSet *results = [db executeQuery:query withArgumentsInArray:parameters];

                if (cancel && cancel()) {
                    DLog(@"Cancelling search for query (%@)", self.searchQuery);
                    completion(nil, nil, nil, [NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                    return;
                }

                while ([results next]) {
                    NSString *hash = [results stringForColumn:@"hash"];
                    NSString *meta = [results stringForColumn:@"meta"];
                    NSString *hashmeta = [hash stringByAppendingString:meta];
                    NSDictionary *post = [PPUtilities dictionaryFromResultSet:results];
                    [updatedBookmarks addObject:post];
                    
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                    newHashesToIndexPaths[hash] = indexPath;
                    newHashmetasToHashes[hashmeta] = hash;
                    row++;
                }

                [results close];
                
                row = 0;
                for (NSDictionary *post in previousBookmarks) {
                    NSString *hash = post[@"hash"];
                    
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row
                                                                inSection:0];
                    oldHashesToIndexPaths[hash] = indexPath;
                    row++;
                }
                
                if (cancel && cancel()) {
                    DLog(@"Cancelling search for query (%@)", self.searchQuery);
                    completion(nil, nil, nil, [NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                    return;
                }
                
                FMResultSet *tagResult = [db executeQuery:@"SELECT name, count FROM tag ORDER BY count DESC;"];
                while ([tagResult next]) {
                    NSString *tag = [tagResult stringForColumnIndex:0];
                    NSNumber *count = [tagResult objectForColumnIndex:1];
                    newTagsWithFrequencies[tag] = count;
                }

                [tagResult close];
            }];
            
            NSMutableArray *indexPathsToInsert = [NSMutableArray array];
            NSMutableArray *indexPathsToDelete = [NSMutableArray array];
            NSMutableArray *indexPathsToReload = [NSMutableArray array];
            
            if (cancel && cancel()) {
                DLog(@"Cancelling search for query (%@)", self.searchQuery);
                completion(nil, nil, nil, [NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                return;
            }
            
            [PPUtilities generateDiffForPrevious:previousBookmarks
                                         updated:updatedBookmarks
                                            hash:^NSString *(id obj) {
                                                return obj[@"hash"];
                                            }
                                            meta:^NSString *(id obj) {
                                                return obj[@"hash"];
                                            }
                                      completion:^(NSSet *inserted, NSSet *updated, NSSet *deleted) {
                                          for (NSString *hash in deleted) {
                                              [indexPathsToDelete addObject:oldHashesToIndexPaths[hash]];
                                          }
                                          
                                          for (NSString *hashmeta in updated) {
                                              NSString *hash = newHashmetasToHashes[hashmeta];
                                              [indexPathsToReload addObject:oldHashesToIndexPaths[hash]];
                                          }
                                          
                                          for (NSString *hash in inserted) {
                                              [indexPathsToInsert addObject:newHashesToIndexPaths[hash]];
                                          }
                                          
                                          NSMutableArray *newMetadata = [NSMutableArray array];
                                          NSMutableArray *newCompressedMetadata = [NSMutableArray array];
                                          
                                          for (NSDictionary *post in updatedBookmarks) {
                                              NSString *hash = post[@"hash"];
                                              NSString *meta = post[@"meta"];
                                              NSString *hashmeta = [hash stringByAppendingString:meta];
                                              
                                              BOOL useCache;
                                              if ([updated containsObject:hashmeta] || [inserted containsObject:hash]) {
                                                  useCache = NO;
                                              }
                                              else {
                                                  useCache = YES;
                                              }
                                              
                                              PostMetadata *metadata = [PostMetadata metadataForPost:post compressed:NO width:width tagsWithFrequency:self.tagsWithFrequency cache:useCache];
                                              [newMetadata addObject:metadata];
                                              
                                              PostMetadata *compressedMetadata = [PostMetadata metadataForPost:post compressed:YES width:width tagsWithFrequency:self.tagsWithFrequency cache:useCache];
                                              [newCompressedMetadata addObject:compressedMetadata];
                                          }
                                          
                                          // We run this block to make sure that these results should be the latest on file
                                          if (cancel && cancel()) {
                                              DLog(@"Cancelling search for query (%@)", self.searchQuery);
                                              completion(nil, nil, nil, [NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                                          }
                                          else {
                                              self.posts = updatedBookmarks;
                                              self.metadata = newMetadata;
                                              self.compressedMetadata = newCompressedMetadata;
                                              self.tagsWithFrequency = newTagsWithFrequencies;
                                              
                                              completion(indexPathsToInsert, indexPathsToReload, indexPathsToDelete, nil);
                                          }
                                      }];
        };
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self generateQueryAndParameters:HandleSearch];
        });
    });
}

- (BOOL)isPostAtIndexPrivate:(NSInteger)index {
    return [self.posts[index][@"private"] boolValue];
}

- (NSString *)urlForPostAtIndex:(NSInteger)index {
    return self.posts[index][@"url"];
}

- (NSDictionary *)postAtIndex:(NSInteger)index {
    return self.posts[index];
}

- (void)markPostAsRead:(NSString *)url callback:(void (^)(NSError *))callback {
    LHSDelicious *delicious = [LHSDelicious sharedInstance];
    [delicious bookmarkWithURL:url
                    completion:^(NSDictionary *bookmark, NSError *error) {
                        if (error) {
                            if (error.code == DeliciousErrorBookmarkNotFound) {
                                callback(error);
                            }
                        }
                        else {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#warning XXX Check tags instead of "toread"
                                if ([bookmark[@"toread"] isEqualToString:@"no"]) {
                                    // Bookmark has already been marked as read on server.
                                    [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                                        [db executeUpdate:@"UPDATE bookmark SET unread=0, meta=random() WHERE hash=?" withArgumentsInArray:@[bookmark[@"hash"]]];
                                    }];
                                    
                                    callback(nil);
                                    return;
                                }
                                
                                NSMutableDictionary *newBookmark = [NSMutableDictionary dictionaryWithDictionary:bookmark];
                                newBookmark[@"url"] = newBookmark[@"href"];
                                
                                [newBookmark removeObjectsForKeys:@[@"href", @"hash", @"meta", @"time"]];
                                [delicious addBookmark:newBookmark
                                            completion:^(NSError *error) {
                                                if (error) {
                                                    callback(error);
                                                }
                                                else {
                                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                                                            [db executeUpdate:@"UPDATE bookmark SET unread=0, meta=random() WHERE hash=?" withArgumentsInArray:@[bookmark[@"hash"]]];
                                                        }];

                                                        callback(nil);
                                                    });
                                                }
                                            }];
                            });
                        }
                    }];
}

- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths callback:(void (^)(NSArray *, NSArray *, NSArray *))callback {
    void (^SuccessBlock)();
    void (^ErrorBlock)(NSError *);

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    LHSDelicious *delicious = [LHSDelicious sharedInstance];
    NSString *url;
    
    for (NSIndexPath *indexPath in indexPaths) {
        url = self.posts[indexPath.row][@"url"];
        SuccessBlock = ^{
            NSString *hash = self.posts[indexPath.row][@"hash"];
            
            [[PPUtilities databaseQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
                [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[hash]];
                [db executeUpdate:@"DELETE FROM bookmark WHERE hash=?" withArgumentsInArray:@[hash]];
            }];
            
            [[Mixpanel sharedInstance] track:@"Deleted bookmark"];

            dispatch_group_leave(group);
        };
        
        ErrorBlock = ^(NSError *error) {
            dispatch_group_leave(group);
        };

        dispatch_group_enter(group);
        [delicious deleteBookmarkWithURL:url
                              completion:^(NSError *error) {
                                  if (error) {
                                      ErrorBlock(error);
                                  }
                                  else {
                                      SuccessBlock();
                                  }
                              }];
    }
    
    dispatch_group_notify(group, queue, ^{
        dispatch_group_t inner_group = dispatch_group_create();
        
        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_name=tag.name)"];
            [db executeUpdate:@"DELETE FROM tag WHERE count=0"];
        }];

        dispatch_group_notify(inner_group, queue, ^{
            if (callback) {
                [self reloadBookmarksWithCompletion:^(NSArray *indexPathsToInsert, NSArray *indexPathsToReload, NSArray *indexPathsToDelete, NSError *error) {
                    callback(indexPathsToInsert, indexPathsToReload, indexPathsToDelete);
                } cancel:nil width:self.mostRecentWidth];
            }
        });
    });
}

- (void)deletePosts:(NSArray *)posts callback:(void (^)(NSIndexPath *))callback {
    void (^SuccessBlock)();
    void (^ErrorBlock)(NSError *);
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    LHSDelicious *delicious = [LHSDelicious sharedInstance];
    for (NSDictionary *post in posts) {
        SuccessBlock = ^{
            dispatch_group_async(group, queue, ^{
                [[PPUtilities databaseQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_name=tag.name)"];
                    [db executeUpdate:@"DELETE FROM tag WHERE count=0"];
                    [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[post[@"hash"]]];
                    [db executeUpdate:@"DELETE FROM bookmark WHERE url=?" withArgumentsInArray:@[post[@"url"]]];
                }];
                
                [[Mixpanel sharedInstance] track:@"Deleted bookmark"];
                
                NSUInteger index = [self.posts indexOfObject:post];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [self.posts removeObjectAtIndex:index];
                [self.metadata removeObjectAtIndex:index];
                [self.compressedMetadata removeObjectAtIndex:index];
                
                callback(indexPath);
            });
        };
        
        ErrorBlock = ^(NSError *error) {
            callback(nil);
        };
        
        [delicious deleteBookmarkWithURL:post[@"url"]
                              completion:^(NSError *error) {
                                  if (error) {
                                      ErrorBlock(error);
                                  }
                                  else {
                                      SuccessBlock();
                                  }
                              }];
    }

    dispatch_group_notify(group, queue, ^{
        NSString *message;
        if ([posts count] == 1) {
            message = NSLocalizedString(@"Your bookmark was deleted.", nil);
        }
        else {
            message = [NSString stringWithFormat:@"%lu bookmarks were deleted.", (unsigned long)[posts count]];
        }

        [PPNotification notifyWithMessage:message success:YES updated:NO];
    });
}

- (PPPostActionType)actionsForPost:(NSDictionary *)post {
    PPPostActionType actions = PPPostActionDelete | PPPostActionEdit | PPPostActionCopyURL | PPPostActionShare;
    
    if ([post[@"unread"] boolValue]) {
        actions |= PPPostActionMarkAsRead;
    }
    
    BOOL shareToReadLater = NO;
    if (shareToReadLater && [PPSettings sharedSettings].readLater != PPReadLaterNone) {
        actions |= PPPostActionReadLater;
    }

    return actions;
}

- (PPNavigationController *)editViewControllerForPostAtIndex:(NSInteger)index {
    return [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:self.posts[index] update:@(YES) callback:nil];
}

- (void)handleTapOnLinkWithURL:(NSURL *)url callback:(void (^)(UIViewController *))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // All tags should be UTF8 encoded (stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding) before getting passed into the NSURL, so we decode them here
        NSString *tag = [url.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if (![self.tags containsObject:tag]) {
            PPDeliciousDataSource *deliciousDataSource = [self dataSourceWithAdditionalTag:tag];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                PPGenericPostViewController *postViewController = [[PPGenericPostViewController alloc] init];
                postViewController.postDataSource = deliciousDataSource;
                PPTitleButton *button = [PPTitleButton buttonWithDelegate:postViewController];
                [button setTitle:[deliciousDataSource.tags componentsJoinedByString:@"+"] imageName:nil];
                
                postViewController.navigationItem.titleView = button;
                callback(postViewController);
            });
        }
    });
}

- (NSAttributedString *)titleForPostAtIndex:(NSInteger)index {
    PostMetadata *metadata = self.metadata[index];
    return metadata.titleString;
}

- (NSAttributedString *)descriptionForPostAtIndex:(NSInteger)index {
    PostMetadata *metadata = self.metadata[index];
    return metadata.descriptionString;
}

- (NSAttributedString *)linkForPostAtIndex:(NSInteger)index {
    PostMetadata *metadata = self.metadata[index];
    return metadata.linkString;
}

- (CGFloat)heightForPostAtIndex:(NSInteger)index {
    PostMetadata *metadata = self.metadata[index];
    return [metadata.height floatValue];
}

- (CGFloat)compressedHeightForPostAtIndex:(NSInteger)index {
    PostMetadata *metadata = self.compressedMetadata[index];
    return [metadata.height floatValue];
}

- (NSArray *)badgesForPostAtIndex:(NSInteger)index {
    PostMetadata *metadata = self.compressedMetadata[index];
    return metadata.badges;
}

- (BOOL)supportsTagDrilldown {
    return YES;
}

- (NSArray *)quotedTags {
    NSMutableArray *quotedTagComponents = [NSMutableArray array];
    for (NSString *tag in self.tags) {
        [quotedTagComponents addObject:[NSString stringWithFormat:@"\"%@\"", tag]];
    }
    return quotedTagComponents;
}

- (PPNavigationController *)editViewControllerForPostAtIndex:(NSInteger)index callback:(void (^)())callback {
    return [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:self.posts[index] update:@(YES) callback:^(NSDictionary *post) {
#warning should really add a success parameter to this block;
        if ([post count] > 0) {
            PostMetadata *metadata = [PostMetadata metadataForPost:post compressed:NO width:self.mostRecentWidth tagsWithFrequency:self.tagsWithFrequency];
            PostMetadata *compressedMetadata = [PostMetadata metadataForPost:post compressed:YES width:self.mostRecentWidth tagsWithFrequency:self.tagsWithFrequency];
            
            self.metadata[index] = metadata;
            self.compressedMetadata[index] = compressedMetadata;
        }
        
        callback();
    }];
}

- (void)generateQueryAndParameters:(void (^)(NSString *, NSArray *))callback {
    NSMutableArray *components = [NSMutableArray array];
    NSMutableArray *parameters = [NSMutableArray array];
    
    [components addObject:@"SELECT bookmark.* FROM"];
    
    NSMutableArray *tables = [NSMutableArray arrayWithObject:@"bookmark"];
    if (self.searchQuery) {
        [tables addObject:@"bookmark_fts"];
    }
    
    [components addObject:[tables componentsJoinedByString:@", "]];
    
    NSMutableArray *whereComponents = [NSMutableArray array];
    [whereComponents addObject:@"bookmark.hash IS NOT NULL"];

    if (self.searchQuery) {
        [whereComponents addObject:@"bookmark.hash = bookmark_fts.hash"];
        
        NSError *error;
        // Both of these regex searches comprise the form 'tag:programming' or 'tag:"programming python"'. The only difference are the capture groups.
        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"((\\w+:[^\" ]+)|(\\w+:\"[^\"]+\"))" options:0 error:&error];
        NSRegularExpression *subExpression = [NSRegularExpression regularExpressionWithPattern:@"(\\w+):\"?([^\"]+)\"?" options:0 error:&error];
        NSArray *fieldMatches = [expression matchesInString:self.searchQuery options:0 range:NSMakeRange(0, self.searchQuery.length)];
        NSMutableArray *valuesForRanges = [NSMutableArray array];
        for (NSTextCheckingResult *result in fieldMatches) {
            [valuesForRanges addObject:[NSValue valueWithRange:result.range]];
            
            NSString *matchString = [self.searchQuery substringWithRange:result.range];
            NSTextCheckingResult *subresult = [subExpression firstMatchInString:matchString options:0 range:NSMakeRange(0, matchString.length)];
            
            if (subresult.numberOfRanges == 3) {
                NSString *field = [[matchString substringWithRange:[subresult rangeAtIndex:1]] lowercaseString];
                
                BOOL isValidField = NO;
                for (NSString *validField in @[@"title", @"description", @"url", @"tags"]) {
                    if ([validField isEqualToString:field]) {
                        isValidField = YES;
                        break;
                    }
                }
                
                if (isValidField) {
                    NSString *value = [[matchString substringWithRange:[subresult rangeAtIndex:2]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSArray *words = [value componentsSeparatedByString:@" "];
                    NSMutableArray *wordsWithWildcards = [NSMutableArray array];
                    for (NSString *word in words) {
                        if ([word hasSuffix:@"*"] || [@[@"AND", @"OR", @"NOT"] containsObject:word]) {
                            [wordsWithWildcards addObject:word];
                        }
                        else {
                            [wordsWithWildcards addObject:[word stringByAppendingString:@"*"]];
                        }
                    }
                    [whereComponents addObject:[NSString stringWithFormat:@"bookmark_fts.%@ MATCH ?", field]];
                    [parameters addObject:[wordsWithWildcards componentsJoinedByString:@" "]];
                }
            }
        }
        
        NSMutableString *remainingQuery = [NSMutableString stringWithString:self.searchQuery];
        for (NSValue *value in [valuesForRanges reverseObjectEnumerator]) {
            [remainingQuery replaceCharactersInRange:[value rangeValue] withString:@""];
        }
        
        NSString *trimmedQuery = [remainingQuery stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (![trimmedQuery isEqualToString:@""]) {
            [whereComponents addObject:@"bookmark_fts MATCH ?"];
            [parameters addObject:trimmedQuery];
        }
    }
    
    switch (self.untagged) {
        case kPushpinFilterFalse:
            [whereComponents addObject:@"bookmark.tags != ?"];
            [parameters addObject:@""];
            break;
            
        case kPushpinFilterTrue:
            [whereComponents addObject:@"bookmark.tags = ?"];
            [parameters addObject:@""];
            break;
            
        case kPushpinFilterNone:
            // Only search within tag filters if there is no search query and untagged is not used (they could conflict).
            if (!self.searchQuery) {
                for (NSString *tag in self.tags) {
                    [whereComponents addObject:@"bookmark.hash IN (SELECT bookmark_hash FROM tagging WHERE tag_name = ?)"];
                    [parameters addObject:tag];
                }
            }
            break;
    }
    
    if (self.isPrivate != kPushpinFilterNone) {
        [whereComponents addObject:@"bookmark.private = ?"];
        [parameters addObject:@(self.isPrivate)];
    }
    
    if (self.unread != kPushpinFilterNone) {
        [whereComponents addObject:@"bookmark.unread = ?"];
        [parameters addObject:@(self.unread)];
    }
    
    if (whereComponents.count > 0) {
        [components addObject:@"WHERE"];
        [components addObject:[whereComponents componentsJoinedByString:@" AND "]];
    }
    
    if (self.orderBy) {
        [components addObject:[NSString stringWithFormat:@"ORDER BY %@", self.orderBy]];
    }
    
    if (self.limit > 0) {
        [components addObject:@"LIMIT ?"];
        [parameters addObject:@(self.limit)];
    }
    
    if (self.offset > 0) {
        [components addObject:@"OFFSET ?"];
        [parameters addObject:@(self.offset)];
    }
    
    NSString *query = [components componentsJoinedByString:@" "];
    callback(query, parameters);
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    PPDeliciousDataSource *dataSource = [[PPDeliciousDataSource alloc] init];
    dataSource.limit = self.limit;
    dataSource.tags = self.tags;
    dataSource.orderBy = self.orderBy;
    dataSource.searchQuery = self.searchQuery;
    dataSource.offset = self.offset;
    dataSource.unread = self.unread;
    dataSource.untagged = self.untagged;
    return dataSource;
}

- (NSString *)searchPlaceholder {
    if (self.unread == kPushpinFilterTrue) {
        return NSLocalizedString(@"Search Unread", nil);
    }
    
    if (self.untagged == kPushpinFilterTrue) {
        return NSLocalizedString(@"Search Untagged", nil);
    }
    
    return NSLocalizedString(@"Search", nil);
}

- (UIColor *)barTintColor {
    if (self.unread == kPushpinFilterTrue) {
        return HEX(0xEF6034FF);
    }
    
    if (self.untagged == kPushpinFilterTrue) {
        return HEX(0xACB3BBFF);
    }
    
    return HEX(0x0096FFFF);
}

- (NSString *)title {
    if (self.isPrivate == kPushpinFilterTrue) {
        return NSLocalizedString(@"Private Bookmarks", nil);
    }
    
    if (self.isPrivate == kPushpinFilterFalse) {
        return NSLocalizedString(@"Public", nil);
    }

    if (self.unread == kPushpinFilterTrue) {
        return NSLocalizedString(@"Unread", nil);
    }
    
    if (self.untagged == kPushpinFilterTrue) {
        return NSLocalizedString(@"Untagged", nil);
    }
    
    if (self.isPrivate == kPushpinFilterNone && self.unread == kPushpinFilterNone && self.untagged == kPushpinFilterNone && self.searchQuery == nil && self.tags.count == 0) {
        return NSLocalizedString(@"All Bookmarks", nil);
    }
    
    return [self.tags componentsJoinedByString:@"+"];
}

- (UIView *)titleViewWithDelegate:(id<PPTitleButtonDelegate>)delegate {
    PPTitleButton *titleButton = [PPTitleButton buttonWithDelegate:delegate];
    
    if (self.isPrivate == kPushpinFilterTrue) {
        [titleButton setTitle:NSLocalizedString(@"Private Bookmarks", nil) imageName:@"navigation-private"];
    }
    
    if (self.isPrivate == kPushpinFilterFalse) {
        [titleButton setTitle:NSLocalizedString(@"Public", nil) imageName:@"navigation-public"];
    }

    if (self.unread == kPushpinFilterTrue) {
        [titleButton setTitle:NSLocalizedString(@"Unread", nil) imageName:@"navigation-unread"];
    }
    
    if (self.untagged == kPushpinFilterTrue) {
        [titleButton setTitle:NSLocalizedString(@"Untagged", nil) imageName:@"navigation-untagged"];
    }
    
    if (self.isPrivate == kPushpinFilterNone && self.unread == kPushpinFilterNone && self.untagged == kPushpinFilterNone && self.searchQuery == nil && self.tags.count == 0) {
        [titleButton setTitle:NSLocalizedString(@"All Bookmarks", nil) imageName:@"navigation-all"];
    }
    
    if (!titleButton.titleLabel.text) {
        [titleButton setTitle:[self.tags componentsJoinedByString:@"+"] imageName:nil];
    }
    
    return titleButton;
}

- (UIView *)titleView {
    return [self titleViewWithDelegate:nil];
}

- (BOOL)searchSupported {
    return YES;
}

- (NSDictionary *)paramsForPost:(NSDictionary *)post dateError:(BOOL)dateError {
    NSDate *date = [self.enUSPOSIXDateFormatter dateFromString:post[@"time"]];
    if (!dateError && !date) {
        date = [NSDate dateWithTimeIntervalSince1970:0];
        [[Mixpanel sharedInstance] track:@"NSDate error in updateLocalDatabaseFromRemoteAPIWithSuccess" properties:@{@"Locale": [NSLocale currentLocale]}];
        DLog(@"Error parsing date: %@", post[@"time"]);
        
        // XXX This changed recently! Could be a source of issues.
        return nil;
    }

    NSString *hash = post[@"hash"];
    NSString *meta = post[@"meta"];
    
    NSString *postTags = [PPUtilities stringByTrimmingWhitespace:post[@"tag"]];
    NSArray *tagList = [postTags componentsSeparatedByString:@" "];
    NSString *title = [PPUtilities stringByTrimmingWhitespace:post[@"description"]];
    NSString *description = [PPUtilities stringByTrimmingWhitespace:post[@"extended"]];
    
    return @{
             @"url": post[@"href"],
             @"title": title,
             @"description": description,
             @"meta": meta,
             @"hash": hash,
             @"tags": postTags,
             @"unread": @([tagList containsObject:@"toread"]),
             @"private": @([post[@"private"] isEqualToString:@"yes"]),
             @"created_at": date
         };
}

@end
