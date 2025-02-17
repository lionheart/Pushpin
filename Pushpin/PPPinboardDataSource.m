// SPDX-License-Identifier: GPL-3.0-or-later
//
// Pushpin for Pinboard
// Copyright (C) 2025 Lionheart Software LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

//
//  PinboardDataSource.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

@import CoreSpotlight;
@import MobileCoreServices;
@import ASPinboard;
@import MWFeedParser;
@import FMDB;
@import LHSCategoryCollection;

#ifndef APP_EXTENSION_SAFE
#import "PPGenericPostViewController.h"
#import "PPNotification.h"
#endif

#import "PPPinboardDataSource.h"
#import "PPAddBookmarkViewController.h"
#import "PPTheme.h"
#import "PPTitleButton.h"
#import "PPSettings.h"

#import "PPPinboardMetadataCache.h"
#import "PPUtilities.h"
#import "PPURLCache.h"
#import "PostMetadata.h"

#import "NSAttributedString+Attributes.h"
#import "NSString+LHSAdditions.h"
#import "NSString+Additions.h"

static BOOL kPinboardSyncInProgress = NO;

@interface PPCachedResult : NSObject

@property (nonatomic, strong) NSMutableArray *bookmarks;
@property (nonatomic, strong) NSMutableDictionary *hashesToIndexPaths;
@property (nonatomic, strong) NSMutableDictionary *hashmetasToHashes;
@property (nonatomic, strong) NSMutableDictionary *tagsWithFrequencies;

@end

@implementation PPCachedResult

@end

@interface PPPinboardDataSource ()

@property (nonatomic, strong) PPPinboardMetadataCache *cache;
@property (nonatomic) CGFloat mostRecentWidth;
@property (nonatomic, strong) UIAlertController *fullTextSearchAlertView;
@property (nonatomic, strong) NSDate *latestReloadTime;

- (NSDictionary *)paramsForPost:(NSDictionary *)post dateError:(BOOL)dateError;
- (void)generateQueryAndParameters:(void (^)(NSString *, NSArray *))callback;

- (void)syncBookmarksWithCompletion:(void (^)(BOOL updated, NSError *))completion
                           progress:(void (^)(NSInteger, NSInteger))progress
                              count:(NSInteger)count
                        skipStarred:(BOOL)skipStarred;

@end

@implementation PPPinboardDataSource

+ (NSCache *)resultCache {
    static NSCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
    });
    return cache;
}

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

        self.fullTextSearchAlertView = [UIAlertController lhs_alertViewWithTitle:nil
                                                                         message:NSLocalizedString(@"To enable Pinboard full-text search, please log out and then log back in to Pushpin.", nil)];

        [self.fullTextSearchAlertView lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
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
    query = [PPUtilities stringByTrimmingWhitespace:query];
    if (self.searchScope != ASPinboardSearchScopeNone) {
        self.searchQuery = query;
    } else {
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
            } else {
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

- (PPPinboardDataSource *)searchDataSource {
    PPPinboardDataSource *search = [self copy];
    search.searchQuery = @"*";
    return search;
}

- (PPPinboardDataSource *)dataSourceWithAdditionalTag:(NSString *)tag {
    NSArray *newTags = [self.tags arrayByAddingObject:tag];
    PPPinboardDataSource *dataSource = [self copy];
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
        } else {
            self.limit += 50;
        }
    }
    callback(needsUpdate);
}

- (NSInteger)numberOfPosts {
    return self.posts.count;
}

- (NSInteger)indexForPost:(NSDictionary *)post {
#warning O(N^2)
    return [self.posts indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj[@"hash"] isEqualToString:post[@"hash"]];
    }];
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

