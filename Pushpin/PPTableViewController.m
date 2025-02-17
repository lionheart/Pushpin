// SPDX-License-Identifier: GPL-3.0-or-later
//
// Pushpin for Pinboard
// Copyright (C) 2025 Lionheart Software LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

//
//  PPTableViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/19/13.
//
//

@import LHSCategoryCollection;

#import "PPTableViewController.h"

@interface PPTableViewController ()

@property (nonatomic) UITableViewStyle style;
@property (nonatomic, strong) NSLayoutConstraint *keyboardAdjustingBottomConstraint;

@end

@implementation PPTableViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)init {
    return [self initWithStyle:UITableViewStyleGrouped];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super init];
    if (self) {
        self.style = style;

        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:self.style];
        self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
        self.tableView.backgroundColor = HEX(0xF7F9FDff);
        self.tableView.opaque = NO;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;

        if (@available(iOS 11, *)) {
            self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.tableView];
    self.edgesForExtendedLayout = UIRectEdgeNone;

    NSDictionary *views = @{@"table": self.tableView};
    [self.tableView lhs_fillWidthOfSuperview];
    [self.view lhs_addConstraints:@"V:|[table]|" views:views];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortrait;
}

@end

