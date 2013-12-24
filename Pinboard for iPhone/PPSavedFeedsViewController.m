//
//  PPSavedFeedsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "PPSavedFeedsViewController.h"
#import "AppDelegate.h"
#import "GenericPostViewController.h"
#import "PinboardFeedDataSource.h"
#import "PPGroupedTableViewCell.h"
#import "PPAddSavedFeedViewController.h"
#import "PPTheme.h"
#import "PPNavigationController.h"

#import <FMDB/FMDatabase.h>

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

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *result = [db executeQuery:@"SELECT components FROM feeds ORDER BY components ASC"];
        [self.feeds removeAllObjects];
        while ([result next]) {
            NSArray *components = [[result stringForColumnIndex:0] componentsSeparatedByString:@" "];
            [self.feeds addObject:@{@"components": components, @"title": [components componentsJoinedByString:@"+"]}];
        }
        [db close];
        
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

    UIFont *font = [PPTheme titleFont];

    NSString *title;
    if (self.feeds.count > 0) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        title = self.feeds[indexPath.row][@"title"];
    }
    else {
        title = NSLocalizedString(@"You have no saved feeds.", nil);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.font = font;
    cell.textLabel.text = title;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.feeds.count > 0) {
        GenericPostViewController *postViewController = [PinboardFeedDataSource postViewControllerWithComponents:self.feeds[indexPath.row][@"components"]];
        [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
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
    PinboardFeedDataSource *dataSource = [[PinboardFeedDataSource alloc] initWithComponents:feed[@"components"]];
    [dataSource removeDataSource:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            [self.feeds removeObjectAtIndex:indexPath.row];
            if (self.feeds.count == 0) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            else {
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
    addSavedFeedViewController.modalDelegate = self;
    PPNavigationController *navigationController = [[PPNavigationController alloc] initWithRootViewController:addSavedFeedViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)closeModal:(UIViewController *)sender success:(void (^)())success {
    [self dismissViewControllerAnimated:YES completion:success];
}

- (void)closeModal:(UIViewController *)sender {
    [self closeModal:sender success:nil];
}

@end
