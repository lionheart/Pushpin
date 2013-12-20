//
//  GenericPostViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "GenericPostViewController.h"
#import "BookmarkCell.h"
#import "NSAttributedString+Attributes.h"
#import "NSString+URLEncoding2.h"

#import "PinboardDataSource.h"
#import "PPBadgeWrapperView.h"
#import "PPMultipleEditViewController.h"
#import "FeedListViewController.h"

#import <FMDB/FMDatabase.h>
#import <oauthconsumer/OAuthConsumer.h>
#import <ASPinboard/ASPinboard.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>
#import <PocketAPI/PocketAPI.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/UIImage+Tint.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

static BOOL kGenericPostViewControllerResizingPosts = NO;
static BOOL kGenericPostViewControllerDimmingReadPosts = NO;
static NSString *BookmarkCellIdentifier = @"BookmarkCell";
static NSInteger kToolbarHeight = 44;

@interface GenericPostViewController ()

@end

@implementation GenericPostViewController

@synthesize postDataSource;
@synthesize selectedPost;
@synthesize selectedIndexPath;
@synthesize actionSheetVisible;
@synthesize confirmDeletionAlertView;
@synthesize pullToRefreshView;
@synthesize pullToRefreshImageView;
@synthesize loading;
@synthesize searchDisplayController = __searchDisplayController;
@synthesize itemSize = _itemSize;

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.tableView];

    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(popViewController)];
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    self.rightSwipeGestureRecognizer.numberOfTouchesRequired = 1;
    self.rightSwipeGestureRecognizer.cancelsTouchesInView = YES;
    [self.tableView addGestureRecognizer:self.rightSwipeGestureRecognizer];
    
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    [self.tableView addGestureRecognizer:self.pinchGestureRecognizer];

    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];

    self.loading = NO;
    self.searchLoading = NO;
    self.pullToRefreshView = [[UIView alloc] initWithFrame:CGRectMake(0, -100, [UIApplication currentSize].width, 60)];
    self.pullToRefreshView.clipsToBounds = YES;
    self.pullToRefreshView.backgroundColor = [UIColor whiteColor];
    self.pullToRefreshImageView = [[PPLoadingView alloc] init];
    self.pullToRefreshImageView.backgroundColor = [UIColor clearColor];
    [self.pullToRefreshView addSubview:self.pullToRefreshImageView];
    [self.tableView addSubview:self.pullToRefreshView];

    CGRect bounds = [[UIScreen mainScreen] bounds];
    CGRect frame = CGRectMake(0, bounds.size.height, bounds.size.width, 44);
    self.toolbar = [[PPToolbar alloc] initWithFrame:frame];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.multipleDeleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete (0)" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMultipleDeletion:)];
    self.multipleDeleteButton.width = CGRectInset(self.toolbar.frame, 10, 0).size.width;
    self.multipleDeleteButton.enabled = NO;
    [self.multipleDeleteButton setTintColor:[UIColor blackColor]];
    [self.toolbar setItems:@[flexibleSpace, self.multipleDeleteButton, flexibleSpace]];
    
    // Setup the multi-edit status view
    self.multiStatusView = [[UIView alloc] init];
    self.multiStatusView.backgroundColor = HEX(0xFFFFFFFF);
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
    [self.multiStatusView lhs_addConstraints:@"H:|-[label]-|" views:statusViews];
    [self.multiStatusView lhs_addConstraints:@"H:|[border]|" views:statusViews];
    [self.multiStatusView lhs_addConstraints:@"V:|-4-[label]-4-[border(0.5)]|" views:statusViews];
    self.multiStatusView.hidden = YES;
    
    // Setup the multi-edit toolbar
    self.multiToolbarView = [[UIView alloc] init];
    self.multiToolbarView.backgroundColor = HEX(0xEBF2F6FF);
    self.multiToolbarView.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *multiToolbarBorderView = [[UIView alloc] init];
    multiToolbarBorderView.backgroundColor = HEX(0xb2b2b2ff);
    multiToolbarBorderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.multiToolbarView addSubview:multiToolbarBorderView];
    self.multiToolbarView.hidden = YES;
    
    // Badge settings
    self.badgeFontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote].pointSize;
    
    // Buttons
    UIButton *markAsReadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    markAsReadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [markAsReadButton setImage:[[UIImage imageNamed:@"toolbar-checkmark"] imageWithColor:HEX(0x808d96ff)] forState:UIControlStateNormal];
    [markAsReadButton addTarget:self action:@selector(multiMarkAsRead:) forControlEvents:UIControlEventTouchUpInside];
    [self.multiToolbarView addSubview:markAsReadButton];
    
    UIButton *editTagsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    editTagsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [editTagsButton setImage:[[UIImage imageNamed:@"toolbar-edit-tags"] imageWithColor:HEX(0x808d96ff)] forState:UIControlStateNormal];
    [editTagsButton addTarget:self action:@selector(multiEdit:) forControlEvents:UIControlEventTouchUpInside];
    [self.multiToolbarView addSubview:editTagsButton];
    
    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [deleteButton setImage:[[UIImage imageNamed:@"toolbar-trash"] imageWithColor:HEX(0x808d96ff)] forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(multiDelete:) forControlEvents:UIControlEventTouchUpInside];
    [self.multiToolbarView addSubview:deleteButton];
    
    NSDictionary *toolbarViews = @{ @"border": multiToolbarBorderView, @"read": markAsReadButton, @"edit": editTagsButton, @"delete": deleteButton };
    [self.multiToolbarView lhs_addConstraints:@"H:|[read][edit(==read)][delete(==read)]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[read]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[edit]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[delete]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"H:|[border]|" views:toolbarViews];
    [self.multiToolbarView lhs_addConstraints:@"V:|[border(0.5)]" views:toolbarViews];
    
    // Register for Dynamic Type notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    // Make sure the delegate and datasource are configured
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-10);
    horizontalMotionEffect.maximumRelativeValue = @(10);
    [self.tableView addMotionEffect:horizontalMotionEffect];

    // Initial database update
    [self.tableView registerClass:[BookmarkCell class] forCellReuseIdentifier:BookmarkCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     }];
    
    UIViewController *backViewController = (self.navigationController.viewControllers.count >= 2) ? self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2] : nil;
    if ([backViewController isKindOfClass:[FeedListViewController class]]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigation-list"] landscapeImagePhone:[UIImage imageNamed:@"navigation-list"] style:UIBarButtonItemStylePlain target:self action:@selector(popViewController)];
    }
    
    if (self.navigationController.navigationBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    
    if ([self.postDataSource respondsToSelector:@selector(deletePostsAtIndexPaths:callback:)]) {
        self.editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigation-edit"] landscapeImagePhone:[UIImage imageNamed:@"navigation-edit"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleEditingMode:)];
        self.navigationItem.rightBarButtonItem = self.editButton;
    }

    if ([self.postDataSource numberOfPosts] == 0) {
        self.tableView.separatorColor = [UIColor clearColor];
    }
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.tableView.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Multi edit status and toolbar
    CGFloat topOffset = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
    [self.navigationController.view addSubview:self.multiStatusView];
    [self.navigationController.view lhs_addConstraints:@"H:|[statusView]|" views:@{ @"statusView": self.multiStatusView }];
    [self.navigationController.view lhs_addConstraints:@"V:|-offset-[statusView(height)]" metrics:@{ @"offset": @(topOffset), @"height": @(kToolbarHeight) } views:@{ @"statusView": self.multiStatusView }];
    [self.navigationController.view addSubview:self.multiToolbarView];
    [self.navigationController.view lhs_addConstraints:@"H:|[toolbarView]|" views:@{ @"toolbarView": self.multiToolbarView }];
    [self.navigationController.view lhs_addConstraints:@"V:[toolbarView(height)]|" metrics:@{ @"height": @(kToolbarHeight) } views:@{ @"toolbarView": self.multiToolbarView }];
    
    [self.navigationController.view addSubview:self.toolbar];

    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;

    self.actionSheetVisible = NO;
    
    BOOL oldCompressPosts = self.compressPosts;
    self.compressPosts = [AppDelegate sharedDelegate].compressPosts;
    if (self.compressPosts != oldCompressPosts) {
        if (!kGenericPostViewControllerResizingPosts) {
            kGenericPostViewControllerResizingPosts = YES;
            NSArray *indexPathsToReload = [self.tableView indexPathsForVisibleRows];
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
            kGenericPostViewControllerResizingPosts = NO;
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
        self.pullToRefreshView.frame = CGRectMake(0, -60, self.tableView.frame.size.width, 60);
        self.tableView.contentInset = UIEdgeInsetsMake(124, 0, 0, 0);
        self.tableView.contentOffset = CGPointMake(0, -124);
        [self.pullToRefreshImageView startAnimating];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateFromLocalDatabaseWithCallback:^{
                if ([AppDelegate sharedDelegate].bookmarksNeedUpdate) {
                    [self updateWithRatio:@(1.0)];
                    [AppDelegate sharedDelegate].bookmarksNeedUpdate = NO;
                }
            }];
        });
    }
    else {
        [self.tableView reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    // Remove the multi editting views
    [self.multiStatusView removeFromSuperview];
    [self.multiToolbarView removeFromSuperview];
    
    // Hide the editing toolbar
    [self.toolbar removeFromSuperview];
    
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
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger selectedRowCount = [tableView.indexPathsForSelectedRows count];
    if (selectedRowCount > 0) {
        self.multiStatusLabel.text = [NSString stringWithFormat:@"%d %@", selectedRowCount, NSLocalizedString(@"bookmarks selected", nil)];
    }
    else {
        self.multiStatusLabel.text = NSLocalizedString(@"No bookmarks selected", nil);
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
            self.multiStatusLabel.text = [NSString stringWithFormat:@"%d %@", selectedRowCount, NSLocalizedString(@"bookmarks selected", nil)];
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
                            switch ([[[AppDelegate sharedDelegate] browser] integerValue]) {
                                case BROWSER_SAFARI: {
                                    [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Safari"}];
                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
                                    break;
                                }
                                    
                                case BROWSER_CHROME:
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
                                    
                                case BROWSER_ICAB_MOBILE:
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
                                    
                                case BROWSER_OPERA:
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
                                    
                                case BROWSER_DOLPHIN:
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
                                    
                                case BROWSER_CYBERSPACE:
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
                        vc = (UIViewController *)[dataSource addViewControllerForPostAtIndex:self.selectedIndexPath.row delegate:self];
                    }
                    else if ([dataSource respondsToSelector:@selector(editViewControllerForPostAtIndex:withDelegate:)]) {
                        vc = (UIViewController *)[dataSource editViewControllerForPostAtIndex:self.selectedIndexPath.row withDelegate:self];
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
        
        if (self.searchDisplayController.isActive) {
            self.selectedPoint = [recognizer locationInView:self.searchDisplayController.searchResultsTableView];
            self.selectedIndexPath = [self.searchDisplayController.searchResultsTableView indexPathForRowAtPoint:self.selectedPoint];
            self.selectedPost = [self.searchPostDataSource postAtIndex:self.selectedIndexPath.row];
        }
        else {
            self.selectedPoint = [recognizer locationInView:self.tableView];
            self.selectedIndexPath = [self.tableView indexPathForRowAtPoint:self.selectedPoint];
            self.selectedPost = [self.postDataSource postAtIndex:self.selectedIndexPath.row];
        }
        [self openActionSheetForSelectedPost];
    }
    else if (recognizer == self.pinchGestureRecognizer) {
        if (recognizer.state != UIGestureRecognizerStateBegan) {
            if (!kGenericPostViewControllerResizingPosts) {
                kGenericPostViewControllerResizingPosts = YES;

                NSArray *visibleIndexPaths = self.tableView.indexPathsForVisibleRows;
                BOOL needsReload = NO;
                
                if (self.compressPosts) {
                    needsReload = self.pinchGestureRecognizer.scale > 1.5;
                }
                else {
                    needsReload = self.pinchGestureRecognizer.scale < 0.5;
                }
                
                if (needsReload) {
                    self.compressPosts = !self.compressPosts;
                    
                    [self.tableView beginUpdates];
                    [self.tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                    
                    double delayInSeconds = 0.25;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [self.tableView scrollToRowAtIndexPath:visibleIndexPaths[0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                        kGenericPostViewControllerResizingPosts = NO;
                    });
                }
                else {
                    kGenericPostViewControllerResizingPosts = NO;
                }
            }
        }
    }
    else if (recognizer == self.doubleTapGestureRecognizer) {
        self.dimReadPosts = !self.dimReadPosts;
        [[AppDelegate sharedDelegate] setDimReadPosts:self.dimReadPosts];

        [self.postDataSource updatePostsFromDatabaseWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *realIndexPathsToReload = self.tableView.indexPathsForVisibleRows;
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:realIndexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            });
        } failure:nil];
    }
}

- (void)updateFromLocalDatabaseWithCallback:(void (^)())callback {
    if (!self.loading) {
        self.loading = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.postDataSource updatePostsFromDatabaseWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView beginUpdates];
                    [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                    self.tableView.separatorColor = HEX(0xE0E0E0ff);

                    self.loading = NO;
                    [UIView animateWithDuration:0.2 animations:^{
                        CGFloat tableOffsetTop = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
                        self.tableView.contentInset = UIEdgeInsetsMake(tableOffsetTop, 0, 0, 0);
                    } completion:^(BOOL finished) {
                        [self.pullToRefreshImageView stopAnimating];
                        [self.pullToRefreshImageView setHidden:YES];
                        CGFloat offset = self.tableView.contentOffset.y;
                        self.pullToRefreshView.frame = CGRectMake(0, offset, [UIApplication currentSize].width, -offset);
                        
                        if ([self.postDataSource respondsToSelector:@selector(searchDataSource)] && !self.searchPostDataSource) {
                            self.searchPostDataSource = [self.postDataSource searchDataSource];

                            self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, [UIApplication currentSize].width, 44)];
                            self.searchBar.delegate = self;
                            self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
                            self.searchDisplayController.searchResultsDataSource = self;
                            self.searchDisplayController.searchResultsDelegate = self;
                            self.searchDisplayController.delegate = self;
                            self.tableView.tableHeaderView = self.searchBar;
                            CGFloat offset = -([UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height - self.searchDisplayController.searchBar.frame.size.height);
                            [self.tableView setContentOffset:CGPointMake(0, offset)];

                            [self.searchDisplayController.searchResultsTableView registerClass:[BookmarkCell class] forCellReuseIdentifier:BookmarkCellIdentifier];
                        }
                    }];

                    if (callback) {
                        callback();
                    }
                });
            } failure:nil];
        });
    }
}

