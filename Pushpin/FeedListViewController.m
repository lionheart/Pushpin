//
//  FeedListViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/4/13.
//
//

@import QuartzCore;

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
#import "PPAddSavedFeedViewController.h"

#import <ASPinboard/ASPinboard.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIImage+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

static NSString *FeedListCellIdentifier = @"FeedListCellIdentifier";

@interface FeedListViewController ()

@property (nonatomic, strong) NSMutableArray *feeds;
@property (nonatomic, strong) UIToolbar *bottomBar;
@property (nonatomic, strong) NSLayoutConstraint *bottomBarBottomConstraint;

- (void)openNotes;
- (void)openSettings;
- (void)openTags;
- (void)toggleEditing:(UIBarButtonItem *)sender;
- (void)leftBarButtonItemTouchUpInside:(UIBarButtonItem *)sender;

- (NSArray *)indexPathsForHiddenFeeds;
- (NSArray *)indexPathsForVisibleFeeds;

#ifdef PINBOARD
- (BOOL)personalSectionIsHidden;
- (BOOL)communitySectionIsHidden;
- (NSInteger)numberOfHiddenSections;
- (PPPinboardSectionType)sectionTypeForSection:(NSInteger)section;
- (PPPinboardPersonalFeedType)personalFeedForIndexPath:(NSIndexPath *)indexPath;
- (PPPinboardCommunityFeedType)communityFeedForIndexPath:(NSIndexPath *)indexPath;
#endif

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
    
    self.feeds = [NSMutableArray array];
    self.navigationController.navigationBar.tintColor = HEX(0xFFFFFFFF);

    UIImage *settingsImage = [[UIImage imageNamed:@"navigation-settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton setImage:settingsImage forState:UIControlStateNormal];
    [settingsButton setImage:[settingsImage lhs_imageWithColor:HEX(0x84CBFFFF)] forState:UIControlStateHighlighted];
    [settingsButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    settingsButton.frame = CGRectMake(0, 0, 24, 24);
    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleDone target:self action:@selector(leftBarButtonItemTouchUpInside:)];
    settingsBarButtonItem.possibleTitles = [NSSet setWithObjects:@"Settings", @"Cancel", nil];

    UIImage *tagImage = [[UIImage imageNamed:@"navigation-tags"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [tagButton setImage:tagImage forState:UIControlStateNormal];
    [tagButton setImage:[tagImage lhs_imageWithColor:HEX(0x84CBFFFF)] forState:UIControlStateHighlighted];
    [tagButton addTarget:self action:@selector(openTags) forControlEvents:UIControlEventTouchUpInside];
    tagButton.frame = CGRectMake(0, 0, 24, 24);
    UIBarButtonItem *tagBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleDone target:self action:@selector(toggleEditing:)];
    tagBarButtonItem.possibleTitles = [NSSet setWithObjects:@"Edit", @"Done", nil];

    self.navigationItem.rightBarButtonItem = tagBarButtonItem;
    self.navigationItem.leftBarButtonItem = settingsBarButtonItem;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.backgroundColor = HEX(0xF7F9FDff);
    self.tableView.opaque = YES;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    [self.view addSubview:self.tableView];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    NSDictionary *barButtonTitleTextAttributes = @{NSForegroundColorAttributeName:[UIColor darkGrayColor],
                                                   NSFontAttributeName: [UIFont fontWithName:[PPTheme boldFontName] size:16] };
    UIBarButtonItem *noteBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Notes" style:UIBarButtonItemStyleDone target:self action:@selector(openNotes)];
    [noteBarButtonItem setTitleTextAttributes:barButtonTitleTextAttributes forState:UIControlStateNormal];

    UIBarButtonItem *tagsBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Tags" style:UIBarButtonItemStyleDone target:self action:@selector(openTags)];
    [tagsBarButtonItem setTitleTextAttributes:barButtonTitleTextAttributes forState:UIControlStateNormal];

    self.bottomBar = [[UIToolbar alloc] init];
    self.bottomBar.barTintColor = [UIColor whiteColor];
    self.bottomBar.tintColor = [UIColor darkGrayColor];
    self.bottomBar.items = @[noteBarButtonItem, flexibleSpace, tagsBarButtonItem];
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bottomBar];
    
    NSDictionary *views = @{@"table": self.tableView,
                            @"top": self.topLayoutGuide,
                            @"bar": self.bottomBar };
    
    self.bottomBarBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomBar
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1
                                                                   constant:0];
    
    [self.view addConstraint:self.bottomBarBottomConstraint];
    [self.view lhs_addConstraints:@"V:[bar(44)]" views:views];
    [self.bottomBar lhs_fillWidthOfSuperview];
    [self.tableView lhs_fillWidthOfSuperview];
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

#ifdef PINBOARD
    AppDelegate *delegate = [AppDelegate sharedDelegate];

    if (![delegate feedToken]) {
        [delegate setNetworkActivityIndicatorVisible:YES];
        [[ASPinboard sharedInstance] rssKeyWithSuccess:^(NSString *feedToken) {
            [delegate setFeedToken:feedToken];
            [self.tableView reloadData];
        }];
    }
#endif
    
#ifdef PINBOARD
    // Check if we have any updates from iCloud
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    [store synchronize];
    NSMutableArray *iCloudFeeds = [NSMutableArray arrayWithArray:[store arrayForKey:kSavedFeedsKey]];
#endif

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
        [db beginTransaction];
        for (NSString *components in iCloudFeeds) {
            [db executeUpdate:@"INSERT OR IGNORE INTO feeds (components) VALUES (?)" withArgumentsInArray:@[components]];
        }
        [db commit];

        FMResultSet *result = [db executeQuery:@"SELECT components FROM feeds ORDER BY components ASC"];
        [self.feeds removeAllObjects];

        NSInteger index = 0;
        while ([result next]) {
            NSString *componentString = [result stringForColumnIndex:0];
            NSArray *components = [componentString componentsSeparatedByString:@" "];

            [iCloudFeeds addObject:componentString];
            [self.feeds addObject:@{@"components": components, @"title": [components componentsJoinedByString:@"+"]}];
            index++;
        }
        
        // Remove duplicates from the array
        NSArray *iCloudFeedsWithoutDuplicates = [[NSSet setWithArray:iCloudFeeds] allObjects];
        
        // Sync the new saved feed list with iCloud
        [store setArray:iCloudFeedsWithoutDuplicates forKey:kSavedFeedsKey];

        NSArray *resultSets = @[
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark"],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private=?" withArgumentsInArray:@[@(YES)]],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private=?" withArgumentsInArray:@[@(NO)]],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE unread=?" withArgumentsInArray:@[@(YES)]],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE hash NOT IN (SELECT DISTINCT bookmark_hash FROM tagging)"],
                                [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE starred=?" withArgumentsInArray:@[@(YES)]]
                            ];
