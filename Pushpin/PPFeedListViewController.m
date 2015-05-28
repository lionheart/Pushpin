//
//  FeedListViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/4/13.
//
//

@import QuartzCore;
@import CoreMotion;

#import "PPFeedListViewController.h"
#import "PPAppDelegate.h"
#import "PPGenericPostViewController.h"
#import "PPPinboardDataSource.h"
#import "PPPinboardFeedDataSource.h"
#import "PPSettingsViewController.h"
#import "PPTagViewController.h"
#import "PPPinboardNotesDataSource.h"
#import "PPSavedFeedsViewController.h"
#import "PPTheme.h"
#import "PPNavigationController.h"
#import "PPTitleButton.h"
#import "PPTableViewTitleView.h"
#import "PPDeliciousDataSource.h"
#import "PPAddSavedFeedViewController.h"
#import "PPSearchViewController.h"
#import "PPSettings.h"
#import "PPShrinkBackTransition.h"
#import <LHSCategoryCollection/UIAlertController+LHSAdditions.h>

#import <ASPinboard/ASPinboard.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIImage+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <Reachability/Reachability.h>
#import <LHSTableViewCells/LHSTableViewCellValue1.h>
#import <LHSTableViewCells/LHSTableViewCellSubtitle.h>

static NSString *SubtitleCellIdentifier = @"SubtitleCellIdentifier";
static NSString *FeedListCellIdentifier = @"FeedListCellIdentifier";

@interface PPFeedListViewController ()

@property (nonatomic, strong) NSMutableArray *feeds;
@property (nonatomic, strong) NSMutableArray *searches;
@property (nonatomic, strong) PPToolbar *toolbar;
@property (nonatomic, strong) NSLayoutConstraint *toolbarBottomConstraint;
@property (nonatomic, strong) NSArray *rightOrientationConstraints;
@property (nonatomic, strong) NSArray *leftOrientationConstraints;
@property (nonatomic, strong) NSArray *centerOrientationConstraints;
@property (nonatomic, strong) NSTimer *feedCountTimer;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic) FeedListToolbarOrientationType toolbarOrientation;

@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) UIButton *tagsButton;

@property (nonatomic, strong) UIBarButtonItem *searchBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *tagsBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *flexibleSpace;

#ifdef PINBOARD
@property (nonatomic, strong) UIButton *noteButton;
@property (nonatomic, strong) UIBarButtonItem *noteBarButtonItem;
#endif

- (void)openNotes;
- (void)openSettings;
- (void)openTags;
- (void)toggleEditing:(UIBarButtonItem *)sender;
- (void)leftBarButtonItemTouchUpInside:(UIBarButtonItem *)sender;
- (void)searchBarButtonItemTouchUpInside:(UIBarButtonItem *)sender;

- (NSArray *)indexPathsForHiddenFeeds;
- (NSArray *)indexPathsForVisibleFeeds;

- (BOOL)personalSectionIsHidden;
- (NSInteger)numberOfHiddenSections;

- (NSString *)personalFeedNameForIndex:(NSInteger)index;

#ifdef DELICIOUS
- (PPDeliciousSectionType)sectionTypeForSection:(NSInteger)section;
- (PPDeliciousPersonalFeedType)personalFeedForIndexPath:(NSIndexPath *)indexPath;
#endif

#ifdef PINBOARD
- (PPPinboardPersonalFeedType)personalFeedForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)communityFeedNameForIndex:(NSInteger)index;
- (PPPinboardSectionType)sectionTypeForSection:(NSInteger)section;
- (BOOL)communitySectionIsHidden;
- (BOOL)feedSectionIsHidden;
- (void)updateSavedFeeds:(FMDatabase *)db;
- (PPPinboardCommunityFeedType)communityFeedForIndexPath:(NSIndexPath *)indexPath;
#endif

- (void)updateFeedCounts;

@end

@implementation PPFeedListViewController

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
    titleView.delegate = self;

    self.title = NSLocalizedString(@"Browse", nil);
    self.navigationItem.titleView = titleView;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.titleView = titleView;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 6.0 / 60.0;

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
    self.searches = [NSMutableArray array];

    self.navigationController.navigationBar.tintColor = HEX(0xFFFFFFFF);

    UIImage *settingsImage = [[UIImage imageNamed:@"navigation-settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton setImage:settingsImage forState:UIControlStateNormal];
    [settingsButton setImage:[settingsImage lhs_imageWithColor:HEX(0x84CBFFFF)] forState:UIControlStateHighlighted];
    [settingsButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    settingsButton.frame = CGRectMake(0, 0, 24, 24);

    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil)
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(leftBarButtonItemTouchUpInside:)];

    settingsBarButtonItem.possibleTitles = [NSSet setWithObjects:NSLocalizedString(@"Settings", nil), NSLocalizedString(@"Cancel", nil), nil];

    UIBarButtonItem *editBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", nil)
                                                                          style:UIBarButtonItemStyleDone
                                                                         target:self
                                                                         action:@selector(toggleEditing:)];

    editBarButtonItem.possibleTitles = [NSSet setWithObjects:NSLocalizedString(@"Edit", nil), NSLocalizedString(@"Done", nil), nil];

    UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];

    self.navigationItem.rightBarButtonItem = editBarButtonItem;
    self.navigationItem.leftBarButtonItem = settingsBarButtonItem;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.backgroundColor = HEX(0xF7F9FDff);
    self.tableView.opaque = YES;
    [self.view addSubview:self.tableView];
    
    self.toolbar = [[PPToolbar alloc] init];
    [self.toolbar setBarTintColor:[UIColor whiteColor]];
    self.toolbar.tintColor = [UIColor darkGrayColor];
    self.toolbar.delegate = self;
    self.toolbar.extraColorLayerOpacity = 0.1;
    
    self.flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    NSDictionary *barButtonTitleTextAttributes = @{NSForegroundColorAttributeName:[UIColor darkGrayColor],
                                                   NSFontAttributeName: [UIFont fontWithName:[PPTheme boldFontName] size:16] };

#ifdef PINBOARD
    self.searchBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Search", nil)
                                                                            style:UIBarButtonItemStyleDone
                                                                           target:self
                                                               action:@selector(searchBarButtonItemTouchUpInside:)];
    
    self.noteBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Notes", nil) style:UIBarButtonItemStylePlain target:self action:@selector(openNotes)];
    [self.noteBarButtonItem setTitleTextAttributes:barButtonTitleTextAttributes forState:UIControlStateNormal];
#endif
    
#ifdef DELICIOUS
    self.searchBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Search", nil)
                                                                style:UIBarButtonItemStyleDone
                                                               target:self
                                                               action:@selector(searchBarButtonItemTouchUpInside:)];
