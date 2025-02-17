// SPDX-License-Identifier: GPL-3.0-or-later
//
// Pushpin for Pinboard
// Copyright (C) 2025 Lionheart Software LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

//
//  PPSplitViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/8/14.
//
//

@import LHSCategoryCollection;

#import "PPSplitViewController.h"
#import "PPNavigationController.h"
#import "PPAddBookmarkViewController.h"
#import "PPAppDelegate.h"

@interface PPSplitViewController ()

@property (nonatomic, strong) UIKeyCommand *createBookmarkKeyCommand;

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand;

@end

@implementation PPSplitViewController

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.viewControllers[1];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.viewControllers[1];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    static NSArray *keyCommands;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.createBookmarkKeyCommand = [UIKeyCommand keyCommandWithInput:@"c"
                                                            modifierFlags:UIKeyModifierAlternate
                                                                   action:@selector(handleKeyCommand:)];
        keyCommands = @[self.createBookmarkKeyCommand];
    });

    return keyCommands;
}

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand {
    if (keyCommand == self.createBookmarkKeyCommand) {
        PPNavigationController *addBookmarkViewController = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:@{} update:@(NO) callback:^(NSDictionary *response) {
        }];

        if ([UIApplication isIPad]) {
            addBookmarkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        }

        [[PPAppDelegate sharedDelegate].navigationController presentViewController:addBookmarkViewController
                                                                          animated:YES
                                                                        completion:nil];
    }
}

@end

