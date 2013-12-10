//
//  PinboardDataSource.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import "PinboardDataSource.h"
#import "FMDatabase.h"
#import "AppDelegate.h"
#import "NSAttributedString+Attributes.h"
#import "ASPinboard/ASPinboard.h"
#import "AddBookmarkViewController.h"
#import "BloomFilter.h"
#import "UIApplication+AppDimensions.h"
#import "PPBadgeView.h"

static BOOL kPinboardSyncInProgress = NO;

@implementation PinboardDataSource

@synthesize query = _query;
@synthesize queryParameters = _queryParameters;
@synthesize posts = _posts;
@synthesize heights = _heights;
@synthesize strings = _strings;
@synthesize badges = _badges;
@synthesize totalNumberOfPosts = _totalNumberOfPosts;
@synthesize urls;
@synthesize maxResults;

- (id)init {
    self = [super init];
    if (self) {
        self.totalNumberOfPosts = 0;
        self.posts = [NSMutableArray array];
        self.strings = [NSMutableArray array];
        self.heights = [NSMutableArray array];
        self.links = [NSMutableArray array];

        self.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"offset": @(0), @"limit": @(50)}];
        self.tags = @[];

        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        self.locale = [NSLocale currentLocale];
        [self.dateFormatter setLocale:self.locale];
        [self.dateFormatter setDoesRelativeDateFormatting:YES];
    }
    return self;
}

- (id)initWithParameters:(NSDictionary *)parameters {
    self = [super init];
    if (self) {
        self.totalNumberOfPosts = 0;
        self.posts = [NSMutableArray array];
        self.strings = [NSMutableArray array];
        self.heights = [NSMutableArray array];
        self.links = [NSMutableArray array];

        self.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"offset": @(0), @"limit": @(50)}];
        self.tags = @[];

        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        self.locale = [NSLocale currentLocale];
        [self.dateFormatter setLocale:self.locale];
        [self.dateFormatter setDoesRelativeDateFormatting:YES];
        [self filterWithParameters:parameters];
    }
    return self;
}

- (void)filterWithParameters:(NSDictionary *)parameters {
    NSNumber *isPrivate = parameters[@"private"];
    NSNumber *isRead;
    if (parameters[@"unread"]) {
        isRead = @(!([parameters[@"unread"] boolValue]));
    }
    else {
        isRead = nil;
    }
    NSNumber *isStarred = parameters[@"starred"];
    NSNumber *hasTags = parameters[@"tagged"];
    NSArray *tags = parameters[@"tags"];
    NSInteger offset = [parameters[@"offset"] integerValue];
    NSInteger limit = [parameters[@"limit"] integerValue];

    [self filterByPrivate:isPrivate isRead:isRead isStarred:isStarred hasTags:hasTags tags:tags offset:offset limit:limit];
}

- (void)filterWithQuery:(NSString *)query {
    query = [query stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSArray *components = [query componentsSeparatedByString:@" "];
    NSMutableArray *newComponents = [NSMutableArray array];
    for (NSString *component in components) {
        if ([component isEqualToString:@"AND"]) {
            [newComponents addObject:component];
        }
        else if ([component isEqualToString:@"OR"]) {
            [newComponents addObject:component];
        }
        else if ([component isEqualToString:@"NOT"]) {
            [newComponents addObject:component];
        }
        else if ([component rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\": "]].location == NSNotFound) {
            [newComponents addObject:[component stringByAppendingString:@"*"]];
        }
        else {
            if ([component hasSuffix:@":"]) {
                [newComponents addObject:[component stringByAppendingString:@"*"]];
            }
            else {
                [newComponents addObject:component];
            }
        }
    }
    NSString *newQuery = [newComponents componentsJoinedByString:@" "];
    self.queryParameters[@"query"] = newQuery;
}

- (PinboardDataSource *)searchDataSource {
    PinboardDataSource *search = [[PinboardDataSource alloc] init];

    search.maxResults = 10;

    NSMutableArray *queryComponents = [NSMutableArray array];
    if (self.queryParameters[@"private"]) {
        [queryComponents addObject:@"private = :private"];
    }
    
    if (self.queryParameters[@"unread"]) {
        [queryComponents addObject:@"unread = :unread"];
    }
    
    if (self.queryParameters[@"starred"]) {
        [queryComponents addObject:@"starred = :starred"];
    }

    if (self.queryParameters[@"tags"]) {
        [queryComponents addObject:@"tags = :tags"];
    }

    if (self.tags.count > 0) {
        NSString *tagComponent = [self.quotedTags componentsJoinedByString:@", "];
        [queryComponents addObject:[NSString stringWithFormat:@"hash IN (SELECT bookmark_hash FROM tagging WHERE tag_name IN (%@))", tagComponent]];
    }

    [queryComponents addObject:@"hash in (SELECT hash FROM bookmark_fts WHERE bookmark_fts MATCH :query)"];

    NSString *whereComponent = [queryComponents componentsJoinedByString:@" AND "];
    search.query = [NSString stringWithFormat:@"SELECT * FROM bookmark WHERE %@ ORDER BY created_at DESC LIMIT :limit OFFSET :offset", whereComponent];
    search.queryParameters = [NSMutableDictionary dictionaryWithDictionary:self.queryParameters];
    search.queryParameters[@"offset"] = @(0);
    search.queryParameters[@"limit"] = @(search.maxResults);
    search.queryParameters[@"query"] = @"*";
    search.tags = [self.tags copy];
    return search;
}

- (PinboardDataSource *)dataSourceWithAdditionalTag:(NSString *)tag {
    PinboardDataSource *dataSource = [[PinboardDataSource alloc] init];
    
    dataSource.maxResults = 50;
    
    NSMutableArray *queryComponents = [NSMutableArray array];
    if (self.queryParameters[@"private"]) {
        [queryComponents addObject:@"private = :private"];
    }

    if (self.queryParameters[@"unread"]) {
        [queryComponents addObject:@"unread = :unread"];
    }

    if (self.queryParameters[@"starred"]) {
        [queryComponents addObject:@"starred = :starred"];
    }

    if (self.queryParameters[@"tags"]) {
        [queryComponents addObject:@"tags = :tags"];
    }
    
    NSMutableArray *newTags = [NSMutableArray arrayWithArray:self.tags];
    if (![newTags containsObject:tag]) {
        [newTags addObject:tag];
    }

    for (NSString *tag in newTags) {
        [queryComponents addObject:[NSString stringWithFormat:@"hash IN (SELECT bookmark_hash FROM tagging WHERE tag_name=\"%@\")", tag]];
    }

    NSString *whereComponent = [queryComponents componentsJoinedByString:@" AND "];

    dataSource.query = [NSString stringWithFormat:@"SELECT * FROM bookmark WHERE %@ ORDER BY created_at DESC LIMIT :limit OFFSET :offset", whereComponent];
    dataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:self.queryParameters];
    dataSource.queryParameters[@"offset"] = @(0);
    dataSource.queryParameters[@"limit"] = @(50);
    dataSource.tags = newTags;
    return dataSource;
}

