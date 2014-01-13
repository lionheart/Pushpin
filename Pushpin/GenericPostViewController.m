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
static NSString *BookmarkCellIdentifier = @"BookmarkCellIdentifier";
static NSInteger kToolbarHeight = 44;

@interface GenericPostViewController ()

@property (nonatomic, strong) UIButton *multipleMarkAsReadButton;
@property (nonatomic, strong) UIButton *multipleTagEditButton;
@property (nonatomic, strong) UIButton *multipleDeleteButton;
@property (nonatomic, strong) UIActionSheet *confirmDeletionActionSheet;
@property (nonatomic, strong) UIActionSheet *confirmMultipleDeletionActionSheet;
@property (nonatomic, strong) NSLayoutConstraint *multipleEditToolbarBottomConstraint;
@property (nonatomic, retain) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *searchDisplayLongPressGestureRecognizer;
@property (nonatomic, strong) NSArray *indexPathsToDelete;
@property (nonatomic) BOOL prefersStatusBarHidden;
@property (nonatomic, strong) NSDate *latestSearchTime;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) NSString *formattedSearchString;
@property (nonatomic, strong) NSTimer *fullTextSearchTimer;

@property (nonatomic, strong) NSLayoutConstraint *pullToRefreshBottomConstraint;
@property (nonatomic, strong) NSInvocation *invocation;

