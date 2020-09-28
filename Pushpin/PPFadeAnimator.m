//
//  PPFadeAnimator.m
//  Pushpin
//
//  Created by Dan Loewenherz on 8/5/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPFadeAnimator.h"

@implementation PPFadeAnimator

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];

    [containerView addSubview:fromViewController.view];
    [containerView addSubview:toViewController.view];

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0
         usingSpringWithDamping:10
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        toViewController.view.alpha = 1;
        fromViewController.view.alpha = 0;
    }
                     completion:^(BOOL finished) {
        [fromViewController.view removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

@end