- (void)updateStarredPostsWithCompletion:(PPErrorBlock)completion {
    PPSettings *settings = [PPSettings sharedSettings];
    NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://feeds.pinboard.in/json/secret:%@/u:%@/starred/?count=400", settings.feedToken, settings.username]];
    NSURLRequest *request = [NSURLRequest requestWithURL:endpoint];
    [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
        if (error) {
            completion(error);
        } else {
            NSArray *posts = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];

            NSMutableArray *previous = [NSMutableArray array];

            [[PPUtilities databaseQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
                FMResultSet *results = [db executeQuery:@"SELECT url FROM bookmark WHERE starred=1 ORDER BY created_at DESC"];
                while ([results next]) {
                    NSString *url = [results stringForColumnIndex:0];
                    [previous addObject:@{@"u": url}];
                }

                [results close];
            }];

            [PPUtilities generateDiffForPrevious:previous
                                         updated:posts
                                            hash:^NSString *(id obj) { return obj[@"u"]; }
                                      completion:^(NSSet *inserted, NSSet *deleted) {
                [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                    for (NSString *url in deleted) {
                        [db executeUpdate:@"UPDATE bookmark SET starred=0, meta=random() WHERE url=?" withArgumentsInArray:@[url]];
                    }

                    for (NSString *url in inserted) {
                        [db executeUpdate:@"UPDATE bookmark SET starred=1, meta=random() WHERE url=?" withArgumentsInArray:@[url]];
                    }
                }];
            }];

            completion(nil);
        }
    }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [task resume];
    });
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

- (PostMetadata *)metadataForPostAtIndex:(NSInteger)index {
    return self.metadata[index];
}

- (PostMetadata *)compressedMetadataForPostAtIndex:(NSInteger)index {
    return self.compressedMetadata[index];
}

- (NSDictionary *)postAtIndex:(NSInteger)index {
    return self.posts[index];
}

- (void)markPostAsRead:(NSString *)url callback:(void (^)(NSError *))callback {
    if (!callback) {
        callback = ^(NSError *error) {};
    }

    ASPinboard *pinboard = [ASPinboard sharedInstance];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [pinboard bookmarkWithURL:url
                          success:^(NSDictionary *bookmark) {
            if ([bookmark[@"toread"] isEqualToString:@"no"]) {
                // Bookmark has already been marked as read on server.
                [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                    [db executeUpdate:@"UPDATE bookmark SET unread=0, meta=random() WHERE hash=?"
                 withArgumentsInArray:@[bookmark[@"hash"]]];
                }];

                [[PPPinboardMetadataCache sharedCache] removeCachedMetadataForPost:bookmark width:self.mostRecentWidth];
                callback(nil);
                return;
            }

            NSMutableDictionary *newBookmark = [NSMutableDictionary dictionaryWithDictionary:bookmark];
            newBookmark[@"toread"] = @"no";
            newBookmark[@"url"] = newBookmark[@"href"];
            [newBookmark removeObjectsForKeys:@[@"href", @"hash", @"meta", @"time"]];
            [pinboard addBookmark:newBookmark
                          success:^{
                [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                    [db executeUpdate:@"UPDATE bookmark SET unread=0, meta=random() WHERE hash=?"
                 withArgumentsInArray:@[bookmark[@"hash"]]];
                }];

                [[PPPinboardMetadataCache sharedCache] removeCachedMetadataForPost:bookmark width:self.mostRecentWidth];
                callback(nil);
            }
                          failure:^(NSError *error) {
                callback(error);
            }];
        }
                          failure:^(NSError *error) {
            if (error.code == PinboardErrorBookmarkNotFound) {
            }
            callback(error);
        }];
    });
}

- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths callback:(void (^)(void))callback {
    void (^SuccessBlock)(void);
    void (^ErrorBlock)(NSError *);

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    ASPinboard *pinboard = [ASPinboard sharedInstance];

    for (NSIndexPath *indexPath in indexPaths) {
        NSString *url = self.posts[indexPath.row][@"url"];

        SuccessBlock = ^{
            NSString *hash = self.posts[indexPath.row][@"hash"];

            [[PPUtilities databaseQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
                [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[hash]];
                [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_name=tag.name)"];
                [db executeUpdate:@"DELETE FROM tag WHERE count=0"];

                [db executeUpdate:@"DELETE FROM bookmark WHERE hash=?" withArgumentsInArray:@[hash]];
            }];

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

        // NOTE: Previously, new posts were loaded here.  We should let the GenericPostViewController handle any necessary refreshes to avoid consistency issues
        dispatch_group_notify(inner_group, queue, ^{
            if (callback) {
                [[PPPinboardDataSource resultCache] removeAllObjects];

                callback();
            }
        });
    });
}