- (void)showConfirmDeletionActionSheet;
- (void)toggleCompressedPosts;
- (void)setMultipleEditButtonsEnabled:(BOOL)enabled;
- (void)performTableViewUpdatesWithInserts:(NSArray *)indexPathsToInsert reloads:(NSArray *)indexPathsToReload deletes:(NSArray *)indexPathsToDelete;
- (void)didReceiveDisplaySettingsUpdateNotification:(NSNotification *)notification;
- (void)updateTitleViewText;
- (CGFloat)currentWidth;
- (CGFloat)currentWidthForOrientation:(UIInterfaceOrientation)orientation;

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

    self.view.backgroundColor = [UIColor whiteColor];
    self.prefersStatusBarHidden = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.actionSheetVisible = NO;
    self.latestSearchTime = [NSDate date];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.separatorColor = HEX(0xE0E0E0ff);
    self.tableView.frame = CGRectOffset(self.view.frame, 0, CGRectGetHeight(self.view.frame));
    
    self.pullToRefreshView = [[UIView alloc] init];
    self.pullToRefreshView.translatesAutoresizingMaskIntoConstraints = NO;
    self.pullToRefreshView.clipsToBounds = YES;
    self.pullToRefreshView.backgroundColor = [UIColor whiteColor];

    self.pullToRefreshImageView = [[PPLoadingView alloc] init];
    self.pullToRefreshImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.pullToRefreshImageView.backgroundColor = [UIColor whiteColor];
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
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.pullToRefreshView];
    [self.view addSubview:self.multiToolbarView];

    NSDictionary *toolbarViews = @{ @"border": multiToolbarBorderView,
                                    @"read": self.multipleMarkAsReadButton,
                                    @"edit": self.multipleTagEditButton,
                                    @"delete": self.multipleDeleteButton };

    [self.multiToolbarView lhs_addConstraints:@"H:|[read][delete(==read)]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[read]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[delete]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"H:|[border]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[border(0.5)]" views:toolbarViews];

    NSDictionary *views = @{@"toolbarView": self.multiToolbarView,
                            @"ptr": self.pullToRefreshView,
                            @"image": self.pullToRefreshImageView,
                            @"table": self.tableView,
                            @"top": self.topLayoutGuide,
                            @"bottom": self.bottomLayoutGuide };
    
    [self.pullToRefreshView lhs_addConstraints:@"V:|-10-[image(40)]" views:views];
    [self.pullToRefreshView lhs_centerHorizontallyForView:self.pullToRefreshImageView];

    [self.view lhs_addConstraints:@"H:|[ptr]|" views:views];
    [self.view lhs_addConstraints:@"H:|[toolbarView]|" views:views];
    [self.view lhs_addConstraints:@"V:[toolbarView(height)]" metrics:@{ @"height": @(kToolbarHeight) } views:views];

    // Initial database update
    [self.tableView registerClass:[PPBookmarkCell class] forCellReuseIdentifier:BookmarkCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

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

    if (![self.view.constraints containsObject:self.multipleEditToolbarBottomConstraint]) {
        self.multipleEditToolbarBottomConstraint = [NSLayoutConstraint constraintWithItem:self.multiToolbarView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:kToolbarHeight];
        [self.view addConstraint:self.multipleEditToolbarBottomConstraint];
    }
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     }];
    
    UIViewController *backViewController = (self.navigationController.viewControllers.count >= 2) ? self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2] : nil;

    if (![UIApplication isIPad] && [backViewController isKindOfClass:[FeedListViewController class]]) {
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Register for Dynamic Type notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveDisplaySettingsUpdateNotification:) name:PPBookmarkDisplaySettingUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleCompressedPosts) name:PPBookmarkCompressSettingUpdate object:nil];

    self.compressPosts = [AppDelegate sharedDelegate].compressPosts;

    if ([self.postDataSource numberOfPosts] == 0) {
        [self.pullToRefreshImageView startAnimating];
        if ([AppDelegate sharedDelegate].bookmarksNeedUpdate) {
            [AppDelegate sharedDelegate].bookmarksNeedUpdate = NO;
            [self.postDataSource updateBookmarksWithSuccess:^{
                [self updateFromLocalDatabaseWithCallback:nil];
            } failure:nil progress:nil options:@{@"ratio": @(1.0) }];
        }
        else {
            [self updateFromLocalDatabaseWithCallback:nil];
        }
    }
    else {
        [self updateFromLocalDatabaseWithCallback:^{
            [self.tableView reloadData];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[AppDelegate sharedDelegate] setCompressPosts:self.compressPosts];
}

- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveDisplaySettingsUpdateNotification:(NSNotification *)notification {
    [self updateFromLocalDatabaseWithCallback:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
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

        [self updateTitleViewText];
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
            [self updateTitleViewText];
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

                            [self.searchDisplayController.searchContentsController.navigationController setNavigationBarHidden:YES animated:NO];
                            [self.navigationController setNavigationBarHidden:YES animated:NO];
                            
                            if ([self.navigationController topViewController] == self) {
                                [self.navigationController pushViewController:self.webViewController animated:YES];
                                [self.navigationController setNavigationBarHidden:YES animated:NO];
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
}

- (void)updateFromLocalDatabaseWithCallback:(void (^)())callback {
    if (!kGenericPostViewControllerIsProcessingPosts) {
        kGenericPostViewControllerIsProcessingPosts = YES;
        CGFloat width = [self currentWidth];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.postDataSource bookmarksWithSuccess:^(NSArray *indexPathsToInsert, NSArray *indexPathsToReload, NSArray *indexPathsToDelete) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL alreadyContainsBookmarks = [self.view.constraints containsObject:self.pullToRefreshBottomConstraint];
                    if (alreadyContainsBookmarks) {
                        [self.tableView beginUpdates];
                        [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView endUpdates];
                    }
                    else {
                        [self.tableView reloadData];

                        self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
                        self.animator.delegate = self;
                        
                        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[self.tableView]];
                        collision.collisionMode = UICollisionBehaviorModeBoundaries;
                        [collision addBoundaryWithIdentifier:@"top" fromPoint:CGPointMake(0, -1) toPoint:CGPointMake(width, -1)];

                        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[self.tableView]];
                        gravity.gravityDirection = CGVectorMake(0, -4);
                        
                        UIPushBehavior *push = [[UIPushBehavior alloc] initWithItems:@[self.tableView] mode:UIPushBehaviorModeInstantaneous];
                        push.pushDirection = CGVectorMake(0, -200);
                        
                        [self.animator addBehavior:collision];
                        [self.animator addBehavior:gravity];
                        [self.animator addBehavior:push];
                    }
                    
                    if ([self.postDataSource respondsToSelector:@selector(searchDataSource)] && !self.searchPostDataSource) {
                        self.searchPostDataSource = [self.postDataSource searchDataSource];
                        
                        self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
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
                    }
                    
                    kGenericPostViewControllerIsProcessingPosts = NO;
                    
                    if (callback) {
                        callback();
                    }
                });
            } failure:nil width:width];
        });
    }
}

