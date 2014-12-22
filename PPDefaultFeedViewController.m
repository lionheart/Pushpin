//
//  PPDefaultFeedViewController.m
//  Pushpin
//
//  Created by Andy Muldowney on 10/17/13.
//
//

#import "PPAppDelegate.h"
#import "PPDefaultFeedViewController.h"
#import "PPTitleButton.h"
#import "PPTheme.h"
#import "PPTableViewTitleView.h"
#import "PPConstants.h"
#import "PPSettings.h"

#import <FMDB/FMDatabase.h>
#import <LHSTableViewCells/LHSTableViewCellSubtitle.h>

static NSString *CellIdentifier = @"Cell";

@interface PPDefaultFeedViewController ()

@property (nonatomic, retain) NSIndexPath *defaultIndexPath;
@property (nonatomic, retain) NSMutableArray *savedFeeds;
@property (nonatomic, retain) NSMutableArray *searches;

@end

@implementation PPDefaultFeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Default Feed", nil) imageName:nil];
    self.navigationItem.titleView = titleView;

    self.savedFeeds = [NSMutableArray array];
    self.searches = [NSMutableArray array];
    
    // Setup the currently selected index path
    self.defaultIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    NSString *feedDetails;
    NSInteger row = 0;
    NSInteger section = 0;
    if ([[PPSettings sharedSettings].defaultFeed hasPrefix:@"personal"]) {
        feedDetails = [[PPSettings sharedSettings].defaultFeed substringFromIndex:9];
        row = [PPPersonalFeeds() indexOfObject:feedDetails];
        section = 0;
    }
    else if ([[PPSettings sharedSettings].defaultFeed hasPrefix:@"community"]) {
        feedDetails = [[PPSettings sharedSettings].defaultFeed substringFromIndex:10];
        row = [PPCommunityFeeds() indexOfObject:feedDetails];
        section = 1;
    }
    
    self.defaultIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
    [self.tableView registerClass:[LHSTableViewCellSubtitle class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
#ifdef PINBOARD
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
            [self.savedFeeds removeAllObjects];
            [self.searches removeAllObjects];

            // See if we need to update our selected index path
            BOOL savedFeedIsDefaultFeed = NO;
            BOOL searchIsDefaultFeed = NO;
            NSString *feedDetails;

            if ([[PPSettings sharedSettings].defaultFeed hasPrefix:@"saved-"]) {
                feedDetails = [[PPSettings sharedSettings].defaultFeed substringFromIndex:6];
                savedFeedIsDefaultFeed = YES;
            }
            else if ([[PPSettings sharedSettings].defaultFeed hasPrefix:@"search-"]) {
                feedDetails = [[PPSettings sharedSettings].defaultFeed substringFromIndex:7];
                searchIsDefaultFeed = YES;
            }
            
            NSInteger section = 2;
            NSUInteger currentRow = 0;
            FMResultSet *result = [db executeQuery:@"SELECT components FROM feeds ORDER BY components ASC"];
            while ([result next]) {
                NSArray *components = [[result stringForColumnIndex:0] componentsSeparatedByString:@" "];
                [self.savedFeeds addObject:@{@"components": components, @"title": [components componentsJoinedByString:@"+"]}];

                if (savedFeedIsDefaultFeed) {
                    if ([[components componentsJoinedByString:@"+"] isEqualToString:feedDetails]) {
                        self.defaultIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:section];
                    }
                }
                currentRow++;
            }
            
            if (self.savedFeeds.count > 0) {
                section++;
            }

            currentRow = 0;
            result = [db executeQuery:@"SELECT * FROM searches ORDER BY created_at ASC"];
            while ([result next]) {
                NSString *name = [result stringForColumn:@"name"];
                NSString *query = [result stringForColumn:@"query"];
                kPushpinFilterType private = [result intForColumn:@"private"];
                kPushpinFilterType unread = [result intForColumn:@"unread"];
                kPushpinFilterType starred = [result intForColumn:@"starred"];
                kPushpinFilterType tagged = [result intForColumn:@"tagged"];

                NSDictionary *search = @{@"name": name,
                                         @"query": query,
                                         @"private": @(private),
                                         @"unread": @(unread),
                                         @"starred": @(starred),
                                         @"tagged": @(tagged) };

                [self.searches addObject:search];

                if (searchIsDefaultFeed) {
                    if ([name isEqualToString:feedDetails]) {
                        self.defaultIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:section];
                    }
                }
                currentRow++;
            }

            [result close];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
#endif
}

#pragma mark - UITableView data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#ifdef DELICIOUS
    return PPProviderDeliciousSections;
#endif
    
#ifdef PINBOARD
    NSInteger sections = PPProviderPinboardSections;
    if (self.savedFeeds.count == 0) {
        sections--;
    }
    
    if (self.searches.count == 0) {
        sections--;
    }

    return sections;
