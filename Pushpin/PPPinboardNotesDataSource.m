//
//  PinboardNotesDataSource.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

#import "PPPinboardNotesDataSource.h"
#import "PPTheme.h"
#import "PPConstants.h"
#import "PostMetadata.h"
#import "PPLicenseViewController.h"

#import "NSAttributedString+Attributes.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <ASPinboard/ASPinboard.h>

@interface PPPinboardNotesDataSource ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSLocale *locale;

@end

@implementation PPPinboardNotesDataSource

- (id)init {
    self = [super init];
    if (self) {
        self.posts = [NSMutableArray array];
        self.metadata = [NSMutableArray array];
        
        self.locale = [NSLocale currentLocale];
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setLocale:self.locale];
        [self.dateFormatter setDoesRelativeDateFormatting:YES];
    }
    return self;
}

#pragma mark - Delegate Methods

- (PPPostActionType)actionsForPost:(NSDictionary *)post {
    return PPPostActionCopyURL;
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

- (NSString *)urlForPostAtIndex:(NSInteger)index {
    PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
    return [NSString stringWithFormat:@"https://notes.pinboard.in/u:%@/%@", delegate.username, self.posts[index][@"id"]];
}

- (NSDictionary *)postAtIndex:(NSInteger)index {
    return self.posts[index];
}

- (UIViewController *)viewControllerForPostAtIndex:(NSInteger)index {
    __block PPLicenseViewController *license = [[PPLicenseViewController alloc] init];
    
    PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    
    [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];;
    [pinboard noteWithId:self.posts[index][@"id"]
                 success:^(NSString *title, NSString *text) {
                     license.text = text;
                     [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];;
    }];

    license.title = self.posts[index][@"title"];
    return license;
}

- (void)reloadBookmarksWithCompletion:(void (^)(NSArray *, NSArray *, NSArray *, NSError *))completion
                               cancel:(BOOL (^)())cancel
                                width:(CGFloat)width {
    NSMutableArray *indexPathsToAdd = [NSMutableArray array];
    NSMutableArray *indexPathsToRemove = [NSMutableArray array];
    NSMutableArray *indexPathsToReload = [NSMutableArray array];
    
    NSMutableArray *newNotesUnsorted = [NSMutableArray array];
    NSMutableArray *newIDs = [NSMutableArray array];
    NSMutableArray *oldIDs = [NSMutableArray array];
    for (NSDictionary *post in self.posts) {
        [oldIDs addObject:post[@"id"]];
    }
    
    PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
    [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];;
    [[ASPinboard sharedInstance] notesWithSuccess:^(NSArray *notes) {
        [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        NSInteger index = 0;
        for (NSDictionary *note in notes) {
            NSString *noteID = note[@"id"];
            NSDate *date = [dateFormatter dateFromString:note[@"updated_at"]];
            [newNotesUnsorted addObject:@{
                                          @"updated_at": date,
                                          @"description": [self.dateFormatter stringFromDate:date],
                                          @"title": note[@"title"],
                                          @"id": noteID,
                                          }];
        }
        
        NSArray *newNotes = [newNotesUnsorted sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj2[@"updated_at"] compare:obj1[@"updated_at"]];
        }];
        
        [self.metadata removeAllObjects];
        for (NSDictionary *note in newNotes) {
            [newIDs addObject:note[@"id"]];
            
            if (![oldIDs containsObject:note[@"id"]]) {
                [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            }
            else {
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:[oldIDs indexOfObject:note[@"id"]] inSection:0]];
            }
            
            PostMetadata *metadata = [PostMetadata metadataForPost:note compressed:NO width:width tagsWithFrequency:@{} cache:NO];
            [self.metadata addObject:metadata];
            index++;
        }
        
        NSInteger i;
        for (i=0; i<oldIDs.count; i++) {
            if (![newIDs containsObject:oldIDs[i]]) {
                [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }

        self.posts = [newNotes copy];
        
        completion(indexPathsToAdd, indexPathsToReload, indexPathsToRemove, nil);
    }];
}

- (void)syncBookmarksWithCompletion:(void (^)(BOOL updated, NSError *))completion
                           progress:(void (^)(NSInteger, NSInteger))progress {
    completion(YES, nil);
}

- (NSArray *)badgesForPostAtIndex:(NSInteger)index {
    return @[];
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

- (CGFloat)compressedHeightForPostAtIndex:(NSInteger)index {
    PostMetadata *metadata = self.metadata[index];
    return [metadata.height floatValue];
}

- (BOOL)supportsTagDrilldown {
    return NO;
}

- (BOOL)searchSupported {
    return NO;
}

@end
