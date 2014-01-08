//
//  GenericPostViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "GenericPostViewController.h"
#import "NSAttributedString+Attributes.h"
#import "NSString+URLEncoding2.h"
#import "PPStatusBarNotification.h"
#import "PPConstants.h"

#import "PinboardDataSource.h"
#import "PPBadgeWrapperView.h"
#import "PPMultipleEditViewController.h"
#import "FeedListViewController.h"
#import "PPTheme.h"

#import <FMDB/FMDatabase.h>
#import <oauthconsumer/OAuthConsumer.h>
#import <ASPinboard/ASPinboard.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>
#import <PocketAPI/PocketAPI.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/UIImage+LHSAdditions.h>
#import <LHSCategoryCollection/UIScreen+LHSAdditions.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

static BOOL kGenericPostViewControllerPerformAtomicUpdates = NO;
static BOOL kGenericPostViewControllerIsProcessingPosts = NO;
static BOOL kGenericPostViewControllerDimmingReadPosts = NO;
static NSString *BookmarkCellIdentifier = @"BookmarkCellIdentifier";
static NSInteger kToolbarHeight = 44;

@interface GenericPostViewController ()

@property (nonatomic, strong) UIButton *multipleMarkAsReadButton;
@property (nonatomic, strong) UIButton *multipleTagEditButton;
@property (nonatomic, strong) UIButton *multipleDeleteButton;
@property (nonatomic, strong) UIActionSheet *confirmDeletionActionSheet;
@property (nonatomic, strong) UIActionSheet *confirmMultipleDeletionActionSheet;
@property (nonatomic, strong) NSLayoutConstraint *multipleEditStatusViewTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *multipleEditToolbarBottomConstraint;
@property (nonatomic, retain) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *searchDisplayLongPressGestureRecognizer;
@property (nonatomic, strong) NSArray *indexPathsToDelete;
@property (nonatomic) BOOL prefersStatusBarHidden;
@property (nonatomic, strong) NSDate *latestSearchTime;
@property (nonatomic, strong) UIDynamicAnimator *animator;

@property (nonatomic, strong) NSLayoutConstraint *pullToRefreshTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *tableViewPinnedToTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *tableViewPinnedToBottomConstraint;

- (void)showConfirmDeletionActionSheet;
- (void)toggleCompressedPosts;
- (void)setMultipleEditButtonsEnabled:(BOOL)enabled;
- (void)resetSearchTimer;
- (void)performTableViewUpdatesWithInserts:(NSArray *)indexPathsToInsert reloads:(NSArray *)indexPathsToReload deletes:(NSArray *)indexPathsToDelete;
- (void)updateSearchResultsForSearchPerformedAtTime:(NSDate *)time;

@end

@implementation GenericPostViewController

