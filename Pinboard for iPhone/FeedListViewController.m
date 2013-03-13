//
//  FeedListViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/4/13.
//
//

#import "FeedListViewController.h"
#import <ASPinboard/ASPinboard.h>
#import "BookmarkViewController.h"
#import "BookmarkFeedViewController.h"
#import "AppDelegate.h"
#import "PPBrowseCell.h"
#import "PPCoreGraphics.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"
#import <QuartzCore/QuartzCore.h>

@interface FeedListViewController ()

@end

@implementation FeedListViewController

@synthesize connectionAvailable;
@synthesize navigationController;
@synthesize updateTimer;
@synthesize bookmarkCounts;
@synthesize timerPaused;

- (void)checkForPostUpdates {
    if (!self.timerPaused) {
        AppDelegate *delegate = [AppDelegate sharedDelegate];
        if (delegate.bookmarksUpdated.boolValue) {
            [self calculateBookmarkCounts];
            [self.tableView reloadData];
            delegate.bookmarksUpdated = @NO;
        }
    }
}

- (void)calculateBookmarkCounts {
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    FMResultSet *results;

    [db open];

    results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark"];
    [results next];
    self.bookmarkCounts[PinboardFeedAllBookmarks] = [results stringForColumnIndex:0];
    
    results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private = ?" withArgumentsInArray:@[@YES]];
    [results next];
    self.bookmarkCounts[PinboardFeedPrivateBookmarks] = [results stringForColumnIndex:0];
    
    results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private = ?" withArgumentsInArray:@[@NO]];
    [results next];
    self.bookmarkCounts[PinboardFeedPublicBookmarks] = [results stringForColumnIndex:0];
    
    results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE unread = ?" withArgumentsInArray:@[@(YES)]];
    [results next];
    self.bookmarkCounts[PinboardFeedUnreadBookmarks] = [results stringForColumnIndex:0];

    results = [db executeQuery:@"SELECT * FROM bookmark WHERE id NOT IN (SELECT DISTINCT bookmark_id FROM tagging)"];
    [results next];
    self.bookmarkCounts[PinboardFeedUntaggedBookmarks] = [results stringForColumnIndex:0];

    [db close];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.connectionAvailable = [[[AppDelegate sharedDelegate] connectionAvailable] boolValue];
        self.timerPaused = NO;
        self.tableView.opaque = NO;
        self.tableView.backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        self.tableView.backgroundColor = HEX(0xF7F9FDff);
        self.bookmarkCounts = [NSMutableArray arrayWithCapacity:5];
        [self calculateBookmarkCounts];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusDidChange:) name:@"ConnectionStatusDidChangeNotification" object:nil];

    AppDelegate *delegate = [AppDelegate sharedDelegate];
    if (![delegate feedToken]) {
        [delegate setNetworkActivityIndicatorVisible:YES];
        [[ASPinboard sharedInstance] rssKeyWithSuccess:^(NSString *feedToken) {
            [delegate setFeedToken:feedToken];
            [self.tableView reloadData];
        }];
    }
    
    self.updateTimer = [NSTimer timerWithTimeInterval:0.10 target:self selector:@selector(checkForPostUpdates) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.updateTimer forMode:NSDefaultRunLoopMode];
    
    [self calculateBookmarkCounts];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.timerPaused = YES;
}

