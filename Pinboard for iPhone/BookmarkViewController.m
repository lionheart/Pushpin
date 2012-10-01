//
//  PostViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "BookmarkViewController.h"
#import "BookmarkCell.h"
#import "NSAttributedString+Attributes.h"
#import "TTTAttributedLabel.h"
#import "ASManagedObject.h"
#import "Bookmark.h"

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
@synthesize predicate = _predicate;
@synthesize date_formatter;
@synthesize savedSearchTerm;
@synthesize filteredBookmarks;
@synthesize searchWasActive;
@synthesize searchDisplayController;
@synthesize searchBar = _searchBar;

- (void)viewDidLoad {
    // create a filtered list that will contain products for the search results table.
	self.filteredBookmarks = [NSMutableArray arrayWithCapacity:[self.bookmarks count]];
	
	// restore search settings if they were saved in didReceiveMemoryWarning.
    if (self.savedSearchTerm)
	{
        [self.searchDisplayController setActive:searchWasActive];
        [self.searchDisplayController.searchBar setText:self.savedSearchTerm];
        
        self.savedSearchTerm = nil;
    }

	[self.tableView reloadData];
	self.tableView.scrollEnabled = YES;
}

- (void)viewDidUnload {
    self.filteredBookmarks = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];
}

- (Bookmark *)updateBookmark:(Bookmark *)bookmark withAttributes:(NSDictionary *)attributes {
    bookmark.url = [attributes objectForKey:@"href"];
    bookmark.title = [attributes objectForKey:@"description"];
    bookmark.extended = [attributes objectForKey:@"extended"];
    bookmark.pinboard_hash = [attributes objectForKey:@"hash"];
    bookmark.read = [NSNumber numberWithBool:([[attributes objectForKey:@"toread"] isEqualToString:@"no"])];
    bookmark.shared = [NSNumber numberWithBool:([[attributes objectForKey:@"shared"] isEqualToString:@"yes"])];
    bookmark.created_on = [self.date_formatter dateFromString:[attributes objectForKey:@"time"]];
    return bookmark;
}

- (void)pinboard:(Pinboard *)pinboard didReceiveResponse:(NSMutableArray *)response {
    NSManagedObjectContext *context = [ASManagedObject sharedContext];
    NSMutableArray *hashes = [NSMutableArray array];
    
    for (NSDictionary *element in response) {
        [hashes addObject:[element objectForKey:@"hash"]];
    }
    
    [hashes sortUsingComparator:(NSComparator)^(id obj1, id obj2) {
        return [obj1 caseInsensitiveCompare:obj2];
    }];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Bookmark"];
    NSPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:self.predicate, [NSPredicate predicateWithFormat:@"pinboard_hash in %@", hashes], nil]];
    [request setPredicate:compoundPredicate];
    [request setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"pinboard_hash" ascending:YES]]];

    NSError *error = nil;
    NSArray *fetchRequestResponse = [context executeFetchRequest:request error:&error];

    int i = 0;
    int j = 0;
    bool update_existing;
    Bookmark *bookmark;
    [self.bookmarks removeAllObjects];
    while (i < [hashes count]) {
        update_existing = false;
        NSString *hash = [hashes objectAtIndex:i];
        if (j < [fetchRequestResponse count]) {
            bookmark = [fetchRequestResponse objectAtIndex:j];
            update_existing = [bookmark.pinboard_hash isEqualToString:hash];
        }
        
        if (update_existing) {
            j++;
        }
        else {
            bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
        }

        NSDictionary *attributes = [response objectAtIndex:i];

        [self updateBookmark:bookmark withAttributes:attributes];
        [self.bookmarks addObject:bookmark];
        i++;
    }

    [context save:nil];
    [self processBookmarks];
}

- (void)processBookmarks {
    UIFont *largeHelvetica = [UIFont fontWithName:kFontName size:kLargeFontSize];
    UIFont *smallHelvetica = [UIFont fontWithName:kFontName size:kSmallFontSize];
    
    [self.strings removeAllObjects];
    [self.heights removeAllObjects];

    for (int i=0; i<[self.bookmarks count]; i++) {
        Bookmark *bookmark = [self.bookmarks objectAtIndex:i];

        CGFloat height = 10.0f;
        height += ceilf([bookmark.title sizeWithFont:largeHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
        height += ceilf([bookmark.extended sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
        [self.heights addObject:[NSNumber numberWithFloat:height]];

        NSString *content;
        if (![bookmark.extended isEqualToString:@""]) {
            content = [NSString stringWithFormat:@"%@\n%@", bookmark.title, bookmark.extended];
        }
        else {
            content = [NSString stringWithFormat:@"%@", bookmark.title];
        }

        NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];

        [attributedString setFont:largeHelvetica range:[content rangeOfString:bookmark.title]];
        [attributedString setFont:smallHelvetica range:[content rangeOfString:bookmark.extended]];
        [attributedString setTextColor:HEX(0x555555ff)];

        if (bookmark.read.boolValue) {
            [attributedString setTextColor:HEX(0x2255aaff) range:[content rangeOfString:bookmark.title]];
        }
        else {
            [attributedString setTextColor:HEX(0xcc2222ff) range:[content rangeOfString:bookmark.title]];
        }
        [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
        [self.strings addObject:attributedString];
    }

    [self.tableView reloadData];
}

- (id)initWithEndpoint:(NSString *)endpoint predicate:(NSPredicate *)predicate parameters:(NSDictionary *)parameters {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.endpoint = endpoint;
        self.bookmarks = [NSMutableArray array];
        self.parameters = [NSMutableArray array];
        self.strings = [NSMutableArray array];
        self.heights = [NSMutableArray array];
        self.predicate = predicate;
        self.date_formatter = [[NSDateFormatter alloc] init];
        [self.date_formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [self.date_formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        self.searchBar = searchBar;
        self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
        self.searchDisplayController.searchResultsDataSource = self;
        self.searchDisplayController.searchResultsDelegate = self;
        self.searchDisplayController.delegate = self;

        self.tableView.tableHeaderView = self.searchBar;

        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(refreshBookmarks)];
    }
    return self;
}

- (void)refreshBookmarks {
    [[AppDelegate sharedDelegate] updateBookmarks];
    
    NSManagedObjectContext *context = [ASManagedObject sharedContext];
    NSError *error = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Bookmark"];
    NSMutableArray *mutableFetchResults = [[context executeFetchRequest:request error:&error] mutableCopy];

    NSLog(@"%d", mutableFetchResults.count);
    return;
    [self.bookmarks removeAllObjects];
    [request setPredicate:self.predicate];
    self.bookmarks = [NSMutableArray arrayWithArray:[context executeFetchRequest:request error:&error]];

    if ([self.bookmarks count] == 0) {
        Pinboard *pinboard = [Pinboard pinboardWithEndpoint:self.endpoint delegate:self];
        [pinboard parse];
    }
    else {
        [self processBookmarks];
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

#pragma mark - Web View Delegate


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.strings count];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[self.heights objectAtIndex:indexPath.row] floatValue];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self;
    Bookmark *bookmark = [self.bookmarks objectAtIndex:indexPath.row];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:bookmark.url]];
    [self.webView loadRequest:request];
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.title = bookmark.title;
    viewController.view = self.webView;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"BookmarkCell";
    BookmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[BookmarkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    NSAttributedString *string = [self.strings objectAtIndex:indexPath.row];
    [cell.textView setText:string];
    cell.textView.delegate = self;
    cell.textView.userInteractionEnabled = YES;
    [cell layoutSubviews];
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    return cell;
}

@end