@synthesize searchDisplayController = __searchDisplayController;
@synthesize itemSize = _itemSize;

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.prefersStatusBarHidden = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.actionSheetVisible = NO;
    self.latestSearchTime = [NSDate date];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = YES;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.frame = CGRectOffset(self.view.frame, 0, CGRectGetHeight(self.view.frame));
    
    self.pullToRefreshView = [[UIView alloc] init];
    self.pullToRefreshView.translatesAutoresizingMaskIntoConstraints = NO;
    self.pullToRefreshView.clipsToBounds = YES;
    self.pullToRefreshView.backgroundColor = [UIColor whiteColor];

    self.pullToRefreshImageView = [[PPLoadingView alloc] init];
    self.pullToRefreshImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.pullToRefreshImageView.backgroundColor = [UIColor clearColor];
    [self.pullToRefreshView addSubview:self.pullToRefreshImageView];

    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(popViewController)];
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    self.rightSwipeGestureRecognizer.numberOfTouchesRequired = 1;
    self.rightSwipeGestureRecognizer.cancelsTouchesInView = YES;
    [self.tableView addGestureRecognizer:self.rightSwipeGestureRecognizer];

    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    [self.tableView addGestureRecognizer:self.pinchGestureRecognizer];

    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];
    
    self.searchDisplayLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];

    self.searchLoading = NO;
    
    // Setup the multi-edit status view
    self.multiStatusView = [[UIView alloc] init];
    self.multiStatusView.backgroundColor = HEX(0xFFFFFFFF);
    self.multiStatusView.alpha = 0;
    self.multiStatusView.hidden = YES;
    self.multiStatusView.clipsToBounds = YES;
    self.multiStatusView.translatesAutoresizingMaskIntoConstraints = NO;

    self.multiStatusLabel = [[UILabel alloc] init];
    self.multiStatusLabel.textColor = [UIColor grayColor];
    self.multiStatusLabel.text = @"No bookmarks selected";
    self.multiStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.multiStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.multiStatusView addSubview:self.multiStatusLabel];

    UIView *multiStatusBorderView = [[UIView alloc] init];
    multiStatusBorderView.backgroundColor = HEX(0xb2b2b2ff);
    multiStatusBorderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.multiStatusView addSubview:multiStatusBorderView];

    NSDictionary *statusViews = @{ @"label": self.multiStatusLabel, @"border": multiStatusBorderView };
    [self.multiStatusView lhs_addConstraints:@"H:|[label]|" views:statusViews];
    [self.multiStatusView lhs_addConstraints:@"H:|[border]|" views:statusViews];
    [self.multiStatusView lhs_addConstraints:@"V:|-4-[label]-4-[border(0.5)]|" views:statusViews];
    
    // Setup the multi-edit toolbar
    self.multiToolbarView = [[UIView alloc] init];
    self.multiToolbarView.backgroundColor = HEX(0xEBF2F6FF);
    self.multiToolbarView.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *multiToolbarBorderView = [[UIView alloc] init];
    multiToolbarBorderView.backgroundColor = HEX(0xb2b2b2ff);
    multiToolbarBorderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.multiToolbarView addSubview:multiToolbarBorderView];
    
    // Buttons
    self.multipleMarkAsReadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.multipleMarkAsReadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.multipleMarkAsReadButton setImage:[[UIImage imageNamed:@"toolbar-checkmark"] lhs_imageWithColor:HEX(0x808d96ff)] forState:UIControlStateNormal];
    [self.multipleMarkAsReadButton addTarget:self action:@selector(multiMarkAsRead:) forControlEvents:UIControlEventTouchUpInside];
    [self.multiToolbarView addSubview:self.multipleMarkAsReadButton];
    self.multipleMarkAsReadButton.enabled = NO;
    
    self.multipleTagEditButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.multipleTagEditButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.multipleTagEditButton setImage:[[UIImage imageNamed:@"toolbar-edit-tags"] lhs_imageWithColor:HEX(0x808d96ff)] forState:UIControlStateNormal];
    [self.multipleTagEditButton addTarget:self action:@selector(multiEdit:) forControlEvents:UIControlEventTouchUpInside];
    [self.multiToolbarView addSubview:self.multipleTagEditButton];
    self.multipleTagEditButton.enabled = NO;
    self.multipleTagEditButton.hidden = YES;

    self.multipleDeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.multipleDeleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.multipleDeleteButton setImage:[[UIImage imageNamed:@"toolbar-trash"] lhs_imageWithColor:HEX(0x808d96ff)] forState:UIControlStateNormal];
    [self.multipleDeleteButton addTarget:self action:@selector(multiDelete:) forControlEvents:UIControlEventTouchUpInside];
    [self.multiToolbarView addSubview:self.multipleDeleteButton];
    self.multipleDeleteButton.enabled = NO;

    // Multi edit status and toolbar
    [self.view addSubview:self.multiStatusView];
    [self.view addSubview:self.multiToolbarView];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.pullToRefreshView];

    NSDictionary *toolbarViews = @{ @"border": multiToolbarBorderView,
                                    @"read": self.multipleMarkAsReadButton,
                                    @"edit": self.multipleTagEditButton,
                                    @"delete": self.multipleDeleteButton };

    [self.multiToolbarView lhs_addConstraints:@"H:|[read][delete(==read)]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[read]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[delete]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"H:|[border]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[border(0.5)]" views:toolbarViews];

    NSDictionary *views = @{@"statusView": self.multiStatusView,
                            @"toolbarView": self.multiToolbarView,
                            @"ptr": self.pullToRefreshView,
                            @"image": self.pullToRefreshImageView,
                            @"table": self.tableView,
                            @"top": self.topLayoutGuide,
                            @"bottom": self.bottomLayoutGuide };
    
    [self.pullToRefreshView lhs_centerHorizontallyForView:self.pullToRefreshImageView];
    [self.pullToRefreshView lhs_centerVerticallyForView:self.pullToRefreshImageView];
    
    self.pullToRefreshTopConstraint = [NSLayoutConstraint constraintWithItem:self.pullToRefreshView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.tableView attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self.view addConstraint:self.pullToRefreshTopConstraint];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.pullToRefreshView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
//    self.tableViewPinnedToBottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    self.tableViewPinnedToTopConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0];
//    [self.view addConstraint:self.tableViewPinnedToTopConstraint];

    [self.view lhs_addConstraints:@"V:[ptr(60)]" views:views];
    [self.view lhs_addConstraints:@"H:|[ptr]|" views:views];
    [self.view lhs_addConstraints:@"H:|[statusView]|" views:views];
    [self.view lhs_addConstraints:@"V:[statusView(height)]" metrics:@{ @"height": @(kToolbarHeight) } views:views];
    [self.view lhs_addConstraints:@"H:|[toolbarView]|" views:views];
    [self.view lhs_addConstraints:@"V:[toolbarView(height)]" metrics:@{ @"height": @(kToolbarHeight) } views:views];

    // Register for Dynamic Type notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];

    // Initial database update
    [self.tableView registerClass:[PPBookmarkCell class] forCellReuseIdentifier:BookmarkCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (![self.view.constraints containsObject:self.tableViewPinnedToBottomConstraint] && ![self.view.constraints containsObject:self.tableViewPinnedToTopConstraint]) {
//        [self.view addConstraint:self.tableViewPinnedToBottomConstraint];
    }

    if ([self.postDataSource respondsToSelector:@selector(barTintColor)]) {
        [self.navigationController.navigationBar setBarTintColor:[self.postDataSource barTintColor]];
    }
    
    if (!self.title && [self.postDataSource respondsToSelector:@selector(title)]) {
        self.title = [self.postDataSource title];
    }

    if (!self.navigationItem.titleView && [self.postDataSource respondsToSelector:@selector(titleViewWithDelegate:)]) {
        PPTitleButton *titleView = (PPTitleButton *)[self.postDataSource titleViewWithDelegate:self];
        self.navigationItem.titleView = titleView;
    }

    if (self.multipleEditToolbarBottomConstraint) {
        [self.view removeConstraint:self.multipleEditToolbarBottomConstraint];
    }
    self.multipleEditToolbarBottomConstraint = [NSLayoutConstraint constraintWithItem:self.multiToolbarView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:kToolbarHeight];
    [self.view addConstraint:self.multipleEditToolbarBottomConstraint];

    if (self.multipleEditStatusViewTopConstraint) {
        [self.view removeConstraint:self.multipleEditStatusViewTopConstraint];
    }
    self.multipleEditStatusViewTopConstraint = [NSLayoutConstraint constraintWithItem:self.multiStatusView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:-kToolbarHeight];
    [self.view addConstraint:self.multipleEditStatusViewTopConstraint];
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     }];
    
    UIViewController *backViewController = (self.navigationController.viewControllers.count >= 2) ? self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2] : nil;

    if ([backViewController isKindOfClass:[FeedListViewController class]]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigation-list"] landscapeImagePhone:[UIImage imageNamed:@"navigation-list"] style:UIBarButtonItemStylePlain target:self action:@selector(popViewController)];

        __weak id weakself = self;
        self.navigationController.interactivePopGestureRecognizer.delegate = weakself;
    }
    
    if (self.navigationController.navigationBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
    
    if ([self.postDataSource respondsToSelector:@selector(deletePostsAtIndexPaths:callback:)]) {
        self.editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigation-edit"] landscapeImagePhone:[UIImage imageNamed:@"navigation-edit"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleEditingMode:)];
        self.navigationItem.rightBarButtonItem = self.editButton;
    }

    if ([self.postDataSource numberOfPosts] == 0) {
        self.tableView.separatorColor = [UIColor clearColor];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    BOOL oldCompressPosts = self.compressPosts;
    self.compressPosts = [AppDelegate sharedDelegate].compressPosts;
    if (self.compressPosts != oldCompressPosts) {
        if (!kGenericPostViewControllerIsProcessingPosts) {
            kGenericPostViewControllerIsProcessingPosts = YES;
            NSArray *indexPathsToReload = [self.tableView indexPathsForVisibleRows];
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
            kGenericPostViewControllerIsProcessingPosts = NO;
        }
    }

    BOOL oldDimReadPosts = self.dimReadPosts;
    self.dimReadPosts = [AppDelegate sharedDelegate].dimReadPosts;
    if (oldDimReadPosts != self.dimReadPosts) {
        if (!kGenericPostViewControllerDimmingReadPosts) {
            kGenericPostViewControllerDimmingReadPosts = YES;
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
            kGenericPostViewControllerDimmingReadPosts = NO;
        }
    }

    if ([self.postDataSource numberOfPosts] == 0) {
        [self.pullToRefreshImageView startAnimating];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateFromLocalDatabaseWithCallback:^{
                if ([AppDelegate sharedDelegate].bookmarksNeedUpdate) {
                    if (!kGenericPostViewControllerIsProcessingPosts) {
                        kGenericPostViewControllerIsProcessingPosts = YES;
                        [self.postDataSource updatePostsWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self performTableViewUpdatesWithInserts:indexPathsToAdd reloads:indexPathsToReload deletes:indexPathsToRemove];

                                self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
                                
                                UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[self.tableView]];
                                collision.collisionMode = UICollisionBehaviorModeBoundaries;
                                [collision addBoundaryWithIdentifier:@"top" fromPoint:CGPointMake(0, 0) toPoint:CGPointMake(CGRectGetWidth(self.view.frame), 0)];

                                UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[self.tableView]];
                                gravity.gravityDirection = CGVectorMake(0, -4);
                                
                                UIPushBehavior *push = [[UIPushBehavior alloc] initWithItems:@[self.tableView] mode:UIPushBehaviorModeContinuous];
                                push.pushDirection = CGVectorMake(0, -100);
                                
                                [self.animator addBehavior:collision];
                                [self.animator addBehavior:gravity];
//                                [self.animator addBehavior:push];

                                kGenericPostViewControllerIsProcessingPosts = NO;
                            });
                        } failure:nil options:@{@"ratio": @(1.0), @"width": @(CGRectGetWidth(self.tableView.frame)) } ];
                    }
                }
            }];
        });
    }
    else {
        [self.tableView reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[AppDelegate sharedDelegate] setCompressPosts:self.compressPosts];
}

- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.tableView == tableView && [self.postDataSource respondsToSelector:@selector(deletePostsAtIndexPaths:callback:)];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        self.selectedPost = [self.postDataSource postAtIndex:indexPath.row];
        [self showConfirmDeletionAlert];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView.editing) {
        NSUInteger selectedRowCount = [tableView.indexPathsForSelectedRows count];
        if (selectedRowCount > 0) {
            self.multipleDeleteButton.enabled = YES;
            self.multipleTagEditButton.enabled = YES;
            self.multipleMarkAsReadButton.enabled = YES;
        }
        else {
            self.multipleDeleteButton.enabled = NO;
            self.multipleTagEditButton.enabled = NO;
            self.multipleMarkAsReadButton.enabled = NO;
        }

        self.multiStatusLabel.text = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedRowCount, NSLocalizedString(@"bookmarks selected", nil)];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.numberOfTapsSinceTapReset++;
    self.selectedTableView = tableView;
    self.selectedIndexPath = indexPath;
    
    if ([AppDelegate sharedDelegate].doubleTapToEdit) {
        if (!self.singleTapTimer) {
            self.singleTapTimer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(handleCellTap) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:self.singleTapTimer forMode:NSRunLoopCommonModes];
        }
        else {
            [self.singleTapTimer invalidate];
            self.singleTapTimer = nil;
            [self handleCellTap];
        }
    }
    else {
        [self handleCellTap];
    }
}

- (void)handleCellTap {
    if (self.numberOfTapsSinceTapReset > 0) {
        id <GenericPostDataSource> dataSource = [self dataSourceForTableView:self.selectedTableView];

        if (self.selectedTableView.editing) {
            NSUInteger selectedRowCount = [self.selectedTableView.indexPathsForSelectedRows count];
            [self setMultipleEditButtonsEnabled:(selectedRowCount > 0)];

            self.multiStatusLabel.text = [NSString stringWithFormat:@"%ld %@", (long)selectedRowCount, NSLocalizedString(@"bookmarks selected", nil)];
        }
        else {
            // If configured, always mark the post as read
            if ([AppDelegate sharedDelegate].markReadPosts) {
                self.selectedPost = [self.postDataSource postAtIndex:self.selectedIndexPath.row];
                [self markPostsAsRead:@[self.selectedPost] notify:NO];
            }
            
            [self.selectedTableView deselectRowAtIndexPath:self.selectedIndexPath animated:NO];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];

            switch (self.numberOfTapsSinceTapReset) {
                case 1:
                    if (![dataSource respondsToSelector:@selector(viewControllerForPostAtIndex:)]) {
                        NSString *urlString = [dataSource urlForPostAtIndex:self.selectedIndexPath.row];
                        NSRange httpRange = NSMakeRange(NSNotFound, 0);
                        if ([urlString hasPrefix:@"http"]) {
                            httpRange = [urlString rangeOfString:@"http"];
                        }
                        
#warning TODO Check outside links
                        // Check for App Store link
                        
                        if ([[[AppDelegate sharedDelegate] openLinksInApp] boolValue]) {
                            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Webview"}];
                            if ([AppDelegate sharedDelegate].openLinksWithMobilizer) {
                                self.webViewController = [PPWebViewController mobilizedWebViewControllerWithURL:urlString];
                            }
                            else {
                                self.webViewController = [PPWebViewController webViewControllerWithURL:urlString];
                            }
                            
                            if ([self.navigationController topViewController] == self) {
                                [self.navigationController pushViewController:self.webViewController animated:YES];
                            }
                        }
                        else {
                            PPBrowserType browser = [AppDelegate sharedDelegate].browser;
                            switch (browser) {
                                case PPBrowserSafari: {
                                    [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Safari"}];
                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
                                    break;
                                }
                                    
                                case PPBrowserChrome:
                                    if (httpRange.location != NSNotFound) {
                                        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome-x-callback://"]]) {
                                            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"googlechrome-x-callback://x-callback-url/open/?url=%@&x-success=pushpin%%3A%%2F%%2F&&x-source=Pushpin", [urlString urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
                                            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Chrome"}];
                                            [[UIApplication sharedApplication] openURL:url];
                                        }
                                        else {
                                            NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"googlechrome"]];
                                            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Chrome"}];
                                            [[UIApplication sharedApplication] openURL:url];
                                        }
                                    }
                                    else {
                                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Shucks", nil) message:NSLocalizedString(@"Google Chrome failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                        [alert show];
                                    }
                                    
                                    break;
                                    
                                case PPBrowseriCabMobile:
                                    if (httpRange.location != NSNotFound) {
                                        NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"icabmobile"]];
                                        [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"iCab Mobile"}];
                                        [[UIApplication sharedApplication] openURL:url];
                                    }
                                    else {
                                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Shucks", nil) message:NSLocalizedString(@"iCab Mobile failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                        [alert show];
                                    }
                                    
                                    break;
                                    
                                case PPBrowserOpera:
                                    if (httpRange.location != NSNotFound) {
                                        NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"ohttp"]];
                                        [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Opera"}];
                                        [[UIApplication sharedApplication] openURL:url];
                                    }
                                    else {
                                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Shucks", nil) message:NSLocalizedString(@"Opera failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                        [alert show];
                                    }
                                    
                                    break;
                                    
                                case PPBrowserDolphin:
                                    if (httpRange.location != NSNotFound) {
                                        NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"dolphin"]];
                                        [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"dolphin"}];
                                        [[UIApplication sharedApplication] openURL:url];
                                    }
                                    else {
                                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Shucks", nil) message:NSLocalizedString(@"iCab Mobile failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                        [alert show];
                                    }
                                    
                                    break;
                                    
                                case PPBrowserCyberspace:
                                    if (httpRange.location != NSNotFound) {
                                        NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"cyber"]];
                                        [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Cyberspace Browser"}];
                                        [[UIApplication sharedApplication] openURL:url];
                                    }
                                    else {
                                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Shucks", nil) message:NSLocalizedString(@"Cyberspace failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                        [alert show];
                                    }
                                    
                                    break;
                                    
                                default:
                                    break;
                            }
                        }
                    }
                    else {
                        // The post data source will provide a view controller to push.
                        UIViewController *controller = [dataSource viewControllerForPostAtIndex:self.selectedIndexPath.row];

                        if ([self.navigationController topViewController] == self) {
                            [self.navigationController pushViewController:controller animated:YES];
                        }
                    }
                    break;
                    
                case 2: {
                    UIViewController *vc;
                    if ([dataSource respondsToSelector:@selector(addViewControllerForPostAtIndex:delegate:)]) {
                        vc = (UIViewController *)[dataSource addViewControllerForPostAtIndex:self.selectedIndexPath.row];
                    }
                    else if ([dataSource respondsToSelector:@selector(editViewControllerForPostAtIndex:withDelegate:)]) {
                        vc = (UIViewController *)[dataSource editViewControllerForPostAtIndex:self.selectedIndexPath.row];
                    }

                    if (vc) {
                        if ([UIApplication isIPad]) {
                            vc.modalPresentationStyle = UIModalPresentationFormSheet;
                        }

                        if ([self.navigationController topViewController] == self) {
                            [self.navigationController presentViewController:vc animated:YES completion:nil];
                        }
                    }
                    break;
                }
                    
                default:
                    break;
            }
        }
    }

    self.singleTapTimer = nil;
    self.doubleTapTimer = nil;
    self.numberOfTapsSinceTapReset = 0;
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (recognizer == self.longPressGestureRecognizer) {
        [self.view endEditing:YES];
        self.selectedPoint = [recognizer locationInView:self.tableView];
        self.selectedIndexPath = [self.tableView indexPathForRowAtPoint:self.selectedPoint];
        self.selectedPost = [self.postDataSource postAtIndex:self.selectedIndexPath.row];
        [self openActionSheetForSelectedPost];
    }
    else if (recognizer == self.searchDisplayLongPressGestureRecognizer) {
        self.selectedPoint = [recognizer locationInView:self.searchDisplayController.searchResultsTableView];
        self.selectedIndexPath = [self.searchDisplayController.searchResultsTableView indexPathForRowAtPoint:self.selectedPoint];
        self.selectedPost = [self.searchPostDataSource postAtIndex:self.selectedIndexPath.row];
        [self openActionSheetForSelectedPost];
    }
    else if (recognizer == self.pinchGestureRecognizer) {
        if (recognizer.state != UIGestureRecognizerStateBegan) {
            BOOL needsReload = NO;
            if (self.compressPosts) {
                needsReload = self.pinchGestureRecognizer.scale > 1.5;
            }
            else {
                needsReload = self.pinchGestureRecognizer.scale < 0.5;
            }

            if (needsReload) {
                [self toggleCompressedPosts];
            }
        }
    }
    else if (recognizer == self.doubleTapGestureRecognizer) {
        self.dimReadPosts = !self.dimReadPosts;
        [[AppDelegate sharedDelegate] setDimReadPosts:self.dimReadPosts];

        [self.postDataSource updatePostsFromDatabaseWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *realIndexPathsToReload = self.tableView.indexPathsForVisibleRows;
                [self performTableViewUpdatesWithInserts:nil reloads:realIndexPathsToReload deletes:nil];
            });
        } failure:nil];
    }
}

