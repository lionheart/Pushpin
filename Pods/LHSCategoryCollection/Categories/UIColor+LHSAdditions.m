//
//  UIColor+LHSAdditions.m
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 4/7/14.
//
//

#import "UIColor+LHSAdditions.h"

@implementation UIColor (LHSAdditions)

- (BOOL)lhs_isDark {
    CGFloat R;
    CGFloat G;
    CGFloat B;
    CGFloat A;

    BOOL converted = [self getRed:&R green:&G blue:&B alpha:&A];
    if (!converted) {
        return NO;
    }
    
    // Formula derived from here:
    // http://www.w3.org/WAI/ER/WD-AERT/#color-contrast
    
    // Alpha blending:
    // http://stackoverflow.com/a/746937/39155
    CGFloat newR = (255 * (1 - A) + 255 * R * A) / 255.;
    CGFloat newG = (255 * (1 - A) + 255 * G * A) / 255.;
    CGFloat newB = (255 * (1 - A) + 255 * B * A) / 255.;
    return ((newR * 255 * 299) + (newG * 255 * 587) + (newB * 255 * 114)) / 1000 < 200;
}

@end
