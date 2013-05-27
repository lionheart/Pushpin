//
//  PPTableViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/19/13.
//
//

#import "PPTableViewController.h"

@interface PPTableViewController ()

@end

@implementation PPTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.tableView.backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        self.tableView.backgroundColor = HEX(0xF7F9FDff);
        self.tableView.opaque = NO;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"X" style:UIBarButtonItemStylePlain target:nil action:nil];
}

@end