#endif
        
        NSString *sectionName = PPSections()[0];

        NSInteger i = 0;
        NSInteger j = 0;
        for (FMResultSet *resultSet in resultSets) {
            NSString *feedName = PPPersonalFeeds()[i];
            NSString *fullName = [@[sectionName, feedName] componentsJoinedByString:@"-"];
            BOOL feedHiddenByUser = [delegate.hiddenFeedNames containsObject:fullName];
            
            [resultSet next];
            
            NSString *count = [resultSet stringForColumnIndex:0];
            NSString *previousCount = self.bookmarkCounts[i];
            self.bookmarkCounts[i] = count;

            if (!feedHiddenByUser) {
                if (![count isEqualToString:previousCount]) {
                    [indexPathsToReload addObject:[NSIndexPath indexPathForRow:j inSection:0]];
                }
                j++;
            }

            i++;
        }
        
        [db close];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            
            if (![self personalSectionIsHidden]) {
                [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
            }

#ifdef PINBOARD
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionSavedFeeds - [self numberOfHiddenSections]]
                          withRowAnimation:UITableViewRowAnimationFade];
#endif
            [self.tableView endUpdates];
        });
    });
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
#ifdef DELICIOUS
    if ((PPDeliciousSectionType)indexPath.section == PPDeliciousSectionPersonal && [self.bookmarkCounts[indexPath.row] isEqualToString:@"0"]) {
        return 0;
    }
