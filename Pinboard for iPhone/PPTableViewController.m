//
//  PPTableViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/19/13.
//
//

#import "PPTableViewController.h"
#import "UIApplication+Additions.h"

@interface PPTableViewController ()

@end

@implementation PPTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.tableView.backgroundView = [[UIImageView alloc] initWithFrame:(CGRect){{0, 0}, [UIApplication currentSize]}];
        self.tableView.backgroundColor = HEX(0xF7F9FDff);
        self.tableView.opaque = NO;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"X" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSArray *visibleIndexPaths = self.tableView.indexPathsForVisibleRows;
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortrait;
}

@end
