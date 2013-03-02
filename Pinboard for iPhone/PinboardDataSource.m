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

@implementation PinboardDataSource

@synthesize query = _query;
@synthesize queryParameters = _queryParameters;
@synthesize posts = _posts;
@synthesize heights = _heights;
@synthesize strings = _strings;
@synthesize urls;
@synthesize maxResults;

- (void)filterByPrivate:(BOOL)isPrivate isRead:(BOOL)isRead isUntagged:(BOOL)isUntagged hasTags:(BOOL)hasTags tags:(NSArray *)tags offset:(NSInteger)offset limit:(NSInteger)limit {
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
        self.query = [NSString stringWithFormat:@"SELECT * FROM bookmarks WHERE %@ ORDER BY created_at LIMIT :limit OFFSET :offset", whereComponent];
    }
    else {
        self.query = @"SELECT * FROM bookmarks ORDER BY created_at LIMIT :limit OFFSET :offset";
    }
}

- (NSInteger)numberOfPosts {
    return [self.posts count];
}

- (void)updatePosts:(void (^)(NSArray *, NSArray *, NSArray *))callback {
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:self.query withParameterDictionary:self.queryParameters];
    
    NSMutableArray *posts = [NSMutableArray array];
    NSMutableArray *heights = [NSMutableArray array];
    NSMutableArray *strings = [NSMutableArray array];

    NSMutableArray *newPosts = [NSMutableArray array];
    NSMutableArray *newHeights = [NSMutableArray array];
    NSMutableArray *newStrings = [NSMutableArray array];
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
        };

        [newPosts addObject:post];
        [newHeights addObject:@([PinboardDataSource heightForPost:post])];
        [newStrings addObject:[PinboardDataSource attributedStringForPost:post]];
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
            [heights addObject:@([PinboardDataSource heightForPost:post])];
            [strings addObject:[PinboardDataSource attributedStringForPost:post]];
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
    self.heights = newHeights;
    self.strings = newStrings;

    if (callback != nil) {
        callback(indexPathsToAdd, indexPathsToReload, indexPathsToRemove);
    }
}

- (CGFloat)heightForPostAtIndex:(NSInteger)index {
    UIFont *largeHelvetica = [UIFont fontWithName:kFontName size:kLargeFontSize];
    UIFont *smallHelvetica = [UIFont fontWithName:kFontName size:kSmallFontSize];
    NSDictionary *post = self.posts[index];

    CGFloat height = 12.0f;
    height += ceilf([post[@"title"] sizeWithFont:largeHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);

    if (![post[@"description"] isEqualToString:@""]) {
        height += ceilf([post[@"description"] sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    }
    
    if (![post[@"tags"] isEqualToString:@""]) {
        height += ceilf([post[@"tags"] sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    }
    
    return height;
}

+ (NSArray *)linksForPost:(NSDictionary *)post {
    
}

+ (CGFloat)heightForPost:(NSDictionary *)post {
    
}

+ (NSMutableAttributedString *)attributedStringForPost:(NSDictionary *)post {
    
}

@end
