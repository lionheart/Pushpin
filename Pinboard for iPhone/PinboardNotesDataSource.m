//
//  PinboardNotesDataSource.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

#import "PinboardNotesDataSource.h"
#import "PPTheme.h"

#import "NSAttributedString+Attributes.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <ASPinboard/ASPinboard.h>

@implementation PinboardNotesDataSource

- (id)init {
    self = [super init];
    if (self) {
        self.notes = [NSArray array];
        self.strings = [NSArray array];
        self.heights = [NSArray array];
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        self.locale = [NSLocale currentLocale];
        [self.dateFormatter setLocale:self.locale];
        [self.dateFormatter setDoesRelativeDateFormatting:YES];
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

- (NSString *)urlForPostAtIndex:(NSInteger)index {
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    return [NSString stringWithFormat:@"https://notes.pinboard.in/u:%@/%@", delegate.username, self.notes[index][@"id"]];
}

- (NSDictionary *)postAtIndex:(NSInteger)index {
    return self.notes[index];
}

- (void)updatePostsFromDatabaseWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure {
    [self updatePostsWithSuccess:success failure:failure options:nil];
}

- (UIViewController *)viewControllerForPostAtIndex:(NSInteger)index {
    UIViewController *controller = [[UIViewController alloc] init];
    UIWebView *webView = [[UIWebView alloc] init];
    controller.title = [self.notes[index][@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
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
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

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
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:[oldIDs indexOfObject:note[@"id"]] inSection:0]];
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

        NSMutableArray *newStrings = [NSMutableArray array];
        NSMutableArray *newHeights = [NSMutableArray array];
        for (NSDictionary *note in newNotes) {
            [self metadataForNote:note callback:^(NSAttributedString *string, NSNumber *height) {
                [newHeights addObject:height];
                [newStrings addObject:string];
            }];
        }
        
        self.strings = newStrings;
        self.heights = newHeights;
        
        if (success) {
            success(indexPathsToAdd, indexPathsToReload, indexPathsToRemove);
        }
    }];
}

- (NSArray *)linksForPostAtIndex:(NSInteger)index {
    return @[];
}

- (CGFloat)compressedHeightForPostAtIndex:(NSInteger)index {
    return [self heightForPostAtIndex:index];
}

- (CGFloat)heightForPostAtIndex:(NSInteger)index {
    return [self.heights[index] floatValue];
}

- (NSAttributedString *)attributedStringForPostAtIndex:(NSInteger)index {
    return self.strings[index];
}

- (BOOL)supportsTagDrilldown {
    return NO;
}

- (void)metadataForNote:(NSDictionary *)note callback:(void (^)(NSAttributedString *, NSNumber *))callback {
    UIFont *titleFont = [UIFont fontWithName:[PPTheme boldFontName] size:16.f];
    UIFont *dateFont = [UIFont fontWithName:[PPTheme fontName] size:10];
    
    NSString *title = [note[@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSString *dateString = [self.dateFormatter stringFromDate:note[@"updated_at"]];
    
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
    
    NSNumber *height = @([attributedString sizeConstrainedToSize:CGSizeMake([UIApplication currentSize].width - 20, CGFLOAT_MAX)].height);
    callback(attributedString, height);
}

@end