#endif

    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#ifdef DELICIOUS
    return PPProviderDeliciousSections;
#endif
    
#ifdef PINBOARD
    if (self.tableView.editing) {
        return PPProviderPinboardSections - 1;
    }
    else {
        return PPProviderPinboardSections - [self numberOfHiddenSections];
    }
#endif
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#ifdef DELICIOUS
    return PPDeliciousPersonalRows;
#endif
    
#ifdef PINBOARD
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    PPPinboardSectionType sectionType = [self sectionTypeForSection:section];
    
    if (tableView.editing) {
        switch (sectionType) {
            case PPPinboardSectionPersonal:
                return PPPinboardPersonalRows;
                
            case PPPinboardSectionCommunity:
                return PPPinboardCommunityRows;
                
            case PPPinboardSectionSavedFeeds:
                return self.feeds.count + 1;
        }
    }
    else {
        switch (sectionType) {
            case PPPinboardSectionPersonal: {
                NSArray *filteredRows = [delegate.hiddenFeedNames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", @"personal"]];
                return PPPinboardPersonalRows - filteredRows.count;
            }
                
            case PPPinboardSectionCommunity: {
                NSArray *filteredRows = [delegate.hiddenFeedNames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", @"community"]];
                return PPPinboardCommunityRows - filteredRows.count;
            }
                
            case PPPinboardSectionSavedFeeds:
                return self.feeds.count + 1;
        }
    }
#endif
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    PPPinboardSectionType sectionType = [self sectionTypeForSection:section];
    switch (sectionType) {
        case PPPinboardSectionPersonal:
            return NSLocalizedString(@"Personal", nil);
            
        case PPPinboardSectionCommunity:
            return NSLocalizedString(@"Community", nil);
            
        case PPPinboardSectionSavedFeeds:
            return NSLocalizedString(@"Feeds", nil);
    }
    
    return nil;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self sectionTypeForSection:indexPath.section] == PPPinboardSectionSavedFeeds) {
        return UITableViewCellEditingStyleDelete;
    }

    return UITableViewCellEditingStyleNone;
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
    PPPinboardSectionType sectionType = [self sectionTypeForSection:indexPath.section];
    switch (sectionType) {
        case PPPinboardSectionPersonal: {
            PPPinboardPersonalFeedType feedType = [self personalFeedForIndexPath:indexPath];

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
            
            cell.detailTextLabel.text = self.bookmarkCounts[feedType];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }

        case PPPinboardSectionCommunity: {
            cell.imageView.image = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            PPPinboardCommunityFeedType feedType = [self communityFeedForIndexPath:indexPath];

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
            }

            break;
        }
            
        case PPPinboardSectionSavedFeeds: {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.font = [PPTheme textLabelFont];

            if (indexPath.row == self.feeds.count) {
                cell.textLabel.text = @"Add Feed";
                cell.imageView.image = nil;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else {
                cell.textLabel.text = self.feeds[indexPath.row][@"title"];
                cell.imageView.image = [UIImage imageNamed:@"browse-saved"];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }
#endif

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MixpanelProxy *mixpanel = [MixpanelProxy sharedInstance];
    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
    
    UIViewController *viewControllerToPush;

    if (!tableView.editing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

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
#endif

#ifdef PINBOARD
        AppDelegate *delegate = [AppDelegate sharedDelegate];
        PPPinboardSectionType sectionType = [self sectionTypeForSection:indexPath.section];
        switch (sectionType) {
            case PPPinboardSectionPersonal: {
                NSInteger numFeedsSkipped = 0;
                NSInteger numFeedsNotSkipped = 0;
                
                if (!tableView.editing) {
                    for (NSInteger i=0; i<[PPPersonalFeeds() count]; i++) {
                        if ([delegate.hiddenFeedNames containsObject:[@[@"personal", PPPersonalFeeds()[i]] componentsJoinedByString:@"-"]]) {
                            numFeedsSkipped++;
                        }
                        else {
                            if (numFeedsNotSkipped == indexPath.row) {
                                break;
                            }
                            numFeedsNotSkipped++;
                        }
                    }
                }
                
                PPPinboardPersonalFeedType feedType = (PPPinboardPersonalFeedType)(indexPath.row + numFeedsSkipped);

                PinboardDataSource *dataSource = [[PinboardDataSource alloc] init];
                dataSource.limit = 100;

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
                    PPPinboardCommunityFeedType feedType = [self communityFeedForIndexPath:indexPath];

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
                    
                    viewControllerToPush = postViewController;
                    break;
                }
            }
                
            case PPPinboardSectionSavedFeeds: {
                if (indexPath.row == self.feeds.count) {
                    PPAddSavedFeedViewController *addSavedFeedViewController = [[PPAddSavedFeedViewController alloc] init];
                    PPNavigationController *navigationController = [[PPNavigationController alloc] initWithRootViewController:addSavedFeedViewController];
                    [self presentViewController:navigationController animated:YES completion:nil];
                }
                else {
                    viewControllerToPush = [PinboardFeedDataSource postViewControllerWithComponents:self.feeds[indexPath.row][@"components"]];
                }
                break;
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
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)leftBarButtonItemTouchUpInside:(UIBarButtonItem *)sender {
    if (self.tableView.editing) {
        [self toggleEditing:sender];
    }
    else {
        SettingsViewController *svc = [[SettingsViewController alloc] init];
        [self.navigationController pushViewController:svc animated:YES];
    }
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

- (void)toggleEditing:(UIBarButtonItem *)sender {
    if (self.tableView.editing) {
        self.navigationItem.leftBarButtonItem.title = @"Settings";
        self.navigationItem.rightBarButtonItem.title = @"Edit";

        NSArray *indexPathsForSelectedRows = [self.tableView indexPathsForSelectedRows];
        
        [self.tableView setEditing:NO animated:YES];

        if (sender == self.navigationItem.leftBarButtonItem) {
            // Don't commit updates. User pressed Cancel.
        }
        else {
            // Commit updates. User pressed Done.
            NSMutableArray *visibleFeedNames = [NSMutableArray array];
            NSMutableArray *hiddenFeedNames = [NSMutableArray array];
            
            for (NSIndexPath *indexPath in indexPathsForSelectedRows) {
                PPPinboardSectionType sectionType = (PPPinboardSectionType)indexPath.section;
                NSString *feedName;
                
                switch (sectionType) {
                    case PPPinboardSectionPersonal: {
                        feedName = [@[@"personal", PPPersonalFeeds()[indexPath.row]] componentsJoinedByString:@"-"];
                        break;
                    }
                        
                    case PPPinboardSectionCommunity: {
                        feedName = [@[@"community", PPCommunityFeeds()[indexPath.row]] componentsJoinedByString:@"-"];
                        break;
                    }
                        
                    default:
                        continue;
                }
                
                [visibleFeedNames addObject:feedName];
            }
            
            for (NSInteger section=0; section<[PPSections() count]; section++) {
                PPPinboardSectionType sectionType = (PPPinboardSectionType)section;
                NSInteger numberOfRows;
                switch (sectionType) {
                    case PPPinboardSectionPersonal:
                        numberOfRows = [PPPersonalFeeds() count];
                        break;
                        
                    case PPPinboardSectionCommunity:
                        numberOfRows = [PPCommunityFeeds() count];
                        break;
                        
                    case PPPinboardSectionSavedFeeds:
                        numberOfRows = 0;
                        break;
                }

                for (NSInteger row=0; row<numberOfRows; row++) {
                    PPPinboardSectionType sectionType = (PPPinboardSectionType)section;
                    
                    NSString *feedName;
                    switch (sectionType) {
                        case PPPinboardSectionPersonal: {
                            feedName = [@[PPSections()[section], PPPersonalFeeds()[row]] componentsJoinedByString:@"-"];
                            break;
                        }
                            
                        case PPPinboardSectionCommunity: {
                            feedName = [@[PPSections()[section], PPCommunityFeeds()[row]] componentsJoinedByString:@"-"];
                            break;
                        }
                            
                        default:
                            break;
                    }
                    
                    if (feedName && ![visibleFeedNames containsObject:feedName]) {
                        [hiddenFeedNames addObject:feedName];
                    }
                }
            }
            
            AppDelegate *delegate = [AppDelegate sharedDelegate];
            delegate.hiddenFeedNames = [hiddenFeedNames copy];
        }
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.bottomBarBottomConstraint.constant = 0;
                             [self.view layoutIfNeeded];
                         }];
        
        [CATransaction begin];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:[self indexPathsForHiddenFeeds] withRowAnimation:UITableViewRowAnimationFade];
        
        if ([self personalSectionIsHidden]) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionPersonal] withRowAnimation:UITableViewRowAnimationFade];
        }

        if ([self communitySectionIsHidden]) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionCommunity] withRowAnimation:UITableViewRowAnimationFade];
        }

        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionSavedFeeds - [self numberOfHiddenSections]]
                      withRowAnimation:UITableViewRowAnimationFade];
        [CATransaction setCompletionBlock:^{
            NSMutableArray *allIndexPaths = [NSMutableArray array];
            for (NSInteger section=0; section<[self numberOfSectionsInTableView:self.tableView]; section++) {
                for (NSInteger row=0; row<[self.tableView numberOfRowsInSection:section]; row++) {
                    [allIndexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
                }
            }

            if (allIndexPaths.count < PPPersonalFeeds().count + PPCommunityFeeds().count) {
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:allIndexPaths withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
            }
        }];
        [self.tableView endUpdates];
        [CATransaction commit];
    }
    else {
        self.navigationItem.leftBarButtonItem.title = @"Cancel";
        self.navigationItem.rightBarButtonItem.title = @"Done";
        [self.tableView setEditing:YES animated:YES];
        
        [self.tableView beginUpdates];
        
        if ([self personalSectionIsHidden]) {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionPersonal] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        if ([self communitySectionIsHidden]) {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionCommunity] withRowAnimation:UITableViewRowAnimationFade];
        }

        [self.tableView insertRowsAtIndexPaths:[self indexPathsForHiddenFeeds] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionSavedFeeds - [self numberOfHiddenSections]]
                      withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];

        [UIView animateWithDuration:0.3
                         animations:^{
                             self.bottomBarBottomConstraint.constant = 44;
                             [self.view layoutIfNeeded];
                         }];

        for (NSIndexPath *indexPath in [self indexPathsForVisibleFeeds]) {
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

- (NSArray *)indexPathsForHiddenFeeds {
    NSMutableArray *indexPaths = [NSMutableArray array];
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    
    if (![self personalSectionIsHidden]) {
        for (NSInteger i=0; i<[PPPersonalFeeds() count]; i++) {
            if ([delegate.hiddenFeedNames containsObject:[@[@"personal", PPPersonalFeeds()[i]] componentsJoinedByString:@"-"]]) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:PPPinboardSectionPersonal]];
            }
        }
    }

    if (![self communitySectionIsHidden]) {
        for (NSInteger i=0; i<[PPCommunityFeeds() count]; i++) {
            if ([delegate.hiddenFeedNames containsObject:[@[@"community", PPCommunityFeeds()[i]] componentsJoinedByString:@"-"]]) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:PPPinboardSectionCommunity]];
            }
        }
    }

    return [indexPaths copy];
}