- (void)filterByPrivate:(NSNumber *)isPrivate isRead:(NSNumber *)isRead isStarred:(NSNumber *)starred hasTags:(NSNumber *)hasTags tags:(NSArray *)tags offset:(NSInteger)offset limit:(NSInteger)limit {
    NSMutableArray *queryComponents = [NSMutableArray array];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{@"offset": @(offset), @"limit": @(limit)}];
    self.maxResults = limit;  

    if (isPrivate) {
        [queryComponents addObject:@"private = :private"];
        parameters[@"private"] = isPrivate;
    }

    if (isRead) {
        [queryComponents addObject:@"unread = :unread"];
        parameters[@"unread"] = @(![isRead boolValue]);
    }
    
    if (starred) {
        [queryComponents addObject:@"starred = :starred"];
        parameters[@"starred"] = starred;
    }

    if (hasTags) {
        if ([hasTags boolValue]) {
            [queryComponents addObject:@"tags != :tags"];
            parameters[@"tags"] = @"";
        }
        else {
            [queryComponents addObject:@"tags = :tags"];
            parameters[@"tags"] = @"";
        }
    }

    self.queryParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];

    if (tags != nil && [tags count] > 0) {
        self.tags = [tags copy];
        NSString *tagComponent = [self.quotedTags componentsJoinedByString:@", "];
        [queryComponents addObject:[NSString stringWithFormat:@"hash IN (SELECT bookmark_hash FROM tagging WHERE tag_name IN (%@))", tagComponent]];
    }

    if ([queryComponents count] > 0) {
        NSString *whereComponent = [queryComponents componentsJoinedByString:@" AND "];
        self.query = [NSString stringWithFormat:@"SELECT * FROM bookmark WHERE %@ ORDER BY created_at DESC LIMIT :limit OFFSET :offset", whereComponent];
    }
    else {
        self.query = @"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
    }
}

- (void)willDisplayIndexPath:(NSIndexPath *)indexPath callback:(void (^)(BOOL))callback {
    NSInteger limit = [self.queryParameters[@"limit"] integerValue];

    BOOL needsUpdate = indexPath.row >= limit * 3. / 4.;
    if (needsUpdate) {
        if (self.queryParameters[@"query"]) {
            self.queryParameters[@"limit"] = @(limit + 10);
        }
        else {
            self.queryParameters[@"limit"] = @(limit + 50);
        }
    }
    callback(needsUpdate);
}

- (NSInteger)numberOfPosts {
    return [self.posts count];
}

- (NSInteger)totalNumberOfPosts {
    if (!_totalNumberOfPosts) {
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *result = [db executeQuery:@"SELECT COUNT(*) FROM bookmark;"];
        [result next];
        NSInteger count = [result intForColumnIndex:0];
        [db close];
        _totalNumberOfPosts = count;
    }
    return _totalNumberOfPosts;
}

