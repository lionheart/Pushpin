//
//  PinboardFeedDataSource.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/22/13.
//
//

@import FMDB;

#import "PPPinboardFeedDataSource.h"
#import "PPAppDelegate.h"
#import "PPAddBookmarkViewController.h"
#import "PPBadgeView.h"
#import "PPTheme.h"
#import "PostMetadata.h"
#import "PPTitleButton.h"
#import "PPPinboardMetadataCache.h"
#import "PPConstants.h"
#import "PPSettings.h"

#import "NSAttributedString+Attributes.h"
#import "NSString+URLEncoding2.h"
#import "PPUtilities.h"
#import "NSString+LHSAdditions.h"

#import <ASPinboard/ASPinboard.h>
#import <FMDB/FMDatabase.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <MWFeedParser/NSString+HTML.h>

@interface PPPinboardFeedDataSource ()

@property (nonatomic, strong) PPPinboardMetadataCache *cache;

// Need to remove or condense with the other data formatters below
- (NSDateFormatter *)feedDateFormatter;

@end

@implementation PPPinboardFeedDataSource

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

+ (PPPinboardFeedDataSource *)dataSourceWithComponents:(NSArray *)components {
    return [[PPPinboardFeedDataSource alloc] initWithComponents:components];
}

#pragma mark - Delegate Methods

- (PPPostActionType)actionsForPost:(NSDictionary *)post {
    NSInteger actions = PPPostActionCopyToMine | PPPostActionCopyURL | PPPostActionShare;
    return actions;
}

- (NSInteger)numberOfPosts {
    return self.posts.count;
}

- (NSInteger)indexForPost:(NSDictionary *)post {
#warning O(N^2)
    return [self.posts indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj[@"url"] isEqualToString:post[@"url"]];
    }];
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

- (PostMetadata *)metadataForPostAtIndex:(NSInteger)index {
    return self.metadata[index];
}

- (PostMetadata *)compressedMetadataForPostAtIndex:(NSInteger)index {
    return self.compressedMetadata[index];
}

- (void)syncBookmarksWithCompletion:(void (^)(BOOL, NSError *))completion
                           progress:(void (^)(NSInteger, NSInteger))progress
                            options:(NSDictionary *)options {
    [self syncBookmarksWithCompletion:completion progress:progress];
}

- (void)syncBookmarksWithCompletion:(void (^)(BOOL updated, NSError *))completion
                           progress:(void (^)(NSInteger, NSInteger))progress {
    completion(YES, nil);
}

