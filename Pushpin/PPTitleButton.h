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
//  PPTitleButton.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/20/13.
//
//

@import UIKit;

@class PPTitleButton;

@protocol PPTitleButtonDelegate <NSObject>

@required

- (void)titleButtonTouchUpInside:(PPTitleButton *)titleButton;
- (void)titleButtonLongPress:(PPTitleButton *)titleButton;

@end

@interface PPTitleButton : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, weak) id<PPTitleButtonDelegate> delegate;

+ (instancetype)button;
+ (instancetype)buttonWithDelegate:(id<PPTitleButtonDelegate>)delegate;
- (void)setTitle:(NSString *)title imageName:(NSString *)imageName;
- (void)setImageNames:(NSArray *)imageNames;
- (void)setImageNames:(NSArray *)imageNames title:(NSString *)title;

@end
