//
//  PostViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <ASPinboard/ASPinboard.h>
#import "BookmarkViewController.h"
#import "BookmarkCell.h"
#import "NSAttributedString+Attributes.h"
#import "TTTAttributedLabel.h"
#import "TSMiniWebBrowser.h"
#import "PocketAPI.h"
#import "FMDatabaseQueue.h"
#import "ZAActivityBar.h"
#import "OAuthConsumer.h"
#import "KeychainItemWrapper.h"
#import "NSString+URLEncoding2.h"

@interface BookmarkViewController ()

@end

@implementation BookmarkViewController

@synthesize selectedIndexPath;
@synthesize parameters = _parameters;
@synthesize bookmarks = _bookmarks;
@synthesize strings;
@synthesize heights;
@synthesize webView;
@synthesize endpoint = _endpoint;
@synthesize date_formatter;
@synthesize savedSearchTerm;
@synthesize filteredBookmarks;
@synthesize searchWasActive;
@synthesize searchDisplayController;
@synthesize searchBar = _searchBar;
@synthesize query = _query;
@synthesize queryParameters;
@synthesize limit;
@synthesize filteredHeights;
@synthesize filteredStrings;
@synthesize bookmark = _bookmark;
@synthesize bookmarkDetailViewController;
@synthesize links;
@synthesize filteredLinks;
@synthesize isSearchTable;
@synthesize bookmarkUpdateTimer;
@synthesize secondsLeft;
@synthesize timerPaused;
@synthesize shouldShowContextMenu;
@synthesize processingBookmarks;
@synthesize longPressGestureRecognizer;
@synthesize activityIndicator;
@synthesize editButton;
@synthesize toolbar;
@synthesize multipleDeleteButton;

- (void)checkForBookmarkUpdates {
    if ([[AppDelegate sharedDelegate] bookmarksLoading]) {
        [self.activityIndicator startAnimating];
    }
    else {
        [self.activityIndicator stopAnimating];
    }

    if (!timerPaused) {
        AppDelegate *delegate = [AppDelegate sharedDelegate];
        if (delegate.bookmarksUpdated.boolValue) {
            UIView *view;
            
            if (self.isSearchTable.boolValue) {
                view = self.searchDisplayController.searchContentsController.view;
            }
            else {
                view = self.navigationController.navigationBar;
            }

            [self processBookmarks];
            delegate.bookmarksUpdated = @NO;
        }
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.filteredBookmarks = [NSMutableArray arrayWithCapacity:[self.bookmarks count]];
	
    if (self.savedSearchTerm) {
        [self.searchDisplayController setActive:searchWasActive];
        [self.searchDisplayController.searchBar setText:self.savedSearchTerm];
        self.savedSearchTerm = nil;
    }
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.frame = CGRectMake(10, 0, 40, 20);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];

	self.tableView.scrollEnabled = YES;
    self.shouldShowContextMenu = YES;
    self.processingBookmarks = NO;
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchDisplayController.delegate = self;
    self.isSearchTable = @(NO);
    self.tableView.tableHeaderView = self.searchBar;
    [self.tableView setContentOffset:CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height)];
    
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];

    CGRect bounds = [[UIScreen mainScreen] bounds];
    CGRect frame = CGRectMake(0, bounds.size.height, bounds.size.width, 44);
    self.toolbar = [[UIToolbar alloc] initWithFrame:frame];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.multipleDeleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete (0)" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMultipleDeletion:)];
    self.multipleDeleteButton.enabled = NO;
    [self.multipleDeleteButton setTintColor:[UIColor redColor]];
    [self.toolbar setItems:@[flexibleSpace, self.multipleDeleteButton, flexibleSpace]];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.timerPaused = NO;
    self.secondsLeft = 1;
    self.bookmarkUpdateTimer = [NSTimer timerWithTimeInterval:0.10 target:self selector:@selector(checkForBookmarkUpdates) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.bookmarkUpdateTimer forMode:NSDefaultRunLoopMode];

    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

    [self.toolbar removeFromSuperview];
    [self.navigationController.view addSubview:self.toolbar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self processBookmarks];
    self.editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(toggleEditingMode:)];
    self.editButton.possibleTitles = [NSSet setWithArray:@[@"Edit", @"Done"]];
    self.navigationItem.rightBarButtonItem = self.editButton;
    
    if ([[AppDelegate sharedDelegate] bookmarksLoading]) {
        [self.activityIndicator startAnimating];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.timerPaused = YES;
    [self.bookmarkUpdateTimer invalidate];
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];
    if ([[AppDelegate sharedDelegate] bookmarksLoading]) {
        [self.activityIndicator stopAnimating];
    }

    [self.toolbar removeFromSuperview];
}