#endif

    self.searchBarButtonItem.tintColor = [UIColor darkGrayColor];
    [self.searchBarButtonItem setTitleTextAttributes:barButtonTitleTextAttributes forState:UIControlStateNormal];

    self.tagsBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Tags", nil) style:UIBarButtonItemStylePlain target:self action:@selector(openTags)];
    [self.tagsBarButtonItem setTitleTextAttributes:barButtonTitleTextAttributes forState:UIControlStateNormal];
    
    self.tagsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tagsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tagsButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Tags", nil) attributes:barButtonTitleTextAttributes]
                               forState:UIControlStateNormal];
    [self.tagsButton addTarget:self action:@selector(openTags) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbar addSubview:self.tagsButton];

    self.searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.searchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.searchButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Search", nil) attributes:barButtonTitleTextAttributes]
                                 forState:UIControlStateNormal];
    [self.searchButton addTarget:self action:@selector(searchBarButtonItemTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbar addSubview:self.searchButton];

#ifdef PINBOARD
    self.noteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.noteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.noteButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Notes", nil) attributes:barButtonTitleTextAttributes] forState:UIControlStateNormal];
    [self.noteButton addTarget:self action:@selector(openNotes) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbar addSubview:self.noteButton];
#endif

    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.toolbar];

    NSDictionary *views = @{@"table": self.tableView,
                            @"top": self.topLayoutGuide,
                            @"bar": self.toolbar,
                            @"search": self.searchButton,
                            @"tags": self.tagsButton,
#ifdef PINBOARD
                            @"notes": self.noteButton
#endif
                        };

#ifdef PINBOARD
    NSMutableArray *constraints = [[NSLayoutConstraint constraintsWithVisualFormat:@"H:[notes]-(>=12)-[search]-(>=12)-[tags]"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:views] mutableCopy];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.noteButton
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.toolbar
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1
                                                         constant:0]];
    
    NSLayoutConstraint *notesLeftConstraint = [NSLayoutConstraint constraintWithItem:self.noteButton
                                                                           attribute:NSLayoutAttributeLeft
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.toolbar
                                                                           attribute:NSLayoutAttributeLeft
                                                                          multiplier:1
                                                                            constant:12];
    
    self.leftOrientationConstraints = [constraints arrayByAddingObject:notesLeftConstraint];
#endif
    
#ifdef DELICIOUS
    NSMutableArray *constraints = [[NSLayoutConstraint constraintsWithVisualFormat:@"H:[search]-(>=12)-[tags]"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:views] mutableCopy];

    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.searchButton
                                                                      attribute:NSLayoutAttributeLeft
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.toolbar
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1
                                                                       constant:12];
    
    self.leftOrientationConstraints = [constraints arrayByAddingObject:leftConstraint];
#endif

    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.tagsButton
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.toolbar
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1
                                                         constant:0]];

    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.searchButton
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.toolbar
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1
                                                         constant:0]];
    
    NSLayoutConstraint *tagsRightConstraint = [NSLayoutConstraint constraintWithItem:self.tagsButton
                                                                           attribute:NSLayoutAttributeRight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.toolbar
                                                                           attribute:NSLayoutAttributeRight
                                                                          multiplier:1
                                                                            constant:-12];

    self.rightOrientationConstraints = [constraints arrayByAddingObject:tagsRightConstraint];
    
#ifdef PINBOARD
    NSLayoutConstraint *searchCenterConstraint = [NSLayoutConstraint constraintWithItem:self.searchButton
                                                                              attribute:NSLayoutAttributeCenterX
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.toolbar
                                                                              attribute:NSLayoutAttributeCenterX
                                                                             multiplier:1
                                                                               constant:0];

    self.centerOrientationConstraints = [constraints arrayByAddingObjectsFromArray:@[notesLeftConstraint, tagsRightConstraint, searchCenterConstraint]];
#endif

#ifdef DELICIOUS
    self.centerOrientationConstraints = [constraints arrayByAddingObjectsFromArray:@[leftConstraint, tagsRightConstraint]];
#endif
    
    [self.toolbar addConstraints:self.centerOrientationConstraints];
    
    self.toolbarBottomConstraint = [NSLayoutConstraint constraintWithItem:self.toolbar
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.bottomLayoutGuide
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1
                                                                   constant:0];
    
    [self.view addConstraint:self.toolbarBottomConstraint];
    [self.toolbar lhs_fillWidthOfSuperview];
    [self.tableView lhs_fillWidthOfSuperview];
    [self.view lhs_addConstraints:@"V:[top][table][bar(44)]" views:views];

    // Register for Dynamic Type notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];

    [self.tableView registerClass:[LHSTableViewCellSubtitle class] forCellReuseIdentifier:SubtitleCellIdentifier];
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:FeedListCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.feedCountTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(updateFeedCounts) userInfo:nil repeats:YES];
    [self updateFeedCounts];

    // On the iPad, the navigation bar changes color based on the view controller last pushed
    if (![UIApplication isIPad]) {
        self.navigationController.navigationBar.barTintColor = HEX(0x0096ffff);
    }

#ifdef PINBOARD
    PPSettings *settings = [PPSettings sharedSettings];

    if (!settings.feedToken) {
        [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];;
        [[ASPinboard sharedInstance] rssKeyWithSuccess:^(NSString *feedToken) {
            settings.feedToken = feedToken;
            [self.tableView reloadData];
        } failure:nil];
    }
#endif
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.feedCountTimer invalidate];
    self.feedCountTimer = nil;
    [self.motionManager stopDeviceMotionUpdates];
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#ifdef DELICIOUS
    if (self.tableView.allowsMultipleSelectionDuringEditing) {
        return PPProviderDeliciousSections;
    }
    else {
        return PPProviderDeliciousSections - [self numberOfHiddenSections];
    }
#endif
    
#ifdef PINBOARD
    if (self.tableView.allowsMultipleSelectionDuringEditing) {
        return PPProviderPinboardSections;
    }
    else {
        return PPProviderPinboardSections - [self numberOfHiddenSections];
    }
