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
//  PPLoadingView.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/17/13.
//
//

#import "PPLoadingView.h"

@implementation PPLoadingView

- (void)startAnimating {
    NSMutableArray *images = [NSMutableArray array];
    for (int i=1; i<81; i++) {
        [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"loading_%02d", i]]];
    }

    self.animationImages = images;
    self.animationDuration = 3;
    [super startAnimating];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(40, 40);
}

@end
