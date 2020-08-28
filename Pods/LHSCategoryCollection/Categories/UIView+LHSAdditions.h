//
//  UIView+LHSAdditions.h
//  LHCategoryCollection
//
//  Copyright (c) 2013 Lionheart Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (LHSAdditions)

- (NSLayoutConstraint *)lhs_constraintForWidth:(CGFloat)width;
- (NSLayoutConstraint *)lhs_constraintForHeight:(CGFloat)height;
- (NSLayoutConstraint *)lhs_setHeight:(CGFloat)height;
- (NSLayoutConstraint *)lhs_setWidth:(CGFloat)width;
- (NSLayoutConstraint *)lhs_matchWidthOfSuperview;
- (NSLayoutConstraint *)lhs_matchHeightOfSuperview;
- (NSLayoutConstraint *)lhs_matchWidthOfSuperviewWithPadding:(CGFloat)padding;
- (NSLayoutConstraint *)lhs_matchHeightOfSuperviewWithPadding:(CGFloat)padding;

- (NSArray *)lhs_expandToFillSuperview;
- (NSArray *)lhs_expandToFillSuperviewWithVerticalMargin:(CGFloat)verticalMargin
                                        horizontalMargin:(CGFloat)horizontalMargin;

- (NSArray *)lhs_expandToFillSuperviewWithMargins:(UIEdgeInsets)margins;
- (NSArray *)lhs_fillWidthOfSuperview;
- (NSArray *)lhs_fillHeightOfSuperview;
- (NSArray *)lhs_addConstraints:(NSString *)constraint views:(NSDictionary *)views;
- (NSArray *)lhs_addConstraints:(NSString *)constraint metrics:(NSDictionary *)metrics views:(NSDictionary *)views;
- (NSArray *)lhs_centerHorizontallyForView:(UIView *)view;
- (NSArray *)lhs_centerVerticallyForView:(UIView *)view;
- (NSArray *)lhs_centerHorizontallyForView:(UIView *)view width:(CGFloat)width;
- (NSArray *)lhs_centerVerticallyForView:(UIView *)view height:(CGFloat)height;
- (CGFloat)lhs_distanceToPoint:(CGPoint)point;
- (void)lhs_removeSubviews;

- (CGRect)lhs_centerRect;

+ (NSArray *)lhs_addConstraints:(NSString *)format views:(NSArray *)views;
+ (NSArray *)lhs_addConstraints:(NSString *)format metrics:(NSDictionary *)metrics views:(NSArray *)views;

@end
