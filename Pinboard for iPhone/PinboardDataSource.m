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

- (void)updatePosts:(void (^)(NSArray *, NSArray *, NSArray *))callback {
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:self.query withParameterDictionary:self.queryParameters];
    
    NSMutableArray *posts = [NSMutableArray array];

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
            @"unread": [results objectForColumnName:@"unread"],
            @"url": [results stringForColumn:@"url"],
            @"private": [results objectForColumnName:@"private"],
            @"tags": [results stringForColumn:@"tags"],
            @"created_at": [results dateForColumn:@"created_at"]
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
            
            [posts addObject:post];
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

    if (callback != nil) {
        callback(indexPathsToAdd, indexPathsToReload, indexPathsToRemove);
    }
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
