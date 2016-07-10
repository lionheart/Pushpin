//
//  GenericPostViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

@import UIKit;
@import TTTAttributedLabel;

#import "PPAppDelegate.h"
#import "PPLoadingView.h"
#import "PPTableViewController.h"
#import "PPToolbar.h"
#import "PPWebViewController.h"
#import "PPBadgeWrapperView.h"
#import "PPTitleButton.h"
#import "PPBookmarkCell.h"
#import "PPDataSource.h"

@class PPNavigationController;

static dispatch_queue_t PPReloadSerialQueue() {
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("io.aurora.Pushpin.PushpinReloadQueue", 0);
    });
    return queue;
}

typedef enum : NSInteger {
    PPSearchScopeAllField,
    PPSearchScopeTitles,
    PPSearchScopeDescriptions,
    PPSearchScopeTags,
    

    PPSearchScopeFullText,

    PPSearchScopePublic,
} PPSearchBarScopeType;

@interface PPGenericPostViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, PPBadgeWrapperDelegate, PPTitleButtonDelegate, PPBookmarkCellDelegate, UIDynamicAnimatorDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PPWebViewController *webViewController;
@property (nonatomic, strong) UIAlertController *longPressActionSheet;
@property (nonatomic, strong) UIAlertController *additionalTagsActionSheet;

@property (nonatomic, retain) id<PPDataSource> postDataSource;
@property (nonatomic, strong) id<PPDataSource> searchPostDataSource;

@property (nonatomic, retain) NSDictionary *selectedPost;

@property (nonatomic, strong) UITableView *selectedTableView;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) UIAlertController *confirmDeletionAlertView;
@property (nonatomic) CFAbsoluteTime latestSearchUpdateTime;

// Multiple Deletion
@property (nonatomic, strong) PPToolbar *toolbar;
@property (nonatomic, strong) UIBarButtonItem *editButton;

@property (nonatomic, retain) UIView *multiToolbarView;

- (void)toggleEditingMode:(id)sender;

// Gesture and tap recognizers
@property (nonatomic, strong) UISwipeGestureRecognizer *rightSwipeGestureRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic) CGFloat beginningScale;
@property (nonatomic) BOOL compressPosts;
@property (nonatomic) BOOL dimReadPosts;
@property (nonatomic) CGPoint selectedPoint;
@property (nonatomic) BOOL needsUpdate;

- (void)handleCellTap;
- (void)popViewController;
- (void)dismissViewController;
- (void)showConfirmDeletionAlert;
- (void)markPostAsRead;
- (void)markPostsAsRead:(NSArray *)posts;
- (void)copyURL;
- (void)sendToReadLater;
- (void)gestureDetected:(UIGestureRecognizer *)recognizer;
- (void)openActionSheetForSelectedPost;

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
