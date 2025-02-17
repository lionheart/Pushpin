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
//  BookmarkletInstallationViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 1/21/13.
//
//

@import QuartzCore;
@import LHSCategoryCollection;

#import "PPAppDelegate.h"
#import "BookmarkletInstallationViewController.h"
#import "PPTheme.h"
#import "PPTableViewTitleView.h"
#import "PPNotification.h"

static NSString *CellIdentifier = @"Cell";

@interface BookmarkletInstallationViewController ()

@end

@implementation BookmarkletInstallationViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Browser Integration", nil);
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return 2;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return NSLocalizedString(@"Watch a video", nil);
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    cell.textLabel.font = [PPTheme textLabelFont];
    if (indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"Copy bookmarklet to clipboard", nil);
    } else {
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"How to install on Safari", nil);
        } else {
            cell.textLabel.text = NSLocalizedString(@"How to install on Chrome for iOS", nil);
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        [[UIPasteboard generalPasteboard] setString:@"javascript:window.location='pushpin://x-callback-url/add?url='+encodeURIComponent(location.href)+'&title='+encodeURIComponent(document.title)"];

        [PPNotification notifyWithMessage:NSLocalizedString(@"Bookmarklet copied to clipboard.", nil)
                                  success:YES
                                  updated:NO];
    } else {
        if (indexPath.row == 0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=svFHucdSjPI"] options:@{} completionHandler:nil];;
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=y9hjzceX_FE"] options:@{} completionHandler:nil];;
        }
    }
}

@end

