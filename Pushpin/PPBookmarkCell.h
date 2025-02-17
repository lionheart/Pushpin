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
//  PPBookmarkCell.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/26/13.
//
//

@import UIKit;

@protocol PPDataSource;
@protocol PPBadgeWrapperDelegate;

@class PPBookmarkCell;
@class TTTAttributedLabel;

@protocol PPBookmarkCellDelegate <NSObject>

- (CGFloat)bookmarkCellMaxHorizontalOffset;
- (void)bookmarkCellDidScroll:(CGPoint)offset;
- (void)bookmarkCellDidActivateDeleteButton:(PPBookmarkCell *)cell
                                    forPost:(NSDictionary *)post;
- (void)bookmarkCellDidActivateEditButton:(PPBookmarkCell *)cell
                                  forPost:(NSDictionary *)post;
- (BOOL)bookmarkCellCanSwipe:(PPBookmarkCell *)cell;

@end

@interface PPBookmarkCell : UITableViewCell <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, assign) id<PPBookmarkCellDelegate> delegate;

- (void)prepareCellWithDataSource:(id<PPDataSource>)dataSource
                    badgeDelegate:(id<PPBadgeWrapperDelegate>)badgeDelegate
                             post:(NSDictionary *)post
                       compressed:(BOOL)compressed;

@end
