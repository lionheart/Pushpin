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

@implementation PinboardDataSource

@synthesize query = _query;
@synthesize queryParameters = _queryParameters;
@synthesize posts = _posts;
@synthesize heights = _heights;
@synthesize strings = _strings;
@synthesize urls;
@synthesize maxResults;

- (void)filterWithParameters:(NSDictionary *)parameters {
    BOOL isPrivate = [parameters[@"private"] boolValue];
    BOOL isRead = [parameters[@"read"] boolValue];
    BOOL hasTags = [parameters[@"tagged"] boolValue];
    NSArray *tags = parameters[@"tags"];
    NSInteger offset = [parameters[@"offset"] integerValue];
    NSInteger limit = [parameters[@"limit"] integerValue];

    [self filterByPrivate:isPrivate isRead:isRead hasTags:hasTags tags:tags offset:offset limit:limit];
}

- (void)filterByPrivate:(BOOL)isPrivate isRead:(BOOL)isRead hasTags:(BOOL)hasTags tags:(NSArray *)tags offset:(NSInteger)offset limit:(NSInteger)limit {
    NSMutableArray *queryComponents = [NSMutableArray array];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{@"offset": @(offset), @"limit": @(limit)}];
    self.maxResults = limit;
    
    if (&isPrivate != nil) {
        [queryComponents addObject:@"private = :private"];
        parameters[@"private"] = @(isPrivate);
    }

    if (&isRead != nil) {
        [queryComponents addObject:@"unread = :unread"];
        parameters[@"unread"] = @(!isRead);
    }
    
    if (&hasTags != nil) {
        [queryComponents addObject:@"tags = :tags"];
        parameters[@"tags"] = @(hasTags);
    }

    self.queryParameters = [NSDictionary dictionaryWithDictionary:parameters];

    if (tags != nil && [tags count] > 0) {
        NSString *tagComponent = [tags componentsJoinedByString:@", "];
        [queryComponents addObject:[NSString stringWithFormat:@"id IN (SELECT bookmark_id FROM tagging WHERE tag_id IN (%@))", tagComponent]];
    }

    if ([queryComponents count] > 0) {
        NSString *whereComponent = [queryComponents componentsJoinedByString:@" and "];
        self.query = [NSString stringWithFormat:@"SELECT * FROM bookmark WHERE %@ ORDER BY created_at LIMIT :limit OFFSET :offset", whereComponent];
    }
    else {
        self.query = @"SELECT * FROM bookmark ORDER BY created_at LIMIT :limit OFFSET :offset";
    }
}

- (void)willDisplayIndexPath:(NSIndexPath *)indexPath callback:(void (^)(BOOL))callback {
    NSInteger limit = [self.queryParameters[@"limit"] integerValue];

    BOOL needsUpdate = indexPath.row >= limit / 2;
    if (needsUpdate) {
        self.queryParameters[@"limit"] = @(limit + 50);
    }
    callback(needsUpdate);
}

- (NSInteger)numberOfPosts {
    return [self.posts count];
}

- (void)updateLocalDatabaseFromRemoteAPIWithSuccess:(void (^)())success failure:(void (^)())failure {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    NSDate *lastUpdated = [[AppDelegate sharedDelegate] lastUpdated];
    
    void (^BookmarksSuccessBlock)(NSArray *) = ^(NSArray *elements) {
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        [db beginTransaction];
        
        db.logsErrors = NO;
        [db executeUpdate:@"DELETE FROM bookmark WHERE hash IS NULL"];
        
        FMResultSet *results;
        
        results = [db executeQuery:@"SELECT * FROM tag"];
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

        for (NSDictionary *element in elements) {
            updated_or_created = NO;
            count++;

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
        }
        [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_id=tag.id)"];
        
        for (NSString *bookmarkHash in bookmarksToDelete) {
            [db executeUpdate:@"DELETE FROM bookmark WHERE hash=?" withArgumentsInArray:@[bookmarkHash]];
        }

        [db commit];
        [db close];

        [[AppDelegate sharedDelegate] setLastUpdated:[NSDate date]];
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
        [self updateStarredPosts:^{ dispatch_group_leave(group); } failure:^{ dispatch_group_leave(group); }];

        if (lastUpdated == nil || [lastUpdated compare:updateTime] == NSOrderedAscending || [[NSDate date] timeIntervalSinceReferenceDate] - [lastUpdated timeIntervalSinceReferenceDate] > 300) {

            dispatch_group_enter(group);
            [pinboard bookmarksWithSuccess:^(NSArray *bookmarks) {
                BookmarksSuccessBlock(bookmarks);
                dispatch_group_leave(group);
            }
                                   failure:BookmarksFailureBlock];
            
        }
        else {
            success();
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
               @"tags": [results stringForColumn:@"tags"],
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
            [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:[self.posts indexOfObject:oldPosts[i]] inSection:0]];
        }
    }
    
    self.posts = newPosts;
    
    if (success != nil) {
        success(indexPathsToAdd, indexPathsToReload, indexPathsToRemove);
    }
}

- (void)updatePostsWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure {
    [self updateLocalDatabaseFromRemoteAPIWithSuccess:^{
        [self updatePostsFromDatabaseWithSuccess:success failure:failure];
    } failure:failure];
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
            notification.alertBody = NSLocalizedString(@"Bookmark Deleted Message", nil);
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

+ (NSArray *)linksForPost:(NSDictionary *)post {
    NSMutableArray *links = [NSMutableArray array];
    int location = [post[@"title"] length] + 1;
    if (![post[@"description"] isEqualToString:@""]) {
        location += [post[@"description"] length] + 1;
    }
    
    if (![post[@"tags"] isEqualToString:@""]) {
        for (NSString *tag in [post[@"tags"] componentsSeparatedByString:@" "]) {
            NSRange range = [post[@"tags"] rangeOfString:tag];
            [links addObject:@{@"url": [NSURL URLWithString:[tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]], @"location": @(location+range.location), @"length": @(range.length)}];
        }
    }
    return links;
}

@end