- (void)reloadBookmarksWithCompletion:(void (^)(NSError *))completion
                               cancel:(BOOL (^)())cancel
                                width:(CGFloat)width {
    dispatch_async(PPPinboardFeedReloadQueue(), ^{
        
        if (cancel && cancel()) {
            completion([NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
            return;
        }

        [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];

        NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];;
                                                    
                                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                        if (!error) {
                                                            NSDictionary *payload = [NSJSONSerialization
                                                                                     JSONObjectWithData:data
                                                                                     options:NSJSONReadingMutableContainers
                                                                                     error:nil];
                                                            
                                                            NSMutableDictionary *oldURLsToIndexPaths = [NSMutableDictionary dictionary];
                                                            NSMutableDictionary *newURLsToIndexPaths = [NSMutableDictionary dictionary];
                                                            NSInteger row = 0;
                                                            
                                                            NSMutableArray *newPosts = [NSMutableArray array];
                                                            NSMutableArray *oldURLs = [NSMutableArray array];
                                                            NSMutableArray *oldPosts = [self.posts copy];
                                                            
                                                            for (NSDictionary *post in oldPosts) {
                                                                [oldURLs addObject:post[@"url"]];
                                                                oldURLsToIndexPaths[post[@"url"]] = [NSIndexPath indexPathForRow:row inSection:0];
                                                                row++;
                                                            }
                                                            
                                                            if (cancel && cancel()) {
                                                                completion([NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                                                                return;
                                                            }
                                                            
                                                            NSDate *date;
                                                            
                                                            row = 0;
                                                            for (NSDictionary *element in payload) {
                                                                NSMutableArray *tags = [NSMutableArray array];
                                                                [tags addObject:[NSString stringWithFormat:@"via:%@", element[@"a"]]];
                                                                for (NSString *tag in element[@"t"]) {
                                                                    if (![tag isEqual:[NSNull null]] && ![tag isEqualToString:@""]) {
                                                                        [tags addObject:[tag stringByDecodingHTMLEntities]];
                                                                    }
                                                                }
                                                                
                                                                date = [[self feedDateFormatter] dateFromString:element[@"dt"]];
                                                                if (!date) {
                                                                    // https://rink.hockeyapp.net/manage/apps/33685/app_versions/4/crash_reasons/4734816
                                                                    date = [NSDate date];
                                                                }
                                                                
                                                                // There is a bug where spaces are not encoded as %20 in feeds when the space occurs after a hash. In this case, we encode it ourselves first.
                                                                NSString *url = [element[@"u"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                                                NSMutableDictionary *post = [@{
                                                                                               @"title": [PPUtilities stringByTrimmingWhitespace:element[@"d"]],
                                                                                               @"description": [PPUtilities stringByTrimmingWhitespace:element[@"n"]],
                                                                                               @"url": url,
                                                                                               @"tags": [tags componentsJoinedByString:@" "],
                                                                                               @"created_at": date
                                                                                           } mutableCopy];
                                                                
                                                                [newPosts addObject:post];
                                                                newURLsToIndexPaths[url] = [NSIndexPath indexPathForRow:row inSection:0];
                                                                row++;
                                                            }
                                                            
                                                            
                                                            if (cancel && cancel()) {
                                                                completion([NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                                                                return;
                                                            }
                                                            
                                                            [PPUtilities generateDiffForPrevious:oldPosts
                                                                                         updated:newPosts
                                                                                            hash:^NSString *(id obj) {
                                                                                                NSString *date = [[self feedDateFormatter] stringFromDate:obj[@"created_at"]];
                                                                                                return [NSString stringWithFormat:@"%@ %@", obj[@"url"], date];
                                                                                            }
                                                                                      completion:^(NSSet *inserted, NSSet *deleted) {
                                                                                          NSMutableArray *indexPathsToInsert = [NSMutableArray array];
                                                                                          NSMutableArray *indexPathsToReload = [NSMutableArray array];
                                                                                          NSMutableArray *indexPathsToDelete = [NSMutableArray array];
                                                                                          
                                                                                          for (NSString *urlDate in deleted) {
                                                                                              NSString *url = [[urlDate componentsSeparatedByString:@" "] firstObject];
                                                                                              [indexPathsToDelete addObject:oldURLsToIndexPaths[url]];
                                                                                          }
                                                                                          
                                                                                          for (NSString *urlDate in inserted) {
                                                                                              NSString *url = [[urlDate componentsSeparatedByString:@" "] firstObject];
                                                                                              [indexPathsToInsert addObject:newURLsToIndexPaths[url]];
                                                                                          }
                                                                                          
                                                                                          NSMutableArray *newMetadata = [NSMutableArray array];
                                                                                          NSMutableArray *newCompressedMetadata = [NSMutableArray array];
                                                                                          
                                                                                          for (NSDictionary *post in newPosts) {
                                                                                              PostMetadata *metadata = [PostMetadata metadataForPost:post compressed:NO width:width tagsWithFrequency:nil];
                                                                                              [newMetadata addObject:metadata];
                                                                                              
                                                                                              PostMetadata *compressedMetadata = [PostMetadata metadataForPost:post compressed:YES width:width tagsWithFrequency:nil];
                                                                                              [newCompressedMetadata addObject:compressedMetadata];
                                                                                          }
                                                                                          
                                                                                          if (cancel && cancel()) {
                                                                                              completion([NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]);
                                                                                              return;
                                                                                          }
                                                                                          else {
                                                                                              self.posts = newPosts;
                                                                                              self.metadata = newMetadata;
                                                                                              self.compressedMetadata = newCompressedMetadata;
                                                                                              
                                                                                              completion(nil);
                                                                                          }
                                                                                      }];
                                                        }
                                                    });
                                                }];
        [task resume];
    });
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
    
    PPSettings *settings = [PPSettings sharedSettings];
    // If it's our username, we need to use the feed token to get any private tags
    if ([escapedComponents[0] isEqualToString:[NSString stringWithFormat:@"u:%@", settings.username]]) {
        urlString = [NSString stringWithFormat:@"https://feeds.pinboard.in/json/secret:%@/%@?count=%ld", settings.feedToken, [escapedComponents componentsJoinedByString:@"/"], (long)self.count];
    }
    else {
        urlString = [NSString stringWithFormat:@"https://feeds.pinboard.in/json/%@?count=%ld", [escapedComponents componentsJoinedByString:@"/"], (long)self.count];
    }
    
    return [NSURL URLWithString:urlString];
}

- (CGFloat)compressedHeightForPostAtIndex:(NSInteger)index {
    PostMetadata *metadata = self.compressedMetadata[index];
    return [metadata.height floatValue];
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

- (NSArray *)badgesForPostAtIndex:(NSInteger)index {
    PostMetadata *metadata = self.metadata[index];
    return metadata.badges;
}

- (PPNavigationController *)addViewControllerForPostAtIndex:(NSInteger)index {
    return [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:self.posts[index] update:@(NO) callback:nil];
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
                PPGenericPostViewController *postViewController = [PPPinboardFeedDataSource postViewControllerWithComponents:components];
                callback(postViewController);
            });
        }
    });
}

