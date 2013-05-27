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
        self.stringsForPosts = [NSMutableDictionary dictionary];
        self.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"offset": @(0), @"limit": @(50)}];
        self.tags = @[];
    }
    return self;
}

- (void)filterWithParameters:(NSDictionary *)parameters {
    NSNumber *isPrivate = parameters[@"private"];
    NSNumber *isRead = parameters[@"read"];
    NSNumber *hasTags = parameters[@"tagged"];
    NSArray *tags = parameters[@"tags"];
    NSInteger offset = [parameters[@"offset"] integerValue];
    NSInteger limit = [parameters[@"limit"] integerValue];

    [self filterByPrivate:isPrivate isRead:isRead hasTags:hasTags tags:tags offset:offset limit:limit];
}

- (void)filterWithQuery:(NSString *)query {
    query = [query stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    if ([query rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"]].location == NSNotFound) {
        self.queryParameters[@"query"] = [query stringByAppendingString:@"*"];        
    }
    else {
        self.queryParameters[@"query"] = query;
    }
}

- (PinboardDataSource *)searchDataSource {
    PinboardDataSource *search = [[PinboardDataSource alloc] init];

    search.maxResults = 50;

    NSMutableArray *queryComponents = [NSMutableArray array];
    if (self.queryParameters[@"private"]) {
        [queryComponents addObject:@"private = :private"];
    }
    
    if (self.queryParameters[@"unread"]) {
        [queryComponents addObject:@"unread = :unread"];
    }
    
    if (self.queryParameters[@"tags"]) {
        [queryComponents addObject:@"tags = :tags"];
    }
    
    if (self.tags.count > 0) {
        NSString *tagComponent = [self.tags componentsJoinedByString:@", "];
        [queryComponents addObject:[NSString stringWithFormat:@"id IN (SELECT bookmark_id FROM tagging WHERE tag_id IN (%@))", tagComponent]];
    }

    [queryComponents addObject:@"id in (SELECT id FROM bookmark_fts WHERE bookmark_fts MATCH :query)"];


    NSString *whereComponent = [queryComponents componentsJoinedByString:@" AND "];
    search.query = [NSString stringWithFormat:@"SELECT * FROM bookmark WHERE %@ ORDER BY created_at DESC LIMIT :limit OFFSET :offset", whereComponent];
    search.queryParameters = [NSMutableDictionary dictionaryWithDictionary:self.queryParameters];
    search.queryParameters[@"offset"] = @(0);
    search.queryParameters[@"limit"] = @(50);
    search.queryParameters[@"query"] = @"*";
    search.tags = [self.tags copy];
    return search;
}

- (PinboardDataSource *)dataSourceWithAdditionalTagID:(NSNumber *)tagID {
    PinboardDataSource *dataSource = [[PinboardDataSource alloc] init];
    
    dataSource.maxResults = 50;
    
    NSMutableArray *queryComponents = [NSMutableArray array];
    if (self.queryParameters[@"private"]) {
        [queryComponents addObject:@"private = :private"];
    }
    
    if (self.queryParameters[@"unread"]) {
        [queryComponents addObject:@"unread = :unread"];
    }

    if (self.queryParameters[@"tags"]) {
        [queryComponents addObject:@"tags = :tags"];
    }
    
    NSMutableArray *newTags = [NSMutableArray arrayWithArray:self.tags];
    if (![newTags containsObject:tagID]) {
        [newTags addObject:tagID];
    }
    
    for (NSNumber *tagID in newTags) {
        [queryComponents addObject:[NSString stringWithFormat:@"id IN (SELECT bookmark_id FROM tagging WHERE tag_id=%@)", tagID]];
    }

    NSString *whereComponent = [queryComponents componentsJoinedByString:@" AND "];

    dataSource.query = [NSString stringWithFormat:@"SELECT * FROM bookmark WHERE %@ ORDER BY created_at DESC LIMIT :limit OFFSET :offset", whereComponent];
    dataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:self.queryParameters];
    dataSource.queryParameters[@"offset"] = @(0);
    dataSource.queryParameters[@"limit"] = @(50);
    dataSource.tags = newTags;
    return dataSource;
}

- (void)filterByPrivate:(NSNumber *)isPrivate isRead:(NSNumber *)isRead hasTags:(NSNumber *)hasTags tags:(NSArray *)tags offset:(NSInteger)offset limit:(NSInteger)limit {
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
    
    if (hasTags) {
        [queryComponents addObject:@"tags = :tags"];
        parameters[@"tags"] = hasTags;
    }

    self.queryParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];

    if (tags != nil && [tags count] > 0) {
        self.tags = [tags copy];
        NSString *tagComponent = [tags componentsJoinedByString:@", "];
        [queryComponents addObject:[NSString stringWithFormat:@"id IN (SELECT bookmark_id FROM tagging WHERE tag_id IN (%@))", tagComponent]];
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
        self.queryParameters[@"limit"] = @(limit + 50);
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
    NSDate *lastUpdated = [[AppDelegate sharedDelegate] lastUpdated];
    
    if (!progress) {
        progress = ^(NSInteger current, NSInteger total) {};
    }
    
    if (!success) {
        success = ^{};
    }

    void (^BookmarksSuccessBlock)(NSArray *) = ^(NSArray *elements) {
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
        NSNumber *tagIdNumber;
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
        [[NSNotificationCenter defaultCenter] postNotificationName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(0), @"total": @(total)}];
        for (NSDictionary *element in elements) {
            progress(count, total);
            [[NSNotificationCenter defaultCenter] postNotificationName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(count), @"total": @(total)}];
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
                               @"title": element[@"description"],
                               @"description": element[@"extended"],
                               @"meta": element[@"meta"],
                               @"hash": element[@"hash"],
                               @"tags": element[@"tags"],
                               @"unread": @([element[@"toread"] isEqualToString:@"yes"]),
                               @"private": @([element[@"shared"] isEqualToString:@"no"])
                            };

                    [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, url=:url, private=:private, unread=:unread, tags=:tags, meta=:meta WHERE hash=:hash" withParameterDictionary:params];
                    [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_id IN (SELECT id FROM bookmark WHERE hash=?)" withArgumentsInArray:@[element[@"hash"]]];
                }
            }
            else {
                newBookmarkCount++;
                updated_or_created = YES;
                params = @{
                       @"url": element[@"href"],
                       @"title": element[@"description"],
                       @"description": element[@"extended"],
                       @"meta": element[@"meta"],
                       @"hash": element[@"hash"],
                       @"tags": element[@"tags"],
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
                for (id tagName in [element[@"tags"] componentsSeparatedByString:@" "]) {
                    tagIdNumber = [tags objectForKey:tagName];
                    if (!tagIdNumber) {
                        [db executeUpdate:@"INSERT INTO tag (name) VALUES (?)" withArgumentsInArray:@[tagName]];
                        
                        results = [db executeQuery:@"SELECT last_insert_rowid();"];
                        [results next];
                        tagIdNumber = @([results intForColumnIndex:0]);
                        [tags setObject:tagIdNumber forKey:tagName];
                    }
                    
                    [db executeUpdate:@"INSERT OR IGNORE INTO tagging (tag_id, bookmark_id) SELECT ?, bookmark.id FROM bookmark WHERE bookmark.hash=?" withArgumentsInArray:@[tagIdNumber, element[@"hash"]]];
                }
            }

            count++;
        }
        [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_id=tag.id)"];
        
        for (NSString *bookmarkHash in bookmarksToDelete) {
            [db executeUpdate:@"DELETE FROM bookmark WHERE hash=?" withArgumentsInArray:@[bookmarkHash]];
        }

        [db commit];
        [db close];

        [[AppDelegate sharedDelegate] setLastUpdated:[NSDate date]];
        progress(total, total);
        [[NSNotificationCenter defaultCenter] postNotificationName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(total), @"total": @(total)}];
    };
    
    void (^BookmarksFailureBlock)(NSError *) = ^(NSError *error) {
        if (failure) {
            failure(error);
        }
    };
    
    void (^BookmarksUpdatedTimeSuccessBlock)(NSDate *) = ^(NSDate *updateTime) {
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_group_enter(group);
        if ([lastUpdated compare:updateTime] == NSOrderedAscending || ([[NSDate date] timeIntervalSinceReferenceDate] - [lastUpdated timeIntervalSinceReferenceDate] > 300)) {
            dispatch_group_enter(group);
            [pinboard bookmarksWithTags:nil
                                 offset:-1
                                  count:[options[@"count"] integerValue]
                               fromDate:nil
                                 toDate:nil
                            includeMeta:YES
                                success:^(NSArray *bookmarks) {
                BookmarksSuccessBlock(bookmarks);
                [self updateStarredPosts:^{ dispatch_group_leave(group); } failure:^{ dispatch_group_leave(group); }];
                dispatch_group_leave(group);
            }
                                failure:BookmarksFailureBlock];
            
        }
        else {
            dispatch_group_leave(group);
        }

        dispatch_group_notify(group, queue, ^{
            success();
        });
    };
    
    [pinboard lastUpdateWithSuccess:BookmarksUpdatedTimeSuccessBlock failure:failure];
}

