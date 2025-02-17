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
//  PPAboutViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/31/13.
//
//

@import StoreKit;

#import "PPTableViewController.h"
#import "PPLoadingView.h"

@interface PPAboutViewController : PPTableViewController <UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *heights;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) PPLoadingView *loadingIndicator;
@property (nonatomic) NSDictionary *selectedItem;
@property (nonatomic, strong) UIAlertController *actionSheet;

@end