+ (PPGenericPostViewController *)postViewControllerWithComponents:(NSArray *)components {
    PPGenericPostViewController *postViewController = [[PPGenericPostViewController alloc] init];
    PPPinboardFeedDataSource *dataSource = [[PPPinboardFeedDataSource alloc] initWithComponents:components];
    
    [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:@"SELECT COUNT(*) FROM feeds WHERE components=?" withArgumentsInArray:@[[components componentsJoinedByString:@" "]]];
        [result next];

        if ([result intForColumnIndex:0] > 0) {
            postViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStylePlain target:postViewController action:@selector(removeBarButtonTouchUpside:)];
        }
        else {
            postViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:postViewController action:@selector(addBarButtonTouchUpside:)];
        }

        [result close];
    }];

    postViewController.postDataSource = dataSource;
    return postViewController;
}

- (BOOL)supportsTagDrilldown {
    return NO;
}

- (void)addDataSource:(void (^)())callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *componentString = [self.components componentsJoinedByString:@" "];

        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"INSERT INTO feeds (components) VALUES (?)" withArgumentsInArray:@[componentString]];
        }];
        
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

        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"DELETE FROM feeds WHERE components=?" withArgumentsInArray:@[componentString]];
        }];

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
            else if ([self.components[0] isEqualToString:@"recent"]) {
                return HEX(0x2AC5FFFF);
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
            if ([self.components containsObject:@"network"]) {
            // Network Feed
                return HEX(0x30A1C1FF);
            }

        default:
            return HEX(0xD5A470FF);
    }
}

- (NSString *)title {
    switch (self.components.count) {
        case 1:
            if ([self.components[0] isEqualToString:@"popular?count=100"]) {
                return NSLocalizedString(@"Popular", nil);
            }
            else if ([self.components[0] isEqualToString:@"recent"]) {
                return NSLocalizedString(@"Recent", nil);
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
            else if ([self.components[0] isEqualToString:@"recent"]) {
                titleViewSet = YES;
                [titleButton setTitle:NSLocalizedString(@"Recent", nil) imageName:@"navigation-recent"];
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

- (BOOL)searchSupported {
    return NO;
}

- (NSDateFormatter *)feedDateFormatter {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    });
    return dateFormatter;
}

@end
