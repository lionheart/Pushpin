/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Pushpin for Pinboard
 * Copyright (C) 2025 Lionheart Software LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

//
//  FeedListViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/4/13.
//
//

@import UIKit;

#import "PPTableViewController.h"
#import "PPGenericPostViewController.h"
#import "PPConstants.h"
#import "PPPinboardDataSource.h"
#import "PPPinboardFeedDataSource.h"

typedef NS_ENUM(NSInteger, FeedListToolbarOrientationType) {
    FeedListToolbarOrientationRight,
    FeedListToolbarOrientationLeft,
    FeedListToolbarOrientationCenter,
};

@interface PPFeedListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIToolbarDelegate, PPTitleButtonDelegate> {
    NSString *postViewTitle;
}

@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSObject <PPDataSource> *postDataSource;
@property (nonatomic, strong) UIBarButtonItem *notesBarButtonItem;
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSMutableArray *bookmarkCounts;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic) CGFloat textSize;
@property (nonatomic) CGFloat detailTextSize;
@property (nonatomic) CGFloat rowHeight;

- (void)dismissViewController;
- (void)preferredContentSizeChanged:(NSNotification *)aNotification;

@end
