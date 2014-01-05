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
        row = [@[@"all", @"private", @"public", @"unread", @"untagged", @"starred"] indexOfObject:feedDetails];
        section = 0;
    }
    else if ([[AppDelegate sharedDelegate].defaultFeed hasPrefix:@"community"]) {
        feedDetails = [[AppDelegate sharedDelegate].defaultFeed substringFromIndex:10];
        row = [@[@"network", @"popular", @"wikipedia", @"fandom", @"japanese"] indexOfObject:feedDetails];
        section = 1;
    }
    
    self.defaultIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
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
}

#pragma mark - UITableView data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.savedFeeds.count > 0) {
        return 3;
    }
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 6;
            break;
        case 1:
            return 5;
            break;
        case 2:
            return [self.savedFeeds count];
            break;
        default:
            return 0;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [PPTableViewTitleView heightWithText:NSLocalizedString(@"Personal", nil)];

        case 1:
            return [PPTableViewTitleView heightWithText:NSLocalizedString(@"Community", nil)];

        case 2:
            return [PPTableViewTitleView heightWithText:NSLocalizedString(@"Saved Feeds", nil)];

    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [PPTableViewTitleView headerWithText:NSLocalizedString(@"Personal", nil)];
            
        case 1:
            return [PPTableViewTitleView headerWithText:NSLocalizedString(@"Community", nil)];
            
        case 2:
            return [PPTableViewTitleView headerWithText:NSLocalizedString(@"Saved Feeds", nil)];
            
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textLabel.font = [PPTheme cellTextLabelFont];

    switch (indexPath.section) {
        case 0: {
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
            
            break;
        }
        case 2: {

            cell.textLabel.text = self.savedFeeds[indexPath.row][@"title"];
            
            break;
        }
    }
    
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
        if (indexPath.section == 0) {
            switch (indexPath.row) {
                case 0:
                    defaultFeed = @"personal-all";
                    break;
                case 1:
                    defaultFeed = @"personal-private";
                    break;
                case 2:
                    defaultFeed = @"personal-public";
                    break;
                case 3:
                    defaultFeed = @"personal-unread";
                    break;
                case 4:
                    defaultFeed = @"personal-untagged";
                    break;
                case 5:
                    defaultFeed = @"personal-starred";
                    break;
            }
        }
        else if (indexPath.section == 1) {
            switch (indexPath.row) {
                case 0:
                    defaultFeed = @"community-network";
                    break;
                case 1:
                    defaultFeed = @"community-popular";
                    break;
                case 2:
                    defaultFeed = @"community-wikipedia";
                    break;
                case 3:
                    defaultFeed = @"community-fandom";
                    break;
                case 4:
                    defaultFeed = @"community-japanese";
                    break;
            }
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
