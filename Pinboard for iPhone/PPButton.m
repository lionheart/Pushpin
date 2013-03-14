//
//  PPButton.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/11/13.
//
//

#import "PPButton.h"
#import "PPCoreGraphics.h"

@implementation PPButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.font = [UIFont fontWithName:@"Avenir" size:17.f];
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;

        UIImage *normalBackgroundImage = [[UIImage imageNamed:@"gray-button-cap"] resizableImageWithCapInsets:UIEdgeInsetsMake(24, 10, 23, 9)];
        UIImage *highlightedBackgroundImage = [[UIImage imageNamed:@"gray-button-highlighted-cap"] resizableImageWithCapInsets:UIEdgeInsetsMake(24, 10, 23, 9)];
        [self setBackgroundImage:normalBackgroundImage forState:UIControlStateNormal];
        [self setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
    }
    return self;
}

@end
