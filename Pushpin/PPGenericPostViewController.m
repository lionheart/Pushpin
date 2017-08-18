//
//  GenericPostViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

@import QuartzCore;
@import FMDB;
@import ASPinboard;
@import KeychainItemWrapper;
@import LHSCategoryCollection;
@import Mixpanel;
@import SafariServices;

#import "PPGenericPostViewController.h"
#import "PPConstants.h"
#import "PPSettings.h"
#import "PPUtilities.h"
#import "PPPinboardDataSource.h"
#import "PPBadgeWrapperView.h"
#import "PPMultipleEditViewController.h"
#import "PPFeedListViewController.h"
#import "PPTheme.h"
#import "PPActivityViewController.h"
#import "PPAddBookmarkViewController.h"
#import "PPNavigationController.h"
#import "PPShrinkBackTransition.h"
#import "PPNotification.h"
#import "PPSplitViewController.h"
#import "PPMailChimp.h"

#import "NSAttributedString+Attributes.h"
#import "NSString+URLEncoding2.h"

static NSString *BookmarkCellIdentifier = @"BookmarkCellIdentifier";
static NSInteger kToolbarHeight = 44;
static NSInteger PPBookmarkEditMaximum = 25;

@interface PPGenericPostViewController ()

@property (nonatomic, strong) UIBarButtonItem *hamburgerBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *selectAllBarButtonItem;

@property (nonatomic, strong) UIButton *multipleMarkAsReadButton;
@property (nonatomic, strong) UIButton *multipleTagEditButton;
@property (nonatomic, strong) UIButton *multipleDeleteButton;

@property (nonatomic, strong) UIAlertController *confirmDeletionActionSheet;
@property (nonatomic, strong) UIAlertController *confirmMultipleDeletionActionSheet;

@property (nonatomic, strong) NSLayoutConstraint *multipleEditToolbarBottomConstraint;
@property (nonatomic, retain) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) NSArray *indexPathsToDelete;
@property (nonatomic) BOOL prefersStatusBarHidden;
@property (nonatomic, strong) NSDate *latestSearchTime;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) NSString *formattedSearchString;
@property (nonatomic, strong) NSTimer *fullTextSearchTimer;
@property (nonatomic) BOOL isProcessingPosts;
@property (nonatomic) BOOL viewIsAppearing;

@property (nonatomic, strong) NSLayoutConstraint *tableViewPinnedToTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *tableViewPinnedToBottomConstraint;
@property (nonatomic, strong) NSInvocation *invocation;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) PPActivityViewController *activityView;
@property (nonatomic, strong) UIKeyCommand *focusSearchKeyCommand;
@property (nonatomic, strong) UIKeyCommand *toggleCompressKeyCommand;
@property (nonatomic, strong) UIKeyCommand *escapeKeyCommand;
@property (nonatomic, strong) UIKeyCommand *moveUpKeyCommand;
@property (nonatomic, strong) UIKeyCommand *moveDownKeyCommand;
@property (nonatomic, strong) UIKeyCommand *openKeyCommand;
@property (nonatomic, strong) UIKeyCommand *editKeyCommand;
@property (nonatomic, strong) UIKeyCommand *enterKeyCommand;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic, strong) UIView *circle;
@property (nonatomic, strong) UISnapBehavior *circleSnapBehavior;
@property (nonatomic, strong) NSTimer *circleHideTimer;

@property (nonatomic, strong) PPTableViewController *searchResultsController;
@property (nonatomic, strong) UISearchController *searchController;

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand;

- (void)showConfirmDeletionActionSheet;
- (void)toggleCompressedPosts;
- (void)setMultipleEditButtonsEnabled:(BOOL)enabled;
- (void)didReceiveDisplaySettingsUpdateNotification:(NSNotification *)notification;
- (void)updateMultipleEditUI;
- (void)updateTitleViewText;
- (CGFloat)currentWidth;
- (CGFloat)currentWidthForOrientation:(UIInterfaceOrientation)orientation;

- (void)updateFromLocalDatabase;
- (void)updateFromLocalDatabaseWithCallback:(void (^)())callback;
- (void)updateFromLocalDatabaseWithCallback:(void (^)())callback time:(NSDate *)time;
- (void)updateSearchResultsForSearchPerformed:(NSNotification *)notification;
- (void)updateSearchResultsForSearchPerformedAtTime:(NSDate *)time;

- (void)moveCircleFocusToSelectedIndexPathWithPosition:(UITableViewScrollPosition)position;
- (void)hideCircle;

- (void)refreshControlValueChanged:(id)sender;
- (void)synchronizeAddedBookmark;

- (NSArray *)posts;

- (void)responseFailureHandler:(NSError *)error;

- (UIViewController *)editViewControllerForPostAtIndex:(NSInteger)index dataSource:(id<PPDataSource>)dataSource;
- (UIViewController *)editViewControllerForPostAtIndex:(NSInteger)index tableView:(UITableView *)tableView;
- (UIViewController *)editViewControllerForPostAtIndex:(NSInteger)index;

- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths dataSource:(id<PPDataSource>)dataSource;
- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths;

- (void)deletePosts:(NSArray *)posts dataSource:(id<PPDataSource>)dataSource;
- (void)deletePosts:(NSArray *)posts;

- (void)toggleSelectAllBookmarks:(id)sender;
- (void)alertIfSelectedBookmarkCountExceedsRecommendation:(NSInteger)count cancel:(void (^)())cancel update:(void (^)())update;

- (UITableView *)currentTableView;

@end

@implementation PPGenericPostViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifdef PROFILING
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.URL = [NSURL URLWithString:@"http://lionheartsw.com"];
#endif
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.definesPresentationContext = YES;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.view.backgroundColor = [UIColor whiteColor];
#pragma mark - XXX
    // self.prefersStatusBarHidden = NO;
    self.latestSearchTime = [NSDate date];
    self.isProcessingPosts = NO;
    
    self.focusSearchKeyCommand = [UIKeyCommand keyCommandWithInput:@"/"
                                                     modifierFlags:0
                                                            action:@selector(handleKeyCommand:)];
    
    self.openKeyCommand = [UIKeyCommand keyCommandWithInput:@"o"
                                              modifierFlags:UIKeyModifierCommand
                                                     action:@selector(handleKeyCommand:)];
    
    self.editKeyCommand = [UIKeyCommand keyCommandWithInput:@"e"
                                              modifierFlags:UIKeyModifierCommand
                                                     action:@selector(handleKeyCommand:)];
    
    self.moveUpKeyCommand = [UIKeyCommand keyCommandWithInput:@"k"
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)];
    
    self.moveDownKeyCommand = [UIKeyCommand keyCommandWithInput:@"j"
                                                  modifierFlags:0
                                                         action:@selector(handleKeyCommand:)];
    
    self.toggleCompressKeyCommand = [UIKeyCommand keyCommandWithInput:@"c"
                                                        modifierFlags:UIKeyModifierCommand | UIKeyModifierAlternate
                                                               action:@selector(handleKeyCommand:)];
    
    self.escapeKeyCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)];
    
#if TARGET_IPHONE_SIMULATOR
    self.enterKeyCommand = [UIKeyCommand keyCommandWithInput:@"\R"
                                               modifierFlags:0
                                                      action:@selector(handleKeyCommand:)];
#else
    self.enterKeyCommand = [UIKeyCommand keyCommandWithInput:@"\r"
                                               modifierFlags:0
                                                      action:@selector(handleKeyCommand:)];