- (void)updateLocalDatabaseFromRemoteAPIWithSuccess:(void (^)())success failure:(void (^)())failure progress:(void (^)(NSInteger, NSInteger))progress options:(NSDictionary *)options {
    
    if (!failure) {
        failure = ^(NSError *error) {};
    }

    if (!kPinboardSyncInProgress) {
        kPinboardSyncInProgress = YES;

        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        ASPinboard *pinboard = [ASPinboard sharedInstance];
        
        if (!progress) {
            progress = ^(NSInteger current, NSInteger total) {};
        }
        
        if (!success) {
            success = ^{};
        }

        void (^BookmarksSuccessBlock)(NSArray *, NSDictionary *) = ^(NSArray *posts, NSDictionary *constraints) {
            DLog(@"%@ - Received data", [NSDate date]);
            NSDate *startDate = [NSDate date];
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            
            [db beginTransaction];
            [db executeUpdate:@"DELETE FROM bookmark WHERE hash IS NULL"];
            
            FMResultSet *results;

            NSMutableArray *tags = [NSMutableArray array];
            results = [db executeQuery:@"SELECT name FROM tag"];
            while ([results next]) {
                [tags addObject:[results stringForColumn:@"name"]];
            }

            // Offsets from the full data set
            NSUInteger offset = 0;
            NSUInteger count = 0;
            offset = ([constraints[@"start"] isEqual:[NSNull null]]) ? 0 : [(NSString *)constraints[@"start"] intValue];
            count = ([constraints[@"results"] isEqual:[NSNull null]]) ? 0 : [(NSString *)constraints[@"results"] intValue];
            
            // Create an NSSet of the local data for filtering
            NSMutableArray *localHashTable = [NSMutableArray array];
            NSMutableArray *localMetaTable = [NSMutableArray array];
            
            DLog(@"%@ - Getting local data", [NSDate date]);
            
            NSString *firstHash = ([posts count] > 0) ? posts[0][@"hash"] : @"";
            NSUInteger firstBookmarkIndex = NSNotFound;
            NSUInteger total = posts.count;
            NSUInteger deleteOffset;
            results = [db executeQuery:@"SELECT meta, hash, url FROM bookmark ORDER BY created_at DESC"];
            NSUInteger resultIndex = 0;
            while ([results next]) {
                NSString *hash = [results stringForColumn:@"hash"];
                
                // Update our NSSets
                [localHashTable addObject:hash];
                [localMetaTable addObject:[NSString stringWithFormat:@"%@_%@", hash, [results stringForColumn:@"meta"]]];
                
                // If our local first hash doesn't equal the remote first hash, get the offset for deletion
                if (firstBookmarkIndex == NSNotFound) {
                    if ([hash isEqualToString:firstHash]) {
                        deleteOffset = resultIndex;
                        firstBookmarkIndex = resultIndex;
                    }
                }
                resultIndex++;
            }
            NSUInteger localCount = [localHashTable count];
            
            DLog(@"%@ - Creating NSSets", [NSDate date]);
            
            // Create NSSets containing hashes and meta data
            NSMutableArray *remoteHashTable = [NSMutableArray array];
            NSMutableArray *remoteMetaTable = [NSMutableArray array];
            for (NSDictionary *post in posts) {
                [remoteHashTable addObject:post[@"hash"]];
                [remoteMetaTable addObject:[NSString stringWithFormat:@"%@_%@", post[@"hash"], post[@"meta"]]];
            }
            
            // We convert to NSSet directly from NSArray to avoid hash lookups on each addObject on NSMutableSet
            NSSet *localHashSet = [NSSet setWithArray:localHashTable];
            NSSet *localMetaSet = [NSSet setWithArray:localMetaTable];
            
            NSSet *remoteHashSet = [NSSet setWithArray:remoteHashTable];
            NSSet *remoteMetaSet = [NSSet setWithArray:remoteMetaTable];
            
            DLog(@"%@ - Calculating changes", [NSDate date]);
            
            // Find the additions
            NSMutableSet *additionBookmarksSet = [remoteHashSet mutableCopy];
            [additionBookmarksSet minusSet:localHashSet];
            
            // Find the removals
            NSUInteger rangeEnd = 0;
            if (firstBookmarkIndex == NSNotFound) {
                rangeEnd = count > localCount ? localCount - 1 : count;
            }
            else {
                rangeEnd = (count + deleteOffset) > localCount ? localCount - 1 : (count + deleteOffset);
            }

            // MIN is needed as localCount - 1 => very large number when localCount is 0
            rangeEnd = MIN(0, rangeEnd);
            NSRange deleteRange = NSMakeRange(offset, rangeEnd);
            
            NSMutableSet *deletionBookmarksSet = [[NSSet setWithArray:[localHashTable subarrayWithRange:deleteRange]] mutableCopy];
            [deletionBookmarksSet minusSet:remoteHashSet];
            
            // Find the modifications
            NSMutableSet *updateBookmarksSet = [remoteMetaSet mutableCopy];
            [updateBookmarksSet minusSet:localMetaSet];
            
            NSDictionary *params;
            NSUInteger index = 0;
            NSUInteger skipped = 0;
            NSUInteger updateCount = 0;
            NSUInteger addCount = 0;
            NSUInteger deleteCount = 0;
            NSUInteger tagAddCount = 0;
            NSUInteger tagDeleteCount = 0;
            NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setLocale:enUSPOSIXLocale];
            [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

            [mixpanel.people set:@"Bookmarks" to:@(total)];

            DLog(@"%@ - Iterating posts", [NSDate date]);
            dispatch_async(dispatch_get_main_queue(), ^{
                progress(0, total);
                [[NSNotificationCenter defaultCenter] postNotificationName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(0), @"total": @(total)}];
            });
            
            // Only track one date error per update
            BOOL dateError = NO;

            for (NSDictionary *post in posts) {
                if (index > 0 && (index % 1000) == 0) {
                    DLog(@"%@ - Index %ld of %ld", [NSDate date], (long)index, (long)total);
                }
                BOOL updated_or_created = NO;

                NSString *hash = post[@"hash"];
                NSString *meta = post[@"meta"];

                NSString *postTags = ([post[@"tags"] isEqual:[NSNull null]]) ? @"" : [post[@"tags"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *title = ([post[@"description"] isEqual:[NSNull null]]) ? @"" : [post[@"description"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *description = ([post[@"extended"] isEqual:[NSNull null]]) ? @"" : [post[@"extended"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                // Add if necessary
                if ([additionBookmarksSet containsObject:hash]) {
                    NSDate *date = [dateFormatter dateFromString:post[@"time"]];
                    if (!dateError && !date) {
                        date = [NSDate dateWithTimeIntervalSince1970:0];
                        [[Mixpanel sharedInstance] track:@"NSDate error in updateLocalDatabaseFromRemoteAPIWithSuccess" properties:@{@"Locale": [NSLocale currentLocale]}];
                        dateError = YES;
                    }
                    
                    params = @{
                               @"url": post[@"href"],
                               @"title": title,
                               @"description": description,
                               @"meta": meta,
                               @"hash": hash,
                               @"tags": postTags,
                               @"unread": @([post[@"toread"] isEqualToString:@"yes"]),
                               @"private": @([post[@"shared"] isEqualToString:@"no"]),
                               @"created_at": date
                               };
                    
                    [db executeUpdate:@"INSERT INTO bookmark (title, description, url, private, unread, hash, tags, meta, created_at) VALUES (:title, :description, :url, :private, :unread, :hash, :tags, :meta, :created_at);" withParameterDictionary:params];
                    
                    // Remove from the updateBookmarks array
                    //[updateBookmarks removeObject:[NSString stringWithFormat:@"%@_%@", post[@"hash"], post[@"meta"]]];
                    
                    updated_or_created = YES;
                    addCount++;
                }
                
                // Update if necessary
                if (!updated_or_created) {
                    if ([updateBookmarksSet containsObject:[NSString stringWithFormat:@"%@_%@", post[@"hash"], post[@"meta"]]]) {
                        params = @{
                                   @"url": post[@"href"],
                                   @"title": title,
                                   @"description": description,
                                   @"meta": meta,
                                   @"hash": hash,
                                   @"tags": postTags,
                                   @"unread": @([post[@"toread"] isEqualToString:@"yes"]),
                                   @"private": @([post[@"shared"] isEqualToString:@"no"])
                                   };
                        
                        // Update this bookmark
                        [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, url=:url, private=:private, unread=:unread, tags=:tags, meta=:meta WHERE hash=:hash" withParameterDictionary:params];
                        updated_or_created = YES;
                        updateCount++;
                    }
                }
                
                // Update tags
                if (updated_or_created && postTags.length > 0) {
                    [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[hash]];
                    tagDeleteCount++;

                    for (NSString *tagName in [postTags componentsSeparatedByString:@" "]) {
                        [db executeUpdate:@"INSERT OR IGNORE INTO tag (name) VALUES (?)" withArgumentsInArray:@[tagName]];
                        [db executeUpdate:@"INSERT INTO tagging (tag_name, bookmark_hash) VALUES (?, ?)" withArgumentsInArray:@[tagName, hash]];
                        tagAddCount++;
                    }
                }

                index++;
                dispatch_async(dispatch_get_main_queue(), ^{
                    progress(index, total);
                    [[NSNotificationCenter defaultCenter] postNotificationName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(index), @"total": @(total)}];
                });
            }
            
            DLog(@"%@ - Updating tags", [NSDate date]);
            [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_name=tag.name)"];
            [db executeUpdate:@"DELETE FROM tag WHERE count=0"];
            
            DLog(@"%@ - Deleting bookmarks", [NSDate date]);
            for (NSString *hash in deletionBookmarksSet) {
                [db executeUpdate:@"DELETE FROM bookmark WHERE hash=?" withArgumentsInArray:@[hash]];
                deleteCount++;
            }
            
            DLog(@"%@ - Starting DB commit", [NSDate date]);
            [db commit];
            [db close];

            NSDate *endDate = [NSDate date];
            skipped = total - addCount - updateCount - deleteCount;

            DLog(@"%f", [endDate timeIntervalSinceDate:startDate]);
            DLog(@"added %d", addCount);
            DLog(@"updated %d", updateCount);
            DLog(@"skipped %d", skipped);
            DLog(@"removed %d", deleteCount);
            DLog(@"tags added %d", tagAddCount);
            
            self.totalNumberOfPosts = index;

            [[AppDelegate sharedDelegate] setLastUpdated:[NSDate date]];
            kPinboardSyncInProgress = NO;

            dispatch_async(dispatch_get_main_queue(), ^{
                progress(total, total);
                [[NSNotificationCenter defaultCenter] postNotificationName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(total), @"total": @(total)}]; 
            });

            [[Mixpanel sharedInstance] track:@"Synced Pinboard bookmarks" properties:@{@"Duration": @([endDate timeIntervalSinceDate:startDate])}];
            [self updateStarredPostsWithSuccess:success failure:nil];
        };
        
        void (^BookmarksFailureBlock)(NSError *) = ^(NSError *error) {
            if (failure) {
                failure(error);
            }
            kPinboardSyncInProgress = NO;
        };

        void (^BookmarksUpdatedTimeSuccessBlock)(NSDate *) = ^(NSDate *updateTime) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSDate *lastLocalUpdate = [[AppDelegate sharedDelegate] lastUpdated];
                BOOL neverUpdated = lastLocalUpdate == nil;
                BOOL outOfSyncWithAPI = [lastLocalUpdate compare:updateTime] == NSOrderedAscending;
                // BOOL lastUpdatedMoreThanFiveMinutesAgo = [[NSDate date] timeIntervalSinceReferenceDate] - [lastLocalUpdate timeIntervalSinceReferenceDate] > 300;
                NSInteger count;
                if (options[@"ratio"]) {
                    count = (NSInteger)(MAX([self totalNumberOfPosts] * [options[@"ratio"] floatValue] - 200, 0) + 200);
                }
                else {
                    count = [options[@"count"] integerValue];
                }

                if (neverUpdated || outOfSyncWithAPI) {
                    [pinboard bookmarksWithTags:nil
                                         offset:-1
                                          count:count
                                       fromDate:nil
                                         toDate:nil
                                    includeMeta:YES
                                        success:^(NSArray *bookmarks, NSDictionary *parameters) {
                                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                BookmarksSuccessBlock(bookmarks, parameters);
                                            });
                                        }
                                        failure:^(NSError *error) {
                                            BookmarksFailureBlock(error);
                                        }];
                    
                }
                else {
                    kPinboardSyncInProgress = NO;
                    [self updateStarredPostsWithSuccess:success failure:nil];
                }
            });
        };
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [pinboard lastUpdateWithSuccess:BookmarksUpdatedTimeSuccessBlock failure:failure];
        });
    }
    else {
        failure([NSError errorWithDomain:PinboardDataSourceErrorDomain code:kPinboardSyncInProgress userInfo:nil]);
    }
}