- (void)updateFromLocalDatabaseWithCallback:(void (^)())callback {
    if (!kGenericPostViewControllerIsProcessingPosts) {
        kGenericPostViewControllerIsProcessingPosts = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.postDataSource updatePostsFromDatabaseWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self performTableViewUpdatesWithInserts:indexPathsToAdd reloads:indexPathsToReload deletes:indexPathsToRemove];
                    self.tableView.separatorColor = HEX(0xE0E0E0ff);

                    if ([self.postDataSource respondsToSelector:@selector(searchDataSource)] && !self.searchPostDataSource) {
                        self.searchPostDataSource = [self.postDataSource searchDataSource];
                        
                        self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, [UIApplication currentSize].width, 44)];
                        self.searchBar.delegate = self;
                        self.searchBar.scopeButtonTitles = @[@"All", @"Full Text", @"Title", @"Desc.", @"Tags"];
                        self.searchBar.showsScopeBar = YES;
                        
                        if ([self.searchPostDataSource respondsToSelector:@selector(searchPlaceholder)]) {
                            self.searchBar.placeholder = [self.searchPostDataSource searchPlaceholder];
                        }
                        
                        self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
                        self.searchDisplayController.searchResultsDataSource = self;
                        self.searchDisplayController.searchResultsDelegate = self;
                        self.searchDisplayController.delegate = self;
                        [self.searchDisplayController.searchResultsTableView addGestureRecognizer:self.searchDisplayLongPressGestureRecognizer];
                        
                        self.tableView.tableHeaderView = self.searchBar;
                        self.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(self.searchBar.frame));
                        [self.searchDisplayController.searchResultsTableView registerClass:[PPBookmarkCell class] forCellReuseIdentifier:BookmarkCellIdentifier];

                        kGenericPostViewControllerIsProcessingPosts = NO;

                        if (callback) {
                            callback();
                        }
                    }
                });
            } failure:nil];
        });
    }
}

- (void)updateSearchResultsForSearchPerformedAtTime:(NSDate *)time {
    if (!self.searchLoading) {
        self.searchLoading = YES;
        __weak GenericPostViewController *weakself = self;
        BOOL shouldSearchFullText = self.searchBar.selectedScopeButtonIndex == PPSearchFullText;
        
        if (shouldSearchFullText) {
            [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
        }
        [self.searchPostDataSource updatePostsFromDatabaseWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
            if ([time compare:self.latestSearchTime] == NSOrderedSame) {
                if (shouldSearchFullText) {
                    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    weakself.searchLoading = NO;
                    [weakself.searchDisplayController.searchResultsTableView reloadData];
                });
            }
            else {
                weakself.searchLoading = NO;
            }
        } failure:^(NSError *error) {
            weakself.searchLoading = NO;
            
            if (shouldSearchFullText) {
                [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
            }
        }];
    }
}

- (void)updateWithRatio:(NSNumber *)ratio {
    if (!kGenericPostViewControllerIsProcessingPosts) {
        kGenericPostViewControllerIsProcessingPosts = YES;
        [self.postDataSource updatePostsWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performTableViewUpdatesWithInserts:indexPathsToAdd reloads:indexPathsToReload deletes:indexPathsToRemove];

                [self.pullToRefreshImageView stopAnimating];
                kGenericPostViewControllerIsProcessingPosts = NO;
            });
        } failure:nil options:@{@"ratio": ratio}];
    }
}

