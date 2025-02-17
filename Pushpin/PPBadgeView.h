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
//  PPBadgeView.h
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

@import UIKit;

@class PPBadgeView;

@protocol PPBadgeDelegate <NSObject>

- (void)didSelectBadgeView:(PPBadgeView *)badgeView;
- (void)didTapAndHoldBadgeView:(PPBadgeView *)badgeView;

@end

@interface PPBadgeView : UIView

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

@property (nonatomic, weak) id<PPBadgeDelegate> delegate;
@property (nonatomic, strong) UIView *badgeView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIColor *normalColor;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, strong) UIColor *disabledColor;

@property (nonatomic, strong) NSString *text;

@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL selected;

- (id)initWithImage:(UIImage *)image;
- (id)initWithImage:(UIImage *)image options:(NSDictionary *)options;
- (id)initWithText:(NSString *)text;
- (id)initWithText:(NSString *)text options:(NSDictionary *)options;

- (void)updateBackgroundColor;
- (void)gestureDetected:(UIGestureRecognizer *)recognizer;

@end
