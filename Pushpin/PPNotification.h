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
//  PPNotification.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/20/13.
//
//

@import Foundation;

@interface PPNotification : NSObject

@property (nonatomic) BOOL hiding;
@property (nonatomic) BOOL visible;
@property (nonatomic, strong) UIView *notificationView;

+ (PPNotification *)sharedInstance;
+ (void)notifyWithMessage:(NSString *)message;
+ (void)notifyWithMessage:(NSString *)message success:(BOOL)success updated:(BOOL)updated;
+ (void)notifyWithMessage:(NSString *)message success:(BOOL)success updated:(BOOL)updated delay:(CGFloat)seconds;
+ (void)notifyWithMessage:(NSString *)message userInfo:(id)userInfo;
+ (void)notifyWithMessage:(NSString *)message userInfo:(id)userInfo delay:(CGFloat)seconds;

- (void)showInView:(UIView *)view withMessage:(NSString *)message;
- (UIView *)notificationViewWithMessage:(NSString *)message;
- (void)hide;
- (void)hide:(BOOL)animated;
- (void)didRotate:(NSNotification *)notification;

@end