- (void)deletePosts:(NSArray *)posts callback:(void (^)(NSIndexPath *))callback {
    void (^SuccessBlock)(void);
    void (^ErrorBlock)(NSError *);

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    ASPinboard *pinboard = [ASPinboard sharedInstance];
    for (NSDictionary *post in posts) {
        SuccessBlock = ^{
            dispatch_group_async(group, queue, ^{
                [[PPUtilities databaseQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    [db executeUpdate:@"DELETE FROM bookmark WHERE url=?" withArgumentsInArray:@[post[@"url"]]];
                    [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[post[@"hash"]]];
                    [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_name=tag.name)"];
                    [db executeUpdate:@"DELETE FROM tag WHERE count=0"];
                }];


                NSInteger index = [self.posts indexOfObject:post];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];

                [[PPPinboardDataSource resultCache] removeAllObjects];
                callback(indexPath);
            });
        };

        ErrorBlock = ^(NSError *error) {
            callback(nil);
        };

        [pinboard deleteBookmarkWithURL:post[@"url"] success:SuccessBlock failure:ErrorBlock];
    }

#ifndef APP_EXTENSION_SAFE
    dispatch_group_notify(group, queue, ^{
        NSString *message;
        if ([posts count] == 1) {
            message = NSLocalizedString(@"Your bookmark was deleted.", nil);
        } else {
            message = [NSString stringWithFormat:@"%lu bookmarks were deleted.", (unsigned long)[posts count]];
        }

        [PPNotification notifyWithMessage:message
                                  success:YES
                                  updated:NO];
    });
#endif
}

- (PPPostActionType)actionsForPost:(NSDictionary *)post {
    PPPostActionType actions = PPPostActionDelete | PPPostActionEdit | PPPostActionCopyURL | PPPostActionShare;

    if ([post[@"unread"] boolValue]) {
        actions |= PPPostActionMarkAsRead;
    }

    return actions;
}

- (PPNavigationController *)editViewControllerForPostAtIndex:(NSInteger)index callback:(void (^)(void))callback {
    return [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:self.posts[index] update:@(YES) callback:^(NSDictionary *post) {
        if (post) {
            [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, tags=:tags, unread=:unread, private=:private, meta=:meta WHERE hash=:hash" withParameterDictionary:post];
            }];
        }

        callback();
    }];
}

- (PPNavigationController *)editViewControllerForPostAtIndex:(NSInteger)index {
    return [self editViewControllerForPostAtIndex:index callback:nil];
}

#ifndef APP_EXTENSION_SAFE
- (void)handleTapOnLinkWithURL:(NSURL *)url callback:(void (^)(UIViewController *))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // All tags should be UTF8 encoded (stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding) before getting passed into the NSURL, so we decode them here
        NSString *tag = [url.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        if (![self.tags containsObject:tag]) {
            PPPinboardDataSource *pinboardDataSource = [self dataSourceWithAdditionalTag:tag];

            dispatch_async(dispatch_get_main_queue(), ^{
                PPGenericPostViewController *postViewController = [[PPGenericPostViewController alloc] init];
                postViewController.postDataSource = pinboardDataSource;
                postViewController.navigationItem.titleView = [pinboardDataSource titleViewWithDelegate:postViewController];
                callback(postViewController);
            });
        }
    });
}
#endif

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

    NSString *tags = [resultSet stringForColumn:@"tags"];
    if (!tags) {
        tags = @"";
    }

    return @{
        @"title": title,
        @"description": [resultSet stringForColumn:@"description"],
        @"unread": @([resultSet boolForColumn:@"unread"]),
        @"url": [resultSet stringForColumn:@"url"],
        @"private": @([resultSet boolForColumn:@"private"]),
        @"tags": tags,
        @"created_at": [resultSet dateForColumn:@"created_at"],
        @"starred": @([resultSet boolForColumn:@"starred"]),
        @"hash": hash,
        @"meta": [resultSet stringForColumn:@"meta"],
    };
}

