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
//  PPMultipleEditViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/9/13.
//
//

#import "PPTagEditViewController.h"

typedef NS_ENUM(NSInteger, PPMultipleEditSectionType) {
    PPMultipleEditSectionAddedTags,
    PPMultipleEditSectionExistingTags,
    PPMultipleEditSectionOtherData
};

typedef NS_ENUM(NSInteger, PPMultipleEditSectionOtherRowType) {
    PPMultipleEditSectionOtherRowPrivate,
    PPMultipleEditSectionOtherRowRead
};

enum : NSInteger {
    PPMultipleEditSectionCount = PPMultipleEditSectionOtherData + 1,
};

@interface PPMultipleEditViewController : UIViewController <UITextFieldDelegate, PPTagEditing, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITextField *tagsToAddTextField;

@property (nonatomic, strong) NSArray *bookmarks;
@property (nonatomic, strong) NSMutableArray *existingTags;
@property (nonatomic, strong) NSMutableOrderedSet *tagsToRemove;
@property (nonatomic, strong) NSMutableArray *tagsToAdd;

- (id)initWithBookmarks:(NSArray *)bookmarks;

@end
