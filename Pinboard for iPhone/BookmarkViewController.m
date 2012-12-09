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

- (void)reloadTableData {
    [[AppDelegate sharedDelegate] updateBookmarksWithDelegate:self];
    [self.tableView reloadData];
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
    [self.tableView setContentOffset:CGPointMake(0,self.searchDisplayController.searchBar.frame.size.height)];
    
    // self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStylePlain target:self action:@selector(toggleEditMode)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if(![self becomeFirstResponder])
    {
        NSLog(@"Couldn't become first responder ");
        return;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSMutableArray *items = [NSMutableArray array];
    UIMenuItem *copyURLMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy URL", nil) action:@selector(copyURL:)];
    UIMenuItem *copyTitleMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Title", nil) action:@selector(copyTitle:)];

    UIMenuItem *shareMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Share", nil) action:@selector(share:)];
    UIMenuItem *editBookmarkMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Edit", nil) action:@selector(editBookmark:)];
    UIMenuItem *deleteBookmarkMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete", nil) action:@selector(deleteBookmark:)];

    NSNumber *readLater = [[AppDelegate sharedDelegate] readlater];
    if (readLater.integerValue == READLATER_INSTAPAPER) {
        UIMenuItem *readLaterMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Instapaper", nil) action:@selector(readLater:)];
        [items addObject:readLaterMenuItem];
    }
    else if (readLater.integerValue == READLATER_READABILITY) {
        UIMenuItem *readLaterMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Readability", nil) action:@selector(readLater:)];
        [items addObject:readLaterMenuItem];
    }
    
    [items addObject:copyURLMenuItem];
    [items addObject:copyTitleMenuItem];
    [items addObject:shareMenuItem];
    
    [[UIMenuController sharedMenuController] setMenuItems:items];
    [[UIMenuController sharedMenuController] update];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];

    FMResultSet *results = [db executeQuery:@"SELECT bookmark.* FROM bookmark, bookmark_fts WHERE bookmark.id=bookmark_fts.id AND bookmark_fts MATCH ?" withArgumentsInArray:@[[searchText stringByAppendingString:@"*"]]];

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
}

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
    if (![bookmark[@"description"] isEqualToString:@""]) {
        [content appendString:[NSString stringWithFormat:@"\n%@", bookmark[@"description"]]];
    }
    if (![bookmark[@"tags"] isEqualToString:@""]) {
        [content appendString:[NSString stringWithFormat:@"\n%@", bookmark[@"tags"]]];
    }
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
    
    [attributedString setFont:largeHelvetica range:[content rangeOfString:bookmark[@"title"]]];
    [attributedString setFont:smallHelvetica range:[content rangeOfString:bookmark[@"description"]]];
    [attributedString setTextColor:HEX(0x555555ff)];

    if (![bookmark[@"unread"] boolValue]) {
        [attributedString setTextColor:HEX(0x2255aaff) range:[content rangeOfString:bookmark[@"title"]]];
    }
    else {
        [attributedString setTextColor:HEX(0xcc2222ff) range:[content rangeOfString:bookmark[@"title"]]];
    }
    
    if (![bookmark[@"tags"] isEqualToString:@""]) {
        [attributedString setTextColor:HEX(0xcc2222ff) range:[content rangeOfString:bookmark[@"tags"]]];
    }

    [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
    return attributedString;
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
        self.filteredHeights = [NSMutableArray array];
        self.filteredStrings = [NSMutableArray array];
        self.filteredBookmarks = [NSMutableArray array];
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
        
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        self.searchBar = searchBar;
        self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
        self.searchDisplayController.searchResultsDataSource = self;
        self.searchDisplayController.searchResultsDelegate = self;
        self.searchDisplayController.delegate = self;
        
        // self.tableView.tableHeaderView = self.searchBar;
        
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

        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        self.searchBar = searchBar;
        self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
        self.searchDisplayController.searchResultsDataSource = self;
        self.searchDisplayController.searchResultsDelegate = self;
        self.searchDisplayController.delegate = self;

        // self.tableView.tableHeaderView = self.searchBar;

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

- (void)markBookmarkAsRead:(NSDictionary *)bookmark {
    NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/get?auth_token=%@&format=json&url=%@", [[AppDelegate sharedDelegate] token], self.bookmark[@"url"]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                               NSDictionary *bookmark = payload[@"posts"][0];
                               
                               NSString *urlString = [[NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/add?auth_token=%@&format=json&url=%@&description=%@&extended=%@&replace=yes&tags=%@&shared=%@toread=no", [[AppDelegate sharedDelegate] token], bookmark[@"href"], bookmark[@"description"], bookmark[@"extended"], bookmark[@"tags"], bookmark[@"shared"]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
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
                                                                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:NSLocalizedString(@"Bookmark Updated Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                                                  [alert show];
                                                                  return;
                                                              }
                                                          }
                                                          
                                                          UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Error", nil) message:NSLocalizedString(@"Bookmark Update Error Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                                          [alert show];
                                                      }];
                           }];
    
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.bookmark[@"url"]]];
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
    if (tableView.isEditing) {
    
    }
    else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        self.webView = [[UIWebView alloc] init];
        self.webView.scalesPageToFit = YES;
        self.webView.delegate = self;

        if (tableView == self.tableView) {
            self.bookmark = self.bookmarks[indexPath.row];
        }
        else {
            self.bookmark = self.filteredBookmarks[indexPath.row];
        }

        switch ([[[AppDelegate sharedDelegate] browser] integerValue]) {
            case BROWSER_WEBVIEW: {
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.bookmark[@"url"]]];
                [self.webView loadRequest:request];
                self.bookmarkDetailViewController = [[UIViewController alloc] init];
                self.bookmarkDetailViewController.title = self.bookmark[@"title"];
                self.webView.frame = self.bookmarkDetailViewController.view.frame;
                self.bookmarkDetailViewController.view = self.webView;
                self.bookmarkDetailViewController.hidesBottomBarWhenPushed = YES;
                self.bookmarkDetailViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openActionSheetForBookmark:)];
                [self.navigationController pushViewController:self.bookmarkDetailViewController animated:YES];
                break;
            }
                
            case BROWSER_SAFARI: {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.bookmark[@"url"]]];
                break;
            }
                
            case BROWSER_CHROME:
                if ([self.bookmark[@"url"] hasPrefix:@"http"]) {
                    NSURL *url = [NSURL URLWithString:[self.bookmark[@"url"] stringByReplacingCharactersInRange:[self.bookmark[@"url"] rangeOfString:@"http"] withString:@"googlechrome"]];
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
}


- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if ([[AppDelegate sharedDelegate] readlater] != nil) {
        if (action == @selector(readLater:)) {
            NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
            if ([bookmark[@"url"] rangeOfString:@"twitter.com"].location != NSNotFound || [bookmark[@"url"] rangeOfString:@"github.com"].location != NSNotFound) {
                return NO;
            }
            return YES;
        }
    }
    return (action == @selector(copyTitle:) || action == @selector(copyURL:));
}

- (void)editBookmark:(id)sender {

}

- (void)copyTitle:(id)sender {
    NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
    [[UIPasteboard generalPasteboard] setString:bookmark[@"title"]];
}

- (void)copyURL:(id)sender {
    NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
    [[UIPasteboard generalPasteboard] setString:bookmark[@"url"]];
}

- (void)readLater:(id)sender {
    NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
    NSNumber *readLater = [[AppDelegate sharedDelegate] readlater];
    NSURL *url = [NSURL URLWithString:bookmark[@"url"]];
    NSString *scheme = [NSString stringWithFormat:@"%@://", url.scheme];
    if (readLater.integerValue == READLATER_INSTAPAPER) {
        NSURL *newURL = [NSURL URLWithString:[bookmark[@"url"] stringByReplacingCharactersInRange:[bookmark[@"url"] rangeOfString:scheme] withString:@"x-callback-instapaper://x-callback-url/add?x-source=Pushpin&x-success=pushpin://&url="]];
        [[UIApplication sharedApplication] openURL:newURL];
    }
    else {
        NSURL *newURL = [NSURL URLWithString:[bookmark[@"url"] stringByReplacingCharactersInRange:[bookmark[@"url"] rangeOfString:scheme] withString:@"readability://add/"]];
        [[UIApplication sharedApplication] openURL:newURL];
    }
}

- (void)share:(id)sender {
    NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[bookmark[@"title"], bookmark[@"url"]] applicationActivities:nil];
    [self presentModalViewController:activityViewController animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    self.selectedIndexPath = indexPath;
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

    if ([bookmark[@"private"] boolValue] == YES) {
        cell.textView.backgroundColor = HEX(0xddddddff);
        cell.contentView.backgroundColor = HEX(0xddddddff);
    }
    else {
        cell.textView.backgroundColor = HEX(0xffffffff);
        cell.contentView.backgroundColor = HEX(0xffffffff);
    }

    cell.textView.delegate = self;
    cell.editing = YES;
    // cell.textView.userInteractionEnabled = YES;
    return cell;
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
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:@"Delete Bookmark" otherButtonTitles:@"Edit Bookmark", nil];
    [sheet showInView:self.bookmarkDetailViewController.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: {
            [self deleteBookmark:self.bookmark atIndexPath:nil];
            break;
        }
        case 1: {
            NSNumber *read = @(!([self.bookmark[@"unread"] boolValue]));
            [[AppDelegate sharedDelegate] showAddBookmarkViewControllerWithURL:self.bookmark[@"url"] andTitle:self.bookmark[@"title"] andTags:self.bookmark[@"tags"] andDescription:self.bookmark[@"description"] andPrivate:self.bookmark[@"private"] andRead:read];
            break;
        }
            
        default:
            break;
    }
}

- (void)deleteBookmark:(NSDictionary *)bookmark atIndexPath:(NSIndexPath *)indexPath {
    NSString *url = [NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/delete?format=json&auth_token=%@&url=%@", [[AppDelegate sharedDelegate] token], [bookmark[@"url"] urlEncodeUsingEncoding:NSUTF8StringEncoding]];
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

                                   if (indexPath != nil) {
                                       [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                   }
                                   [self processBookmarks];
                                   
                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:@"Your bookmark was deleted." delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                   [alert show];
                                   
                                   [self.navigationController popViewControllerAnimated:YES];
                               }
                           }];
}

#pragma mark - Swipe to delete

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"hey!!!");
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Delete";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *bookmark = self.bookmarks[indexPath.row];
        [self deleteBookmark:bookmark atIndexPath:indexPath];
    }
}

@end