#endif
    
    self.circle = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame), -100, 20, 20)];
    self.circle.layer.cornerRadius = 10;
    self.circle.backgroundColor = [UIColor blackColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.separatorColor = HEX(0xE0E0E0FF);
    
    // Add in the refresh control
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = self.refreshControl;
    
    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(popViewController)];
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    self.rightSwipeGestureRecognizer.numberOfTouchesRequired = 1;
    self.rightSwipeGestureRecognizer.cancelsTouchesInView = YES;
    [self.tableView addGestureRecognizer:self.rightSwipeGestureRecognizer];
    
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    [self.tableView addGestureRecognizer:self.pinchGestureRecognizer];
    
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];
    
    if ([self.postDataSource respondsToSelector:@selector(searchSupported)] && [self.postDataSource searchSupported]) {
        self.searchResultsController = [[PPTableViewController alloc] initWithStyle:UITableViewStylePlain];
        self.searchResultsController.tableView.delegate = self;
        self.searchResultsController.tableView.dataSource = self;
        [self.searchResultsController.tableView registerClass:[PPBookmarkCell class] forCellReuseIdentifier:BookmarkCellIdentifier];
        
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchResultsController];
        self.searchController.delegate = self;
        self.searchController.searchResultsUpdater = self;
        
        [self.searchController.searchBar sizeToFit];
        self.searchController.searchBar.delegate = self;
        self.searchController.searchBar.keyboardType = UIKeyboardTypeASCIICapable;
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleProminent;
        self.searchController.searchBar.isAccessibilityElement = YES;
        self.searchController.searchBar.accessibilityLabel = NSLocalizedString(@"Search Bar", nil);
        

        self.searchController.searchBar.scopeButtonTitles = @[NSLocalizedString(@"All", nil), NSLocalizedString(@"Title", nil), NSLocalizedString(@"Desc.", nil), NSLocalizedString(@"Tags", nil), NSLocalizedString(@"Full Text", nil)];
        
        self.searchPostDataSource = [self.postDataSource searchDataSource];
        if ([self.searchPostDataSource respondsToSelector:@selector(searchPlaceholder)]) {
            self.searchController.searchBar.placeholder = [self.searchPostDataSource searchPlaceholder];
        }
    }
    
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
    
    self.multipleDeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.multipleDeleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.multipleDeleteButton setImage:[[UIImage imageNamed:@"toolbar-trash"] lhs_imageWithColor:HEX(0x808d96ff)] forState:UIControlStateNormal];
    [self.multipleDeleteButton addTarget:self action:@selector(multiDelete:) forControlEvents:UIControlEventTouchUpInside];
    [self.multiToolbarView addSubview:self.multipleDeleteButton];
    self.multipleDeleteButton.enabled = NO;
    
    // Multi edit status and toolbar
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.multiToolbarView];
    [self.view addSubview:self.circle];
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    self.circleSnapBehavior = [[UISnapBehavior alloc] initWithItem:self.circle snapToPoint:CGPointMake(0, -100)];
    [self.animator addBehavior:self.circleSnapBehavior];
    
    NSDictionary *toolbarViews = @{ @"border": multiToolbarBorderView,
                                    @"read": self.multipleMarkAsReadButton,
                                    @"edit": self.multipleTagEditButton,
                                    @"delete": self.multipleDeleteButton };
    
    [self.multiToolbarView lhs_addConstraints:@"H:|[read][edit(==read)][delete(==read)]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[read]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[edit]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[delete]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"H:|[border]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[border(0.5)]" views:toolbarViews];
    
    NSDictionary *views = @{@"toolbarView": self.multiToolbarView,
                            @"table": self.tableView};
    
    [self.tableView lhs_fillHeightOfSuperview];
    [self.tableView lhs_fillWidthOfSuperview];
    [self.multiToolbarView lhs_fillWidthOfSuperview];
    [self.view lhs_addConstraints:@"V:[toolbarView(height)]" metrics:@{ @"height": @(kToolbarHeight) } views:views];
    
    // Initial database update
    [self.tableView registerClass:[PPBookmarkCell class] forCellReuseIdentifier:BookmarkCellIdentifier];
    PPSettings *settings = [PPSettings sharedSettings];
    
#if 0
    if (!settings.turnOffPushpinCloudPrompt) {
        UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:@"Pushpin Cloud Signup" message:@"\nIf you're interested in a Pushpin Mac Application or standalone web application, subscribe for updates on our progress."];
        
        [alert lhs_addActionWithTitle:@"Sign Up"
                                style:UIAlertActionStyleCancel
                              handler:^(UIAlertAction *action) {
                                  UIAlertController *alert = [PPMailChimp mailChimpSubscriptionAlertController];
                                  [self presentViewController:alert animated:YES completion:nil];
                                  settings.turnOffPushpinCloudPrompt = YES;
                              }];
        
        [alert lhs_addActionWithTitle:@"Do Not Show Again"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action) {
                                  settings.turnOffPushpinCloudPrompt = YES;
                              }];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
#endif
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.viewIsAppearing = YES;
    
    if (!self.searchController.isActive) {
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
            self.multipleEditToolbarBottomConstraint = [NSLayoutConstraint constraintWithItem:self.multiToolbarView
                                                                                    attribute:NSLayoutAttributeBottom
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:self.tableView
                                                                                    attribute:NSLayoutAttributeBottom
                                                                                   multiplier:1
                                                                                     constant:kToolbarHeight];
            [self.view addConstraint:self.multipleEditToolbarBottomConstraint];
        }
        
        UIViewController *backViewController = (self.navigationController.viewControllers.count >= 2) ? self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2] : nil;
        
        self.selectAllBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Mark All", nil)
                                                                       style:UIBarButtonItemStyleDone
                                                                      target:self
                                                                      action:@selector(toggleSelectAllBookmarks:)];
        self.selectAllBarButtonItem.possibleTitles = [NSSet setWithObjects:NSLocalizedString(@"Mark All", nil), NSLocalizedString(@"Mark None", nil), nil];
        
        if (![UIApplication isIPad] && [backViewController isKindOfClass:[PPFeedListViewController class]]) {
            self.hamburgerBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigation-list"]
                                                             landscapeImagePhone:[UIImage imageNamed:@"navigation-list"]
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(popViewController)];
            
            self.navigationItem.leftBarButtonItem = self.hamburgerBarButtonItem;
            self.navigationItem.accessibilityLabel = NSLocalizedString(@"Back", nil);
            
            __weak id weakself = self;
            self.navigationController.interactivePopGestureRecognizer.delegate = weakself;
        } else {
            PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
            self.hamburgerBarButtonItem = delegate.navigationController.splitViewControllerBarButtonItem;
        }
        
        if (self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:NO animated:NO];
        }
        
        if ([self.postDataSource respondsToSelector:@selector(deletePostsAtIndexPaths:callback:)]) {
            self.editButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", nil)
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(toggleEditingMode:)];
            
            self.navigationItem.rightBarButtonItem = self.editButton;
        }
        
        PPSettings *settings = [PPSettings sharedSettings];
        self.compressPosts = settings.compressPosts;
        PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
        
        [self updateFromLocalDatabaseWithCallback:^{
            if (delegate.connectionAvailable) {
                [self.postDataSource syncBookmarksWithCompletion:^(BOOL updated, NSError *error) {
                    if (error) {
                        [self responseFailureHandler:error];
                    } else {
                        if (updated) {
                            [self updateFromLocalDatabaseWithCallback:nil];
                        }
                    }
                } progress:nil];
            }
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.viewIsAppearing = NO;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     }];
    
    // Register for Dynamic Type notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferredContentSizeChanged:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDisplaySettingsUpdateNotification:)
                                                 name:PPBookmarkDisplaySettingUpdated
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toggleCompressedPosts)
                                                 name:PPBookmarkCompressSettingUpdate
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(synchronizeAddedBookmark)
                                                 name:PPBookmarkEventNotificationName
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    PPSettings *settings = [PPSettings sharedSettings];
    [settings setCompressPosts:self.compressPosts];
}

- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveDisplaySettingsUpdateNotification:(NSNotification *)notification {
    [self updateFromLocalDatabaseWithCallback:^{
        [self.tableView reloadData];
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
        } else {
            self.multipleDeleteButton.enabled = NO;
            self.multipleTagEditButton.enabled = NO;
            self.multipleMarkAsReadButton.enabled = NO;
        }
        
        [self updateMultipleEditUI];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedTableView = tableView;
    self.selectedIndexPath = indexPath;
    
    id <PPDataSource> dataSource = [self dataSourceForTableView:self.selectedTableView];
    PPSettings *settings = [PPSettings sharedSettings];
    
    if (self.selectedTableView.editing) {
        NSUInteger selectedRowCount = [self.selectedTableView.indexPathsForSelectedRows count];
        [self alertIfSelectedBookmarkCountExceedsRecommendation:selectedRowCount
                                                         cancel:^{
                                                             [tableView deselectRowAtIndexPath:indexPath animated:YES];
                                                         }
                                                         update:^{
                                                             [self updateMultipleEditUI];
                                                         }];
    } else {
        // If configured, always mark the post as read
        if (settings.markReadPosts) {
            self.selectedPost = [self.postDataSource postAtIndex:self.selectedIndexPath.row];
            [self markPostsAsRead:@[self.selectedPost] notify:NO];
        }
        
        [self.selectedTableView deselectRowAtIndexPath:self.selectedIndexPath animated:NO];
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        
        if (![dataSource respondsToSelector:@selector(viewControllerForPostAtIndex:)]) {
            NSString *urlString = [dataSource urlForPostAtIndex:self.selectedIndexPath.row];
            NSRange httpRange = NSMakeRange(NSNotFound, 0);
            if ([urlString hasPrefix:@"http"]) {
                httpRange = [urlString rangeOfString:@"http"];
            }
            
#warning TODO Check outside links
            if (settings.openLinksInApp) {
                [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Webview"}];

                if (settings.useSafariViewController) {
                    SFSafariViewController *controller = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:urlString]];
                    [self presentViewController:controller animated:YES completion:nil];
                } else {
                    self.webViewController = [PPWebViewController webViewControllerWithURL:urlString];
                    self.webViewController.shouldMobilize = settings.openLinksWithMobilizer;
                    self.webViewController.transitioningDelegate = [PPShrinkBackTransition sharedInstance];

                    static BOOL presentModally = YES;
                    if (presentModally) {
                        if (self.searchController.isActive) {
                            [self.searchController presentViewController:self.webViewController animated:YES completion:nil];
                        } else {
                            [self presentViewController:self.webViewController animated:YES completion:nil];
                        }
                    } else {
                        [self.navigationController pushViewController:self.webViewController animated:YES];
                    }
                }
            } else {
                if (httpRange.location == NSNotFound) {
                    // "http" couldn't be found anywhere in the URL.
                    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Shucks", nil)
                                                                                 message:NSLocalizedString(@"The URL could not be opened.", nil)];
                    
                    [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                            style:UIAlertActionStyleDefault
                                          handler:nil];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                } else {
                    PPBrowserType browser = settings.browser;
                    switch (browser) {
                        case PPBrowserSafari: {
                            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Safari"}];
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
                            break;
                        }
                            
                        case PPBrowserChrome: {
                            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome-x-callback://"]]) {
                                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"googlechrome-x-callback://x-callback-url/open/?url=%@&x-success=pushpin%%3A%%2F%%2F&&x-source=Pushpin", [urlString urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
                                [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Chrome"}];
                                [[UIApplication sharedApplication] openURL:url];
                            } else {
                                NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"googlechrome"]];
                                [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Chrome"}];
                                [[UIApplication sharedApplication] openURL:url];
                            }
                            break;
                        }
                            
                        case PPBrowseriCabMobile: {
                            NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"icabmobile"]];
                            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"iCab Mobile"}];
                            [[UIApplication sharedApplication] openURL:url];
                            break;
                        }
                            
                        case PPBrowserOpera: {
                            NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"ohttp"]];
                            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Opera"}];
                            [[UIApplication sharedApplication] openURL:url];
                            break;
                        }
                            
                        case PPBrowserDolphin: {
                            NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"dolphin"]];
                            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"dolphin"}];
                            [[UIApplication sharedApplication] openURL:url];
                            break;
                        }
                            
                        case PPBrowserCyberspace: {
                            NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"cyber"]];
                            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Cyberspace Browser"}];
                            [[UIApplication sharedApplication] openURL:url];
                            break;
                        }
                            
                        default:
                            break;
                    }
                }
            }
        } else {
            // The post data source will provide a view controller to push.
            UIViewController *controller = [dataSource viewControllerForPostAtIndex:self.selectedIndexPath.row];
            
            if ([self.navigationController topViewController] == self) {
                [self.navigationController pushViewController:controller animated:YES];
            }
        }
    }
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (recognizer == self.longPressGestureRecognizer) {
        [self.view endEditing:YES];
        self.selectedPoint = [recognizer locationInView:self.tableView];
        self.selectedIndexPath = [self.tableView indexPathForRowAtPoint:self.selectedPoint];
        if (self.selectedIndexPath) {
            self.selectedPost = [self.postDataSource postAtIndex:self.selectedIndexPath.row];
            [self openActionSheetForSelectedPost];
        }
    }
    else if (recognizer == self.pinchGestureRecognizer) {
        if (recognizer.state != UIGestureRecognizerStateBegan) {
            BOOL needsReload = NO;
            if (self.compressPosts) {
                needsReload = self.pinchGestureRecognizer.scale > 1.5;
            } else {
                needsReload = self.pinchGestureRecognizer.scale < 0.5;
            }
            
            if (needsReload) {
                [self toggleCompressedPosts];
            }
        }
    }
}

- (void)synchronizeAddedBookmark {
    [self.postDataSource syncBookmarksWithCompletion:^(BOOL updated, NSError *error) {
        if (error) {
            [self responseFailureHandler:error];
        } else {
            if (updated) {
                [self updateFromLocalDatabase];
            }
        }
    } progress:nil options:@{@"count": @(10)}];
}

- (void)updateFromLocalDatabase {
    [self updateFromLocalDatabaseWithCallback:nil];
}

- (void)updateFromLocalDatabaseWithCallback:(void (^)())callback {
    [self updateFromLocalDatabaseWithCallback:callback time:nil];
}

