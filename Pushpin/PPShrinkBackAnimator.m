//
//  PPShrinkBackAnimator.m
//  Pushpin
//
//  Created by Dan Loewenherz on 8/1/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPShrinkBackAnimator.h"

static CGFloat kPPShrinkBackAnimationDuration = 0.7;

@implementation PPShrinkBackAnimator

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    // Forwards, slide the new view up while shrinking the old view.
    // Reverse, do the opposite.
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];

    [containerView addSubview:fromViewController.view];
    [containerView addSubview:toViewController.view];

    CATransform3D transform3D = CATransform3DIdentity;
    transform3D = CATransform3DTranslate(transform3D, 0, 0, -100);
    transform3D = CATransform3DScale(transform3D, 0.92, 0.92, 0);
//    CATransform3DTranslate(transform3D, 0, 0, -10);

    void (^animations)();
    if (self.reverse) {
        toViewController.view.frame = containerView.frame;
        toViewController.view.transform = CATransform3DGetAffineTransform(transform3D);

        [containerView bringSubviewToFront:fromViewController.view];
        
        animations = ^{
            toViewController.view.layer.transform = CATransform3DIdentity;
            fromViewController.view.frame = CGRectOffset(containerView.frame, 0, CGRectGetHeight(containerView.frame));
        };
    }
    else {
        toViewController.view.frame = CGRectOffset(containerView.frame, 0, CGRectGetHeight(containerView.frame));
        fromViewController.view.frame = containerView.frame;
        fromViewController.view.layer.transform = CATransform3DIdentity;

        [containerView bringSubviewToFront:toViewController.view];
        
        animations = ^{
            toViewController.view.frame = containerView.frame;
            fromViewController.view.transform = CATransform3DGetAffineTransform(transform3D);
        };
    }
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0
         usingSpringWithDamping:10
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:animations
                     completion:^(BOOL finished) {
                         [fromViewController.view removeFromSuperview];
                         [transitionContext completeTransition:YES];
                     }];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return kPPShrinkBackAnimationDuration;
}

@end
