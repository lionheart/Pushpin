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
#import "PPPinboardMetadataCache.h"
#import "PPConstants.h"

#import "NSAttributedString+Attributes.h"
#import "NSString+URLEncoding2.h"

#import <ASPinboard/ASPinboard.h>
#import <FMDB/FMDatabase.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

@interface PinboardFeedDataSource ()

@property (nonatomic, strong) PPPinboardMetadataCache *cache;

@end

@implementation PinboardFeedDataSource

- (id)initWithComponents:(NSArray *)components {
    self = [super init];
    if (self) {
        // Keys are hash:meta pairs
        self.cache = [PPPinboardMetadataCache sharedCache];

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
        // Keys are hash:meta pairs
        self.cache = [PPPinboardMetadataCache sharedCache];

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
    
    if ([AppDelegate sharedDelegate].readLater != PPReadLaterNone) {
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
                                           PostMetadata *metadata = [self.cache cachedMetadataForPost:post compressed:NO];
                                           if (!metadata) {
                                               metadata = [self metadataForPost:post];
                                               [self.cache cacheMetadata:metadata forPost:post compressed:NO];
                                           }
                                           
                                           [newHeights addObject:metadata.height];
                                           [newStrings addObject:metadata.string];
                                           [newLinks addObject:metadata.links];
                                           [newBadges addObject:metadata.badges];
                                           
                                           PostMetadata *compressedMetadata = [self.cache cachedMetadataForPost:post compressed:YES];
                                           if (!compressedMetadata) {
                                               compressedMetadata = [self compressedMetadataForPost:post];
                                               [self.cache cacheMetadata:compressedMetadata forPost:post compressed:YES];
                                           }
                                           
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
    return [PostMetadata metadataForPost:post compressed:compressed tagsWithFrequency:nil];
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

- (PPNavigationController *)addViewControllerForPostAtIndex:(NSInteger)index {
    return [AddBookmarkViewController addBookmarkViewControllerWithBookmark:self.posts[index] update:@(NO) callback:nil];
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
    return postViewController;
}

- (BOOL)supportsTagDrilldown {
    return NO;
}

- (void)addDataSource:(void (^)())callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *componentString = [self.components componentsJoinedByString:@" "];

        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        [db executeUpdate:@"INSERT INTO feeds (components) VALUES (?)" withArgumentsInArray:@[componentString]];
        [db close];
        
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        [store synchronize];
        
        NSMutableArray *iCloudFeeds = [NSMutableArray arrayWithArray:[store arrayForKey:kSavedFeedsKey]];
        if (![iCloudFeeds containsObject:componentString]) {
            [iCloudFeeds addObject:componentString];
            [store setArray:iCloudFeeds forKey:kSavedFeedsKey];
        }
        callback();
    });
}

- (void)removeDataSource:(void (^)())callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *componentString = [self.components componentsJoinedByString:@" "];
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        [db executeUpdate:@"DELETE FROM feeds WHERE components=?" withArgumentsInArray:@[componentString]];
        [db close];

        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        [store synchronize];

        NSMutableArray *iCloudFeeds = [NSMutableArray arrayWithArray:[store arrayForKey:kSavedFeedsKey]];
        if ([iCloudFeeds containsObject:componentString]) {
            [iCloudFeeds removeObject:componentString];
            [store setArray:iCloudFeeds forKey:kSavedFeedsKey];
        }

        callback();
    });
}

