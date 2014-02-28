//
//  PinboardDataSource.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import "PinboardDataSource.h"
#import "AppDelegate.h"
#import "AddBookmarkViewController.h"
#import "PPBadgeView.h"
#import "PPTheme.h"
#import "PPTitleButton.h"
#import "PostMetadata.h"
#import "PPDefaultFeedViewController.h"

#import "NSAttributedString+Attributes.h"
#import "PPPinboardMetadataCache.h"

#import <FMDB/FMDatabase.h>
#import <ASPinboard/ASPinboard.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

static BOOL kPinboardSyncInProgress = NO;

@interface PinboardDataSource ()

@property (nonatomic, strong) PPPinboardMetadataCache *cache;
@property (nonatomic) CGFloat mostRecentWidth;

- (void)generateQueryAndParameters:(void (^)(NSString *, NSArray *))callback;

@end

@implementation PinboardDataSource

- (id)init {
    self = [super init];
    if (self) {
        self.totalNumberOfPosts = 0;
        
        // Keys are hash:meta pairs
        self.cache = [PPPinboardMetadataCache sharedCache];
        self.metadata = [NSMutableArray array];
        self.compressedMetadata = [NSMutableArray array];
        self.posts = [NSMutableArray array];
        self.mostRecentWidth = 0;

        self.tags = @[];
        self.untagged = kPushpinFilterNone;
        self.isPrivate = kPushpinFilterNone;
        self.unread = kPushpinFilterNone;
        self.starred = kPushpinFilterNone;
        self.offset = 0;
        self.limit = 50;
        self.orderBy = @"created_at DESC";
        self.searchQuery = nil;
        self.searchScope = ASPinboardSearchScopeNone;

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

    kPushpinFilterType starred = kPushpinFilterNone;
    if (parameters[@"starred"]) {
        starred = [parameters[@"starred"] boolValue];
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
                isStarred:starred
                 untagged:untagged
                     tags:tags
                   offset:offset
                    limit:limit];
}

- (void)filterWithQuery:(NSString *)query {
    query = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (self.searchScope != ASPinboardSearchScopeNone) {
        self.searchQuery = query;
    }
    else {
#warning Make this recursive to handle queries like (url:anand OR url:wire) title:mac. Parse out parentheses and feed back in.

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
                if (![value hasSuffix:@"*"] && ![value hasSuffix:@")"]) {
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

- (PinboardDataSource *)searchDataSource {
    PinboardDataSource *search = [self copy];
    search.searchQuery = @"*";
    return search;
}

- (PinboardDataSource *)dataSourceWithAdditionalTag:(NSString *)tag {
    NSArray *newTags = [self.tags arrayByAddingObject:tag];
    PinboardDataSource *dataSource = [self copy];
    dataSource.tags = newTags;
    return dataSource;
}

- (void)filterByPrivate:(kPushpinFilterType)isPrivate
               isUnread:(kPushpinFilterType)isUnread
              isStarred:(kPushpinFilterType)starred
               untagged:(kPushpinFilterType)untagged
                   tags:(NSArray *)tags
                 offset:(NSInteger)offset
                  limit:(NSInteger)limit {
    self.limit = limit;
    self.untagged = untagged;
    self.isPrivate = isPrivate;
    self.unread = isUnread;
    self.starred = starred;
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
    return self.posts.count;
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

- (void)updateBookmarksWithSuccess:(void (^)())success
                           failure:(void (^)(NSError *))failure
                          progress:(void (^)(NSInteger, NSInteger))progress
                           options:(NSDictionary *)options {

    if (!failure) {
        failure = ^(NSError *error) {};
    }
    
    if (self.searchScope != ASPinboardSearchScopeNone) {
        success();
    }
    else {
        if (!kPinboardSyncInProgress) {
            kPinboardSyncInProgress = YES;

            MixpanelProxy *mixpanel = [MixpanelProxy sharedInstance];
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

                // Three things we want to do here:
                //
                // 1. Add new bookmarks.
                // 2. Update existing bookmarks.
                // 3. Delete removed bookmarks.
                //
                // Let's call "before update" A, and "after update" B.
                // For 1, we want all bookmarks in B but not in A. So [B minusSet:A]
                // For 3, we want all bookmarks in A but not in B. So [A minusSet:B]
                // For 2, we do [B minusSet:A], but with hashes + meta instead of just hashes as keys.
                NSMutableSet *A = [NSMutableSet set];
                NSMutableSet *B = [NSMutableSet set];
                NSMutableSet *APlusMeta = [NSMutableSet set];
                NSMutableSet *BPlusMeta = [NSMutableSet set];
                
                NSMutableSet *insertedBookmarkSet = [NSMutableSet set];
                NSMutableSet *deletedBookmarkSet = [NSMutableSet set];
                NSMutableSet *updatedBookmarkSet = [NSMutableSet set];

                // Used for filtering out bookmarks that have been added from the updated set.
                NSMutableSet *insertedBookmarkPlusMetaSet = [NSMutableSet set];

                NSString *firstHash;
                if (posts.count > 0) {
                    firstHash = posts[0][@"hash"];
                }
                else {
                    firstHash = @"";
                }
                
                DLog(@"Getting local data");

                NSUInteger total = posts.count;
                results = [db executeQuery:@"SELECT meta, hash, url FROM bookmark ORDER BY created_at DESC"];
                while ([results next]) {
                    NSString *hash = [results stringForColumn:@"hash"];
                    NSString *meta = [results stringForColumn:@"meta"];

                    [A addObject:hash];
                    [APlusMeta addObject:[@[hash, meta] componentsJoinedByString:@"_"]];

                    // Update our NSSets
                    [localHashTable addObject:hash];
                    [localMetaTable addObject:[NSString stringWithFormat:@"%@_%@", hash, meta]];
                }
                
                DLog(@"Calculating changes");
                
                NSDictionary *params;
                CGFloat index = 0;
                NSUInteger skipped = 0;
                NSUInteger updateCount = 0;
                NSUInteger addCount = 0;
                NSUInteger deleteCount = 0;
                NSUInteger tagAddCount = 0;
                NSUInteger tagDeleteCount = 0;

                [mixpanel.people set:@"Bookmarks" to:@(total)];

                DLog(@"Iterating posts");
                progress(0, total);

                NSNotificationQueue *queue = [NSNotificationQueue defaultQueue];
                [queue enqueueNotification:[NSNotification notificationWithName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(0), @"total": @(total)}] postingStyle:NSPostASAP];
                
                // Only track one date error per update
                __block BOOL dateError = NO;

                NSMutableDictionary *bookmarks = [NSMutableDictionary dictionary];
                // Go through the posts once to fill out the B & BPlusMeta sets
                for (NSDictionary *post in posts) {
                    NSString *hash = post[@"hash"];
                    NSString *meta = post[@"meta"];
                    
                    [B addObject:hash];
                    [BPlusMeta addObject:[@[hash, meta] componentsJoinedByString:@"_"]];
                    bookmarks[hash] = post;
                }
                
                NSDictionary* (^ParamsForPost)(NSDictionary *) = ^NSDictionary*(NSDictionary *post) {
                    NSDate *date = [self.enUSPOSIXDateFormatter dateFromString:post[@"time"]];
                    if (!dateError && !date) {
                        date = [NSDate dateWithTimeIntervalSince1970:0];
                        [[MixpanelProxy sharedInstance] track:@"NSDate error in updateLocalDatabaseFromRemoteAPIWithSuccess" properties:@{@"Locale": [NSLocale currentLocale]}];
                        dateError = YES;
                        DLog(@"Error parsing date: %@", post[@"time"]);
                    }

                    NSString *hash = post[@"hash"];
                    NSString *meta = post[@"meta"];

                    NSString *postTags = ([post[@"tags"] isEqual:[NSNull null]]) ? @"" : [post[@"tags"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSString *title = ([post[@"description"] isEqual:[NSNull null]]) ? @"" : [post[@"description"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSString *description = ([post[@"extended"] isEqual:[NSNull null]]) ? @"" : [post[@"extended"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    return @{
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
                };
                
                // Now we figure out our syncing.
                [insertedBookmarkSet setSet:B];
                [insertedBookmarkSet minusSet:A];

                CGFloat amountToAdd = (CGFloat)insertedBookmarkSet.count / posts.count;
                for (NSString *hash in insertedBookmarkSet) {
                    NSDictionary *post = bookmarks[hash];
                    NSString *meta = post[@"meta"];
                    [insertedBookmarkPlusMetaSet addObject:[@[hash, meta] componentsJoinedByString:@"_"]];
                    
                    NSString *postTags = ([post[@"tags"] isEqual:[NSNull null]]) ? @"" : [post[@"tags"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    params = ParamsForPost(post);
                    
                    [db executeUpdate:@"INSERT INTO bookmark (title, description, url, private, unread, hash, tags, meta, created_at) VALUES (:title, :description, :url, :private, :unread, :hash, :tags, :meta, :created_at);" withParameterDictionary:params];
                    addCount++;
                    
                    [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[hash]];
                    tagDeleteCount++;
                    
                    for (NSString *tagName in [postTags componentsSeparatedByString:@" "]) {
                        NSString *cleanedTagName = [tagName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if (![cleanedTagName isEqualToString:@""]) {
                            [db executeUpdate:@"INSERT OR IGNORE INTO tag (name) VALUES (?)" withArgumentsInArray:@[tagName]];
                            [db executeUpdate:@"INSERT INTO tagging (tag_name, bookmark_hash) VALUES (?, ?)" withArgumentsInArray:@[tagName, hash]];
                            tagAddCount++;
                        }
                    }
                    
                    index += amountToAdd;
                    progress((NSInteger)index, total);
                    NSNotification *note = [NSNotification notificationWithName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(index), @"total": @(total)}];
                    [queue enqueueNotification:note postingStyle:NSPostASAP];
                }
                
                // This gives us all bookmarks in 'A' but not in 'B'.
                [deletedBookmarkSet setSet:A];
                [deletedBookmarkSet minusSet:B];

                amountToAdd = (CGFloat)deletedBookmarkSet.count / posts.count;
                for (NSString *hash in deletedBookmarkSet) {
                    [db executeUpdate:@"DELETE FROM bookmark WHERE hash=?" withArgumentsInArray:@[hash]];
                    deleteCount++;
                    index += amountToAdd;
                    progress((NSInteger)index, total);
                    NSNotification *note = [NSNotification notificationWithName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(index), @"total": @(total)}];
                    [queue enqueueNotification:note postingStyle:NSPostASAP];
                }
                
                [updatedBookmarkSet setSet:BPlusMeta];
                [updatedBookmarkSet minusSet:APlusMeta];
                [updatedBookmarkSet minusSet:insertedBookmarkPlusMetaSet];
                
                amountToAdd = (CGFloat)updatedBookmarkSet.count / posts.count;
                for (NSString *hashPlusMeta in updatedBookmarkSet) {
                    NSString *hash = [hashPlusMeta componentsSeparatedByString:@"_"][0];
                    NSDictionary *post = bookmarks[hash];
                    
                    NSDate *date = [self.enUSPOSIXDateFormatter dateFromString:post[@"time"]];
                    if (!dateError && !date) {
                        date = [NSDate dateWithTimeIntervalSince1970:0];
                        [[MixpanelProxy sharedInstance] track:@"NSDate error in updateLocalDatabaseFromRemoteAPIWithSuccess" properties:@{@"Locale": [NSLocale currentLocale]}];
                        dateError = YES;
                    }
                    
                    NSString *postTags = ([post[@"tags"] isEqual:[NSNull null]]) ? @"" : [post[@"tags"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    params = ParamsForPost(post);
                    
                    // Update this bookmark
                    [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, url=:url, private=:private, unread=:unread, tags=:tags, meta=:meta, created_at=:created_at WHERE hash=:hash" withParameterDictionary:params];
                    updateCount++;
                    
                    [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[hash]];
                    tagDeleteCount++;
                    
                    for (NSString *tagName in [postTags componentsSeparatedByString:@" "]) {
                        NSString *cleanedTagName = [tagName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if (![cleanedTagName isEqualToString:@""]) {
                            [db executeUpdate:@"INSERT OR IGNORE INTO tag (name) VALUES (?)" withArgumentsInArray:@[tagName]];
                            [db executeUpdate:@"INSERT INTO tagging (tag_name, bookmark_hash) VALUES (?, ?)" withArgumentsInArray:@[tagName, hash]];
                            tagAddCount++;
                        }
                    }
                    
                    index += amountToAdd;
                    progress((NSInteger)index, total);
                    NSNotification *note = [NSNotification notificationWithName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(index), @"total": @(total)}];
                    [queue enqueueNotification:note postingStyle:NSPostASAP];
                }
                
                DLog(@"Updating tags");
                [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_name=tag.name)"];
                [db executeUpdate:@"DELETE FROM tag WHERE count=0"];
                
                DLog(@"Committing changes");
                [db commit];
                [db close];

                NSDate *endDate = [NSDate date];
                skipped = total - addCount - updateCount - deleteCount;

                DLog(@"%f", [endDate timeIntervalSinceDate:startDate]);
                DLog(@"added %lu", (unsigned long)[insertedBookmarkSet count]);
                DLog(@"updated %lu", (unsigned long)[updatedBookmarkSet count]);
                DLog(@"skipped %lu", (unsigned long)skipped);
                DLog(@"removed %lu", (unsigned long)[deletedBookmarkSet count]);
                DLog(@"tags added %lu", (unsigned long)tagAddCount);
                
                self.totalNumberOfPosts = index;

                [[AppDelegate sharedDelegate] setLastUpdated:[NSDate date]];
                kPinboardSyncInProgress = NO;

                progress(total, total);
                
                NSNotification *note = [NSNotification notificationWithName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(total), @"total": @(total)}];
                [queue enqueueNotification:note postingStyle:NSPostASAP];

                [[MixpanelProxy sharedInstance] track:@"Synced Pinboard bookmarks" properties:@{@"Duration": @([endDate timeIntervalSinceDate:startDate])}];
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
                    BOOL lastUpdatedMoreThanFiveMinutesAgo = [[NSDate date] timeIntervalSinceReferenceDate] - [lastLocalUpdate timeIntervalSinceReferenceDate] > 300;

                    if (neverUpdated || outOfSyncWithAPI) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [pinboard bookmarksWithTags:nil
                                                 offset:-1
                                                  count:-1
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
                        });
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
}

- (void)updateStarredPostsWithSuccess:(void (^)())success failure:(void (^)())failure {
    void (^BookmarksSuccessBlock)(NSArray *, NSDictionary *) = ^(NSArray *posts, NSDictionary *constraints) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            [db beginTransaction];

            NSMutableDictionary *bookmarks = [NSMutableDictionary dictionary];
            
            // Two things we want to do here:
            //
            // 1. Add new bookmarks.
            // 2. Delete removed bookmarks.
            //
            // Let's call "before update" A, and "after update" B.
            // For 1, we want all bookmarks in B but not in A. So [B minusSet:A]
            // For 2, we want all bookmarks in A but not in B. So [A minusSet:B]
            NSMutableSet *A = [NSMutableSet set];
            NSMutableSet *B = [NSMutableSet set];
            
            NSMutableSet *insertedBookmarkSet = [NSMutableSet set];
            NSMutableSet *deletedBookmarkSet = [NSMutableSet set];
            
            FMResultSet *results = [db executeQuery:@"SELECT url FROM bookmark WHERE starred=1 ORDER BY created_at DESC"];
            while ([results next]) {
                NSString *url = [results stringForColumnIndex:0];
                [A addObject:url];
            }
            
            for (NSDictionary *post in posts) {
                [B addObject:post[@"u"]];
                bookmarks[post[@"u"]] = post;
            }
            
            [insertedBookmarkSet setSet:B];
            [insertedBookmarkSet minusSet:A];

            [deletedBookmarkSet setSet:A];
            [deletedBookmarkSet minusSet:B];
            
            for (NSString *url in deletedBookmarkSet) {
                [db executeUpdate:@"UPDATE bookmark SET starred=0, meta=random() WHERE url=?" withArgumentsInArray:@[url]];
            }
            
            for (NSString *url in insertedBookmarkSet) {
                [db executeUpdate:@"UPDATE bookmark SET starred=1, meta=random() WHERE url=?" withArgumentsInArray:@[url]];
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

- (void)bookmarksWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success
                     failure:(void (^)(NSError *))failure
                       width:(CGFloat)width {
    [self bookmarksWithSuccess:success failure:failure cancel:nil width:width];
}

- (void)bookmarksWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success
                     failure:(void (^)(NSError *))failure
                      cancel:(void (^)(BOOL *))cancel
                       width:(CGFloat)width {
    self.mostRecentWidth = width;

    void (^HandleSearch)(NSString *, NSArray *) = ^(NSString *query, NSArray *parameters) {
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *results = [db executeQuery:query withArgumentsInArray:parameters];
        
        NSArray *oldPosts = [self.posts copy];
        NSMutableArray *newPosts = [NSMutableArray array];
        
        NSMutableArray *oldHashes = [NSMutableArray array];
        NSMutableDictionary *oldMetas = [NSMutableDictionary dictionary];
        for (NSDictionary *post in self.posts) {
            [oldHashes addObject:post[@"hash"]];
            oldMetas[post[@"hash"]] = post[@"meta"];
        }
        
        NSMutableArray *indexPathsToInsert = [NSMutableArray array];
        NSMutableArray *indexPathsToDelete = [NSMutableArray array];
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
                        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:j inSection:0]];
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
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            }
            
            [newPosts addObject:post];
            index++;
        }
        
        [self.tagsWithFrequency removeAllObjects];
        
        FMResultSet *tagResult = [db executeQuery:@"SELECT name, count FROM tag ORDER BY count DESC;"];
        while ([tagResult next]) {
            NSString *tag = [tagResult stringForColumnIndex:0];
            NSNumber *count = [tagResult objectForColumnIndex:1];
            self.tagsWithFrequency[tag] = count;
        }
        
        [db close];
        
        for (NSInteger i=skipPivot; i<oldHashes.count; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        NSMutableArray *newMetadata = [NSMutableArray array];
        NSMutableArray *newCompressedMetadata = [NSMutableArray array];

        for (NSDictionary *post in newPosts) {
            PostMetadata *metadata = [PostMetadata metadataForPost:post compressed:NO width:width tagsWithFrequency:self.tagsWithFrequency];
            [newMetadata addObject:metadata];

            PostMetadata *compressedMetadata = [PostMetadata metadataForPost:post compressed:YES width:width tagsWithFrequency:self.tagsWithFrequency];
            [newCompressedMetadata addObject:compressedMetadata];
        }

        // We run this block to make sure that these results should be the latest on "file"
        BOOL stop = NO;
        
        if (cancel) {
            cancel(&stop);
        }

        if (stop) {
            failure(nil);
            DLog(@"Cancelling search for query (%@)", self.searchQuery);
        }
        else {
            self.posts = newPosts;

            self.metadata = newMetadata;
            self.compressedMetadata = newCompressedMetadata;

            if (success) {
                success(indexPathsToInsert, indexPathsToReload, indexPathsToDelete);
            }
        }
    };

    if (self.searchScope != ASPinboardSearchScopeNone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            AppDelegate *sharedDelegate = [AppDelegate sharedDelegate];
            [pinboard searchBookmarksWithUsername:sharedDelegate.username
                                         password:sharedDelegate.password
                                            query:self.searchQuery
                                            scope:self.searchScope
                                          success:^(NSArray *urls) {
                                              NSMutableArray *components = [NSMutableArray array];
                                              NSMutableArray *parameters = [NSMutableArray array];
                                              [components addObject:@"SELECT * FROM bookmark WHERE url IN ("];
                                              
                                              NSMutableArray *urlComponents = [NSMutableArray array];
                                              for (NSString *url in urls) {
                                                  [urlComponents addObject:@"?"];
                                                  [parameters addObject:url];
                                              }
                                              
                                              [components addObject:[urlComponents componentsJoinedByString:@", "]];
                                              [components addObject:@")"];
                                              
                                              NSString *query = [components componentsJoinedByString:@" "];
                                              
                                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                  HandleSearch(query, parameters);
                                              });
                                          }];
        });
    }
    else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self generateQueryAndParameters:HandleSearch];
        });
    }
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

- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths callback:(void (^)(NSArray *, NSArray *, NSArray *))callback {
    void (^SuccessBlock)();
    void (^ErrorBlock)(NSError *);

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    ASPinboard *pinboard = [ASPinboard sharedInstance];
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

            [[MixpanelProxy sharedInstance] track:@"Deleted bookmark"];
            dispatch_group_leave(group);
        };

        ErrorBlock = ^(NSError *error) {
            dispatch_group_leave(group);
        };

        dispatch_group_enter(group);
        [pinboard deleteBookmarkWithURL:url success:SuccessBlock failure:ErrorBlock];
    }

    dispatch_group_notify(group, queue, ^{
        dispatch_group_t inner_group = dispatch_group_create();

        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_name=tag.name)"];
        [db executeUpdate:@"DELETE FROM tag WHERE count=0"];
        [db close];

        // NOTE: Previously, new posts were loaded here.  We should let the GenericPostViewController handle any necessary refreshes to avoid consistency issues
        
        dispatch_group_notify(inner_group, queue, ^{
            if (callback) {
                [self bookmarksWithSuccess:callback failure:nil width:self.mostRecentWidth];
            }
        });
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
                
                [[MixpanelProxy sharedInstance] track:@"Deleted bookmark"];

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
        
        [pinboard deleteBookmarkWithURL:post[@"url"] success:SuccessBlock failure:ErrorBlock];
    }
    
    dispatch_group_notify(group, queue, ^{
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
        if ([posts count] == 1) {
            notification.alertBody = NSLocalizedString(@"Your bookmark was deleted.", nil);
        }
        else {
            notification.alertBody = [NSString stringWithFormat:@"%lu bookmarks were deleted.", (unsigned long)[posts count]];
        }
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    });
}

- (PPPostActionType)actionsForPost:(NSDictionary *)post {
    PPPostActionType actions = PPPostActionDelete | PPPostActionEdit | PPPostActionCopyURL | PPPostActionShare;

    if ([post[@"unread"] boolValue]) {
        actions |= PPPostActionMarkAsRead;
    }

    BOOL shareToReadLater = NO;
    if (shareToReadLater && [AppDelegate sharedDelegate].readLater != PPReadLaterNone) {
        actions |= PPPostActionReadLater;
    }

    return actions;
}

- (PPNavigationController *)editViewControllerForPostAtIndex:(NSInteger)index callback:(void (^)())callback {
    return [AddBookmarkViewController addBookmarkViewControllerWithBookmark:self.posts[index] update:@(YES) callback:^(NSDictionary *post) {
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

- (PPNavigationController *)editViewControllerForPostAtIndex:(NSInteger)index {
    return [self editViewControllerForPostAtIndex:index callback:nil];
}

- (void)handleTapOnLinkWithURL:(NSURL *)url callback:(void (^)(UIViewController *))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // All tags should be UTF8 encoded (stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding) before getting passed into the NSURL, so we decode them here
        NSString *tag = [url.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        if (![self.tags containsObject:tag]) {
            PinboardDataSource *pinboardDataSource = [self dataSourceWithAdditionalTag:tag];

            dispatch_async(dispatch_get_main_queue(), ^{
                GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
                postViewController.postDataSource = pinboardDataSource;
                PPTitleButton *button = [PPTitleButton buttonWithDelegate:postViewController];
                [button setTitle:[pinboardDataSource.tags componentsJoinedByString:@"+"] imageName:nil];

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

- (void)generateQueryAndParameters:(void (^)(NSString *, NSArray *))callback {
    NSMutableArray *components = [NSMutableArray array];
    NSMutableArray *parameters = [NSMutableArray array];

    [components addObject:@"SELECT bookmark.* FROM"];
    
    // Use only one match query with the FTS4 syntax.
    BOOL singleMatch = YES;
    NSMutableArray *tables = [NSMutableArray arrayWithObject:@"bookmark"];
    if (self.searchQuery && singleMatch) {
        [tables addObject:@"bookmark_fts"];
    }

    [components addObject:[tables componentsJoinedByString:@", "]];
    
    NSMutableArray *whereComponents = [NSMutableArray array];
    if (self.searchQuery) {
        if (singleMatch) {
            [whereComponents addObject:@"bookmark.hash = bookmark_fts.hash"];
            [whereComponents addObject:@"bookmark_fts MATCH ?"];
            [parameters addObject:self.searchQuery];
        }
        else {
            NSMutableArray *subqueries = [NSMutableArray array];
            
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
                        
                        [subqueries addObject:[NSString stringWithFormat:@"SELECT hash FROM bookmark_fts WHERE bookmark_fts.%@ MATCH ?", field]];
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
                [subqueries addObject:@"SELECT hash FROM bookmark_fts WHERE bookmark_fts MATCH ?"];
                [parameters addObject:trimmedQuery];
            }
            
            [whereComponents addObject:[NSString stringWithFormat:@"bookmark.hash IN (%@)", [subqueries componentsJoinedByString:@" INTERSECT "]]];
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
                    // Lowercase the database tag name and the parameter string so that searches for Programming and programming return the same results. We do this in order to act more similarly to the Pinboard website.
                    [whereComponents addObject:@"bookmark.hash IN (SELECT bookmark_hash FROM tagging WHERE tag_name = ? COLLATE NOCASE)"];
                    [parameters addObject:tag];
                }
            }
            break;
    }
    
    switch (self.starred) {
        case kPushpinFilterTrue:
            [whereComponents addObject:@"bookmark.starred = ?"];
            [parameters addObject:@(YES)];
            break;
            
        case kPushpinFilterFalse:
            [whereComponents addObject:@"(bookmark.starred IS NULL)"];
            break;

        default:
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
    PinboardDataSource *dataSource = [[PinboardDataSource alloc] init];
    dataSource.limit = self.limit;
    dataSource.tags = self.tags;
    dataSource.orderBy = self.orderBy;
    dataSource.searchQuery = self.searchQuery;
    dataSource.offset = self.offset;
    dataSource.isPrivate = self.isPrivate;
    dataSource.unread = self.unread;
    dataSource.starred = self.starred;
    dataSource.untagged = self.untagged;
    return dataSource;
}

- (NSString *)searchPlaceholder {
    if (self.isPrivate == kPushpinFilterTrue) {
        return @"Search Private";
    }
    
    if (self.isPrivate == kPushpinFilterFalse) {
        return @"Search Public";
    }
    
    if (self.starred == kPushpinFilterTrue) {
        return @"Search Starred";
    }
    
    if (self.unread == kPushpinFilterTrue) {
        return @"Search Unread";
    }
    
    if (self.untagged == kPushpinFilterTrue) {
        return @"Search Untagged";
    }

    return @"Search";
}

- (UIColor *)barTintColor {
    if (self.starred == kPushpinFilterTrue) {
        return HEX(0x8361F4FF);
    }
    
    if (self.unread == kPushpinFilterTrue) {
        return HEX(0xEF6034FF);
    }
    
    switch (self.isPrivate) {
        case kPushpinFilterTrue:
            return HEX(0xFFAE46FF);
            
        case kPushpinFilterFalse:
            return HEX(0x7BB839FF);
            
        default:
            break;
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
    
    if (self.starred == kPushpinFilterTrue) {
        return NSLocalizedString(@"Starred", nil);
    }
    
    if (self.unread == kPushpinFilterTrue) {
        return NSLocalizedString(@"Unread", nil);
    }
    
    if (self.untagged == kPushpinFilterTrue) {
        return NSLocalizedString(@"Untagged", nil);
    }
    
    if (self.isPrivate == kPushpinFilterNone && self.starred == kPushpinFilterNone && self.unread == kPushpinFilterNone && self.untagged == kPushpinFilterNone && self.searchQuery == nil && self.tags.count == 0) {
        return NSLocalizedString(@"All Bookmarks", nil);
    }
    
    return [self.tags componentsJoinedByString:@"+"];
}

- (UIView *)titleViewWithDelegate:(id<PPTitleButtonDelegate>)delegate {
    PPTitleButton *titleButton = [PPTitleButton buttonWithDelegate:delegate];

    NSMutableArray *imageNames = [NSMutableArray array];
    NSString *title;

    switch (self.isPrivate) {
        case kPushpinFilterTrue:
            [imageNames addObject:@"navigation-private"];
            title = NSLocalizedString(@"Private Bookmarks", nil);
            break;
            
        case kPushpinFilterFalse:
            [imageNames addObject:@"navigation-public"];
            title = NSLocalizedString(@"Public", nil);
            break;

        default:
            break;
    }

    if (self.starred == kPushpinFilterTrue) {
        [imageNames addObject:@"navigation-starred"];
        title = NSLocalizedString(@"Starred", nil);
    }
    
    if (self.unread == kPushpinFilterTrue) {
        [imageNames addObject:@"navigation-unread"];
        title = NSLocalizedString(@"Unread", nil);
    }
    
    if (self.untagged == kPushpinFilterTrue) {
        [imageNames addObject:@"navigation-untagged"];
        title = NSLocalizedString(@"Untagged", nil);
    }

    if (self.isPrivate == kPushpinFilterNone && self.starred == kPushpinFilterNone && self.unread == kPushpinFilterNone && self.untagged == kPushpinFilterNone && self.searchQuery == nil && self.tags.count == 0) {
        [imageNames addObject:@"navigation-all"];
        title = NSLocalizedString(@"All Bookmarks", nil);
    }
    
    if (self.searchQuery) {
        title = [NSString stringWithFormat:@"\"%@\"", self.searchQuery];
    }
    
    if (title) {
        if (imageNames.count > 1) {
            if (self.searchQuery) {
                [titleButton setImageNames:imageNames title:[NSString stringWithFormat:@"+\"%@\"", self.searchQuery]];
            }
            else {
                [titleButton setImageNames:imageNames title:nil];
            }
        }
        else if (imageNames.count == 1) {
            [titleButton setTitle:title imageName:imageNames[0]];
        }
        else {
            [titleButton setTitle:title imageName:nil];
        }
    }
    else {
        if (self.tags.count > 0) {
            [titleButton setTitle:[self.tags componentsJoinedByString:@"+"] imageName:nil];
        }
        else {
            [titleButton setTitle:NSLocalizedString(@"All Bookmarks", nil) imageName:@"navigation-all"];
        }
    }

    return titleButton;
}

- (UIView *)titleView {
    return [self titleViewWithDelegate:nil];
}

- (BOOL)searchSupported {
    if (self.searchQuery) {
        return NO;
    }
    else {
#warning Might want to tweak this.
        return YES;
    }
}

@end
