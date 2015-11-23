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
#import "PPPlainTextViewController.h"
#import "PPNoteViewController.h"
#import "PPSettings.h"

#import "NSAttributedString+Attributes.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <Fabric/Fabric.h>
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
    PPSettings *settings = [PPSettings sharedSettings];
    return [NSString stringWithFormat:@"https://notes.pinboard.in/u:%@/%@", settings.username, self.posts[index][@"id"]];
}

- (NSDictionary *)postAtIndex:(NSInteger)index {
    return self.posts[index];
}

- (UIViewController *)viewControllerForPostAtIndex:(NSInteger)index {
    PPNoteViewController *noteViewController = [[PPNoteViewController alloc] init];
    noteViewController.noteID = self.posts[index][@"id"];
    noteViewController.title = self.posts[index][@"title"];
    return noteViewController;
}

- (void)reloadBookmarksWithCompletion:(void (^)(NSError *))completion
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

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter *enUSPOSIXDateFormatter;
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

        enUSPOSIXDateFormatter = [[NSDateFormatter alloc] init];
        enUSPOSIXDateFormatter.locale = enUSPOSIXLocale;
        enUSPOSIXDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        enUSPOSIXDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

        [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
        [[ASPinboard sharedInstance] notesWithSuccess:^(NSArray *notes) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSInteger index = 0;
                    for (NSDictionary *note in notes) {
                        NSString *noteID = note[@"id"];
                        NSString *title = note[@"title"];
                        NSDate *date = [enUSPOSIXDateFormatter dateFromString:note[@"updated_at"]];
                        
#warning XXX
                        if (note[@"updated_at"]) {
                        }
                        else {
                            date = [NSDate date];
                        }
                        
                        if (title) {
                        }
                        else {
                            title = @"Untitled";
                        }
                        
                        [newNotesUnsorted addObject:@{
                                                      @"updated_at": date,
                                                      @"description": [self.dateFormatter stringFromDate:date],
                                                      @"title": title,
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
                    completion(nil);
                });
            });
        }];
    });
}

- (PostMetadata *)metadataForPostAtIndex:(NSInteger)index {
    return self.metadata[index];
}

- (PostMetadata *)compressedMetadataForPostAtIndex:(NSInteger)index {
    return self.metadata[index];
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

- (NSInteger)indexForPost:(NSDictionary *)post {
#warning O(N^2)
    return [self.posts indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj[@"id"] isEqualToString:post[@"id"]];
    }];
}

- (BOOL)supportsTagDrilldown {
    return NO;
}

- (BOOL)searchSupported {
    return NO;
}

@end
