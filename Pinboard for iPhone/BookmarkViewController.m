//
//  PostViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookmarkViewController.h"
#import "BookmarkCell.h"
#import "NSAttributedString+Attributes.h"
#import "TTTAttributedLabel.h"
#import "NSString+URLEncoding.h"

@interface BookmarkViewController ()

@end

@implementation BookmarkViewController

@synthesize selectedIndexPath;
@synthesize parameters = _parameters;
@synthesize bookmarks;
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

- (void)reloadTableData {
    [[AppDelegate sharedDelegate] updateBookmarksWithDelegate:self];
    [self.tableView reloadData];
}

- (void)bookmarkUpdateEvent {
    [self processBookmarks];
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

	[self processBookmarks];
	self.tableView.scrollEnabled = YES;
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchDisplayController.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView setContentOffset:CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height)];
    
    // self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStylePlain target:self action:@selector(toggleEditMode)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bookmarkUpdated:)
                                                 name:@"BookmarkUpdated"
                                               object:nil];

    // menu
    if (![self becomeFirstResponder]) {
        NSLog(@"Couldn't become first responder ");
        return;
    }

    NSMutableArray *items = [NSMutableArray array];
    UIMenuItem *copyURLMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy URL", nil) action:@selector(copyURL:)];
    UIMenuItem *copyTitleMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Title", nil) action:@selector(copyTitle:)];
    
    UIMenuItem *shareMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Share", nil) action:@selector(share:)];
    UIMenuItem *markReadMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Mark as read", nil) action:@selector(markBookmarkAsRead:)];
    UIMenuItem *editBookmarkMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Edit", nil) action:@selector(editBookmark:)];
    UIMenuItem *deleteBookmarkMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete", nil) action:@selector(confirmDeletion:)];

    NSNumber *readLater = [[AppDelegate sharedDelegate] readlater];
    if (readLater.integerValue == READLATER_INSTAPAPER) {
        UIMenuItem *readLaterMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Instapaper", nil) action:@selector(readLater:)];
        [items addObject:readLaterMenuItem];
    }
    else if (readLater.integerValue == READLATER_READABILITY) {
        UIMenuItem *readLaterMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Readability", nil) action:@selector(readLater:)];
        [items addObject:readLaterMenuItem];
    }

    [items addObject:markReadMenuItem];
    [items addObject:shareMenuItem];
    [items addObject:editBookmarkMenuItem];
    [items addObject:deleteBookmarkMenuItem];
    
//    [items addObject:copyURLMenuItem];
//    [items addObject:copyTitleMenuItem];
    
    [[UIMenuController sharedMenuController] setMenuItems:items];
    [[UIMenuController sharedMenuController] update];

    // long press
    // UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    // [self.view addGestureRecognizer:longPress];
}

- (void)longPress:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
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

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    [self.tableView reloadData];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.filteredBookmarks = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"BookmarkUpdated"
                                                  object:nil];
}

- (void)processBookmarks {
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:self.query withParameterDictionary:self.queryParameters];

    [self.bookmarks removeAllObjects];
    [self.strings removeAllObjects];
    [self.heights removeAllObjects];

    while ([results next]) {
        NSDictionary *bookmark = @{
            @"title": [results stringForColumn:@"title"],
            @"description": [results stringForColumn:@"description"],
            @"unread": [results objectForColumnName:@"unread"],
            @"url": [results stringForColumn:@"url"],
            @"private": [results objectForColumnName:@"private"],
            @"tags": [results stringForColumn:@"tags"],
        };
        
        [self.bookmarks addObject:bookmark];
        [self.heights addObject:[BookmarkViewController heightForBookmark:bookmark]];
        [self.strings addObject:[BookmarkViewController attributedStringForBookmark:bookmark]];
    }

    [db close];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

