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
//  SettingsViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

@import UIKit;
@import MessageUI;
@import MessageUI.MFMessageComposeViewController;

#import "PPAppDelegate.h"
#import "PPLoadingView.h"
#import "PPTableViewController.h"

typedef NS_ENUM(NSInteger, PPSectionType) {
    PPSectionMainSettings,
    PPSectionOtherSettings,
    PPSectionCacheSettings
};

typedef NS_ENUM(NSInteger, PPMainSettingsRowType) {
    PPMainReader,
    PPMainOffline,
    PPMainBrowser,
    PPMainAdvanced,
};

typedef NS_ENUM(NSInteger, PPOtherSettingsRowType) {
  PPOtherGitHub,
    PPOtherRatePushpin,
    PPOtherTipJar,
    PPOtherFollow,
    PPOtherFeedback,
    PPOtherLogout,
};

enum : NSInteger {
    PPRowCountMain = PPMainAdvanced + 1,
    PPRowCountOther = PPOtherLogout + 1,
    PPRowCountCache = 1,
};

@interface PPSettingsViewController : PPTableViewController <UIWebViewDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UIAlertController *twitterAccountActionSheet;
@property (nonatomic, retain) NSMutableArray *readLaterServices;

- (void)showAboutPage;

@end
