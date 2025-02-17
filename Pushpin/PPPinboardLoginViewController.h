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
//  PPPinboardLoginViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/18/12.
//
//

@import UIKit;

typedef NS_ENUM(NSInteger, PPLoginCredentialRowType) {
    PPLoginCredentialUsernameRow,
    PPLoginCredentialPasswordRow
};

typedef NS_ENUM(NSInteger, PPLoginSectionType) {
    PPLoginCredentialSection,
    PPLoginAuthTokenSection,
};

static NSInteger PPLoginSectionCount = PPLoginAuthTokenSection + 1;

@interface PPPinboardLoginViewController : UITableViewController <UITextFieldDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic) BOOL keyboard_shown;
@property (nonatomic) CGRect activityIndicatorFrameBottom;
@property (nonatomic) CGRect activityIndicatorFrameMiddle;
@property (nonatomic) CGRect activityIndicatorFrameTop;
@property (nonatomic, strong) NSTimer *loginTimer;
@property (nonatomic, strong) NSTimer *messageUpdateTimer;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) NSDictionary *textViewAttributes;

- (void)login;
- (void)resetLoginScreen;
- (void)updateLoadingMessage;
- (void)showContactForm;

- (void)loginSuccessCallback:(BOOL)authTokenProvided;
- (void)loginFailureCallback:(NSError *)error authTokenProvided:(BOOL)authTokenProvided;
- (void)syncCompletedCallback;
- (void)updateProgressCallback:(NSInteger)current total:(NSInteger)total;

@end
