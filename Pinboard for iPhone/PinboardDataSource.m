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

static BOOL kPinboardDataSourceUpdateInProgress = NO;

@implementation PinboardDataSource

@synthesize query = _query;
@synthesize queryParameters = _queryParameters;
@synthesize posts = _posts;
@synthesize heights = _heights;
@synthesize strings = _strings;
@synthesize urls;
@synthesize maxResults;

- (id)init {
    self = [super init];
    if (self) {
        self.posts = [NSMutableArray array];
        self.strings = [NSMutableArray array];
        self.heights = [NSMutableArray array];
        self.links = [NSMutableArray array];

        self.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"offset": @(0), @"limit": @(50)}];
        self.tags = @[];

        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        self.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [self.dateFormatter setLocale:self.locale];
        [self.dateFormatter setDoesRelativeDateFormatting:YES];
    }
    return self;
}

- (id)initWithParameters:(NSDictionary *)parameters {
    self = [super init];
    if (self) {
        self.posts = [NSMutableArray array];
        self.strings = [NSMutableArray array];
        self.heights = [NSMutableArray array];
        self.links = [NSMutableArray array];

        self.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"offset": @(0), @"limit": @(50)}];
        self.tags = @[];

        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        self.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
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
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *result = [db executeQuery:@"SELECT COUNT(*) FROM bookmark;"];
    [result next];
    NSInteger count = [result intForColumnIndex:0];
    [db close];
    return count;
}

