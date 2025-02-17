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
//  PPTitleButton.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/20/13.
//
//

@import LHSCategoryCollection;

#import "PPTitleButton.h"
#import "PPTheme.h"

@interface PPTitleButton ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) NSMutableArray *existingConstraints;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

- (void)addConstraintsForImageOnly;
- (void)addConstraintsForImageAndTitle;
- (void)addConstraintsForTitleOnly;
- (void)gestureDetected:(UIGestureRecognizer *)recognizer;

@end

@implementation PPTitleButton

+ (instancetype)buttonWithDelegate:(id)delegate {
    PPTitleButton *titleButton = [[PPTitleButton alloc] init];
    titleButton.translatesAutoresizingMaskIntoConstraints = NO;
    titleButton.containerView = [[UIView alloc] init];
    titleButton.containerView.translatesAutoresizingMaskIntoConstraints = NO;

    titleButton.titleLabel = [[UILabel alloc] init];
    titleButton.titleLabel.clipsToBounds = YES;
    titleButton.titleLabel.textColor = [UIColor whiteColor];
    titleButton.titleLabel.adjustsFontSizeToFitWidth = NO;
    titleButton.titleLabel.font = [PPTheme extraLargeFont];
    titleButton.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [titleButton.containerView addSubview:titleButton.titleLabel];

    titleButton.imageView = [[UIImageView alloc] init];
    titleButton.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [titleButton.containerView addSubview:titleButton.imageView];

    [titleButton addSubview:titleButton.containerView];
    [titleButton.containerView lhs_expandToFillSuperview];
    [titleButton lhs_centerVerticallyForView:titleButton.containerView];
    [titleButton lhs_centerHorizontallyForView:titleButton.containerView];
    [titleButton addConstraintsForImageAndTitle];

    if (delegate) {
        titleButton.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:titleButton
                                                                                   action:@selector(gestureDetected:)];
        [titleButton addGestureRecognizer:titleButton.tapGestureRecognizer];

        titleButton.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:titleButton
                                                                                               action:@selector(gestureDetected:)];
        [titleButton addGestureRecognizer:titleButton.longPressGestureRecognizer];
    }

    titleButton.delegate = delegate;
    return titleButton;
}

+ (instancetype)button {
    return [PPTitleButton buttonWithDelegate:nil];
}

- (void)setImageNames:(NSArray *)imageNames title:(NSString *)title {
    NSMutableArray *formatComponents = [NSMutableArray array];
    NSMutableDictionary *views = [NSMutableDictionary dictionary];
    NSInteger i = 0;

    self.imageView.hidden = YES;

    [NSLayoutConstraint deactivateConstraints:self.containerView.constraints];

    NSDictionary *metrics = @{@"width": @(20),
                              @"textWidth": @([UIApplication currentSize].width - 120)};
    for (NSString *imageName in imageNames) {
        NSString *formatName = [NSString stringWithFormat:@"image%ld", (long)i];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.containerView addSubview:imageView];

        views[formatName] = imageView;
        [formatComponents addObject:[NSString stringWithFormat:@"[%@(width)]", formatName]];

        if (title) {
            [self.containerView lhs_centerVerticallyForView:imageView height:20];
        } else {
            [self.containerView lhs_addConstraints:[NSString stringWithFormat:@"V:|[%@(width)]|", formatName] metrics:metrics views:views];
        }

        i++;
    }

    if (title) {
        self.titleLabel.text = title;
        views[@"title"] = self.titleLabel;
        [formatComponents addObject:@"[title(<=textWidth)]"];
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor constant:1].active = YES;
    }

    NSString *format = [NSString stringWithFormat:@"H:|%@|", [formatComponents componentsJoinedByString:@"-5-"]];

    [self.containerView lhs_addConstraints:format metrics:metrics views:views];

    [self layoutIfNeeded];
    self.frame = (CGRect){{0, 0}, self.containerView.frame.size};
}

- (void)setImageNames:(NSArray *)imageNames {
    [self setImageNames:imageNames title:nil];
}

- (void)setTitle:(NSString *)title imageName:(NSString *)imageName {
    if (imageName) {
        self.imageView.image = [UIImage imageNamed:imageName];

        if (title) {
            self.titleLabel.text = title;
            [self addConstraintsForImageAndTitle];
        } else {
            [self addConstraintsForImageOnly];
        }
    } else {
        self.titleLabel.text = title;
        self.imageView.image = nil;
        [self addConstraintsForTitleOnly];
    }

    [self layoutIfNeeded];
    self.frame = (CGRect){{0, 0}, self.containerView.frame.size};
}

- (void)addConstraintsForImageAndTitle {
    NSDictionary *views = @{@"title": self.titleLabel,
                            @"image": self.imageView};

    NSDictionary *metrics = @{@"width": @([UIApplication currentSize].width - 120)};

    [NSLayoutConstraint deactivateConstraints:self.containerView.constraints];
    [self.containerView lhs_addConstraints:@"H:|[image(20)]-5-[title(<=width)]|" metrics:metrics views:views];
    [self.containerView lhs_centerVerticallyForView:self.imageView height:20];
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor constant:1].active = YES;
}

- (void)addConstraintsForTitleOnly {
    NSDictionary *views = @{@"title": self.titleLabel};
    NSDictionary *metrics = @{@"width": @([UIApplication currentSize].width - 95)};

    [NSLayoutConstraint deactivateConstraints:self.containerView.constraints];
    [self.containerView lhs_addConstraints:@"H:|[title(<=width)]|" metrics:metrics views:views];
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor constant:1].active = YES;
}

- (void)addConstraintsForImageOnly {
    NSDictionary *views = @{@"image": self.imageView};
    NSDictionary *metrics = @{@"width": @(30)};

    [NSLayoutConstraint deactivateConstraints:self.containerView.constraints];
    [self.containerView lhs_addConstraints:@"H:|[image(width)]|" metrics:metrics views:views];
    [self.containerView lhs_addConstraints:@"V:|[image(width)]|" metrics:metrics views:views];
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (self.delegate) {
        if (recognizer == self.tapGestureRecognizer) {
            [self.delegate titleButtonTouchUpInside:self];
        } else {
            [self.delegate titleButtonLongPress:self];
        }
    }
}

@end

