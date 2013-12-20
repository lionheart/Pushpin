//
//  FeedListViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/4/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "FeedListViewController.h"
#import "AppDelegate.h"
#import "PPBrowseCell.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"
#import "PinboardFeedDataSource.h"
#import "SettingsViewController.h"
#import "TagViewController.h"
#import "PinboardNotesDataSource.h"
#import "PPSavedFeedsViewController.h"
#import "PPGroupedTableViewCell.h"
#import "PPTheme.h"
#import "PPNavigationController.h"

#import <ASPinboard/ASPinboard.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIImage+Tint.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

@interface FeedListViewController ()

@end

@implementation FeedListViewController

@synthesize connectionAvailable;
@synthesize updateTimer;
@synthesize bookmarkCounts;

- (void)calculateBookmarkCounts:(void (^)(NSArray *))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *indexPathsToReload = [NSMutableArray array];
        
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        NSString *count, *previousCount;
        BOOL skip = [self.bookmarkCounts count] < 5;
        
        [db open];
        NSArray *resultSets = @[
            [db executeQuery:@"SELECT COUNT(*) FROM bookmark"],
            [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private=?" withArgumentsInArray:@[@YES]],
            [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private=?" withArgumentsInArray:@[@NO]],
            [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE unread=?" withArgumentsInArray:@[@YES]],
            [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE hash NOT IN (SELECT DISTINCT bookmark_hash FROM tagging)"],
            [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE starred=?" withArgumentsInArray:@[@YES]]
        ];

        NSInteger i = 0;
        for (FMResultSet *resultSet in resultSets) {
            [resultSet next];
            count = [resultSet stringForColumnIndex:0];
            
            if (skip) {
                previousCount = @"";
            }
            else {
                previousCount = self.bookmarkCounts[i];
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
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Browse", nil);
    self.connectionAvailable = [[AppDelegate sharedDelegate].connectionAvailable boolValue];
    [self calculateBookmarkCounts:nil];
    self.bookmarkCounts = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", @"", @"", nil];

    self.navigationController.navigationBar.tintColor = HEX(0xFFFFFFFF);

    UIImage *settingsImage = [[UIImage imageNamed:@"navigation-settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton setImage:settingsImage forState:UIControlStateNormal];
    [settingsButton setImage:[settingsImage imageWithColor:HEX(0x84CBFFFF)] forState:UIControlStateHighlighted];
    [settingsButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    settingsButton.frame = CGRectMake(0, 0, 24, 24);
    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];

    UIImage *tagImage = [[UIImage imageNamed:@"navigation-tags"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [tagButton setImage:tagImage forState:UIControlStateNormal];
    [tagButton setImage:[tagImage imageWithColor:HEX(0x84CBFFFF)] forState:UIControlStateHighlighted];
    [tagButton addTarget:self action:@selector(openTags) forControlEvents:UIControlEventTouchUpInside];
    tagButton.frame = CGRectMake(0, 0, 24, 24);
    UIBarButtonItem *tagBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:tagButton];

    self.navigationItem.rightBarButtonItem = tagBarButtonItem;
    self.navigationItem.leftBarButtonItem = settingsBarButtonItem;

    self.tableView.backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    self.tableView.backgroundColor = HEX(0xF7F9FDff);
    self.tableView.opaque = NO;

    // Register for Dynamic Type notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barTintColor = HEX(0x0096ffff);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusDidChange:) name:@"ConnectionStatusDidChangeNotification" object:nil];

    AppDelegate *delegate = [AppDelegate sharedDelegate];
    if (![delegate feedToken]) {
        [delegate setNetworkActivityIndicatorVisible:YES];
        [[ASPinboard sharedInstance] rssKeyWithSuccess:^(NSString *feedToken) {
            [delegate setFeedToken:feedToken];
            [self.tableView reloadData];
        }];
    }

    [self calculateBookmarkCounts:^(NSArray *indexPathsToReload) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        });
    }];
}

- (void)connectionStatusDidChange:(NSNotification *)notification {
    BOOL newConnectionAvailable = [[AppDelegate sharedDelegate].connectionAvailable boolValue];
    if (self.connectionAvailable != newConnectionAvailable) {
        self.connectionAvailable = newConnectionAvailable;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.connectionAvailable) {
                [self showAllFeeds];
            }
            else {
                [self hideNetworkDependentFeeds];
            }
        });
    }
}

// Dispatched on main thread
- (void)showAllFeeds {
    self.notesBarButtonItem.enabled = YES;
    [self.tableView beginUpdates];
    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

// Dispatched on main thread
- (void)hideNetworkDependentFeeds {
    self.notesBarButtonItem.enabled = NO;
    [self.tableView beginUpdates];
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.connectionAvailable) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
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
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    static NSUInteger badgeTag = 1;
    UILabel *badgeLabel;

    if (!cell) {
        cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    // The badge is hidden by default
    badgeLabel = (UILabel *)[cell.contentView viewWithTag:badgeTag];
    [badgeLabel setHidden:YES];
    
    cell.textLabel.font = [PPTheme descriptionFont];
    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.font = [PPTheme descriptionFont];

    NSString *badgeCount;
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case PinboardFeedAllBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"All", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-all"];
                    badgeCount = self.bookmarkCounts[PinboardFeedAllBookmarks];
                    break;
                case PinboardFeedPrivateBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Private Bookmarks", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-private"];
                    badgeCount = self.bookmarkCounts[PinboardFeedPrivateBookmarks];
                    break;
                case PinboardFeedPublicBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Public", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-public"];
                    badgeCount = self.bookmarkCounts[PinboardFeedPublicBookmarks];
                    break;
                case PinboardFeedUnreadBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Unread", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-unread"];
                    badgeCount = self.bookmarkCounts[PinboardFeedUnreadBookmarks];
                    break;
                case PinboardFeedUntaggedBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-untagged"];
                    badgeCount = self.bookmarkCounts[PinboardFeedUntaggedBookmarks];
                    break;
                case PinboardFeedStarredBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Starred", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-starred"];
                    badgeCount = self.bookmarkCounts[PinboardFeedStarredBookmarks];
                    break;
            }
            
            cell.detailTextLabel.text = badgeCount;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case 1: {
            cell.imageView.image = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Network", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-network"];
                    break;
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Popular", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-popular"];
                    break;
                case 2:
                    cell.textLabel.text = @"Wikipedia";
                    cell.imageView.image = [UIImage imageNamed:@"browse-wikipedia"];
                    break;
                case 3:
                    cell.textLabel.text = NSLocalizedString(@"Fandom", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-fandom"];
                    break;
                case 4:
                    cell.textLabel.text = @"日本語";
                    cell.imageView.image = [UIImage imageNamed:@"browse-japanese"];
                    break;
                case 5:
                    cell.textLabel.text = NSLocalizedString(@"Saved Feeds", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-saved"];
                    break;
            }

            break;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // UINavigationItem doesn't like auto layout, so trick it with a button
    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    titleButton.frame = CGRectMake(0, 0, 200, 24);
    titleButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    titleButton.titleLabel.textColor = [UIColor whiteColor];
    titleButton.backgroundColor = [UIColor clearColor];
    titleButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    titleButton.adjustsImageWhenHighlighted = NO;
    postViewController.navigationItem.titleView = titleButton;
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    postViewController.postDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"limit": @(100), @"offset": @(0)}];
                    postViewController.title = NSLocalizedString(@"All Bookmarks", nil);
                    [titleButton setTitle:NSLocalizedString(@"All Bookmarks", nil) forState:UIControlStateNormal];
                    [titleButton setImage:[UIImage imageNamed:@"navigation-all"] forState:UIControlStateNormal];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0x0096ffff)];
                    [mixpanel track:@"Browsed all bookmarks"];
                    break;
                }
                case 1: {
                    postViewController.postDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"private": @(YES), @"limit": @(100), @"offset": @(0)}];
                    postViewController.title = NSLocalizedString(@"Private Bookmarks", nil);
                    [titleButton setTitle:NSLocalizedString(@"Private Bookmarks", nil) forState:UIControlStateNormal];
                    [titleButton setImage:[UIImage imageNamed:@"navigation-private"] forState:UIControlStateNormal];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0xffae46ff)];
                    [mixpanel track:@"Browsed private bookmarks"];
                    break;
                }
                case 2: {
                    postViewController.postDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"private": @(NO), @"limit": @(100), @"offset": @(0)}];
                    postViewController.title = NSLocalizedString(@"Public", nil);
                    [titleButton setTitle:NSLocalizedString(@"Public", nil) forState:UIControlStateNormal];
                    [titleButton setImage:[UIImage imageNamed:@"navigation-public"] forState:UIControlStateNormal];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0x7bb839ff)];
                    [mixpanel track:@"Browsed public bookmarks"];
                    break;
                }
                case 3: {
                    postViewController.postDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"unread": @(YES), @"limit": @(100), @"offset": @(0)}];
                    postViewController.title = NSLocalizedString(@"Unread", nil);
                    [titleButton setTitle:NSLocalizedString(@"Unread", nil) forState:UIControlStateNormal];
                    [titleButton setImage:[UIImage imageNamed:@"navigation-unread"] forState:UIControlStateNormal];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0xef6034ff)];
                    [mixpanel track:@"Browsed unread bookmarks"];
                    break;
                }
                case 4: {
                    postViewController.postDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"tagged": @(NO), @"limit": @(100), @"offset": @(0)}];
                    postViewController.title = NSLocalizedString(@"Untagged", nil);
                    [titleButton setTitle:NSLocalizedString(@"Untagged", nil) forState:UIControlStateNormal];
                    [titleButton setImage:[UIImage imageNamed:@"navigation-untagged"] forState:UIControlStateNormal];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0xacb3bbff)];
                    [mixpanel track:@"Browsed untagged bookmarks"];
                    break;
                }
                case 5: {
                    postViewController.postDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"starred": @(YES), @"limit": @(100), @"offset": @(0)}];
                    postViewController.title = NSLocalizedString(@"Starred", nil);
                    [titleButton setTitle:NSLocalizedString(@"Starred", nil) forState:UIControlStateNormal];
                    [titleButton setImage:[UIImage imageNamed:@"navigation-starred"] forState:UIControlStateNormal];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0x8361f4ff)];
                    [mixpanel track:@"Browsed starred bookmarks"];
                    break;
                }
            }

            // Can we just use self.navigationController instead?
            [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
            break;
        }
        case 1: {
            PinboardFeedDataSource *feedDataSource = [[PinboardFeedDataSource alloc] init];
            postViewController.postDataSource = feedDataSource;
            [tableView deselectRowAtIndexPath:indexPath animated:YES];

            if (![[[AppDelegate sharedDelegate] connectionAvailable] boolValue]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh.", nil) message:@"You can't browse popular feeds unless you have an active Internet connection." delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            }
            else {
                switch (indexPath.row) {
                    case 0: {
                        NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
                        NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
                        feedDataSource.components = @[[NSString stringWithFormat:@"secret:%@", feedToken], [NSString stringWithFormat:@"u:%@", username], @"network"];
                        postViewController.title = NSLocalizedString(@"Network", nil);
                        [titleButton setTitle:NSLocalizedString(@"Network", nil) forState:UIControlStateNormal];
                        [titleButton setImage:[UIImage imageNamed:@"navigation-network"] forState:UIControlStateNormal];
                        [self.navigationController.navigationBar setBarTintColor:HEX(0x30a1c1ff)];
                        [mixpanel track:@"Browsed network bookmarks"];
                        [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
                        break;
                    }
                    case 1: {
                        feedDataSource.components = @[@"popular?count=100"];
                        postViewController.title = NSLocalizedString(@"Popular", nil);
                        [titleButton setTitle:NSLocalizedString(@"Popular", nil) forState:UIControlStateNormal];
                        [titleButton setImage:[UIImage imageNamed:@"navigation-popular"] forState:UIControlStateNormal];
                        [self.navigationController.navigationBar setBarTintColor:HEX(0xff9409ff)];
                        [mixpanel track:@"Browsed popular bookmarks"];
                        [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
                        break;
                    }
                    case 2:
                        feedDataSource.components = @[@"popular", @"wikipedia"];
                        postViewController.title = @"Wikipedia";
                        [titleButton setTitle:@"Wikipedia" forState:UIControlStateNormal];
                        [titleButton setImage:[UIImage imageNamed:@"navigation-wikipedia"] forState:UIControlStateNormal];
                        [self.navigationController.navigationBar setBarTintColor:HEX(0x2ca881ff)];
                        [mixpanel track:@"Browsed wikipedia bookmarks"];
                        [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
                        break;
                    case 3:
                        feedDataSource.components = @[@"popular", @"fandom"];
                        postViewController.title = NSLocalizedString(@"Fandom", nil);
                        [titleButton setTitle:NSLocalizedString(@"Fandom", nil) forState:UIControlStateNormal];
                        [titleButton setImage:[UIImage imageNamed:@"navigation-fandom"] forState:UIControlStateNormal];
                        [self.navigationController.navigationBar setBarTintColor:HEX(0xe062d6ff)];
                        [mixpanel track:@"Browsed fandom bookmarks"];
                        [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
                        break;
                    case 4:
                        feedDataSource.components = @[@"popular", @"japanese"];
                        postViewController.title = @"日本語";
                        [titleButton setTitle:@"日本語" forState:UIControlStateNormal];
                        [titleButton setImage:[UIImage imageNamed:@"navigation-japanese"] forState:UIControlStateNormal];
                        [self.navigationController.navigationBar setBarTintColor:HEX(0xff5353ff)];
                        [mixpanel track:@"Browsed 日本語 bookmarks"];
                        [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
                        break;
                    case 5: {
                        PPSavedFeedsViewController *controller = [[PPSavedFeedsViewController alloc] init];
                        controller.title = @"Saved Feeds";
                        controller.navigationItem.titleView = titleButton;
                        [titleButton setTitle:@"Saved Feeds" forState:UIControlStateNormal];
                        [titleButton setImage:[UIImage imageNamed:@"navigation-saved"] forState:UIControlStateNormal];
                        [self.navigationController.navigationBar setBarTintColor:HEX(0xd5a470ff)];
                        [[AppDelegate sharedDelegate].navigationController pushViewController:controller animated:YES];
                        break;
                    }
                }

                break;
            }
        }
    }
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openSettings {
    SettingsViewController *svc = [[SettingsViewController alloc] init];
    svc.title = NSLocalizedString(@"Settings", nil);
    svc.modalDelegate = self;
    PPNavigationController *nc = [[PPNavigationController alloc] initWithRootViewController:svc];
    if ([UIApplication isIPad]) {
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    svc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(dismissViewController)];
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)openNotes {
    GenericPostViewController *notesViewController = [[GenericPostViewController alloc] init];
    PinboardNotesDataSource *notesDataSource = [[PinboardNotesDataSource alloc] init];
    notesViewController.postDataSource = notesDataSource;
    notesViewController.title = NSLocalizedString(@"Notes", nil);
    [[AppDelegate sharedDelegate].navigationController pushViewController:notesViewController animated:YES];
}

- (void)openTags {
    TagViewController *tagViewController = [[TagViewController alloc] init];
    tagViewController.title = NSLocalizedString(@"Tags", nil);
    [[AppDelegate sharedDelegate].navigationController pushViewController:tagViewController animated:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSArray *visibleIndexPaths = self.tableView.indexPathsForVisibleRows;
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortrait;
}

- (void)closeModal:(UIViewController *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)closeModal:(UIViewController *)sender success:(void (^)())success {
    [self dismissViewControllerAnimated:YES completion:success];
}

- (void)preferredContentSizeChanged:(NSNotification *)aNotification {
    [self.tableView reloadData];
}

@end