- (void)updateFromLocalDatabaseWithCallback:(void (^)())callback time:(NSDate *)time {
    if (!time) {
        time = [NSDate date];
    }
    self.latestSearchTime = time;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.searchController.isActive) {
            [self.searchPostDataSource reloadBookmarksWithCompletion:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!error) {
                        UITableView *tableView = self.searchResultsController.tableView;
                        
                        // attempt to delete row 99 from section 0 which only contains 2 rows before the update
                        
                        [tableView reloadData];
                        
                        if (callback) {
                            callback();
                        }
                    }
                });
            } cancel:^BOOL{
                BOOL isHidden = !self.isViewLoaded || self.view.window == nil;
                if (isHidden && !self.viewIsAppearing) {
                    return YES;
                } else {
                    return [self.latestSearchTime compare:time] != NSOrderedSame;
                }
            } width:self.currentWidth];
        } else {
            BOOL firstLoad = [self.postDataSource numberOfPosts] == 0;
            
            UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            
            if (firstLoad) {
                activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
                [activityIndicator startAnimating];
                
                [self.view addSubview:activityIndicator];
                [self.view lhs_centerHorizontallyForView:activityIndicator];
                [self.view lhs_centerVerticallyForView:activityIndicator];
            }
            
            [self.postDataSource reloadBookmarksWithCompletion:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (firstLoad) {
                        [activityIndicator removeFromSuperview];
                        [self.tableView reloadData];
                        
                        if (self.searchController) {
                            self.tableView.tableHeaderView = self.searchController.searchBar;
                            [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame)) animated:NO];
                        }
                    } else {
                        [self.tableView reloadData];
                    }
                    
                    if (callback) {
                        callback();
                    }
                    
                    self.isProcessingPosts = NO;
                });
            } cancel:^BOOL{
                BOOL isHidden = !self.isViewLoaded || self.view.window == nil;
                if (isHidden) {
                    return YES;
                } else {
                    return [time compare:self.latestSearchTime] != NSOrderedSame;
                }
            } width:self.currentWidth];
        }
    });
}

- (void)updateSearchResultsForSearchPerformed:(NSNotification *)notification {
    [self updateSearchResultsForSearchPerformedAtTime:notification.userInfo[@"time"]];
}

- (void)updateSearchResultsForSearchPerformedAtTime:(NSDate *)time {

    if (self.searchController.searchBar.selectedScopeButtonIndex == PPSearchScopeFullText) {
        [(PPPinboardDataSource *)self.searchPostDataSource setSearchScope:ASPinboardSearchScopeFullText];
    } else {
        [(PPPinboardDataSource *)self.searchPostDataSource setSearchScope:ASPinboardSearchScopeNone];
    }
    
    [self.searchPostDataSource filterWithQuery:self.formattedSearchString];
    [self updateFromLocalDatabaseWithCallback:nil time:time];
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
        
        [self.navigationItem setRightBarButtonItem:self.editButton
                                          animated:YES];
        
        [self.navigationItem setLeftBarButtonItem:self.hamburgerBarButtonItem
                                         animated:YES];
        
        self.navigationItem.backBarButtonItem.enabled = YES;
        
        if ([self.postDataSource respondsToSelector:@selector(titleViewWithDelegate:)]) {
            PPTitleButton *titleView = (PPTitleButton *)[self.postDataSource titleViewWithDelegate:self];
            self.navigationItem.titleView = titleView;
        } else {
            self.navigationItem.titleView = nil;
        }
        
        [UIView animateWithDuration:0.25 animations:^{
            UITextField *searchTextField = [self.searchController.searchBar valueForKey:@"_searchField"];
            searchTextField.enabled = YES;
            searchTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            
            self.tableView.contentInset = UIEdgeInsetsZero;
            self.multipleEditToolbarBottomConstraint.constant = kToolbarHeight;
            [self.view layoutIfNeeded];
        }];
    } else {
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        [self.tableView setEditing:YES animated:YES];
        
        self.navigationItem.backBarButtonItem.enabled = NO;
        
        UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                                style:UIBarButtonItemStyleDone
                                                                               target:self
                                                                               action:@selector(toggleEditingMode:)];
        [self.navigationItem setRightBarButtonItem:cancelBarButtonItem
                                          animated:YES];
        
        [self.navigationItem setLeftBarButtonItem:self.selectAllBarButtonItem
                                         animated:YES];
        
        [self updateMultipleEditUI];
        
        [UIView animateWithDuration:0.25 animations:^{
            
            UITextField *searchTextField = [self.searchController.searchBar valueForKey:@"_searchField"];
            searchTextField.enabled = NO;
            
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, kToolbarHeight, 0);
            self.multipleEditToolbarBottomConstraint.constant = 0;
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths dataSource:(id<PPDataSource>)dataSource {
    [dataSource deletePostsAtIndexPaths:indexPaths callback:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            for (NSIndexPath *indexPath in indexPaths) {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }

            [self updateFromLocalDatabaseWithCallback:^{
                [UIView animateWithDuration:0.25 animations:^{
                    UITextField *searchTextField = [self.searchController.searchBar valueForKey:@"_searchField"];
                    searchTextField.enabled = YES;
                } completion:^(BOOL finished) {
                    self.indexPathsToDelete = @[];
                }];
            }];
        });
    }];
}

- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths {
    [self deletePostsAtIndexPaths:indexPaths dataSource:self.currentDataSource];
}

- (void)deletePosts:(NSArray *)posts dataSource:(id<PPDataSource>)dataSource {
    [dataSource deletePosts:posts callback:^(NSIndexPath *indexPath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (dataSource == self.searchPostDataSource) {
                [self.searchResultsController.tableView deselectRowAtIndexPath:indexPath animated:YES];
            } else {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
            
            [self updateFromLocalDatabaseWithCallback:^{
                [UIView animateWithDuration:0.25 animations:^{
                    UITextField *searchTextField = [self.searchController.searchBar valueForKey:@"_searchField"];
                    searchTextField.enabled = YES;
                } completion:^(BOOL finished) {
                    self.selectedPost = nil;
                }];
            }];
        });
    }];
}

- (void)deletePosts:(NSArray *)posts {
    [self deletePosts:posts dataSource:self.currentDataSource];
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
    NSMutableArray *bookmarksToUpdate = [NSMutableArray array];
    [[self.tableView indexPathsForSelectedRows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = (NSIndexPath *)obj;
        NSDictionary *bookmark = [self.postDataSource postAtIndex:indexPath.row];
        [bookmarksToUpdate addObject:bookmark];
    }];
    
    if (self.tableView.editing) {
        [self toggleEditingMode:nil];
    }
    
    PPMultipleEditViewController *vc = [[PPMultipleEditViewController alloc] initWithBookmarks:bookmarksToUpdate];
    PPNavigationController *navigationController = [[PPNavigationController alloc] initWithRootViewController:vc];
    
    if (![UIApplication isIPad]) {
        navigationController.transitioningDelegate = [PPShrinkBackTransition sharedInstance];
    }
    [self presentViewControllerInFormSheetIfApplicable:navigationController];
}

- (void)multiDelete:(id)sender {
    self.indexPathsToDelete = [self.tableView indexPathsForSelectedRows];
    
    self.confirmMultipleDeletionActionSheet = [UIAlertController lhs_actionSheetWithTitle:NSLocalizedString(@"Are you sure you want to delete these bookmarks?", nil)];
    
    [self.confirmMultipleDeletionActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Delete", nil)
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction *action) {
                                                                self.tableView.scrollEnabled = YES;
                                                                
                                                                [self deletePostsAtIndexPaths:self.indexPathsToDelete];
                                                                [self toggleEditingMode:nil];
                                                            }];
    
    [self.confirmMultipleDeletionActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction *action) {
                                                                self.tableView.scrollEnabled = YES;
                                                                
                                                                if (self.tableView.editing) {
                                                                    [self toggleEditingMode:nil];
                                                                }
                                                            }];
    
    self.confirmMultipleDeletionActionSheet.popoverPresentationController.sourceRect = [self.view convertRect:[self.multipleDeleteButton lhs_centerRect] fromView:self.multipleDeleteButton];
    self.confirmMultipleDeletionActionSheet.popoverPresentationController.sourceView = self.view;
    [self presentViewController:self.confirmMultipleDeletionActionSheet animated:YES completion:nil];
}

- (void)tagSelected:(id)sender {
}

