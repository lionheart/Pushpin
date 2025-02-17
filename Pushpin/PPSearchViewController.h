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
//  PPSearchViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 2/16/14.
//
//

@import LHSKeyboardAdjusting;

#import "PPTableViewController.h"

typedef NS_ENUM(NSInteger, PPSearchScopeType) {
    PPSearchScopeMine,
    PPSearchScopePinboard,
    PPSearchScopeNetwork,
    PPSearchScopeEveryone,
};

typedef NS_ENUM(NSInteger, PPSearchFilterRowType) {
    PPSearchFilterPrivate,
    PPSearchFilterUnread,
    PPSearchFilterStarred,
    PPSearchFilterUntagged
};

typedef NS_ENUM(NSInteger, PPSearchSectionType) {
    PPSearchSectionQuery,
    PPSearchSectionScope,
    PPSearchSectionFilters,
    PPSearchSectionSave
};

static NSArray *PPSearchScopes() {
    return @[@"Pushpin", @"Pinboard Servers"];
}


typedef NS_ENUM(NSInteger, PPSearchQueryRowType) {
    PPSearchQueryRow
};

typedef NS_ENUM(NSInteger, PPSearchScopeRowType) {
    PPSearchScopeRow
};

typedef NS_ENUM(NSInteger, PPSearchRowCounts) {
    PPSearchQueryRowCount = PPSearchQueryRow + 1,
    PPSearchScopeRowCount = PPSearchScopeRow + 1,
    PPSearchFilterRowCount = PPSearchFilterUntagged + 1
};

@interface PPSearchViewController : PPTableViewController <UITextFieldDelegate,  LHSKeyboardAdjusting>

@end