- (void)longPress:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan && self.shouldShowContextMenu) {
        CGPoint pressPoint;

        if (self.searchDisplayController.active) {
            pressPoint = [recognizer locationInView:self.searchDisplayController.searchResultsTableView];
            self.selectedIndexPath = [self.searchDisplayController.searchResultsTableView indexPathForRowAtPoint:pressPoint];
            self.bookmark = self.filteredBookmarks[self.selectedIndexPath.row];
        }
        else {
            pressPoint = [recognizer locationInView:self.tableView];
            self.selectedIndexPath = [self.tableView indexPathForRowAtPoint:pressPoint];
            self.bookmark = self.bookmarks[self.selectedIndexPath.row];
        }

        [self openActionSheetForBookmark:self.bookmark];
    }
}

- (void)updateSearchResults {
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    
    FMResultSet *results = [db executeQuery:@"SELECT bookmark.* FROM bookmark, bookmark_fts WHERE bookmark.id=bookmark_fts.id AND bookmark_fts MATCH ?" withArgumentsInArray:@[[self.savedSearchTerm stringByAppendingString:@"*"]]];

    [self.filteredBookmarks removeAllObjects];
    [self.filteredHeights removeAllObjects];
    [self.filteredStrings removeAllObjects];
    NSInteger count = 0;
    
    while ([results next]) {
        count++;
        if (count > 20) {
            break;
        }
        NSDictionary *bookmark = @{
            @"title": [results stringForColumn:@"title"],
            @"description": [results stringForColumn:@"description"],
            @"unread": [results objectForColumnName:@"unread"],
            @"url": [results stringForColumn:@"url"],
            @"private": [results objectForColumnName:@"private"],
            @"tags": [results stringForColumn:@"tags"],
        };
        
        [self.filteredBookmarks addObject:bookmark];
        [self.filteredHeights addObject:[BookmarkViewController heightForBookmark:bookmark]];
        [self.filteredStrings addObject:[BookmarkViewController attributedStringForBookmark:bookmark]];
    }
    
    [db close];
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.savedSearchTerm = searchText;
    [self updateSearchResults];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.tableView reloadData];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.filteredBookmarks = nil;
}

- (void)processBookmarks {
    self.processingBookmarks = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.timerPaused = YES;
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *results = [db executeQuery:self.query withParameterDictionary:self.queryParameters];
        
        NSMutableArray *oldURLs = [NSMutableArray array];
        NSMutableArray *newURLs = [NSMutableArray array];
        for (NSDictionary *bookmark in self.bookmarks) {
            [oldURLs addObject:bookmark[@"url"]];
        }

        NSMutableArray *newBookmarks = [NSMutableArray array];
        NSMutableArray *newHeights = [NSMutableArray array];
        NSMutableArray *newStrings = [NSMutableArray array];

        NSMutableArray *oldBookmarks = [self.bookmarks copy];

        NSMutableArray *indexPathsToAdd = [NSMutableArray array];
        NSMutableArray *indexPathsToRemove = [NSMutableArray array];
        NSMutableArray *indexPathsToUpdate = [NSMutableArray array];
        NSInteger index = 0;

        while ([results next]) {
            NSString *title = [results stringForColumn:@"title"];
            
            if ([title isEqualToString:@""]) {
                title = @"untitled";
            }
            NSDictionary *bookmark = @{
                @"title": title,
                @"description": [results stringForColumn:@"description"],
                @"unread": [results objectForColumnName:@"unread"],
                @"url": [results stringForColumn:@"url"],
                @"private": [results objectForColumnName:@"private"],
                @"tags": [results stringForColumn:@"tags"],
            };
            
            [newBookmarks addObject:bookmark];
            [newHeights addObject:[BookmarkViewController heightForBookmark:bookmark]];
            [newStrings addObject:[BookmarkViewController attributedStringForBookmark:bookmark]];
            [newURLs addObject:bookmark[@"url"]];

            if (![oldBookmarks containsObject:bookmark]) {
                // Check if the bookmark is being updated (as opposed to entirely new)
                if ([oldURLs containsObject:bookmark[@"url"]]) {
                    [indexPathsToUpdate addObject:[NSIndexPath indexPathForRow:index inSection:0]];
                }
                else {
                    [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:0]];
                }
                
                [self.bookmarks addObject:bookmark];
                [self.heights addObject:[BookmarkViewController heightForBookmark:bookmark]];
                [self.strings addObject:[BookmarkViewController attributedStringForBookmark:bookmark]];
            }
            index++;
        }
        [db close];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (oldBookmarks.count == 0) {
                    [self.tableView reloadData];
                }
                else {
                    [self.tableView beginUpdates];
                    [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationAutomatic];
                    
                    for (int i=0; i<oldURLs.count; i++) {
                        if (![newURLs containsObject:oldURLs[i]]) {
                            [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:[self.bookmarks indexOfObject:oldBookmarks[i]] inSection:0]];
                        }
                    }

                    DLog(@"OLD %d", oldBookmarks.count);
                    DLog(@"ADD %d", indexPathsToAdd.count);
                    DLog(@"UPDATE %d", indexPathsToUpdate.count);
                    [self.tableView reloadRowsAtIndexPaths:indexPathsToUpdate withRowAnimation:UITableViewRowAnimationAutomatic];

                    self.bookmarks = newBookmarks;
                    self.heights = newHeights;
                    self.strings = newStrings;

                    DLog(@"REMOVE %d", indexPathsToRemove.count);
                    DLog(@"NEW %d", self.strings.count);

                    [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationLeft];
                    [self.tableView endUpdates];
                    self.timerPaused = NO;
                }
                self.processingBookmarks = NO;
            });
        });
    });
}