- (void)updateSearchResultsForSearchPerformedAtTime:(NSDate *)time {
    if (!self.searchLoading) {
        self.searchLoading = YES;

        self.searchPostDataSource.shouldSearchFullText = self.searchBar.selectedScopeButtonIndex == PPSearchFullText && [self.searchPostDataSource respondsToSelector:@selector(shouldSearchFullText)];

        [self.searchPostDataSource filterWithQuery:self.formattedSearchString];

        if (self.searchPostDataSource.shouldSearchFullText) {
            [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
        }

        __weak GenericPostViewController *weakself = self;
        [self.searchPostDataSource bookmarksWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
            if (weakself.searchPostDataSource.shouldSearchFullText) {
                [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.searchDisplayController.searchResultsTableView reloadData];
                weakself.searchLoading = NO;
            });
        } failure:^(NSError *error) {
            weakself.searchLoading = NO;
            
            if (weakself.searchPostDataSource.shouldSearchFullText) {
                [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
            }
        } cancel:^(BOOL *stop) {
            *stop = [time compare:weakself.latestSearchTime] != NSOrderedSame;
        } width:[self currentWidth]];
    }
}

- (void)updateWithRatio:(NSNumber *)ratio {
    if (!kGenericPostViewControllerIsProcessingPosts) {
        kGenericPostViewControllerIsProcessingPosts = YES;
        [self.postDataSource updateBookmarksWithSuccess:^{
            [self.postDataSource bookmarksWithSuccess:^(NSArray *indexPathsToInsert, NSArray *indexPathsToReload, NSArray *indexPathsToDelete) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView beginUpdates];
                    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];

                    [self.pullToRefreshImageView stopAnimating];
                    [UIView animateWithDuration:0.3 animations:^{
                        self.pullToRefreshBottomConstraint.constant = 0;
                        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                        [self.view layoutIfNeeded];
                    } completion:^(BOOL finished) {
                        [self.pullToRefreshImageView stopAnimating];
                    }];
                    kGenericPostViewControllerIsProcessingPosts = NO;
                });
            } failure:nil width:[self currentWidth]];
        } failure:nil progress:nil options:@{@"ratio": ratio}];
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
        [self.navigationItem setRightBarButtonItem:self.editButton animated:YES];
        
        if ([self.postDataSource respondsToSelector:@selector(titleViewWithDelegate:)]) {
            PPTitleButton *titleView = (PPTitleButton *)[self.postDataSource titleViewWithDelegate:self];
            self.navigationItem.titleView = titleView;
        }
        else {
            self.navigationItem.titleView = nil;
        }

        [UIView animateWithDuration:0.25 animations:^{

            UITextField *searchTextField = [self.searchBar valueForKey:@"_searchField"];
            searchTextField.enabled = YES;
            searchTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;

            self.multipleEditToolbarBottomConstraint.constant = kToolbarHeight;
            [self.view layoutIfNeeded];
        }];
    }
    else {
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        [self.tableView setEditing:YES animated:YES];

        self.navigationItem.leftBarButtonItem.enabled = NO;
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(toggleEditingMode:)] animated:YES];
        
        [self updateTitleViewText];

        [UIView animateWithDuration:0.25 animations:^{

            UITextField *searchTextField = [self.searchBar valueForKey:@"_searchField"];
            searchTextField.enabled = NO;

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
                        [self updateSearchResultsForSearchPerformedAtTime:[self.latestSearchTime copy]];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.compressPosts && [self.currentDataSource respondsToSelector:@selector(compressedHeightForPostAtIndex:)]) {
        return [self.currentDataSource compressedHeightForPostAtIndex:indexPath.row];
    }

    return [self.currentDataSource heightForPostAtIndex:indexPath.row];
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

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

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
                    notification.alertBody = [NSString stringWithFormat:@"%lu bookmarks marked as read.", (unsigned long)posts.count];
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

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!self.tableView.editing && !kGenericPostViewControllerIsProcessingPosts) {
        CGFloat offset = scrollView.contentOffset.y;
        if (offset <= -60) {
            [self.pullToRefreshImageView startAnimating];
            
            [UIView animateWithDuration:0.3 animations:^{
                self.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
            }];
            
            [self updateWithRatio:@(0.2)];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offset = scrollView.contentOffset.y;
    
    if (offset <= 0) {
        self.pullToRefreshBottomConstraint.constant = -offset;
        [self.view layoutIfNeeded];

        if (!kGenericPostViewControllerIsProcessingPosts) {
            NSInteger index = MAX(1, 32 - MIN(-offset / 60 * 32, 32));
            NSString *imageName = [NSString stringWithFormat:@"ptr_%02ld", (long)index];
            self.pullToRefreshImageView.image = [UIImage imageNamed:imageName];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (![searchText isEqualToString:@""]) {
        switch (self.searchBar.selectedScopeButtonIndex) {
            case PPSearchTitles:
                self.formattedSearchString = [NSString stringWithFormat:@"title:\"%@\"", searchText];
                break;
                
            case PPSearchDescriptions:
                self.formattedSearchString = [NSString stringWithFormat:@"description:\"%@\"", searchText];
                break;
                
            case PPSearchTags:
                self.formattedSearchString = [NSString stringWithFormat:@"tags:\"%@\"", searchText];
                break;
                
            default:
                self.formattedSearchString = searchText;
                break;
        }

        BOOL shouldSearchFullText = NO;
        if ([self.searchPostDataSource respondsToSelector:@selector(shouldSearchFullText)]) {
            shouldSearchFullText = self.searchBar.selectedScopeButtonIndex == PPSearchFullText;
        }

        self.latestSearchTime = [NSDate date];
        if (shouldSearchFullText) {
            // Put this on a timer, since we don't want to kill Pinboard servers.
            if (self.fullTextSearchTimer) {
                [self.fullTextSearchTimer invalidate];
            }
            
            NSMethodSignature *signature = [self methodSignatureForSelector:@selector(updateSearchResultsForSearchPerformedAtTime:)];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            invocation.selector = @selector(updateSearchResultsForSearchPerformedAtTime:);
            invocation.target = self;
            [invocation setArgument:(__bridge void *)(self.latestSearchTime) atIndex:0];

            self.fullTextSearchTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 invocation:invocation repeats:NO];
        }
        else {
            [self updateSearchResultsForSearchPerformedAtTime:[self.latestSearchTime copy]];
        }
    }
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    if (![searchBar.text isEqualToString:@""]) {
        [self updateSearchResultsForSearchPerformedAtTime:[self.latestSearchTime copy]];
    }
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return YES;
}

#pragma mark - UISearchDisplayControllerDelegate

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    [self.view layoutIfNeeded];
}

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
        [self.postDataSource bookmarksWithSuccess:^(NSArray *indexPathsToInsert, NSArray *indexPathsToReload, NSArray *indexPathsToDelete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                kGenericPostViewControllerIsProcessingPosts = NO;
            });
        } failure:nil width:[self currentWidth]];
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

        [self.postDataSource bookmarksWithSuccess:^(NSArray *indexPathsToInsert, NSArray *indexPathsToReload, NSArray *indexPathsToDelete) {
            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];

                kGenericPostViewControllerIsProcessingPosts = NO;
            });
        } failure:^(NSError *error) {
            kGenericPostViewControllerIsProcessingPosts = NO;
        } width:[self currentWidth]];
    }
}