- (void)toggleEditingMode:(id)sender {
    if (self.tableView.editing) {
        NSArray *selectedIndexPaths = [self.tableView.indexPathsForSelectedRows copy];
        for (NSIndexPath *indexPath in selectedIndexPaths) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        
        [self setMultipleEditButtonsEnabled:NO];

        self.tableView.allowsMultipleSelectionDuringEditing = NO;
        [self.tableView setEditing:NO animated:YES];

        self.navigationItem.leftBarButtonItem.enabled = YES;

        [UIView animateWithDuration:0.25 animations:^{
            UITextField *searchTextField = [self.searchBar valueForKey:@"_searchField"];
            searchTextField.enabled = YES;
            searchTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;

            self.multiStatusView.alpha = 0;
            self.multipleEditStatusViewTopConstraint.constant = -kToolbarHeight;
            self.multipleEditToolbarBottomConstraint.constant = kToolbarHeight;
            [self.view layoutIfNeeded];
        }];
    }
    else {
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        [self.tableView setEditing:YES animated:YES];

        self.navigationItem.leftBarButtonItem.enabled = NO;

        [UIView animateWithDuration:0.25 animations:^{
            UITextField *searchTextField = [self.searchBar valueForKey:@"_searchField"];
            searchTextField.enabled = NO;
            
            self.multiStatusView.alpha = 1;
            self.multipleEditStatusViewTopConstraint.constant = 0;
            self.multipleEditToolbarBottomConstraint.constant = 0;
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths {
    void (^DeletePostCallback)(NSArray *, NSArray *) = ^(NSArray *indexPathsToRemove, NSArray *indexPathsToAdd) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (NSIndexPath *indexPath in indexPaths) {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
            
            [UIView animateWithDuration:0.25 animations:^{
                UITextField *searchTextField = [self.searchBar valueForKey:@"_searchField"];
                searchTextField.enabled = YES;
                
                CGRect bounds = [[UIScreen mainScreen] bounds];
                CGRect frame = CGRectMake(0, CGRectGetHeight(bounds), CGRectGetWidth(bounds), 44);
            } completion:^(BOOL finished) {
                self.indexPathsToDelete = nil;
            }];
        });
    };

    [self.postDataSource deletePostsAtIndexPaths:indexPaths callback:DeletePostCallback];
}

- (void)multiMarkAsRead:(id)sender {
    NSMutableArray *bookmarksToUpdate = [NSMutableArray array];
    [[self.tableView indexPathsForSelectedRows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = (NSIndexPath *)obj;
        NSDictionary *bookmark = [self.postDataSource postAtIndex:indexPath.row];
        [bookmarksToUpdate addObject:bookmark];
    }];

    [self markPostsAsRead:bookmarksToUpdate];
    [self toggleEditingMode:nil];
}

- (void)multiEdit:(id)sender {
    [[[UIAlertView alloc] initWithTitle:nil message:@"Almost ready to go, but not quite functional yet." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    return;

    NSMutableArray *bookmarksToUpdate = [NSMutableArray array];
    [[self.tableView indexPathsForSelectedRows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = (NSIndexPath *)obj;
        NSDictionary *bookmark = [self.postDataSource postAtIndex:indexPath.row];
        NSArray *tags = [bookmark[@"tags"] componentsSeparatedByString:@" "];
        [tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![bookmarksToUpdate containsObject:obj] && ![obj isEqualToString:@""]) {
                [bookmarksToUpdate addObject:obj];
            }
        }];
    }];
    
    if (self.tableView.editing) {
        [self toggleEditingMode:nil];
    }
    
    PPMultipleEditViewController *vc = [[PPMultipleEditViewController alloc] initWithTags:bookmarksToUpdate];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)multiDelete:(id)sender {
    self.indexPathsToDelete = [self.tableView indexPathsForSelectedRows];

    self.confirmMultipleDeletionActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete these bookmarks?", nil) delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:nil];
    [self.confirmMultipleDeletionActionSheet showInView:self.view];
}

- (void)tagSelected:(id)sender {
}

#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    id <GenericPostDataSource> dataSource = [self dataSourceForTableView:tableView];

    if (!kGenericPostViewControllerIsProcessingPosts) {
        if ([dataSource respondsToSelector:@selector(willDisplayIndexPath:callback:)]) {
            [dataSource willDisplayIndexPath:indexPath callback:^(BOOL needsUpdate) {
                if (needsUpdate) {
                    if (self.tableView == tableView) {
                        [self updateFromLocalDatabaseWithCallback:nil];
                    }
                    else {
                        [self updateSearchResultsForSearchPerformedAtTime:self.latestSearchTime];
                    }
                }
            }];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [self.postDataSource numberOfPosts];
    }
    else {
        return [self.searchPostDataSource numberOfPosts];
    }
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id <GenericPostDataSource> dataSource = [self dataSourceForTableView:tableView];

    PPBadgeWrapperView *badgeWrapperView;
    if (self.compressPosts && [dataSource respondsToSelector:@selector(compressedHeightForPostAtIndex:)]) {
        badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:[dataSource badgesForPostAtIndex:indexPath.row] options:@{ PPBadgeFontSize: @([PPTheme badgeFontSize]) } compressed:YES];
        return [dataSource compressedHeightForPostAtIndex:indexPath.row] + [badgeWrapperView calculateHeightForWidth:CGRectGetWidth(self.tableView.frame) - 20] + 10;
    }

    badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:[dataSource badgesForPostAtIndex:indexPath.row] options:@{ PPBadgeFontSize: @([PPTheme badgeFontSize]) }];
    return [dataSource heightForPostAtIndex:indexPath.row] + [badgeWrapperView calculateHeightForWidth:CGRectGetWidth(self.tableView.frame) - 20] + 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PPBookmarkCell *cell = (PPBookmarkCell *)[tableView dequeueReusableCellWithIdentifier:BookmarkCellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    id <GenericPostDataSource> dataSource = [self dataSourceForTableView:tableView];
    [cell prepareCellWithDataSource:dataSource badgeDelegate:self index:indexPath.row compressed:self.compressPosts];
    return cell;
}

- (void)openActionSheetForSelectedPost {
    if (self.longPressActionSheet) {
        if ([UIApplication isIPad]) {
            [(UIActionSheet *)self.longPressActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
        }
    }
    else {
        NSString *urlString;
        if ([self.selectedPost[@"url"] length] > 67) {
            urlString = [[self.selectedPost[@"url"] substringToIndex:67] stringByAppendingString:ellipsis];
        }
        else {
            urlString = self.selectedPost[@"url"];
        }

        self.longPressActionSheet = [[UIActionSheet alloc] initWithTitle:urlString delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

        PPPostActionType action;
        id <GenericPostDataSource> dataSource = [self currentDataSource];
        NSInteger count = 0;
        NSInteger deleteIndex;

        for (id PPPAction in [dataSource actionsForPost:self.selectedPost]) {
            action = [PPPAction integerValue];

            switch (action) {
                case PPPostActionCopyToMine:
                    [self.longPressActionSheet addButtonWithTitle:NSLocalizedString(@"Copy to mine", nil)];
                    break;
                    
                case PPPostActionCopyURL:
                    [self.longPressActionSheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];
                    break;
                    
                case PPPostActionDelete:
                    [self.longPressActionSheet addButtonWithTitle:NSLocalizedString(@"Delete Bookmark", nil)];
                    deleteIndex = count;
                    break;
                    
                case PPPostActionEdit:
                    [self.longPressActionSheet addButtonWithTitle:NSLocalizedString(@"Edit Bookmark", nil)];
                    break;
                    
                case PPPostActionMarkAsRead:
                    [self.longPressActionSheet addButtonWithTitle:NSLocalizedString(@"Mark as read", nil)];
                    break;
                    
                case PPPostActionReadLater: {
                    PPReadLaterType readLater = [AppDelegate sharedDelegate].readLater;

                    switch (readLater) {
                        case PPReadLaterInstapaper:
                            [self.longPressActionSheet addButtonWithTitle:NSLocalizedString(@"Send to Instapaper", nil)];
                            break;

                        case PPReadLaterReadability:
                            [self.longPressActionSheet addButtonWithTitle:NSLocalizedString(@"Send to Readability", nil)];
                            break;
                            
                        case PPReadLaterPocket:
                            [self.longPressActionSheet addButtonWithTitle:NSLocalizedString(@"Send to Pocket", nil)];
                            break;
                            
                        default:
                            break;
                    }

                    break;
                }
            }

            count++;
        }

        // Properly set the cancel button index
        [self.longPressActionSheet addButtonWithTitle:@"Cancel"];
        self.longPressActionSheet.cancelButtonIndex = self.longPressActionSheet.numberOfButtons - 1;
        self.longPressActionSheet.destructiveButtonIndex = deleteIndex;

        self.actionSheetVisible = YES;
        [self.longPressActionSheet showFromRect:(CGRect){self.selectedPoint, {1, 1}} inView:self.tableView animated:YES];
        self.tableView.scrollEnabled = NO;
    }
}

#pragma mark - UITableViewDelegate

- (void)closeModal:(UIViewController *)sender {
    [self closeModal:sender success:nil];
}

- (void)closeModal:(UIViewController *)sender success:(void (^)())success {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            if (success) {
                success();
            }

            [self updateFromLocalDatabaseWithCallback:nil];
        }];
    });
}

