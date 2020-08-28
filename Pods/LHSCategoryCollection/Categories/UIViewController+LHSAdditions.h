//
//  UIViewController+LHSAdditions.h
//  LHCategoryCollection
//
//  Copyright (c) 2013 Lionheart Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (LHSAdditions)

+ (UIViewController *)lhs_topViewController;
+ (UIViewController *)lhs_topViewControllerWithRootViewController:(UIViewController *)rootViewController;

@end

