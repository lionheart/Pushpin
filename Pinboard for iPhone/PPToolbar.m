//
//  PPToolbar.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/24/13.
//
//

#import "PPToolbar.h"
#import <QuartzCore/QuartzCore.h>

@implementation PPToolbar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *backgroundImage = [UIColor colorWithRed:0.161 green:0.176 blue:0.318 alpha:1];

        CALayer *topBorder = [CALayer layer];
        topBorder.frame = CGRectMake(0, 0, 600, 1);
        topBorder.borderWidth = 1;
        topBorder.borderColor = [UIColor blackColor].CGColor;
        [self.layer insertSublayer:topBorder atIndex:[self.layer.sublayers count]];
    }
    return self;
}

@end