#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    id <PPDataSource> dataSource = [self dataSourceForTableView:tableView];
    
    if (!self.isProcessingPosts) {
        if ([dataSource respondsToSelector:@selector(willDisplayIndexPath:callback:)]) {
            [dataSource willDisplayIndexPath:indexPath callback:^(BOOL needsUpdate) {
                if (needsUpdate) {
                    if (self.tableView == tableView) {
                        [self updateFromLocalDatabase];
                    } else {
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
    NSInteger num = [[self dataSourceForTableView:tableView] numberOfPosts];
    return num;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id <PPDataSource> dataSource = [self dataSourceForTableView:tableView];
    if (self.compressPosts && [dataSource respondsToSelector:@selector(compressedHeightForPostAtIndex:)]) {
        return [dataSource compressedHeightForPostAtIndex:indexPath.row];
    }
    
    return [dataSource heightForPostAtIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PPBookmarkCell *cell = (PPBookmarkCell *)[tableView dequeueReusableCellWithIdentifier:BookmarkCellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    
    id <PPDataSource> dataSource = [self dataSourceForTableView:tableView];
    NSDictionary *post = [dataSource postAtIndex:indexPath.row];
    [cell prepareCellWithDataSource:dataSource badgeDelegate:self post:post compressed:self.compressPosts];
    return cell;
}

- (void)openActionSheetForSelectedPost {
    if (self.longPressActionSheet.isFirstResponder) {
        if ([UIApplication isIPad]) {
            [(UIActionSheet *)self.longPressActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
        }
    } else {
        NSString *urlString;
        if ([self.selectedPost[@"url"] length] > 67) {
            urlString = [[self.selectedPost[@"url"] substringToIndex:67] stringByAppendingString:ellipsis];
        } else {
            urlString = self.selectedPost[@"url"];
        }
        
        self.longPressActionSheet = [UIAlertController lhs_actionSheetWithTitle:urlString];
        
        id <PPDataSource> dataSource = [self currentDataSource];
        PPPostActionType actions = [dataSource actionsForPost:self.selectedPost];
        
        if (actions & PPPostActionDelete) {
            [self.longPressActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Delete Bookmark", nil)
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action) {
                                                          self.tableView.scrollEnabled = YES;
                                                          
                                                          [self showConfirmDeletionAlert];
                                                      }];
        }
        
        if (actions & PPPostActionEdit) {
            [self.longPressActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Edit Bookmark", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          self.tableView.scrollEnabled = YES;
                                                          
                                                          UIViewController *vc = [self editViewControllerForPostAtIndex:self.selectedIndexPath.row dataSource:dataSource];
                                                          [self presentViewControllerInFormSheetIfApplicable:vc];
                                                      }];
        }
        
        if (actions & PPPostActionMarkAsRead) {
            [self.longPressActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Mark as read", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          self.tableView.scrollEnabled = YES;
                                                          
                                                          [self markPostAsRead];
                                                      }];
        }
        
        if (actions & PPPostActionCopyToMine) {
            [self.longPressActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Copy to mine", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          self.tableView.scrollEnabled = YES;
                                                          
                                                          UIViewController *vc = (UIViewController *)[dataSource addViewControllerForPostAtIndex:self.selectedIndexPath.row];
                                                          
                                                          [self presentViewControllerInFormSheetIfApplicable:vc];
                                                      }];
        }
        
        if (actions & PPPostActionCopyURL) {
            [self.longPressActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Copy URL", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          self.tableView.scrollEnabled = YES;
                                                          
                                                          [self copyURL];
                                                      }];
        }
        
        if (actions & PPPostActionShare) {
            [self.longPressActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Share Bookmark", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          self.tableView.scrollEnabled = YES;
                                                          
                                                          NSURL *url = [NSURL URLWithString:[dataSource urlForPostAtIndex:self.selectedIndexPath.row]];
                                                          NSString *title = [self.currentDataSource titleForPostAtIndex:self.selectedIndexPath.row].string;
                                                          
                                                          CGRect rect;
                                                          if (self.searchController.isActive) {
                                                              rect = [self.searchResultsController.tableView rectForRowAtIndexPath:self.selectedIndexPath];
                                                          } else {
                                                              rect = [self.tableView rectForRowAtIndexPath:self.selectedIndexPath];
                                                          }
                                                          
                                                          NSArray *activityItems = @[title, url];
                                                          self.activityView = [[PPActivityViewController alloc] initWithActivityItems:activityItems];
                                                          
                                                          __weak PPGenericPostViewController *weakself = self;
                                                          self.activityView.completionHandler = ^(NSString *activityType, BOOL completed) {
                                                              [weakself setNeedsStatusBarAppearanceUpdate];
                                                              
                                                              if (weakself.popover) {
                                                                  [weakself.popover dismissPopoverAnimated:YES];
                                                              }
                                                          };
                                                          
                                                          if ([UIApplication isIPad]) {
                                                              self.popover = [[UIPopoverController alloc] initWithContentViewController:self.activityView];
                                                              [self.popover presentPopoverFromRect:(CGRect){self.selectedPoint, {1, 1}} inView:self.tableView
                                                                          permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                                                          } else {
                                                              [self presentViewController:self.activityView animated:YES completion:nil];
                                                          }
                                                      }];
        }
        
        // Properly set the cancel button index
        [self.longPressActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                    style:UIAlertActionStyleCancel
                                                  handler:^(UIAlertAction *action) {
                                                      self.tableView.scrollEnabled = YES;
                                                  }];
        
        self.longPressActionSheet.popoverPresentationController.sourceView = self.tableView;
        self.longPressActionSheet.popoverPresentationController.sourceRect = (CGRect){self.selectedPoint, {1, 1}};
        
        [self presentViewController:self.longPressActionSheet animated:YES completion:^{
            self.tableView.scrollEnabled = NO;
        }];
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
            
            [self updateFromLocalDatabase];
        }];
    });
}

- (void)dismissViewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Post Action Methods

- (void)markPostAsRead {
    [self markPostsAsRead:@[self.selectedPost] notify:YES];
}

- (void)markPostsAsRead:(NSArray *)posts {
    [self markPostsAsRead:posts notify:YES];
}

- (void)markPostsAsRead:(NSArray *)posts notify:(BOOL)notify {
    PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
    
    if (!delegate.connectionAvailable) {
        [PPNotification notifyWithMessage:@"Connection unavailable"];
    } else {
        id <PPDataSource> dataSource = [self currentDataSource];
        
        if ([dataSource respondsToSelector:@selector(markPostAsRead:callback:)]) {
            BOOL __block hasError = NO;
            
            dispatch_group_t group = dispatch_group_create();
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            
            NSString *message;
            __block BOOL success = NO;
            __block BOOL updated = NO;
            
            // Enumerate all posts
            for (NSDictionary *post in posts) {
                dispatch_group_enter(group);
                [dataSource markPostAsRead:post[@"url"] callback:^(NSError *error) {
                    if (error) {
                        hasError = YES;
                    }
                    dispatch_group_leave(group);
                }];
            }
            
            // If we have any errors, update the local notification
            if (hasError) {
                message = NSLocalizedString(@"There was an error marking your bookmarks as read.", nil);
            } else {
                success = YES;
                updated = YES;
                
                if (posts.count == 1) {
                    message = NSLocalizedString(@"Bookmark marked as read.", nil);
                } else {
                    message = [NSString stringWithFormat:@"%lu bookmarks marked as read.", (unsigned long)posts.count];
                }
            }
            
            // Once all async tasks are done, present the notification and update the local database
            dispatch_group_notify(group, queue, ^{
                if (notify) {
                    [PPNotification notifyWithMessage:message success:success updated:updated];
                }
                
#warning XXX should probably do something to avoid removing everything
                [[PPPinboardDataSource resultCache] removeAllObjects];
                
                [self updateFromLocalDatabase];
            });
            
        }
    }
}

