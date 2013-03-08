//
//  GenericPostViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"
#import "RDActionSheet.h"

enum PostSources {
    POST_SOURCE_TWITTER,
    POST_SOURCE_TWITTER_FAVORITE,
    POST_SOURCE_READABILITY,
    POST_SOURCE_DELICIOUS,
    POST_SOURCE_POCKET, // AKA Read It Later
    POST_SOURCE_INSTAPAPER,
    POST_SOURCE_EMAIL,
};

@protocol GenericPostDataSource <NSObject>

- (NSInteger)numberOfPosts;
- (void)updatePosts:(void (^)(NSArray *, NSArray *, NSArray *))callback;
- (void)willDisplayIndexPath:(NSIndexPath *)indexPath callback:(void (^)(BOOL))callback;

- (NSRange)rangeForTitleForPostAtIndex:(NSInteger)index;
- (NSRange)rangeForDescriptionForPostAtIndex:(NSInteger)index;
- (NSRange)rangeForTagsForPostAtIndex:(NSInteger)index;

- (NSString *)titleForPostAtIndex:(NSInteger)index;
- (NSString *)descriptionForPostAtIndex:(NSInteger)index;

// These are separated by spaces
- (NSString *)tagsForPostAtIndex:(NSInteger)index;
- (NSInteger)sourceForPostAtIndex:(NSInteger)index;
- (NSDate *)dateForPostAtIndex:(NSInteger)index;
- (BOOL)isPostAtIndexStarred:(NSInteger)index;
- (BOOL)isPostAtIndexPrivate:(NSInteger)index;
- (BOOL)isPostAtIndexRead:(NSInteger)index;

- (CGFloat)heightForPostAtIndex:(NSInteger)index;
- (NSDictionary *)postAtIndex:(NSInteger)index;
- (NSAttributedString *)stringForPostAtIndex:(NSInteger)index;

@end

@interface GenericPostViewController : UITableViewController <TTTAttributedLabelDelegate, RDActionSheetDelegate>

@property (nonatomic, retain) id<GenericPostDataSource> postDataSource;
@property (nonatomic) BOOL processingPosts;

- (void)update;
- (NSMutableAttributedString *)attributedStringForPostAtIndexPath:(NSIndexPath *)indexPath;

@end
