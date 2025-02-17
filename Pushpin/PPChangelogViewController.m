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
//  PPChangelogViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/5/13.
//
//

@import QuartzCore;
@import LHSTableViewCells;
@import LHSCategoryCollection;

#import "PPChangelogViewController.h"
#import "PPAppDelegate.h"
#import "PPTheme.h"

#import "UITableView+Additions.h"

static NSString *CellIdentifier = @"Cell";

@interface PPChangelogViewController ()

@property (nonatomic, strong) NSMutableArray *heights;
@property (nonatomic, strong) NSDictionary *detailAttributes;

@end

@implementation PPChangelogViewController

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.heights = [NSMutableArray array];

    NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"Changelog" ofType:@"plist"];

    self.data = [NSArray arrayWithContentsOfFile:plistPath];
    self.title = NSLocalizedString(@"Changelog", nil);
    self.titles = [NSMutableArray array];

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    self.detailAttributes = @{NSFontAttributeName: [PPTheme detailLabelFont],
                              NSParagraphStyleAttributeName: paragraphStyle };

    if ([UIApplication isIPad]) {
        [self calculateHeightsForWidth:290];
    } else {
        [self calculateHeightsForWidth:CGRectGetWidth(self.view.frame) - 30];
    }

    [self.tableView registerClass:[LHSTableViewCellSubtitle class] forCellReuseIdentifier:CellIdentifier];
}

- (void)calculateHeightsForWidth:(CGFloat)w {
    [self.titles removeAllObjects];

    UILabel *fakeLabel = [[UILabel alloc] init];
    fakeLabel.preferredMaxLayoutWidth = w;

    [self.data enumerateObjectsUsingBlock:^(NSArray *list, NSUInteger section, BOOL *stop) {
        [self.titles addObject:list[0]];
        self.heights[section] = [NSMutableArray array];

        [list[1] enumerateObjectsUsingBlock:^(NSArray *pair, NSUInteger row, BOOL *stop) {
            NSString *description = pair[1];
            CGFloat height = 0;

            fakeLabel.attributedText = [[NSAttributedString alloc] initWithString:description attributes:self.detailAttributes];

            if (![description isEqualToString:@""]) {
                height += CGRectGetHeight([fakeLabel textRectForBounds:CGRectMake(0, 0, w, CGFLOAT_MAX) limitedToNumberOfLines:0]);
            }

            self.heights[section][row] = @(height);
        }];
    }];

    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.heights.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.heights[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.titles[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.heights[indexPath.section][indexPath.row] floatValue] + 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    cell.accessoryView = nil;
    cell.textLabel.text = nil;
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.text = nil;
    cell.imageView.image = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NSArray *info = self.data[indexPath.section][1];
    NSString *description = info[indexPath.row][1];
    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:description attributes:self.detailAttributes];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