#endif
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#ifdef DELICIOUS
    switch ((PPDeliciousSectionType)section) {
        case PPDeliciousSectionPersonal:
            return PPDeliciousPersonalRows;
            
        default:
            return 0;
    }
#endif
    
#ifdef PINBOARD
    switch ((PPPinboardSectionType)section) {
        case PPPinboardSectionPersonal:
            return PPPinboardPersonalRows;
            
        case PPPinboardSectionCommunity:
            return PPPinboardCommunityRows;
            
        case PPPinboardSectionSavedFeeds:
            return self.savedFeeds.count;
            
        case PPPinboardSectionSearches:
            return self.searches.count;
    }
#endif
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
#ifdef DELICIOUS
    switch ((PPDeliciousSectionType)section) {
        case PPDeliciousSectionPersonal:
            return [PPTableViewTitleView heightWithText:NSLocalizedString(@"Personal", nil)] + 10;
            
        default:
            return 0;
    }
#endif

#ifdef PINBOARD
    switch ((PPPinboardSectionType)section) {
        case PPPinboardSectionPersonal:
            return [PPTableViewTitleView heightWithText:NSLocalizedString(@"Personal", nil)] + 10;

        case PPPinboardSectionCommunity:
            return [PPTableViewTitleView heightWithText:NSLocalizedString(@"Community", nil)];

        case PPPinboardSectionSavedFeeds:
            return [PPTableViewTitleView heightWithText:NSLocalizedString(@"Saved Feeds", nil)];

        case PPPinboardSectionSearches:
            return [PPTableViewTitleView heightWithText:NSLocalizedString(@"Searches", nil)];
    }
    return 0;
#endif
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
#ifdef DELICIOUS
    switch ((PPDeliciousSectionType)section) {
        case PPDeliciousSectionPersonal:
            return NSLocalizedString(@"Personal", nil);
            
        default:
            return nil;
    }
#endif
    
#ifdef PINBOARD
    switch ((PPPinboardSectionType)section) {
        case PPPinboardSectionPersonal:
            return NSLocalizedString(@"Personal", nil);
            
        case PPPinboardSectionCommunity:
            return NSLocalizedString(@"Community", nil);
            
        case PPPinboardSectionSavedFeeds:
            return NSLocalizedString(@"Saved Feeds", nil);

        case PPPinboardSectionSearches:
            return NSLocalizedString(@"Searches", nil);
    }
#endif
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textLabel.font = [PPTheme textLabelFont];
    
#ifdef DELICIOUS
    switch ((PPDeliciousSectionType)indexPath.section) {
        case PPDeliciousSectionPersonal: {
            switch ((PPDeliciousPersonalFeedType)indexPath.row) {
                case PPDeliciousPersonalFeedAll:
                    cell.textLabel.text = NSLocalizedString(@"All", nil);
                    break;

                case PPDeliciousPersonalFeedPrivate:
                    cell.textLabel.text = NSLocalizedString(@"Private Bookmarks", nil);
                    break;

                case PPDeliciousPersonalFeedPublic:
                    cell.textLabel.text = NSLocalizedString(@"Public", nil);
                    break;

                case PPDeliciousPersonalFeedUnread:
                    cell.textLabel.text = NSLocalizedString(@"Unread", nil);
                    break;

                case PPDeliciousPersonalFeedUntagged:
                    cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                    break;
            }
            
            break;
        }
    }
#endif

