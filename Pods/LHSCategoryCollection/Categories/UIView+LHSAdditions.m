//
//  UIView+LHSAdditions.m
//  LHSCategoryCollection
//
//  Copyright (c) 2013 Lionheart Software LLC. All rights reserved.
//

#import "UIView+LHSAdditions.h"

@implementation UIView (LHSAdditions)

#pragma mark - Auto Layout Helpers

- (NSLayoutConstraint *)lhs_constraintForWidth:(CGFloat)width {
    return [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:width];
}

- (NSLayoutConstraint *)lhs_constraintForHeight:(CGFloat)height {
    return [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:height];
}

- (NSLayoutConstraint *)lhs_setHeight:(CGFloat)height {
    NSLayoutConstraint *constraint = [self lhs_constraintForHeight:height];
    [self.superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)lhs_setWidth:(CGFloat)width {
    NSLayoutConstraint *constraint = [self lhs_constraintForWidth:width];
    [self.superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)lhs_matchHeightOfSuperviewWithPadding:(CGFloat)padding {
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeHeight multiplier:1 constant:padding];
    [self.superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)lhs_matchWidthOfSuperviewWithPadding:(CGFloat)padding {
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeWidth multiplier:1 constant:padding];
    [self.superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)lhs_matchHeightOfSuperview {
    return [self lhs_matchHeightOfSuperviewWithPadding:0];
}

- (NSLayoutConstraint *)lhs_matchWidthOfSuperview {
    return [self lhs_matchWidthOfSuperviewWithPadding:0];
}

- (NSArray *)lhs_fillHeightOfSuperview {
    NSArray *constraints = [self.superview lhs_addConstraints:@"V:|[view]|" views:@{@"view": self}];
    [self.superview addConstraints:constraints];
    return constraints;
}

- (NSArray *)lhs_fillWidthOfSuperview {
    NSArray *constraints = [self.superview lhs_addConstraints:@"H:|[view]|" views:@{@"view": self}];
    [self.superview addConstraints:constraints];
    return constraints;
}

#pragma mark - Expanding

- (NSArray *)lhs_expandToFillSuperview {
    return [[self lhs_fillHeightOfSuperview] arrayByAddingObjectsFromArray:[self lhs_fillWidthOfSuperview]];
}

- (NSArray *)lhs_expandToFillSuperviewWithVerticalMargin:(CGFloat)verticalMargin
                                        horizontalMargin:(CGFloat)horizontalMargin {
    return [self lhs_expandToFillSuperviewWithMargins:UIEdgeInsetsMake(verticalMargin, horizontalMargin, verticalMargin, horizontalMargin)];
}

- (NSArray *)lhs_expandToFillSuperviewWithMargins:(UIEdgeInsets)margins {
    NSDictionary *metrics = @{@"top": @(margins.top),
                              @"right": @(margins.right),
                              @"bottom": @(margins.bottom),
                              @"left": @(margins.left) };
    NSDictionary *views = @{@"view": self};
    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObject:[self.superview lhs_addConstraints:@"H:|-(left)-[view]-(right)-|" metrics:metrics views:views]];
    [constraints addObject:[self.superview lhs_addConstraints:@"V:|-(top)-[view]-(bottom)-|" metrics:metrics views:views]];
    return constraints;
}

#pragma mark - Centering

- (NSArray *)lhs_centerHorizontallyForView:(UIView *)view {
    return [self lhs_centerHorizontallyForView:view width:0];
}

- (NSArray *)lhs_centerVerticallyForView:(UIView *)view {
    return [self lhs_centerVerticallyForView:view height:0];
}

- (NSArray *)lhs_centerHorizontallyForView:(UIView *)view width:(CGFloat)width {
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    [self addConstraint:constraint];
    
    NSMutableArray *constraints = [@[constraint] mutableCopy];
    
    if (width > 0) {
        [constraints addObjectsFromArray:[self lhs_addConstraints:@"H:|-(>=1)-[view(width)]-(>=1)-|" metrics:@{@"width": @(width)} views:@{@"view": view}]];
    }
    
    return constraints;
}

- (NSArray *)lhs_centerVerticallyForView:(UIView *)view height:(CGFloat)height {
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    [self addConstraint:constraint];
    
    NSMutableArray *constraints = [@[constraint] mutableCopy];
    
    if (height > 0) {
        [constraints addObjectsFromArray:[self lhs_addConstraints:@"V:|-(>=1)-[view(height)]-(>=1)-|" metrics:@{@"height": @(height)} views:@{@"view": view}]];
    }
    
    return constraints;
}

#pragma - Auto Layout

- (NSArray *)lhs_addConstraints:(NSString *)constraint views:(NSDictionary *)views {
    return [self lhs_addConstraints:constraint metrics:0 views:views];
}

- (NSArray *)lhs_addConstraints:(NSString *)constraint metrics:(NSDictionary *)metrics views:(NSDictionary *)views {
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:constraint options:0 metrics:metrics views:views];
    [self addConstraints:constraints];
    return constraints;
}

#pragma - Helpers

- (CGFloat)lhs_distanceToPoint:(CGPoint)point {
    if (CGRectContainsPoint(self.frame, point)) {
        return 0;
    }
    
    CGPoint closest = self.frame.origin;
    if (self.frame.origin.x + self.frame.size.width < point.x) {
        closest.x += self.frame.size.width;
    }
    else if (point.x > self.frame.origin.x) {
        closest.x = point.x;
    }
    
    if (self.frame.origin.y + self.frame.size.height < point.y) {
        closest.y += self.frame.size.height;
    }
    else if (point.y > self.frame.origin.y) {
        closest.y = point.y;
    }
    
    CGFloat a = powf(closest.y-point.y, 2);
    CGFloat b = powf(closest.x-point.x, 2);
    return sqrtf(a + b);
}

#pragma mark - Utilities

- (void)lhs_removeSubviews {
    NSArray *subviews = [self subviews];
    for (UIView *subview in subviews) {
        [subview removeFromSuperview];
    }
}

- (CGRect)lhs_centerRect {
    return (CGRect){{self.frame.size.width / 2., self.frame.size.height / 2.}, {1, 1}};
}

#pragma mark - Multi View Helpers

+ (NSArray *)lhs_addConstraints:(NSString *)format metrics:(NSDictionary *)metrics views:(NSArray *)views {
    NSMutableArray *constraints = [NSMutableArray array];
    for (UIView *view in views) {
        if (view.superview) {
            NSArray *viewConstraints = [view.superview lhs_addConstraints:format metrics:metrics views:@{@"view": view}];
            [constraints addObjectsFromArray:viewConstraints];
        }
    }
    
    return constraints;
}

+ (NSArray *)lhs_addConstraints:(NSString *)format views:(NSArray *)views {
    return [UIView lhs_addConstraints:format metrics:nil views:views];
}

@end