- (void)updateLocalDatabaseFromRemoteAPIWithSuccess:(void (^)())success failure:(void (^)())failure progress:(void (^)(NSInteger, NSInteger))progress options:(NSDictionary *)options {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    
    if (!progress) {
        progress = ^(NSInteger current, NSInteger total) {};
    }
    
    if (!success) {
        success = ^{};
    }

    void (^BookmarksSuccessBlock)(NSArray *) = ^(NSArray *elements) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            
            [db beginTransaction];
            [db executeUpdate:@"DELETE FROM bookmark WHERE hash IS NULL"];
            
            FMResultSet *results;
            
            results = [db executeQuery:@"SELECT id, name FROM tag"];
            NSMutableDictionary *tags = [[NSMutableDictionary alloc] init];
            
            while ([results next]) {
                [tags setObject:@([results intForColumn:@"id"]) forKey:[results stringForColumn:@"name"]];
            }
            results = [db executeQuery:@"SELECT meta, hash FROM bookmark ORDER BY created_at DESC"];
            
            NSMutableDictionary *metas = [[NSMutableDictionary alloc] init];
            NSMutableArray *oldBookmarkHashes = [[NSMutableArray alloc] init];
            while ([results next]) {
                [oldBookmarkHashes addObject:[results stringForColumn:@"hash"]];
                [metas setObject:[results stringForColumn:@"meta"] forKey:[results stringForColumn:@"hash"]];
            }
            NSMutableArray *bookmarksToDelete = [[NSMutableArray alloc] init];
            
            NSString *bookmarkMeta;
            BOOL updated_or_created = NO;
            NSUInteger count = 0;
            NSUInteger skipCount = 0;
            NSUInteger newBookmarkCount = 0;
            NSUInteger total = elements.count;
            NSDictionary *params;
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
            
            [mixpanel.people set:@"Bookmarks" to:@(total)];
            
            progress(0, total);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(0), @"total": @(total)}];
            });
            for (NSDictionary *element in elements) {
                count++;
                progress(count, total);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(count), @"total": @(total)}];
                });
                
                updated_or_created = NO;
                
                bookmarkMeta = metas[element[@"hash"]];
                if (bookmarkMeta) {
                    while (skipCount < oldBookmarkHashes.count && ![oldBookmarkHashes[skipCount] isEqualToString:element[@"hash"]]) {
                        [bookmarksToDelete addObject:oldBookmarkHashes[skipCount]];
                        skipCount++;
                    }
                    skipCount++;
                    
                    if (![bookmarkMeta isEqualToString:element[@"meta"]]) {
                        updated_or_created = YES;
                        params = @{
                            @"url": element[@"href"],
                            @"title": [element[@"description"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
                            @"description": [element[@"extended"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
                            @"meta": element[@"meta"],
                            @"hash": element[@"hash"],
                            @"tags": [element[@"tags"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
                            @"unread": @([element[@"toread"] isEqualToString:@"yes"]),
                            @"private": @([element[@"shared"] isEqualToString:@"no"])
                        };
                        
                        [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, url=:url, private=:private, unread=:unread, tags=:tags, meta=:meta WHERE hash=:hash" withParameterDictionary:params];
                        [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[element[@"hash"]]];
                    }
                }
                else {
                    newBookmarkCount++;
                    updated_or_created = YES;
                    params = @{
                        @"url": element[@"href"],
                        @"title": [element[@"description"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
                        @"description": [element[@"extended"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
                        @"meta": element[@"meta"],
                        @"hash": element[@"hash"],
                        @"tags": [element[@"tags"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
                        @"unread": @([element[@"toread"] isEqualToString:@"yes"]),
                        @"private": @([element[@"shared"] isEqualToString:@"no"]),
                        @"created_at": [dateFormatter dateFromString:element[@"time"]]
                    };
                    
                    [db executeUpdate:@"INSERT INTO bookmark (title, description, url, private, unread, hash, tags, meta, created_at) VALUES (:title, :description, :url, :private, :unread, :hash, :tags, :meta, :created_at);" withParameterDictionary:params];
                }
                
                if ([element[@"tags"] length] == 0) {
                    continue;
                }
                
                if (updated_or_created) {
                    [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[element[@"hash"]]];
                    for (NSString *tagName in [element[@"tags"] componentsSeparatedByString:@" "]) {
                        [db executeUpdate:@"INSERT OR IGNORE INTO tag (name) VALUES (?)" withArgumentsInArray:@[tagName]];
                        [db executeUpdate:@"INSERT INTO tagging (tag_name, bookmark_hash) VALUES (?, ?)" withArgumentsInArray:@[tagName, element[@"hash"]]];
                    }
                }
            }
            [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_name=tag.name)"];
            [db executeUpdate:@"DELETE FROM tag WHERE count=0"];

            for (NSString *bookmarkHash in bookmarksToDelete) {
                [db executeUpdate:@"DELETE FROM bookmark WHERE hash=?" withArgumentsInArray:@[bookmarkHash]];
            }
            
            [db commit];
            [db close];

            [[AppDelegate sharedDelegate] setLastUpdated:[NSDate date]];
            progress(total, total);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(total), @"total": @(total)}];
            });
        });
    };
    
    void (^BookmarksFailureBlock)(NSError *) = ^(NSError *error) {
        if (failure) {
            failure(error);
        }
    };

    void (^BookmarksUpdatedTimeSuccessBlock)(NSDate *) = ^(NSDate *updateTime) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDate *lastLocalUpdate = [[AppDelegate sharedDelegate] lastUpdated];
            BOOL neverUpdated = lastLocalUpdate == nil;
            BOOL outOfSyncWithAPI = [lastLocalUpdate compare:updateTime] == NSOrderedAscending;
            // BOOL lastUpdatedMoreThanFiveMinutesAgo = [[NSDate date] timeIntervalSinceReferenceDate] - [lastLocalUpdate timeIntervalSinceReferenceDate] > 300;
            if (neverUpdated || outOfSyncWithAPI) {
                [pinboard bookmarksWithTags:nil
                                     offset:-1
                                      count:[options[@"count"] integerValue]
                                   fromDate:nil
                                     toDate:nil
                                includeMeta:YES
                                    success:^(NSArray *bookmarks) {
                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                            BookmarksSuccessBlock(bookmarks);

                                            if (!lastLocalUpdate) {
                                                [self updateStarredPosts:^{
                                                    success();
                                                }
                                                                 failure:nil];
                                            }
                                            else {
                                                [self updateStarredPosts:nil failure:nil];
                                                success();
                                            }
                                        });
                                    }
                                    failure:^(NSError *error) {
                                        BookmarksFailureBlock(error);
                                    }];
                
            }
            else {
                success();
            }
        });
    };
    
    [pinboard lastUpdateWithSuccess:BookmarksUpdatedTimeSuccessBlock failure:failure];
}