#ifdef PINBOARD
    switch ((PPPinboardSectionType)indexPath.section) {
        case PPPinboardSectionPersonal: {
            switch ((PPPinboardPersonalFeedType)indexPath.row) {
                case PPPinboardPersonalFeedAll:
                    cell.textLabel.text = NSLocalizedString(@"All", nil);
                    break;

                case PPPinboardPersonalFeedPrivate:
                    cell.textLabel.text = NSLocalizedString(@"Private Bookmarks", nil);
                    break;

                case PPPinboardPersonalFeedPublic:
                    cell.textLabel.text = NSLocalizedString(@"Public", nil);
                    break;

                case PPPinboardPersonalFeedUnread:
                    cell.textLabel.text = NSLocalizedString(@"Unread", nil);
                    break;

                case PPPinboardPersonalFeedUntagged:
                    cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                    break;

                case PPPinboardPersonalFeedStarred:
                    cell.textLabel.text = NSLocalizedString(@"Starred", nil);
                    break;
            }
            
            break;
        }

        case PPPinboardSectionCommunity: {
            switch ((PPPinboardCommunityFeedType)indexPath.row) {
                case PPPinboardCommunityFeedNetwork:
                    cell.textLabel.text = NSLocalizedString(@"Network", nil);
                    break;

                case PPPinboardCommunityFeedPopular:
                    cell.textLabel.text = NSLocalizedString(@"Popular", nil);
                    break;

                case PPPinboardCommunityFeedWikipedia:
                    cell.textLabel.text = @"Wikipedia";
                    break;

                case PPPinboardCommunityFeedFandom:
                    cell.textLabel.text = NSLocalizedString(@"Fandom", nil);
                    break;

                case PPPinboardCommunityFeedJapan:
                    cell.textLabel.text = @"日本語";
                    break;
                    
                case PPPinboardCommunityFeedRecent:
                    cell.textLabel.text = NSLocalizedString(@"Recent", nil);
                    break;
            }
            
            break;
        }

        case PPPinboardSectionSavedFeeds:
            cell.textLabel.text = self.savedFeeds[indexPath.row][@"title"];
            break;

        case PPPinboardSectionSearches: {
            NSDictionary *search = self.searches[indexPath.row];
            cell.textLabel.text = search[@"name"];

            NSString *query = search[@"query"];
            NSMutableArray *components = [NSMutableArray array];
            if (query && ![query isEqualToString:@""]) {
                [components addObject:[NSString stringWithFormat:@"query: %@", query]];
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
    
    if ([indexPath isEqual:self.defaultIndexPath]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL selectedChanged = ![self.defaultIndexPath isEqual:indexPath];
    if (selectedChanged) {
        NSIndexPath *previousDefaultIndexPath = self.defaultIndexPath;
        self.defaultIndexPath = indexPath;

        [CATransaction begin];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [CATransaction setCompletionBlock:^{
            [tableView beginUpdates];
            [tableView reloadRowsAtIndexPaths:@[indexPath, previousDefaultIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView endUpdates];
        }];
        [CATransaction commit];
        
        // Build our new default view string
        NSString *defaultFeed = @"personal-all";

#ifdef DELICIOUS
        PPDeliciousSectionType sectionType = (PPDeliciousSectionType)indexPath.section;
        
        switch (sectionType) {
            case PPDeliciousSectionPersonal:
                switch ((PPDeliciousPersonalFeedType)indexPath.row) {
                    case PPDeliciousPersonalFeedAll:
                        defaultFeed = @"personal-all";
                        break;
                        
                    case PPDeliciousPersonalFeedPrivate:
                        defaultFeed = @"personal-private";
                        break;
                        
                    case PPDeliciousPersonalFeedPublic:
                        defaultFeed = @"personal-public";
                        break;
                        
                    case PPDeliciousPersonalFeedUnread:
                        defaultFeed = @"personal-unread";
                        break;
                        
                    case PPDeliciousPersonalFeedUntagged:
                        defaultFeed = @"personal-untagged";
                        break;
                }
                break;
        }
#endif
        
#ifdef PINBOARD
        PPPinboardSectionType sectionType = (PPPinboardSectionType)indexPath.section;

        switch (sectionType) {
            case PPPinboardSectionPersonal:
                switch ((PPPinboardPersonalFeedType)indexPath.row) {
                    case PPPinboardPersonalFeedAll:
                        defaultFeed = @"personal-all";
                        break;

                    case PPPinboardPersonalFeedPrivate:
                        defaultFeed = @"personal-private";
                        break;

                    case PPPinboardPersonalFeedPublic:
                        defaultFeed = @"personal-public";
                        break;

                    case PPPinboardPersonalFeedUnread:
                        defaultFeed = @"personal-unread";
                        break;

                    case PPPinboardPersonalFeedUntagged:
                        defaultFeed = @"personal-untagged";
                        break;

                    case PPPinboardPersonalFeedStarred:
                        defaultFeed = @"personal-starred";
                        break;
                }
                break;
                
            case PPPinboardSectionCommunity:
                switch ((PPPinboardCommunityFeedType)indexPath.row) {
                    case PPPinboardCommunityFeedNetwork:
                        defaultFeed = @"community-network";
                        break;

                    case PPPinboardCommunityFeedPopular:
                        defaultFeed = @"community-popular";
                        break;

                    case PPPinboardCommunityFeedWikipedia:
                        defaultFeed = @"community-wikipedia";
                        break;

                    case PPPinboardCommunityFeedFandom:
                        defaultFeed = @"community-fandom";
                        break;

                    case PPPinboardCommunityFeedJapan:
                        defaultFeed = @"community-japanese";
                        break;
                        
                    case PPPinboardCommunityFeedRecent:
                        defaultFeed = @"community-recent";
                        break;
                }
                break;

            case PPPinboardSectionSavedFeeds:
                defaultFeed = [NSString stringWithFormat:@"saved-%@", self.savedFeeds[indexPath.row][@"title"]];
                break;

            case PPPinboardSectionSearches:
                defaultFeed = [NSString stringWithFormat:@"search-%@", self.searches[indexPath.row][@"name"]];
                break;
                
            default:
                break;
        }
#endif
        
        // Update the default feed and pop the view
        [[PPSettings sharedSettings] setDefaultFeed:defaultFeed];
    }
    else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