- (id)initWithFilters:(NSArray *)filters parameters:(NSMutableDictionary *)parameters {
    NSString *queryFormat = @"SELECT * FROM bookmark%@%@ ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
    NSMutableArray *whereComponents = [NSMutableArray array];
    for (id filter in filters) {
        [whereComponents addObject:[NSString stringWithFormat:@"%@ = :%@", filter, filter]];
    }
    
    NSString *query;
    if (whereComponents.count > 0) {
        query = [NSString stringWithFormat:queryFormat, @" WHERE ", [whereComponents componentsJoinedByString:@" and "]];
    }
    else {
        query = [NSString stringWithFormat:queryFormat, @"", @""];
    }

    return [self initWithQuery:query parameters:parameters];
}

- (id)initWithQuery:(NSString *)query parameters:(NSMutableDictionary *)parameters {
    // initWithQuery:@"SELECT * FROM bookmark WHERE name = :name LIMIT :limit OFFSET :offset" arguments:@{@"name": @"dan"}
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.limit = @(100);

        self.bookmarks = [NSMutableArray array];
        self.parameters = [NSMutableArray array];
        self.strings = [NSMutableArray array];
        self.heights = [NSMutableArray array];
        self.links = [NSMutableArray array];

        self.filteredHeights = [NSMutableArray array];
        self.filteredStrings = [NSMutableArray array];
        self.filteredBookmarks = [NSMutableArray array];
        self.filteredLinks = [NSMutableArray array];

        self.date_formatter = [[NSDateFormatter alloc] init];
        [self.date_formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [self.date_formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        
        self.query = query;
        if (!parameters) {
            self.queryParameters = [[NSMutableDictionary alloc] init];
        }
        else {
            self.queryParameters = parameters;
        }
        self.queryParameters[@"limit"] = limit;
        self.queryParameters[@"offset"] = @(0);

        self.tableView.separatorColor = HEX(0xD1D1D1ff);

    }
    return self;
}

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.limit = @(100);

        self.bookmarks = [NSMutableArray array];
        self.parameters = [NSMutableArray array];
        self.strings = [NSMutableArray array];
        self.heights = [NSMutableArray array];
        self.date_formatter = [[NSDateFormatter alloc] init];
        [self.date_formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [self.date_formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

        self.query = @"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
        self.queryParameters = [[NSMutableDictionary alloc] initWithObjectsAndKeys:limit, @"limit", @(0), "offset", nil];

        self.tableView.separatorColor = HEX(0xD1D1D1ff);
    }
    return self;
}

- (void)markBookmarkAsRead:(id)sender {
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    if (![[delegate connectionAvailable] boolValue]) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = @"Connection unavailable.";
        notification.userInfo = @{@"success": @NO, @"updated": @YES};
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        return;
    }
    
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard bookmarkWithURL:self.bookmark[@"url"]
                      success:^(NSDictionary *bookmark) {
                          if ([bookmark[@"toread"] isEqualToString:@"no"]) {
                              // Bookmark has already been marked as read on server.
                              FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                              [db open];
                              [db executeUpdate:@"UPDATE bookmark SET unread=0 WHERE hash=?" withArgumentsInArray:@[bookmark[@"hash"]]];
                              [db close];
                              
                              UILocalNotification *notification = [[UILocalNotification alloc] init];
                              notification.alertBody = NSLocalizedString(@"Bookmark Updated Message", nil);
                              notification.alertAction = @"Open Pushpin";
                              notification.userInfo = @{@"success": @YES, @"updated": @YES};
                              [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                              return;
                          }

                          NSMutableDictionary *newBookmark = [NSMutableDictionary dictionaryWithDictionary:bookmark];
                          newBookmark[@"toread"] = @"no";
                          newBookmark[@"url"] = newBookmark[@"href"];
                          [newBookmark removeObjectsForKeys:@[@"href", @"hash", @"meta", @"time"]];
                          [pinboard addBookmark:newBookmark
                                        success:^{
                                            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                            [db open];
                                            BOOL success = [db executeUpdate:@"UPDATE bookmark SET unread=0 WHERE hash=?" withArgumentsInArray:@[bookmark[@"hash"]]];
                                            [db close];
                                            
                                            if (success) {
                                                if (self.savedSearchTerm) {
                                                    [self updateSearchResults];
                                                }
                                            }
                                            
                                            UILocalNotification *notification = [[UILocalNotification alloc] init];
                                            notification.alertAction = @"Open Pushpin";
                                            notification.alertBody = NSLocalizedString(@"Bookmark Updated Message", nil);
                                            notification.userInfo = @{@"success": @YES, @"updated": @YES};
                                            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                        }
                                        failure:^(NSError *error) {
                                            UILocalNotification *notification = [[UILocalNotification alloc] init];
                                            notification.alertAction = @"Open Pushpin";
                                            notification.alertBody = NSLocalizedString(@"Bookmark Update Error Message", nil);
                                            notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                        }];
                      }
                      failure:^(NSError *error) {
                          if (error.code == PinboardErrorBookmarkNotFound) {
                              UILocalNotification *notification = [[UILocalNotification alloc] init];
                              notification.alertBody = @"Error marking as read.";
                              notification.userInfo = @{@"success": @NO, @"updated": @NO};
                              [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                          }
                      }];
}

#pragma mark - Search Results Delegate

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    self.isSearchTable = @(YES);
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    [self.tableView reloadData];
    self.isSearchTable = @(NO);
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self.confirmDeleteAlertView) {
        NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:NSLocalizedString(@"Yes", nil)]) {
            [self deleteBookmarks:@[self.bookmark]];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [self.heights count];
    }
    else {
        return [self.filteredHeights count];
    }
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return [self.heights[indexPath.row] floatValue];
    }
    else {
        return [self.filteredHeights[indexPath.row] floatValue];
    }
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

