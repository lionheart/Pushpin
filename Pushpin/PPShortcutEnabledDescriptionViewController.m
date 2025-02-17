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
//  PPEditDescriptionViewController_iPad.m
//  Pushpin
//
//  Created by Dan Loewenherz on 7/3/14.
//
//

#import "PPShortcutEnabledDescriptionViewController.h"

@interface PPShortcutEnabledDescriptionViewController ()

@property (nonatomic, strong) UIKeyCommand *goBackKeyCommand;

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand;

@end

@implementation PPShortcutEnabledDescriptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.goBackKeyCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)];
}

#pragma mark - Key Commands

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    return @[self.goBackKeyCommand];
}

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand {
    if (keyCommand == self.goBackKeyCommand) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end

