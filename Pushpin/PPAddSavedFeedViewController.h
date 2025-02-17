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
//  PPAddSavedFeedViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/30/13.
//
//

#import "PPTableViewController.h"
#import "PPAppDelegate.h"

@interface PPAddSavedFeedViewController : PPTableViewController <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *userTextField;
@property (nonatomic, strong) UITextField *tagsTextField;
@property (nonatomic, copy) void (^SuccessCallback)(void);

- (void)addButtonTouchUpInside:(id)sender;
- (void)closeButtonTouchUpInside:(id)sender;

@end