#endif
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#ifdef DELICIOUS
    PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
    PPDeliciousSectionType sectionType = [self sectionTypeForSection:section];

    if (tableView.allowsMultipleSelectionDuringEditing) {
        switch (sectionType) {
            case PPDeliciousSectionPersonal:
                return PPDeliciousPersonalRows;
        }
    }
    else {
        switch (sectionType) {
            case PPDeliciousSectionPersonal: {
                NSArray *filteredRows = [settings.hiddenFeedNames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", @"personal"]];
                return PPDeliciousPersonalRows - filteredRows.count;
            }
        }
    }
#endif
    
#ifdef PINBOARD
    PPPinboardSectionType sectionType = [self sectionTypeForSection:section];
    
    if (tableView.editing) {
        switch (sectionType) {
            case PPPinboardSectionPersonal:
                return PPPinboardPersonalRows;
                
            case PPPinboardSectionCommunity:
                return PPPinboardCommunityRows;

            case PPPinboardSectionSavedFeeds:
                return self.feeds.count + 1;
                
            case PPPinboardSectionSearches:
                return self.searches.count;
        }
    }
    else {
        PPSettings *settings = [PPSettings sharedSettings];
        switch (sectionType) {
            case PPPinboardSectionPersonal: {
                NSArray *filteredRows = [settings.hiddenFeedNames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", @"personal"]];
                return PPPinboardPersonalRows - filteredRows.count;
            }
                
            case PPPinboardSectionCommunity: {
                NSArray *filteredRows = [settings.hiddenFeedNames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", @"community"]];
                return PPPinboardCommunityRows - filteredRows.count;
            }
                
            case PPPinboardSectionSavedFeeds:
                return self.feeds.count;
                
            case PPPinboardSectionSearches:
                return self.searches.count;
        }
    }
#endif
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
#ifdef PINBOARD
    PPPinboardSectionType sectionType = [self sectionTypeForSection:section];
    switch (sectionType) {
        case PPPinboardSectionPersonal:
            return NSLocalizedString(@"Personal", nil);
            
        case PPPinboardSectionCommunity:
            return NSLocalizedString(@"Community", nil);
            
        case PPPinboardSectionSavedFeeds:
            return NSLocalizedString(@"Feeds", nil);

        case PPPinboardSectionSearches:
            return NSLocalizedString(@"Searches", nil);
    }
#endif
    
#ifdef DELICIOUS
    PPDeliciousSectionType sectionType = [self sectionTypeForSection:section];
    switch (sectionType) {
        case PPDeliciousSectionPersonal:
            return NSLocalizedString(@"Personal", nil);
    }
#endif
    return nil;
}

#ifdef PINBOARD
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    PPPinboardSectionType sectionType = [self sectionTypeForSection:indexPath.section];

    if (tableView.allowsMultipleSelectionDuringEditing) {
        if (sectionType == PPPinboardSectionSavedFeeds) {
            return NO;
        }
        else if (sectionType == PPPinboardSectionSearches) {
            return NO;
        }
    }
    else {
        switch (sectionType) {
            case PPPinboardSectionCommunity:
                return NO;
                
            case PPPinboardSectionPersonal:
                return NO;
                
            case PPPinboardSectionSavedFeeds:
                return YES;
                
            case PPPinboardSectionSearches:
                return YES;
        }
    }
    
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    PPPinboardSectionType sectionType = [self sectionTypeForSection:indexPath.section];
    switch (sectionType) {
        case PPPinboardSectionSavedFeeds: {
            NSDictionary *feed = self.feeds[indexPath.row];
            PPPinboardFeedDataSource *dataSource = [[PPPinboardFeedDataSource alloc] initWithComponents:feed[@"components"]];
            [dataSource removeDataSource:^{
                [self.feeds removeObjectAtIndex:indexPath.row];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [tableView reloadData];
                });
            }];
            break;
        }
            
        case PPPinboardSectionSearches: {
            NSString *name = self.searches[indexPath.row][@"name"];
            [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                [db executeUpdate:@"DELETE FROM searches WHERE name=?" withArgumentsInArray:@[name]];
            }];
            
            NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
            [store synchronize];
            
            NSMutableArray *iCloudSearches = [NSMutableArray arrayWithArray:[store arrayForKey:kSavedSearchesKey]];
            for (NSInteger i=0; i<iCloudSearches.count; i++) {
                if ([iCloudSearches[i][@"name"] isEqualToString:name]) {
                    [iCloudSearches removeObjectAtIndex:i];
                    break;
                }
            }

            [store setArray:iCloudSearches forKey:kSavedSearchesKey];
            [store synchronize];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.searches removeObjectAtIndex:indexPath.row];
                [tableView reloadData];
            });
            break;
        }
    }
}
#endif

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    cell.textLabel.font = [PPTheme boldTextLabelFont];
    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.font = [PPTheme detailLabelFont];
    cell.clipsToBounds = YES;
    
