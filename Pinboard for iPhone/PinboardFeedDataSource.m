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
#import "PPBadgeView.h"

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

- (void)compressedMetadataForPost:(NSDictionary *)post callback:(void (^)(NSAttributedString *, NSNumber *, NSArray *, NSArray *))callback {
    [self metadataForPost:post compressed:YES callback:callback];
}

- (void)metadataForPost:(NSDictionary *)post callback:(void (^)(NSAttributedString *, NSNumber *, NSArray *, NSArray *))callback {
    [self metadataForPost:post compressed:NO callback:callback];
}

- (void)metadataForPost:(NSDictionary *)post compressed:(BOOL)compressed callback:(void (^)(NSAttributedString *, NSNumber *, NSArray *, NSArray *))callback {
    UIFont *titleFont = [UIFont fontWithName:[AppDelegate heavyFontName] size:16.f];
    UIFont *descriptionFont = [UIFont fontWithName:[AppDelegate bookFontName] size:14.f];
    UIFont *urlFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

    NSString *title = [post[@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *description = [post[@"description"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *tags = [post[@"tags"] stringByReplacingOccurrencesOfString:@" " withString:@" · "];
    BOOL isRead = NO;

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
        descriptionRange = NSMakeRange(linkRange.location + linkRange.length + 1, [description length]);
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
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
    [attributedString setFont:titleFont range:titleRange];
    [attributedString setFont:descriptionFont range:descriptionRange];
    [attributedString setFont:urlFont range:linkRange];
    [attributedString setTextColor:HEX(0x33353Bff)];
    
    /*
    [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
    */
    
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
            tempString = [self trimTrailingPunctuationFromAttributedString:[titleAttributedString attributedSubstringFromRange:titleLineRange] trimmedLength:&trimmedCharacterCount];
            attributedString = [NSMutableAttributedString attributedStringWithAttributedString:tempString];
            if (titleLineRange.length < titleRange.length) {
                [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@"…"]];
                extraCharacterCount++;
            }
            [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@"\n"]];
            extraCharacterCount++;
            titleRange = NSMakeRange(0, titleLineRange.length + extraCharacterCount - trimmedCharacterCount);
        }
        
        if (linkAttributedString) {
            extraCharacterCount = 0;
            tempString = [self trimTrailingPunctuationFromAttributedString:[linkAttributedString attributedSubstringFromRange:linkLineRange] trimmedLength:&trimmedCharacterCount];
            [attributedString appendAttributedString:tempString];
            if (linkLineRange.length < linkRange.length) {
                [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@"…"]];
                extraCharacterCount++;
            }
            [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@"\n"]];
            linkRange = NSMakeRange(titleRange.location + titleRange.length + extraCharacterCount - trimmedCharacterCount, linkLineRange.length);
        }
        
        if (descriptionAttributedString) {
            extraCharacterCount = 0;
            tempString = [self trimTrailingPunctuationFromAttributedString:[descriptionAttributedString attributedSubstringFromRange:descriptionLineRange] trimmedLength:&trimmedCharacterCount];
            [attributedString appendAttributedString:tempString];
            if (descriptionLineRange.length < descriptionRange.length) {
                [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@"…"]];
                extraCharacterCount++;
            }
            descriptionRange = NSMakeRange(linkRange.location + linkRange.length + extraCharacterCount - trimmedCharacterCount, descriptionLineRange.length);
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

    NSMutableArray *badges = [NSMutableArray array];
    if ([post[@"private"] boolValue]) [badges addObject:@{ @"type": @"image", @"image": @"bookmark-private" }];
    if ([post[@"starred"] boolValue]) [badges addObject:@{ @"type": @"image", @"image": @"bookmark-favorite" }];
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
    
    NSNumber *height = @([attributedString sizeConstrainedToSize:CGSizeMake([UIApplication currentSize].width, CGFLOAT_MAX)].height);

    callback(attributedString, height, @[], badges);
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
