//
//  MFMailComposeViewController+Theme.m
//  Pushpin
//
//  Created by Dan Loewenherz on 2/13/14.
//
//

#import "MFMailComposeViewController+Theme.h"

@implementation MFMailComposeViewController (Theme)

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return nil;
}

@end