- (void)dismissViewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    if (actionSheet == self.confirmMultipleDeletionActionSheet && self.tableView.editing) {
        [self toggleEditingMode:nil];
    }
    self.tableView.scrollEnabled = YES;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.tableView.scrollEnabled = YES;
    
    if (actionSheet == self.additionalTagsActionSheet) {
        if (buttonIndex >= self.additionalTagsActionSheet.numberOfButtons - 1) {
            self.additionalTagsActionSheet = nil;
            return;
        }

        NSString *tag = [self.additionalTagsActionSheet buttonTitleAtIndex:buttonIndex];
        id <GenericPostDataSource> dataSource = [self currentDataSource];
        if (!self.tableView.editing) {
            if ([dataSource respondsToSelector:@selector(handleTapOnLinkWithURL:callback:)]) {
                [dataSource handleTapOnLinkWithURL:[NSURL URLWithString:[tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                          callback:^(UIViewController *controller) {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  [self.navigationController pushViewController:controller animated:YES];
                                              });
                                          }];
            }
        }

    }
    else if (actionSheet == self.confirmDeletionActionSheet) {
        NSString *title = [self.confirmDeletionActionSheet buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:NSLocalizedString(@"Delete", nil)]) {
            if (self.searchDisplayController.isActive) {
                [self.searchPostDataSource deletePosts:@[self.selectedPost] callback:^(NSIndexPath *indexPath) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.searchDisplayController.searchResultsTableView beginUpdates];
                        [self.searchDisplayController.searchResultsTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                        [self.searchDisplayController.searchResultsTableView endUpdates];
                    });
                }];
            }
            else {
                [self.postDataSource deletePosts:@[self.selectedPost] callback:^(NSIndexPath *indexPath) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                        [self.tableView endUpdates];

                        [self.tableView beginUpdates];
                        [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationTop];
                        [self.tableView endUpdates];
                    });
                }];
            }
        }
    }
    else if (actionSheet == self.confirmMultipleDeletionActionSheet) {
        if (buttonIndex == 0) {
            [self deletePostsAtIndexPaths:self.indexPathsToDelete];
            [self toggleEditingMode:nil];
        }
    }
    else if (actionSheet == self.longPressActionSheet) {
        if (buttonIndex >= 0) {
            NSString *title = [self.longPressActionSheet buttonTitleAtIndex:buttonIndex];
            id <GenericPostDataSource> dataSource = [self currentDataSource];
            
            if ([title isEqualToString:NSLocalizedString(@"Delete Bookmark", nil)]) {
                [self showConfirmDeletionAlert];
            }
            else if ([title isEqualToString:NSLocalizedString(@"Edit Bookmark", nil)]) {
                UIViewController *vc = (UIViewController *)[dataSource editViewControllerForPostAtIndex:self.selectedIndexPath.row];
                
                if ([UIApplication isIPad]) {
                    vc.modalPresentationStyle = UIModalPresentationFormSheet;
                }
                
                [self.navigationController presentViewController:vc animated:YES completion:nil];
            }
            else if ([title isEqualToString:NSLocalizedString(@"Mark as read", nil)]) {
                [self markPostAsRead];
            }
            else if ([title isEqualToString:NSLocalizedString(@"Send to Instapaper", nil)]) {
                [self sendToReadLater];
            }
            else if ([title isEqualToString:NSLocalizedString(@"Send to Readability", nil)]) {
                [self sendToReadLater];
            }
            else if ([title isEqualToString:NSLocalizedString(@"Send to Pocket", nil)]) {
                [self sendToReadLater];
            }
            else if ([title isEqualToString:NSLocalizedString(@"Copy URL", nil)]) {
                [self copyURL];
            }
            else if ([title isEqualToString:NSLocalizedString(@"Copy to mine", nil)]) {
                UIViewController *vc = (UIViewController *)[dataSource addViewControllerForPostAtIndex:self.selectedIndexPath.row];
                
                if ([UIApplication isIPad]) {
                    vc.modalPresentationStyle = UIModalPresentationFormSheet;
                }

                [self.navigationController presentViewController:vc animated:YES completion:nil];
            }
            
            self.longPressActionSheet = nil;
        }
    }
}

#pragma mark - Post Action Methods

- (void)markPostAsRead {
    [self markPostsAsRead:@[self.selectedPost] notify:YES];
}

- (void)markPostsAsRead:(NSArray *)posts {
    [self markPostsAsRead:posts notify:YES];
}

- (void)markPostsAsRead:(NSArray *)posts notify:(BOOL)notify {
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    if (![[delegate connectionAvailable] boolValue]) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = @"Connection unavailable.";
        notification.userInfo = @{@"success": @(NO), @"updated": @(YES)};
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
    else {
        id <GenericPostDataSource> dataSource = [self currentDataSource];

        if ([dataSource respondsToSelector:@selector(markPostAsRead:callback:)]) {
            BOOL __block hasError = NO;
            
            dispatch_group_t group = dispatch_group_create();
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

            UILocalNotification *notification = [[UILocalNotification alloc] init];
            
            // Enumerate all posts
            for (NSDictionary *post in posts) {
                dispatch_group_enter(group);
                [dataSource markPostAsRead:post[@"url"] callback:^(NSError *error) {
                    if (error) {
                        notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                        hasError = YES;
                    }
                    dispatch_group_leave(group);
                }];
            }
            
            // If we have any errors, update the local notification
            if (hasError) {
                notification.alertBody = NSLocalizedString(@"There was an error marking your bookmarks as read.", nil);
                notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
            }
            else {
                notification.userInfo = @{@"success": @(YES), @"updated": @(YES)};
                
                if (posts.count == 1) {
                    notification.alertBody = @"Bookmark marked as read.";
                }
                else {
                    notification.alertBody = [NSString stringWithFormat:@"%d bookmarks marked as read.", posts.count];
                }
            }

            // Once all async tasks are done, present the notification and update the local database
            dispatch_group_notify(group, queue, ^{
                if (notify) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                    });
                }
                
                [self updateFromLocalDatabaseWithCallback:nil];
            });
            
        }
    }
}

- (void)copyURL {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"URL copied to clipboard.", nil);
    notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    [[UIPasteboard generalPasteboard] setString:[self.currentDataSource urlForPostAtIndex:self.selectedIndexPath.row]];
    [[Mixpanel sharedInstance] track:@"Copied URL"];
}