- (void)updateStarredPostsWithSuccess:(void (^)())success failure:(void (^)())failure {
    void (^BookmarksSuccessBlock)(NSArray *, NSDictionary *) = ^(NSArray *posts, NSDictionary *constraints) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *oldURLs = [NSMutableArray array];
            NSUInteger index = 0;
            NSUInteger offset = 0;
            BOOL postFound = NO;
            NSString *url;
            
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            [db beginTransaction];
            
            FMResultSet *results = [db executeQuery:@"SELECT url FROM bookmark WHERE starred=1 ORDER BY created_at DESC"];
            while ([results next]) {
                url = [results stringForColumnIndex:0];
                [oldURLs addObject:url];
            }
            
            for (NSDictionary *post in posts) {
                postFound = NO;
                url = post[@"u"];
                
                for (NSInteger i=offset; i<oldURLs.count - offset; i++) {
                    if ([oldURLs[i] isEqualToString:url]) {
                        // Delete all posts that were skipped
                        for (NSInteger j=offset; j<i; j++) {
                            [db executeUpdate:@"UPDATE bookmark SET starred=0, meta=random() WHERE url=?" withArgumentsInArray:@[oldURLs[j]]];
                        }
                        
                        offset = i - 1;
                        postFound = YES;
                        break;
                    }
                }
                
                if (!postFound && ![oldURLs containsObject:url]) {
                    [db executeUpdate:@"UPDATE bookmark SET starred=1, meta=random() WHERE url=?" withArgumentsInArray:@[url]];
                }

                index++;
            }
            [db commit];
            [db close];
            
            success();
        });
    };
    
    if (!failure) {
        failure = ^{};
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
        NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
        NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://feeds.pinboard.in/json/secret:%@/u:%@/starred/?count=400", feedToken, username]];
        NSURLRequest *request = [NSURLRequest requestWithURL:endpoint];
        AppDelegate *delegate = [AppDelegate sharedDelegate];
        [delegate setNetworkActivityIndicatorVisible:YES];
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   [delegate setNetworkActivityIndicatorVisible:NO];
                                   if (error) {
                                       failure(error);
                                   }
                                   else {
                                       NSArray *posts = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                       BookmarksSuccessBlock(posts, nil);
                                   }
                               }];
    });
}

