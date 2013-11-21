//
//  PinboardFeedDataSource.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/22/13.
//
//

#import "PinboardFeedDataSource.h"
#import "AppDelegate.h"
#import "ASPinboard/ASPinboard.h"
#import "NSAttributedString+Attributes.h"
#import "NSString+URLEncoding2.h"
#import "AddBookmarkViewController.h"
#import "FMDatabase.h"
#import "UIApplication+AppDimensions.h"

@implementation PinboardFeedDataSource

- (id)initWithComponents:(NSArray *)components {
    self = [super init];
    if (self) {
        self.components = components;
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        self.locale = [NSLocale currentLocale];
        [self.dateFormatter setLocale:self.locale];
        [self.dateFormatter setDoesRelativeDateFormatting:YES];
        self.count = 100;
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        self.locale = [NSLocale currentLocale];
        [self.dateFormatter setLocale:self.locale];
        [self.dateFormatter setDoesRelativeDateFormatting:YES];
        self.count = 100;
    }
    return self;
}

+ (PinboardFeedDataSource *)dataSourceWithComponents:(NSArray *)components {
    return [[PinboardFeedDataSource alloc] initWithComponents:components];
}

#pragma mark - Delegate Methods

- (NSArray *)actionsForPost:(NSDictionary *)post {
    NSMutableArray *actions = [NSMutableArray array];
    [actions addObject:@(PPPostActionCopyToMine)];
    [actions addObject:@(PPPostActionCopyURL)];
    
    if ([[AppDelegate sharedDelegate] readlater]) {
        [actions addObject:@(PPPostActionReadLater)];
    }
    
    return actions;
}

- (NSInteger)numberOfPosts {
    return self.posts.count;
}

- (NSInteger)totalNumberOfPosts {
    return 0;
}

- (BOOL)isPostAtIndexStarred:(NSInteger)index {
    return NO;
}

- (BOOL)isPostAtIndexPrivate:(NSInteger)index {
    return NO;
}

- (NSDictionary *)postAtIndex:(NSInteger)index {
    return self.posts[index];
}

- (NSString *)urlForPostAtIndex:(NSInteger)index {
    return self.posts[index][@"url"];
}

- (void)updatePostsFromDatabaseWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure {
    [self updatePostsWithSuccess:success failure:failure options:nil];
}

- (NSURL *)url {
    NSMutableArray *escapedComponents = [NSMutableArray array];
    for (NSString *component in self.components) {
        NSString *substring = [component substringFromIndex:2];
        if ([component hasPrefix:@"t:"]) {
            substring = [NSString stringWithFormat:@"t:%@", [[substring urlEncodeUsingEncoding:NSUTF8StringEncoding] urlEncodeUsingEncoding:NSUTF8StringEncoding]];
            [escapedComponents addObject:substring];
        }
        else if ([component hasPrefix:@"u:"]) {
            substring = [NSString stringWithFormat:@"u:%@", [[substring urlEncodeUsingEncoding:NSUTF8StringEncoding] urlEncodeUsingEncoding:NSUTF8StringEncoding]];
            [escapedComponents addObject:substring];
        }
        else {
            [escapedComponents addObject:component];
        }
    }
    
    NSString *urlString;
    
    // If it's our username, we need to use the feed token to get any private tags
    NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
    NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
    if ([[escapedComponents objectAtIndex:0] isEqualToString:[NSString stringWithFormat:@"u:%@", username]]) {
        urlString = [NSString stringWithFormat:@"https://feeds.pinboard.in/json/secret:%@/%@?count=%d", feedToken, [escapedComponents componentsJoinedByString:@"/"], self.count];
    } else {
        urlString = [NSString stringWithFormat:@"https://feeds.pinboard.in/json/%@?count=%d", [escapedComponents componentsJoinedByString:@"/"], self.count];
    }
    
    return [NSURL URLWithString:urlString];
}