#ifdef DELICIOUS
    cell = [tableView dequeueReusableCellWithIdentifier:FeedListCellIdentifier forIndexPath:indexPath];
    switch ((PPDeliciousSectionType)indexPath.section) {
        case PPDeliciousSectionPersonal: {
            PPDeliciousPersonalFeedType feedType = [self personalFeedForIndexPath:indexPath];

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

            cell.detailTextLabel.text = self.bookmarkCounts[feedType];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
    }
#endif
    
#ifdef PINBOARD
    PPPinboardSectionType sectionType = [self sectionTypeForSection:indexPath.section];
    switch (sectionType) {
        case PPPinboardSectionPersonal: {
            cell = [tableView dequeueReusableCellWithIdentifier:FeedListCellIdentifier forIndexPath:indexPath];
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.font = [PPTheme detailLabelFont];
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
            
            static NSNumberFormatter *formatter;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                formatter = [[NSNumberFormatter alloc] init];
                formatter.numberStyle = NSNumberFormatterDecimalStyle;
                formatter.groupingSeparator = [[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator];
            });

            NSNumber *number = [formatter numberFromString:self.bookmarkCounts[feedType]];
            cell.detailTextLabel.text = [formatter stringFromNumber:number];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }

        case PPPinboardSectionCommunity: {
            cell = [tableView dequeueReusableCellWithIdentifier:FeedListCellIdentifier forIndexPath:indexPath];
            cell.imageView.image = nil;
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.text = nil;
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
                    cell.textLabel.text = NSLocalizedString(@"Wikipedia", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-wikipedia"];
                    break;

                case PPPinboardCommunityFeedFandom:
                    cell.textLabel.text = NSLocalizedString(@"Fandom", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-fandom"];
                    break;

                case PPPinboardCommunityFeedJapan:
                    cell.textLabel.text = NSLocalizedString(@"日本語", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-japanese"];
                    break;
                    
                case PPPinboardCommunityFeedRecent:
                    cell.textLabel.text = NSLocalizedString(@"Recent", nil);
                    cell.imageView.image = [UIImage imageNamed:@"browse-recent"];
                    break;
            }

            break;
        }
            
        case PPPinboardSectionSavedFeeds: {
            cell = [tableView dequeueReusableCellWithIdentifier:FeedListCellIdentifier forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.detailTextLabel.text = nil;

            if (tableView.editing) {
                if (indexPath.row == 0) {
                    cell.textLabel.text = NSLocalizedString(@"Add Feed", nil);
                    cell.imageView.image = nil;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                else {
                    cell.textLabel.text = self.feeds[indexPath.row - 1][@"title"];
                    cell.imageView.image = [UIImage imageNamed:@"browse-saved"];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
            else {
                cell.textLabel.text = self.feeds[indexPath.row][@"title"];
                cell.imageView.image = [UIImage imageNamed:@"browse-saved"];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            break;
        }
            
        case PPPinboardSectionSearches: {
            cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier forIndexPath:indexPath];
            NSDictionary *search = self.searches[indexPath.row];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.font = [PPTheme textLabelFont];
            cell.textLabel.text = search[@"name"];
            cell.detailTextLabel.font = [PPTheme detailLabelFontAlternate1];
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            cell.imageView.image = [UIImage imageNamed:@"browse-search"];
            cell.accessoryType = UITableViewCellAccessoryNone;

            NSString *query = search[@"query"];
            NSMutableArray *components = [NSMutableArray array];
            if (query && ![query isEqualToString:@""]) {
                [components addObject:[NSString stringWithFormat:@"query: \"%@\"", query]];
            }

            kPushpinFilterType isPrivate = [search[@"private"] integerValue];
            switch (isPrivate) {
                case kPushpinFilterFalse:
                    [components addObject:@"public"];
                    
                case kPushpinFilterTrue:
                    [components addObject:@"private"];
            }

            kPushpinFilterType unread = [search[@"unread"] integerValue];
            switch (unread) {
                case kPushpinFilterFalse:
                    [components addObject:@"read"];
                    
                case kPushpinFilterTrue:
                    [components addObject:@"unread"];
            }

            kPushpinFilterType starred = [search[@"starred"] integerValue];
            switch (starred) {
                case kPushpinFilterFalse:
                    [components addObject:@"unstarred"];
                    
                case kPushpinFilterTrue:
                    [components addObject:@"starred"];
            }

            kPushpinFilterType tagged = [search[@"tagged"] integerValue];
            switch (tagged) {
                case kPushpinFilterFalse:
                    [components addObject:@"untagged"];
                    
                case kPushpinFilterTrue:
                    [components addObject:@"tagged"];
            }

            cell.detailTextLabel.text = [components componentsJoinedByString:@", "];
            break;
        }
    }
#endif

    cell.showsReorderControl = YES;
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
       toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
#ifdef PINBOARD
    PPPinboardSectionType destinationSection = (PPPinboardSectionType)proposedDestinationIndexPath.section;
    PPPinboardSectionType sourceSection = (PPPinboardSectionType)sourceIndexPath.section;

    if (destinationSection < sourceSection) {
        // The row was moved to a section above the current one, so change the row to 0.
        return [NSIndexPath indexPathForRow:0 inSection:sourceSection];
    }
    else if (destinationSection > sourceSection) {
        // The row was moved to a section above the current one, so change the row to the last row.
        switch (sourceSection) {
            case PPPinboardSectionPersonal:
                return [NSIndexPath indexPathForRow:(PPPinboardPersonalRows-1) inSection:sourceSection];

            case PPPinboardSectionCommunity:
                return [NSIndexPath indexPathForRow:(PPPinboardCommunityRows-1) inSection:sourceSection];

            default:
                return sourceIndexPath;
        }
    }
    else {
        return proposedDestinationIndexPath;
    }
#endif
    
#ifdef DELICIOUS
    PPDeliciousSectionType destinationSection = (PPDeliciousSectionType)proposedDestinationIndexPath.section;
    PPDeliciousSectionType sourceSection = (PPDeliciousSectionType)sourceIndexPath.section;
    
    if (destinationSection < sourceSection) {
        // The row was moved to a section above the current one, so change the row to 0.
        return [NSIndexPath indexPathForRow:0 inSection:sourceSection];
    }
    else if (destinationSection > sourceSection) {
        // The row was moved to a section above the current one, so change the row to the last row.
        switch (sourceSection) {
            case PPDeliciousSectionPersonal:
                return [NSIndexPath indexPathForRow:(PPDeliciousPersonalRows-1) inSection:sourceSection];

            default:
                return sourceIndexPath;
        }
    }
    else {
        return proposedDestinationIndexPath;
    }
#endif
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath
      toIndexPath:(NSIndexPath *)destinationIndexPath {
#ifdef PINBOARD
    PPPinboardSectionType sectionType = [self sectionTypeForSection:sourceIndexPath.section];
    PPSettings *settings = [PPSettings sharedSettings];

    switch (sectionType) {
        case PPPinboardSectionPersonal: {
            NSMutableArray *feeds = [settings.personalFeedOrder mutableCopy];
            NSNumber *object = feeds[sourceIndexPath.row];
            [feeds removeObjectAtIndex:sourceIndexPath.row];
            [feeds insertObject:object atIndex:destinationIndexPath.row];
            settings.personalFeedOrder = [feeds copy];
            break;
        }

        case PPPinboardSectionCommunity: {
            NSMutableArray *feeds = [settings.communityFeedOrder mutableCopy];
            NSNumber *object = feeds[sourceIndexPath.row];
            [feeds removeObjectAtIndex:sourceIndexPath.row];
            [feeds insertObject:object atIndex:destinationIndexPath.row];
            settings.communityFeedOrder = [feeds copy];
            break;
        }

        default:
            break;
    }
#endif
    
#ifdef DELICIOUS
    PPDeliciousSectionType sectionType = [self sectionTypeForSection:sourceIndexPath.section];
    PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
    
    switch (sectionType) {
        case PPDeliciousSectionPersonal: {
            NSMutableArray *feeds = [settings.personalFeedOrder mutableCopy];
            NSNumber *object = feeds[sourceIndexPath.row];
            [feeds removeObjectAtIndex:sourceIndexPath.row];
            [feeds insertObject:object atIndex:destinationIndexPath.row];
            settings.personalFeedOrder = [feeds copy];
            break;
        }

        default:
            break;
    }
#endif
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    PPGenericPostViewController *postViewController = [[PPGenericPostViewController alloc] init];
    
    UIViewController *viewControllerToPush;

    if (tableView.allowsMultipleSelectionDuringEditing) {
#ifdef PINBOARD
        PPPinboardSectionType sectionType = [self sectionTypeForSection:indexPath.section];
        switch (sectionType) {
            case PPPinboardSectionSavedFeeds: {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                
                if (indexPath.row == 0) {
                    PPAddSavedFeedViewController *addSavedFeedViewController = [[PPAddSavedFeedViewController alloc] init];
                    addSavedFeedViewController.SuccessCallback = ^{
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                                [self updateSavedFeeds:db];
                            }];
                        });
                    };

                    PPNavigationController *navigationController = [[PPNavigationController alloc] initWithRootViewController:addSavedFeedViewController];
                    if ([UIApplication isIPad]) {
                        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                    }
                    [self presentViewController:navigationController animated:YES completion:nil];
                }
                break;
            }
                
            default:
                break;
        }
#endif
    }
    else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

#ifdef DELICIOUS
        switch ((PPDeliciousSectionType)indexPath.section) {
            case PPDeliciousSectionPersonal: {
                PPDeliciousDataSource *dataSource = [[PPDeliciousDataSource alloc] init];
                dataSource.limit = 100;

                PPDeliciousPersonalFeedType feedType = [self personalFeedForIndexPath:indexPath];

                switch (feedType) {
                    case PPDeliciousPersonalFeedAll:
                        [mixpanel track:@"Browsed all bookmarks"];
                        break;
                        
                    case PPDeliciousPersonalFeedPrivate:
                        dataSource.isPrivate = YES;
                        [mixpanel track:@"Browsed private bookmarks"];
                        break;
                        
                    case PPDeliciousPersonalFeedPublic:
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
        PPSettings *settings = [PPSettings sharedSettings];
        PPPinboardSectionType sectionType = [self sectionTypeForSection:indexPath.section];
        switch (sectionType) {
            case PPPinboardSectionPersonal: {
                NSInteger numFeedsSkipped = 0;
                NSInteger numFeedsNotSkipped = 0;
                
                if (!tableView.allowsMultipleSelectionDuringEditing) {
                    for (NSInteger i=0; i<[PPPersonalFeeds() count]; i++) {
                        if ([settings.hiddenFeedNames containsObject:[@[@"personal", [self personalFeedNameForIndex:i]] componentsJoinedByString:@"-"]]) {
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
                
                PPPinboardPersonalFeedType feedType = (PPPinboardPersonalFeedType)([settings.personalFeedOrder[indexPath.row + numFeedsSkipped] integerValue]);

                PPPinboardDataSource *dataSource = [[PPPinboardDataSource alloc] init];
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
                PPPinboardFeedDataSource *feedDataSource = [[PPPinboardFeedDataSource alloc] init];
                postViewController.postDataSource = feedDataSource;
                [tableView deselectRowAtIndexPath:indexPath animated:YES];

                if (![PPAppDelegate sharedDelegate].connectionAvailable) {
                    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Uh oh.", nil)
                                                                                 message:NSLocalizedString(@"You can't browse popular feeds unless you have an active Internet connection.", nil)];
                    
                    [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                            style:UIAlertActionStyleDefault
                                          handler:nil];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                }
                else {
                    PPPinboardCommunityFeedType feedType = [self communityFeedForIndexPath:indexPath];

                    switch (feedType) {
                        case PPPinboardCommunityFeedNetwork: {
                            feedDataSource.components = @[[NSString stringWithFormat:@"secret:%@", settings.feedToken], [NSString stringWithFormat:@"u:%@", settings.username], @"network"];
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

                        case PPPinboardCommunityFeedRecent: {
                            feedDataSource.components = @[@"recent"];
                            [mixpanel track:@"Browsed Recent bookmarks"];
                            break;
                        }
                    }
                    
                    viewControllerToPush = postViewController;
                    break;
                }
            }
                
            case PPPinboardSectionSavedFeeds: {
                viewControllerToPush = [PPPinboardFeedDataSource postViewControllerWithComponents:self.feeds[indexPath.row][@"components"]];
                break;
            }
                
            case PPPinboardSectionSearches: {
                PPGenericPostViewController *postViewController = [[PPGenericPostViewController alloc] init];
                PPPinboardDataSource *dataSource = [[PPPinboardDataSource alloc] init];
                dataSource.limit = 100;
                
                NSDictionary *search = self.searches[indexPath.row];
                
                NSString *searchQuery = search[@"query"];
                if (searchQuery && ![searchQuery isEqualToString:@""]) {
                    dataSource.searchQuery = search[@"query"];
                }

                dataSource.unread = [search[@"unread"] integerValue];
                dataSource.isPrivate = [search[@"private"] integerValue];
                dataSource.starred = [search[@"starred"] integerValue];
                
                kPushpinFilterType tagged = [search[@"tagged"] integerValue];
                switch (tagged) {
                    case kPushpinFilterTrue:
                        dataSource.untagged = kPushpinFilterFalse;
                        break;
                        
                    case kPushpinFilterFalse:
                        dataSource.untagged = kPushpinFilterTrue;
                        break;
                        
                    case kPushpinFilterNone:
                        dataSource.untagged = kPushpinFilterNone;
                        break;
                }
                
                postViewController.postDataSource = dataSource;
                viewControllerToPush = postViewController;
            }
        }
#endif
    
        // We need to switch this based on whether the user is on an iPad, due to the split view controller.
        if ([UIApplication isIPad]) {
            UINavigationController *navigationController = [PPAppDelegate sharedDelegate].navigationController;
            if (navigationController.viewControllers.count == 1) {
                UIBarButtonItem *showPopoverBarButtonItem = navigationController.topViewController.navigationItem.leftBarButtonItem;
                if (showPopoverBarButtonItem) {
                    viewControllerToPush.navigationItem.leftBarButtonItem = showPopoverBarButtonItem;
                }
            }

            [navigationController setViewControllers:@[viewControllerToPush] animated:YES];
            
            if ([viewControllerToPush respondsToSelector:@selector(postDataSource)]) {
                if ([[(PPGenericPostViewController *)viewControllerToPush postDataSource] respondsToSelector:@selector(barTintColor)]) {
                    [self.navigationController.navigationBar setBarTintColor:[[(PPGenericPostViewController *)viewControllerToPush postDataSource] barTintColor]];
                }
            }
            
            UIPopoverController *popover = [PPAppDelegate sharedDelegate].feedListViewController.popover;
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
    if (self.tableView.allowsMultipleSelectionDuringEditing) {
        [self toggleEditing:sender];
    }
    else {
        PPSettingsViewController *svc = [[PPSettingsViewController alloc] init];
        [self.navigationController pushViewController:svc animated:YES];
    }
}

- (void)openNotes {
    PPGenericPostViewController *notesViewController = [[PPGenericPostViewController alloc] init];
    PPPinboardNotesDataSource *notesDataSource = [[PPPinboardNotesDataSource alloc] init];
    notesViewController.postDataSource = notesDataSource;
    notesViewController.title = NSLocalizedString(@"Notes", nil);
    [self.navigationController pushViewController:notesViewController animated:YES];
}

- (void)openTags {
    PPTagViewController *tagViewController = [[PPTagViewController alloc] init];
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
    if (![PPAppDelegate sharedDelegate].connectionAvailable) {
        UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:nil
                                                                     message:NSLocalizedString(@"Editing feeds requires an active Internet connection.", nil)];
        
        [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil)
                                style:UIAlertActionStyleDefault
                              handler:nil];
        
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    if (self.tableView.allowsMultipleSelectionDuringEditing) {
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Settings", nil);
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Edit", nil);

        NSArray *indexPathsForSelectedRows = [self.tableView indexPathsForSelectedRows];
        
        self.tableView.allowsMultipleSelectionDuringEditing = NO;
        [self.tableView setEditing:NO animated:YES];

        if (sender == self.navigationItem.leftBarButtonItem) {
            // Don't commit updates. User pressed Cancel.
        }
        else {
            // Commit updates. User pressed Done.
            NSMutableArray *visibleFeedNames = [NSMutableArray array];
            NSMutableArray *hiddenFeedNames = [NSMutableArray array];
            
            for (NSIndexPath *indexPath in indexPathsForSelectedRows) {
#ifdef DELICIOUS
                PPDeliciousSectionType sectionType = (PPDeliciousSectionType)indexPath.section;
                NSString *feedName;
                
                switch (sectionType) {
                    case PPDeliciousSectionPersonal: {
                        feedName = [@[@"personal", [self personalFeedNameForIndex:indexPath.row]] componentsJoinedByString:@"-"];
                        break;
                    }
                        
                    default:
                        continue;
                }
#endif
                
#ifdef PINBOARD
                PPPinboardSectionType sectionType = (PPPinboardSectionType)indexPath.section;
                NSString *feedName;
                
                switch (sectionType) {
                    case PPPinboardSectionPersonal: {
                        feedName = [@[@"personal", [self personalFeedNameForIndex:indexPath.row]] componentsJoinedByString:@"-"];
                        break;
                    }
                        
                    case PPPinboardSectionCommunity: {
                        feedName = [@[@"community", [self communityFeedNameForIndex:indexPath.row]] componentsJoinedByString:@"-"];
                        break;
                    }
                        
                    default:
                        continue;
                }
#endif
                
                [visibleFeedNames addObject:feedName];
            }
            
            for (NSInteger section=0; section<[PPSections() count]; section++) {
                NSInteger numberOfRows;
                
#ifdef DELICIOUS
                PPDeliciousSectionType sectionType = (PPDeliciousSectionType)section;
                
                switch (sectionType) {
                    case PPDeliciousSectionPersonal:
                        numberOfRows = [PPPersonalFeeds() count];
                        break;
                }
                
                for (NSInteger row=0; row<numberOfRows; row++) {
                    PPDeliciousSectionType sectionType = (PPDeliciousSectionType)section;
                    
                    NSString *feedName;
                    switch (sectionType) {
                        case PPDeliciousSectionPersonal: {
                            feedName = [@[PPSections()[section], [self personalFeedNameForIndex:row]] componentsJoinedByString:@"-"];
                            break;
                        }
                    }

                    if (feedName && ![visibleFeedNames containsObject:feedName]) {
                        [hiddenFeedNames addObject:feedName];
                    }
                }
#endif

#ifdef PINBOARD
                PPPinboardSectionType sectionType = (PPPinboardSectionType)section;

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
                        
                    case PPPinboardSectionSearches:
                        numberOfRows = 0;
                        break;
                }

                for (NSInteger row=0; row<numberOfRows; row++) {
                    PPPinboardSectionType sectionType = (PPPinboardSectionType)section;
                    
                    NSString *feedName;
                    switch (sectionType) {
                        case PPPinboardSectionPersonal: {
                            feedName = [@[PPSections()[section], [self personalFeedNameForIndex:row]] componentsJoinedByString:@"-"];
                            break;
                        }
                            
                        case PPPinboardSectionCommunity: {
                            feedName = [@[PPSections()[section], [self communityFeedNameForIndex:row]] componentsJoinedByString:@"-"];
                            break;
                        }
                            
                        default:
                            break;
                    }
                    
                    if (feedName && ![visibleFeedNames containsObject:feedName]) {
                        [hiddenFeedNames addObject:feedName];
                    }
                }
#endif
            }
            
            PPSettings *settings = [PPSettings sharedSettings];
            settings.hiddenFeedNames = [hiddenFeedNames copy];
        }
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.toolbarBottomConstraint.constant = 0;
                             [self.view layoutIfNeeded];
                         }];
        
        [CATransaction begin];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:[self indexPathsForHiddenFeeds] withRowAnimation:UITableViewRowAnimationFade];
        
#ifdef DELICIOUS
        if ([self personalSectionIsHidden]) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPDeliciousSectionPersonal] withRowAnimation:UITableViewRowAnimationFade];

        }
#endif
        
#ifdef PINBOARD
        if ([self personalSectionIsHidden]) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionPersonal] withRowAnimation:UITableViewRowAnimationFade];\
        }

        if ([self communitySectionIsHidden]) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionCommunity] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        if ([self feedSectionIsHidden]) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionSavedFeeds]
                          withRowAnimation:UITableViewRowAnimationFade];
        }
        else {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionSavedFeeds]
                          withRowAnimation:UITableViewRowAnimationFade];
        }
        
        if ([self searchSectionIsHidden]) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionSearches]
                          withRowAnimation:UITableViewRowAnimationFade];
        }
        else {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionSearches]
                          withRowAnimation:UITableViewRowAnimationFade];
        }
