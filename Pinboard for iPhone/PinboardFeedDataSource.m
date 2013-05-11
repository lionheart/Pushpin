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

- (NSAttributedString *)attributedStringForPostAtIndex:(NSInteger)index {
    UIFont *titleFont = [UIFont fontWithName:@"Avenir-Heavy" size:16.f];
    UIFont *descriptionFont = [UIFont fontWithName:@"Avenir-Book" size:14.f];
    UIFont *tagsFont = [UIFont fontWithName:@"Avenir-Medium" size:12];
    UIFont *dateFont = [UIFont fontWithName:@"Avenir-Medium" size:10];
    
    NSString *title = [self titleForPostAtIndex:index];
    NSString *description = [self descriptionForPostAtIndex:index];
    NSString *tags = [self tagsForPostAtIndex:index];
    NSString *dateString = [self formattedDateForPostAtIndex:index];
    BOOL isRead = [self isPostAtIndexRead:index];
    
    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", title];
    NSRange titleRange = [self rangeForTitleForPostAtIndex:index];
    
    NSRange descriptionRange = [self rangeForDescriptionForPostAtIndex:index];
    if (descriptionRange.location != NSNotFound) {
        [content appendString:[NSString stringWithFormat:@"\n%@", description]];
    }
    
    NSRange tagRange = [self rangeForTagsForPostAtIndex:index];
    BOOL hasTags = tagRange.location != NSNotFound;
    
    if (hasTags) {
        [content appendFormat:@"\n%@", tags];
    }
    
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
    
    if (hasTags) {
        [attributedString setTextColor:HEX(0xA5A9B2ff) range:tagRange];
        [attributedString setFont:tagsFont range:tagRange];
    }
    
    [attributedString setTextColor:HEX(0xA5A9B2ff) range:dateRange];
    [attributedString setFont:dateFont range:dateRange];
    [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
    return attributedString;
}

- (NSRange)rangeForTitleForPostAtIndex:(NSInteger)index {
    return NSMakeRange(0, [[self titleForPostAtIndex:index] length]);
}

- (NSRange)rangeForDescriptionForPostAtIndex:(NSInteger)index {
    NSString *description = [self descriptionForPostAtIndex:index];
    if ([description isEqualToString:@""]) {
        return NSMakeRange(NSNotFound, 0);
    }
    else {
        NSRange titleRange = [self rangeForTitleForPostAtIndex:index];
        return NSMakeRange(titleRange.location + titleRange.length + 1, [description length]);
    }
}

- (NSRange)rangeForTagsForPostAtIndex:(NSInteger)index {
    NSString *tags = [self tagsForPostAtIndex:index];
    if ([tags isEqualToString:@""]) {
        return NSMakeRange(NSNotFound, 0);
    }
    else {
        NSRange titleRange = [self rangeForTitleForPostAtIndex:index];
        NSRange descriptionRange = [self rangeForDescriptionForPostAtIndex:index];
        NSInteger offset = 1;
        if (descriptionRange.location != NSNotFound) {
            offset++;
        }
        return NSMakeRange(titleRange.location + titleRange.length + descriptionRange.length + offset, [tags length]);
    }
}

- (NSArray *)linksForPostAtIndex:(NSInteger)index {
    NSMutableArray *links = [NSMutableArray array];
    NSInteger location = [self rangeForTagsForPostAtIndex:index].location;
    NSString *tags = [self.posts[index][@"tags"] stringByReplacingOccurrencesOfString:@" " withString:@" * "];
    for (NSString *tag in [tags componentsSeparatedByString:@" * "]) {
        NSRange range = [tags rangeOfString:tag];
        [links addObject:@{@"url": [NSURL URLWithString:[tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]], @"location": @(location+range.location), @"length": @(range.length)}];
    }
    return links;
}

@end
