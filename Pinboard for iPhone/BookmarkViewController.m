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

static NSString *const kFontName = @"Helvetica";
static float kLargeFontSize = 16.0f;
static float kSmallFontSize = 13.0f;

@interface BookmarkViewController ()

@end

@implementation BookmarkViewController

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
    }
    return self;
}

- (void)toggleEditMode {
    if (self.tableView.editing) {
        [self.tableView setEditing:NO animated:YES];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(toggleEditMode)];
    }
    else {
        [self.tableView setEditing:YES animated:YES];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done"
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
                                                                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Your bookmark was updated." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                                                  [alert show];
                                                                  return;
                                                              }
                                                          }
                                                          
                                                          UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Uh oh." message:@"There was an error updating your bookmark." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
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
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Shucks" message:@"It looks like Google Chrome is unable to open this link. Click OK to open it with Safari instead." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
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

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        NSDictionary *bookmark = self.bookmarks[indexPath.row];
        [[UIPasteboard generalPasteboard] setString:bookmark[@"url"]];
    }
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

    cell.textView.delegate = self;
    cell.textView.userInteractionEnabled = YES;
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
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Mark as read", @"Open in Safari", nil];
    [sheet showInView:self.bookmarkDetailViewController.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self markBookmarkAsRead:self.bookmark];
            break;
            
        case 1:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.bookmark[@"url"]]];
            break;
            
        default:
            break;
    }
}

@end