- (void)sendToReadLater {
    PPReadLaterType readLater = [AppDelegate sharedDelegate].readLater;
    NSString *urlString = self.selectedPost[@"url"];
    
    switch (readLater) {
        case PPReadLaterInstapaper: {
            KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"InstapaperOAuth" accessGroup:nil];
            NSString *resourceKey = [keychain objectForKey:(__bridge id)kSecAttrAccount];
            NSString *resourceSecret = [keychain objectForKey:(__bridge id)kSecValueData];
            NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.instapaper.com/api/1/bookmarks/add"]];
            OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kInstapaperKey secret:kInstapaperSecret];
            OAToken *token = [[OAToken alloc] initWithKey:resourceKey secret:resourceSecret];
            OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:token realm:nil signatureProvider:nil];
            [request setHTTPMethod:@"POST"];
            NSMutableArray *parameters = [[NSMutableArray alloc] init];
            [parameters addObject:[OARequestParameter requestParameter:@"url" value:urlString]];
            [request setParameters:parameters];
            [request prepare];
            
            [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                                       NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                       
                                       UILocalNotification *notification = [[UILocalNotification alloc] init];
                                       notification.alertAction = @"Open Pushpin";
                                       if (httpResponse.statusCode == 200) {
                                           notification.alertBody = NSLocalizedString(@"Sent to Instapaper.", nil);
                                           notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
                                           [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Instapaper"}];
                                       }
                                       else if (httpResponse.statusCode == 1221) {
                                           notification.alertBody = NSLocalizedString(@"Publisher opted out of Instapaper compatibility.", nil);
                                           notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                                       }
                                       else {
                                           notification.alertBody = NSLocalizedString(@"Error sending to Instapaper.", nil);
                                           notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                                       }
                                       [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                   }];
            break;
        }
            
        case PPReadLaterReadability: {
            KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ReadabilityOAuth" accessGroup:nil];
            NSString *resourceKey = [keychain objectForKey:(__bridge id)kSecAttrAccount];
            NSString *resourceSecret = [keychain objectForKey:(__bridge id)kSecValueData];
            NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.readability.com/api/rest/v1/bookmarks"]];
            OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kReadabilityKey secret:kReadabilitySecret];
            OAToken *token = [[OAToken alloc] initWithKey:resourceKey secret:resourceSecret];
            OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:token realm:nil signatureProvider:nil];
            [request setHTTPMethod:@"POST"];
            [request setParameters:@[[OARequestParameter requestParameter:@"url" value:urlString]]];
            [request prepare];
            
            [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                                       UILocalNotification *notification = [[UILocalNotification alloc] init];
                                       notification.alertAction = @"Open Pushpin";
                                       
                                       NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                       if (httpResponse.statusCode == 202) {
                                           notification.alertBody = @"Sent to Readability.";
                                           notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
                                           [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Readability"}];
                                       }
                                       else if (httpResponse.statusCode == 409) {
                                           notification.alertBody = @"Link already sent to Readability.";
                                           notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                                       }
                                       else {
                                           notification.alertBody = @"Error sending to Readability.";
                                           notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                                       }
                                       [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                   }];
            break;
        }
            
        case PPReadLaterPocket:
            [[PocketAPI sharedAPI] saveURL:[NSURL URLWithString:urlString]
                                 withTitle:self.selectedPost[@"title"]
                                   handler:^(PocketAPI *api, NSURL *url, NSError *error) {
                                       if (!error) {
                                           UILocalNotification *notification = [[UILocalNotification alloc] init];
                                           notification.alertBody = @"Sent to Pocket.";
                                           notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
                                           [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                           
                                           [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Pocket"}];
                                       }
                                   }];
            
        default:
            break;
    }
}

- (void)showConfirmDeletionAlert {
    self.confirmDeletionAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil) message:NSLocalizedString(@"Are you sure you want to delete this bookmark?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
    [self.confirmDeletionAlertView show];
}

- (void)showConfirmDeletionActionSheet {
    self.confirmDeletionActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete this bookmark?", nil) delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:nil];
    [self.confirmDeletionActionSheet showInView:self.view];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if (alertView == self.confirmDeletionAlertView) {
        if ([title isEqualToString:NSLocalizedString(@"Yes", nil)]) {
            // We're only deleting one bookmark in this case.
            if (self.searchDisplayController.isActive) {
                [self.searchPostDataSource deletePosts:@[self.selectedPost] callback:^(NSIndexPath *indexPath) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.searchDisplayController.searchResultsTableView beginUpdates];
                        [self.searchDisplayController.searchResultsTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                        [self.searchDisplayController.searchResultsTableView endUpdates];
                    });
                }];
            }
            else {
                [self.postDataSource deletePosts:@[self.selectedPost] callback:^(NSIndexPath *indexPath) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                        [self.tableView endUpdates];
                    });
                }];
            }
        }
        else if ([title isEqualToString:NSLocalizedString(@"No", nil)]) {
            // Dismiss the edit view
            [self.tableView setEditing:NO animated:YES];
        }
    }
    else if (alertView == self.confirmMultipleDeletionAlertView) {
        if ([title isEqualToString:NSLocalizedString(@"Yes", nil)]) {
            [self deletePostsAtIndexPaths:self.indexPathsToDelete];
        }
        
        [self toggleEditingMode:nil];
    }
}

#pragma mark - Scroll View delegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (!self.tableView.editing && !kGenericPostViewControllerIsProcessingPosts && !self.searchDisplayController.isActive) {
        CGFloat offset = scrollView.contentOffset.y;
        CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
        CGFloat navigationHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
        CGFloat searchHeight = CGRectGetHeight(self.searchBar.frame);
        CGFloat minimumOffset = statusBarHeight + navigationHeight;
        if (offset < -(minimumOffset + CGRectGetHeight(self.pullToRefreshImageView.frame) + 20)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.5 animations:^{
                    [self.pullToRefreshImageView startAnimating];
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.5 animations:^{
                        // Calculate the update ratio
                        CGFloat updateBasis = (minimumOffset + searchHeight);
                        NSNumber *updateRatio = @(MIN((-offset - updateBasis) / 80, 1));
                        [self updateWithRatio:updateRatio];
                    }];
                }];
            });
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!kGenericPostViewControllerIsProcessingPosts) {
        CGFloat offset = scrollView.contentOffset.y;
        self.pullToRefreshTopConstraint.constant = -offset;
        [self.view layoutIfNeeded];

        NSInteger index = MAX(1, 32 - MIN(-offset / 60 * 32, 32));
        NSString *imageName = [NSString stringWithFormat:@"ptr_%02ld", (long)index];
        
        if (offset < 0) {
            offset = -60;

            self.pullToRefreshImageView.image = [UIImage imageNamed:imageName];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (![searchText isEqualToString:@""]) {
        [self resetSearchTimer];
    }
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    if (![searchBar.text isEqualToString:@""]) {
        [self resetSearchTimer];
    }
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return YES;
}

- (void)resetSearchTimer {

    NSDate *time = [NSDate date];
    if ([time compare:self.latestSearchTime]) {
        self.latestSearchTime = time;

        if (self.latestSearchTimer) {
            [self.latestSearchTimer invalidate];
            self.latestSearchTimer = nil;
        }
        
        CGFloat interval;
        if (self.searchBar.selectedScopeButtonIndex == PPSearchFullText) {
            interval = 0.6;
        }
        else {
            interval = 0.1;
        }

        self.latestSearchText = [self.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.latestSearchTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(searchTimerFired:) userInfo:@{@"time": time} repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.latestSearchTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)searchTimerFired:(NSTimer *)timer {
    NSString *query;
    switch (self.searchBar.selectedScopeButtonIndex) {
        case PPSearchTitles:
            query = [NSString stringWithFormat:@"title:\"%@\"", self.latestSearchText];
            break;

        case PPSearchDescriptions:
            query = [NSString stringWithFormat:@"description:\"%@\"", self.latestSearchText];
            break;

        case PPSearchTags: {
            query = [NSString stringWithFormat:@"tags:\"%@\"", self.latestSearchText];
            break;
        }

        default:
            query = self.latestSearchText;
            break;
    }

    [self.searchPostDataSource filterWithQuery:query];

    if ([self.searchPostDataSource respondsToSelector:@selector(shouldSearchFullText)]) {
        self.searchPostDataSource.shouldSearchFullText = self.searchBar.selectedScopeButtonIndex == PPSearchFullText;
    }

    [self updateSearchResultsForSearchPerformedAtTime:timer.userInfo[@"time"]];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self updateSearchResultsForSearchPerformedAtTime:self.latestSearchTime];
}

#pragma mark - UISearchDisplayControllerDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return NO;
}

- (void)removeBarButtonTouchUpside:(id)sender {
    __weak GenericPostViewController *weakself = self;
    [self.postDataSource removeDataSource:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.alertBody = NSLocalizedString(@"Removed from saved feeds.", nil);
            notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];

            weakself.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:weakself action:@selector(addBarButtonTouchUpside:)];
        });
    }];
}