- (void)toggleMultipleDeletion:(id)sender {
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    NSMutableArray *bookmarks = [NSMutableArray arrayWithCapacity:[selectedIndexPaths count]];
    for (NSIndexPath *indexPath in selectedIndexPaths) {
        [bookmarks addObject:self.bookmarks[indexPath.row]];
    }

    dispatch_group_async(group, queue, ^{
        [self deleteBookmarks:bookmarks];
    });

    dispatch_group_notify(group, queue, ^{
        dispatch_async(queue, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [selectedIndexPaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [self.tableView deselectRowAtIndexPath:obj animated:YES];
                }];
                [self.tableView setEditing:NO animated:YES];
                [self.navigationItem setHidesBackButton:NO animated:YES];
                [self.editButton setStyle:UIBarButtonItemStylePlain];
                [self.editButton setTitle:@"Edit"];

                [UIView animateWithDuration:0.25 animations:^{
                    CGRect bounds = [[UIScreen mainScreen] bounds];
                    CGRect frame = CGRectMake(0, bounds.size.height, bounds.size.width, 44);
                    self.toolbar.frame = frame;
                }];
            });
        });
    });

    dispatch_release(group);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        NSUInteger selectedRowCount = [tableView.indexPathsForSelectedRows count];
        self.multipleDeleteButton.enabled = YES;
        [self.multipleDeleteButton setTitle:[NSString stringWithFormat:@"Delete (%d)", selectedRowCount]];
    }
    else {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];

        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        if (tableView == self.tableView) {
            self.bookmark = self.bookmarks[indexPath.row];
        }
        else {
            self.bookmark = self.filteredBookmarks[indexPath.row];
        }

        switch ([[[AppDelegate sharedDelegate] browser] integerValue]) {
            case BROWSER_WEBVIEW: {
                [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Webview"}];
                TSMiniWebBrowser *webBrowser = [[TSMiniWebBrowser alloc] initWithUrl:[NSURL URLWithString:self.bookmark[@"url"]]];
                webBrowser.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:webBrowser animated:YES];
                break;
            }

            case BROWSER_SAFARI: {
                [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Safari"}];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.bookmark[@"url"]]];
                break;
            }

            case BROWSER_CHROME:
                if ([self.bookmark[@"url"] hasPrefix:@"http"]) {
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome-x-callback://"]]) {
                        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"googlechrome-x-callback://x-callback-url/open/?url=%@&x-success=pushpin%%3A%%2F%%2F&&x-source=Pushpin", [self.bookmark[@"url"] urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
                        [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Chrome"}];
                        [[UIApplication sharedApplication] openURL:url];
                    }
                    else {
                        NSURL *url = [NSURL URLWithString:[self.bookmark[@"url"] stringByReplacingCharactersInRange:[self.bookmark[@"url"] rangeOfString:@"http"] withString:@"googlechrome"]];
                        [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Chrome"}];
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Disappointment", nil) message:NSLocalizedString(@"Google Chrome failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                    [alert show];
                }

                break;

            case BROWSER_ICAB_MOBILE:
                if ([self.bookmark[@"url"] hasPrefix:@"http"]) {
                    NSURL *url = [NSURL URLWithString:[self.bookmark[@"url"] stringByReplacingCharactersInRange:[self.bookmark[@"url"] rangeOfString:@"http"] withString:@"icabmobile"]];
                    [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"iCab Mobile"}];
                    [[UIApplication sharedApplication] openURL:url];
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Disappointment", nil) message:NSLocalizedString(@"iCab Mobile failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                    [alert show];
                }

            break;
            
            case BROWSER_OPERA:
                if ([self.bookmark[@"url"] hasPrefix:@"http"]) {
                    NSURL *url = [NSURL URLWithString:[self.bookmark[@"url"] stringByReplacingCharactersInRange:[self.bookmark[@"url"] rangeOfString:@"http"] withString:@"ohttp"]];
                    [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Opera"}];
                    [[UIApplication sharedApplication] openURL:url];
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Disappointment", nil) message:NSLocalizedString(@"Opera failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                    [alert show];
                }
                
                break;
                
            case BROWSER_DOLPHIN:
                if ([self.bookmark[@"url"] hasPrefix:@"http"]) {
                    NSURL *url = [NSURL URLWithString:[self.bookmark[@"url"] stringByReplacingCharactersInRange:[self.bookmark[@"url"] rangeOfString:@"http"] withString:@"dolphin"]];
                    [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"dolphin"}];
                    [[UIApplication sharedApplication] openURL:url];
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Disappointment", nil) message:NSLocalizedString(@"iCab Mobile failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                    [alert show];
                }
                
                break;
                
            case BROWSER_CYBERSPACE:
                if ([self.bookmark[@"url"] hasPrefix:@"http"]) {
                    NSURL *url = [NSURL URLWithString:[self.bookmark[@"url"] stringByReplacingCharactersInRange:[self.bookmark[@"url"] rangeOfString:@"http"] withString:@"cyber"]];
                    [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Cyberspace Browser"}];
                    [[UIApplication sharedApplication] openURL:url];
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Disappointment", nil) message:NSLocalizedString(@"iCab Mobile failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                    [alert show];
                }
                
                break;

            default:
                break;
        }
    }
}

#pragma mark - Menu

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
    if (!self.shouldShowContextMenu) {
        return NO;
    }
    
    self.selectedIndexPath = indexPath;
    
    // XXX - are there other tableviews?
    self.bookmark = self.bookmarks[self.selectedIndexPath.row];
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        self.bookmark = self.filteredBookmarks[self.selectedIndexPath.row];
    }
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (![[[AppDelegate sharedDelegate] connectionAvailable] boolValue]) {
        return (action == @selector(copyTitle:) || action == @selector(copyURL:));
    }
    
    if ([[AppDelegate sharedDelegate] readlater] != nil) {
        if (action == @selector(readLater:)) {
            return YES;
        }
    }
    
    if (action == @selector(markBookmarkAsRead:)) {
        return [self.bookmark[@"unread"] boolValue];
    }

    return (action == @selector(copyTitle:) || action == @selector(copyURL:) || action == @selector(editBookmark:) || action == @selector(confirmDeletion:));
}

