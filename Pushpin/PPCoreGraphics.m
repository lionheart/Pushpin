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
//  PPCoreGraphics.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/11/13.
//
//

#import "PPCoreGraphics.h"
#import "AppDelegate.h"
#import "PPTheme.h"

void CGContextAddRoundedRect(CGContextRef context, CGRect rect, CGFloat radius) {
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + radius);
    CGContextAddArcToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x + radius, rect.origin.y, radius);
    CGContextAddArcToPoint(context, rect.origin.x + rect.size.width, rect.origin.y, rect.origin.x + rect.size.width, rect.origin.y + radius, radius);
    CGContextAddArcToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height, rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height, radius);
    CGContextAddArcToPoint(context, rect.origin.x, rect.origin.y + rect.size.height, rect.origin.x, rect.origin.y + rect.size.height - radius, radius);
    CGContextClosePath(context);
}

@implementation PPCoreGraphics

+ (UIImage *)pillImage:(NSString *)text {
    UIImage *countBackground = [[UIImage imageNamed:@"count-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 15, 14, 15)];
    UIFont *font = [UIFont fontWithName:[PPTheme blackFontName] size:14];
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGRect textRect = [text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:0 attributes:attributes context:nil];
    CGSize textSize = textRect.size;
    CGSize size = textSize;
    size.height = 27;
    size.width = size.width + 20;

    UIImageView *countBackgroundView = [[UIImageView alloc] initWithImage:countBackground];
    countBackgroundView.frame = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);
    [countBackgroundView drawRect:CGRectMake(0, 0, size.width, size.height)];
    CGContextRestoreGState(context);

    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    CGContextSetShadowWithColor(context, CGSizeMake(1, 1), 1, HEX(0x00000044).CGColor);

    [text drawInRect:CGRectInset(CGRectMake(0, 1, size.width, size.height), (size.width - textSize.width) / 2, (size.height - textSize.height) / 2) withAttributes:attributes];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
