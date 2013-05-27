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
#import "AppDelegate.h"
#import "PPLoadingView.h"
#import "PPTableViewController.h"

enum PostSources {
    POST_SOURCE_TWITTER,
    POST_SOURCE_TWITTER_FAVORITE,
    POST_SOURCE_READABILITY,
    POST_SOURCE_DELICIOUS,
    POST_SOURCE_POCKET, // AKA Read It Later
    POST_SOURCE_INSTAPAPER,
    POST_SOURCE_EMAIL,
};

enum PPPostActions {
    PPPostActionCopyToMine,
    PPPostActionCopyURL,
    PPPostActionDelete,
    PPPostActionEdit,
    PPPostActionReadLater,
    PPPostActionMarkAsRead
};
typedef NSInteger PPPostAction;

@protocol GenericPostDataSource <NSObject>

- (void)filterWithQuery:(NSString *)query;
- (NSInteger)numberOfPosts;
- (NSInteger)totalNumberOfPosts;
- (void)updatePostsFromDatabaseWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure;
- (void)updatePostsWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure options:(NSDictionary *)options;

- (NSArray *)actionsForPost:(NSDictionary *)post;
- (NSString *)titleForPostAtIndex:(NSInteger)index;
- (NSString *)urlForPostAtIndex:(NSInteger)index;
- (NSString *)descriptionForPostAtIndex:(NSInteger)index;
- (NSArray *)linksForPostAtIndex:(NSInteger)index;
- (NSAttributedString *)attributedStringForPostAtIndex:(NSInteger)index;
- (NSRange)rangeForTitleForPostAtIndex:(NSInteger)index;
- (NSRange)rangeForDescriptionForPostAtIndex:(NSInteger)index;
- (NSRange)rangeForTagsForPostAtIndex:(NSInteger)index;

- (UIViewController *)editViewControllerForPostAtIndex:(NSInteger)index withDelegate:(id<ModalDelegate>)delegate;

// These are separated by spaces
- (NSString *)tagsForPostAtIndex:(NSInteger)index;
- (NSInteger)sourceForPostAtIndex:(NSInteger)index;
- (NSDate *)dateForPostAtIndex:(NSInteger)index;
- (NSString *)formattedDateForPostAtIndex:(NSInteger)index;
- (BOOL)isPostAtIndexStarred:(NSInteger)index;
- (BOOL)isPostAtIndexPrivate:(NSInteger)index;
- (BOOL)isPostAtIndexRead:(NSInteger)index;
- (BOOL)supportsSearch;
- (BOOL)supportsTagDrilldown;

- (id <GenericPostDataSource>)searchDataSource;

- (NSDictionary *)postAtIndex:(NSInteger)index;

@optional

- (UIViewController *)addViewControllerForPostAtIndex:(NSInteger)index delegate:(id<ModalDelegate>)delegate;
- (void)markPostAsRead:(NSString *)url callback:(void (^)(NSError *))callback;
- (void)deletePosts:(NSArray *)posts callback:(void (^)(NSIndexPath *))callback;
- (void)willDisplayIndexPath:(NSIndexPath *)indexPath callback:(void (^)(BOOL))callback;

@end

@interface GenericPostViewController : PPTableViewController <TTTAttributedLabelDelegate, RDActionSheetDelegate, UIAlertViewDelegate, ModalDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) UIView *pullToRefreshView;
@property (nonatomic, strong) PPLoadingView *pullToRefreshImageView;

@property (nonatomic, retain) id<GenericPostDataSource> postDataSource;
@property (nonatomic, strong) id<GenericPostDataSource> searchPostDataSource;

@property (nonatomic) BOOL processingPosts;
@property (nonatomic) BOOL actionSheetVisible;
@property (nonatomic, retain) NSDictionary *selectedPost;
@property (nonatomic, retain) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) WCAlertView *confirmDeletionAlertView;
@property (nonatomic) BOOL loading;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchDisplayController;

// Timer Stuff
@property (nonatomic, strong) NSTimer *bookmarkRefreshTimer;
@property (nonatomic) BOOL bookmarkRefreshTimerPaused;

- (void)dismissViewController;
- (void)checkForPostUpdates;
- (void)showConfirmDeletionAlert;
- (void)markPostAsRead;
- (void)deletePosts:(NSArray *)posts;
- (void)copyURL;
- (void)copyToMine;
- (void)sendToReadLater;
- (void)updateWithCount:(NSNumber *)count;
- (void)updateFromLocalDatabase;
- (void)updateSearchResults;
- (void)longPressGestureDetected:(UILongPressGestureRecognizer *)recognizer;
- (void)openActionSheetForSelectedPost;
- (NSMutableAttributedString *)attributedStringForPostAtIndexPath:(NSIndexPath *)indexPath;

@end
