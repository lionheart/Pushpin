//
//  UIViewController+LHSAdditions.m
//  LHSCategoryCollection
//
//  Copyright (c) 2013 Lionheart Software LLC. All rights reserved.
//

#import "UIViewController+LHSAdditions.h"

@implementation UIViewController (LHSAdditions)

+ (UIViewController *)lhs_topViewController {
    return [UIViewController lhs_topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

+ (UIViewController *)lhs_topViewControllerWithRootViewController:(UIViewController *)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)rootViewController;
        return [UIViewController lhs_topViewControllerWithRootViewController:tabBarController.selectedViewController];
    }
    else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController;
        return [UIViewController lhs_topViewControllerWithRootViewController:navigationController.visibleViewController];
    }
    else if ([rootViewController isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *splitViewController = (UISplitViewController *)rootViewController;
        return [UIViewController lhs_topViewControllerWithRootViewController:splitViewController.viewControllers[1]];
    }
    else if (rootViewController.presentedViewController) {
        UIViewController *presentedViewController = rootViewController.presentedViewController;
        if ([presentedViewController isKindOfClass:[UIAlertController class]]) {
            return rootViewController;
        }
        else {
            return [UIViewController lhs_topViewControllerWithRootViewController:presentedViewController];
        }
    }
    else {
        return rootViewController;
    }
}

@end
