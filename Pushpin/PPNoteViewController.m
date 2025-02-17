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
//  PPNoteViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 7/5/14.
//
//

@import LHSCategoryCollection;
@import ASPinboard;

#import "PPNoteViewController.h"

@implementation PPNoteViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard noteWithId:self.noteID
                 success:^(NSString *title, NSString *text) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.text = text;

            [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
        });
    }];
}

@end

