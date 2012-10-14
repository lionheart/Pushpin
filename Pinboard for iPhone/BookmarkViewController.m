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

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [self performSelectorInBackground:@selector(reloadTableData) withObject:nil];
}

- (void)reloadTableData {
    [[AppDelegate sharedDelegate] updateBookmarks];
    [self.tableView reloadData];
    [pull finishedLoading];
}

- (void)viewDidLoad {
	self.filteredBookmarks = [NSMutableArray arrayWithCapacity:[self.bookmarks count]];
	
    if (self.savedSearchTerm) {
        [self.searchDisplayController setActive:searchWasActive];
        [self.searchDisplayController.searchBar setText:self.savedSearchTerm];
        
        self.savedSearchTerm = nil;
    }

	[self processBookmarks];
	self.tableView.scrollEnabled = YES;
    
    pull = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *) self.tableView];
    [pull setDelegate:self];
    [self.tableView addSubview:pull];
}

- (void)viewDidUnload {
    self.filteredBookmarks = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];
}

- (void)processBookmark:(NSDictionary *)bookmark {
    [self.bookmarks addObject:bookmark];
    UIFont *largeHelvetica = [UIFont fontWithName:kFontName size:kLargeFontSize];
    UIFont *smallHelvetica = [UIFont fontWithName:kFontName size:kSmallFontSize];

    CGFloat height = 10.0f;
    height += ceilf([bookmark[@"title"] sizeWithFont:largeHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    height += ceilf([bookmark[@"description"] sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    [self.heights addObject:@(height)];
    
    NSString *content;
    if (![bookmark[@"description"] isEqualToString:@""]) {
        content = [NSString stringWithFormat:@"%@\n%@", bookmark[@"title"], bookmark[@"description"]];
    }
    else {
        content = [NSString stringWithFormat:@"%@", bookmark[@"title"]];
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
    [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
    [self.strings addObject:attributedString];
}

- (void)processBookmarks {
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:self.query withParameterDictionary:self.queryParameters];

    [self.strings removeAllObjects];
    [self.heights removeAllObjects];

    while ([results next]) {
        NSDictionary *bookmark = @{
            @"title": [results stringForColumn:@"title"],
            @"description": [results stringForColumn:@"description"],
            @"unread": [results objectForColumnName:@"unread"],
            @"url": [results stringForColumn:@"url"],
            @"private": [results stringForColumn:@"private"],
        };
        
        [self processBookmark:bookmark];
    }

    [db close];
    [self.tableView performSelectorInBackground:@selector(reloadData) withObject:nil];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.strings count];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.heights[indexPath.row] floatValue];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
    
    }
    else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        self.webView = [[UIWebView alloc] init];
        self.webView.delegate = self;
        NSDictionary *bookmark = self.bookmarks[indexPath.row];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:bookmark[@"url"]]];
        [self.webView loadRequest:request];
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.title = bookmark[@"title"];
        viewController.view = self.webView;
        [self.navigationController pushViewController:viewController animated:YES];
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

    NSAttributedString *string = self.strings[indexPath.row];
    NSDictionary *bookmark = self.bookmarks[indexPath.row];

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
    if (indexPath.row == self.limit.integerValue - 25) {
        self.limit = @(self.limit.integerValue + 50);
        self.queryParameters[@"limit"] = limit;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self processBookmarks];
            });
        });
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.bookmarks.count == 10) {
        NSInteger currentOffset = scrollView.contentOffset.y;
        NSInteger maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;

        if (maximumOffset - currentOffset <= -40) {
//            limit += 50;
//            [self refreshBookmarks];
        }
    }
}

@end
