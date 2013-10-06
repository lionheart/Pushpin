//
//  FeedListViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/4/13.
//
//

#import "FeedListViewController.h"
#import <ASPinboard/ASPinboard.h>
#import "AppDelegate.h"
#import "PPBrowseCell.h"
#import "PPCoreGraphics.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"
#import "PinboardFeedDataSource.h"
#import <QuartzCore/QuartzCore.h>
#import "SettingsViewController.h"
#import "TagViewController.h"
#import "PinboardNotesDataSource.h"
#import "PPSavedFeedsViewController.h"
#import "PPGroupedTableViewCell.h"
#import "UIApplication+AppDimensions.h"
#import "UIApplication+Additions.h"

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

    self.connectionAvailable = [[AppDelegate sharedDelegate].connectionAvailable boolValue];
    [self calculateBookmarkCounts:nil];
    self.bookmarkCounts = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", @"", @"", nil];

    self.navigationController.navigationBar.barTintColor = HEX(0x007AFFFF);
    self.navigationController.navigationBar.tintColor = HEX(0xFFFFFFFF);


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

    UIButton *notesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [notesButton setImage:[UIImage imageNamed:@"NotesNavigationDimmed"] forState:UIControlStateNormal];
    [notesButton setImage:[UIImage imageNamed:@"NotesNavigation"] forState:UIControlStateHighlighted];
    [notesButton addTarget:self action:@selector(openNotes) forControlEvents:UIControlEventTouchUpInside];
    notesButton.frame = CGRectMake(0, 0, 20, 24);
    self.notesBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:notesButton];
    self.notesBarButtonItem.enabled = self.connectionAvailable;

    self.navigationItem.rightBarButtonItems = @[tagBarButtonItem, self.notesBarButtonItem];
    self.navigationItem.leftBarButtonItem = settingsBarButtonItem;

    self.tableView.backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    self.tableView.backgroundColor = HEX(0xF7F9FDff);
    self.tableView.opaque = NO;

    // Register for Dynamic Type notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIFont *textLabelFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    CGSize textLabelFontSize = [@"Feed" sizeWithAttributes:@{NSFontAttributeName: textLabelFont}];
    CGFloat padding = 10;
    CGFloat totalHeight = padding + textLabelFontSize.height + padding;
    return totalHeight;
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

    // Dynamic Type
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];;
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    // The badge is hidden by default
    badgeLabel = (UILabel *)[cell.contentView viewWithTag:badgeTag];
    [badgeLabel setHidden:YES];
    
    cell.detailTextLabel.text = nil;

    NSString *badgeCount;
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case PinboardFeedAllBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"All", nil);
                    cell.imageView.image = [UIImage imageNamed:@"cabinet"];
                    badgeCount = self.bookmarkCounts[PinboardFeedAllBookmarks];
                    break;
                case PinboardFeedPrivateBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Private Bookmarks", nil);
                    cell.imageView.image = [UIImage imageNamed:@"lock"];
                    badgeCount = self.bookmarkCounts[PinboardFeedPrivateBookmarks];
                    break;
                case PinboardFeedPublicBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Public", nil);
                    cell.imageView.image = [UIImage imageNamed:@"globe-dash"];
                    badgeCount = self.bookmarkCounts[PinboardFeedPublicBookmarks];
                    break;
                case PinboardFeedUnreadBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Unread", nil);
                    cell.imageView.image = [UIImage imageNamed:@"glasses"];
                    badgeCount = self.bookmarkCounts[PinboardFeedUnreadBookmarks];
                    break;
                case PinboardFeedUntaggedBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                    cell.imageView.image = [UIImage imageNamed:@"tag"];
                    badgeCount = self.bookmarkCounts[PinboardFeedUntaggedBookmarks];
                    break;
                case PinboardFeedStarredBookmarks:
                    cell.textLabel.text = NSLocalizedString(@"Starred", nil);
                    cell.imageView.image = [UIImage imageNamed:@"star"];
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
                case 5:
                    cell.textLabel.text = NSLocalizedString(@"Saved Feeds", nil);
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

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    postViewController.postDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"limit": @(100), @"offset": @(0)}];
                    postViewController.title = NSLocalizedString(@"All Bookmarks", nil);
                    [mixpanel track:@"Browsed all bookmarks"];
                    break;
                }
                case 1: {
                    postViewController.postDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"private": @(YES), @"limit": @(100), @"offset": @(0)}];
                    postViewController.title = NSLocalizedString(@"Private Bookmarks", nil);
                    [mixpanel track:@"Browsed private bookmarks"];
                    break;
                }
                case 2: {
                    postViewController.postDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"private": @(NO), @"limit": @(100), @"offset": @(0)}];
                    postViewController.title = NSLocalizedString(@"Public", nil);
                    [mixpanel track:@"Browsed public bookmarks"];
                    break;
                }
                case 3: {
                    postViewController.postDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"unread": @(YES), @"limit": @(100), @"offset": @(0)}];
                    postViewController.title = NSLocalizedString(@"Unread", nil);
                    [mixpanel track:@"Browsed unread bookmarks"];
                    break;
                }
                case 4: {
                    postViewController.postDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"tagged": @(NO), @"limit": @(100), @"offset": @(0)}];
                    postViewController.title = NSLocalizedString(@"Untagged", nil);
                    [mixpanel track:@"Browsed untagged bookmarks"];
                    break;
                }
                case 5: {
                    postViewController.postDataSource = [[PinboardDataSource alloc] initWithParameters:@{@"starred": @(YES), @"limit": @(100), @"offset": @(0)}];
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
                        postViewTitle = NSLocalizedString(@"Network", nil);
                        [mixpanel track:@"Browsed network bookmarks"];
                        break;
                    }
                    case 1: {
                        feedDataSource.components = @[@"popular?count=100"];
                        postViewTitle = NSLocalizedString(@"Popular", nil);
                        [mixpanel track:@"Browsed popular bookmarks"];
                        break;
                    }
                    case 2:
                        feedDataSource.components = @[@"popular", @"wikipedia"];
                        postViewTitle = @"Wikipedia";
                        [mixpanel track:@"Browsed wikipedia bookmarks"];
                        break;
                    case 3:
                        feedDataSource.components = @[@"popular", @"fandom"];
                        postViewTitle = NSLocalizedString(@"Fandom", nil);
                        [mixpanel track:@"Browsed fandom bookmarks"];
                        break;
                    case 4:
                        feedDataSource.components = @[@"popular", @"japanese"];
                        postViewTitle = @"日本語";
                        [mixpanel track:@"Browsed 日本語 bookmarks"];
                        break;
                    case 5: {
                        PPSavedFeedsViewController *controller = [[PPSavedFeedsViewController alloc] init];
                        controller.title = @"Saved Feeds";
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
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:svc];
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

#pragma mark -
#pragma mark iOS 7 Updates

- (void)preferredContentSizeChanged:(NSNotification *)aNotification {
    [self.view setNeedsLayout];
    [self.tableView reloadData];
}

@end