- (void)updatePostsFromDatabase:(void (^)())success failure:(void (^)(NSError *))failure {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *results = [db executeQuery:self.query withParameterDictionary:self.queryParameters];
        
        NSArray *oldPosts = [self.posts copy];
        NSMutableArray *newPosts = [NSMutableArray array];
        
        NSMutableArray *oldHashes = [NSMutableArray array];
        NSMutableDictionary *oldMetas = [NSMutableDictionary dictionary];
        for (NSDictionary *post in self.posts) {
            [oldHashes addObject:post[@"hash"]];
            oldMetas[post[@"hash"]] = post[@"meta"];
        }

        NSInteger index = 0;
        
        // The index of the list that `index` corresponds to
        NSInteger skipPivot = 0;
        BOOL postFound = NO;
        
        while ([results next]) {
            postFound = NO;
            NSString *hash = [results stringForColumn:@"hash"];
            NSString *meta = [results stringForColumn:@"meta"];
            NSDictionary *post;
            
            // Go from the last found value to the end of the list.
            // If you find something, break and set the pivot to the current skip index.
            for (NSInteger i=skipPivot; i<oldHashes.count; i++) {
                if ([oldHashes[i] isEqualToString:hash]) {
                    post = oldPosts[i];
                    
                    // Reload the post if its meta value has changed.
                    if (![meta isEqualToString:oldMetas[hash]]) {
                        post = [PinboardDataSource postFromResultSet:results];
                    }

                    postFound = YES;
                    skipPivot = i+1;
                    break;
                }
            }
            
            // If the post wasn't found by looping through, it's a new one
            if (!postFound) {
                post = [PinboardDataSource postFromResultSet:results];
            }
            
            [newPosts addObject:post];
            index++;
        }
        [db close];
        
        NSMutableArray *newStrings = [NSMutableArray array];
        NSMutableArray *newHeights = [NSMutableArray array];
        NSMutableArray *newLinks = [NSMutableArray array];
        NSMutableArray *newBadges = [NSMutableArray array];

        NSMutableArray *newCompressedStrings = [NSMutableArray array];
        NSMutableArray *newCompressedHeights = [NSMutableArray array];
        NSMutableArray *newCompressedLinks = [NSMutableArray array];
        NSMutableArray *newCompressedBadges = [NSMutableArray array];
        dispatch_group_t group = dispatch_group_create();
        for (NSDictionary *post in newPosts) {
            dispatch_group_enter(group);
            [self metadataForPost:post callback:^(NSAttributedString *string, NSNumber *height, NSArray *links, NSArray *badges) {
                [newHeights addObject:height];
                [newStrings addObject:string];
                [newLinks addObject:links];
                [newBadges addObject:badges];
                dispatch_group_leave(group);
            }];

            dispatch_group_enter(group);
            [self compressedMetadataForPost:post callback:^(NSAttributedString *string, NSNumber *height, NSArray *links, NSArray *badges) {
                [newCompressedHeights addObject:height];
                [newCompressedStrings addObject:string];
                [newCompressedLinks addObject:links];
                [newCompressedBadges addObject:badges];
                dispatch_group_leave(group);
            }];
        }
        
        self.posts = newPosts;
        self.strings = newStrings;
        self.heights = newHeights;
        self.links = newLinks;
        self.badges = newBadges;
        
        self.compressedStrings = newCompressedStrings;
        self.compressedHeights = newCompressedHeights;
        self.compressedLinks = newCompressedLinks;
        self.compressedBadges = newCompressedBadges;
        
        if (success) {
            dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                success();
            });
        }
    });
}

- (void)updatePostsFromDatabaseWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *results = [db executeQuery:self.query withParameterDictionary:self.queryParameters];
        
        NSArray *oldPosts = [self.posts copy];
        NSMutableArray *newPosts = [NSMutableArray array];

        NSMutableArray *oldHashes = [NSMutableArray array];
        NSMutableDictionary *oldMetas = [NSMutableDictionary dictionary];
        for (NSDictionary *post in self.posts) {
            [oldHashes addObject:post[@"hash"]];
            oldMetas[post[@"hash"]] = post[@"meta"];
        }
        
        NSMutableArray *indexPathsToAdd = [NSMutableArray array];
        NSMutableArray *indexPathsToRemove = [NSMutableArray array];
        NSMutableArray *indexPathsToReload = [NSMutableArray array];
        NSInteger index = 0;
        
        // The index of the list that `index` corresponds to
        NSInteger skipPivot = 0;
        BOOL postFound = NO;

        while ([results next]) {
            postFound = NO;
            NSString *hash = [results stringForColumn:@"hash"];
            NSString *meta = [results stringForColumn:@"meta"];
            NSDictionary *post;

            // Go from the last found value to the end of the list.
            // If you find something, break and set the pivot to the current skip index.

            for (NSInteger i=skipPivot; i<oldHashes.count; i++) {
                if ([oldHashes[i] isEqualToString:hash]) {
                    // Delete all posts that were skipped
                    for (NSInteger j=skipPivot; j<i; j++) {
                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:j inSection:0]];
                    }

                    post = oldPosts[i];

                    // Reload the post if its meta value has changed.
                    if (![meta isEqualToString:oldMetas[hash]]) {
                        post = [PinboardDataSource postFromResultSet:results];

                        // Reloads affect the old index path
                        [indexPathsToReload addObject:[NSIndexPath indexPathForRow:skipPivot inSection:0]];
                    }

                    postFound = YES;
                    skipPivot = i+1;
                    break;
                }
            }

            // If the post wasn't found by looping through, it's a new one
            if (!postFound) {
                post = [PinboardDataSource postFromResultSet:results];
                [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            }

            [newPosts addObject:post];
            index++;
        }
        [db close];
        
        for (NSInteger i=skipPivot; i<oldHashes.count; i++) {
            [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }

        NSMutableArray *newStrings = [NSMutableArray array];
        NSMutableArray *newHeights = [NSMutableArray array];
        NSMutableArray *newLinks = [NSMutableArray array];
        NSMutableArray *newBadges = [NSMutableArray array];
        
        NSMutableArray *newCompressedStrings = [NSMutableArray array];
        NSMutableArray *newCompressedHeights = [NSMutableArray array];
        NSMutableArray *newCompressedLinks = [NSMutableArray array];
        NSMutableArray *newCompressedBadges = [NSMutableArray array];
        dispatch_group_t group = dispatch_group_create();
        for (NSDictionary *post in newPosts) {
            dispatch_group_enter(group);
            [self metadataForPost:post callback:^(NSAttributedString *string, NSNumber *height, NSArray *links, NSArray *badges) {
                [newHeights addObject:height];
                [newStrings addObject:string];
                [newLinks addObject:links];
                [newBadges addObject:badges];
                dispatch_group_leave(group);
            }];
            
            dispatch_group_enter(group);
            [self compressedMetadataForPost:post callback:^(NSAttributedString *string, NSNumber *height, NSArray *links, NSArray *badges) {
                [newCompressedHeights addObject:height];
                [newCompressedStrings addObject:string];
                [newCompressedLinks addObject:links];
                [newCompressedBadges addObject:badges];
                dispatch_group_leave(group);
            }];
        }

        self.posts = newPosts;
        self.strings = newStrings;
        self.heights = newHeights;
        self.links = newLinks;
        self.badges = newBadges;

        self.compressedStrings = newCompressedStrings;
        self.compressedHeights = newCompressedHeights;
        self.compressedLinks = newCompressedLinks;
        self.compressedBadges = newBadges;
        
        if (success) {
            dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                success(indexPathsToAdd, indexPathsToReload, indexPathsToRemove);
            });
        }
    });
}

