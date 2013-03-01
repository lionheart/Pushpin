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
@synthesize posts;

- (void)filterByPrivate:(BOOL)isPrivate isRead:(BOOL)isRead isUntagged:(BOOL)isUntagged hasTags:(BOOL)hasTags tags:(NSArray *)tags offset:(NSInteger)offset limit:(NSInteger)limit {
    NSMutableArray *queryComponents = [NSMutableArray array];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{@"offset": @(offset), @"limit": @(limit)}];
    
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

- (NSArray *)posts {
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:self.query withParameterDictionary:self.queryParameters];
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
        
        [self.posts addObject:post];
        [newHeights addObject:[BookmarkViewController heightForBookmark:bookmark]];
        [newStrings addObject:[BookmarkViewController attributedStringForBookmark:bookmark]];
        [newURLs addObject:bookmark[@"url"]];
        
        if (![oldBookmarks containsObject:bookmark]) {
            // Check if the bookmark is being updated (as opposed to entirely new)
            if ([oldURLs containsObject:bookmark[@"url"]]) {
                [indexPathsToUpdate addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            }
            else {
                [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            }
            
            [self.bookmarks addObject:bookmark];
            [self.heights addObject:[BookmarkViewController heightForBookmark:bookmark]];
            [self.strings addObject:[BookmarkViewController attributedStringForBookmark:bookmark]];
        }
        index++;
    }
    [db close];
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