- (void)updateStarredPosts:(void (^)())success failure:(void (^)())failure {
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
                                   NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                   FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                   [db open];
                                   [db beginTransaction];

                                   [db executeUpdate:@"UPDATE bookmark SET starred=0 WHERE starred=1"];
                                   for (NSDictionary *post in payload) {
                                       [db executeUpdate:@"UPDATE bookmark SET starred=1 WHERE url=?" withArgumentsInArray:@[post[@"u"]]];
                                   }
                                   [db commit];
                                   [db close];

                                   success();
                               }
                           }];
}

- (void)updatePostsFromDatabaseWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure {
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:self.query withParameterDictionary:self.queryParameters];
    
    NSMutableArray *newPosts = [NSMutableArray array];
    NSMutableArray *newURLs = [NSMutableArray array];
    
    NSMutableArray *oldPosts = [self.posts copy];
    NSMutableArray *oldURLs = [NSMutableArray array];
    for (NSDictionary *post in self.posts) {
        [oldURLs addObject:post[@"url"]];
    }
    
    NSMutableArray *indexPathsToAdd = [NSMutableArray array];
    NSMutableArray *indexPathsToRemove = [NSMutableArray array];
    NSMutableArray *indexPathsToReload = [NSMutableArray array];
    NSInteger index = 0;
    
    while ([results next]) {
        NSString *title = [results stringForColumn:@"title"];
        
        if ([title isEqualToString:@""]) {
            title = @"untitled";
        }
        NSDictionary *post = @{
               @"title": title,
               @"description": [results stringForColumn:@"description"],
               @"unread": @([results boolForColumn:@"unread"]),
               @"url": [results stringForColumn:@"url"],
               @"private": @([results boolForColumn:@"private"]),
               @"tags": [[results stringForColumn:@"tags"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
               @"created_at": [results dateForColumn:@"created_at"],
               @"starred": @([results boolForColumn:@"starred"])
           };
        
        [newPosts addObject:post];
        [newURLs addObject:post[@"url"]];
        
        if (![oldPosts containsObject:post]) {
            // Check if the bookmark is being updated (as opposed to entirely new)
            if ([oldURLs containsObject:post[@"url"]]) {
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            }
            else {
                [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            }
        }
        index++;
    }
    [db close];
    
    for (int i=0; i<oldURLs.count; i++) {
        if (![newURLs containsObject:oldURLs[i]]) {
            [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    }

    self.posts = newPosts;
    
    if (success != nil) {
        success(indexPathsToAdd, indexPathsToReload, indexPathsToRemove);
    }
}

- (void)updatePostsWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure options:(NSDictionary *)options {
    [self updateLocalDatabaseFromRemoteAPIWithSuccess:^{
        [self updatePostsFromDatabaseWithSuccess:success failure:failure];
    } failure:failure progress:nil options:options];
}

- (NSString *)titleForPostAtIndex:(NSInteger)index {
    return [self.posts[index][@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (NSString *)descriptionForPostAtIndex:(NSInteger)index {
    return [self.posts[index][@"description"] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (NSString *)tagsForPostAtIndex:(NSInteger)index {
    return [self.posts[index][@"tags"] stringByReplacingOccurrencesOfString:@" " withString:@" · "];
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

- (NSDate *)dateForPostAtIndex:(NSInteger)index {
    return self.posts[index][@"created_at"];
}

- (NSString *)formattedDateForPostAtIndex:(NSInteger)index {
    NSDateFormatter *relativeDateFormatter = [[NSDateFormatter alloc] init];
    [relativeDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [relativeDateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [relativeDateFormatter setLocale:locale];
    [relativeDateFormatter setDoesRelativeDateFormatting:YES];
    return [relativeDateFormatter stringFromDate:[self dateForPostAtIndex:index]];
}

- (void)markPostAsRead:(NSString *)url callback:(void (^)(NSError *))callback {
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard bookmarkWithURL:url
                      success:^(NSDictionary *bookmark) {
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
                      }
                      failure:^(NSError *error) {
                          if (error.code == PinboardErrorBookmarkNotFound) {
                              callback(error);
                          }
                      }];
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
                
                FMResultSet *results = [db executeQuery:@"SELECT id FROM bookmark WHERE url=?" withArgumentsInArray:@[post[@"url"]]];
                [results next];
                NSNumber *bookmarkId = @([results intForColumnIndex:0]);
                
                [db beginTransaction];
                [db executeUpdate:@"DELETE FROM bookmark WHERE url=?" withArgumentsInArray:@[post[@"url"]]];
                [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_id=?" withArgumentsInArray:@[bookmarkId]];
                [db commit];
                [db close];
                
                [[Mixpanel sharedInstance] track:@"Deleted bookmark"];
                
                NSUInteger index = [self.posts indexOfObject:post];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [self.posts removeObjectAtIndex:index];

                callback(indexPath);
            });
        };
        
        ErrorBlock = ^(NSError *error) {
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
    NSMutableArray *links = [NSMutableArray array];
    NSInteger location = [self rangeForTagsForPostAtIndex:index].location;
    NSString *tags = [self.posts[index][@"tags"] stringByReplacingOccurrencesOfString:@" " withString:@" * "];
    for (NSString *tag in [tags componentsSeparatedByString:@" * "]) {
        NSRange range = [tags rangeOfString:tag];
        [links addObject:@{@"url": [NSURL URLWithString:[tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]], @"location": @(location+range.location), @"length": @(range.length)}];
    }
    return links;
}

- (NSAttributedString *)attributedStringForPostAtIndex:(NSInteger)index {
    UIFont *titleFont = [UIFont fontWithName:@"Avenir-Heavy" size:16.f];
    UIFont *descriptionFont = [UIFont fontWithName:@"Avenir-Book" size:14.f];
    UIFont *tagsFont = [UIFont fontWithName:@"Avenir-Medium" size:12];
    UIFont *dateFont = [UIFont fontWithName:@"Avenir-Medium" size:10];

    NSString *title = [self titleForPostAtIndex:index];
    NSString *description = [self descriptionForPostAtIndex:index];
    NSString *tags = [self tagsForPostAtIndex:index];
    NSString *dateString = [self formattedDateForPostAtIndex:index];
    BOOL isRead = [self isPostAtIndexRead:index];
    
    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", title];
    NSRange titleRange = [self rangeForTitleForPostAtIndex:index];
    
    NSRange descriptionRange = [self rangeForDescriptionForPostAtIndex:index];
    if (descriptionRange.location != NSNotFound) {
        [content appendString:[NSString stringWithFormat:@"\n%@", description]];
    }
    
    NSRange tagRange = [self rangeForTagsForPostAtIndex:index];
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
    return attributedString;
}

- (NSRange)rangeForTitleForPostAtIndex:(NSInteger)index {
    return NSMakeRange(0, [[self titleForPostAtIndex:index] length]);
}

- (NSRange)rangeForDescriptionForPostAtIndex:(NSInteger)index {
    NSString *description = [self descriptionForPostAtIndex:index];
    if ([description isEqualToString:@""]) {
        return NSMakeRange(NSNotFound, 0);
    }
    else {
        NSRange titleRange = [self rangeForTitleForPostAtIndex:index];
        return NSMakeRange(titleRange.location + titleRange.length + 1, [description length]);
    }
}

- (NSRange)rangeForTagsForPostAtIndex:(NSInteger)index {
    NSString *tags = [self tagsForPostAtIndex:index];
    if ([tags isEqualToString:@""]) {
        return NSMakeRange(NSNotFound, 0);
    }
    else {
        NSRange titleRange = [self rangeForTitleForPostAtIndex:index];
        NSRange descriptionRange = [self rangeForDescriptionForPostAtIndex:index];
        NSInteger offset = 1;
        if (descriptionRange.location != NSNotFound) {
            offset++;
        }
        return NSMakeRange(titleRange.location + titleRange.length + descriptionRange.length + offset, [tags length]);
    }
}

- (UIViewController *)editViewControllerForPostAtIndex:(NSInteger)index withDelegate:(id<ModalDelegate>)delegate {
    UINavigationController *navigationController = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:self.posts[index] update:@(YES) delegate:delegate callback:nil];
    return navigationController;
}

- (BOOL)supportsSearch {
    return YES;
}

@end
