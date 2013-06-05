//
//  GenericPostViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import "GenericPostViewController.h"
#import "BookmarkCell.h"
#import "NSAttributedString+Attributes.h"
#import "NSString+URLEncoding2.h"
#import "RDActionSheet.h"
#import <QuartzCore/QuartzCore.h>
#import "OAuthConsumer.h"
#import "KeychainItemWrapper.h"
#import "PocketAPI.h"
#import "ASPinboard/ASPinboard.h"
#import "PPCoreGraphics.h"
#import "PPWebViewController.h"
#import "PinboardDataSource.h"
#import "FMDatabase.h"

static BOOL kGenericPostViewControllerResizingPosts = NO;

@interface GenericPostViewController ()

@end

@implementation GenericPostViewController

@synthesize postDataSource;
@synthesize selectedPost;
@synthesize longPressGestureRecognizer;
@synthesize selectedIndexPath;
@synthesize actionSheetVisible;
@synthesize confirmDeletionAlertView;
@synthesize pullToRefreshView;
@synthesize pullToRefreshImageView;
@synthesize loading;
@synthesize searchDisplayController = __searchDisplayController;

- (void)viewDidLoad {
    [super viewDidLoad];

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
    self.pullToRefreshView = [[UIView alloc] initWithFrame:CGRectMake(0, -30, 320, 30)];
    self.pullToRefreshView.backgroundColor = [UIColor whiteColor];
    self.pullToRefreshImageView = [[PPLoadingView alloc] init];
    [self.pullToRefreshView addSubview:self.pullToRefreshImageView];
    [self.tableView addSubview:self.pullToRefreshView];

    CGRect bounds = [[UIScreen mainScreen] bounds];
    CGRect frame = CGRectMake(0, bounds.size.height, bounds.size.width, 44);
    self.toolbar = [[PPToolbar alloc] initWithFrame:frame];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.multipleDeleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete (0)" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMultipleDeletion:)];
    self.multipleDeleteButton.width = CGRectInset(self.toolbar.frame, 10, 0).size.width;
    self.multipleDeleteButton.enabled = NO;
    [self.multipleDeleteButton setTintColor:HEX(0xa4091c00)];
    [self.toolbar setItems:@[flexibleSpace, self.multipleDeleteButton, flexibleSpace]];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.tableView.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([self.postDataSource respondsToSelector:@selector(deletePostsAtIndexPaths:callback:)]) {
        self.editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(toggleEditingMode:)];
        self.editButton.possibleTitles = [NSSet setWithArray:@[@"Edit", @"Cancel"]];
        self.navigationItem.rightBarButtonItem = self.editButton;
    }

    if ([self.postDataSource numberOfPosts] == 0) {
        self.tableView.separatorColor = [UIColor clearColor];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.navigationController.view addSubview:self.toolbar];

    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;

    self.actionSheetVisible = NO;
    
    BOOL oldCompressPosts = self.compressPosts;
    self.compressPosts = [AppDelegate sharedDelegate].compressPosts;
    if (self.compressPosts != oldCompressPosts) {
        if (!kGenericPostViewControllerResizingPosts) {
            kGenericPostViewControllerResizingPosts = YES;
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
            kGenericPostViewControllerResizingPosts = NO;
        }
    }

    BOOL oldDimReadPosts = self.dimReadPosts;
    self.dimReadPosts = [AppDelegate sharedDelegate].dimReadPosts;
    if (oldDimReadPosts != self.dimReadPosts) {
        #warning XXX Use another static var here
        if (!kGenericPostViewControllerResizingPosts) {
            kGenericPostViewControllerResizingPosts = YES;
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
            kGenericPostViewControllerResizingPosts = NO;
        }
    }

    if ([self.postDataSource numberOfPosts] == 0) {
        self.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);

        [self.pullToRefreshImageView startAnimating];
        self.pullToRefreshImageView.frame = CGRectMake(140, 10, 40, 40);

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateFromLocalDatabaseWithCallback:^{
                if ([AppDelegate sharedDelegate].bookmarksNeedUpdate) {
                    [self updateWithRatio:@(1.0)];
                    [AppDelegate sharedDelegate].bookmarksNeedUpdate = NO;
                }
            }];
        });
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
    [self deletePostsAtIndexPaths:@[indexPath]];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        NSUInteger selectedRowCount = [tableView.indexPathsForSelectedRows count];
        if (selectedRowCount > 0) {
            self.multipleDeleteButton.enabled = YES;
            [self.multipleDeleteButton setTitle:[NSString stringWithFormat:@"Delete (%d)", selectedRowCount]];
        }
        else {
            self.multipleDeleteButton.enabled = NO;
            [self.multipleDeleteButton setTitle:[NSString stringWithFormat:@"Delete (0)"]];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        NSUInteger selectedRowCount = [tableView.indexPathsForSelectedRows count];
        self.multipleDeleteButton.enabled = YES;
        [self.multipleDeleteButton setTitle:[NSString stringWithFormat:@"Delete (%d)", selectedRowCount]];
    }
    else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        Mixpanel *mixpanel = [Mixpanel sharedInstance];

        if (![self.postDataSource respondsToSelector:@selector(viewControllerForPostAtIndex:)]) {
            NSString *urlString;
            if (tableView == self.tableView) {
                urlString = [self.postDataSource urlForPostAtIndex:indexPath.row];
            }
            else {
                urlString = [self.searchPostDataSource urlForPostAtIndex:indexPath.row];
            }
            NSRange httpRange = NSMakeRange(NSNotFound, 0);
            if ([urlString hasPrefix:@"http"]) {
                httpRange = [urlString rangeOfString:@"http"];
            }

            if ([[[AppDelegate sharedDelegate] openLinksInApp] boolValue]) {
                [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Webview"}];
                PPWebViewController *webViewController = [PPWebViewController webViewControllerWithURL:urlString];
                [self.navigationController pushViewController:webViewController animated:YES];
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
            UIViewController *controller = [self.postDataSource viewControllerForPostAtIndex:indexPath.row];
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (recognizer == self.longPressGestureRecognizer) {
        [self.view endEditing:YES];
        CGPoint pressPoint;
        
        if (self.searchDisplayController.isActive) {
            pressPoint = [recognizer locationInView:self.searchDisplayController.searchResultsTableView];
            self.selectedIndexPath = [self.searchDisplayController.searchResultsTableView indexPathForRowAtPoint:pressPoint];
            self.selectedPost = [self.searchPostDataSource postAtIndex:self.selectedIndexPath.row];
        }
        else {
            pressPoint = [recognizer locationInView:self.tableView];
            self.selectedIndexPath = [self.tableView indexPathForRowAtPoint:pressPoint];
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
                    NSMutableArray *indexPathsToReload = [NSMutableArray array];
                    for (NSIndexPath *indexPath in visibleIndexPaths) {
                        if ([self.postDataSource heightForPostAtIndex:indexPath.row] != [self.postDataSource compressedHeightForPostAtIndex:indexPath.row]) {
                            [indexPathsToReload addObject:indexPath];
                        }
                    }
                    
                    [self.tableView beginUpdates];
                    [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
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
                        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                    } completion:^(BOOL finished) {
                        [self.pullToRefreshImageView stopAnimating];
                        CGFloat offset = self.tableView.contentOffset.y;
                        self.pullToRefreshView.frame = CGRectMake(0, offset, 320, -offset);
                        
                        if ([self.postDataSource respondsToSelector:@selector(searchDataSource)] && !self.searchPostDataSource) {
                            self.searchPostDataSource = [self.postDataSource searchDataSource];

                            self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
                            self.searchBar.delegate = self;
                            self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
                            self.searchDisplayController.searchResultsDataSource = self;
                            self.searchDisplayController.searchResultsDelegate = self;
                            self.searchDisplayController.delegate = self;
                            self.tableView.tableHeaderView = self.searchBar;
                            [self.tableView setContentOffset:CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height)];
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
        [self.searchPostDataSource updatePostsFromDatabaseWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.searchLoading = NO;
                [self.searchDisplayController.searchResultsTableView beginUpdates];
                [self.searchDisplayController.searchResultsTableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                [self.searchDisplayController.searchResultsTableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
                [self.searchDisplayController.searchResultsTableView endUpdates];
                self.searchDisplayController.searchResultsTableView.separatorColor = HEX(0xE0E0E0ff);
            });
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
                self.tableView.separatorColor = HEX(0xE0E0E0ff);

                [UIView animateWithDuration:0.2 animations:^{
                    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                } completion:^(BOOL finished) {
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
        [self.editButton setStyle:UIBarButtonItemStylePlain];
        [self.editButton setTitle:NSLocalizedString(@"Edit", nil)];
        
        [self.navigationItem setHidesBackButton:NO animated:YES];

        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        }];
        [self.tableView setEditing:NO animated:YES];
        [CATransaction commit];

        [UIView animateWithDuration:0.25 animations:^{
            UITextField *searchTextField = [self.searchBar valueForKey:@"_searchField"];
            searchTextField.enabled = YES;

            CGRect bounds = [[UIScreen mainScreen] bounds];
            CGRect frame = CGRectMake(0, bounds.size.height, bounds.size.width, 44);
            self.toolbar.frame = frame;
        }];
    }
    else {
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        [self.editButton setStyle:UIBarButtonItemStyleDone];
        [self.editButton setTitle:NSLocalizedString(@"Cancel", nil)];
        [self.navigationItem setHidesBackButton:YES animated:YES];

        [self.multipleDeleteButton setTitle:@"Delete (0)"];
        self.multipleDeleteButton.enabled = NO;

        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        }];
        [self.tableView setEditing:YES animated:YES];
        [CATransaction commit];

        [UIView animateWithDuration:0.25 animations:^{
            UITextField *searchTextField = [self.searchBar valueForKey:@"_searchField"];
            searchTextField.enabled = NO;

            CGRect bounds = [[UIScreen mainScreen] bounds];
            CGRect frame = CGRectMake(0, bounds.size.height - 44, bounds.size.width, 44);
            self.toolbar.frame = frame;
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
            [self.tableView setEditing:NO animated:YES];
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

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    id <GenericPostDataSource> dataSource;
    if (tableView == self.tableView) {
        dataSource = self.postDataSource;
    }
    else {
        dataSource = self.searchPostDataSource;
    }

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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id <GenericPostDataSource> dataSource;
    if (tableView == self.tableView) {
        dataSource = self.postDataSource;
    }
    else {
        dataSource = self.searchPostDataSource;
    }

    if ([dataSource respondsToSelector:@selector(compressedHeightForPostAtIndex:)] && self.compressPosts) {
        return [dataSource compressedHeightForPostAtIndex:indexPath.row];
    }
    return [dataSource heightForPostAtIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"BookmarkCell";
    
    BookmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[BookmarkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.contentView.backgroundColor = [UIColor clearColor];
    }

    NSAttributedString *string;
    id <GenericPostDataSource> dataSource;
    if (tableView == self.tableView) {
        dataSource = self.postDataSource;
    }
    else {
        dataSource = self.searchPostDataSource;
    }

    if ([dataSource respondsToSelector:@selector(compressedAttributedStringForPostAtIndex:)] && self.compressPosts) {
        string = [dataSource compressedAttributedStringForPostAtIndex:indexPath.row];
    }
    else {
        string = [dataSource attributedStringForPostAtIndex:indexPath.row];
    }

    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
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
    
    for (id subview in [cell.contentView subviews]) {
        if (![subview isKindOfClass:[TTTAttributedLabel class]]) {
            [subview removeFromSuperview];
        }
    }

    for (id subview in [cell subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            [subview removeFromSuperview];
        }
    }

    NSArray* sublayers = [NSArray arrayWithArray:cell.contentView.layer.sublayers];
    for (CALayer *layer in sublayers) {
        if ([layer.name isEqualToString:@"Gradient"]) {
            [layer removeFromSuperlayer];
        }
    }

    CGFloat height = [tableView.delegate tableView:tableView heightForRowAtIndexPath:indexPath];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, 320.f, height);
    gradient.colors = @[(id)[HEX(0xFAFBFEff) CGColor], (id)[HEX(0xF2F6F9ff) CGColor]];
    gradient.name = @"Gradient";
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.f, height)];
    cell.backgroundView = backgroundView;
    [cell.backgroundView.layer addSublayer:gradient];
    
    if (tableView.editing) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    else {
        CAGradientLayer *selectedGradient = [CAGradientLayer layer];
        selectedGradient.frame = CGRectMake(0, 0, 320.f, height);
        selectedGradient.colors = @[(id)[HEX(0xE1E4ECff) CGColor], (id)[HEX(0xF3F5F9ff) CGColor]];
        UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.f, height)];
        cell.selectedBackgroundView = selectedBackgroundView;
        [cell.selectedBackgroundView.layer addSublayer:selectedGradient];
    }

    BOOL isPrivate = [dataSource isPostAtIndexPrivate:indexPath.row];
    if (isPrivate) {
        UIImageView *lockImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top-right-lock"]];
        lockImageView.frame = CGRectMake(302.f, 0, 18.f, 19.f);
        [cell addSubview:lockImageView];
    }
    
    BOOL isStarred = [dataSource isPostAtIndexStarred:indexPath.row];
    if (isStarred) {
        UIImageView *starImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top-left-star"]];
        starImageView.frame = CGRectMake(0, 0, 18.f, 19.f);
        [cell addSubview:starImageView];
    }

    cell.textView.delegate = self;
    cell.textView.userInteractionEnabled = YES;
    return cell;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if (!self.tableView.editing || self.searchDisplayController.isActive) {
        if ([self.postDataSource respondsToSelector:@selector(handleTapOnLinkWithURL:callback:)]) {
            [self.postDataSource handleTapOnLinkWithURL:url
                                               callback:^(UIViewController *controller) {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       [[AppDelegate sharedDelegate].navigationController pushViewController:controller animated:YES];
                                                   });
                        }];
        }
    }
}