- (void)editBookmark:(id)sender {
    [[AppDelegate sharedDelegate] showAddBookmarkViewControllerWithBookmark:self.bookmark update:@(YES) callback:nil];
}

- (void)copyTitle:(id)sender {
    UIView *view;
    if (self.isSearchTable.boolValue) {
        view = self.searchDisplayController.searchContentsController.view;
    }
    else {
        view = self.navigationController.navigationBar;
    }

    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"Title copied to clipboard.", nil);
    notification.userInfo = @{@"success": @YES, @"updated": @NO};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];

    [[UIPasteboard generalPasteboard] setString:self.bookmark[@"title"]];
    [[Mixpanel sharedInstance] track:@"Copied title"];
}

- (void)copyURL:(id)sender {
    UIView *view;
    if (self.isSearchTable.boolValue) {
        view = self.searchDisplayController.searchContentsController.view;
    }
    else {
        view = self.navigationController.navigationBar;
    }

    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"URL copied to clipboard.", nil);
    notification.userInfo = @{@"success": @YES, @"updated": @NO};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];

    [[UIPasteboard generalPasteboard] setString:self.bookmark[@"url"]];
    [[Mixpanel sharedInstance] track:@"Copied URL"];
}

- (void)readLater:(id)sender {
    NSNumber *readLater = [[AppDelegate sharedDelegate] readlater];
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
        [parameters addObject:[OARequestParameter requestParameter:@"url" value:self.bookmark[@"url"]]];
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

                                       if (httpResponse.statusCode == 403) {
                                           [[AppDelegate sharedDelegate] setReadlater:@(READLATER_NONE)];
                                       }
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
        [request setParameters:@[[OARequestParameter requestParameter:@"url" value:self.bookmark[@"url"]]]];
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

                                       if (httpResponse.statusCode == 403) {
                                           [[AppDelegate sharedDelegate] setReadlater:@(READLATER_NONE)];
                                       }
                                   }
                                   [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                               }];
    }
    else if (readLater.integerValue == READLATER_POCKET) {
        [[PocketAPI sharedAPI] saveURL:[NSURL URLWithString:self.bookmark[@"url"]]
                             withTitle:self.bookmark[@"title"]
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

- (void)share:(id)sender {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.bookmark[@"title"], self.bookmark[@"url"]] applicationActivities:nil];
    [self presentModalViewController:activityViewController animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    self.selectedIndexPath = indexPath;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        self.bookmark = self.filteredBookmarks[self.selectedIndexPath.row];
    }
    else {
        self.bookmark = self.bookmarks[self.selectedIndexPath.row];
    }
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"BookmarkCell";

    BookmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[BookmarkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }

    NSAttributedString *string;
    NSDictionary *bookmark;

    if (tableView == self.tableView) {
        string = self.strings[indexPath.row];
        bookmark = self.bookmarks[indexPath.row];
    }
    else {
        string = self.filteredStrings[indexPath.row];
        bookmark = self.filteredBookmarks[indexPath.row];
    }

    [cell.textView setText:string];
    
    for (NSDictionary *link in [BookmarkViewController linksForBookmark:bookmark]) {
        [cell.textView addLinkToURL:link[@"url"] withRange:NSMakeRange([link[@"location"] integerValue], [link[@"length"] integerValue])];
    }
    
    for (id subview in [cell.contentView subviews]) {
        if (![subview isKindOfClass:[TTTAttributedLabel class]]) {
            [subview removeFromSuperview];
        }
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(-40, 0, 360, [self.heights[indexPath.row] floatValue])];

    if ([bookmark[@"private"] boolValue] == YES) {
        cell.textView.backgroundColor = HEX(0xddddddff);
        label.backgroundColor = HEX(0xddddddff);
    }
    else {
        cell.textView.backgroundColor = HEX(0xffffffff);
        label.backgroundColor = HEX(0xffffffff);
    }
    
    if (tableView == self.tableView) {
        [cell.contentView addSubview:label];
        [cell.contentView sendSubviewToBack:label];
    }

    cell.textView.delegate = self;
    cell.textView.userInteractionEnabled = YES;

    return cell;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didStartTouchWithTextCheckingResult:(NSTextCheckingResult *)result {
    self.shouldShowContextMenu = NO;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didCancelTouchWithTextCheckingResult:(NSTextCheckingResult *)result {
    self.shouldShowContextMenu = YES;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    self.shouldShowContextMenu = YES;
    NSNumber *tag_id;
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    NSString *tag = [url.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    FMResultSet *results = [db executeQuery:@"SELECT id FROM tag WHERE name=?" withArgumentsInArray:@[tag]];
    [results next];
    tag_id = [results objectForColumnIndex:0];
    [db close];

    BookmarkViewController *bookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT bookmark.* FROM bookmark LEFT JOIN tagging ON bookmark.id = tagging.bookmark_id LEFT JOIN tag ON tag.id = tagging.tag_id WHERE tag.id=:tag_id ORDER BY created_at DESC LIMIT :limit OFFSET :offset" parameters:[NSMutableDictionary dictionaryWithObjectsAndKeys:tag_id, @"tag_id", nil]];
    bookmarkViewController.title = tag;
    [self.navigationController pushViewController:bookmarkViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView != self.tableView) {
        return;
    }
    if (indexPath.row >= self.limit.integerValue / 2 && !self.processingBookmarks) {
        self.limit = @(self.limit.integerValue * 2);
        self.queryParameters[@"limit"] = limit;
        [self processBookmarks];
    }
}

#pragma mark - Action Sheet Delegate

- (void)openActionSheetForBookmark:(NSDictionary *)bookmark {
    NSString *urlString;
    if ([self.bookmark[@"url"] length] > 67) {
        urlString = [NSString stringWithFormat:@"%@...", [self.bookmark[@"url"] substringToIndex:67]];
    }
    else {
        urlString = self.bookmark[@"url"];
    }
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:urlString delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    NSInteger cancelButtonIndex = 5;
    [sheet addButtonWithTitle:NSLocalizedString(@"Delete Bookmark", nil)];
    [sheet addButtonWithTitle:NSLocalizedString(@"Edit Bookmark", nil)];
    
    if ([bookmark[@"unread"] boolValue]) {
        [sheet addButtonWithTitle:NSLocalizedString(@"Mark as read", nil)];
    }
    else {
        cancelButtonIndex--;
    }

    sheet.destructiveButtonIndex = 0;
    [sheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];
    // [sheet addButtonWithTitle:NSLocalizedString(@"Copy Title", nil)];

    NSNumber *readlater = [[AppDelegate sharedDelegate] readlater];
    
    if (readlater.integerValue == READLATER_INSTAPAPER) {
        [sheet addButtonWithTitle:NSLocalizedString(@"Send to Instapaper", nil)];
    }
    else if (readlater.integerValue == READLATER_READABILITY) {
        [sheet addButtonWithTitle:NSLocalizedString(@"Send to Readability", nil)];
    }
    else if (readlater.integerValue == READLATER_POCKET) {
        [sheet addButtonWithTitle:NSLocalizedString(@"Send to Pocket", nil)];
    }
    else {
        cancelButtonIndex--;
    }

    sheet.cancelButtonIndex = cancelButtonIndex;

    [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [sheet showInView:self.tableView];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:NSLocalizedString(@"Delete Bookmark", nil)]) {
        [self confirmDeletion:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Edit Bookmark", nil)]) {
        [[AppDelegate sharedDelegate] showAddBookmarkViewControllerWithBookmark:self.bookmark update:@(YES) callback:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Mark as read", nil)]) {
        [self markBookmarkAsRead:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Instapaper", nil)]) {
        [self readLater:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Readability", nil)]) {
        [self readLater:nil];        
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Pocket", nil)]) {
        [self readLater:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Copy URL", nil)]) {
        [self copyURL:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Copy Title", nil)]) {
        [self copyTitle:nil];
    }
}

- (void)confirmDeletion:(id)sender {
    self.confirmDeleteAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil) message:NSLocalizedString(@"Delete Bookmark Warning", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
    [self.confirmDeleteAlertView show];
}

- (void)deleteBookmarks:(NSArray *)bookmarks {
    self.timerPaused = YES;
    void (^SuccessBlock)();
    void (^ErrorBlock)(NSError *);

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    ASPinboard *pinboard = [ASPinboard sharedInstance];
    for (NSDictionary *bookmark in bookmarks) {
        SuccessBlock = ^{
            dispatch_group_async(group, queue, ^{
                FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                [db open];

                FMResultSet *results = [db executeQuery:@"SELECT id FROM bookmark WHERE url=?" withArgumentsInArray:@[bookmark[@"url"]]];
                [results next];
                NSNumber *bookmarkId = @([results intForColumnIndex:0]);

                [db beginTransaction];
                [db executeUpdate:@"DELETE FROM bookmark WHERE url=?" withArgumentsInArray:@[bookmark[@"url"]]];
                [db executeUpdate:@"DELETE FROM tagging WHERE bookmark_id=?" withArgumentsInArray:@[bookmarkId]];
                [db commit];
                [db close];

                [[Mixpanel sharedInstance] track:@"Deleted bookmark"];
                self.timerPaused = NO;

                NSUInteger index = [self.bookmarks indexOfObject:bookmark];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [self.bookmarks removeObjectAtIndex:index];
                [self.heights removeObjectAtIndex:index];
                [self.strings removeObjectAtIndex:index];

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                        [self.tableView endUpdates];
                    });
                });
            });
        };

        ErrorBlock = ^(NSError *error) {
        };

        [pinboard deleteBookmarkWithURL:bookmark[@"url"] success:SuccessBlock failure:ErrorBlock];
    }

    dispatch_group_notify(group, queue, ^{
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertAction = @"Open Pushpin";
        notification.userInfo = @{@"success": @YES, @"updated": @NO};
        if ([bookmarks count] == 1) {
            notification.alertBody = NSLocalizedString(@"Bookmark Deleted Message", nil);
        }
        else {
            notification.alertBody = [NSString stringWithFormat:@"%d bookmarks were deleted.", [bookmarks count]];
        }
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        self.timerPaused = NO;
    });
}

#pragma mark - Swipe to delete

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.tableView == tableView;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView == tableView) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSDictionary *bookmark = self.bookmarks[indexPath.row];
            [self deleteBookmarks:@[bookmark]];
            [[Mixpanel sharedInstance] track:@"Swiped to delete"];
        }
        else if (editingStyle == UITableViewCellEditingStyleNone) {

        }
    }
}

