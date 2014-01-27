//
//  PPDefaultFeedViewController.m
//  Pushpin
//
//  Created by Andy Muldowney on 10/17/13.
//
//

#import "AppDelegate.h"
#import "PPDefaultFeedViewController.h"
#import "PPTitleButton.h"
#import "PPTheme.h"
#import "PPTableViewTitleView.h"
#import "PPConstants.h"

#import <FMDB/FMDatabase.h>

static NSString *CellIdentifier = @"Cell";

@interface PPDefaultFeedViewController ()

@end

@implementation PPDefaultFeedViewController

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Default Feed", nil) imageName:nil];
    self.navigationItem.titleView = titleView;

    self.savedFeeds = [NSMutableArray array];
    
    // Setup the currently selected index path
    self.defaultIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    NSString *feedDetails;
    NSInteger row = 0;
    NSInteger section = 0;
    if ([[AppDelegate sharedDelegate].defaultFeed hasPrefix:@"personal"]) {
        feedDetails = [[AppDelegate sharedDelegate].defaultFeed substringFromIndex:9];
        row = [PPPersonalFeeds() indexOfObject:feedDetails];
        section = 0;
    }
    else if ([[AppDelegate sharedDelegate].defaultFeed hasPrefix:@"community"]) {
        feedDetails = [[AppDelegate sharedDelegate].defaultFeed substringFromIndex:10];
        row = [PPCommunityFeeds() indexOfObject:feedDetails];
        section = 1;
    }
    
    self.defaultIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
#ifdef PINBOARD
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *result = [db executeQuery:@"SELECT components FROM feeds ORDER BY components ASC"];
        [self.savedFeeds removeAllObjects];
        
        // See if we need to update our selected index path
        BOOL updateDefaultIndex = NO;
        NSString *feedDetails;
        if ([[[AppDelegate sharedDelegate].defaultFeed substringToIndex:5] isEqualToString:@"saved"]) {
            feedDetails = [[AppDelegate sharedDelegate].defaultFeed substringFromIndex:6];
            updateDefaultIndex = YES;
        }
        
        NSUInteger currentRow = 0;
        while ([result next]) {
            NSArray *components = [[result stringForColumnIndex:0] componentsSeparatedByString:@" "];
            [self.savedFeeds addObject:@{@"components": components, @"title": [components componentsJoinedByString:@"+"]}];
            if (updateDefaultIndex) {
                if ([[components componentsJoinedByString:@"+"] isEqualToString:feedDetails]) {
                    self.defaultIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:2];
                }
            }
            currentRow++;
        }
        [db close];
        
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
    if (self.savedFeeds.count > 0) {
        return PPProviderPinboardSections + 1;
    }
    
    return PPProviderPinboardSections;
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
            return [self.savedFeeds count];
            
        default:
            return 0;
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

        default:
            return nil;
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
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"All", nil);
                    break;

                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Private Bookmarks", nil);
                    break;

                case 2:
                    cell.textLabel.text = NSLocalizedString(@"Public", nil);
                    break;

                case 3:
                    cell.textLabel.text = NSLocalizedString(@"Unread", nil);
                    break;

                case 4:
                    cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                    break;

                case 5:
                    cell.textLabel.text = NSLocalizedString(@"Starred", nil);
                    break;
            }
            
            break;
        }

        case PPPinboardSectionCommunity: {
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
            
            break;
        }

        case PPPinboardSectionSavedFeeds:
            cell.textLabel.text = self.savedFeeds[indexPath.row][@"title"];
            break;
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
        switch ((PPPinboardSectionType)indexPath.section) {
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
                }
                
            default:
                break;
        }
        if (indexPath.section == 0) {
        }
        else if (indexPath.section == 1) {
        }
        else if (indexPath.section == 2) {
            defaultFeed = [NSString stringWithFormat:@"saved-%@", self.savedFeeds[indexPath.row][@"title"]];
        }
        
        // Update the default feed and pop the view
        [[AppDelegate sharedDelegate] setDefaultFeed:defaultFeed];
    }
    else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