- (void)updateStarredPosts:(void (^)())success failure:(void (^)())failure {
    if (!success) {
        success = ^{};
    }
    
    if (!failure) {
        failure = ^{};
    }

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
                                   if (failure) {
                                       failure(error);
                                   }
                               }
                               else {
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                       NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                       
                                       const char *dbPath = [[AppDelegate databasePath] UTF8String];
                                       char *sqliteErrorMessage;
                                       sqlite3_stmt *updateStatement = nil;
                                       sqlite3 *db;
                                       sqlite3_open(dbPath, &db);
                                       sqlite3_exec(db, "BEGIN", NULL, NULL, &sqliteErrorMessage);
                                       sqlite3_exec(db, "UPDATE bookmark SET starred=0 WHERE starred=1", NULL, NULL, &sqliteErrorMessage);

                                       for (NSDictionary *post in payload) {
                                           sqlite3_prepare_v2(db, "UPDATE bookmark SET starred=1 WHERE url=?", -1, &updateStatement, NULL);
                                           sqlite3_bind_text(updateStatement, 1, [post[@"u"] UTF8String], -1, SQLITE_STATIC);
                                           sqlite3_step(updateStatement);
                                           sqlite3_finalize(updateStatement);
                                       }

                                       sqlite3_exec(db, "COMMIT", NULL, NULL, &sqliteErrorMessage);
                                       sqlite3_close(db);
                                       success();
                                   });
                               }
                           }];
}

- (void)updatePostsFromDatabaseWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *results = [db executeQuery:self.query withParameterDictionary:self.queryParameters];
        
        NSArray *oldPosts = [self.posts copy];
        NSMutableArray *newPosts = [NSMutableArray array];

        NSMutableArray *oldHashes = [NSMutableArray array];
        NSMutableArray *newHashes = [NSMutableArray array];
        NSMutableDictionary *oldHashesToMetas = [NSMutableDictionary dictionary];
        for (NSDictionary *post in self.posts) {
            [oldHashes addObject:post[@"hash"]];
            oldHashesToMetas[post[@"hash"]] = post[@"meta"];
        }
        
        NSMutableArray *indexPathsToAdd = [NSMutableArray array];
        NSMutableArray *indexPathsToRemove = [NSMutableArray array];
        NSMutableArray *indexPathsToReload = [NSMutableArray array];
        NSInteger index = 0;
        
        // The index of the list that `index` corresponds to
        NSInteger skipPivot = 0;
        BOOL postFound = NO;

        #warning XXX there is an O(n^2) algo here
        while ([results next]) {
            postFound = NO;
            NSString *hash = [results stringForColumn:@"hash"];
            [newHashes addObject:hash];

            NSDictionary *post;
            
            // Go from the last found value to the end of the list.
            // If you find something, break and set the pivot to the current skip index.

            for (NSInteger i=skipPivot; i<oldHashes.count; i++) {
                if ([oldHashes[i] isEqualToString:hash]) {
                    // Delete all posts that were skipped
                    for (NSInteger j=skipPivot; j<i; j++) {
                        [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:j inSection:0]];
                    }

                    skipPivot = i;
                    post = oldPosts[i];
                    
                    // Reload the post if its meta value has changed.
                    if (![post[@"meta"] isEqualToString:oldHashesToMetas[hash]]) {
                        post = [PinboardDataSource postFromResultSet:results];
                        
                        // Reloads effect the old index path
                        [indexPathsToReload addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                    }
                    
                    postFound = YES;
                    skipPivot++;
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

        dispatch_group_t group = dispatch_group_create();
        for (NSDictionary *post in newPosts) {
            dispatch_group_enter(group);
            [self metadataForPost:post callback:^(NSAttributedString *string, NSNumber *height, NSArray *links) {
                [newHeights addObject:height];
                [newStrings addObject:string];
                [newLinks addObject:links];
                dispatch_group_leave(group);
            }];
        }

        self.posts = newPosts;
        self.strings = newStrings;
        self.heights = newHeights;
        self.links = newLinks;
        
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

- (NSInteger)sourceForPostAtIndex:(NSInteger)index {
    return [self.posts[index][@"source"] integerValue];
}

- (BOOL)isPostAtIndexStarred:(NSInteger)index {
    return [self.posts[index][@"starred"] boolValue];
}

- (BOOL)isPostAtIndexRead:(NSInteger)index {
    return ![self.posts[index][@"unread"] boolValue];
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
                                  [db executeUpdate:@"UPDATE bookmark SET unread=0 WHERE hash=?" withArgumentsInArray:@[bookmark[@"hash"]]];
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
                                                FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                                [db open];
                                                [db executeUpdate:@"UPDATE bookmark SET unread=0 WHERE hash=?" withArgumentsInArray:@[bookmark[@"hash"]]];
                                                [db close];
                                                callback(nil);
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
        FMResultSet *results = [db executeQuery:self.query withParameterDictionary:self.queryParameters];

        NSMutableArray *newPosts = [NSMutableArray array];
        NSMutableArray *newStrings = [NSMutableArray array];
        NSMutableArray *newHeights = [NSMutableArray array];
        NSMutableArray *newLinks = [NSMutableArray array];
        while ([results next]) {
            NSDictionary *post = [PinboardDataSource postFromResultSet:results];

            [newPosts addObject:post];
            dispatch_group_enter(inner_group);
            [self metadataForPost:post callback:^(NSAttributedString *string, NSNumber *height, NSArray *links) {
                [newHeights addObject:height];
                [newStrings addObject:string];
                [newLinks addObject:links];
                dispatch_group_leave(inner_group);
            }];
        }
        [db close];

        for (int i=previousPostCount - numberOfPostsDeleted; i<newPosts.count; i++) {
            [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }

        self.posts = newPosts;
        self.strings = newStrings;
        self.heights = newHeights;
        self.links = newLinks;

        if (callback) {
            dispatch_group_notify(inner_group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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

- (NSArray *)linksForPostAtIndex:(NSInteger)index {
    return self.links[index];
}

- (void)metadataForPost:(NSDictionary *)post callback:(void (^)(NSAttributedString *, NSNumber *, NSArray *))callback {
    UIFont *titleFont = [UIFont fontWithName:@"Avenir-Heavy" size:16.f];
    UIFont *descriptionFont = [UIFont fontWithName:@"Avenir-Book" size:14.f];
    UIFont *tagsFont = [UIFont fontWithName:@"Avenir-Medium" size:12];
    UIFont *dateFont = [UIFont fontWithName:@"Avenir-Medium" size:10];

    NSString *title = post[@"title"];
    NSString *description = post[@"description"];
    NSString *tags = [post[@"tags"] stringByReplacingOccurrencesOfString:@" " withString:@" · "];
    NSString *dateString = [self.dateFormatter stringFromDate:post[@"created_at"]];
    BOOL isRead = ![post[@"unread"] boolValue];
    
    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", title];
    NSRange titleRange = NSMakeRange(0, title.length);
    
    NSRange descriptionRange;
    if ([description isEqualToString:@""]) {
        descriptionRange = NSMakeRange(NSNotFound, 0);
    }
    else {
        descriptionRange = NSMakeRange(titleRange.location + titleRange.length + 1, [description length]);
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

    BOOL hasTags = tagRange.location != NSNotFound;
    
    if (hasTags) {
        [content appendFormat:@"\n%@", tags];
    }

    [content appendFormat:@"\n%@", dateString];
    NSRange dateRange = NSMakeRange(content.length - dateString.length, dateString.length);

    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
    [attributedString setFont:titleFont range:titleRange];
    [attributedString setFont:descriptionFont range:descriptionRange];
    [attributedString setTextColor:HEX(0x33353Bff)];
    
    if (isRead) {
        [attributedString setTextColor:HEX(0x96989Dff) range:titleRange];
        [attributedString setTextColor:HEX(0x96989Dff) range:descriptionRange];
    }
    else {
        [attributedString setTextColor:HEX(0x353840ff) range:titleRange];
        [attributedString setTextColor:HEX(0x696F78ff) range:descriptionRange];
    }
    
    if (hasTags) {
        [attributedString setTextColor:HEX(0xA5A9B2ff) range:tagRange];
        [attributedString setFont:tagsFont range:tagRange];
    }
    
    [attributedString setTextColor:HEX(0xA5A9B2ff) range:dateRange];
    [attributedString setFont:dateFont range:dateRange];
    [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];

    NSNumber *height = @([attributedString sizeConstrainedToSize:CGSizeMake(300, CGFLOAT_MAX)].height + 20);

    NSMutableArray *links = [NSMutableArray array];
    NSInteger location = tagRange.location;
    for (NSString *tag in [tags componentsSeparatedByString:@" · "]) {
        NSRange range = [tags rangeOfString:tag];
        [links addObject:@{@"url": [NSURL URLWithString:[tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]], @"location": @(location+range.location), @"length": @(range.length)}];
    }

    callback(attributedString, height, links);
}

- (UIViewController *)editViewControllerForPostAtIndex:(NSInteger)index withDelegate:(id<ModalDelegate>)delegate {
    UINavigationController *navigationController = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:self.posts[index] update:@(YES) delegate:delegate callback:nil];
    return navigationController;
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

- (BOOL)supportsSearch {
    return YES;
}

- (BOOL)supportsTagDrilldown {
    return YES;
}

+ (NSDictionary *)postFromResultSet:(FMResultSet *)resultSet {
    NSString *title = [resultSet stringForColumn:@"title"];
    
    if ([title isEqualToString:@""]) {
        title = @"untitled";
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
        @"hash": [resultSet stringForColumn:@"hash"],
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

@end
