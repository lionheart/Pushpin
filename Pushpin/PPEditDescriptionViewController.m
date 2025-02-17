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
//  PPEditDescriptionViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/30/13.
//
//

@import LHSCategoryCollection;

#import "PPEditDescriptionViewController.h"
#import "PPTheme.h"
#import "PPSettings.h"

@interface PPEditDescriptionViewController ()

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;

@end

@implementation PPEditDescriptionViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)initWithDescription:(NSString *)description {
    self = [super init];
    if (self) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.title = NSLocalizedString(@"Description", nil);

        UIFont *font = [UIFont systemFontOfSize:16];

        PPSettings *settings = [PPSettings sharedSettings];

        self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
        self.textView.translatesAutoresizingMaskIntoConstraints = NO;
        self.textView.autocorrectionType = [settings autoCorrectionType];
        self.textView.autocapitalizationType =  [settings autoCapitalizationType];
        self.textView.spellCheckingType = UITextSpellCheckingTypeDefault;
        self.textView.font = font;
        self.textView.text = description;
        self.textView.delegate = self;

        [self.view addSubview:self.textView];

        self.bottomConstraint = [self.textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor];
        self.bottomConstraint.active = YES;
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    NSDictionary *views = @{@"guide": self.topLayoutGuide,
                            @"text": self.textView};

    [self.view lhs_addConstraints:@"V:[guide][text]" views:views];
    [self.view lhs_addConstraints:@"H:|[text]|" views:views];
    [self.view layoutIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.textView becomeFirstResponder];

    [self lhs_activateKeyboardAdjustment];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self lhs_deactivateKeyboardAdjustment];
    [self.delegate editDescriptionViewControllerDidUpdateDescription:self];
}

#pragma mark - LHSKeyboardAdjusting

- (UIView *)keyboardAdjustingView {
    return self.textView;
}

- (BOOL)keyboardAdjustingAnimated {
    return YES;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return YES;
}

@end