- (id)initWithQuery:(NSString *)query parameters:(NSMutableDictionary *)parameters {
    // initWithQuery:@"SELECT * FROM bookmark WHERE name = :name LIMIT :limit OFFSET :offset" arguments:@{@"name": @"dan"}
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.limit = @(50);

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
        
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        self.tableView.separatorColor = HEX(0xD1D1D1ff);

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processBookmarks)
                                                     name:@"BookmarksLoaded"
                                                   object:nil];

    }
    return self;
}

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.limit = @(50);

        self.bookmarks = [NSMutableArray array];
        self.parameters = [NSMutableArray array];
        self.strings = [NSMutableArray array];
        self.heights = [NSMutableArray array];
        self.date_formatter = [[NSDateFormatter alloc] init];
        [self.date_formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [self.date_formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

        self.query = @"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
        self.queryParameters = [[NSMutableDictionary alloc] initWithObjectsAndKeys:limit, @"limit", @(0), "offset", nil];

        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        self.tableView.separatorColor = HEX(0xD1D1D1ff);
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processBookmarks)
                                                     name:@"BookmarksLoaded"
                                                   object:nil];
    }
    return self;
}

- (void)toggleEditMode {
    if (self.tableView.editing) {
        [self.tableView setEditing:NO animated:YES];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", nil)
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(toggleEditMode)];
    }
    else {
        [self.tableView setEditing:YES animated:YES];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(toggleEditMode)];
    }
}

- (void)markBookmarkAsRead:(id)sender {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/get?auth_token=%@&format=json&url=%@", [[AppDelegate sharedDelegate] token], [self.bookmark[@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                               NSLog(@"%@", payload);
                               NSDictionary *bookmark = payload[@"posts"][0];
                               
                               NSString *urlString = [[NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/add?auth_token=%@&format=json&url=%@&description=%@&extended=%@&replace=yes&tags=%@&shared=%@toread=no", [[AppDelegate sharedDelegate] token], bookmark[@"href"], bookmark[@"description"], bookmark[@"extended"], bookmark[@"tags"], bookmark[@"shared"]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                               NSURL *url = [NSURL URLWithString:urlString];
                               NSLog(@"%@", urlString);
                               NSURLRequest *request = [NSURLRequest requestWithURL:url];
                               [NSURLConnection sendAsynchronousRequest:request
                                                                  queue:[NSOperationQueue mainQueue]
                                                      completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                                          [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                                          if (!error) {
                                                              FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                                              [db open];
                                                              BOOL success = [db executeUpdate:@"UPDATE bookmark SET unread=0 WHERE hash=?" withArgumentsInArray:@[bookmark[@"hash"]]];
                                                              [db close];
                                                              
                                                              if (success) {
                                                                  [self processBookmarks];
                                                                  
                                                                  if (self.savedSearchTerm) {
                                                                      [self updateSearchResults];
                                                                  }
                                                                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:NSLocalizedString(@"Bookmark Updated Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                                                  [alert show];
                                                                  return;
                                                              }
                                                          }
                                                          else {
                                                              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Error", nil) message:NSLocalizedString(@"Bookmark Update Error Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                                              [alert show];
                                                          }
                                                      }];
                           }];
    
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self.confirmDeleteAlertView) {
        NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:@"Yes"]) {
            [self deleteBookmark:nil];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.bookmark[@"url"]]];
            self.webView = [[UIWebView alloc] init];
            self.webView.scalesPageToFit = YES;
            self.webView.delegate = self;
            [self.webView loadRequest:request];
            self.bookmarkDetailViewController = [[UIViewController alloc] init];
            self.bookmarkDetailViewController.title = self.bookmark[@"title"];
            self.webView.frame = self.bookmarkDetailViewController.view.frame;
            self.bookmarkDetailViewController.view = self.webView;
            self.bookmarkDetailViewController.hidesBottomBarWhenPushed = YES;
