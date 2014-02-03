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
#import "PPConstants.h"
#import "DeliciousDataSource.h"

#import <ASPinboard/ASPinboard.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIImage+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

static NSString *FeedListCellIdentifier = @"FeedListCellIdentifier";

@interface FeedListViewController ()

@end

@implementation FeedListViewController

#pragma mark UITableViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSArray *visibleIndexPaths = self.tableView.indexPathsForVisibleRows;
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Browse", nil) imageName:nil];

    self.title = @"Browse";
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.titleView = titleView;
    self.view.backgroundColor = [UIColor whiteColor];

    self.bookmarkCounts = [NSMutableArray array];

#ifdef DELICIOUS
    NSInteger rows = PPDeliciousPersonalRows;
#endif
    
#ifdef PINBOARD
    NSInteger rows = PPPinboardPersonalRows;
#endif
    
    for (NSInteger i=0; i<rows; i++) {
        [self.bookmarkCounts addObject:@""];
    }

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

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = HEX(0xF7F9FDff);
    self.tableView.opaque = YES;
    
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = @{@"table": self.tableView,
                            @"top": self.topLayoutGuide };
    
    [self.view lhs_addConstraints:@"H:|[table]|" views:views];
    [self.view lhs_addConstraints:@"V:[top][table]|" views:views];

    // Register for Dynamic Type notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [self.tableView registerClass:[UITableViewCellValue1 class] forCellReuseIdentifier:FeedListCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // On the iPad, the navigation bar changes color based on the view controller last pushed
    if (![UIApplication isIPad]) {
        self.navigationController.navigationBar.barTintColor = HEX(0x0096ffff);
    }

    AppDelegate *delegate = [AppDelegate sharedDelegate];
    if (![delegate feedToken]) {
        [delegate setNetworkActivityIndicatorVisible:YES];
        [[ASPinboard sharedInstance] rssKeyWithSuccess:^(NSString *feedToken) {
            [delegate setFeedToken:feedToken];
            [self.tableView reloadData];
        }];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *indexPathsToReload = [NSMutableArray array];
        
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        
#ifdef DELICIOUS
        NSArray *resultSets = @[
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark"],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private=?" withArgumentsInArray:@[@(YES)]],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private=?" withArgumentsInArray:@[@(NO)]],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE unread=?" withArgumentsInArray:@[@(YES)]],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE hash NOT IN (SELECT DISTINCT bookmark_hash FROM tagging)"]
                                ];
#endif
        
#ifdef PINBOARD
        NSArray *resultSets = @[
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark"],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private=?" withArgumentsInArray:@[@(YES)]],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private=?" withArgumentsInArray:@[@(NO)]],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE unread=?" withArgumentsInArray:@[@(YES)]],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE hash NOT IN (SELECT DISTINCT bookmark_hash FROM tagging)"],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE starred=?" withArgumentsInArray:@[@(YES)]]
                                ];
#endif
        
        NSInteger i = 0;
        for (FMResultSet *resultSet in resultSets) {
            [resultSet next];
            NSString *count = [resultSet stringForColumnIndex:0];
            NSString *previousCount = self.bookmarkCounts[i];

            if (![count isEqualToString:previousCount]) {
                self.bookmarkCounts[i] = count;
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }

            i++;
        }
        
        [db close];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        });
    });
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.bookmarkCounts[indexPath.row] isEqualToString:@"0"]) {
        return 0;
    }
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#ifdef DELICIOUS
    return PPProviderDeliciousSections;
#endif
    
#ifdef PINBOARD
    return PPProviderPinboardSections;
#endif
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#ifdef DELICIOUS
    return PPDeliciousPersonalRows;
#endif
    
#ifdef PINBOARD
    switch ((PPPinboardSectionType)section) {
        case PPPinboardSectionPersonal:
            return PPPinboardPersonalRows;

        case PPPinboardSectionCommunity:
            return PPPinboardCommunityRows + 1;
            
        case PPPinboardSectionSavedFeeds:
            return 0;
    }
#endif
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"Personal", nil);
            
        case 1:
            return NSLocalizedString(@"Community", nil);
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FeedListCellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.font = [PPTheme boldTextLabelFont];
    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.font = [PPTheme detailLabelFont];
    cell.clipsToBounds = YES;

    NSString *badgeCount;
    
