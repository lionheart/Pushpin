//
//  GenericPostViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

@import UIKit;

#import "TTTAttributedLabel.h"
#import "PPAppDelegate.h"
#import "PPLoadingView.h"
#import "PPTableViewController.h"
#import "PPToolbar.h"
#import "PPWebViewController.h"

#import "PPBadgeWrapperView.h"
#import "FluidTableviewFlowLayout.h"
#import "PPTitleButton.h"
#import "PPBookmarkCell.h"
#import "PPDataSource.h"

@class PPNavigationController;

typedef enum : NSInteger {
    PPSearchScopeAllField,
    PPSearchScopeTitles,
    PPSearchScopeDescriptions,
    PPSearchScopeTags,
    
#ifdef PINBOARD
    PPSearchScopeFullText,
#endif

    PPSearchScopePublic,
} PPSearchBarScopeType;

@interface PPGenericPostViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, PPBadgeWrapperDelegate, PPTitleButtonDelegate, PPBookmarkCellDelegate, UIDynamicAnimatorDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *pullToRefreshView;
@property (nonatomic, strong) PPLoadingView *pullToRefreshImageView;
@property (nonatomic, strong) PPWebViewController *webViewController;
@property (nonatomic, strong) UIActionSheet *longPressActionSheet;
@property (nonatomic, strong) UIActionSheet *additionalTagsActionSheet;

@property (nonatomic, retain) id<PPDataSource> postDataSource;
@property (nonatomic, strong) id<PPDataSource> searchPostDataSource;

@property (nonatomic) BOOL actionSheetVisible;
@property (nonatomic, retain) NSDictionary *selectedPost;

@property (nonatomic, strong) UITableView *selectedTableView;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) UIAlertView *confirmMultipleDeletionAlertView;
@property (nonatomic, strong) UIAlertView *confirmDeletionAlertView;
@property (nonatomic) BOOL searchLoading;
@property (nonatomic) CFAbsoluteTime latestSearchUpdateTime;

@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchDisplayController;

// UIKit Dynamics
@property (nonatomic, strong) FluidTableviewFlowLayout *collectionViewLayout;
@property (nonatomic) CGSize itemSize;

// Multiple Deletion
@property (nonatomic, strong) PPToolbar *toolbar;
@property (nonatomic, strong) UIBarButtonItem *editButton;

@property (nonatomic, retain) UIView *multiToolbarView;

- (void)toggleEditingMode:(id)sender;

// Gesture and tap recognizers
@property (nonatomic, strong) UISwipeGestureRecognizer *rightSwipeGestureRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic, strong) NSTimer *singleTapTimer;
@property (nonatomic, strong) NSTimer *doubleTapTimer;
@property (nonatomic) NSUInteger numberOfTapsSinceTapReset;
@property (nonatomic) CGFloat beginningScale;
@property (nonatomic) BOOL compressPosts;
@property (nonatomic) BOOL dimReadPosts;
@property (nonatomic) CGPoint selectedPoint;

- (void)handleCellTap;
- (void)popViewController;
- (void)dismissViewController;
- (void)showConfirmDeletionAlert;
- (void)markPostAsRead;
- (void)markPostsAsRead:(NSArray *)posts;
- (void)copyURL;
- (void)sendToReadLater;
- (void)updateFromLocalDatabaseWithCallback:(void (^)())callback;
- (void)gestureDetected:(UIGestureRecognizer *)recognizer;
- (void)openActionSheetForSelectedPost;
- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths;

- (void)multiMarkAsRead:(id)sender;
- (void)multiEdit:(id)sender;
- (void)multiDelete:(id)sender;

- (void)tagSelected:(id)sender;

- (void)removeBarButtonTouchUpside:(id)sender;
- (void)addBarButtonTouchUpside:(id)sender;
- (id<PPDataSource>)dataSourceForTableView:(UITableView *)tableView;
- (id<PPDataSource>)currentDataSource;

- (void)preferredContentSizeChanged:(NSNotification *)aNotification;

@end
