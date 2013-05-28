//
//  PinboardNotesDataSource.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

#import "PinboardNotesDataSource.h"
#import "ASPinboard/ASPinboard.h"
#import "NSAttributedString+Attributes.h"

@implementation PinboardNotesDataSource

- (id)init {
    self = [super init];
    if (self) {
        self.notes = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Delegate Methods

- (NSArray *)actionsForPost:(NSDictionary *)post {
    return @[@(PPPostActionCopyURL)];
}

- (NSInteger)numberOfPosts {
    return self.notes.count;
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

- (BOOL)isPostAtIndexRead:(NSInteger)index {
    return NO;
}

- (NSString *)titleForPostAtIndex:(NSInteger)index {
    return [self.notes[index][@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (NSString *)descriptionForPostAtIndex:(NSInteger)index {
    return @"";
}

- (NSString *)tagsForPostAtIndex:(NSInteger)index {
    return @"";
}

- (NSString *)urlForPostAtIndex:(NSInteger)index {
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    return [NSString stringWithFormat:@"https://notes.pinboard.in/u:%@/%@", delegate.username, self.notes[index][@"id"]];
}

- (NSDictionary *)postAtIndex:(NSInteger)index {
    return self.notes[index];
}

- (NSDate *)dateForPostAtIndex:(NSInteger)index {
    return self.notes[index][@"updated_at"];
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
    [self updatePostsWithSuccess:success failure:failure options:nil];
}

- (UIViewController *)viewControllerForPostAtIndex:(NSInteger)index {
    UIViewController *controller = [[UIViewController alloc] init];
    UIWebView *webView = [[UIWebView alloc] init];
    controller.title = [self titleForPostAtIndex:index];
    webView.frame = controller.view.frame;
    controller.view = webView;
    
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    
    [delegate setNetworkActivityIndicatorVisible:YES];
    [pinboard noteWithId:self.notes[index][@"id"]
                 success:^(NSString *title, NSString *text) {
                     [delegate setNetworkActivityIndicatorVisible:NO];
                     [webView loadHTMLString:[NSString stringWithFormat:@"<body><div style='white-space:pre-wrap;font-family:Helvetica;font-size:12px;'>%@</div></body>", text]
                                     baseURL:nil];
    }];
    return controller;
}

- (void)updatePostsWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure options:(NSDictionary *)options {
    NSMutableArray *indexPathsToAdd = [NSMutableArray array];
    NSMutableArray *indexPathsToRemove = [NSMutableArray array];
    NSMutableArray *indexPathsToReload = [NSMutableArray array];
    
    NSMutableArray *newNotesUnsorted = [NSMutableArray array];
    NSMutableArray *newIDs = [NSMutableArray array];
    NSMutableArray *oldIDs = [NSMutableArray array];
    for (NSDictionary *post in self.notes) {
        [oldIDs addObject:post[@"id"]];
    }

    AppDelegate *delegate = [AppDelegate sharedDelegate];
    [delegate setNetworkActivityIndicatorVisible:YES];
    [[ASPinboard sharedInstance] notesWithSuccess:^(NSArray *notes) {
        [delegate setNetworkActivityIndicatorVisible:NO];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

        NSInteger index = 0;
        for (NSDictionary *note in notes) {
            NSString *noteID = note[@"id"];
            [newNotesUnsorted addObject:@{
                @"updated_at": [dateFormatter dateFromString:note[@"updated_at"]],
                @"title": note[@"title"],
                @"id": noteID,
             }];
        }

        NSArray *newNotes = [newNotesUnsorted sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj2[@"updated_at"] compare:obj1[@"updated_at"]];
        }];

        for (NSDictionary *note in newNotes) {
            [newIDs addObject:note[@"id"]];

            if (![oldIDs containsObject:note[@"id"]]) {
                [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            }
            else {
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            }

            index++;
        }
        
        NSInteger i;
        for (i=0; i<oldIDs.count; i++) {
            if (![newIDs containsObject:oldIDs[i]]) {
                [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        
        self.notes = [newNotes copy];
        
        if (success) {
            success(indexPathsToAdd, indexPathsToReload, indexPathsToRemove);
        }
    }];
}

- (NSAttributedString *)attributedStringForPostAtIndex:(NSInteger)index {
    UIFont *titleFont = [UIFont fontWithName:@"Avenir-Heavy" size:16.f];
    UIFont *dateFont = [UIFont fontWithName:@"Avenir-Medium" size:10];
    
    NSString *title = [self titleForPostAtIndex:index];
    NSString *dateString = [self formattedDateForPostAtIndex:index];
    
    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", title];
    NSRange titleRange = [self rangeForTitleForPostAtIndex:index];
    
    [content appendFormat:@"\n%@", dateString];
    NSRange dateRange = NSMakeRange(content.length - dateString.length, dateString.length);
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
    [attributedString setFont:titleFont range:titleRange];
    [attributedString setTextColor:HEX(0x33353Bff)];
    [attributedString setTextColor:HEX(0x353840ff) range:titleRange];
    [attributedString setTextColor:HEX(0xA5A9B2ff) range:dateRange];
    [attributedString setFont:dateFont range:dateRange];
    [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
    return attributedString;
}

- (NSRange)rangeForTitleForPostAtIndex:(NSInteger)index {
    return NSMakeRange(0, [[self titleForPostAtIndex:index] length]);
}

- (NSRange)rangeForDescriptionForPostAtIndex:(NSInteger)index {
    return NSMakeRange(NSNotFound, 0);
}

- (NSRange)rangeForTagsForPostAtIndex:(NSInteger)index {
    return NSMakeRange(NSNotFound, 0);
}

- (NSArray *)linksForPostAtIndex:(NSInteger)index {
    return @[];
}

- (BOOL)supportsSearch {
    return NO;
}

- (BOOL)supportsTagDrilldown {
    return NO;
}

@end