#ifdef DELICIOUS
    switch ((PPDeliciousSectionType)indexPath.section) {
        case PPDeliciousSectionPersonal: {
            PPDeliciousPersonalFeedType feedType = (PPDeliciousPersonalFeedType)indexPath.row;
            badgeCount = self.bookmarkCounts[feedType];
            switch (feedType) {
                case PPDeliciousPersonalFeedAll:
                    cell.textLabel.text = NSLocalizedString(@"All", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-all"];
                    break;
                    
                case PPDeliciousPersonalFeedPrivate:
                    cell.textLabel.text = NSLocalizedString(@"Private Bookmarks", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-private"];
                    break;
                    
                case PPDeliciousPersonalFeedPublic:
                    cell.textLabel.text = NSLocalizedString(@"Public", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-public"];
                    break;
                    
                case PPDeliciousPersonalFeedUnread:
                    cell.textLabel.text = NSLocalizedString(@"Unread", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-unread"];
                    break;
                    
                case PPDeliciousPersonalFeedUntagged:
                    cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-untagged"];
                    break;
            }
            
            cell.detailTextLabel.text = badgeCount;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
    }
#endif
    
#ifdef PINBOARD
    switch ((PPPinboardSectionType)indexPath.section) {
        case PPPinboardSectionPersonal: {
            PPPinboardPersonalFeedType feedType = (PPPinboardPersonalFeedType)indexPath.row;
            badgeCount = self.bookmarkCounts[feedType];
            switch (feedType) {
                case PPPinboardPersonalFeedAll:
                    cell.textLabel.text = NSLocalizedString(@"All", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-all"];
                    break;

                case PPPinboardPersonalFeedPrivate:
                    cell.textLabel.text = NSLocalizedString(@"Private Bookmarks", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-private"];
                    break;

                case PPPinboardPersonalFeedPublic:
                    cell.textLabel.text = NSLocalizedString(@"Public", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-public"];
                    break;

                case PPPinboardPersonalFeedUnread:
                    cell.textLabel.text = NSLocalizedString(@"Unread", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-unread"];
                    break;

                case PPPinboardPersonalFeedUntagged:
                    cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-untagged"];
                    break;

                case PPPinboardPersonalFeedStarred:
                    cell.textLabel.text = NSLocalizedString(@"Starred", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-starred"];
                    break;
            }
            
            cell.detailTextLabel.text = badgeCount;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }

        case PPPinboardSectionCommunity: {
            cell.imageView.image = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            PPPinboardCommunityFeedType feedType = (PPPinboardCommunityFeedType)indexPath.row;

            switch (feedType) {
                case PPPinboardCommunityFeedNetwork:
                    cell.textLabel.text = NSLocalizedString(@"Network", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-network"];
                    break;

                case PPPinboardCommunityFeedPopular:
                    cell.textLabel.text = NSLocalizedString(@"Popular", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-popular"];
                    break;

                case PPPinboardCommunityFeedWikipedia:
                    cell.textLabel.text = @"Wikipedia";
                    cell.imageView.image = [UIImage imageNamed:@"browse-wikipedia"];
                    break;

                case PPPinboardCommunityFeedFandom:
                    cell.textLabel.text = NSLocalizedString(@"Fandom", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-fandom"];
                    break;

                case PPPinboardCommunityFeedJapan:
                    cell.textLabel.text = @"日本語";
                    cell.imageView.image = [UIImage imageNamed:@"browse-japanese"];
                    break;

                default:
                    cell.textLabel.text = NSLocalizedString(@"Saved Feeds", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-saved"];
                    break;
            }

            break;
        }
    }
#endif

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MixpanelProxy *mixpanel = [MixpanelProxy sharedInstance];
    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIViewController *viewControllerToPush;

#ifdef DELICIOUS
    switch ((PPDeliciousSectionType)indexPath.section) {
        case PPDeliciousSectionPersonal: {
            DeliciousDataSource *dataSource = [[DeliciousDataSource alloc] init];
            dataSource.limit = 100;

            PPDeliciousPersonalFeedType feedType = (PPDeliciousPersonalFeedType)indexPath.row;

            switch (feedType) {
                case PPDeliciousPersonalFeedAll:
                    [mixpanel track:@"Browsed all bookmarks"];
                    break;
                    
                case PPPinboardPersonalFeedPrivate:
                    dataSource.isPrivate = YES;
                    [mixpanel track:@"Browsed private bookmarks"];
                    break;
                    
                case PPPinboardPersonalFeedPublic:
                    dataSource.isPrivate = NO;
                    [mixpanel track:@"Browsed public bookmarks"];
                    break;
                    
                case PPDeliciousPersonalFeedUnread:
                    dataSource.unread = YES;
                    [mixpanel track:@"Browsed unread bookmarks"];
                    break;
                    
                case PPDeliciousPersonalFeedUntagged:
                    dataSource.untagged = YES;
                    [mixpanel track:@"Browsed untagged bookmarks"];
                    break;
            }
            
            postViewController.postDataSource = dataSource;
            // Can we just use self.navigationController instead?
            viewControllerToPush = postViewController;
            break;
        }
    }
#else
    switch ((PPPinboardSectionType)indexPath.section) {
        case PPPinboardSectionPersonal: {
            PinboardDataSource *dataSource = [[PinboardDataSource alloc] init];
            dataSource.limit = 100;
            
            PPPinboardPersonalFeedType feedType = (PPPinboardPersonalFeedType)indexPath.row;

            switch (feedType) {
                case PPPinboardPersonalFeedAll:
                    [mixpanel track:@"Browsed all bookmarks"];
                    break;

                case PPPinboardPersonalFeedPrivate:
                    dataSource.isPrivate = YES;
                    [mixpanel track:@"Browsed private bookmarks"];
                    break;

                case PPPinboardPersonalFeedPublic:
                    dataSource.isPrivate = NO;
                    [mixpanel track:@"Browsed public bookmarks"];
                    break;

                case PPPinboardPersonalFeedUnread:
                    dataSource.unread = YES;
                    [mixpanel track:@"Browsed unread bookmarks"];
                    break;

                case PPPinboardPersonalFeedUntagged:
                    dataSource.untagged = YES;
                    [mixpanel track:@"Browsed untagged bookmarks"];
                    break;

                case PPPinboardPersonalFeedStarred:
                    dataSource.starred = YES;
                    [mixpanel track:@"Browsed starred bookmarks"];
                    break;
            }

            postViewController.postDataSource = dataSource;
            // Can we just use self.navigationController instead?
            viewControllerToPush = postViewController;
            break;
        }
        case PPPinboardSectionCommunity: {
            PinboardFeedDataSource *feedDataSource = [[PinboardFeedDataSource alloc] init];
            postViewController.postDataSource = feedDataSource;
            [tableView deselectRowAtIndexPath:indexPath animated:YES];

            if (![AppDelegate sharedDelegate].connectionAvailable) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh.", nil) message:@"You can't browse popular feeds unless you have an active Internet connection." delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            }
            else {
                PPPinboardCommunityFeedType feedType = (PPPinboardCommunityFeedType)indexPath.row;

                switch (feedType) {
                    case PPPinboardCommunityFeedNetwork: {
                        NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
                        NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
                        feedDataSource.components = @[[NSString stringWithFormat:@"secret:%@", feedToken], [NSString stringWithFormat:@"u:%@", username], @"network"];
                        [mixpanel track:@"Browsed network bookmarks"];
                        break;
                    }

                    case PPPinboardCommunityFeedPopular: {
                        feedDataSource.components = @[@"popular?count=100"];
                        [mixpanel track:@"Browsed popular bookmarks"];
                        break;
                    }

                    case PPPinboardCommunityFeedWikipedia: {
                        feedDataSource.components = @[@"popular", @"wikipedia"];
                        [mixpanel track:@"Browsed wikipedia bookmarks"];
                        break;
                    }

                    case PPPinboardCommunityFeedFandom: {
                        feedDataSource.components = @[@"popular", @"fandom"];
                        [mixpanel track:@"Browsed fandom bookmarks"];
                        break;
                    }

                    case PPPinboardCommunityFeedJapan: {
                        feedDataSource.components = @[@"popular", @"japanese"];
                        [mixpanel track:@"Browsed 日本語 bookmarks"];
                        break;
                    }
                }
                
                if (indexPath.row == 5) {
                    PPSavedFeedsViewController *controller = [[PPSavedFeedsViewController alloc] init];
                    PPTitleButton *titleButton = [PPTitleButton button];
                    [titleButton setTitle:NSLocalizedString(@"Saved Feeds", nil) imageName:@"navigation-saved"];

                    controller.navigationItem.titleView = titleButton;
                    viewControllerToPush = controller;
                }
                else {
                    viewControllerToPush = postViewController;
                }

                break;
            }
        }
    }
#endif
    
    // We need to switch this based on whether the user is on an iPad, due to the split view controller.
    if ([UIApplication isIPad]) {
        UINavigationController *navigationController = [AppDelegate sharedDelegate].navigationController;
        if (navigationController.viewControllers.count == 1) {
            UIBarButtonItem *showPopoverBarButtonItem = navigationController.topViewController.navigationItem.leftBarButtonItem;
            if (showPopoverBarButtonItem) {
                viewControllerToPush.navigationItem.leftBarButtonItem = showPopoverBarButtonItem;
            }
        }

        [navigationController setViewControllers:@[viewControllerToPush] animated:YES];
        
        if ([viewControllerToPush respondsToSelector:@selector(postDataSource)]) {
            if ([[(GenericPostViewController *)viewControllerToPush postDataSource] respondsToSelector:@selector(barTintColor)]) {
                [self.navigationController.navigationBar setBarTintColor:[[(GenericPostViewController *)viewControllerToPush postDataSource] barTintColor]];
            }
        }
        
        UIPopoverController *popover = [AppDelegate sharedDelegate].feedListViewController.popover;
        if (popover) {
            [popover dismissPopoverAnimated:YES];
        }
    }
    else {
        [self.navigationController pushViewController:viewControllerToPush animated:YES];
    }
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openSettings {
    SettingsViewController *svc = [[SettingsViewController alloc] init];
    [self.navigationController pushViewController:svc animated:YES];
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