//            self.bookmarkDetailViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openActionSheetForBookmark:)];
            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Webview"}];
            [self.navigationController pushViewController:self.bookmarkDetailViewController animated:YES];
            break;
        }
            
        case BROWSER_SAFARI: {
            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Safari"}];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.bookmark[@"url"]]];
            break;
        }
            
        case BROWSER_CHROME:
            // XXX
            if ([self.bookmark[@"url"] hasPrefix:@"http"]) {
                NSURL *url = [NSURL URLWithString:[self.bookmark[@"url"] stringByReplacingCharactersInRange:[self.bookmark[@"url"] rangeOfString:@"http"] withString:@"googlechrome"]];
                [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Chrome"}];
                [[UIApplication sharedApplication] openURL:url];
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Disappointment", nil) message:NSLocalizedString(@"Google Chrome failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                [alert show];
            }

            break;
            
        default:
            break;
    }
}

#pragma mark - Menu

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if ([[AppDelegate sharedDelegate] readlater] != nil) {
        if (action == @selector(readLater:)) {
            return YES;
        }
    }
    return (action == @selector(copyTitle:) || action == @selector(markBookmarkAsRead:) || action == @selector(copyURL:) || action == @selector(editBookmark:) || action == @selector(confirmDeletion:));
}

- (void)editBookmark:(id)sender {
    [[AppDelegate sharedDelegate] showAddBookmarkViewControllerWithBookmark:self.bookmark andDelegate:self];
}

- (void)copyTitle:(id)sender {
    [[UIPasteboard generalPasteboard] setString:self.bookmark[@"title"]];
    [[Mixpanel sharedInstance] track:@"Copied title"];
}

- (void)copyURL:(id)sender {
    [[UIPasteboard generalPasteboard] setString:self.bookmark[@"url"]];
    [[Mixpanel sharedInstance] track:@"Copied URL"];
}