- (NSArray *)indexPathsForVisibleFeeds {
    NSMutableArray *indexPaths = [NSMutableArray array];
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    for (NSInteger i=0; i<[PPPersonalFeeds() count]; i++) {
        if (![delegate.hiddenFeedNames containsObject:[@[@"personal", PPPersonalFeeds()[i]] componentsJoinedByString:@"-"]]) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:PPPinboardSectionPersonal]];
        }
    }
    
    for (NSInteger i=0; i<[PPCommunityFeeds() count]; i++) {
        if (![delegate.hiddenFeedNames containsObject:[@[@"community", PPCommunityFeeds()[i]] componentsJoinedByString:@"-"]]) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:PPPinboardSectionCommunity]];
        }
    }
    
    return [indexPaths copy];
}

#ifdef PINBOARD

- (NSInteger)numberOfHiddenSections {
    NSInteger numSectionsToHide = 0;
    if ([self personalSectionIsHidden]) {
        numSectionsToHide++;
    }
    
    if ([self communitySectionIsHidden]) {
        numSectionsToHide++;
    }
    
    return numSectionsToHide;
}

- (BOOL)personalSectionIsHidden {
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    return [delegate.hiddenFeedNames indexesOfObjectsPassingTest:^(NSString *feed, NSUInteger idx, BOOL *stop) {
        return [feed hasPrefix:@"personal-"];
    }].count == [PPPersonalFeeds() count];
}

