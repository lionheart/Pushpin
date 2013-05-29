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
    UIFont *font = [UIFont fontWithName:@"Avenir-Heavy" size:fontSize];

    NSString *title;
    if (self.feeds.count > 0) {
        title = self.feeds[indexPath.row][@"title"];
        while ([title sizeWithFont:font constrainedToSize:CGSizeMake(320, CGFLOAT_MAX)].width > 280 || fontSize < 5) {
            fontSize -= 0.2;
            font = [UIFont fontWithName:@"Avenir-Heavy" size:fontSize];
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

@end