- (void)updatePostsWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure options:(NSDictionary *)options {
    [self updateLocalDatabaseFromRemoteAPIWithSuccess:^{
        [self updatePostsFromDatabaseWithSuccess:success failure:failure];
    } failure:failure progress:nil options:options];
}

- (BOOL)isPostAtIndexStarred:(NSInteger)index {
    return [self.posts[index][@"starred"] boolValue];
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
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard bookmarkWithURL:url
                      success:^(NSDictionary *bookmark) {
                          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                              if ([bookmark[@"toread"] isEqualToString:@"no"]) {
                                  // Bookmark has already been marked as read on server.
                                  FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                  [db open];
                                  [db executeUpdate:@"UPDATE bookmark SET unread=0, meta=random() WHERE hash=?" withArgumentsInArray:@[bookmark[@"hash"]]];
                                  [db close];
                                  
                                  callback(nil);
                                  return;
                              }
                              
                              NSMutableDictionary *newBookmark = [NSMutableDictionary dictionaryWithDictionary:bookmark];
                              newBookmark[@"toread"] = @"no";
                              newBookmark[@"url"] = newBookmark[@"href"];
                              [newBookmark removeObjectsForKeys:@[@"href", @"hash", @"meta", @"time"]];
                              [pinboard addBookmark:newBookmark
                                            success:^{
                                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                                    [db open];
                                                    [db executeUpdate:@"UPDATE bookmark SET unread=0, meta=random() WHERE hash=?" withArgumentsInArray:@[bookmark[@"hash"]]];
                                                    [db close];
                                                    callback(nil);
                                                });
                                            }
                                            failure:^(NSError *error) {
                                                callback(error);
                                            }];
                          });
                      }
                      failure:^(NSError *error) {
                          if (error.code == PinboardErrorBookmarkNotFound) {
                              callback(error);
                          }
                      }];
}

- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths callback:(void (^)(NSArray *, NSArray *))callback {
    void (^SuccessBlock)();
    void (^ErrorBlock)(NSError *);

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    ASPinboard *pinboard = [ASPinboard sharedInstance];
    NSMutableArray *indexPathsToDelete = [NSMutableArray array];
    NSMutableArray *indexPathsToAdd = [NSMutableArray array];
    __block NSInteger numberOfPostsDeleted = 0;
    NSString *url;

    for (NSIndexPath *indexPath in indexPaths) {
        url = self.posts[indexPath.row][@"url"];
        SuccessBlock = ^{
            NSString *hash = self.posts[indexPath.row][@"hash"];
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            [db beginTransaction];
            [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[hash]];
            [db executeUpdate:@"DELETE FROM bookmark WHERE hash=?" withArgumentsInArray:@[hash]];
            [db commit];
            [db close];

            [[Mixpanel sharedInstance] track:@"Deleted bookmark"];
            
            [self.posts removeObjectAtIndex:indexPath.row];

            [indexPathsToDelete addObject:indexPath];
            numberOfPostsDeleted++;
            dispatch_group_leave(group);
        };

        ErrorBlock = ^(NSError *error) {
            dispatch_group_leave(group);
        };

        dispatch_group_enter(group);
        [pinboard deleteBookmarkWithURL:url success:SuccessBlock failure:ErrorBlock];
    }

    dispatch_group_notify(group, queue, ^{
        NSInteger previousPostCount = [self numberOfPosts];
        dispatch_group_t inner_group = dispatch_group_create();

        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_name=tag.name)"];
        [db executeUpdate:@"DELETE FROM tag WHERE count=0"];

        // NOTE: Previously, new posts were loaded here.  We should let the GenericPostViewController handle any necessary refreshes to avoid consistency issues

        if (callback) {
            dispatch_group_notify(inner_group, queue, ^{
                callback(indexPathsToDelete, indexPathsToAdd);
            });
        }
    });
}

- (void)deletePosts:(NSArray *)posts callback:(void (^)(NSIndexPath *))callback {
    void (^SuccessBlock)();
    void (^ErrorBlock)(NSError *);
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    for (NSDictionary *post in posts) {
        SuccessBlock = ^{
            dispatch_group_async(group, queue, ^{
                FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                [db open];

                [db beginTransaction];
                [db executeUpdate:@"DELETE FROM bookmark WHERE url=?" withArgumentsInArray:@[post[@"url"]]];
                [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[post[@"hash"]]];
                [db commit];
                [db close];
                
                [[Mixpanel sharedInstance] track:@"Deleted bookmark"];

                NSUInteger index = [self.posts indexOfObject:post];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [self.posts removeObjectAtIndex:index];
                [self.heights removeObjectAtIndex:index];
                [self.strings removeObjectAtIndex:index];
                [self.links removeObjectAtIndex:index];
                callback(indexPath);
            });
        };
        
        ErrorBlock = ^(NSError *error) {
            callback(nil);
        };
        
        [pinboard deleteBookmarkWithURL:post[@"url"] success:SuccessBlock failure:ErrorBlock];
    }
    
    dispatch_group_notify(group, queue, ^{
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.userInfo = @{@"success": @YES, @"updated": @NO};
        if ([posts count] == 1) {
            notification.alertBody = NSLocalizedString(@"Your bookmark was deleted.", nil);
        }
        else {
            notification.alertBody = [NSString stringWithFormat:@"%d bookmarks were deleted.", [posts count]];
        }
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    });
}

- (NSArray *)actionsForPost:(NSDictionary *)post {
    NSMutableArray *actions = [NSMutableArray array];
    [actions addObject:@(PPPostActionDelete)];
    [actions addObject:@(PPPostActionEdit)];
    
    if ([post[@"unread"] boolValue]) {
        [actions addObject:@(PPPostActionMarkAsRead)];
    }
    
    [actions addObject:@(PPPostActionCopyURL)];
    
    if ([[AppDelegate sharedDelegate] readlater]) {
        [actions addObject:@(PPPostActionReadLater)];        
    }

    return actions;
}

