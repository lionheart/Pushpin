//
//  PPSavedFeedsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

#import "PPSavedFeedsViewController.h"
#import "FMDatabase.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "GenericPostViewController.h"
#import "PinboardFeedDataSource.h"
#import "PPGroupedTableViewCell.h"
#import "PPAddSavedFeedViewController.h"

@interface PPSavedFeedsViewController ()

@end

@implementation PPSavedFeedsViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.feeds = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    self.feeds = [NSMutableArray array];
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
    
}

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
    static NSString *CellIdentifier = @"Cell";
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    CALayer *selectedBackgroundLayer = [PPGroupedTableViewCell baseLayerForSelectedBackground];
    if (indexPath.row > 0) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell topRectangleLayer]];
    }

    if (indexPath.row < self.feeds.count - 1) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell bottomRectangleLayer]];
    }

    [cell setSelectedBackgroundViewWithLayer:selectedBackgroundLayer];
    
    CGFloat fontSize = 17;
    UIFont *font = [UIFont fontWithName:[AppDelegate heavyFontName] size:fontSize];

    NSString *title;
    if (self.feeds.count > 0) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        title = self.feeds[indexPath.row][@"title"];
        while ([title sizeWithFont:font constrainedToSize:CGSizeMake(320, CGFLOAT_MAX)].width > 280 || fontSize < 5) {
            fontSize -= 0.2;
            font = [UIFont fontWithName:[AppDelegate heavyFontName] size:fontSize];
        }
    }
    else {
        title = @"You have no saved feeds.";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    cell.textLabel.font = font;
    cell.textLabel.text = title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.feeds.count > 0) {
        GenericPostViewController *postViewController = [PinboardFeedDataSource postViewControllerWithComponents:self.feeds[indexPath.row][@"components"]];
        [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
    }
}

- (void)addSavedFeedButtonTouchUpInside:(id)sender {
    /*
    PPAddSavedFeedViewController *addSavedFeedViewController = [[PPAddSavedFeedViewController alloc] init];
    addSavedFeedViewController.modalDelegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addSavedFeedViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
    */
    [self performSegueWithIdentifier:@"AddFeed" sender:self];
}

- (void)closeModal:(UIViewController *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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

#pragma mark -
#pragma mark iOS 7 updates
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"AddFeed"]) {
        PPAddSavedFeedViewController *destinationVC = (PPAddSavedFeedViewController *)[segue destinationViewController];
        destinationVC.modalDelegate = self;
    }
}

@end