- (void)copyURL {
    [PPNotification notifyWithMessage:NSLocalizedString(@"URL copied to clipboard.", nil)
                              success:YES
                              updated:NO];
    
    [[UIPasteboard generalPasteboard] setString:[self.currentDataSource urlForPostAtIndex:self.selectedIndexPath.row]];
    [[Mixpanel sharedInstance] track:@"Copied URL"];
}

- (void)showConfirmDeletionAlert {
    NSString *message = [NSString stringWithFormat:@"%@\n\n%@", NSLocalizedString(@"Are you sure you want to delete this bookmark?", nil), self.selectedPost[@"url"]];
    
    self.confirmDeletionAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Confirm Deletion", nil)
                                                                      message:message];
    
    [self.confirmDeletionAlertView lhs_addActionWithTitle:NSLocalizedString(@"Delete", nil)
                                                    style:UIAlertActionStyleDestructive
                                                  handler:^(UIAlertAction *action) {
                                                      self.tableView.scrollEnabled = YES;
                                                      
                                                      // http://crashes.to/s/2565a27d5df
                                                      if (self.selectedPost) {
                                                          [self deletePosts:@[self.selectedPost]];
                                                      } else {
                                                          UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Error", nil)
                                                                                                                       message:NSLocalizedString(@"An error occurred and this bookmark could not be deleted. Please try again.", nil)];
                                                          [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil];
                                                          [self presentViewController:alert animated:YES completion:nil];
                                                      }
                                                  }];
    
    [self.confirmDeletionAlertView lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                    style:UIAlertActionStyleCancel
                                                  handler:^(UIAlertAction *action) {
                                                      self.tableView.scrollEnabled = YES;
                                                  }];
    
    [self presentViewController:self.confirmDeletionAlertView animated:YES completion:nil];
}

- (void)showConfirmDeletionActionSheet {
    self.confirmDeletionActionSheet = [UIAlertController lhs_actionSheetWithTitle:NSLocalizedString(@"Are you sure you want to delete this bookmark?", nil)];
    
    [self.confirmDeletionActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Delete", nil)
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(UIAlertAction *action) {
                                                        self.tableView.scrollEnabled = YES;
                                                        
                                                        if (self.searchController.isActive) {
                                                            [self deletePosts:@[self.selectedPost] dataSource:self.searchPostDataSource];
                                                        } else {
                                                            [self deletePostsAtIndexPaths:self.indexPathsToDelete];
                                                        }
                                                    }];
    
    [self.confirmDeletionActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction *action) {
                                                        self.tableView.scrollEnabled = YES;
                                                    }];
    
    self.confirmDeletionActionSheet.popoverPresentationController.sourceView = self.view;
    [self presentViewController:self.confirmDeletionActionSheet animated:YES completion:nil];
}

- (void)toggleSelectAllBookmarks:(id)sender {
    NSArray *indexPathsForSelectedRows = self.tableView.indexPathsForSelectedRows;
    if (indexPathsForSelectedRows.count > 0) {
        for (NSIndexPath *indexPath in indexPathsForSelectedRows) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        
        [self updateMultipleEditUI];
    } else {
        NSInteger numberOfRows = [self.tableView numberOfRowsInSection:0];
        
        [self alertIfSelectedBookmarkCountExceedsRecommendation:numberOfRows
                                                         cancel:nil
                                                         update:^{
                                                             for (NSInteger i=0; i<numberOfRows; i++) {
                                                                 NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                                                                 [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                                                             }
                                                             
                                                             [self updateMultipleEditUI];
                                                         }];
    }
}

- (void)alertIfSelectedBookmarkCountExceedsRecommendation:(NSInteger)count cancel:(void (^)())cancel update:(void (^)())update {
    if (count > PPBookmarkEditMaximum) {
        UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:@"Warning"
                                                                     message:[NSString stringWithFormat:@"Bulk-editing more than %lu bookmarks at a time might take a while to complete and will probably incur the wrath of the Pinboard API gods. Are you absolutely sure you want to continue?", (long)PPBookmarkEditMaximum]];
        [alert lhs_addActionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (cancel) {
                cancel();
            }
        }];
        [alert lhs_addActionWithTitle:@"Continue" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            update();
        }];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        update();
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    NSString *searchText = searchBar.text;
    if (![searchText isEqualToString:emptyString]) {
        switch (self.searchController.searchBar.selectedScopeButtonIndex) {
            case PPSearchScopeTitles:
                self.formattedSearchString = [NSString stringWithFormat:@"title:\"%@\"", searchText];
                break;
                
            case PPSearchScopeDescriptions:
                self.formattedSearchString = [NSString stringWithFormat:@"description:\"%@\"", searchText];
                break;
                
            case PPSearchScopeTags:
                self.formattedSearchString = [NSString stringWithFormat:@"tags:\"%@\"", searchText];
                break;
                
            default:
                self.formattedSearchString = searchText;
                break;
        }
        
        [self updateSearchResultsForSearchPerformedAtTime:[self.latestSearchTime copy]];
    }
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return YES;
}

#pragma mark - UISearchDisplayControllerDelegate

- (void)removeBarButtonTouchUpside:(id)sender {
    __weak PPGenericPostViewController *weakself = self;
    [self.postDataSource removeDataSource:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [PPNotification notifyWithMessage:NSLocalizedString(@"Removed from saved feeds.", nil)
                                      success:YES
                                      updated:NO];
            
            weakself.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil)
                                                                                          style:UIBarButtonItemStylePlain
                                                                                         target:weakself
                                                                                         action:@selector(addBarButtonTouchUpside:)];
        });
    }];
}

- (void)addBarButtonTouchUpside:(id)sender {
    __weak PPGenericPostViewController *weakself = self;
    [self.postDataSource addDataSource:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [PPNotification notifyWithMessage:NSLocalizedString(@"Added to saved feeds.", nil)
                                      success:YES
                                      updated:NO];
            
            weakself.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Remove", nil)
                                                                                          style:UIBarButtonItemStylePlain
                                                                                         target:weakself
                                                                                         action:@selector(removeBarButtonTouchUpside:)];
        });
    }];
}

- (id<PPDataSource>)dataSourceForTableView:(UITableView *)tableView {
    id <PPDataSource> dataSource;
    if (tableView == self.tableView) {
        dataSource = self.postDataSource;
    } else {
        dataSource = self.searchPostDataSource;
    }
    return dataSource;
}

- (id<PPDataSource>)currentDataSource {
    id <PPDataSource> dataSource;
    if (self.searchController.isActive) {
        dataSource = self.searchPostDataSource;
    } else {
        dataSource = self.postDataSource;
    }
    return dataSource;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self updateFromLocalDatabase];
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
    [self updateFromLocalDatabase];
}

#pragma mark - PPBadgeWrapperDelegate