- (void)toggleEditingMode:(id)sender {
    if (self.tableView.editing) {
        NSArray *selectedIndexPaths = [self.tableView.indexPathsForSelectedRows copy];
        for (NSIndexPath *indexPath in selectedIndexPaths) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }

        [self.tableView setEditing:NO animated:YES];
        [self.navigationItem setHidesBackButton:NO animated:YES];
        [self.editButton setStyle:UIBarButtonItemStylePlain];
        [self.editButton setTitle:@"Edit"];
        [UIView animateWithDuration:0.25 animations:^{
            CGRect bounds = [[UIScreen mainScreen] bounds];
            CGRect frame = CGRectMake(0, bounds.size.height, bounds.size.width, 44);
            self.toolbar.frame = frame;
        }];
    }
    else {
        [self.tableView setEditing:YES animated:YES];
        [self.navigationItem setHidesBackButton:YES animated:YES];
        [self.editButton setStyle:UIBarButtonItemStyleDone];
        [self.editButton setTitle:@"Done"];
        [self.multipleDeleteButton setTitle:@"Delete (0)"];
        self.multipleDeleteButton.enabled = NO;

        [UIView animateWithDuration:0.25 animations:^{
            CGRect bounds = [[UIScreen mainScreen] bounds];
            CGRect frame = CGRectMake(0, bounds.size.height - 44, bounds.size.width, 44);
            self.toolbar.frame = frame;
        }];
    }
}