- (void)updateSearchResults {
    if (!self.searchLoading) {
        self.searchLoading = YES;
        __block CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
        __weak GenericPostViewController *weakself = self;
        self.latestSearchUpdateTime = time;
        [self.searchPostDataSource updatePostsFromDatabaseWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
            if (time == weakself.latestSearchUpdateTime) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakself.searchLoading = NO;
                    [weakself.searchDisplayController.searchResultsTableView beginUpdates];
                    [weakself.searchDisplayController.searchResultsTableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationNone];
                    [weakself.searchDisplayController.searchResultsTableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationNone];
                    [weakself.searchDisplayController.searchResultsTableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationNone];
                    [weakself.searchDisplayController.searchResultsTableView endUpdates];
                    weakself.searchDisplayController.searchResultsTableView.separatorColor = HEX(0xE0E0E0ff);
                });
            }
        } failure:nil];
    }
}

- (void)updateWithRatio:(NSNumber *)ratio {
    if (!self.loading) {
        self.loading = YES;
        [self.postDataSource updatePostsWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.loading = NO;
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];

                [UIView animateWithDuration:0.2 animations:^{
                    CGFloat tableOffsetTop = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
                    self.tableView.contentInset = UIEdgeInsetsMake(tableOffsetTop, 0, 0, 0);
                } completion:^(BOOL finished) {
                    [self.pullToRefreshImageView setHidden:YES];
                    [self.pullToRefreshImageView stopAnimating];
                }];
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

        self.tableView.allowsMultipleSelectionDuringEditing = NO;
        [self.tableView setEditing:NO animated:YES];

        [UIView animateWithDuration:0.25 animations:^{
            UITextField *searchTextField = [self.searchBar valueForKey:@"_searchField"];
            searchTextField.enabled = YES;
            searchTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;

            // TODO: Animate auto layout
            self.multiStatusView.hidden = YES;
            self.multiToolbarView.hidden = YES;
        }];
    }
    else {
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        [self.tableView setEditing:YES animated:YES];

        [UIView animateWithDuration:0.25 animations:^{
            UITextField *searchTextField = [self.searchBar valueForKey:@"_searchField"];
            searchTextField.enabled = NO;

            // TODO: Animate auto layout
            self.multiStatusView.hidden = NO;
            self.multiToolbarView.hidden = NO;
        }];
    }
}

- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths {
    [self.postDataSource deletePostsAtIndexPaths:indexPaths callback:^(NSArray *indexPathsToRemove, NSArray *indexPathsToAdd) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [indexPaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [self.tableView deselectRowAtIndexPath:obj animated:YES];
            }];
            
            [self.navigationItem setHidesBackButton:NO animated:YES];
            [self.editButton setStyle:UIBarButtonItemStylePlain];
            [self.editButton setTitle:@"Edit"];
            
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
            }];
            [CATransaction commit];
            
            [UIView animateWithDuration:0.25 animations:^{
                UITextField *searchTextField = [self.searchBar valueForKey:@"_searchField"];
                searchTextField.enabled = YES;
                
                CGRect bounds = [[UIScreen mainScreen] bounds];
                CGRect frame = CGRectMake(0, bounds.size.height, bounds.size.width, 44);
                self.toolbar.frame = frame;
            }];
        });
    }];
}

- (void)toggleMultipleDeletion:(id)sender {
    self.multipleDeleteButton.enabled = NO;
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    [self deletePostsAtIndexPaths:selectedIndexPaths];
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
    
}

- (void)tagSelected:(id)sender {
    PPBadgeView *badgeView = (PPBadgeView *)sender;
    
    id <GenericPostDataSource> dataSource = [self dataSourceForTableView:self.tableView];
    PPBadgeWrapperView *wrapperView = (PPBadgeWrapperView *)badgeView.superview;
    NSArray *indexPathsForVisibleRows = [self.tableView indexPathsForVisibleRows];

    BookmarkCell *cell;
    NSMutableArray *badges;
    
    for (NSIndexPath *indexPath in indexPathsForVisibleRows) {
        cell = (BookmarkCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        if ([cell.contentView.subviews containsObject:wrapperView]) {
            badges = [[dataSource badgesForPostAtIndex:indexPath.row] mutableCopy];
            break;
        }
    }
    
    NSUInteger __block visibleBadgeCount = 0;
    for (PPBadgeView *badgeView in wrapperView.subviews) {
        if (badgeView.hidden == NO) {
            visibleBadgeCount++;
        }
    }

    [badges removeObjectsInRange:NSMakeRange(0, visibleBadgeCount - 1)];
    if (badges.count > 5) {
        [badges removeObjectsInRange:NSMakeRange(5, badges.count - 5)];
    }
    
    NSString *tag = badgeView.textLabel.text;
    if (![tag isEqualToString:@""]) {
        if ([tag isEqualToString:@"…"] && cell && badges.count > 0) {
            // Show more tag options
            self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

            for (NSDictionary *badge in badges) {
                if ([badge[@"type"] isEqualToString:@"tag"]) {
                    [self.actionSheet addButtonWithTitle:badge[@"tag"]];
                }
            }
            
            // Properly set the cancel button index
            [self.actionSheet addButtonWithTitle:@"Cancel"];
            self.actionSheet.cancelButtonIndex = self.actionSheet.numberOfButtons - 1;
            self.actionSheetVisible = YES;

            [self.actionSheet showFromRect:(CGRect){self.selectedPoint, {1, 1}} inView:self.tableView animated:YES];
            self.tableView.scrollEnabled = NO;
        } else {
            // Go to the tag link
            id <GenericPostDataSource> dataSource = [self currentDataSource];
            if (!self.tableView.editing) {
                if ([dataSource respondsToSelector:@selector(handleTapOnLinkWithURL:callback:)]) {
                    [dataSource handleTapOnLinkWithURL:[NSURL URLWithString:tag]
                                              callback:^(UIViewController *controller) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self.navigationController pushViewController:controller animated:YES];
                                                  });
                                              }];
                }
            }
        }
    }
}