- (BOOL)communitySectionIsHidden {
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    return [delegate.hiddenFeedNames indexesOfObjectsPassingTest:^(NSString *feed, NSUInteger idx, BOOL *stop) {
        return [feed hasPrefix:@"community-"];
    }].count == [PPCommunityFeeds() count];
}

- (PPPinboardSectionType)sectionTypeForSection:(NSInteger)section {
    NSInteger numSectionsSkipped = 0;
    NSInteger numSectionsNotSkipped = 0;

    if (!self.tableView.editing) {
        while (YES) {
            if ([self personalSectionIsHidden]) {
                numSectionsSkipped++;
            }
            else {
                if (numSectionsNotSkipped == section) {
                    break;
                }

                numSectionsNotSkipped++;
            }
            
            if ([self communitySectionIsHidden]) {
                numSectionsSkipped++;
            }
            else {
                if (numSectionsNotSkipped == section) {
                    break;
                }
                
                numSectionsNotSkipped++;
            }

            break;
        }
    }

    return (PPPinboardSectionType)(section + numSectionsSkipped);
}

- (PPPinboardPersonalFeedType)personalFeedForIndexPath:(NSIndexPath *)indexPath {
    NSInteger numFeedsSkipped = 0;
    NSInteger numFeedsNotSkipped = 0;
    
    AppDelegate *delegate = [AppDelegate sharedDelegate];

    if (!self.tableView.editing) {
        for (NSInteger i=0; i<[PPPersonalFeeds() count]; i++) {
            if ([delegate.hiddenFeedNames containsObject:[@[@"personal", PPPersonalFeeds()[i]] componentsJoinedByString:@"-"]]) {
                numFeedsSkipped++;
            }
            else {
                if (numFeedsNotSkipped == indexPath.row) {
                    break;
                }
                numFeedsNotSkipped++;
            }
        }
    }
    
    return (PPPinboardPersonalFeedType)(indexPath.row + numFeedsSkipped);
}

- (PPPinboardCommunityFeedType)communityFeedForIndexPath:(NSIndexPath *)indexPath {
    NSInteger numFeedsSkipped = 0;
    NSInteger numFeedsNotSkipped = 0;
    
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    if (!self.tableView.editing) {
        for (NSInteger i=0; i<[PPCommunityFeeds() count]; i++) {
            if ([delegate.hiddenFeedNames containsObject:[@[@"community", PPCommunityFeeds()[i]] componentsJoinedByString:@"-"]]) {
                numFeedsSkipped++;
            }
            else {
                if (numFeedsNotSkipped == indexPath.row) {
                    break;
                }
                numFeedsNotSkipped++;
            }
        }
    }

    return (PPPinboardCommunityFeedType)(indexPath.row + numFeedsSkipped);
}
#endif

@end