#endif

        [CATransaction setCompletionBlock:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSMutableArray *allIndexPaths = [NSMutableArray array];
                for (NSInteger section=0; section<[self numberOfSectionsInTableView:self.tableView]; section++) {
                    for (NSInteger row=0; row<[self.tableView numberOfRowsInSection:section]; row++) {
                        [allIndexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
                    }
                }

                if (allIndexPaths.count <= PPPersonalFeeds().count + PPCommunityFeeds().count) {
                    [self.tableView beginUpdates];
                    [self.tableView reloadRowsAtIndexPaths:allIndexPaths withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView endUpdates];
                }
            });
        }];

        [self.tableView endUpdates];
        [CATransaction commit];
    }
    else {
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Cancel", nil);
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Done", nil);
        
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        [self.tableView setEditing:YES animated:YES];
        
        // http://crashes.to/s/50699750a80
        @try {
            [self.tableView beginUpdates];

            if ([self personalSectionIsHidden]) {
#ifdef PINBOARD
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionPersonal] withRowAnimation:UITableViewRowAnimationFade];
#endif

#ifdef DELICIOUS
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPDeliciousSectionPersonal] withRowAnimation:UITableViewRowAnimationFade];
#endif
            }

#ifdef PINBOARD
            if ([self communitySectionIsHidden]) {
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionCommunity] withRowAnimation:UITableViewRowAnimationFade];
            }

            if ([self feedSectionIsHidden]) {
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionSavedFeeds]
                              withRowAnimation:UITableViewRowAnimationFade];
            }
            else {
                NSInteger hiddenSections = [self numberOfHiddenSections];
                if ([self searchSectionIsHidden]) {
                    hiddenSections--;
                }
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionSavedFeeds - hiddenSections]
                              withRowAnimation:UITableViewRowAnimationFade];
            }

            if ([self searchSectionIsHidden]) {
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionSearches]
                              withRowAnimation:UITableViewRowAnimationFade];
            }
            else {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:PPPinboardSectionSearches - [self numberOfHiddenSections]]
                              withRowAnimation:UITableViewRowAnimationFade];
            }