- (void)connectionStatusDidChange:(NSNotification *)notification {
    BOOL oldConnectionAvailable = self.connectionAvailable;
    self.connectionAvailable = [[[AppDelegate sharedDelegate] connectionAvailable] boolValue];
    if (oldConnectionAvailable != self.connectionAvailable) {
        [self.tableView beginUpdates];
        if (self.connectionAvailable) {
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:5 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:5 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.tableView endUpdates];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.connectionAvailable) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if (self.connectionAvailable) {
                return 6;
            }
            else {
                return 4;
            }
            break;
        case 1:
            return 5;
            break;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    float width = tableView.bounds.size.width;

    int fontSize = 17;
    int padding = 15;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(padding, 8, width - padding, fontSize)];
    NSString *sectionTitle;
    switch (section) {
        case 0:
            sectionTitle = NSLocalizedString(@"Personal", nil);
            break;
        case 1:
            sectionTitle = NSLocalizedString(@"Community", nil);
            break;
    }

    label.text = sectionTitle;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = HEX(0x808690ff);
    label.shadowColor = [UIColor whiteColor];
    label.shadowOffset = CGSizeMake(0,1);
    label.font = [UIFont fontWithName:@"Avenir-Black" size:fontSize];
    CGSize textSize = [sectionTitle sizeWithFont:label.font];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, textSize.height)];
    [view addSubview:label];
    return view;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"Personal", nil);
            break;
        case 1:
            return NSLocalizedString(@"Community", nil);
            break;
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSArray *subviews = [cell.contentView subviews];
    for (id subview in subviews) {
        [subview removeFromSuperview];
    }

    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    selectedBackgroundView.backgroundColor = HEX(0xDDE1E9ff);
    cell.selectedBackgroundView = selectedBackgroundView;
    cell.textLabel.highlightedTextColor = HEX(0x33353Bff);
    cell.textLabel.textColor = HEX(0x33353Bff);

    cell.textLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessory-caret"]];
    UIImage *pillImage;

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"All", nil);
                    cell.imageView.image = [UIImage imageNamed:@"cabinet"];
                    pillImage = [PPCoreGraphics pillImage:self.bookmarkCounts[PinboardFeedAllBookmarks]];
                    break;
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Private Bookmarks", nil);
                    cell.imageView.image = [UIImage imageNamed:@"lock"];
                    pillImage = [PPCoreGraphics pillImage:self.bookmarkCounts[PinboardFeedPrivateBookmarks]];
                    break;
                case 2:
                    cell.textLabel.text = NSLocalizedString(@"Public", nil);
                    cell.imageView.image = [UIImage imageNamed:@"globe"];
                    pillImage = [PPCoreGraphics pillImage:self.bookmarkCounts[PinboardFeedPublicBookmarks]];
                    break;
                case 3:
                    cell.textLabel.text = NSLocalizedString(@"Unread", nil);
                    cell.imageView.image = [UIImage imageNamed:@"glasses"];
                    pillImage = [PPCoreGraphics pillImage:self.bookmarkCounts[PinboardFeedUnreadBookmarks]];
                    break;
                case 4:
                    cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                    cell.imageView.image = [UIImage imageNamed:@"tag"];
                    pillImage = [PPCoreGraphics pillImage:self.bookmarkCounts[PinboardFeedUntaggedBookmarks]];
                    break;
                case 5:
                    cell.textLabel.text = NSLocalizedString(@"Starred", nil);
                    cell.imageView.image = [UIImage imageNamed:@"star"];
                    break;
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Network", nil);
                    break;
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Popular", nil);
                    break;
                case 2:
                    cell.textLabel.text = @"Wikipedia";
                    break;
                case 3:
                    cell.textLabel.text = NSLocalizedString(@"Fandom", nil);
                    break;
                case 4:
                    cell.textLabel.text = @"日本語";
                    break;
            }
            cell.detailTextLabel.text = @"";

            break;
        }
    }
    
    UIImageView *pillView = [[UIImageView alloc] initWithImage:pillImage];
    pillView.frame = CGRectMake(320 - pillImage.size.width - 45, (cell.contentView.frame.size.height - pillImage.size.height) / 2, pillImage.size.width, pillImage.size.height);
    
    [cell.contentView addSubview:pillView];
    cell.backgroundColor = [UIColor whiteColor];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    switch (indexPath.section) {
        case 0: {
            id bookmarkViewController;
            PinboardDataSource *pinboardDataSource = [[PinboardDataSource alloc] init];

            switch (indexPath.row) {
                case 0: {
                    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
                    
                    pinboardDataSource.query = @"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
                    pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"limit": @(100), @"offset": @(0)}];

                    postViewController.postDataSource = pinboardDataSource;
                    postViewController.title = NSLocalizedString(@"All Bookmarks", nil);

                    [self.navigationController pushViewController:postViewController animated:YES];
                    [mixpanel track:@"Browsed all bookmarks"];
                    break;
                }
                case 1: {
                    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
                    
                    pinboardDataSource.query = @"SELECT * FROM bookmark WHERE private=:private ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
                    pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"private": @YES, @"limit": @100, @"offset": @0}];

                    postViewController.postDataSource = pinboardDataSource;
                    postViewController.title = NSLocalizedString(@"Private Bookmarks", nil);

                    [self.navigationController pushViewController:postViewController animated:YES];
                    [mixpanel track:@"Browsed private bookmarks"];
                    break;
                }
                case 2: {
                    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
                    
                    pinboardDataSource.query = @"SELECT * FROM bookmark WHERE private=:private ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
                    pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"private": @NO, @"limit": @100, @"offset": @0}];

                    postViewController.postDataSource = pinboardDataSource;
                    postViewController.title = NSLocalizedString(@"Public", nil);

                    [self.navigationController pushViewController:postViewController animated:YES];
                    [mixpanel track:@"Browsed public bookmarks"];
                    break;
                }
                case 3: {
                    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
                    
                    pinboardDataSource.query = @"SELECT * FROM bookmark WHERE unread=:unread ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
                    pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"unread": @YES, @"limit": @100, @"offset": @0}];

                    postViewController.postDataSource = pinboardDataSource;
                    postViewController.title = NSLocalizedString(@"Unread", nil);

                    [self.navigationController pushViewController:postViewController animated:YES];
                    [mixpanel track:@"Browsed unread bookmarks"];
                    break;
                }
                case 4: {
                    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];

                    pinboardDataSource.query = @"SELECT * FROM bookmark WHERE id NOT IN (SELECT DISTINCT bookmark_id FROM tagging) ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
                    pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"limit": @100, @"offset": @0}];
                    
                    postViewController.postDataSource = pinboardDataSource;
                    postViewController.title = NSLocalizedString(@"Untagged", nil);

                    [self.navigationController pushViewController:postViewController animated:YES];
                    [mixpanel track:@"Browsed untagged bookmarks"];
                    break;
                }
                case 5: {
                    NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
                    NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
                    NSString *url = [NSString stringWithFormat:@"https://feeds.pinboard.in/json/secret:%@/u:%@/starred/", feedToken, username];
                    bookmarkViewController = [[BookmarkFeedViewController alloc] initWithURL:url];
                    [(BookmarkFeedViewController *)bookmarkViewController setTitle:NSLocalizedString(@"Starred", nil)];
                    [self.navigationController pushViewController:bookmarkViewController animated:YES];
                    [mixpanel track:@"Browsed starred bookmarks"];
                    break;
                }
            }

            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
        case 1: {
            BookmarkFeedViewController *bookmarkViewController;
            [tableView deselectRowAtIndexPath:indexPath animated:YES];

            if (![[[AppDelegate sharedDelegate] connectionAvailable] boolValue]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Error", nil) message:@"You can't browse popular feeds unless you have an active Internet connection." delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            }
            else {
                switch (indexPath.row) {
                    case 0: {
                        NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
                        NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
                        NSString *url = [NSString stringWithFormat:@"https://feeds.pinboard.in/json/secret:%@/u:%@/network/", feedToken, username];
                        bookmarkViewController = [[BookmarkFeedViewController alloc] initWithURL:url];
                        bookmarkViewController.title = NSLocalizedString(@"Network", nil);
                        [mixpanel track:@"Browsed network bookmarks"];
                        break;
                    }
                    case 1:
                        bookmarkViewController = [[BookmarkFeedViewController alloc] initWithURL:@"https://feeds.pinboard.in/json/popular"];
                        bookmarkViewController.title = NSLocalizedString(@"Popular", nil);
                        [mixpanel track:@"Browsed popular bookmarks"];
                        break;
                    case 2:
                        bookmarkViewController = [[BookmarkFeedViewController alloc] initWithURL:@"https://feeds.pinboard.in/json/popular/wikipedia"];
                        bookmarkViewController.title = @"Wikipedia";
                        [mixpanel track:@"Browsed wikipedia bookmarks"];
                        break;
                    case 3:
                        bookmarkViewController = [[BookmarkFeedViewController alloc] initWithURL:@"https://feeds.pinboard.in/json/popular/fandom"];
                        bookmarkViewController.title = NSLocalizedString(@"Fandom", nil);
                        [mixpanel track:@"Browsed fandom bookmarks"];
                        break;
                    case 4:
                        bookmarkViewController = [[BookmarkFeedViewController alloc] initWithURL:@"https://feeds.pinboard.in/json/popular/japanese"];
                        bookmarkViewController.title = @"日本語";
                        [mixpanel track:@"Browsed 日本語 bookmarks"];
                        break;
                }
                [self.navigationController pushViewController:bookmarkViewController animated:YES];
                break;
            }
        }
    }
}

@end
