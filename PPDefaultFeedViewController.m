//
//  PPDefaultFeedViewController.m
//  Pushpin
//
//  Created by Andy Muldowney on 10/17/13.
//
//

#import "AppDelegate.h"
#import "PPDefaultFeedViewController.h"
#import "PPGroupedTableViewCell.h"

#import <FMDB/FMDatabase.h>

@interface PPDefaultFeedViewController ()

@end

@implementation PPDefaultFeedViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"Default Feed", nil);
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.savedFeeds = [NSMutableArray array];
    
    // Setup the currently selected index path
    self.defaultIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    NSString *feedDetails;
    if ([[[AppDelegate sharedDelegate].defaultFeed substringToIndex:8] isEqualToString:@"personal"]) {
        feedDetails = [[AppDelegate sharedDelegate].defaultFeed substringFromIndex:9];
        if ([feedDetails isEqualToString:@"all"]) {
            self.defaultIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        } else if ([feedDetails isEqualToString:@"private"]) {
            self.defaultIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
        } else if ([feedDetails isEqualToString:@"public"]) {
            self.defaultIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
        } else if ([feedDetails isEqualToString:@"unread"]) {
            self.defaultIndexPath = [NSIndexPath indexPathForRow:3 inSection:0];
        } else if ([feedDetails isEqualToString:@"untagged"]) {
            self.defaultIndexPath = [NSIndexPath indexPathForRow:4 inSection:0];
        } else if ([feedDetails isEqualToString:@"starred"]) {
            self.defaultIndexPath = [NSIndexPath indexPathForRow:5 inSection:0];
        }
    } else if ([[[AppDelegate sharedDelegate].defaultFeed substringToIndex:9] isEqualToString:@"community"]) {
        feedDetails = [[AppDelegate sharedDelegate].defaultFeed substringFromIndex:10];
        
        if ([feedDetails isEqualToString:@"network"]) {
            self.defaultIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
        } else if ([feedDetails isEqualToString:@"popular"]) {
            self.defaultIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
        } else if ([feedDetails isEqualToString:@"wikipedia"]) {
            self.defaultIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
        } else if ([feedDetails isEqualToString:@"fandom"]) {
            self.defaultIndexPath = [NSIndexPath indexPathForRow:3 inSection:1];
        } else if ([feedDetails isEqualToString:@"japanese"]) {
            self.defaultIndexPath = [NSIndexPath indexPathForRow:4 inSection:1];
        }
    }
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"Personal", nil);
            break;
        case 1:
            return NSLocalizedString(@"Community", nil);
            break;
        case 2:
            return NSLocalizedString(@"Saved Feeds", nil);
            break;
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView cellForRowAtIndexPath:self.defaultIndexPath].accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;

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
    
    self.defaultIndexPath = indexPath;
}

@end