#endif
            
            [self.tableView insertRowsAtIndexPaths:[self indexPathsForHiddenFeeds] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        @catch (NSException *exception) {
            [self.tableView reloadData];
        }

        [UIView animateWithDuration:0.3
                         animations:^{
                             self.toolbarBottomConstraint.constant = 44;
                             [self.view layoutIfNeeded];
                         }];

        for (NSIndexPath *indexPath in [self indexPathsForVisibleFeeds]) {
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

- (NSArray *)indexPathsForHiddenFeeds {
    NSMutableArray *indexPaths = [NSMutableArray array];
    PPSettings *settings = [PPSettings sharedSettings];
    
    if (![self personalSectionIsHidden]) {
        for (NSInteger i=0; i<[PPPersonalFeeds() count]; i++) {
#ifdef PINBOARD
            if ([settings.hiddenFeedNames containsObject:[@[@"personal", [self personalFeedNameForIndex:i]] componentsJoinedByString:@"-"]]) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:PPPinboardSectionPersonal]];
            }
#endif
                
#ifdef DELICIOUS
            if ([settings.hiddenFeedNames containsObject:[@[@"personal", [self personalFeedNameForIndex:i]] componentsJoinedByString:@"-"]]) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:PPDeliciousSectionPersonal]];
            }
#endif
        }
    }

