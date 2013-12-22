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

@property (nonatomic, strong) NSMutableArray *existingConstraints;

- (void)addConstraintsForImageAndTitle;
- (void)addConstraintsForTitleOnly;

@end

@implementation PPTitleButton

+ (instancetype)button {
    PPTitleButton *titleButton = [[PPTitleButton alloc] init];
    titleButton.frame = CGRectMake(0, 0, 300, 24);
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

    [titleButton addSubview:titleButton.containerView];
    [titleButton lhs_centerVerticallyForView:titleButton.containerView];
    [titleButton lhs_centerHorizontallyForView:titleButton.containerView];
    [titleButton addConstraintsForImageAndTitle];
    return titleButton;
}

- (void)setTitle:(NSString *)title imageName:(NSString *)imageName {
    self.titleLabel.text = title;

    if (imageName) {
        self.imageView.image = [UIImage imageNamed:imageName];
        [self addConstraintsForImageAndTitle];
    }
    else {
        self.imageView.image = nil;
        [self addConstraintsForTitleOnly];
    }

    [self layoutIfNeeded];
    self.frame = (CGRect){{0, 0}, self.containerView.frame.size};
}

- (void)addConstraintsForImageAndTitle {
    NSDictionary *views = @{@"title": self.titleLabel,
                            @"image": self.imageView};

    [self.containerView removeConstraints:self.containerView.constraints];
    [self.containerView lhs_addConstraints:@"H:|[image(20)]-5-[title]|" views:views];
    [self.containerView lhs_centerVerticallyForView:self.imageView height:20];
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeCenterY multiplier:1 constant:1]];
}

- (void)addConstraintsForTitleOnly {
    NSDictionary *views = @{@"title": self.titleLabel};

    [self.containerView removeConstraints:self.containerView.constraints];
    [self.containerView lhs_addConstraints:@"H:|[title]|" views:views];
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeCenterY multiplier:1 constant:1]];
}

@end