- (void)badgeWrapperView:(PPBadgeWrapperView *)badgeWrapperView didSelectBadge:(PPBadgeView *)badge {
    if (self.searchController.active) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (self.tableView.editing) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:badgeWrapperView.tag inSection:0];
        if ([self.tableView.indexPathsForSelectedRows containsObject:indexPath]) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        } else {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    } else {
        NSArray *badgeViews = badgeWrapperView.subviews;
        NSMutableArray *badges = [badgeWrapperView.badges mutableCopy];
        
        NSUInteger visibleBadgeCount = [badgeViews indexesOfObjectsPassingTest:^BOOL(UIView *badgeView, NSUInteger idx, BOOL *stop) {
            return !badgeView.hidden;
        }].count;
        
        [badges removeObjectsInRange:NSMakeRange(0, visibleBadgeCount - 1)];
        if (badges.count > 5) {
            [badges removeObjectsInRange:NSMakeRange(5, badges.count - 5)];
        }
        
        NSString *tag = badge.text;
        if (![tag isEqualToString:emptyString]) {
            if ([tag isEqualToString:ellipsis] && badgeViews.count > 0) {
                // Show more tag options
                self.additionalTagsActionSheet = [UIAlertController lhs_actionSheetWithTitle:NSLocalizedString(@"Additional Tags", nil)];
                
                id <PPDataSource> dataSource = [self currentDataSource];
                if ([dataSource respondsToSelector:@selector(handleTapOnLinkWithURL:callback:)]) {
                    for (NSDictionary *badge in badges) {
                        if ([badge[@"type"] isEqualToString:@"tag"]) {
                            NSString *tappedTag = badge[@"tag"];
                            [self.additionalTagsActionSheet lhs_addActionWithTitle:tappedTag
                                                                             style:UIAlertActionStyleDefault
                                                                           handler:^(UIAlertAction *action) {
                                                                               self.tableView.scrollEnabled = YES;
                                                                               
                                                                               if (!self.tableView.editing) {
                                                                                   [dataSource handleTapOnLinkWithURL:[NSURL URLWithString:[tappedTag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                                                                                             callback:^(UIViewController *controller) {
                                                                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                     [self.navigationController pushViewController:controller animated:YES];
                                                                                                                 });
                                                                                                             }];
                                                                               }
                                                                               
                                                                               self.tableView.scrollEnabled = YES;
                                                                           }];
                        }
                    }
                }
                
                [self.additionalTagsActionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction *action) {
                                                                   self.tableView.scrollEnabled = YES;
                                                               }];
                
                self.additionalTagsActionSheet.popoverPresentationController.sourceView = badgeWrapperView;
                
                CGPoint point = CGPointMake(badge.center.x - 2, badge.center.y);
                self.additionalTagsActionSheet.popoverPresentationController.sourceRect = (CGRect){point, {1, 1}};
                
                [self presentViewController:self.additionalTagsActionSheet animated:YES completion:^{
                    self.tableView.scrollEnabled = NO;
                }];
            } else {
                // Go to the tag link
                id <PPDataSource> dataSource = [self currentDataSource];
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

- (void)titleButtonLongPress:(PPTitleButton *)titleButton {
    PPPinboardDataSource *pinboardDataSource = (PPPinboardDataSource *)self.postDataSource;
    UIAlertController *alert = [PPUtilities saveSearchAlertControllerWithQuery:pinboardDataSource.searchQuery
                                                                     isPrivate:pinboardDataSource.isPrivate
                                                                        unread:pinboardDataSource.unread
                                                                       starred:pinboardDataSource.starred
                                                                        tagged:[PPUtilities inverseValueForFilter:pinboardDataSource.untagged]
                                                                    completion:^{
                                                                    }];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)toggleCompressedPosts {
    if (!self.isProcessingPosts) {
        self.isProcessingPosts = YES;
        
        NSArray *indexPathsForVisibleRows = [self.tableView indexPathsForVisibleRows];
        NSArray *indexPathsToReload = [indexPathsForVisibleRows filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSIndexPath *indexPath, NSDictionary *bindings) {
            return [self.currentDataSource heightForPostAtIndex:indexPath.row] != [self.currentDataSource compressedHeightForPostAtIndex:indexPath.row];
        }]];
        
        if (indexPathsToReload.count > 0) {
            // For some reason, the first row is hidden, *unless* the first visible row is the one at the top of the table
            
            NSInteger row;
            if ([(NSIndexPath *)indexPathsForVisibleRows[0] row] == 0 || ![indexPathsToReload isEqual:indexPathsForVisibleRows[0]]) {
                row = 0;
            } else {
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
                self.isProcessingPosts = NO;
            });
        } else {
            self.isProcessingPosts = NO;
        }
    }
}

- (void)setMultipleEditButtonsEnabled:(BOOL)enabled {
    if (enabled) {
        self.multipleDeleteButton.enabled = YES;
        self.multipleTagEditButton.enabled = YES;
        self.multipleMarkAsReadButton.enabled = YES;
    } else {
        self.multipleDeleteButton.enabled = NO;
        self.multipleTagEditButton.enabled = NO;
        self.multipleMarkAsReadButton.enabled = NO;
    }
}

- (void)bookmarkCellDidActivateDeleteButton:(PPBookmarkCell *)cell
                                    forPost:(NSDictionary *)post {
    [self.currentTableView setContentOffset:CGPointMake(0, self.currentTableView.contentOffset.y) animated:YES];
    NSInteger index = [self.currentDataSource indexForPost:post];
    
    self.selectedPost = post;
    self.selectedIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self showConfirmDeletionAlert];
}

- (void)bookmarkCellDidActivateEditButton:(PPBookmarkCell *)cell
                                  forPost:(NSDictionary *)post {
    [self.currentTableView setContentOffset:CGPointMake(0, self.currentTableView.contentOffset.y) animated:YES];
    NSInteger index = [self.currentDataSource indexForPost:post];
    self.selectedIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    UIViewController *vc = [self editViewControllerForPostAtIndex:self.selectedIndexPath.row];
    [self presentViewControllerInFormSheetIfApplicable:vc];
}

- (BOOL)bookmarkCellCanSwipe:(PPBookmarkCell *)cell {
    return [self.postDataSource respondsToSelector:@selector(deletePostsAtIndexPaths:callback:)];
}

- (void)updateMultipleEditUI {
    NSInteger numberOfSelectedRows = [self.tableView indexPathsForSelectedRows].count > 0;
    
    if (numberOfSelectedRows > 0) {
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Mark None", nil);
    } else {
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Mark All", nil);
    }
    
    [self setMultipleEditButtonsEnabled:numberOfSelectedRows];
    [self updateTitleViewText];
}

- (void)updateTitleViewText {
    NSInteger selectedRowCount = [self.tableView indexPathsForSelectedRows].count;
    PPTitleButton *button = [PPTitleButton button];
    
    NSString *title;
    if (selectedRowCount == 1) {
        title = NSLocalizedString(@"1 bookmark", nil);
    } else {
        title = [NSString stringWithFormat:@"%lu %@", (unsigned long)selectedRowCount, NSLocalizedString(@"bookmarks", nil)];
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
    } else {
        width = MAX(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    }
    return width;
}

- (void)moveCircleFocusToSelectedIndexPathWithPosition:(UITableViewScrollPosition)position {
    self.circle.alpha = 1;
    
    if (self.circleHideTimer) {
        [self.circleHideTimer invalidate];
    }
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self.tableView scrollToRowAtIndexPath:self.selectedIndexPath atScrollPosition:position animated:NO];
                     }
                     completion:^(BOOL finished) {
                         CGRect rect = [self.tableView rectForRowAtIndexPath:self.selectedIndexPath];
                         CGRect viewRect = [self.tableView convertRect:rect toView:self.view];
                         CGPoint point = CGPointMake(CGRectGetMidX(viewRect), CGRectGetMidY(viewRect));
                         
                         [self.animator removeBehavior:self.circleSnapBehavior];
                         self.circleSnapBehavior = [[UISnapBehavior alloc] initWithItem:self.circle snapToPoint:point];
                         self.circleSnapBehavior.damping = 0.7;
                         [self.animator addBehavior:self.circleSnapBehavior];
                         
                         if (self.circleHideTimer) {
                             [self.circleHideTimer invalidate];
                         }
                         self.circleHideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(hideCircle) userInfo:nil repeats:NO];
                     }];
}

- (void)hideCircle {
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.circle.alpha = 0;
                     }];
}

