//
//  PPTitleButton.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/20/13.
//
//

#import "PPTitleButton.h"
#import "PPTheme.h"
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

@interface PPTitleButton ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation PPTitleButton

+ (instancetype)button {
    PPTitleButton *titleButton = [[PPTitleButton alloc] init];
    titleButton.frame = CGRectMake(0, 0, 300, 24);
    titleButton.backgroundColor = [UIColor clearColor];
    
    titleButton.containerView = [[UIView alloc] init];
    titleButton.containerView.translatesAutoresizingMaskIntoConstraints = NO;

    titleButton.titleLabel = [[UILabel alloc] init];
    titleButton.titleLabel.textColor = [UIColor whiteColor];
    titleButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    titleButton.titleLabel.font = [PPTheme extraLargeFont];
    titleButton.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [titleButton.containerView addSubview:titleButton.titleLabel];
    
    titleButton.imageView = [[UIImageView alloc] init];
    titleButton.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [titleButton.containerView addSubview:titleButton.imageView];
    
    NSDictionary *views = @{@"title": titleButton.titleLabel,
                            @"image": titleButton.imageView};
    [titleButton.containerView lhs_addConstraints:@"H:|[image(20)]-5-[title]|" views:views];
    [titleButton.containerView lhs_centerVerticallyForView:titleButton.titleLabel];
    [titleButton.containerView lhs_centerVerticallyForView:titleButton.imageView height:20];
    
    [titleButton addSubview:titleButton.containerView];
    [titleButton lhs_centerVerticallyForView:titleButton.containerView];
    [titleButton lhs_centerHorizontallyForView:titleButton.containerView];
    return titleButton;
}

- (void)setTitle:(NSString *)title imageName:(NSString *)imageName {
    self.titleLabel.text = title;
    self.imageView.image = [UIImage imageNamed:imageName];
    
//    self.frame = CGRectMake(0, 0, 30 + [self.titleLabel sizeThatFits:CGSizeMake(270, 24)].width, 24);
    DLog(@"%@", NSStringFromCGRect(self.frame));
    [self layoutIfNeeded];
}

@end
