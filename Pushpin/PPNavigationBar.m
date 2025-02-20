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
//  PPNavigationBar.m
//  Pushpin
//
//  Created by Andy Muldowney on 11/20/13.
//
//

#import "PPNavigationBar.h"

@implementation PPNavigationBar

static CGFloat const kDefaultColorLayerOpacity = 1.0;
static CGFloat const kSpaceToCoverStatusBars = 44;

- (void)setBarTintColor:(UIColor *)barTintColor {
    [super setBarTintColor:barTintColor];

    if (self.colorLayer == nil) {
        self.colorLayer = [CALayer layer];
        self.colorLayer.opacity = kDefaultColorLayerOpacity;
        [self.layer addSublayer:self.colorLayer];
    }

    CGFloat red, green, blue, alpha;
    [barTintColor getRed:&red green:&green blue:&blue alpha:&alpha];

    CGFloat opacity = kDefaultColorLayerOpacity;

    CGFloat minVal = MIN(MIN(red, green), blue);

    if ([self convertValue:minVal withOpacity:opacity] < 0) {
        opacity = [self minOpacityForValue:minVal];
    }

    self.colorLayer.opacity = opacity;

    red = [self convertValue:red withOpacity:opacity];
    green = [self convertValue:green withOpacity:opacity];
    blue = [self convertValue:blue withOpacity:opacity];

    red = MAX(MIN(1.0, red), 0);
    green = MAX(MIN(1.0, green), 0);
    blue = MAX(MIN(1.0, blue), 0);

    self.colorLayer.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha].CGColor;
}

- (CGFloat)minOpacityForValue:(CGFloat)value
{
    return (0.4 - 0.4 * value) / (0.6 * value + 0.4);
}

- (CGFloat)convertValue:(CGFloat)value withOpacity:(CGFloat)opacity
{
    return 0.4 * value / opacity + 0.6 * value - 0.4 / opacity + 0.4;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.colorLayer != nil) {
        self.colorLayer.frame = CGRectMake(0, 0 - kSpaceToCoverStatusBars, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) + kSpaceToCoverStatusBars);

        [self.layer insertSublayer:self.colorLayer atIndex:1];
    }
}

- (void)displayColorLayer:(BOOL)display {
    self.colorLayer.hidden = !display;
}

@end