- (void)readLater:(id)sender {
    NSNumber *readLater = [[AppDelegate sharedDelegate] readlater];
    NSURL *url = [NSURL URLWithString:self.bookmark[@"url"]];
    NSString *scheme = [NSString stringWithFormat:@"%@://", url.scheme];
    if (readLater.integerValue == READLATER_INSTAPAPER) {
        NSURL *newURL = [NSURL URLWithString:[self.bookmark[@"url"] stringByReplacingCharactersInRange:[self.bookmark[@"url"] rangeOfString:scheme] withString:@"x-callback-instapaper://x-callback-url/add?x-source=Pushpin&x-success=pushpin://&url="]];
        [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Instapaper"}];
        [[UIApplication sharedApplication] openURL:newURL];
    }
    else {
        NSURL *newURL = [NSURL URLWithString:[self.bookmark[@"url"] stringByReplacingCharactersInRange:[self.bookmark[@"url"] rangeOfString:scheme] withString:@"readability://add/"]];
        [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Readability"}];
        [[UIApplication sharedApplication] openURL:newURL];
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

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"BookmarkCell";

    BookmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[BookmarkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
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

    if ([bookmark[@"private"] boolValue] == YES) {
        cell.textView.backgroundColor = HEX(0xddddddff);
        cell.contentView.backgroundColor = HEX(0xddddddff);
    }
    else {
        cell.textView.backgroundColor = HEX(0xffffffff);
        cell.contentView.backgroundColor = HEX(0xffffffff);
    }

    cell.textView.delegate = self;
    cell.textView.userInteractionEnabled = YES;
    return cell;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    NSNumber *tag_id;
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT id FROM tag WHERE name=?" withArgumentsInArray:@[url.absoluteString]];
    [results next];
    tag_id = [results objectForColumnIndex:0];
    [db close];

    BookmarkViewController *bookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT bookmark.* FROM bookmark LEFT JOIN tagging ON bookmark.id = tagging.bookmark_id LEFT JOIN tag ON tag.id = tagging.tag_id WHERE tag.id = :tag_id LIMIT :limit OFFSET :offset" parameters:[NSMutableDictionary dictionaryWithObjectsAndKeys:tag_id, @"tag_id", nil]];
    bookmarkViewController.title = url.absoluteString;
    [self.navigationController pushViewController:bookmarkViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView != self.tableView) {
        return;
    }
    if (indexPath.row == self.limit.integerValue - 5) {
        self.limit = @(self.limit.integerValue + 50);
        self.queryParameters[@"limit"] = limit;

        [self processBookmarks];
    }
}

#pragma mark - Webview Delegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - Action Sheet Delegate

- (void)openActionSheetForBookmark:(NSDictionary *)bookmark {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [sheet addButtonWithTitle:NSLocalizedString(@"Delete Bookmark", nil)];
    [sheet addButtonWithTitle:NSLocalizedString(@"Edit Bookmark", nil)];
    [sheet addButtonWithTitle:NSLocalizedString(@"Mark as read", nil)];
    [sheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];
    [sheet addButtonWithTitle:NSLocalizedString(@"Copy Title", nil)];
    
    NSNumber *readlater = [[AppDelegate sharedDelegate] readlater];
    sheet.cancelButtonIndex = 6;
    if (readlater.integerValue == READLATER_INSTAPAPER) {
        [sheet addButtonWithTitle:@"Send to Instapaper"];
    }
    else if (readlater.integerValue == READLATER_READABILITY) {
        [sheet addButtonWithTitle:@"Send to Readability"];
    }
    else {
        sheet.cancelButtonIndex = 5;
    }

    [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    sheet.destructiveButtonIndex = 0;
    [sheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:NSLocalizedString(@"Delete Bookmark", nil)]) {
        [self confirmDeletion:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Edit Bookmark", nil)]) {
        [[AppDelegate sharedDelegate] showAddBookmarkViewControllerWithBookmark:self.bookmark andDelegate:self];
    }
    else if ([title isEqualToString:@"Send to Instapaper"]) {
        [self readLater:nil];
    }
    else if ([title isEqualToString:@"Send to Readability"]) {
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
    self.confirmDeleteAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil) message:@"Are you sure you want to delete this bookmark?" delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
    [self.confirmDeleteAlertView show];
}

- (void)deleteBookmark:(id)sender {
    NSString *url = [NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/delete?format=json&auth_token=%@&url=%@", [[AppDelegate sharedDelegate] token], [self.bookmark[@"url"] urlEncodeUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (!error) {
                                   FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                   [db open];
                                   
                                   FMResultSet *results = [db executeQuery:@"SELECT id FROM bookmark WHERE url=?" withArgumentsInArray:@[self.bookmark[@"url"]]];
                                   [results next];
                                   NSNumber *bookmarkId = @([results intForColumnIndex:0]);
                                   
                                   [db beginTransaction];
                                   [db executeUpdate:@"DELETE FROM bookmark WHERE url=?" withArgumentsInArray:@[self.bookmark[@"url"]]];
                                   [db executeUpdate:@"DELETE FROM taggings WHERE bookmark_id=?" withArgumentsInArray:@[bookmarkId]];
                                   [db commit];
                                   [db close];

                                   [self processBookmarks];
                                   
                                   if (self.savedSearchTerm) {
                                       [self updateSearchResults];
                                   }

                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:NSLocalizedString(@"Your bookmark was deleted.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                   [alert show];
                                   
                                   [[Mixpanel sharedInstance] track:@"Deleted bookmark"];

                                   if (self.navigationController.visibleViewController != self) {
                                       [self.navigationController popViewControllerAnimated:YES];
                                   }
                               }
                           }];
}

/* XXX
#pragma mark - Swipe to delete

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *bookmark = self.bookmarks[indexPath.row];
        [self deleteBookmark:bookmark atIndexPath:indexPath];
    }
}
 */

#pragma mark - Bookmark Helpers

+ (NSNumber *)heightForBookmark:(NSDictionary *)bookmark {
    UIFont *largeHelvetica = [UIFont fontWithName:kFontName size:kLargeFontSize];
    UIFont *smallHelvetica = [UIFont fontWithName:kFontName size:kSmallFontSize];
    
    CGFloat height = 10.0f;
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
            [links addObject:@{@"url": [NSURL URLWithString:tag], @"location": @(location+range.location), @"length": @(range.length)}];
        }
    }
    return links;
}

@end
