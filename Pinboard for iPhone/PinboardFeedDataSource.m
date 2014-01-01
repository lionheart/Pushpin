//
//  PinboardFeedDataSource.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/22/13.
//
//

#import "PinboardFeedDataSource.h"
#import "AppDelegate.h"
#import "AddBookmarkViewController.h"
#import "PPBadgeView.h"
#import "PPTheme.h"
#import "PostMetadata.h"
#import "PPTitleButton.h"

#import "NSAttributedString+Attributes.h"
#import "NSString+URLEncoding2.h"

#import <ASPinboard/ASPinboard.h>
#import <FMDB/FMDatabase.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

static NSString *emptyString = @"";
static NSString *newLine = @"\n";
static NSString *ellipsis = @"…";

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
        urlString = [NSString stringWithFormat:@"https://feeds.pinboard.in/json/secret:%@/%@?count=%ld", feedToken, [escapedComponents componentsJoinedByString:@"/"], (long)self.count];
    }
    else {
        urlString = [NSString stringWithFormat:@"https://feeds.pinboard.in/json/%@?count=%ld", [escapedComponents componentsJoinedByString:@"/"], (long)self.count];
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

                                       // TODO: Should refactor to update / reload / delete more efficiently
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
                                           PostMetadata *metadata = [self metadataForPost:post];
                                           [newHeights addObject:metadata.height];
                                           [newStrings addObject:metadata.string];
                                           [newLinks addObject:metadata.links];
                                           [newBadges addObject:metadata.badges];
                                           
                                           PostMetadata *compressedMetadata = [self compressedMetadataForPost:post];
                                           [newCompressedHeights addObject:compressedMetadata.height];
                                           [newCompressedStrings addObject:compressedMetadata.string];
                                           [newCompressedLinks addObject:compressedMetadata.links];
                                           [newCompressedBadges addObject:compressedMetadata.badges];
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

- (PostMetadata *)compressedMetadataForPost:(NSDictionary *)post {
    return [self metadataForPost:post compressed:YES];
}

- (PostMetadata *)metadataForPost:(NSDictionary *)post {
    return [self metadataForPost:post compressed:NO];
}

- (PostMetadata *)metadataForPost:(NSDictionary *)post compressed:(BOOL)compressed {
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    NSString *title = [post[@"title"] stringByTrimmingCharactersInSet:whitespace];
    if ([title isEqualToString:@""]) {
        title = @"Untitled";
    }

    NSString *description = [post[@"description"] stringByTrimmingCharactersInSet:whitespace];
    NSString *tags = post[@"tags"];
    
    BOOL isRead = NO;
    BOOL dimReadPosts = [AppDelegate sharedDelegate].dimReadPosts;

    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", title];
    NSRange titleRange = NSMakeRange(0, title.length);
    
    NSURL *linkUrl = [NSURL URLWithString:post[@"url"]];
    NSString *linkHost = [linkUrl host];
    NSRange linkRange = NSMakeRange((titleRange.location + titleRange.length) + 1, linkHost.length);
    [content appendString:[NSString stringWithFormat:@"\n%@", linkHost]];
    
    NSRange descriptionRange;
    if ([description isEqualToString:emptyString]) {
        descriptionRange = NSMakeRange(NSNotFound, 0);
    }
    else {
        descriptionRange = NSMakeRange((linkRange.location + linkRange.length) + 1, [description length]);
        [content appendString:[NSString stringWithFormat:@"\n%@", description]];
    }
    
    NSRange tagRange;
    if ([tags isEqualToString:emptyString]) {
        tagRange = NSMakeRange(NSNotFound, 0);
    }
    else {
        // Set the offset to one because of the line break between the title and tags
        NSInteger offset = 1;
        if (descriptionRange.location != NSNotFound) {
            // Another line break is included if the description isn't empty
            offset++;
        }
        tagRange = NSMakeRange(titleRange.length + descriptionRange.length + offset, tags.length);
    }
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];

    NSDictionary *titleAttributes = @{NSFontAttributeName: [PPTheme titleFont]};
    NSDictionary *descriptionAttributes = @{NSFontAttributeName: [PPTheme descriptionFont]};
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacingBefore = 3;
    paragraphStyle.paragraphSpacing = 0;
    paragraphStyle.lineHeightMultiple = 0.7;
    NSDictionary *linkAttributes = @{NSFontAttributeName: [PPTheme urlFont],
                                     NSParagraphStyleAttributeName: paragraphStyle
                                     };
    
    [attributedString addAttributes:titleAttributes range:titleRange];
    [attributedString addAttributes:descriptionAttributes range:descriptionRange];
    [attributedString addAttributes:linkAttributes range:linkRange];
    [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0x33353Bff) range:attributedString.fullRange];
    
    // Calculate our shorter strings if we're compressed
    if (compressed) {
        // Calculate elippsis size for each element
        CGSize ellipsisSizeTitle = [ellipsis sizeWithAttributes:titleAttributes];
        CGSize ellipsisSizeLink = [ellipsis sizeWithAttributes:linkAttributes];
        CGSize ellipsisSizeDescription = [ellipsis sizeWithAttributes:descriptionAttributes];
        
        CGSize textSize = CGSizeMake([UIApplication currentSize].width, CGFLOAT_MAX);
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:textSize];

        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        [layoutManager addTextContainer:textContainer];

        NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:emptyString];
        [textStorage addLayoutManager:layoutManager];

        [layoutManager setHyphenationFactor:1.0];
        [layoutManager glyphRangeForTextContainer:textContainer];

        NSRange titleLineRange, descriptionLineRange, linkLineRange;
        
        // Get the compressed substrings
        NSAttributedString *titleAttributedString, *descriptionAttributedString, *linkAttributedString;
        
        titleAttributedString = [attributedString attributedSubstringFromRange:titleRange];
        [textContainer setSize:CGSizeMake(UIApplication.currentSize.width - ellipsisSizeTitle.width - 10, CGFLOAT_MAX)];
        [textStorage setAttributedString:titleAttributedString];

        // Throws _NSLayoutTreeLineFragmentRectForGlyphAtIndex invalid glyph index 0 when title is of length 0
        [layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:&titleLineRange];
        
        if (descriptionRange.location != NSNotFound) {
            descriptionAttributedString = [attributedString attributedSubstringFromRange:descriptionRange];
            [textContainer setSize:CGSizeMake(UIApplication.currentSize.width - ellipsisSizeDescription.width - 10.0f, CGFLOAT_MAX)];
            [textStorage setAttributedString:descriptionAttributedString];
            
            descriptionLineRange = NSMakeRange(0, 0);
            NSUInteger index, numberOfLines, numberOfGlyphs = [layoutManager numberOfGlyphs];
            NSRange tempLineRange;
            for (numberOfLines=0, index=0; index < numberOfGlyphs; numberOfLines++){
                [layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&tempLineRange];
                descriptionLineRange.length += tempLineRange.length;
                if (numberOfLines >= [PPTheme maxNumberOfLinesForCompressedDescriptions] - 1) {
                    break;
                }
                index = NSMaxRange(tempLineRange);
            }
            descriptionLineRange.length = (descriptionLineRange.length > descriptionAttributedString.length) ? descriptionAttributedString.length : descriptionLineRange.length;
        }
        
        if (linkRange.location != NSNotFound) {
            linkAttributedString = [attributedString attributedSubstringFromRange:linkRange];
            [textContainer setSize:CGSizeMake(UIApplication.currentSize.width - ellipsisSizeLink.width - 10.0f, CGFLOAT_MAX)];
            [textStorage setAttributedString:linkAttributedString];
            [layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:&linkLineRange];
        }
        
        // Re-create the main string
        NSAttributedString *tempAttributedString;
        NSString *tempString;
        NSString *trimmedString;
        NSInteger characterOffset = 0;
        
        if (titleAttributedString && titleLineRange.location != NSNotFound) {
            tempString = [[titleAttributedString attributedSubstringFromRange:titleLineRange] string];
            trimmedString = [tempString stringByTrimmingCharactersInSet:whitespace];
            characterOffset = trimmedString.length - tempString.length;
            
            tempAttributedString = [[NSAttributedString alloc] initWithString:trimmedString attributes:titleAttributes];
            if (titleLineRange.length < titleRange.length) {
                tempAttributedString = [self stringByTrimmingTrailingPunctuationFromAttributedString:tempAttributedString offset:&characterOffset];
                attributedString = [NSMutableAttributedString attributedStringWithAttributedString:tempAttributedString];
                [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:ellipsis]];
                characterOffset++;
            }
            else {
                attributedString = [NSMutableAttributedString attributedStringWithAttributedString:tempAttributedString];
            }
            
            [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:newLine]];
            characterOffset++;
            
            titleRange = NSMakeRange(0, titleLineRange.length + characterOffset);
        }
        
        if (linkAttributedString && linkLineRange.location != NSNotFound) {
            tempString = [[[linkAttributedString attributedSubstringFromRange:linkLineRange] string] stringByTrimmingCharactersInSet:whitespace];
            trimmedString = [tempString stringByTrimmingCharactersInSet:whitespace];
            characterOffset = trimmedString.length - tempString.length;
            
            tempAttributedString = [[NSAttributedString alloc] initWithString:trimmedString attributes:linkAttributes];
            if (linkLineRange.length < linkRange.length) {
                tempAttributedString = [self stringByTrimmingTrailingPunctuationFromAttributedString:tempAttributedString offset:&characterOffset];
                [attributedString appendAttributedString:tempAttributedString];
                [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:ellipsis]];
                characterOffset++;
            }
            else {
                [attributedString appendAttributedString:tempAttributedString];
            }
            
            [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:newLine]];
            characterOffset++;
            
            linkRange = NSMakeRange(titleRange.length, linkLineRange.length + characterOffset);
        }
        
        if (descriptionAttributedString && descriptionLineRange.location != NSNotFound) {
            tempString = [[[descriptionAttributedString attributedSubstringFromRange:descriptionLineRange] string] stringByTrimmingCharactersInSet:whitespace];
            trimmedString = [tempString stringByTrimmingCharactersInSet:whitespace];
            characterOffset = trimmedString.length - tempString.length;
            
            tempAttributedString = [[NSAttributedString alloc] initWithString:trimmedString attributes:descriptionAttributes];
            
            if (descriptionLineRange.length < descriptionRange.length) {
                tempAttributedString = [self stringByTrimmingTrailingPunctuationFromAttributedString:tempAttributedString offset:&characterOffset];
                [attributedString appendAttributedString:tempAttributedString];
                [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:ellipsis]];
                characterOffset++;
            }
            else {
                [attributedString appendAttributedString:tempAttributedString];
            }
            
            descriptionRange = NSMakeRange(titleRange.length + linkRange.length, attributedString.fullRange.length - titleRange.length - linkRange.length);
        }
    }

    if (dimReadPosts && isRead) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0xb3b3b3ff) range:titleRange];
        [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0xcdcdcdff) range:linkRange];
        [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0x96989Dff) range:descriptionRange];
    }
    else {
        [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0x000000ff) range:titleRange];
        [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0xb4b6b9ff) range:linkRange];
        [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0x585858ff) range:descriptionRange];
    }

    NSMutableArray *badges = [NSMutableArray array];
    UIColor *privateColor = (isRead && dimReadPosts) ? HEX(0xddddddff) : HEX(0xfdbb6dff);
    UIColor *starredColor = (isRead && dimReadPosts) ? HEX(0xddddddff) : HEX(0xf0b2f7ff);
    if ([post[@"private"] boolValue]) [badges addObject:@{ @"type": @"image", @"image": @"badge-private", @"options": @{ PPBadgeNormalBackgroundColor: privateColor } }];
    if ([post[@"starred"] boolValue]) [badges addObject:@{ @"type": @"image", @"image": @"badge-favorite", @"options": @{ PPBadgeNormalBackgroundColor: starredColor } }];

    NSArray *tagList = [tags componentsSeparatedByString:@" "];
    for (NSString *tag in tagList) {
        if (![tag hasPrefix:@"via:"]) {
            if (isRead && dimReadPosts) {
                [badges addObject:@{ @"type": @"tag", @"tag": tag, @"options": @{ PPBadgeNormalBackgroundColor: HEX(0xddddddff) } }];
            }
            else {
                [badges addObject:@{ @"type": @"tag", @"tag": tag }];
            }
        }
    }
    
    // We use TTTAttributedLabel's method here because it sizes strings a tiny bit differently than NSAttributedString does
    CGSize size = [TTTAttributedLabel sizeThatFitsAttributedString:attributedString
                                                   withConstraints:CGSizeMake([UIApplication currentSize].width - 20, CGFLOAT_MAX)
                                            limitedToNumberOfLines:0];
    NSNumber *height = @(size.height);

    PostMetadata *metadata = [[PostMetadata alloc] init];
    metadata.height = height;
    metadata.links = @[];
    metadata.string = attributedString;
    metadata.badges = badges;
    return metadata;
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

    PPTitleButton *button = [PPTitleButton buttonWithDelegate:postViewController];
    [button setTitle:[components componentsJoinedByString:@"+"] imageName:nil];
    
    postViewController.navigationItem.titleView = button;
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

        for (NSDictionary *post in self.posts) {
            PostMetadata *metadata = [self metadataForPost:post];
            [newHeights addObject:metadata.height];

            PostMetadata *compressedMetadata = [self compressedMetadataForPost:post];
            [newCompressedHeights addObject:compressedMetadata.height];
        }

        self.heights = newHeights;
        self.compressedHeights = newCompressedHeights;
        
        if (success) {
            success();
        }
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

- (NSAttributedString *)stringByTrimmingTrailingPunctuationFromAttributedString:(NSAttributedString *)string offset:(NSInteger *)offset {
    NSRange punctuationRange = [string.string rangeOfCharacterFromSet:[NSCharacterSet punctuationCharacterSet] options:NSBackwardsSearch];
    if (punctuationRange.location != NSNotFound && (punctuationRange.location + punctuationRange.length) >= string.length) {
        *offset += punctuationRange.location - string.length;
        return [NSAttributedString attributedStringWithAttributedString:[string attributedSubstringFromRange:NSMakeRange(0, punctuationRange.location)]];
    }
    
    return string;
}

@end