- (void)updatePostsWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure options:(NSDictionary *)options {
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    [delegate setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [delegate setNetworkActivityIndicatorVisible:NO];

                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                   if (!error) {
                                       NSMutableArray *indexPathsToAdd = [NSMutableArray array];
                                       NSMutableArray *indexPathsToRemove = [NSMutableArray array];
                                       NSMutableArray *indexPathsToReload = [NSMutableArray array];
                                       NSMutableArray *newPosts = [NSMutableArray array];
                                       NSMutableArray *newURLs = [NSMutableArray array];
                                       NSMutableArray *oldURLs = [NSMutableArray array];
                                       NSMutableArray *oldPosts = [self.posts copy];
                                       
                                       for (NSDictionary *post in self.posts) {
                                           [oldURLs addObject:post[@"url"]];
                                       }

                                       NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                       NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                       [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                                       [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                                       
                                       NSInteger index = 0;
                                       NSMutableArray *tags = [NSMutableArray array];
                                       NSDate *date;

                                       #warning XXX Should refactor to update / reload / delete more efficiently
                                       for (NSDictionary *element in payload) {
                                           [tags removeAllObjects];
                                           [tags addObject:[NSString stringWithFormat:@"via:%@", element[@"a"]]];
                                           for (NSString *tag in element[@"t"]) {
                                               if (![tag isEqual:[NSNull null]] && ![tag isEqualToString:@""]) {
                                                   [tags addObject:tag];
                                               }
                                           }
                                           
                                           date = [dateFormatter dateFromString:element[@"dt"]];
                                           if (!date) {
                                               // https://rink.hockeyapp.net/manage/apps/33685/app_versions/4/crash_reasons/4734816
                                               date = [NSDate date];
                                           }

                                           NSMutableDictionary *post = [NSMutableDictionary dictionaryWithDictionary:@{
                                                @"title": element[@"d"],
                                                @"description": element[@"n"],
                                                @"url": element[@"u"],
                                                @"tags": [tags componentsJoinedByString:@" "],
                                                @"created_at": date
                                            }];
                                           
                                           if (post[@"title"] == [NSNull null]) {
                                               post[@"title"] = @"";
                                           }
                                           
                                           if (post[@"description"] == [NSNull null]) {
                                               post[@"description"] = @"";
                                           }
                                           
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
                                       
                                       for (int i=0; i<oldURLs.count; i++) {
                                           if (![newURLs containsObject:oldURLs[i]]) {
                                               [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:[self.posts indexOfObject:oldPosts[i]] inSection:0]];
                                           }
                                       }
                                       
                                       self.posts = newPosts;
                                       
                                       NSMutableArray *newStrings = [NSMutableArray array];
                                       NSMutableArray *newHeights = [NSMutableArray array];
                                       NSMutableArray *newLinks = [NSMutableArray array];
                                       NSMutableArray *newBadges = [NSMutableArray array];

                                       NSMutableArray *newCompressedStrings = [NSMutableArray array];
                                       NSMutableArray *newCompressedHeights = [NSMutableArray array];
                                       NSMutableArray *newCompressedLinks = [NSMutableArray array];
                                       NSMutableArray *newCompressedBadges = [NSMutableArray array];
                                       for (NSDictionary *post in newPosts) {
                                           [self metadataForPost:post callback:^(NSAttributedString *string, NSNumber *height, NSArray *links, NSArray *badges) {
                                               [newHeights addObject:height];
                                               [newStrings addObject:string];
                                               [newLinks addObject:links];
                                               [newBadges addObject:badges];
                                           }];
                                           
                                           [self compressedMetadataForPost:post callback:^(NSAttributedString *string, NSNumber *height, NSArray *links, NSArray *badges) {
                                               [newCompressedHeights addObject:height];
                                               [newCompressedStrings addObject:string];
                                               [newCompressedLinks addObject:links];
                                               [newCompressedBadges addObject:badges];
                                           }];
                                       }
                                       
                                       self.strings = newStrings;
                                       self.heights = newHeights;
                                       self.links = newLinks;
                                       self.badges = newBadges;

                                       self.compressedStrings = newCompressedStrings;
                                       self.compressedHeights = newCompressedHeights;
                                       self.compressedLinks = newCompressedLinks;
                                       self.compressedBadges = newCompressedBadges;
                                       
                                       if (success != nil) {
                                           success(indexPathsToAdd, indexPathsToReload, indexPathsToRemove);
                                       }
                                   }
                               });
                           }];
}