#pragma mark - Key Commands

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    if ([self.searchController.searchBar isFirstResponder]) {
        return @[self.enterKeyCommand];
    } else {
        return @[self.focusSearchKeyCommand, self.toggleCompressKeyCommand, self.escapeKeyCommand, self.moveUpKeyCommand, self.moveDownKeyCommand, self.openKeyCommand, self.editKeyCommand];
    }
}

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand {
    if (keyCommand == self.enterKeyCommand) {
        [self.searchController.searchBar resignFirstResponder];
    }
    else if (keyCommand == self.focusSearchKeyCommand) {
        [self.searchController.searchBar becomeFirstResponder];
    }
    else if (keyCommand == self.toggleCompressKeyCommand) {
        [self toggleCompressedPosts];
    }
    else if (keyCommand == self.escapeKeyCommand) {
        [self.searchController.searchBar resignFirstResponder];
    }
    else if (keyCommand == self.moveUpKeyCommand) {
        if (self.selectedIndexPath) {
            NSInteger row = self.selectedIndexPath.row;
            self.selectedIndexPath = [NSIndexPath indexPathForRow:MAX(0, row-1) inSection:0];
            [self moveCircleFocusToSelectedIndexPathWithPosition:UITableViewScrollPositionNone];
        }
    }
    else if (keyCommand == self.moveDownKeyCommand) {
        if (self.selectedIndexPath) {
            NSInteger row = self.selectedIndexPath.row;
            self.selectedIndexPath = [NSIndexPath indexPathForRow:MIN([self.tableView numberOfRowsInSection:0] - 1, row+1) inSection:0];
            [self moveCircleFocusToSelectedIndexPathWithPosition:UITableViewScrollPositionNone];
        } else {
            self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self moveCircleFocusToSelectedIndexPathWithPosition:UITableViewScrollPositionNone];
        }
    }
    else if (keyCommand == self.openKeyCommand) {
        self.selectedTableView = self.tableView;
        [self handleCellTap];
    }
    else if (keyCommand == self.editKeyCommand) {
        UIViewController *vc = [self editViewControllerForPostAtIndex:self.selectedIndexPath.row];
        [self presentViewControllerInFormSheetIfApplicable:vc];
    }
}

- (NSArray *)posts {
    if (self.searchController.isActive) {
        return [self.searchPostDataSource posts];
    } else {
        return [self.postDataSource posts];
    }
}

- (void)refreshControlValueChanged:(id)sender {
    if (!self.tableView.editing && !self.isProcessingPosts && !self.searchController.isActive) {
        [self.postDataSource syncBookmarksWithCompletion:^(BOOL updated, NSError *error) {
            if (error) {
                [self responseFailureHandler:error];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (updated) {
                        [self updateFromLocalDatabaseWithCallback:^{
                            [self.refreshControl endRefreshing];
                        }];
                    } else {
                        [self.refreshControl endRefreshing];
                    }
                });
            }
        } progress:nil];
    }
}

- (void)responseFailureHandler:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSHTTPURLResponse *response = error.userInfo[ASPinboardHTTPURLResponseKey];
        if (response.statusCode == 401) {
            UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Invalid Credentials", nil)
                                                                         message:NSLocalizedString(@"Your Pinboard credentials are currently out-of-date. Your auth token may have been reset. Please log out and back into Pushpin to continue syncing bookmarks.", nil)];
            
            [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                    style:UIAlertActionStyleDefault
                                  handler:nil];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        else if (response.statusCode == 401) {
            UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Rate Limit Hit", nil)
                                                                         message:NSLocalizedString(@"Pushpin has currently hit the API rate limit for your account. Please wait at least 5 minutes before updating your bookmarks again.", nil)];
            
            [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                    style:UIAlertActionStyleDefault
                                  handler:nil];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        else if (response.statusCode == 500) {
            UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Error", nil)
                                                                         message:NSLocalizedString(@"The Pinboard API was unable to complete this request.", nil)];
            
            [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                    style:UIAlertActionStyleDefault
                                  handler:nil];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        
        [self.refreshControl endRefreshing];
    });
}

- (UIViewController *)editViewControllerForPostAtIndex:(NSInteger)index dataSource:(id<PPDataSource>)dataSource {
    UIViewController *vc = (UIViewController *)[dataSource editViewControllerForPostAtIndex:index callback:^{
        [self updateFromLocalDatabase];
    }];
    
    if (![UIApplication isIPad]) {
        vc.transitioningDelegate = [PPShrinkBackTransition sharedInstance];
    }
    return vc;
}

- (UIViewController *)editViewControllerForPostAtIndex:(NSInteger)index tableView:(UITableView *)tableView {
    id<PPDataSource> dataSource;
    if (tableView) {
        dataSource = [self dataSourceForTableView:tableView];
    } else {
        dataSource = self.currentDataSource;
    }
    
    return [self editViewControllerForPostAtIndex:index dataSource:dataSource];
}

- (UIViewController *)editViewControllerForPostAtIndex:(NSInteger)index {
    return [self editViewControllerForPostAtIndex:index tableView:nil];
}

- (void)presentViewControllerInFormSheetIfApplicable:(UIViewController *)vc {
    if ([UIApplication isIPad]) {
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    if ([self.navigationController topViewController] == self) {
        UIViewController *presentingViewController;
        if (self.searchController.active) {
            presentingViewController = self.searchController;
        } else {
            presentingViewController = self.navigationController;
        }
        
        [presentingViewController presentViewController:vc animated:YES completion:nil];
    }
}

- (UITableView *)currentTableView {
    if (self.currentDataSource == self.postDataSource) {
        return self.tableView;
    } else {
        return self.searchResultsController.tableView;
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    
    if (![searchText isEqualToString:emptyString]) {
        switch (self.searchController.searchBar.selectedScopeButtonIndex) {
            case PPSearchScopeTitles:
                self.formattedSearchString = [NSString stringWithFormat:@"title:\"%@\"", searchText];
                break;
                
            case PPSearchScopeDescriptions:
                self.formattedSearchString = [NSString stringWithFormat:@"description:\"%@\"", searchText];
                break;
                
            case PPSearchScopeTags:
                self.formattedSearchString = [NSString stringWithFormat:@"tags:\"%@\"", searchText];
                break;
                
            default:
                self.formattedSearchString = searchText;
                break;
        }
        
        BOOL shouldSearchFullText = NO;
        

        if ([self.searchPostDataSource respondsToSelector:@selector(shouldSearchFullText)]) {
            shouldSearchFullText = self.searchController.searchBar.selectedScopeButtonIndex == PPSearchScopeFullText;
        }
        
        self.latestSearchTime = [NSDate date];
        if (shouldSearchFullText) {
            // Put this on a timer, since we don't want to kill Pinboard servers.
            if (self.fullTextSearchTimer) {
                [self.fullTextSearchTimer invalidate];
            }
            
            self.fullTextSearchTimer = [NSTimer timerWithTimeInterval:0.4
                                                               target:self
                                                             selector:@selector(updateSearchResultsForSearchPerformed:)
                                                             userInfo:@{@"time": self.latestSearchTime}
                                                              repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:self.fullTextSearchTimer forMode:NSRunLoopCommonModes];
        } else {
            [self updateSearchResultsForSearchPerformedAtTime:self.latestSearchTime];
        }
    }
}

- (void)didPresentSearchController:(UISearchController *)searchController {
    searchController.view.frame = (CGRect){{0, 0}, {CGRectGetWidth(self.view.frame), self.view.frame.origin.y + CGRectGetHeight(self.view.frame)}};
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    [self setNeedsStatusBarAppearanceUpdate];
}

@end

