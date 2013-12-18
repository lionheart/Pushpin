//
//  PPButton.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/11/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "PPButton.h"
#import "AppDelegate.h"
#import "PPTheme.h"

@implementation PPButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.font = [UIFont fontWithName:[PPTheme boldFontName] size:17.f];
        self.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.titleLabel.layer.shadowRadius = 0.0;
        self.titleLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        self.titleLabel.layer.shadowOpacity = 0.5;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        [self setTitleColor:HEX(0xffffffff) forState:UIControlStateNormal];

        UIImage *normalBackgroundImage = [[UIImage imageNamed:@"gray-button-cap"] resizableImageWithCapInsets:UIEdgeInsetsMake(24, 10, 23, 9)];
        UIImage *highlightedBackgroundImage = [[UIImage imageNamed:@"gray-button-highlighted-cap"] resizableImageWithCapInsets:UIEdgeInsetsMake(24, 10, 23, 9)];
        [self setBackgroundImage:normalBackgroundImage forState:UIControlStateNormal];
        [self setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
    }
    return self;
}

@end