#ifdef PINBOARD
    if (![self communitySectionIsHidden]) {
        for (NSInteger i=0; i<[PPCommunityFeeds() count]; i++) {
            if ([settings.hiddenFeedNames containsObject:[@[@"community", [self communityFeedNameForIndex:i]] componentsJoinedByString:@"-"]]) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:PPPinboardSectionCommunity]];
            }
        }
    }
#endif

    return [indexPaths copy];
}

- (NSArray *)indexPathsForVisibleFeeds {
    NSMutableArray *indexPaths = [NSMutableArray array];
    PPSettings *settings = [PPSettings sharedSettings];
    for (NSInteger i=0; i<[PPPersonalFeeds() count]; i++) {
#ifdef PINBOARD
        if (![settings.hiddenFeedNames containsObject:[@[@"personal", [self personalFeedNameForIndex:i]] componentsJoinedByString:@"-"]]) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:PPPinboardSectionPersonal]];
        }
#endif
            
#ifdef DELICIOUS
        if (![settings.hiddenFeedNames containsObject:[@[@"personal", [self personalFeedNameForIndex:i]] componentsJoinedByString:@"-"]]) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:PPDeliciousSectionPersonal]];
        }
#endif
    }
    
#ifdef PINBOARD
    for (NSInteger i=0; i<[PPCommunityFeeds() count]; i++) {
        if (![settings.hiddenFeedNames containsObject:[@[@"community", [self communityFeedNameForIndex:i]] componentsJoinedByString:@"-"]]) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:PPPinboardSectionCommunity]];
        }
    }
#endif
    
    return [indexPaths copy];
}

- (BOOL)personalSectionIsHidden {
    PPSettings *settings = [PPSettings sharedSettings];
    return [settings.hiddenFeedNames indexesOfObjectsPassingTest:^(NSString *feed, NSUInteger idx, BOOL *stop) {
        return [feed hasPrefix:@"personal-"];
    }].count == [PPPersonalFeeds() count];
}

- (NSInteger)numberOfHiddenSections {
    NSInteger numSectionsToHide = 0;
    if ([self personalSectionIsHidden]) {
        numSectionsToHide++;
    }
    
#ifdef PINBOARD
    if ([self communitySectionIsHidden]) {
        numSectionsToHide++;
    }

    if ([self feedSectionIsHidden]) {
        numSectionsToHide++;
    }
    
    if ([self searchSectionIsHidden]) {
        numSectionsToHide++;
    }
#endif
    
    return numSectionsToHide;
}

#ifdef DELICIOUS

- (PPDeliciousSectionType)sectionTypeForSection:(NSInteger)section {
    NSInteger numSectionsSkipped = 0;
    NSInteger numSectionsNotSkipped = 0;

    if (!self.tableView.allowsMultipleSelectionDuringEditing) {
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
            
            break;
        }
    }
    
    return (PPDeliciousSectionType)(section + numSectionsSkipped);
}