#warning XXX Code smell, repeats metadataForPost
- (void)compressedMetadataForPost:(NSDictionary *)post callback:(void (^)(NSAttributedString *, NSNumber *, NSArray *, NSArray *))callback {
    UIFont *titleFont = [UIFont fontWithName:[AppDelegate heavyFontName] size:16.f];
    UIFont *dateFont = [UIFont fontWithName:[AppDelegate mediumFontName] size:10];
    
    NSString *title = [post[@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *dateString = [self.dateFormatter stringFromDate:post[@"created_at"]];
    
    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", title];
    NSRange titleRange = NSMakeRange(0, title.length);
    
    [content appendFormat:@"\n%@", dateString];
    NSRange dateRange = NSMakeRange(content.length - dateString.length, dateString.length);
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
    [attributedString setFont:titleFont range:titleRange];
    [attributedString setTextColor:HEX(0x33353Bff)];
    [attributedString setTextColor:HEX(0x353840ff) range:titleRange];
    [attributedString setTextColor:HEX(0xA5A9B2ff) range:dateRange];
    [attributedString setFont:dateFont range:dateRange];
    [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];

    NSMutableArray *badges = [NSMutableArray array];
    if ([post[@"private"] boolValue]) [badges addObject:@{ @"type": @"image", @"image": @"bookmark-private" }];
    if ([post[@"starred"] boolValue]) [badges addObject:@{ @"type": @"image", @"image": @"bookmark-favorite" }];
    NSArray *tagsArray = [post[@"tags"] componentsSeparatedByString:@" "];
    [tagsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![obj hasPrefix:@"via:"]) {
            [badges addObject:@{ @"type": @"tag", @"tag": obj }];
        }
    }];
    
    NSNumber *height = @([attributedString sizeConstrainedToSize:CGSizeMake([UIApplication currentSize].width, CGFLOAT_MAX)].height);
    callback(attributedString, height, @[], badges);
}