- (void)compressedMetadataForPost:(NSDictionary *)post callback:(void (^)(NSAttributedString *, NSNumber *, NSArray *, NSArray *))callback {
    [self metadataForPost:post compressed:YES callback:callback];
}

- (void)metadataForPost:(NSDictionary *)post callback:(void (^)(NSAttributedString *, NSNumber *, NSArray *, NSArray *))callback {
    [self metadataForPost:post compressed:NO callback:callback];
}

- (void)metadataForPost:(NSDictionary *)post compressed:(BOOL)compressed callback:(void (^)(NSAttributedString *, NSNumber *, NSArray *, NSArray *))callback {
    UIFont *titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    UIFont *descriptionFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIFont *urlFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    
    NSString *title = post[@"title"];
    NSString *description = post[@"description"];
    NSString *tags = [post[@"tags"] stringByReplacingOccurrencesOfString:@" " withString:@" · "];
    BOOL isRead = ![post[@"unread"] boolValue];
    
    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", title];
    NSRange titleRange = NSMakeRange(0, title.length);
    
    NSURL *linkUrl = [NSURL URLWithString:post[@"url"]];
    NSString *linkHost = [linkUrl host];
    NSRange linkRange = NSMakeRange((titleRange.location + titleRange.length) + 1, linkHost.length);
    [content appendString:[NSString stringWithFormat:@"\n%@", linkHost]];
    
    NSRange descriptionRange;
    if ([description isEqualToString:@""]) {
        descriptionRange = NSMakeRange(NSNotFound, 0);
    }
    else {
        descriptionRange = NSMakeRange((linkRange.location + linkRange.length) + 1, [description length]);
        [content appendString:[NSString stringWithFormat:@"\n%@", description]];
    }
    
    NSRange tagRange;
    if ([tags isEqualToString:@""]) {
        tagRange = NSMakeRange(NSNotFound, 0);
    }
    else {
        NSInteger offset = 1;
        if (descriptionRange.location != NSNotFound) {
            offset++;
        }
        tagRange = NSMakeRange(titleRange.location + titleRange.length + descriptionRange.length + offset, [tags length]);
    }

    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
    [attributedString setFont:titleFont range:titleRange];
    [attributedString setFont:descriptionFont range:descriptionRange];
    [attributedString setFont:urlFont range:linkRange];
    [attributedString setTextColor:HEX(0x33353Bff)];

    // Calculate our shorter strings if we're compressed
    if (compressed) {
        CGSize textSize = CGSizeMake([UIApplication currentSize].width - 30.0f, CGFLOAT_MAX);
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:textSize];
        NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:@"Test"];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];
        [layoutManager setHyphenationFactor:0.0];
        [layoutManager glyphRangeForTextContainer:textContainer];
        
        NSRange titleLineRange, descriptionLineRange, linkLineRange;
        
        // Get the compressed substrings
        NSAttributedString *titleAttributedString, *descriptionAttributedString, *linkAttributedString;
        
        titleAttributedString = [attributedString attributedSubstringFromRange:titleRange];
        [textStorage setAttributedString:titleAttributedString];
        (void)[layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:&titleLineRange];
        
        if (descriptionRange.location != NSNotFound) {
            descriptionAttributedString = [attributedString attributedSubstringFromRange:descriptionRange];
            [textStorage setAttributedString:descriptionAttributedString];
            
            descriptionLineRange = NSMakeRange(0, 0);
            unsigned index, numberOfLines, numberOfGlyphs = [layoutManager numberOfGlyphs];
            NSRange tempLineRange;
            for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++){
                (void)[layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&tempLineRange];
                descriptionLineRange.length += tempLineRange.length;
                if (numberOfLines >= 2) {
                    break;
                }
                index = NSMaxRange(tempLineRange);
            }
        }
        
        if (linkRange.location != NSNotFound) {
            linkAttributedString = [attributedString attributedSubstringFromRange:linkRange];
            [textStorage setAttributedString:linkAttributedString];
            (void)[layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:&linkLineRange];
        }
        
        // Re-create the main string
        NSAttributedString *tempString;
        NSUInteger extraCharacterCount = 0;
        NSUInteger trimmedCharacterCount = 0;
        if (titleAttributedString) {
            tempString = [titleAttributedString attributedSubstringFromRange:titleLineRange];
            if (titleLineRange.length < titleRange.length) {
                tempString = [self trimTrailingPunctuationFromAttributedString:tempString trimmedLength:&trimmedCharacterCount];
                attributedString = [NSMutableAttributedString attributedStringWithAttributedString:tempString];
                [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@"…"]];
                extraCharacterCount++;
            } else {
                attributedString = [NSMutableAttributedString attributedStringWithAttributedString:tempString];
            }
            [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@"\n"]];
            extraCharacterCount++;
            titleRange = NSMakeRange(0, titleLineRange.length + extraCharacterCount - trimmedCharacterCount);
        }
        
        if (linkAttributedString) {
            extraCharacterCount = 0;
            trimmedCharacterCount = 0;
            tempString = [linkAttributedString attributedSubstringFromRange:linkLineRange];
            if (linkLineRange.length < linkRange.length) {
                tempString = [self trimTrailingPunctuationFromAttributedString:tempString trimmedLength:&trimmedCharacterCount];
                [attributedString appendAttributedString:tempString];
                [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@"…"]];
                extraCharacterCount++;
            } else {
                [attributedString appendAttributedString:tempString];
            }
            [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@"\n"]];
            extraCharacterCount++;
            linkRange = NSMakeRange(titleRange.location + titleRange.length, linkLineRange.length + extraCharacterCount - trimmedCharacterCount);
        }
        
        if (descriptionAttributedString) {
            extraCharacterCount = 0;
            trimmedCharacterCount = 0;
            tempString = [descriptionAttributedString attributedSubstringFromRange:descriptionLineRange];
            if (descriptionLineRange.length < descriptionRange.length) {
                tempString = [self trimTrailingPunctuationFromAttributedString:tempString trimmedLength:&trimmedCharacterCount];
                [attributedString appendAttributedString:tempString];
                [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@"…"]];
                extraCharacterCount++;
            } else {
                [attributedString appendAttributedString:tempString];
            }
            descriptionRange = NSMakeRange(linkRange.location + linkRange.length, descriptionLineRange.length + extraCharacterCount - trimmedCharacterCount);
        }
    }
    
    if (isRead && [AppDelegate sharedDelegate].dimReadPosts) {
        [attributedString setTextColor:HEX(0xb3b3b3ff) range:titleRange];
        [attributedString setTextColor:HEX(0x96989Dff) range:descriptionRange];
        [attributedString setTextColor:HEX(0xcdcdcdff) range:linkRange];
    }
    else {
        [attributedString setTextColor:HEX(0x000000ff) range:titleRange];
        [attributedString setTextColor:HEX(0x585858ff) range:descriptionRange];
        [attributedString setTextColor:HEX(0xb4b6b9ff) range:linkRange];
    }
    
    //[attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];

    NSNumber *height = @([attributedString sizeConstrainedToSize:CGSizeMake([UIApplication currentSize].width - 20, CGFLOAT_MAX)].height);

    NSMutableArray *badges = [NSMutableArray array];
    if ([post[@"private"] boolValue]) [badges addObject:@{ @"type": @"image", @"image": @"bookmark-private" }];
    if ([post[@"starred"] boolValue]) [badges addObject:@{ @"type": @"image", @"image": @"bookmark-favorite" }];
    if (post[@"tags"] && ![post[@"tags"] isEqualToString:@""]) {
        NSArray *tagsArray = [post[@"tags"] componentsSeparatedByString:@" "];
        [tagsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![obj hasPrefix:@"via:"]) {
                if (isRead && [AppDelegate sharedDelegate].dimReadPosts) {
                    [badges addObject:@{ @"type": @"tag", @"tag": obj, PPBadgeNormalBackgroundColor: HEX(0xf0f0f0ff) }];
                } else {
                    [badges addObject:@{ @"type": @"tag", @"tag": obj }];
                }
            }
        }];
    }
    
    callback(attributedString, height, @[], badges);
}

