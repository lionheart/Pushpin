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
#import "PinboardFeedDataSource.h"
#import <QuartzCore/QuartzCore.h>
#import "SettingsViewController.h"
#import "TagViewController.h"

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
            [self calculateBookmarkCounts:^(NSArray *indexPathsToReload) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView beginUpdates];
                        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView endUpdates];
                    });
                });
            }];
            delegate.bookmarksUpdated = @NO;
        }
    }
}

- (void)calculateBookmarkCounts:(void (^)(NSArray *))callback {
    NSMutableArray *indexPathsToReload = [NSMutableArray array];

    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    NSString *count, *previousCount;
    BOOL skip = [self.bookmarkCounts count] < 5;

    [db open];
    
    NSArray *resultSets = @[
       [db executeQuery:@"SELECT COUNT(*) FROM bookmark"],
       [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private = ?" withArgumentsInArray:@[@YES]],
       [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private = ?" withArgumentsInArray:@[@NO]],
       [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE unread = ?" withArgumentsInArray:@[@(YES)]],
       [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE id NOT IN (SELECT DISTINCT bookmark_id FROM tagging)"],
       [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE starred = ?" withArgumentsInArray:@[@YES]]
    ];
    
    int i = 0;
    for (FMResultSet *resultSet in resultSets) {
        [resultSet next];
        count = [resultSet stringForColumnIndex:0];

        if (skip) {
            previousCount = @"";
        }
        else {
            previousCount = [self.bookmarkCounts objectAtIndex:i];
        }

        if (previousCount != nil && ![count isEqualToString:previousCount]) {
            self.bookmarkCounts[i] = count;
            [indexPathsToReload addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
              
        i++;
    }

    [db close];
    
    if (callback) {
        callback(indexPathsToReload);
    }
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
        [self calculateBookmarkCounts:nil];

        UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [settingsButton setImage:[UIImage imageNamed:@"SettingsNavigationDimmed"] forState:UIControlStateNormal];
        [settingsButton setImage:[UIImage imageNamed:@"SettingsNavigation"] forState:UIControlStateHighlighted];
        [settingsButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
        settingsButton.frame = CGRectMake(0, 0, 30, 24);
        UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];
        
        UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [tagButton setImage:[UIImage imageNamed:@"TagNavigationDimmed"] forState:UIControlStateNormal];
        [tagButton setImage:[UIImage imageNamed:@"TagNavigation"] forState:UIControlStateHighlighted];
        [tagButton addTarget:self action:@selector(openTags) forControlEvents:UIControlEventTouchUpInside];
        tagButton.frame = CGRectMake(0, 0, 30, 24);
        UIBarButtonItem *tagBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:tagButton];
        
        self.navigationItem.rightBarButtonItems = @[settingsBarButtonItem, tagBarButtonItem];
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"XXXXX" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.updateTimer = [NSTimer timerWithTimeInterval:0.10 target:self selector:@selector(checkForPostUpdates) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.updateTimer forMode:NSDefaultRunLoopMode];
    
    [self calculateBookmarkCounts:nil];
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
    selectedBackgroundView.layer.cornerRadius = 10;
    selectedBackgroundView.backgroundColor = HEX(0xDDE1E9ff);

    if (indexPath.row > 0) {
        CALayer *topBarLayer = [CALayer layer];
        topBarLayer.frame = CGRectMake(0, 0, 302, 10);
        topBarLayer.backgroundColor = HEX(0xDDE1E9ff).CGColor;
        [selectedBackgroundView.layer addSublayer:topBarLayer];
    }
    
    if (indexPath.row < 5) {
        CALayer *bottomBarLayer = [CALayer layer];
        bottomBarLayer.frame = CGRectMake(0, 34, 302, 10);
        bottomBarLayer.backgroundColor = HEX(0xDDE1E9ff).CGColor;
        [selectedBackgroundView.layer addSublayer:bottomBarLayer];
    }

    cell.selectedBackgroundView = selectedBackgroundView;
    cell.imageView.image = nil;
    cell.textLabel.highlightedTextColor = HEX(0x33353Bff);
    cell.textLabel.textColor = HEX(0x33353Bff);
    cell.textLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessory-caret"]];
    UIImage *pillImage;

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case PinboardFeedAllBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"All", nil);
                    cell.imageView.image = [UIImage imageNamed:@"cabinet"];
                    pillImage = [PPCoreGraphics pillImage:self.bookmarkCounts[PinboardFeedAllBookmarks]];
                    break;
                case PinboardFeedPrivateBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Private Bookmarks", nil);
                    cell.imageView.image = [UIImage imageNamed:@"lock"];
                    pillImage = [PPCoreGraphics pillImage:self.bookmarkCounts[PinboardFeedPrivateBookmarks]];
                    break;
                case PinboardFeedPublicBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Public", nil);
                    cell.imageView.image = [UIImage imageNamed:@"globe"];
                    pillImage = [PPCoreGraphics pillImage:self.bookmarkCounts[PinboardFeedPublicBookmarks]];
                    break;
                case PinboardFeedUnreadBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Unread", nil);
                    cell.imageView.image = [UIImage imageNamed:@"glasses"];
                    pillImage = [PPCoreGraphics pillImage:self.bookmarkCounts[PinboardFeedUnreadBookmarks]];
                    break;
                case PinboardFeedUntaggedBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                    cell.imageView.image = [UIImage imageNamed:@"tag"];
                    pillImage = [PPCoreGraphics pillImage:self.bookmarkCounts[PinboardFeedUntaggedBookmarks]];
                    break;
                case PinboardFeedStarredBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Starred", nil);
                    cell.imageView.image = [UIImage imageNamed:@"star"];
                    pillImage = [PPCoreGraphics pillImage:self.bookmarkCounts[PinboardFeedStarredBookmarks]];
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
    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case 0: {
            PinboardDataSource *pinboardDataSource = [[PinboardDataSource alloc] init];
            postViewController.postDataSource = pinboardDataSource;

            switch (indexPath.row) {
                case 0: {
                    pinboardDataSource.query = @"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
                    pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"limit": @(100), @"offset": @(0)}];

                    postViewController.title = NSLocalizedString(@"All Bookmarks", nil);
                    [mixpanel track:@"Browsed all bookmarks"];
                    break;
                }
                case 1: {
                    pinboardDataSource.query = @"SELECT * FROM bookmark WHERE private=:private ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
                    pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"private": @YES, @"limit": @100, @"offset": @0}];

                    postViewController.title = NSLocalizedString(@"Private Bookmarks", nil);
                    [mixpanel track:@"Browsed private bookmarks"];
                    break;
                }
                case 2: {
                    pinboardDataSource.query = @"SELECT * FROM bookmark WHERE private=:private ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
                    pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"private": @NO, @"limit": @100, @"offset": @0}];

                    postViewController.title = NSLocalizedString(@"Public", nil);
                    [mixpanel track:@"Browsed public bookmarks"];
                    break;
                }
                case 3: {
                    pinboardDataSource.query = @"SELECT * FROM bookmark WHERE unread=:unread ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
                    pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"unread": @YES, @"limit": @100, @"offset": @0}];

                    postViewController.title = NSLocalizedString(@"Unread", nil);
                    [mixpanel track:@"Browsed unread bookmarks"];
                    break;
                }
                case 4: {
                    pinboardDataSource.query = @"SELECT * FROM bookmark WHERE id NOT IN (SELECT DISTINCT bookmark_id FROM tagging) ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
                    pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"limit": @100, @"offset": @0}];

                    postViewController.title = NSLocalizedString(@"Untagged", nil);
                    [mixpanel track:@"Browsed untagged bookmarks"];
                    break;
                }
                case 5: {
                    pinboardDataSource.query = @"SELECT * FROM bookmark WHERE starred=:starred ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
                    pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"starred": @YES, @"limit": @100, @"offset": @0}];
                    postViewController.title = NSLocalizedString(@"Starred", nil);
                    [mixpanel track:@"Browsed starred bookmarks"];
                    break;
                }
            }
            [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];

            break;
        }
        case 1: {
            PinboardFeedDataSource *feedDataSource = [[PinboardFeedDataSource alloc] init];
            postViewController.postDataSource = feedDataSource;
            [tableView deselectRowAtIndexPath:indexPath animated:YES];

            if (![[[AppDelegate sharedDelegate] connectionAvailable] boolValue]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Error", nil) message:@"You can't browse popular feeds unless you have an active Internet connection." delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            }
            else {
                switch (indexPath.row) {
                    case 0: {
                        NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
                        NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
                        feedDataSource.endpoint = [NSString stringWithFormat:@"https://feeds.pinboard.in/json/secret:%@/u:%@/network/", feedToken, username];
                        postViewController.title = NSLocalizedString(@"Network", nil);
                        [mixpanel track:@"Browsed network bookmarks"];
                        break;
                    }
                    case 1: {
                        feedDataSource.endpoint = @"https://feeds.pinboard.in/json/popular?count=100";
                        postViewController.title = NSLocalizedString(@"Popular", nil);
                        [mixpanel track:@"Browsed popular bookmarks"];
                        break;
                    }
                    case 2:
                        feedDataSource.endpoint = @"https://feeds.pinboard.in/json/popular/wikipedia";
                        postViewController.title = @"Wikipedia";
                        [mixpanel track:@"Browsed wikipedia bookmarks"];
                        break;
                    case 3:
                        feedDataSource.endpoint = @"https://feeds.pinboard.in/json/popular/fandom";
                        postViewController.title = NSLocalizedString(@"Fandom", nil);
                        [mixpanel track:@"Browsed fandom bookmarks"];
                        break;
                    case 4:
                        feedDataSource.endpoint = @"https://feeds.pinboard.in/json/popular/japanese";
                        postViewController.title = @"日本語";
                        [mixpanel track:@"Browsed 日本語 bookmarks"];
                        break;
                }

                [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
                break;
            }
        }
    }
}

- (void)openSettings {
    SettingsViewController *svc = [[SettingsViewController alloc] init];
    svc.title = NSLocalizedString(@"Settings", nil);
    [[AppDelegate sharedDelegate].navigationController pushViewController:svc animated:YES];
}

- (void)openTags {
    TagViewController *tagViewController = [[TagViewController alloc] init];
    tagViewController.title = NSLocalizedString(@"Tags", nil);
    [[AppDelegate sharedDelegate].navigationController pushViewController:tagViewController animated:YES];
}

@end