#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    id <GenericPostDataSource> dataSource = [self dataSourceForTableView:tableView];

    if (!self.loading) {
        if ([dataSource respondsToSelector:@selector(willDisplayIndexPath:callback:)]) {
            [dataSource willDisplayIndexPath:indexPath callback:^(BOOL needsUpdate) {
                if (needsUpdate) {
                    if (self.tableView == tableView) {
                        [self updateFromLocalDatabaseWithCallback:nil];
                    }
                    else {
                        [self updateSearchResults];
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

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id <GenericPostDataSource> dataSource = [self dataSourceForTableView:tableView];

    PPBadgeWrapperView *badgeWrapperView;
    if ([dataSource respondsToSelector:@selector(compressedHeightForPostAtIndex:)] && self.compressPosts) {
        badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:[dataSource badgesForPostAtIndex:indexPath.row] options:@{ PPBadgeFontSize: @(self.badgeFontSize) } compressed:YES];
        return [dataSource compressedHeightForPostAtIndex:indexPath.row] + [badgeWrapperView calculateHeight] + 13.0f;
    }
    badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:[dataSource badgesForPostAtIndex:indexPath.row] options:@{ PPBadgeFontSize: @(self.badgeFontSize) }];
    return [dataSource heightForPostAtIndex:indexPath.row] + [badgeWrapperView calculateHeight] + 13.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BookmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:BookmarkCellIdentifier forIndexPath:indexPath];

    // TODO: This is a bit of a hack, and could be updated to reuse the views
    for (UIView *subview in [cell.contentView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            [subview removeFromSuperview];
        }
        else if ([subview isKindOfClass:[TTTAttributedLabel class]]) {
            [subview removeFromSuperview];
        }
        else if ([subview isKindOfClass:[PPBadgeWrapperView class]]) {
            [subview removeFromSuperview];
        }
    }

    NSAttributedString *string;
    id <GenericPostDataSource> dataSource = [self dataSourceForTableView:tableView];
    NSArray *badges = [dataSource badgesForPostAtIndex:indexPath.row];
    if (self.compressPosts && [dataSource respondsToSelector:@selector(compressedAttributedStringForPostAtIndex:)]) {
        string = [dataSource compressedAttributedStringForPostAtIndex:indexPath.row];
        cell.badgeView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @(self.badgeFontSize) } compressed:YES];
    }
    else {
        string = [dataSource attributedStringForPostAtIndex:indexPath.row];
        cell.badgeView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @(self.badgeFontSize) }];
    }
    [cell.badgeView addBadgeTarget:self action:@selector(tagSelected:) forControlEvents:UIControlEventTouchUpInside];

    cell.backgroundColor = [UIColor whiteColor];
    cell.contentView.backgroundColor = [UIColor clearColor];

    cell.textView = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    cell.textView.font = [UIFont systemFontOfSize:kLargeFontSize];
    cell.textView.translatesAutoresizingMaskIntoConstraints = NO;
    cell.textView.numberOfLines = 0;
    cell.textView.textColor = [UIColor darkGrayColor];
    cell.textView.preferredMaxLayoutWidth = 320;
    cell.textView.lineBreakMode = kCTLineBreakByWordWrapping;
    cell.textView.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    cell.textView.linkAttributes = [NSDictionary dictionaryWithObject:@(NO) forKey:(NSString *)kCTUnderlineStyleAttributeName];

    NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
    [mutableActiveLinkAttributes setValue:@(NO) forKey:(NSString *)kCTUnderlineStyleAttributeName];
    [mutableActiveLinkAttributes setValue:(id)[HEX(0xeeddddff) CGColor] forKey:(NSString *)kTTTBackgroundFillColorAttributeName];
    [mutableActiveLinkAttributes setValue:(id)@(5.0f) forKey:(NSString *)kTTTBackgroundCornerRadiusAttributeName];
    cell.textView.activeLinkAttributes = mutableActiveLinkAttributes;
    cell.textView.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:cell.textView];
    
    cell.badgeView.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:cell.badgeView];
    
    [cell.contentView lhs_addConstraints:@"H:|-10-[text]-10-|" views:@{@"text": cell.textView}];
    if (badges.count > 0) {
        [cell.contentView lhs_addConstraints:@"H:|-10-[badges]-10-|" views:@{@"badges": cell.badgeView}];
        [cell.contentView lhs_addConstraints:@"V:|-5-[text]-3-[badges]-5-|" views:@{@"text": cell.textView, @"badges": cell.badgeView }];
    }
    else {
        [cell.contentView lhs_addConstraints:@"V:|-5-[text]-5-|" views:@{@"text": cell.textView }];
    }

    [cell.textView setText:string];

    NSArray *links;
    if ([dataSource respondsToSelector:@selector(compressedLinksForPostAtIndex:)] && self.compressPosts) {
        links = [dataSource compressedLinksForPostAtIndex:indexPath.row];
    }
    else {
        links = [dataSource linksForPostAtIndex:indexPath.row];
    }

    for (NSDictionary *link in links) {
        [cell.textView addLinkToURL:link[@"url"] withRange:NSMakeRange([link[@"location"] integerValue], [link[@"length"] integerValue])];
    }

    NSArray* sublayers = cell.contentView.layer.sublayers;
    for (CALayer *layer in sublayers) {
        if ([layer.name isEqualToString:@"Gradient"]) {
            [layer removeFromSuperlayer];
        }
    }

    sublayers = cell.selectedBackgroundView.layer.sublayers;
    for (CALayer *layer in sublayers) {
        [layer removeFromSuperlayer];
    }

    cell.textView.delegate = self;
    cell.textView.userInteractionEnabled = YES;
    return cell;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    id <GenericPostDataSource> dataSource = [self currentDataSource];
    if (!self.tableView.editing) {
        if ([dataSource respondsToSelector:@selector(handleTapOnLinkWithURL:callback:)]) {
            [dataSource handleTapOnLinkWithURL:url
                                      callback:^(UIViewController *controller) {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              [self.navigationController pushViewController:controller animated:YES];
                                          });
                                      }];
        }
    }
}