- (PPNavigationController *)editViewControllerForPostAtIndex:(NSInteger)index withDelegate:(id<ModalDelegate>)delegate {
    return [AddBookmarkViewController addBookmarkViewControllerWithBookmark:self.posts[index] update:@(YES) delegate:delegate callback:nil];
}

- (void)handleTapOnLinkWithURL:(NSURL *)url callback:(void (^)(UIViewController *))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *tag = [url.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        if (![self.tags containsObject:tag]) {
            PinboardDataSource *pinboardDataSource = [self dataSourceWithAdditionalTag:tag];

            dispatch_async(dispatch_get_main_queue(), ^{
                GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
                postViewController.postDataSource = pinboardDataSource;
                postViewController.title = [pinboardDataSource.tags componentsJoinedByString:@"+"];
                callback(postViewController);
            });
        }
    });
}

- (NSAttributedString *)attributedStringForPostAtIndex:(NSInteger)index {
    return self.strings[index];
}

- (CGFloat)heightForPostAtIndex:(NSInteger)index {
    return [self.heights[index] floatValue];
}

- (NSArray *)linksForPostAtIndex:(NSInteger)index {
    return self.links[index];
}

- (CGFloat)compressedHeightForPostAtIndex:(NSInteger)index {
    return [self.compressedHeights[index] floatValue];
}

- (NSArray *)compressedLinksForPostAtIndex:(NSInteger)index {
    return self.compressedLinks[index];
}

- (NSAttributedString *)compressedAttributedStringForPostAtIndex:(NSInteger)index {
    return self.compressedStrings[index];
}

- (NSArray *)badgesForPostAtIndex:(NSInteger)index {
    return self.badges[index];
}

- (BOOL)supportsTagDrilldown {
    return YES;
}

+ (NSDictionary *)postFromResultSet:(FMResultSet *)resultSet {
    NSString *title = [resultSet stringForColumn:@"title"];
    
    if ([title isEqualToString:@""]) {
        title = @"untitled";
    }
    
    NSString *hash = [resultSet stringForColumn:@"hash"];
    if (!hash) {
        hash = @"";
    }

    return @{
        @"title": title,
        @"description": [resultSet stringForColumn:@"description"],
        @"unread": @([resultSet boolForColumn:@"unread"]),
        @"url": [resultSet stringForColumn:@"url"],
        @"private": @([resultSet boolForColumn:@"private"]),
        @"tags": [resultSet stringForColumn:@"tags"],
        @"created_at": [resultSet dateForColumn:@"created_at"],
        @"starred": @([resultSet boolForColumn:@"starred"]),
        @"hash": hash,
        @"meta": [resultSet stringForColumn:@"meta"],
    };
}

- (NSArray *)quotedTags {
    NSMutableArray *quotedTagComponents = [NSMutableArray array];
    for (NSString *tag in self.tags) {
        [quotedTagComponents addObject:[NSString stringWithFormat:@"\"%@\"", tag]];
    }
    return quotedTagComponents;
}

- (void)resetHeightsWithSuccess:(void (^)())success {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *newHeights = [NSMutableArray array];
        NSMutableArray *newCompressedHeights = [NSMutableArray array];
        dispatch_group_t group = dispatch_group_create();
        for (NSDictionary *post in self.posts) {
            dispatch_group_enter(group);
            [self metadataForPost:post callback:^(NSAttributedString *string, NSNumber *height, NSArray *links, NSArray *badges) {
                [newHeights addObject:height];
                dispatch_group_leave(group);
            }];
            
            dispatch_group_enter(group);
            [self compressedMetadataForPost:post callback:^(NSAttributedString *string, NSNumber *height, NSArray *links, NSArray *badges) {
                [newCompressedHeights addObject:height];
                dispatch_group_leave(group);
            }];
        }
        
        self.heights = newHeights;
        self.compressedHeights = newCompressedHeights;
        
        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            success();
        });
    });
}

- (NSAttributedString *)trimTrailingPunctuationFromAttributedString:(NSAttributedString *)string trimmedLength:(NSUInteger *)trimmed {
    NSRange punctuationRange = [string.string rangeOfCharacterFromSet:[NSCharacterSet punctuationCharacterSet] options:NSBackwardsSearch];
    if (punctuationRange.location != NSNotFound && (punctuationRange.location + punctuationRange.length) >= string.length) {
        *trimmed = string.length - punctuationRange.location;
        return [NSAttributedString attributedStringWithAttributedString:[string attributedSubstringFromRange:NSMakeRange(0, punctuationRange.location)]];
    }
    
    *trimmed = 0;
    return string;
}

@end
