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
//  PPBadgeWrapperView.h
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

@import UIKit;

#import "PPBadgeView.h"

@class PPBadgeWrapperView;

@protocol PPBadgeWrapperDelegate <NSObject>

@optional

- (void)badgeWrapperView:(PPBadgeWrapperView *)badgeWrapperView didSelectBadge:(PPBadgeView *)badge;
- (void)badgeWrapperView:(PPBadgeWrapperView *)badgeWrapperView didTapAndHoldBadge:(PPBadgeView *)badge;

@end

@interface PPBadgeWrapperView : UIView <PPBadgeDelegate>

@property (nonatomic, weak) id<PPBadgeWrapperDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *badges;
@property (nonatomic, strong) PPBadgeView *ellipsisView;
@property (nonatomic, strong) NSDictionary *badgeOptions;
@property (nonatomic) BOOL compressed;
@property (nonatomic) BOOL isInvalidated;

- (id)initWithBadges:(NSArray *)badges;
- (id)initWithBadges:(NSArray *)badges options:(NSDictionary *)options;
- (id)initWithBadges:(NSArray *)badges options:(NSDictionary *)options compressed:(BOOL)compressed;
- (CGFloat)calculateHeight;
- (CGFloat)calculateHeightForWidth:(CGFloat)width;

@end
