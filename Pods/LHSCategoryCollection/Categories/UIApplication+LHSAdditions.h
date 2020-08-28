//
//  UIApplication+LHSAdditions.h
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 12/17/13.
//
//

#import <UIKit/UIKit.h>

@interface UIApplication (LHSAdditions)

+ (BOOL)isIPad;
+ (BOOL)isIOS6OrGreater;
+ (CGSize)currentSize;
+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation;
+ (void)lhs_setNetworkActivityIndicatorVisible:(BOOL)setVisible;
+ (NSString *)lhs_formattedVersionString;

@end
