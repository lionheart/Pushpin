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
//  PPTagEditViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/30/13.
//
//

@import UIKit;
@import LHSKeyboardAdjusting;

@class PPTagEditViewController;

@protocol PPBadgeWrapperDelegate;

@protocol PPTagEditing <NSObject>

- (void)tagEditViewControllerDidUpdateTags:(PPTagEditViewController *)tagEditViewController;

@end

@interface PPTagEditViewController : UIViewController <PPBadgeWrapperDelegate,  UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, LHSKeyboardAdjusting>

@property (nonatomic, strong) NSLayoutConstraint *keyboardAdjustingBottomConstraint;

@property (nonatomic) BOOL autocompleteInProgress;
@property (nonatomic) BOOL loadingTags;
@property (nonatomic) BOOL presentedFromShareSheet;

@property (nonatomic, strong) NSDictionary *bookmarkData;
@property (nonatomic, strong) NSMutableArray *existingTags;
@property (nonatomic, strong) NSMutableArray *popularTags;
@property (nonatomic, strong) NSMutableArray *previousTagSuggestions;
@property (nonatomic, strong) NSMutableArray *recommendedTags;
@property (nonatomic, strong) NSMutableArray *tagCompletions;
@property (nonatomic, strong) NSMutableArray *unfilteredPopularTags;
@property (nonatomic, strong) NSMutableArray *unfilteredRecommendedTags;
@property (nonatomic, strong) NSMutableDictionary *deleteTagButtons;
@property (nonatomic, strong) NSMutableDictionary *tagCounts;
@property (nonatomic, strong) NSMutableDictionary *tagDescriptions;
@property (nonatomic, strong) NSString *currentlySelectedTag;
@property (nonatomic, strong) UIAlertController *removeTagActionSheet;
@property (nonatomic, strong) UITextField *tagTextField;
@property (nonatomic, weak) id<PPTagEditing> tagDelegate;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *allTags;

- (NSInteger)maxTagsToAutocomplete;
- (NSInteger)minTagsToAutocomplete;

@end