#pragma mark - PPBadgeWrapperDelegate

- (void)badgeWrapperView:(PPBadgeWrapperView *)badgeWrapperView didSelectBadge:(PPBadgeView *)badge {
    if (self.tableView.editing) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:badgeWrapperView.tag inSection:0];
        if ([self.tableView.indexPathsForSelectedRows containsObject:indexPath]) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        else {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    else {
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
}

#pragma mark - PPTitleButtonDelegate

- (void)titleButtonTouchUpInside:(PPTitleButton *)titleButton {
    [self toggleCompressedPosts];
}

- (void)toggleCompressedPosts {
    if (!kGenericPostViewControllerIsProcessingPosts) {
        kGenericPostViewControllerIsProcessingPosts = YES;
        
        NSArray *indexPathsForVisibleRows = [self.tableView indexPathsForVisibleRows];
        NSArray *indexPathsToReload = [indexPathsForVisibleRows filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSIndexPath *indexPath, NSDictionary *bindings) {
            return [self.currentDataSource heightForPostAtIndex:indexPath.row] != [self.currentDataSource compressedHeightForPostAtIndex:indexPath.row];
        }]];

        if (indexPathsToReload.count > 0) {
            // For some reason, the first row is hidden, *unless* the first visible row is the one at the top of the table

            NSInteger row;
            if ([(NSIndexPath *)indexPathsForVisibleRows[0] row] == 0 || ![indexPathsToReload isEqual:indexPathsForVisibleRows[0]]) {
                row = 0;
            }
            else {
                row = 1;
            }

            NSIndexPath *currentIndexPath = indexPathsForVisibleRows[row];

            self.compressPosts = !self.compressPosts;

            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
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
        else {
            kGenericPostViewControllerIsProcessingPosts = NO;
        }
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

#pragma mark - UIDynamicAnimatorDelegate

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    if (animator == self.animator && ![self.view.constraints containsObject:self.pullToRefreshBottomConstraint]) {
        self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

        NSDictionary *views = @{@"ptr": self.pullToRefreshView,
                                @"table": self.tableView,
                                @"top": self.topLayoutGuide,
                                @"bottom": self.bottomLayoutGuide };

        self.pullToRefreshBottomConstraint = [NSLayoutConstraint constraintWithItem:self.pullToRefreshView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0];
        [self.view addConstraint:self.pullToRefreshBottomConstraint];
        [self.view lhs_addConstraints:@"V:[top]-(<=0)-[ptr(>=60)]" views:views];
        [self.view lhs_addConstraints:@"V:[top][table][bottom]" views:views];
        [self.view lhs_addConstraints:@"H:|[table]|" views:views];
        [self.view layoutIfNeeded];
    }
}

- (void)updateTitleViewText {
    NSInteger selectedRowCount = [self.tableView indexPathsForSelectedRows].count;
    PPTitleButton *button = [PPTitleButton button];
    
    NSString *title;
    if (selectedRowCount == 1) {
        title = @"1 bookmark selected";
    }
    else {
        title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedRowCount, NSLocalizedString(@"bookmarks selected", nil)];
    }
    
    [button setTitle:title imageName:nil];
    self.navigationItem.titleView = button;
}

- (CGFloat)currentWidth {
    return [self currentWidthForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (CGFloat)currentWidthForOrientation:(UIInterfaceOrientation)orientation {
    CGFloat width;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        width = MIN(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    }
    else {
        width = MAX(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    }
    return width;
}

@end
