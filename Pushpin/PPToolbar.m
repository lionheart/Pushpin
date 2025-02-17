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
//  PPToolbar.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/24/13.
//
//
@import QuartzCore;
@import LHSCategoryCollection;

#import "PPToolbar.h"

static CGFloat const kDefaultColorLayerOpacity = 0.5f;

@interface PPToolbar ()

@property (nonatomic, strong) CALayer *extraColorLayer;

@end

@implementation PPToolbar

- (void)setBarTintColor:(UIColor *)barTintColor
{
    [super setBarTintColor:barTintColor];
    if (self.extraColorLayer == nil) {
        // this all only applies to 7.0 - 7.0.2
        if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0.3" options:NSNumericSearch] == NSOrderedAscending) {
            self.extraColorLayer = [CALayer layer];
            self.extraColorLayer.opacity = self.extraColorLayerOpacity;
            [self.layer addSublayer:self.extraColorLayer];
        }
    }
    self.extraColorLayer.backgroundColor = barTintColor.CGColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.extraColorLayer != nil) {
        [self.extraColorLayer removeFromSuperlayer];
        self.extraColorLayer.opacity = self.extraColorLayerOpacity;
        [self.layer insertSublayer:self.extraColorLayer atIndex:1];
        CGFloat spaceAboveBar = self.frame.origin.y;
        self.extraColorLayer.frame = CGRectMake(0, 0 - spaceAboveBar, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) + spaceAboveBar);
    }
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        _extraColorLayerOpacity = [[decoder decodeObjectForKey:@"extraColorLayerOpacity"] floatValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:@(self.extraColorLayerOpacity) forKey:@"extraColorLayerOpacity"];
}

@end

