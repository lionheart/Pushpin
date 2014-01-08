//
//  PPSplitViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/8/14.
//
//

#import "PPSplitViewController.h"

@interface PPSplitViewController ()

@end

@implementation PPSplitViewController

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.viewControllers[1];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.viewControllers[1];
}

@end
