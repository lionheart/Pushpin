//
//  PPFadeTransition.m
//  Pushpin
//
//  Created by Dan Loewenherz on 8/5/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPFadeTransition.h"
#import "PPFadeAnimator.h"

@implementation PPFadeTransition

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    PPFadeAnimator *animator = [PPFadeAnimator new];
    animator.reverse = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [PPFadeAnimator new];
}

@end