- (void)metadataForPost:(NSDictionary *)post callback:(void (^)(NSAttributedString *, NSNumber *, NSArray *, NSArray *))callback {
    UIFont *titleFont = [UIFont fontWithName:[AppDelegate heavyFontName] size:16.f];
    UIFont *descriptionFont = [UIFont fontWithName:[AppDelegate bookFontName] size:14.f];
    UIFont *tagsFont = [UIFont fontWithName:[AppDelegate mediumFontName] size:12];
    UIFont *dateFont = [UIFont fontWithName:[AppDelegate mediumFontName] size:10];

    NSString *title = [post[@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *description = [post[@"description"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *tags = [post[@"tags"] stringByReplacingOccurrencesOfString:@" " withString:@" · "];
    NSString *dateString = [self.dateFormatter stringFromDate:post[@"created_at"]];
    BOOL isRead = NO;

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
        tagRange = NSMakeRange(titleRange.location + titleRange.length + descriptionRange.length + offset, tags.length);
    }

    BOOL hasTags = tagRange.location != NSNotFound;
    
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
    
    [attributedString setTextColor:HEX(0xA5A9B2ff) range:dateRange];
    [attributedString setFont:dateFont range:dateRange];
    [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];

    NSMutableArray *badges = [NSMutableArray array];
    if ([post[@"private"] boolValue]) [badges addObject:@{ @"type": @"image", @"image": @"bookmark-private" }];
    if ([post[@"starred"] boolValue]) [badges addObject:@{ @"type": @"image", @"image": @"bookmark-favorite" }];
    NSArray *tagsArray = [post[@"tags"] componentsSeparatedByString:@" "];
    [tagsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![obj hasPrefix:@"via:"]) {
            [badges addObject:@{ @"type": @"tag", @"tag": obj }];
        }
    }];
    
    NSNumber *height = @([attributedString sizeConstrainedToSize:CGSizeMake([UIApplication currentSize].width, CGFLOAT_MAX)].height);

    NSMutableArray *links = [NSMutableArray array];
    NSInteger location = tagRange.location;
    for (NSString *tag in [tags componentsSeparatedByString:@" · "]) {
        NSRange range = [tags rangeOfString:tag];
        [links addObject:@{@"url": [NSURL URLWithString:[tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]], @"location": @(location+range.location), @"length": @(range.length)}];
    }
    callback(attributedString, height, links, badges);
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

- (NSAttributedString *)attributedStringForPostAtIndex:(NSInteger)index {
    return self.strings[index];
}

- (CGFloat)heightForPostAtIndex:(NSInteger)index {
    return [self.heights[index] floatValue];
}

- (NSArray *)linksForPostAtIndex:(NSInteger)index {
    return self.links[index];
}

- (NSArray *)badgesForPostAtIndex:(NSInteger)index {
    return self.badges[index];
}

- (PPNavigationController *)addViewControllerForPostAtIndex:(NSInteger)index delegate:(id<ModalDelegate>)delegate {
    return [AddBookmarkViewController addBookmarkViewControllerWithBookmark:self.posts[index] update:@(NO) delegate:delegate callback:nil];
}

- (void)willDisplayIndexPath:(NSIndexPath *)indexPath callback:(void (^)(BOOL))callback {
    BOOL needsUpdate = indexPath.row >= self.count * 3. / 4. && self.count < 400;
    if (needsUpdate) {
        self.count = MAX(self.count + 100, 400);
    }
    callback(needsUpdate);
}

- (void)handleTapOnLinkWithURL:(NSURL *)url callback:(void (^)(UIViewController *))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *tagName = [url.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        BOOL shouldPush = NO;
        NSMutableArray *components = [NSMutableArray array];
        if ([tagName hasPrefix:@"via:"]) {
            NSString *userNameWithPrefix = [NSString stringWithFormat:@"u:%@", [tagName substringFromIndex:4]];
            if (![self.components containsObject:userNameWithPrefix]) {
                [components addObject:userNameWithPrefix];
                shouldPush = YES;
            }
        }
        else {
            if ([self.components[0] hasPrefix:@"t:"]) {
                components = [NSMutableArray arrayWithArray:self.components];
            }
            else if ([self.components[0] hasPrefix:@"u:"]) {
                components = [NSMutableArray arrayWithArray:self.components];
            }
            else {
                components = [NSMutableArray array];
            }
            
            NSString *tagNameWithPrefix = [NSString stringWithFormat:@"t:%@", tagName];
            if (![components containsObject:tagNameWithPrefix]) {
                [components addObject:tagNameWithPrefix];
                shouldPush = YES;
            }
        }
        
        if (components.count > 4) {
            shouldPush = NO;
        }

        if (shouldPush) {
            dispatch_async(dispatch_get_main_queue(), ^{
                GenericPostViewController *postViewController = [PinboardFeedDataSource postViewControllerWithComponents:components];
                callback(postViewController);
            });
        }
    });
}

+ (GenericPostViewController *)postViewControllerWithComponents:(NSArray *)components {
    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
    PinboardFeedDataSource *dataSource = [[PinboardFeedDataSource alloc] initWithComponents:components];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *result = [db executeQuery:@"SELECT COUNT(*) FROM feeds WHERE components=?" withArgumentsInArray:@[[components componentsJoinedByString:@" "]]];
    [result next];
    if ([result intForColumnIndex:0] > 0) {
        postViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStylePlain target:postViewController action:@selector(removeBarButtonTouchUpside:)];
    }
    else {
        postViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:postViewController action:@selector(addBarButtonTouchUpside:)];
    }
    [db close];
    
    postViewController.postDataSource = dataSource;
    postViewController.title = [components componentsJoinedByString:@"+"];
    return postViewController;
}

- (BOOL)supportsTagDrilldown {
    return NO;
}

- (void)addDataSource:(void (^)())callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        [db executeUpdate:@"INSERT INTO feeds (components) VALUES (?)" withArgumentsInArray:@[[self.components componentsJoinedByString:@" "]]];
        [db close];
        callback();
    });
}

- (void)removeDataSource:(void (^)())callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        [db executeUpdate:@"DELETE FROM feeds WHERE components=?" withArgumentsInArray:@[[self.components componentsJoinedByString:@" "]]];
        [db close];
        callback();
    });
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

@end
