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

@implementation PinboardFeedDataSource

- (id)initWithEndpoint:(NSString *)endpoint {
    self = [super init];
    if (self) {
        self.endpoint = endpoint;
        self.posts = [NSMutableArray array];
    }
    return self;
}

+ (PinboardFeedDataSource *)dataSourceWithEndpoint:(NSString *)endpoint {
    return [[PinboardFeedDataSource alloc] initWithEndpoint:endpoint];
}

- (void)setEndpoint:(NSString *)endpoint {
    _endpoint = endpoint;
    self.endpointURL = [NSURL URLWithString:endpoint];
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

- (BOOL)isPostAtIndexStarred:(NSInteger)index {
    return NO;
}

- (BOOL)isPostAtIndexPrivate:(NSInteger)index {
    return NO;
}

- (BOOL)isPostAtIndexRead:(NSInteger)index {
    return NO;
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

- (void)updatePostsFromDatabaseWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure {
    [self updatePostsWithSuccess:success failure:failure];
}

- (void)updatePostsWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure {
    NSMutableArray *indexPathsToAdd = [NSMutableArray array];
    NSMutableArray *indexPathsToRemove = [NSMutableArray array];
    NSMutableArray *indexPathsToReload = [NSMutableArray array];

    NSMutableArray *newPosts = [NSMutableArray array];
    NSMutableArray *newURLs = [NSMutableArray array];
    NSMutableArray *oldPosts = [self.posts copy];
    NSMutableArray *oldURLs = [NSMutableArray array];
    for (NSDictionary *post in self.posts) {
        [oldURLs addObject:post[@"url"]];
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:self.endpointURL];
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    [delegate setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [delegate setNetworkActivityIndicatorVisible:NO];

                               if (!error) {
                                   NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                   NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                   [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                                   [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

                                   NSInteger index = 0;
                                   for (NSDictionary *element in payload) {
                                       NSMutableDictionary *post = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                        @"title": element[@"d"],
                                                                        @"description": element[@"n"],
                                                                        @"url": element[@"u"],
                                                                        @"tags": [element[@"t"] componentsJoinedByString:@" "],
                                                                        @"created_at": [dateFormatter dateFromString:element[@"dt"]]
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

                                   if (success != nil) {
                                       success(indexPathsToAdd, indexPathsToReload, indexPathsToRemove);
                                   }
                               }
                           }];
}

@end