- (void)generateQueryAndParameters:(void (^)(NSString *, NSArray *))callback {
    NSMutableArray *components = [NSMutableArray array];
    NSMutableArray *parameters = [NSMutableArray array];

    [components addObject:@"SELECT bookmark.* FROM"];

    // Use only one match query with the FTS4 syntax.
    BOOL generateSubquery = YES;
    NSMutableArray *tables = [NSMutableArray arrayWithObject:@"bookmark"];
    if (self.searchQuery && !generateSubquery) {
        [tables addObject:@"bookmark_fts"];
    }

    [components addObject:[tables componentsJoinedByString:@", "]];

    NSMutableArray *whereComponents = [NSMutableArray array];
    if (self.searchQuery) {
        if (generateSubquery) {
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
                        NSString *value = [PPUtilities stringByTrimmingWhitespace:[matchString substringWithRange:[subresult rangeAtIndex:2]]];
                        NSArray *words = [value componentsSeparatedByString:@" "];
                        NSMutableArray *wordsWithWildcards = [NSMutableArray array];
                        for (NSString *word in words) {
                            if ([word hasSuffix:@"*"] || [@[@"AND", @"OR", @"NOT"] containsObject:word]) {
                                [wordsWithWildcards addObject:word];
                            } else {
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

            NSString *trimmedQuery = [PPUtilities stringByTrimmingWhitespace:remainingQuery];
            if (![trimmedQuery isEqualToString:@""]) {
                [subqueries addObject:@"SELECT hash FROM bookmark_fts WHERE bookmark_fts MATCH ?"];
                [parameters addObject:trimmedQuery];
            }

            [whereComponents addObject:[NSString stringWithFormat:@"bookmark.hash IN (%@)", [subqueries componentsJoinedByString:@" INTERSECT "]]];
        } else {
            [whereComponents addObject:@"bookmark.hash = bookmark_fts.hash"];
            [whereComponents addObject:@"bookmark_fts MATCH ?"];
            [parameters addObject:self.searchQuery];
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
            // Only search within tag filters if untagged is not used (they could conflict).
            for (NSString *tag in self.tags) {
                // Lowercase the database tag name and the parameter string so that searches for Programming and programming return the same results. We do this in order to act more similarly to the Pinboard website.
                [whereComponents addObject:@"bookmark.hash IN (SELECT bookmark_hash FROM tagging WHERE tag_name = ? COLLATE NOCASE)"];
                [parameters addObject:tag];
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

    [whereComponents addObject:@"bookmark.hash IS NOT NULL"];

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
    PPPinboardDataSource *dataSource = [[PPPinboardDataSource alloc] init];
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
    if (self.searchQuery && ![self.searchQuery isEqualToString:@"*"]) {
        return NSLocalizedString(@"Search in Results", nil);
    }

    switch (self.untagged) {
        case kPushpinFilterFalse:
            return NSLocalizedString(@"Search Tagged", nil);

        case kPushpinFilterTrue:
            return NSLocalizedString(@"Search Untagged", nil);

        default:
            break;
    }

    switch (self.starred) {
        case kPushpinFilterTrue:
            return NSLocalizedString(@"Search Starred", nil);

        case kPushpinFilterFalse:
            return NSLocalizedString(@"Search Unstarred", nil);

        default:
            break;
    }

    switch (self.isPrivate) {
        case kPushpinFilterTrue:
            return NSLocalizedString(@"Search Private", nil);

        case kPushpinFilterFalse:
            return NSLocalizedString(@"Search Public", nil);

        default:
            break;
    }

    switch (self.unread) {
        case kPushpinFilterTrue:
            return NSLocalizedString(@"Search Unread", nil);

        case kPushpinFilterFalse:
            return NSLocalizedString(@"Search Read", nil);

        default:
            break;
    }

    return NSLocalizedString(@"Search", nil);
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
            } else {
                [titleButton setImageNames:imageNames title:nil];
            }
        } else if (imageNames.count == 1) {
            [titleButton setTitle:title imageName:imageNames[0]];
        } else {
            [titleButton setTitle:title imageName:nil];
        }
    } else {
        if (self.tags.count > 0) {
            NSMutableArray *htmlDecodedTags = [NSMutableArray array];
            for (NSString *tag in self.tags) {
                [htmlDecodedTags addObject:[tag stringByDecodingHTMLEntities]];
            }
            [titleButton setTitle:[htmlDecodedTags componentsJoinedByString:@"+"] imageName:nil];
        } else {
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
    } else {
#warning Might want to tweak this.
        return YES;
    }
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
    BOOL skipStarred = NO;
    if (options[@"skipStarred"]) {
        skipStarred = YES;
    }

    NSInteger count = -1;
    if (options[@"count"]) {
        count = [options[@"count"] integerValue];
    }

    [self syncBookmarksWithCompletion:completion
                             progress:progress
                                count:count
                          skipStarred:skipStarred];
}

- (void)syncBookmarksWithCompletion:(void (^)(BOOL updated, NSError *))completion
                           progress:(void (^)(NSInteger, NSInteger))progress
                              count:(NSInteger)count
                        skipStarred:(BOOL)skipStarred {
    if (!progress) {
        progress = ^(NSInteger current, NSInteger total) {};
    }

    __weak PPPinboardDataSource *weakSelf = self;
    // Dispatch serially to ensure that no two syncs happen simultaneously.
    dispatch_async(PPBookmarkUpdateQueue(), ^{
        __weak PPPinboardDataSource *_weakSelf;
        if (weakSelf) {
            __strong PPPinboardDataSource *strongSelf = weakSelf;
            _weakSelf = strongSelf;
        } else {
            _weakSelf = self;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __strong PPPinboardDataSource *_strongSelf = self;

            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [pinboard lastUpdateWithSuccess:^(NSDate *date) {
                if (_strongSelf) {
                    [_strongSelf BookmarksUpdatedTimeSuccessBlock:date
                                                           count:count
                                                      completion:completion
                                                        progress:progress
                                                     skipStarred:skipStarred];
                } else {
                    completion(NO, nil);
                }
            } failure:^(NSError *error) {
                completion(NO, error);
            }];
        });
    });
}

- (void)BookmarksSuccessBlock:(NSArray *)posts constraints:(NSDictionary *)constraints count:(NSInteger)count completion:(void (^)(BOOL, NSError *))completion progress:(void (^)(NSInteger, NSInteger))progress skipStarred:(BOOL)skipStarred {
    DLog(@"%@ - Received data", [NSDate date]);
    NSDate *startDate = [NSDate date];
    PPSettings *settings = [PPSettings sharedSettings];

    __weak PPPinboardDataSource *weakSelf = self;

    __block NSUInteger total;
    __block NSMutableArray *previousBookmarks;

    [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM bookmark WHERE hash IS NULL"];

        FMResultSet *results;

        NSMutableArray *tags = [NSMutableArray array];
        results = [db executeQuery:@"SELECT name FROM tag"];
        while ([results next]) {
            NSString *name = [results stringForColumn:@"name"];
            [tags addObject:name];
        }

        [results close];

        NSString *firstHash;
        if (posts.count > 0) {
            firstHash = posts[0][@"hash"];
        } else {
            firstHash = @"";
        }

        total = posts.count;

        if (count > 0) {
            NSDictionary *earliestPost = [self paramsForPost:[posts lastObject] dateError:NO];
            results = [db executeQuery:@"SELECT meta, hash, url FROM bookmark WHERE created_at >= ? ORDER BY created_at DESC"
                  withArgumentsInArray:@[earliestPost[@"created_at"]]];
        } else {
            results = [db executeQuery:@"SELECT meta, hash, url FROM bookmark ORDER BY created_at DESC"];
        }

        previousBookmarks = [NSMutableArray array];
        while ([results next]) {
            [previousBookmarks addObject:@{@"hash": [results stringForColumn:@"hash"],
                                           @"meta": [results stringForColumn:@"meta"]}];
        }

        [results close];
    }];

    DLog(@"Iterating posts");
    progress(0, total);

    NSNotificationQueue *queue = [NSNotificationQueue defaultQueue];
    [queue enqueueNotification:[NSNotification notificationWithName:kPinboardDataSourceProgressNotification
                                                             object:nil
                                                           userInfo:@{@"current": @(0), @"total": @(total)}]
                  postingStyle:NSPostASAP];

    NSMutableDictionary *bookmarks = [NSMutableDictionary dictionary];
    for (id post in posts) {
        bookmarks[post[@"hash"]] = post;
    }

    [PPUtilities generateDiffForPrevious:previousBookmarks
                                 updated:posts
                                    hash:^NSString *(id obj) { return obj[@"hash"]; }
                                    meta:^NSString *(id obj) { return obj[@"meta"]; }
                              completion:^(NSSet *inserted, NSSet *updated, NSSet *deleted) {
        __block CGFloat index = 0;
        __block NSUInteger updateCount = 0;
        __block NSUInteger addCount = 0;
        __block NSUInteger deleteCount = 0;
        __block NSUInteger tagAddCount = 0;
        __block NSUInteger tagDeleteCount = 0;

        // Only track one date error per update
        __block BOOL dateError = NO;

        __block CGFloat amountToAdd = (CGFloat)inserted.count / posts.count;

        [[PPUtilities databaseQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for (NSString *hash in inserted) {
                NSDictionary *post = bookmarks[hash];

                NSString *postTags = [PPUtilities stringByTrimmingWhitespace:post[@"tags"]];
                NSDictionary *params = [self paramsForPost:post dateError:dateError];
                if (!dateError && !params) {
                    dateError = YES;
                }

                [db executeUpdate:@"INSERT INTO bookmark (title, description, url, private, unread, hash, tags, meta, created_at) VALUES (:title, :description, :url, :private, :unread, :hash, :tags, :meta, :created_at);" withParameterDictionary:params];
                addCount++;

                [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash=?" withArgumentsInArray:@[hash]];
                tagDeleteCount++;

                for (NSString *tagName in [postTags componentsSeparatedByString:@" "]) {
                    NSString *cleanedTagName = [PPUtilities stringByTrimmingWhitespace:[tagName stringByDecodingHTMLEntities]];
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

            amountToAdd = (CGFloat)deleted.count / posts.count;
            for (NSString *hash in deleted) {
                [db executeUpdate:@"DELETE FROM bookmark WHERE hash=?" withArgumentsInArray:@[hash]];
                deleteCount++;
                index += amountToAdd;
                progress((NSInteger)index, total);
                NSNotification *note = [NSNotification notificationWithName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(index), @"total": @(total)}];
                [queue enqueueNotification:note postingStyle:NSPostASAP];
            }

            amountToAdd = (CGFloat)updated.count / posts.count;
            for (NSString *hashmeta in updated) {
                NSString *hash = [hashmeta componentsSeparatedByString:@"_"][0];
                NSDictionary *post = bookmarks[hash];

                NSDate *date = [self.enUSPOSIXDateFormatter dateFromString:post[@"time"]];
                if (!dateError && !date) {
                    date = [NSDate dateWithTimeIntervalSince1970:0];

                    dateError = YES;
                }

                NSString *postTags = [PPUtilities stringByTrimmingWhitespace:post[@"tags"]];

                NSDictionary *params = [self paramsForPost:post dateError:dateError];
                if (!dateError && !params) {
                    dateError = YES;
                }

                // Update this bookmark
                [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, url=:url, private=:private, unread=:unread, tags=:tags, meta=:meta, created_at=:created_at WHERE hash=:hash" withParameterDictionary:params];
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
                NSNotification *note = [NSNotification notificationWithName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(index), @"total": @(total)}];
                [queue enqueueNotification:note postingStyle:NSPostASAP];
            }

            DLog(@"Updating tags");
            [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_hash NOT IN (SELECT hash FROM bookmark)"];
            [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_name=tag.name)"];
            [db executeUpdate:@"DELETE FROM tag WHERE count=0"];
        }];

        NSDate *endDate = [NSDate date];

        if (inserted.count > 0 || updated.count > 0 || deleted.count > 0) {
            [[PPPinboardDataSource resultCache] removeAllObjects];
            [[PPPinboardMetadataCache sharedCache] removeAllObjects];
        }

        DLog(@"%f", [endDate timeIntervalSinceDate:startDate]);
        DLog(@"added %lu", (unsigned long)[inserted count]);
        DLog(@"updated %lu", (unsigned long)[updated count]);
        DLog(@"removed %lu", (unsigned long)[deleted count]);
        DLog(@"tags added %lu", (unsigned long)tagAddCount);

        self.totalNumberOfPosts = index;

        [settings setLastUpdated:[NSDate date]];
        kPinboardSyncInProgress = NO;

        progress(total, total);

        NSNotification *note = [NSNotification notificationWithName:kPinboardDataSourceProgressNotification object:nil userInfo:@{@"current": @(total), @"total": @(total)}];
        [queue enqueueNotification:note postingStyle:NSPostASAP];

        BOOL updatesMade = addCount > 0 || updateCount > 0 || deleteCount > 0;
        if (weakSelf) {
            __strong PPPinboardDataSource *strongSelf = weakSelf;
            if (skipStarred) {
                completion(updatesMade, nil);
                [strongSelf updateSpotlightSearchIndex];
            } else {
                __weak PPPinboardDataSource *_weakSelf = strongSelf;
                [strongSelf updateStarredPostsWithCompletion:^(NSError *error) {
                    completion(updatesMade, error);
                    [_weakSelf updateSpotlightSearchIndex];
                }];
            }
        } else {
            completion(updatesMade, nil);
        }
    }];
}

- (void)BookmarksUpdatedTimeSuccessBlock:(NSDate *)updateTime count:(NSInteger)count completion:(void (^)(BOOL, NSError *))completion progress:(void (^)(NSInteger, NSInteger))progress skipStarred:(BOOL)skipStarred {
    PPSettings *settings = [PPSettings sharedSettings];

    NSDate *lastLocalUpdate = [settings lastUpdated];
    BOOL neverUpdated = lastLocalUpdate == nil;
    BOOL outOfSyncWithAPI = [lastLocalUpdate compare:updateTime] == NSOrderedAscending;
    BOOL lastUpdatedMoreThanFiveMinutesAgo = fabs([lastLocalUpdate timeIntervalSinceNow]) >= 300;

    if (neverUpdated || outOfSyncWithAPI || lastUpdatedMoreThanFiveMinutesAgo) {
        __strong PPPinboardDataSource* strongSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [pinboard bookmarksWithTags:nil
                                 offset:-1
                                  count:count
                               fromDate:nil
                                 toDate:nil
                            includeMeta:YES
                                success:^(NSArray *bookmarks, NSDictionary *parameters) {
                if (bookmarks.count > 0 && strongSelf) {
                    [strongSelf BookmarksSuccessBlock:bookmarks
                                          constraints:parameters
                                                count:count
                                           completion:completion
                                             progress:progress
                                          skipStarred:skipStarred];
                } else {
                    completion(NO, [NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                }
            }
                                failure:^(NSError *error) {
                completion(NO, error);
            }];
        });
    } else {
        kPinboardSyncInProgress = NO;

        __weak PPPinboardDataSource *weakSelf = self;
        [self updateStarredPostsWithCompletion:^(NSError *error) {
            completion(NO, error);
            [weakSelf updateSpotlightSearchIndex];
        }];
    }
}

- (void)updateSpotlightSearchIndex {
    [[PPUtilities databaseQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        CSSearchableIndex *index = [CSSearchableIndex defaultSearchableIndex];
        NSMutableArray <CSSearchableItem *> *items = [NSMutableArray array];
        FMResultSet *results = [db executeQuery:@"SELECT * FROM bookmark WHERE searchable_in_spotlight=0"];
        while ([results next]) {
            NSDictionary *bookmark = [PPUtilities dictionaryFromResultSet:results];
            NSString *title = bookmark[@"title"];
            NSString *description = bookmark[@"description"];

            NSString *urlString = [bookmark[@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSURL *url = [NSURL URLWithString:urlString];
            NSDate *createdAt = bookmark[@"created_at"];

            CSSearchableItemAttributeSet* attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeText];
            attributeSet.title = title;
            attributeSet.originalSource = @"Pushpin";
            attributeSet.contentURL = url;
            attributeSet.contentDescription = description;
            attributeSet.contentCreationDate = createdAt;

            NSString *uniqueIdentifier = url.absoluteString;
            CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:uniqueIdentifier
                                                                       domainIdentifier:@"io.aurora.Pushpin.search"
                                                                           attributeSet:attributeSet];
            [items addObject:item];

            [db executeUpdate:@"UPDATE bookmark SET searchable_in_spotlight=1 WHERE url=?" withArgumentsInArray:@[bookmark[@"url"]]];
        }

        [index indexSearchableItems:items completionHandler:nil];
    }];
}

- (NSDictionary *)paramsForPost:(NSDictionary *)post dateError:(BOOL)dateError {
    NSDate *date = [self.enUSPOSIXDateFormatter dateFromString:post[@"time"]];
    if (!dateError && !date) {
        date = [NSDate dateWithTimeIntervalSince1970:0];

        DLog(@"Error parsing date: %@", post[@"time"]);

        // XXX This changed recently! Could be a source of issues.
        return nil;
    }

    NSString *hash = post[@"hash"];
    NSString *meta = post[@"meta"];

    NSString *postTags = [PPUtilities stringByTrimmingWhitespace:post[@"tags"]];
    NSString *title = [PPUtilities stringByTrimmingWhitespace:post[@"description"]];
    NSString *description = [PPUtilities stringByTrimmingWhitespace:post[@"extended"]];

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
}

- (void)reloadBookmarksWithCompletion:(void (^)(NSError *))completion
                               cancel:(BOOL (^)(void))cancel
                                width:(CGFloat)width {
    NSDate *timeWhenReloadBegan = [NSDate date];
    self.latestReloadTime = timeWhenReloadBegan;
    dispatch_async(PPBookmarkReloadQueue(), ^{
        self.mostRecentWidth = width;

        void (^HandleSearch)(NSString *, NSArray *) = ^(NSString *query, NSArray *parameters) {
            NSMutableArray *updatedBookmarks = [NSMutableArray array];
            __block NSInteger row = 0;

            NSMutableDictionary *newTagsWithFrequencies = [NSMutableDictionary dictionary];

            if (cancel && cancel()) {
                completion([NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                return;
            }

            __block BOOL shouldReturn = NO;
            __block NSMutableSet *urls = [NSMutableSet set];
            [[PPURLCache databaseQueue] inDatabase:^(FMDatabase *db) {
                FMResultSet *results = [db executeQuery:@"SELECT url FROM cache"];

                while ([results next]) {
                    NSString *url = [results stringForColumnIndex:0];
                    url = [url originalURLString];
                    [urls addObject:url];
                }
            }];

            NSString *key = [query stringByAppendingString:[parameters componentsJoinedByString:@""]];
            NSString *checksum = [PPURLCache md5ChecksumForData:[key dataUsingEncoding:NSUTF8StringEncoding]];

            PPCachedResult *result = [[PPPinboardDataSource resultCache] objectForKey:checksum];
            if (result) {
                newTagsWithFrequencies = result.tagsWithFrequencies;
                updatedBookmarks = result.bookmarks;
            } else {
                [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                    FMResultSet *results = [db executeQuery:query withArgumentsInArray:parameters];

                    if (cancel && cancel()) {
                        completion([NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                        shouldReturn = YES;
                        return;
                    }

                    row = 0;
                    while ([results next]) {
                        NSMutableDictionary *post = [[PPPinboardDataSource postFromResultSet:results] mutableCopy];
                        if ([urls containsObject:post[@"url"]]) {
                            post[@"offline"] = @(YES);
                        }
                        [updatedBookmarks addObject:post];
                    }

                    [results close];

                    if (cancel && cancel()) {
                        DLog(@"B: Cancelling search for query (%@)", self.searchQuery);
                        completion([NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                        shouldReturn = YES;
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

                result = [[PPCachedResult alloc] init];
                result.tagsWithFrequencies = newTagsWithFrequencies;
                result.bookmarks = updatedBookmarks;

                [[PPPinboardDataSource resultCache] setObject:result forKey:checksum];
            }

            if (shouldReturn) {
                return;
            }

            if (cancel && cancel()) {
                DLog(@"C: Cancelling search for query (%@)", self.searchQuery);
                completion([NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                return;
            }

            NSMutableArray *newMetadata = [NSMutableArray array];
            NSMutableArray *newCompressedMetadata = [NSMutableArray array];

            for (NSDictionary *post in updatedBookmarks) {
                PostMetadata *metadata = [PostMetadata metadataForPost:post
                                                            compressed:NO
                                                                 width:width
                                                     tagsWithFrequency:self.tagsWithFrequency
                                                                 cache:YES];
                [newMetadata addObject:metadata];

                PostMetadata *compressedMetadata = [PostMetadata metadataForPost:post
                                                                      compressed:YES
                                                                           width:width
                                                               tagsWithFrequency:self.tagsWithFrequency
                                                                           cache:YES];
                [newCompressedMetadata addObject:compressedMetadata];
            }

            // We run this block to make sure that these results should be the latest on file
            if (cancel && cancel() && self.latestReloadTime != timeWhenReloadBegan) {
                DLog(@"Cancelling search for query (%@)", self.searchQuery);
                completion([NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
            } else {
                self.posts = updatedBookmarks;
                self.metadata = newMetadata;
                self.compressedMetadata = newCompressedMetadata;
                self.tagsWithFrequency = newTagsWithFrequencies;

                completion(nil);
            }
        };

        if (self.searchScope != ASPinboardSearchScopeNone) {
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            PPSettings *settings = [PPSettings sharedSettings];
            if (settings.password.length > 0) {
                [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
                [pinboard searchBookmarksWithUsername:settings.username
                                             password:settings.password
                                                query:self.searchQuery
                                                scope:self.searchScope
                                           completion:^(NSArray *urls, NSError *error) {
                                               [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
                                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                   if (!error) {
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

                                                       HandleSearch(query, parameters);
                                                   }
                                               });
                                           }];
            } else {
                if (!self.fullTextSearchAlertView.presentingViewController) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIViewController lhs_topViewController] presentViewController:self.fullTextSearchAlertView animated:YES completion:nil];
                    });
                }
            }
        } else {
            [self generateQueryAndParameters:HandleSearch];
        }
    });
}

@end
