//
//  PPShrinkBackAnimator.m
//  Pushpin
//
//  Created by Dan Loewenherz on 8/1/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

@import LHSCategoryCollection;

#import "PPShrinkBackAnimator.h"

static CGFloat kPPShrinkBackAnimationDuration = 0.6;

@implementation PPShrinkBackAnimator

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    // Forwards, slide the new view up while shrinking the old view.
    // Reverse, do the opposite.
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];

    [containerView addSubview:fromViewController.view];
    [containerView addSubview:toViewController.view];
    UIView *cover = [[UIView alloc] initWithFrame:fromViewController.view.frame];
    cover.backgroundColor = [UIColor blackColor];
    cover.userInteractionEnabled = NO;

    [containerView addSubview:cover];

    containerView.backgroundColor = [UIColor blackColor];

    CATransform3D transform3D = CATransform3DIdentity;
    transform3D = CATransform3DTranslate(transform3D, 0, 0, -100);
    transform3D = CATransform3DScale(transform3D, 0.925, 0.925, 0);

    void (^animations)(void);
    if (self.reverse) {
        cover.alpha = 0.4;

        if (![UIApplication isIPad]) {
            fromViewController.view.frame = containerView.frame;
        }
        toViewController.view.transform = CATransform3DGetAffineTransform(transform3D);

        [containerView bringSubviewToFront:fromViewController.view];

        animations = ^{
            cover.alpha = 0;
            toViewController.view.layer.transform = CATransform3DIdentity;
            toViewController.view.frame = containerView.frame;
            fromViewController.view.frame = CGRectOffset(fromViewController.view.frame, 0, CGRectGetHeight(fromViewController.view.frame));
        };
    } else {
        cover.alpha = 0;
        toViewController.view.frame = CGRectOffset(toViewController.view.frame, 0, CGRectGetHeight(toViewController.view.frame));

        if (![UIApplication isIPad]) {
            fromViewController.view.frame = containerView.frame;
        }
        fromViewController.view.layer.transform = CATransform3DIdentity;

        [containerView bringSubviewToFront:toViewController.view];

        animations = ^{
            toViewController.view.frame = CGRectOffset(toViewController.view.frame, 0, -CGRectGetHeight(toViewController.view.frame));
            cover.alpha = .4;
            fromViewController.view.transform = CATransform3DGetAffineTransform(transform3D);
        };
    }

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0
         usingSpringWithDamping:10
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:animations
                     completion:^(BOOL finished) {
                         [fromViewController.view removeFromSuperview];
                         [cover removeFromSuperview];
                         [transitionContext completeTransition:YES];
                     }];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return kPPShrinkBackAnimationDuration;
}

@end
