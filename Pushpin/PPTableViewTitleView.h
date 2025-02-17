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
//  PPTableViewTitleView.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/2/14.
//
//

@import UIKit;

@interface PPTableViewTitleView : UIView

@property (nonatomic, strong) NSString *text;

- (id)initWithText:(NSString *)text;
- (id)initWithText:(NSString *)text fontSize:(CGFloat)fontSize;

+ (CGFloat)heightWithText:(NSString *)text;
+ (CGFloat)heightWithText:(NSString *)text fontSize:(CGFloat)fontSize;

+ (PPTableViewTitleView *)headerWithText:(NSString *)text fontSize:(CGFloat)fontSize;
+ (PPTableViewTitleView *)headerWithText:(NSString *)text;

@end