- (PPDeliciousPersonalFeedType)personalFeedForIndexPath:(NSIndexPath *)indexPath {
    NSInteger numFeedsSkipped = 0;
    NSInteger numFeedsNotSkipped = 0;
    
    PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];
    
    if (!self.tableView.allowsMultipleSelectionDuringEditing) {
        for (NSInteger i=0; i<[PPPersonalFeeds() count]; i++) {
            if ([settings.hiddenFeedNames containsObject:[@[@"personal", [self personalFeedNameForIndex:i]] componentsJoinedByString:@"-"]]) {
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
    
    return (PPDeliciousPersonalFeedType)([settings.personalFeedOrder[indexPath.row + numFeedsSkipped] integerValue]);
}

#endif

- (NSString *)personalFeedNameForIndex:(NSInteger)index {
    return PPPersonalFeeds()[[[PPSettings sharedSettings].personalFeedOrder[index] integerValue]];
}

#ifdef PINBOARD

- (NSString *)communityFeedNameForIndex:(NSInteger)index {
    return PPCommunityFeeds()[[[PPSettings sharedSettings].communityFeedOrder[index] integerValue]];
}

- (BOOL)feedSectionIsHidden {
    return self.feeds.count == 0;
}

- (BOOL)searchSectionIsHidden {
    return self.searches.count == 0;
}

- (BOOL)communitySectionIsHidden {
    if ([PPAppDelegate sharedDelegate].connectionAvailable) {
        PPSettings *settings = [PPSettings sharedSettings];
        return [settings.hiddenFeedNames indexesOfObjectsPassingTest:^(NSString *feed, NSUInteger idx, BOOL *stop) {
            return [feed hasPrefix:@"community-"];
        }].count == [PPCommunityFeeds() count];
    }
    else {
        return YES;
    }
}

- (PPPinboardSectionType)sectionTypeForSection:(NSInteger)section {
    NSInteger numSectionsSkipped = 0;
    NSInteger numSectionsNotSkipped = 0;
    
    if (!self.tableView.allowsMultipleSelectionDuringEditing) {
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
            
            if ([self feedSectionIsHidden]) {
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
    
    PPSettings *settings = [PPSettings sharedSettings];

    if (!self.tableView.allowsMultipleSelectionDuringEditing) {
        for (NSInteger i=0; i<[PPPersonalFeeds() count]; i++) {
            if ([settings.hiddenFeedNames containsObject:[@[@"personal", [self personalFeedNameForIndex:i]] componentsJoinedByString:@"-"]]) {
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
    
    return (PPPinboardPersonalFeedType)([settings.personalFeedOrder[indexPath.row + numFeedsSkipped] integerValue]);
}
#endif

#ifdef PINBOARD
- (PPPinboardCommunityFeedType)communityFeedForIndexPath:(NSIndexPath *)indexPath {
    NSInteger numFeedsSkipped = 0;
    NSInteger numFeedsNotSkipped = 0;
    PPSettings *settings = [PPSettings sharedSettings];
    if (!self.tableView.allowsMultipleSelectionDuringEditing) {
        for (NSInteger i=0; i<[PPCommunityFeeds() count]; i++) {
            if ([settings.hiddenFeedNames containsObject:[@[@"community", [self communityFeedNameForIndex:i]] componentsJoinedByString:@"-"]]) {
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

    return (PPPinboardCommunityFeedType)([settings.communityFeedOrder[indexPath.row + numFeedsSkipped] integerValue]);
}
#endif

- (void)searchBarButtonItemTouchUpInside:(UIBarButtonItem *)sender {
    PPSearchViewController *search = [[PPSearchViewController alloc] initWithStyle:UITableViewStyleGrouped];

    if ([UIApplication isIPad]) {
        [self.navigationController pushViewController:search animated:YES];
    }
    else {
        PPNavigationController *nav = [[PPNavigationController alloc] initWithRootViewController:search];
        nav.transitioningDelegate = [PPShrinkBackTransition sharedInstance];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

#ifdef PINBOARD

- (void)updateSavedFeeds:(FMDatabase *)db {
    // Check if we have any updates from iCloud
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    [store synchronize];
    NSMutableArray *iCloudFeeds = [NSMutableArray arrayWithArray:[store arrayForKey:kSavedFeedsKey]];
    NSMutableArray *iCloudSearches = [NSMutableArray arrayWithArray:[store arrayForKey:kSavedSearchesKey]];
    
    [db beginTransaction];
    [db executeUpdate:@"DELETE FROM feeds"];
    for (NSString *components in iCloudFeeds) {
        [db executeUpdate:@"INSERT OR IGNORE INTO feeds (components) VALUES (?)" withArgumentsInArray:@[components]];
    }

    [db executeUpdate:@"DELETE FROM searches"];
    for (NSDictionary *search in iCloudSearches) {
        [db executeUpdate:@"INSERT OR IGNORE INTO searches (name, query, private, unread, starred, tagged) VALUES (:name, :query, :private, :unread, :starred, :tagged)" withParameterDictionary:search];
    }
    [db commit];

    NSMutableArray *previousFeedTitles = [NSMutableArray array];
    NSMutableArray *previousSearchNames = [NSMutableArray array];
    NSMutableArray *updatedFeedTitles = [NSMutableArray array];
    NSMutableArray *updatedFeeds = [NSMutableArray array];
    NSMutableArray *updatedSearches = [NSMutableArray array];
    NSMutableArray *updatedSearchNames = [NSMutableArray array];

    for (NSDictionary *feed in self.feeds) {
        [previousFeedTitles addObject:feed[@"title"]];
    }
    
    for (NSDictionary *search in self.searches) {
        [previousSearchNames addObject:search[@"name"]];
    }

    FMResultSet *result = [db executeQuery:@"SELECT components FROM feeds ORDER BY components ASC"];
    while ([result next]) {
        NSString *componentString = [result stringForColumnIndex:0];
        NSArray *components = [componentString componentsSeparatedByString:@" "];
        NSString *title = [components componentsJoinedByString:@"+"];
        
        [iCloudFeeds addObject:componentString];
        [updatedFeedTitles addObject:title];
        [updatedFeeds addObject:@{@"components": components, @"title": title}];
    }
    
    FMResultSet *searchResults = [db executeQuery:@"SELECT * FROM searches ORDER BY created_at ASC"];
    while ([searchResults next]) {
        NSString *name = [searchResults stringForColumn:@"name"];
        NSString *query = [searchResults stringForColumn:@"query"];
        kPushpinFilterType private = [searchResults intForColumn:@"private"];
        kPushpinFilterType unread = [searchResults intForColumn:@"unread"];
        kPushpinFilterType starred = [searchResults intForColumn:@"starred"];
        kPushpinFilterType tagged = [searchResults intForColumn:@"tagged"];
        
        NSDictionary *search = @{@"name": name,
                                 @"query": query,
                                 @"private": @(private),
                                 @"unread": @(unread),
                                 @"starred": @(starred),
                                 @"tagged": @(tagged) };

        [updatedSearchNames addObject:name];
        [updatedSearches addObject:search];
    }

    [result close];
    
    NSInteger offset;
    __block NSInteger section;
    if (self.tableView.editing) {
        // If the table is in editing mode, the first row is "Add feed", so we shift all of the other rows down 1.
        offset = 1;
        
        section = PPPinboardSectionSavedFeeds;
    }
    else {
        offset = 0;
        section = PPPinboardSectionSavedFeeds;
        
        if ([self personalSectionIsHidden]) {
            section--;
        }
        
        if ([self communitySectionIsHidden]) {
            section--;
        }
    }

    self.feeds = [updatedFeeds mutableCopy];
    self.searches = [updatedSearches mutableCopy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (self.tableView.editing) {
            for (NSIndexPath *indexPath in [self indexPathsForVisibleFeeds]) {
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
        }
    });
}

#endif

- (void)updateFeedCounts {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *indexPathsToReload = [NSMutableArray array];
        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
            
#ifdef DELICIOUS
            NSArray *resultSets = @[
                                    [db executeQuery:@"SELECT COUNT(*) FROM bookmark"],
                                    [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private=?" withArgumentsInArray:@[@(YES)]],
                                    [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private=?" withArgumentsInArray:@[@(NO)]],
                                    [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE unread=?" withArgumentsInArray:@[@(YES)]],
                                    [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE tags=?" withArgumentsInArray:@[@""]]
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
            
            NSString *sectionName = PPSections()[0];
            
            NSInteger i = 0;
            NSInteger j = 0;
            for (FMResultSet *resultSet in resultSets) {
                NSString *feedName = PPPersonalFeeds()[i];
                NSString *fullName = [@[sectionName, feedName] componentsJoinedByString:@"-"];

                PPSettings *settings = [PPSettings sharedSettings];
                BOOL feedHiddenByUser = [settings.hiddenFeedNames containsObject:fullName];
                
                [resultSet next];
                NSString *count = [resultSet stringForColumnIndex:0];
                [resultSet close];

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
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.tableView.editing) {
                // There is a table view inconsistency here when:
                // 1. Remove a feed from the personal feed list.
                // 2. Log out.
                // 3. Log back in and do a refresh.
                // 4. View the feed list.
                // Crash.
                [self.tableView reloadData];

#ifdef PINBOARD
                [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
                    [self updateSavedFeeds:db];
                }];
#endif
            }
        });
    });
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionBottom;
}

#pragma mark - PPTitleButtonDelegate

- (void)titleButtonTouchUpInside:(PPTitleButton *)titleButton {
    CGFloat updatedConstant;
    if (self.toolbarBottomConstraint.constant == 0) {
        updatedConstant = 44;
    }
    else {
        updatedConstant = 0;
    }
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.toolbarBottomConstraint.constant = updatedConstant;
                         [self.view layoutIfNeeded];
                     }];
}

@end
