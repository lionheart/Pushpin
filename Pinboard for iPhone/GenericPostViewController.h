//
//  GenericPostViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"
#import "AppDelegate.h"
#import "PPLoadingView.h"
#import "PPTableViewController.h"
#import "PPToolbar.h"
#import "PPWebViewController.h"

#import "FluidTableviewFlowLayout.h"

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

@class PPNavigationController;

@protocol GenericPostDataSource <NSObject>

- (NSInteger)numberOfPosts;
- (void)updatePostsFromDatabaseWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure;
- (void)updatePostsWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure options:(NSDictionary *)options;
- (void)updatePostsFromDatabase:(void (^)())success failure:(void (^)(NSError *))failure;

- (CGFloat)heightForPostAtIndex:(NSInteger)index;
- (NSArray *)actionsForPost:(NSDictionary *)post;
- (NSArray *)linksForPostAtIndex:(NSInteger)index;
- (NSAttributedString *)attributedStringForPostAtIndex:(NSInteger)index;

- (BOOL)isPostAtIndexStarred:(NSInteger)index;
- (BOOL)isPostAtIndexPrivate:(NSInteger)index;
- (BOOL)supportsTagDrilldown;

- (NSDictionary *)postAtIndex:(NSInteger)index;
- (NSString *)urlForPostAtIndex:(NSInteger)index;

@optional

@property (nonatomic) NSInteger totalNumberOfPosts;

- (void)resetHeightsWithSuccess:(void (^)())success;
- (CGFloat)compressedHeightForPostAtIndex:(NSInteger)index;
- (NSArray *)compressedLinksForPostAtIndex:(NSInteger)index;
- (NSAttributedString *)compressedAttributedStringForPostAtIndex:(NSInteger)index;

- (PPNavigationController *)editViewControllerForPostAtIndex:(NSInteger)index withDelegate:(id<ModalDelegate>)delegate;
- (id <GenericPostDataSource>)searchDataSource;
- (void)filterWithQuery:(NSString *)query;
- (void)addDataSource:(void (^)())callback;
- (void)removeDataSource:(void (^)())callback;

// A data source may alternatively provide a UIViewController to push
- (NSInteger)sourceForPostAtIndex:(NSInteger)index;
- (UIViewController *)viewControllerForPostAtIndex:(NSInteger)index;
- (void)handleTapOnLinkWithURL:(NSURL *)url callback:(void (^)(UIViewController *))callback;

- (PPNavigationController *)addViewControllerForPostAtIndex:(NSInteger)index delegate:(id<ModalDelegate>)delegate;
- (void)markPostAsRead:(NSString *)url callback:(void (^)(NSError *))callback;
- (void)deletePosts:(NSArray *)posts callback:(void (^)(NSIndexPath *))callback;
- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths callback:(void (^)(NSArray *, NSArray *))callback;
- (void)willDisplayIndexPath:(NSIndexPath *)indexPath callback:(void (^)(BOOL))callback;

@end

@interface GenericPostViewController : UICollectionViewController <TTTAttributedLabelDelegate, UIAlertViewDelegate, UIActionSheetDelegate, ModalDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) UIView *pullToRefreshView;
@property (nonatomic, strong) PPLoadingView *pullToRefreshImageView;
@property (nonatomic, strong) PPWebViewController *webViewController;
@property (nonatomic, strong) UIActionSheet *actionSheet;

@property (nonatomic, retain) id<GenericPostDataSource> postDataSource;
@property (nonatomic, strong) id<GenericPostDataSource> searchPostDataSource;

@property (nonatomic) BOOL actionSheetVisible;
@property (nonatomic, retain) NSDictionary *selectedPost;
@property (nonatomic, retain) UILongPressGestureRecognizer *longPressGestureRecognizer;

@property (nonatomic, strong) UITableView *selectedTableView;
@property (nonatomic, strong) UICollectionView *selectedCollectionView;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) UIAlertView *confirmDeletionAlertView;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL searchLoading;
@property (nonatomic) CFAbsoluteTime latestSearchUpdateTime;
@property (nonatomic, strong) NSString *latestSearchText;
@property (nonatomic, strong) NSTimer *latestSearchTimer;

@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchDisplayController;

// UIKit Dynamics
@property (nonatomic, strong) FluidTableviewFlowLayout *collectionViewLayout;
@property (nonatomic) CGSize itemSize;

// Multiple Deletion
@property (nonatomic, strong) PPToolbar *toolbar;
@property (nonatomic, strong) UIBarButtonItem *multipleDeleteButton;
@property (nonatomic, strong) UIBarButtonItem *editButton;

- (void)toggleEditingMode:(id)sender;

// Gesture and tap recognizers
@property (nonatomic, strong) UISwipeGestureRecognizer *deleteGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *rightSwipeGestureRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, strong) NSTimer *singleTapTimer;
@property (nonatomic, strong) NSTimer *doubleTapTimer;
@property (nonatomic) NSUInteger numberOfTapsSinceTapReset;
@property (nonatomic) CGFloat beginningScale;
@property (nonatomic) BOOL compressPosts;
@property (nonatomic) BOOL dimReadPosts;
@property (nonatomic) CGPoint selectedPoint;

- (void)handleCellTap;
- (void)popViewController;

- (void)searchTimerFired;
- (void)dismissViewController;
- (void)showConfirmDeletionAlert;
- (void)markPostAsRead;
- (void)copyURL;
- (void)sendToReadLater;
- (void)updateWithRatio:(NSNumber *)ratio;
- (void)updateFromLocalDatabaseWithCallback:(void (^)())callback;
- (void)updateSearchResults;
- (void)longPressGestureDetected:(UILongPressGestureRecognizer *)recognizer;
- (void)gestureDetected:(UIGestureRecognizer *)recognizer;
- (void)openActionSheetForSelectedPost;
- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths;
- (IBAction)deletePost:(id)sender;

- (void)removeBarButtonTouchUpside:(id)sender;
- (void)addBarButtonTouchUpside:(id)sender;
- (id<GenericPostDataSource>)dataSourceForTableView:(UITableView *)tableView;
- (id<GenericPostDataSource>)dataSourceForCollectionView:(UICollectionView *)collectionView;
- (id<GenericPostDataSource>)currentDataSource;

- (void)preferredContentSizeChanged:(NSNotification *)aNotification;

@end