#pragma mark - Bookmark Helpers

+ (NSNumber *)heightForBookmark:(NSDictionary *)bookmark {
    UIFont *largeHelvetica = [UIFont fontWithName:kFontName size:kLargeFontSize];
    UIFont *smallHelvetica = [UIFont fontWithName:kFontName size:kSmallFontSize];
    
    CGFloat height = 12.0f;
    height += ceilf([bookmark[@"title"] sizeWithFont:largeHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);

    if (![bookmark[@"description"] isEqualToString:@""]) {
        height += ceilf([bookmark[@"description"] sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    }
    
    if (![bookmark[@"tags"] isEqualToString:@""]) {
        height += ceilf([bookmark[@"tags"] sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    }

    return @(height);
}

+ (NSMutableAttributedString *)attributedStringForBookmark:(NSDictionary *)bookmark {
    UIFont *largeHelvetica = [UIFont fontWithName:kFontName size:kLargeFontSize];
    UIFont *smallHelvetica = [UIFont fontWithName:kFontName size:kSmallFontSize];

    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", bookmark[@"title"]];
    NSRange titleRange = NSMakeRange(0, [bookmark[@"title"] length]);
    NSRange descriptionRange = {};
    NSRange tagRange = {};
    int newLineCount = 1;
    if (![bookmark[@"description"] isEqualToString:@""]) {
        [content appendString:[NSString stringWithFormat:@"\n%@", bookmark[@"description"]]];
        descriptionRange = NSMakeRange(titleRange.length + newLineCount, [bookmark[@"description"] length]);
        newLineCount++;
    }

    if (![bookmark[@"tags"] isEqualToString:@""]) {
        [content appendString:[NSString stringWithFormat:@"\n%@", bookmark[@"tags"]]];
        tagRange = NSMakeRange(titleRange.length + descriptionRange.length + newLineCount, [bookmark[@"tags"] length]);
    }
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
    [attributedString setFont:largeHelvetica range:titleRange];
    [attributedString setFont:smallHelvetica range:descriptionRange];
    [attributedString setFont:smallHelvetica range:tagRange];
    [attributedString setTextColor:HEX(0x555555ff)];
    
    if (![bookmark[@"unread"] boolValue]) {
        [attributedString setTextColor:HEX(0x2255aaff) range:titleRange];
    }
    else {
        [attributedString setTextColor:HEX(0xcc2222ff) range:titleRange];
    }
    
    if (![bookmark[@"tags"] isEqualToString:@""]) {
        [attributedString setTextColor:HEX(0xcc2222ff) range:tagRange];
    }
    
    [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
    return attributedString;
}

+ (NSArray *)linksForBookmark:(NSDictionary *)bookmark {
    NSMutableArray *links = [NSMutableArray array];
    int location = [bookmark[@"title"] length] + 1;
    if (![bookmark[@"description"] isEqualToString:@""]) {
        location += [bookmark[@"description"] length] + 1;
    }
    
    if (![bookmark[@"tags"] isEqualToString:@""]) {
        for (NSString *tag in [bookmark[@"tags"] componentsSeparatedByString:@" "]) {
            NSRange range = [bookmark[@"tags"] rangeOfString:tag];
            [links addObject:@{@"url": [NSURL URLWithString:[tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]], @"location": @(location+range.location), @"length": @(range.length)}];
        }
    }
    return links;
}

@end
