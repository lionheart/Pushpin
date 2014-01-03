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
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"
#import "PinboardFeedDataSource.h"
#import "SettingsViewController.h"
#import "TagViewController.h"
#import "PinboardNotesDataSource.h"
#import "PPSavedFeedsViewController.h"
#import "PPTheme.h"
#import "PPNavigationController.h"
#import "PPTitleButton.h"
#import "UITableViewCellValue1.h"
#import "PPTableViewTitleView.h"

#import <ASPinboard/ASPinboard.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIImage+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

static NSString *FeedListCellIdentifier = @"FeedListCellIdentifier";

@interface FeedListViewController ()

@end

@implementation FeedListViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)calculateBookmarkCounts:(void (^)(NSArray *))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *indexPathsToReload = [NSMutableArray array];
        
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        NSString *count, *previousCount;
        BOOL skip = self.bookmarkCounts.count < 5;
        
        [db open];
        NSArray *resultSets = @[
            [db executeQuery:@"SELECT COUNT(*) FROM bookmark"],
            [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private=?" withArgumentsInArray:@[@(YES)]],
            [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private=?" withArgumentsInArray:@[@(NO)]],
            [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE unread=?" withArgumentsInArray:@[@(YES)]],
            [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE hash NOT IN (SELECT DISTINCT bookmark_hash FROM tagging)"],
            [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE starred=?" withArgumentsInArray:@[@(YES)]]
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

    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Browse", nil) imageName:nil];
    self.title = @"";
    self.navigationItem.titleView = titleView;

    [self calculateBookmarkCounts:nil];
    self.bookmarkCounts = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", @"", @"", nil];

    self.navigationController.navigationBar.tintColor = HEX(0xFFFFFFFF);

    UIImage *settingsImage = [[UIImage imageNamed:@"navigation-settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton setImage:settingsImage forState:UIControlStateNormal];
    [settingsButton setImage:[settingsImage lhs_imageWithColor:HEX(0x84CBFFFF)] forState:UIControlStateHighlighted];
    [settingsButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    settingsButton.frame = CGRectMake(0, 0, 24, 24);
    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleDone target:self action:@selector(openSettings)];

    UIImage *tagImage = [[UIImage imageNamed:@"navigation-tags"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [tagButton setImage:tagImage forState:UIControlStateNormal];
    [tagButton setImage:[tagImage lhs_imageWithColor:HEX(0x84CBFFFF)] forState:UIControlStateHighlighted];
    [tagButton addTarget:self action:@selector(openTags) forControlEvents:UIControlEventTouchUpInside];
    tagButton.frame = CGRectMake(0, 0, 24, 24);
    UIBarButtonItem *tagBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Tags" style:UIBarButtonItemStyleDone target:self action:@selector(openTags)];

    self.navigationItem.rightBarButtonItem = tagBarButtonItem;
    self.navigationItem.leftBarButtonItem = settingsBarButtonItem;

    self.tableView.backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    self.tableView.backgroundColor = HEX(0xF7F9FDff);
    self.tableView.opaque = NO;

    // Register for Dynamic Type notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [self.tableView registerClass:[UITableViewCellValue1 class] forCellReuseIdentifier:FeedListCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barTintColor = HEX(0x0096ffff);

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [PPTableViewTitleView headerWithText:NSLocalizedString(@"Personal", nil)];
            
        case 1:
            return [PPTableViewTitleView headerWithText:NSLocalizedString(@"Community", nil)];
    }

    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FeedListCellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.font = [PPTheme cellTextLabelFont];
    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.font = [PPTheme cellTextLabelFont];

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

    PPTitleButton *titleButton = [PPTitleButton buttonWithDelegate:postViewController];
    switch (indexPath.section) {
        case 0: {
            PinboardDataSource *dataSource = [[PinboardDataSource alloc] init];
            dataSource.limit = 100;

            switch (indexPath.row) {
                case 0: {
                    postViewController.title = NSLocalizedString(@"All Bookmarks", nil);
                    [titleButton setTitle:NSLocalizedString(@"All Bookmarks", nil) imageName:@"navigation-all"];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0x0096ffff)];
                    [mixpanel track:@"Browsed all bookmarks"];
                    break;
                }
                case 1: {
                    dataSource.isPrivate = YES;
                    postViewController.title = NSLocalizedString(@"Private Bookmarks", nil);
                    [titleButton setTitle:NSLocalizedString(@"Private Bookmarks", nil) imageName:@"navigation-private"];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0xffae46ff)];
                    [mixpanel track:@"Browsed private bookmarks"];
                    break;
                }
                case 2: {
                    dataSource.isPrivate = NO;
                    postViewController.title = NSLocalizedString(@"Public", nil);
                    [titleButton setTitle:NSLocalizedString(@"Public", nil) imageName:@"navigation-public"];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0x7bb839ff)];
                    [mixpanel track:@"Browsed public bookmarks"];
                    break;
                }
                case 3: {
                    dataSource.unread = YES;
                    postViewController.title = NSLocalizedString(@"Unread", nil);
                    [titleButton setTitle:NSLocalizedString(@"Unread", nil) imageName:@"navigation-unread"];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0xef6034ff)];
                    [mixpanel track:@"Browsed unread bookmarks"];
                    break;
                }
                case 4: {
                    dataSource.untagged = YES;
                    postViewController.title = NSLocalizedString(@"Untagged", nil);
                    [titleButton setTitle:NSLocalizedString(@"Untagged", nil) imageName:@"navigation-untagged"];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0xacb3bbff)];
                    [mixpanel track:@"Browsed untagged bookmarks"];
                    break;
                }
                case 5: {
                    dataSource.starred = YES;
                    postViewController.title = NSLocalizedString(@"Starred", nil);
                    [titleButton setTitle:NSLocalizedString(@"Starred", nil) imageName:@"navigation-starred"];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0x8361f4ff)];
                    [mixpanel track:@"Browsed starred bookmarks"];
                    break;
                }
            }

            postViewController.postDataSource = dataSource;
            // Can we just use self.navigationController instead?
            postViewController.navigationItem.titleView = titleButton;
            [self.navigationController pushViewController:postViewController animated:YES];
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
                        [titleButton setTitle:NSLocalizedString(@"Network", nil) imageName:@"navigation-network"];
                        [self.navigationController.navigationBar setBarTintColor:HEX(0x30a1c1ff)];
                        [mixpanel track:@"Browsed network bookmarks"];
                        break;
                    }

                    case 1: {
                        feedDataSource.components = @[@"popular?count=100"];
                        [titleButton setTitle:NSLocalizedString(@"Popular", nil) imageName:@"navigation-popular"];
                        [self.navigationController.navigationBar setBarTintColor:HEX(0xff9409ff)];
                        [mixpanel track:@"Browsed popular bookmarks"];
                        break;
                    }

                    case 2: {
                        feedDataSource.components = @[@"popular", @"wikipedia"];
                        [titleButton setTitle:NSLocalizedString(@"Wikipedia", nil) imageName:@"navigation-wikipedia"];
                        [self.navigationController.navigationBar setBarTintColor:HEX(0x2ca881ff)];
                        [mixpanel track:@"Browsed wikipedia bookmarks"];
                        break;
                    }

                    case 3: {
                        feedDataSource.components = @[@"popular", @"fandom"];
                        [titleButton setTitle:NSLocalizedString(@"Fandom", nil) imageName:@"navigation-fandom"];
                        [self.navigationController.navigationBar setBarTintColor:HEX(0xe062d6ff)];
                        [mixpanel track:@"Browsed fandom bookmarks"];
                        break;
                    }

                    case 4: {
                        feedDataSource.components = @[@"popular", @"japanese"];
                        [titleButton setTitle:NSLocalizedString(@"日本語", nil) imageName:@"navigation-japanese"];
                        [self.navigationController.navigationBar setBarTintColor:HEX(0xff5353ff)];
                        [mixpanel track:@"Browsed 日本語 bookmarks"];
                        break;
                    }
                }
                
                if (indexPath.row == 5) {
                    PPSavedFeedsViewController *controller = [[PPSavedFeedsViewController alloc] init];
                    [titleButton setTitle:NSLocalizedString(@"Saved Feeds", nil) imageName:@"navigation-saved"];
                    [self.navigationController.navigationBar setBarTintColor:HEX(0xd5a470ff)];

                    controller.navigationItem.titleView = titleButton;
                    [self.navigationController pushViewController:controller animated:YES];
                }
                else {
                    postViewController.navigationItem.titleView = titleButton;
                    [self.navigationController pushViewController:postViewController animated:YES];
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
    [self.navigationController pushViewController:notesViewController animated:YES];
}

- (void)openTags {
    TagViewController *tagViewController = [[TagViewController alloc] init];
    [self.navigationController pushViewController:tagViewController animated:YES];
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