- (void)resetHeightsWithSuccess:(void (^)())success {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *newHeights = [NSMutableArray array];
        NSMutableArray *newCompressedHeights = [NSMutableArray array];

        for (NSDictionary *post in self.posts) {
            PostMetadata *metadata = [self.cache cachedMetadataForPost:post compressed:NO];
            if (!metadata) {
                metadata = [self metadataForPost:post];
                [self.cache cacheMetadata:metadata forPost:post compressed:NO];
            }
            
            [newHeights addObject:metadata.height];
            
            PostMetadata *compressedMetadata = [self.cache cachedMetadataForPost:post compressed:YES];
            if (!compressedMetadata) {
                compressedMetadata = [self compressedMetadataForPost:post];
                [self.cache cacheMetadata:compressedMetadata forPost:post compressed:YES];
            }
            
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

- (UIColor *)barTintColor {
    switch (self.components.count) {
        case 1:
            if ([self.components[0] isEqualToString:@"popular?count=100"]) {
                return HEX(0xFF9409FF);
            }
            
        case 2:
            if ([self.components[0] isEqualToString:@"popular"]) {
                if ([self.components[1] isEqualToString:@"wikipedia"]) {
                    return HEX(0x2CA881FF);
                }
                
                if ([self.components[1] isEqualToString:@"fandom"]) {
                    return HEX(0xE062D6FF);
                }
                
                if ([self.components[1] isEqualToString:@"japanese"]) {
                    return HEX(0xFF5353FF);
                }
            }
            
        case 3:
            // Network Feed
            return HEX(0x30A1C1FF);

        default:
            return HEX(0x30A1C1FF);
    }
}

- (NSString *)title {
    switch (self.components.count) {
        case 1:
            if ([self.components[0] isEqualToString:@"popular?count=100"]) {
                return NSLocalizedString(@"Popular", nil);
            }
            break;

        case 2:
            if ([self.components[0] isEqualToString:@"popular"]) {
                if ([self.components[1] isEqualToString:@"wikipedia"]) {
                    return @"Wikipedia";
                }
                
                if ([self.components[1] isEqualToString:@"fandom"]) {
                    return NSLocalizedString(@"Fandom", nil);
                }
                
                if ([self.components[1] isEqualToString:@"japanese"]) {
                    return @"日本語";
                }
            }
            break;

        case 3:
            // Network Feed?
            if ([self.components[2] isEqualToString:@"network"]) {
                return NSLocalizedString(@"Network", nil);
            }
            break;
    }

    return [self.components componentsJoinedByString:@"+"];
}

- (UIView *)titleView {
    return [self titleViewWithDelegate:nil];
}

- (UIView *)titleViewWithDelegate:(id<PPTitleButtonDelegate>)delegate {
    PPTitleButton *titleButton = [PPTitleButton buttonWithDelegate:delegate];
    BOOL titleViewSet = NO;
    switch (self.components.count) {
        case 1:
            if ([self.components[0] isEqualToString:@"popular?count=100"]) {
                titleViewSet = YES;
                [titleButton setTitle:NSLocalizedString(@"Popular", nil) imageName:@"navigation-popular"];
            }
            break;

        case 2:
            if ([self.components[0] isEqualToString:@"popular"]) {
                if ([self.components[1] isEqualToString:@"wikipedia"]) {
                    titleViewSet = YES;
                    [titleButton setTitle:NSLocalizedString(@"Wikipedia", nil) imageName:@"navigation-wikipedia"];
                }
                
                if ([self.components[1] isEqualToString:@"fandom"]) {
                    titleViewSet = YES;
                    [titleButton setTitle:NSLocalizedString(@"Fandom", nil) imageName:@"navigation-fandom"];
                }
                
                if ([self.components[1] isEqualToString:@"japanese"]) {
                    titleViewSet = YES;
                    [titleButton setTitle:NSLocalizedString(@"日本語", nil) imageName:@"navigation-japanese"];
                }
            }
            break;

        case 3:
            // Network Feed?
            if ([self.components[2] isEqualToString:@"network"]) {
                titleViewSet = YES;
                [titleButton setTitle:NSLocalizedString(@"Network", nil) imageName:@"navigation-network"];
            }
            break;
    }
    
    if (!titleViewSet) {
        [titleButton setTitle:[self.components componentsJoinedByString:@"+"] imageName:nil];
    }

    return titleButton;
}

@end
