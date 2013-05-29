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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *result = [db executeQuery:@"SELECT components FROM feeds ORDER BY components ASC"];
    [self.feeds removeAllObjects];
    while ([result next]) {
        NSArray *components = [[result stringForColumnIndex:0] componentsSeparatedByString:@"/"];
        [self.feeds addObject:@{@"components": components, @"title": [components componentsJoinedByString:@"+"]}];
    }
    [db close];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.feeds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    CALayer *selectedBackgroundLayer = [CALayer layer];
    selectedBackgroundLayer.frame = CGRectMake(0, 0, 302, 44);
    selectedBackgroundLayer.cornerRadius = 10;
    selectedBackgroundLayer.backgroundColor = HEX(0xDDE1E9FF).CGColor;
    
    if (indexPath.row > 0) {
        CALayer *topBarLayer = [CALayer layer];
        topBarLayer.frame = CGRectMake(0, 0, 302, 10);
        topBarLayer.backgroundColor = HEX(0xDDE1E9FF).CGColor;
        [selectedBackgroundLayer addSublayer:topBarLayer];
    }
    
    if (indexPath.row < self.feeds.count - 1) {
        CALayer *bottomBarLayer = [CALayer layer];
        bottomBarLayer.frame = CGRectMake(0, 34, 302, 10);
        bottomBarLayer.backgroundColor = HEX(0xDDE1E9FF).CGColor;
        [selectedBackgroundLayer addSublayer:bottomBarLayer];
    }
    
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [selectedBackgroundView.layer addSublayer:selectedBackgroundLayer];
    selectedBackgroundView.layer.masksToBounds = YES;

    cell.selectedBackgroundView = selectedBackgroundView;
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.highlightedTextColor = HEX(0x33353Bff);
    cell.textLabel.textColor = HEX(0x33353Bff);
    cell.textLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
    cell.textLabel.text = self.feeds[indexPath.row][@"title"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    GenericPostViewController *postViewController = [PinboardFeedDataSource postViewControllerWithComponents:self.feeds[indexPath.row][@"components"]];
    [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
}

@end
