//
//  PPTitleButton.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/20/13.
//
//

#import "PPTitleButton.h"
#import "PPTheme.h"

@implementation PPTitleButton

+ (instancetype)button {
    PPTitleButton *titleButton = [PPTitleButton buttonWithType:UIButtonTypeCustom];
    titleButton.frame = CGRectMake(0, 0, 200, 24);
    titleButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    titleButton.titleLabel.textColor = [UIColor whiteColor];
    titleButton.backgroundColor = [UIColor clearColor];
    titleButton.titleLabel.font = [PPTheme extraLargeFont];
    titleButton.adjustsImageWhenHighlighted = NO;
    return titleButton;
}

- (void)setTitle:(NSString *)title imageName:(NSString *)imageName {
    [self setTitle:title forState:UIControlStateNormal];
    [self setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

@end