- (void)openActionSheetForSelectedPost {
    if (!self.actionSheetVisible) {
        NSString *urlString;
        if ([self.selectedPost[@"url"] length] > 67) {
            urlString = [NSString stringWithFormat:@"%@...", [self.selectedPost[@"url"] substringToIndex:67]];
        }
        else {
            urlString = self.selectedPost[@"url"];
        }
        RDActionSheet *sheet = [[RDActionSheet alloc] initWithTitle:urlString delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

        PPPostAction action;
        
        id <GenericPostDataSource> dataSource;
        if (self.searchDisplayController.isActive) {
            dataSource = self.searchPostDataSource;
        }
        else {
            dataSource = self.postDataSource;
        }

        for (id PPPAction in [dataSource actionsForPost:self.selectedPost]) {
            action = [PPPAction integerValue];
            if (action == PPPostActionCopyToMine) {
                [sheet addButtonWithTitle:NSLocalizedString(@"Copy to mine", nil)];
            }
            else if (action == PPPostActionCopyURL) {
                [sheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];
            }
            else if (action == PPPostActionDelete) {
                [sheet addButtonWithTitle:NSLocalizedString(@"Delete Bookmark", nil)];
            }
            else if (action == PPPostActionEdit) {
                [sheet addButtonWithTitle:NSLocalizedString(@"Edit Bookmark", nil)];
            }
            else if (action == PPPostActionMarkAsRead) {
                [sheet addButtonWithTitle:NSLocalizedString(@"Mark as read", nil)];
            }
            else if (action == PPPostActionReadLater) {
                NSInteger readlater = [[[AppDelegate sharedDelegate] readlater] integerValue];
                if (readlater == READLATER_INSTAPAPER) {
                    [sheet addButtonWithTitle:NSLocalizedString(@"Send to Instapaper", nil)];
                }
                else if (readlater == READLATER_READABILITY) {
                    [sheet addButtonWithTitle:NSLocalizedString(@"Send to Readability", nil)];
                }
                else if (readlater == READLATER_POCKET) {
                    [sheet addButtonWithTitle:NSLocalizedString(@"Send to Pocket", nil)];
                }
            }
        }
        
        [sheet showFrom:self.navigationController.view];
        self.tableView.scrollEnabled = NO;
        self.actionSheetVisible = YES;
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

#pragma mark - RDActionSheet

- (void)actionSheet:(RDActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    self.tableView.scrollEnabled = YES;
    self.actionSheetVisible = NO;
    
    id <GenericPostDataSource> dataSource;
    if (self.searchDisplayController.isActive) {
        dataSource = self.searchPostDataSource;
    }
    else {
        dataSource = self.postDataSource;
    }
    
    if ([title isEqualToString:NSLocalizedString(@"Delete Bookmark", nil)]) {
        [self showConfirmDeletionAlert];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Edit Bookmark", nil)]) {
        [self.searchDisplayController setActive:NO];
        UIViewController *vc = [dataSource editViewControllerForPostAtIndex:self.selectedIndexPath.row withDelegate:self];
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
        UIViewController *vc = [dataSource addViewControllerForPostAtIndex:self.selectedIndexPath.row delegate:self];
        [self.navigationController presentViewController:vc animated:YES completion:nil];
    }
}

- (void)dismissViewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Post Action Methods

- (void)markPostAsRead {
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    if (![[delegate connectionAvailable] boolValue]) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = @"Connection unavailable.";
        notification.userInfo = @{@"success": @NO, @"updated": @YES};
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
    else {
        id <GenericPostDataSource> dataSource;
        if (self.searchDisplayController.isActive) {
            dataSource = self.searchPostDataSource;
        }
        else {
            dataSource = self.postDataSource;
        }

        [dataSource markPostAsRead:self.selectedPost[@"url"] callback:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                if (error == nil) {
                    notification.alertBody = NSLocalizedString(@"Your bookmark was updated.", nil);
                    notification.userInfo = @{@"success": @YES, @"updated": @YES};
                    [self updateFromLocalDatabaseWithCallback:nil];
                }
                else {
                    notification.userInfo = @{@"success": @NO, @"updated": @NO};
                    if (error.code == PinboardErrorBookmarkNotFound) {
                        notification.alertBody = @"Error marking as read.";
                    }
                    else {
                        notification.alertBody = NSLocalizedString(@"There was an error updating your bookmark.", nil);
                    }
                }
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            });
            
            [self updateFromLocalDatabaseWithCallback:nil];
        }];
    }
}

