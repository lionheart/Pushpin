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
#import "WCAlertView.h"

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
- (void)markPostAsRead:(NSString *)url callback:(void (^)(NSError *))callback;
- (void)deletePosts:(NSArray *)posts callback:(void (^)(NSIndexPath *))callback;
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

@interface GenericPostViewController : UITableViewController <TTTAttributedLabelDelegate, RDActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) id<GenericPostDataSource> postDataSource;
@property (nonatomic) BOOL processingPosts;
@property (nonatomic) BOOL actionSheetVisible;
@property (nonatomic, retain) NSDictionary *selectedPost;
@property (nonatomic, retain) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) WCAlertView *confirmDeletionAlertView;
@property (nonatomic) BOOL timerPaused;
@property (nonatomic, retain) NSTimer *updateTimer;

- (void)checkForPostUpdates;
- (void)showConfirmDeletionAlert;
- (void)markPostAsRead;
- (void)deletePosts:(NSArray *)posts;
- (void)copyURL;
- (void)sendToReadLater;
- (void)update;
- (void)longPressGestureDetected:(UILongPressGestureRecognizer *)recognizer;
- (void)openActionSheetForSelectedPost;
- (NSMutableAttributedString *)attributedStringForPostAtIndexPath:(NSIndexPath *)indexPath;

@end
