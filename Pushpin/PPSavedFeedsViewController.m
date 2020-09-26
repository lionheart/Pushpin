//
//  PPSavedFeedsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

@import QuartzCore;
@import FMDB;

#import "PPSavedFeedsViewController.h"
#import "PPAppDelegate.h"
#import "PPGenericPostViewController.h"
#import "PPPinboardFeedDataSource.h"
#import "PPAddSavedFeedViewController.h"
#import "PPTheme.h"
#import "PPNavigationController.h"
#import "PPUtilities.h"

static NSString *CellIdentifier = @"Cell";

@interface PPSavedFeedsViewController ()

@end

@implementation PPSavedFeedsViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.feeds = [NSMutableArray array];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController.navigationBar setBarTintColor:HEX(0xd5a470ff)];

    // Check if we have any updates from iCloud
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    [store synchronize];
    NSMutableArray *iCloudFeeds = [NSMutableArray arrayWithArray:[store arrayForKey:kSavedFeedsKey]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PPUtilities databaseQueue] inDatabase:^(FMDatabase *db) {
            [db beginTransaction];

            for (NSString *components in iCloudFeeds) {
                [db executeUpdate:@"INSERT INTO feeds (components) VALUES (?)" withArgumentsInArray:@[components]];
            }

            [db commit];

            [self.feeds removeAllObjects];

            FMResultSet *result = [db executeQuery:@"SELECT components FROM feeds ORDER BY components ASC"];
            while ([result next]) {
                NSString *componentString = [result stringForColumnIndex:0];
                NSArray *components = [componentString componentsSeparatedByString:@" "];

                [iCloudFeeds addObject:componentString];
                [self.feeds addObject:@{@"components": components, @"title": [components componentsJoinedByString:@"+"]}];
            }

            [result close];
        }];

        // Remove duplicates from the array
        NSArray *iCloudFeedsWithoutDuplicates = [[NSSet setWithArray:iCloudFeeds] allObjects];

        // Sync the new saved feed list with iCloud
        [store setArray:iCloudFeedsWithoutDuplicates forKey:kSavedFeedsKey];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });

    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSavedFeedButtonTouchUpInside:)];
    self.navigationItem.rightBarButtonItem = addBarButtonItem;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.feeds.count == 0) {
        return 1;
    }
    return self.feeds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    NSString *title;
    if (self.feeds.count > 0) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        title = self.feeds[indexPath.row][@"title"];
    } else {
        title = NSLocalizedString(@"You have no saved feeds.", nil);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.font = [PPTheme textLabelFont];
    cell.textLabel.text = title;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.feeds.count > 0) {
        PPGenericPostViewController *postViewController = [PPPinboardFeedDataSource postViewControllerWithComponents:self.feeds[indexPath.row][@"components"]];
        [[PPAppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.feeds.count > 0;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *feed = self.feeds[indexPath.row];
    PPPinboardFeedDataSource *dataSource = [[PPPinboardFeedDataSource alloc] initWithComponents:feed[@"components"]];
    [dataSource removeDataSource:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            [self.feeds removeObjectAtIndex:indexPath.row];
            if (self.feeds.count == 0) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

                if (indexPath.row == 0) {
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                }

                if (indexPath.row == self.feeds.count) {
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(self.feeds.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }

            [self.tableView endUpdates];
        });
    }];
}

#pragma mark - Utils

- (void)addSavedFeedButtonTouchUpInside:(id)sender {
    PPAddSavedFeedViewController *addSavedFeedViewController = [[PPAddSavedFeedViewController alloc] init];
    PPNavigationController *navigationController = [[PPNavigationController alloc] initWithRootViewController:addSavedFeedViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

@end