- (void)openActionSheetForSelectedPost {
    if (!self.actionSheet) {
        NSString *urlString;
        if ([self.selectedPost[@"url"] length] > 67) {
            urlString = [NSString stringWithFormat:@"%@...", [self.selectedPost[@"url"] substringToIndex:67]];
        }
        else {
            urlString = self.selectedPost[@"url"];
        }

        self.actionSheet = [[UIActionSheet alloc] initWithTitle:urlString delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

        PPPostAction action;
        id <GenericPostDataSource> dataSource = [self currentDataSource];

        for (id PPPAction in [dataSource actionsForPost:self.selectedPost]) {
            action = [PPPAction integerValue];
            if (action == PPPostActionCopyToMine) {
                [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Copy to mine", nil)];
            }
            else if (action == PPPostActionCopyURL) {
                [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];
            }
            else if (action == PPPostActionDelete) {
                [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Delete Bookmark", nil)];
            }
            else if (action == PPPostActionEdit) {
                [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Edit Bookmark", nil)];
            }
            else if (action == PPPostActionMarkAsRead) {
                [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Mark as read", nil)];
            }
            else if (action == PPPostActionReadLater) {
                NSInteger readlater = [[[AppDelegate sharedDelegate] readlater] integerValue];
                if (readlater == READLATER_INSTAPAPER) {
                    [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Send to Instapaper", nil)];
                }
                else if (readlater == READLATER_READABILITY) {
                    [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Send to Readability", nil)];
                }
                else if (readlater == READLATER_POCKET) {
                    [(UIActionSheet *)self.actionSheet addButtonWithTitle:NSLocalizedString(@"Send to Pocket", nil)];
                }
            }
        }

        // Properly set the cancel button index
        [self.actionSheet addButtonWithTitle:@"Cancel"];
        self.actionSheet.cancelButtonIndex = self.actionSheet.numberOfButtons - 1;

        self.actionSheetVisible = YES;
        [(UIActionSheet *)self.actionSheet showFromRect:(CGRect){self.selectedPoint, {1, 1}} inView:self.tableView animated:YES];
        self.tableView.scrollEnabled = NO;
    }
    else {
        if ([UIApplication isIPad]) {
            [(UIActionSheet *)self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
            self.actionSheet = nil;
        }
    }
}

#pragma mark - Table view delegate

- (void)closeModal:(UIViewController *)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            [self updateFromLocalDatabaseWithCallback:nil];
        }];
    });
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    self.tableView.scrollEnabled = YES;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.tableView.scrollEnabled = YES;
    
    if (!actionSheet.title) {
        if (buttonIndex >= (actionSheet.numberOfButtons - 1)) {
            self.actionSheet = nil;
            return;
        }
        
        NSString *tag = [actionSheet buttonTitleAtIndex:buttonIndex];
        id <GenericPostDataSource> dataSource = [self currentDataSource];
        if (!self.tableView.editing) {
            if ([dataSource respondsToSelector:@selector(handleTapOnLinkWithURL:callback:)]) {
                [dataSource handleTapOnLinkWithURL:[NSURL URLWithString:tag]
                                          callback:^(UIViewController *controller) {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  [self.navigationController pushViewController:controller animated:YES];
                                              });
                                          }];
            }
        }

    }
    else {
        if (buttonIndex >= 0) {
            NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
            id <GenericPostDataSource> dataSource = [self currentDataSource];
            
            if ([title isEqualToString:NSLocalizedString(@"Delete Bookmark", nil)]) {
                [self showConfirmDeletionAlert];
            }
            else if ([title isEqualToString:NSLocalizedString(@"Edit Bookmark", nil)]) {
                UIViewController *vc = (UIViewController *)[dataSource editViewControllerForPostAtIndex:self.selectedIndexPath.row withDelegate:self];
                
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
                UIViewController *vc = (UIViewController *)[dataSource addViewControllerForPostAtIndex:self.selectedIndexPath.row delegate:self];
                
                if ([UIApplication isIPad]) {
                    vc.modalPresentationStyle = UIModalPresentationFormSheet;
                }
                
                [self.navigationController presentViewController:vc animated:YES completion:nil];
            }
            
            self.actionSheet = nil;
        }
    }
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
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    if (![[delegate connectionAvailable] boolValue]) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = @"Connection unavailable.";
        notification.userInfo = @{@"success": @NO, @"updated": @YES};
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
    else {
        id <GenericPostDataSource> dataSource = [self currentDataSource];

        if ([dataSource respondsToSelector:@selector(markPostAsRead:callback:)]) {
            BOOL __block hasError = NO;
            
            dispatch_group_t group = dispatch_group_create();
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            

            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.userInfo = @{@"success": @YES, @"updated": @YES};
            notification.alertBody = NSLocalizedString(@"Your bookmarks were updated.", nil);
            
            // Enumerate all posts
            [posts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                dispatch_group_enter(group);
                [dataSource markPostAsRead:obj[@"url"] callback:^(NSError *error) {
                    if (error) {
                        notification.userInfo = @{@"success": @NO, @"updated": @NO};
                        hasError = YES;
                    }
                    dispatch_group_leave(group);
                }];
            }];
            
            // If we have any errors, update the local notification
            if (hasError) {
                notification.alertBody = NSLocalizedString(@"There was an error updating your bookmarks.", nil);
                notification.userInfo = @{@"success": @NO, @"updated": @NO};
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
    notification.userInfo = @{@"success": @YES, @"updated": @NO};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    [[UIPasteboard generalPasteboard] setString:[self.currentDataSource urlForPostAtIndex:self.selectedIndexPath.row]];
    [[Mixpanel sharedInstance] track:@"Copied URL"];
}

- (void)sendToReadLater {
    NSNumber *readLater = [[AppDelegate sharedDelegate] readlater];
    NSString *urlString = self.selectedPost[@"url"];
    if (readLater.integerValue == READLATER_INSTAPAPER) {
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
                                       notification.userInfo = @{@"success": @YES, @"updated": @NO};
                                       [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Instapaper"}];
                                   }
                                   else if (httpResponse.statusCode == 1221) {
                                       notification.alertBody = NSLocalizedString(@"Publisher opted out of Instapaper compatibility.", nil);
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   else {
                                       notification.alertBody = NSLocalizedString(@"Error sending to Instapaper.", nil);
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                               }];
    }
    else if (readLater.integerValue == READLATER_READABILITY) {
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
                                       notification.userInfo = @{@"success": @YES, @"updated": @NO};
                                       [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Readability"}];
                                   }
                                   else if (httpResponse.statusCode == 409) {
                                       notification.alertBody = @"Link already sent to Readability.";
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   else {
                                       notification.alertBody = @"Error sending to Readability.";
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                               }];
    }
    else if (readLater.integerValue == READLATER_POCKET) {
        [[PocketAPI sharedAPI] saveURL:[NSURL URLWithString:urlString]
                             withTitle:self.selectedPost[@"title"]
                               handler:^(PocketAPI *api, NSURL *url, NSError *error) {
                                   if (!error) {
                                       UILocalNotification *notification = [[UILocalNotification alloc] init];
                                       notification.alertBody = @"Sent to Pocket.";
                                       notification.userInfo = @{@"success": @YES, @"updated": @NO};
                                       [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                       
                                       [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Pocket"}];
                                   }
                               }];
    }
}

- (void)showConfirmDeletionAlert {
    self.confirmDeletionAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil) message:NSLocalizedString(@"Are you sure you want to delete this bookmark?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];

    [self.confirmDeletionAlertView show];
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self.confirmDeletionAlertView) {
        NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:NSLocalizedString(@"Yes", nil)]) {
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
        } else if ([title isEqualToString:NSLocalizedString(@"No", nil)]) {
            // Dismiss the edit view
            [self.tableView setEditing:NO animated:YES];
        }
    }
}

#pragma mark - Scroll View delegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (!self.tableView.editing && !self.loading && !self.searchDisplayController.isActive) {
        CGFloat offset = scrollView.contentOffset.y;
        CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
        CGFloat navigationHeight = self.navigationController.navigationBar.frame.size.height;
        CGFloat searchHeight = self.searchBar.frame.size.height;
        CGFloat minimumOffset = statusBarHeight + navigationHeight;
        if (offset < -(minimumOffset + self.pullToRefreshImageView.frame.size.height + 20)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.5 animations:^{
                    self.tableView.contentInset = UIEdgeInsetsMake(minimumOffset + self.pullToRefreshImageView.frame.size.height + 20, 0, 0, 0);
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
    if (!self.loading) {
        CGFloat offset = scrollView.contentOffset.y;
        CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
        CGFloat navigationHeight = self.navigationController.navigationBar.frame.size.height;
        CGFloat searchHeight = self.searchBar.frame.size.height;
        CGFloat minimumOffset = statusBarHeight + navigationHeight;
        NSInteger index = MAX(1, 32 - MIN((-offset / (minimumOffset + searchHeight + self.pullToRefreshImageView.frame.size.height + 20)) * 32, 32));
        NSString *imageName = [NSString stringWithFormat:@"ptr_%02d", index];
        UIOffset imageOffset;
        
        if (offset < 0) {
            // Start showing the view under the navigation bar
            self.pullToRefreshView.frame = CGRectMake(0, offset + minimumOffset, [UIApplication currentSize].width, ABS(offset) - minimumOffset);
            
            // Make sure the image view is visible, and update with the appropriate photo
            imageOffset = UIOffsetMake(0, 10.0f);
            [self.pullToRefreshImageView setHidden:NO];
            self.pullToRefreshImageView.image = [UIImage imageNamed:imageName];
            self.pullToRefreshImageView.frame = CGRectMake(self.pullToRefreshView.frame.size.width / 2 - 20, imageOffset.vertical, 40, 40);
        }
    }
}

#pragma mark Search Bar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (![searchText isEqualToString:@""]) {
        if (self.latestSearchTimer) {
            [self.latestSearchTimer invalidate];
        }

        self.latestSearchText = searchText;
        self.latestSearchTimer = [NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(searchTimerFired) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.latestSearchTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)searchTimerFired {
    [self.searchPostDataSource filterWithQuery:self.latestSearchText];
    [self updateSearchResults];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {

}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 10, 10) animated:NO];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return NO;
}

- (void)removeBarButtonTouchUpside:(id)sender {
    __weak GenericPostViewController *vc = self;
    [self.postDataSource removeDataSource:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            vc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:vc action:@selector(addBarButtonTouchUpside:)];
        });
    }];
}

- (void)addBarButtonTouchUpside:(id)sender {
    __weak GenericPostViewController *vc = self;
    [self.postDataSource addDataSource:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            vc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStylePlain target:vc action:@selector(removeBarButtonTouchUpside:)];
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
    if ([self.postDataSource respondsToSelector:@selector(resetHeightsWithSuccess:)]) {
        [self.postDataSource resetHeightsWithSuccess:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *indexPathsForVisibleRows = [self.tableView indexPathsForVisibleRows];
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            });
        }];
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
    self.badgeFontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote].pointSize;
    
    [self.postDataSource updatePostsFromDatabaseWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            [self.view setNeedsLayout];
        });
    } failure:nil];
}

@end