- (void)addBarButtonTouchUpside:(id)sender {
    __weak GenericPostViewController *weakself = self;
    [self.postDataSource addDataSource:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.alertBody = NSLocalizedString(@"Added to saved feeds.", nil);
            notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];

            weakself.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStylePlain target:weakself action:@selector(removeBarButtonTouchUpside:)];
        });
    }];
}

- (id<GenericPostDataSource>)dataSourceForTableView:(UITableView *)tableView {
    id <GenericPostDataSource> dataSource;
    if (tableView == self.tableView) {
        dataSource = self.postDataSource;
    }
    else {
        dataSource = self.searchPostDataSource;
    }
    return dataSource;
}

- (id<GenericPostDataSource>)currentDataSource {
    id <GenericPostDataSource> dataSource;
    if (self.searchDisplayController.isActive) {
        dataSource = self.searchPostDataSource;
    }
    else {
        dataSource = self.postDataSource;
    }
    return dataSource;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (!kGenericPostViewControllerIsProcessingPosts) {
        kGenericPostViewControllerIsProcessingPosts = YES;
        if ([self.postDataSource respondsToSelector:@selector(resetHeightsWithSuccess:)]) {
            [self.postDataSource resetHeightsWithSuccess:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    kGenericPostViewControllerIsProcessingPosts = NO;
                });
            }];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortrait;
}

#pragma mark -
#pragma mark iOS 7 Updates

- (void)preferredContentSizeChanged:(NSNotification *)aNotification {
    if (!kGenericPostViewControllerIsProcessingPosts) {
        kGenericPostViewControllerIsProcessingPosts = YES;

        [self.postDataSource updatePostsFromDatabaseWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                [self performTableViewUpdatesWithInserts:nil reloads:[self.tableView indexPathsForVisibleRows] deletes:nil];
                [self.view setNeedsLayout];
                kGenericPostViewControllerIsProcessingPosts = NO;
            });
        } failure:^(NSError *error) {
            kGenericPostViewControllerIsProcessingPosts = NO;
        }];
    }
}

#pragma mark - PPBadgeWrapperDelegate

- (void)badgeWrapperView:(PPBadgeWrapperView *)badgeWrapperView didSelectBadge:(PPBadgeView *)badge {
    NSArray *badgeViews = badgeWrapperView.subviews;
    NSMutableArray *badges = [badgeWrapperView.badges mutableCopy];

    NSUInteger visibleBadgeCount = [badgeViews indexesOfObjectsPassingTest:^BOOL(UIView *badgeView, NSUInteger idx, BOOL *stop) {
        return !badgeView.hidden;
    }].count;

    [badges removeObjectsInRange:NSMakeRange(0, visibleBadgeCount - 1)];
    if (badges.count > 5) {
        [badges removeObjectsInRange:NSMakeRange(5, badges.count - 5)];
    }

    NSString *tag = badge.textLabel.text;
    if (![tag isEqualToString:emptyString]) {
        if ([tag isEqualToString:ellipsis] && badgeViews.count > 0) {
            // Show more tag options
            self.additionalTagsActionSheet = [[UIActionSheet alloc] initWithTitle:@"Additional Tags" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

            for (NSDictionary *badge in badges) {
                if ([badge[@"type"] isEqualToString:@"tag"]) {
                    [self.additionalTagsActionSheet addButtonWithTitle:badge[@"tag"]];
                }
            }

            // Properly set the cancel button index
            [self.additionalTagsActionSheet addButtonWithTitle:@"Cancel"];
            self.additionalTagsActionSheet.cancelButtonIndex = self.additionalTagsActionSheet.numberOfButtons - 1;
            self.actionSheetVisible = YES;

            CGPoint point = CGPointMake(badge.center.x - 2, badge.center.y);
            [self.additionalTagsActionSheet showFromRect:(CGRect){point, {1, 1}} inView:badgeWrapperView animated:YES];
            self.tableView.scrollEnabled = NO;
        }
        else {
            // Go to the tag link
            id <GenericPostDataSource> dataSource = [self currentDataSource];
            if (!self.tableView.editing) {
                if ([dataSource respondsToSelector:@selector(handleTapOnLinkWithURL:callback:)]) {
                    // We need to percent escape all tags, since some contain unicode characters which will cause NSURL to be nil
                    [dataSource handleTapOnLinkWithURL:[NSURL URLWithString:[tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                              callback:^(UIViewController *controller) {
                                                  [self.navigationController pushViewController:controller animated:YES];
                                              }];
                }
            }
        }
    }
}

#pragma mark - PPTitleButtonDelegate

- (void)titleButtonTouchUpInside:(PPTitleButton *)titleButton {
    [self toggleCompressedPosts];
}

- (void)toggleCompressedPosts {
    if (!kGenericPostViewControllerIsProcessingPosts) {
        kGenericPostViewControllerIsProcessingPosts = YES;
        
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        // For some reason, the first row is hidden, *unless* the first visible row is the one at the top of the table

        NSInteger row;
        if ([(NSIndexPath *)visibleIndexPaths[0] row] == 0) {
            row = 0;
        }
        else {
            row = 1;
        }

        NSIndexPath *currentIndexPath = visibleIndexPaths[row];

        self.compressPosts = !self.compressPosts;

        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];

        double delayInSeconds = 0.25;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (self.tableView.contentOffset.y > 0) {
                [self.tableView scrollToRowAtIndexPath:currentIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
            kGenericPostViewControllerIsProcessingPosts = NO;
        });
    }
}

- (void)setMultipleEditButtonsEnabled:(BOOL)enabled {
    if (enabled) {
        self.multipleDeleteButton.enabled = YES;
        self.multipleTagEditButton.enabled = NO;
        self.multipleMarkAsReadButton.enabled = YES;
    }
    else {
        self.multipleDeleteButton.enabled = NO;
        self.multipleTagEditButton.enabled = NO;
        self.multipleMarkAsReadButton.enabled = NO;
    }
}

- (void)performTableViewUpdatesWithInserts:(NSArray *)indexPathsToInsert
                                   reloads:(NSArray *)indexPathsToReload
                                   deletes:(NSArray *)indexPathsToDelete {
    
    if (kGenericPostViewControllerPerformAtomicUpdates) {
        [self.tableView beginUpdates];
        if (indexPathsToReload) {
            [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
        }
        
        if (indexPathsToDelete) {
            [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
        }
        
        if (indexPathsToInsert) {
            [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
        }

        [self.tableView endUpdates];
    }
    else {
        [self.tableView reloadData];
    }
}

- (void)bookmarkCellDidActivateDeleteButton:(PPBookmarkCell *)cell forIndex:(NSInteger)index {
    self.selectedPost = [self.postDataSource postAtIndex:index];
    [self showConfirmDeletionAlert];
}

- (void)bookmarkCellDidActivateEditButton:(PPBookmarkCell *)cell forIndex:(NSInteger)index {
    UIViewController *vc = (UIViewController *)[self.currentDataSource editViewControllerForPostAtIndex:index];
    
    if ([UIApplication isIPad]) {
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self.navigationController presentViewController:vc animated:YES completion:nil];
}

- (BOOL)bookmarkCellCanSwipe:(PPBookmarkCell *)cell {
    return ([self.postDataSource respondsToSelector:@selector(deletePostsAtIndexPaths:callback:)]);
}

@end
