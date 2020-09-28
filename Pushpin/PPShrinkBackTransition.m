//
//  PPShrinkBackTransition.m
//  Pushpin
//
//  Created by Dan Loewenherz on 8/1/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPShrinkBackTransition.h"
#import "PPShrinkBackAnimator.h"

@implementation PPShrinkBackTransition

+ (PPShrinkBackTransition *)sharedInstance {
    static dispatch_once_t onceToken;
    static PPShrinkBackTransition *transition;
    dispatch_once(&onceToken, ^{
        transition = [[PPShrinkBackTransition alloc] init];
    });
    return transition;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    PPShrinkBackAnimator *animator = [PPShrinkBackAnimator new];
    animator.reverse = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [PPShrinkBackAnimator new];
}

@end

