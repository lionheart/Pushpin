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
//  TagViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/1/12.
//
//

@import UIKit;
@import FMDB;

#import "PPTableViewController.h"

@interface PPTagViewController : PPTableViewController <UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>

@property (nonatomic, retain) NSArray *alphabet;
@property (nonatomic, retain) NSArray *filteredTags;
@property (nonatomic, retain) NSMutableArray *tagList;

@end