- (void)copyURL {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"URL copied to clipboard.", nil);
    notification.userInfo = @{@"success": @YES, @"updated": @NO};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    [[UIPasteboard generalPasteboard] setString:[self.postDataSource urlForPostAtIndex:self.selectedIndexPath.row]];
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
        [parameters addObject:[OARequestParameter requestParameter:@"description" value:@"Sent from Pushpin"]];
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
    self.confirmDeletionAlertView = [[WCAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil) message:NSLocalizedString(@"Are you sure you want to delete this bookmark?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];

    [self.confirmDeletionAlertView show];
}

#pragma mark - Alert View Delegate

- (void)alertView:(WCAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
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
        }
    }
}

#pragma mark - Scroll View delegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!self.tableView.editing && !self.loading && !self.searchDisplayController.isActive) {
        CGFloat offset = scrollView.contentOffset.y;
        if (offset < -60) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.5 animations:^{
                    self.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
                    [self.pullToRefreshImageView startAnimating];
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.5 animations:^{
                        self.pullToRefreshImageView.frame = CGRectMake(140, 10, 40, 40);
                        [self updateWithRatio:@(MIN((-offset - 60) / 70., 1))];
                    }];
                }];
            });
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!self.loading) {
        CGFloat offset = scrollView.contentOffset.y;
        NSInteger index = MAX(1, 32 - MIN((-offset / 60.) * 32, 32));
        NSString *imageName = [NSString stringWithFormat:@"ptr_%02d", index];
        UIOffset imageOffset;
        if (offset > -60) {
            imageOffset = UIOffsetMake(0, -(50 + offset));
        }
        else {
            imageOffset = UIOffsetMake(0, 10);
        }
        
        self.pullToRefreshView.frame = CGRectMake(0, offset, 320, -offset);
        self.pullToRefreshImageView.image = [UIImage imageNamed:imageName];
        self.pullToRefreshImageView.frame = CGRectMake(140, imageOffset.vertical, 40, 40);
    }
}

#pragma mark Search Bar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (![searchText isEqualToString:@""]) {
        [self.searchPostDataSource filterWithQuery:searchText];
        [self updateSearchResults];
    }
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
        vc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:vc action:@selector(addBarButtonTouchUpside:)];
    }];
}

- (void)addBarButtonTouchUpside:(id)sender {
    __weak GenericPostViewController *vc = self;
    [self.postDataSource addDataSource:^{
        vc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStylePlain target:vc action:@selector(removeBarButtonTouchUpside:)];
    }];
}

@end
