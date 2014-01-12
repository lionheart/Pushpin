//
//  PPStatusBarNotification.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/25/13.
//
//

#import "PPStatusBarNotification.h"
#import <LHSCategoryCollection/UIScreen+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

@interface PPStatusBarNotification ()

@property (nonatomic, strong) UIWindow *notification;

+ (id)sharedNotification;

@property (nonatomic, strong) UIWindow *notificationWindow;

@end

@implementation PPStatusBarNotification

+ (id)sharedNotification {
    static PPStatusBarNotification *notification;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notification = [[PPStatusBarNotification alloc] init];
    });
    return notification;
}

- (void)showWithText:(NSString *)text {
    [self displayText:text
        withAnimation:PPStatusBarNotificationAnimationSlideDown
             duration:1.5];

}

- (void)displayText:(NSString *)text
      withAnimation:(PPStatusBarNotificationAnimation)animation
           duration:(CGFloat)duration {
    
    CGSize size = [UIApplication currentSize];
    CGRect frame = CGRectMake(0, 0, size.width, 20);

    self.notificationWindow = [[UIWindow alloc] initWithFrame:frame];
    self.notificationWindow.clipsToBounds = YES;

    CGAffineTransform transform;
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            // Home button on left
            transform = CGAffineTransformMakeRotation(-M_PI / 2);
            transform = CGAffineTransformTranslate(transform, -(size.width - 20)/2, -(size.width - 20)/2);
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            // Home button on right
            transform = CGAffineTransformMakeRotation(M_PI / 2);
            transform = CGAffineTransformTranslate(transform, (size.width - 20)/2, 10 + size.height - size.width);
            break;
            
        default:
            transform = CGAffineTransformIdentity;
            break;
    }

    self.notificationWindow.transform = transform;

    UIView *notificationContainer = [[UIView alloc] initWithFrame:frame];
    notificationContainer.clipsToBounds = YES;
    notificationContainer.backgroundColor = [UIColor darkGrayColor];
    [self.notificationWindow addSubview:notificationContainer];
    
    UIView *statusBarView = [UIScreen lhs_snapshotContainingStatusBar];
    statusBarView.translatesAutoresizingMaskIntoConstraints = NO;
    statusBarView.hidden = YES;
    [notificationContainer addSubview:statusBarView];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont boldSystemFontOfSize:12];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor darkGrayColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [notificationContainer addSubview:label];

    NSMutableArray *hiddenStatusBarConstraints = [NSMutableArray array];
    NSMutableArray *visibleStatusBarConstraints = [NSMutableArray array];
    NSMutableArray *bounceConstraints = [NSMutableArray array];

    NSDictionary *views = @{@"status": statusBarView,
                            @"label": label};
    
    CGFloat animationDuration;
    
    switch (animation) {
        case PPStatusBarNotificationAnimationSlideDown:
            [hiddenStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
            [hiddenStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:20]];
            
            [visibleStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:-20]];
            [visibleStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
            
            [bounceConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:5]];
            [bounceConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:25]];
            
            [notificationContainer lhs_addConstraints:@"H:|[status]|" views:views];
            [notificationContainer lhs_addConstraints:@"H:|[label]|" views:views];

            [statusBarView lhs_setHeight:20];
            [label lhs_setHeight:20];
            
            animationDuration = 0.6;
            break;
            
        case PPStatusBarNotificationAnimationSlideUp:
            [hiddenStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
            [hiddenStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:-20]];
            
            [visibleStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:20]];
            [visibleStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
            
            [bounceConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:-5]];
            [bounceConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:-5]];
            
            [notificationContainer lhs_addConstraints:@"H:|[status]|" views:views];
            [notificationContainer lhs_addConstraints:@"H:|[label]|" views:views];

            [statusBarView lhs_setHeight:20];
            [label lhs_setHeight:20];
            
            animationDuration = 0.6;
            break;
            
        case PPStatusBarNotificationAnimationSlideToLeft:
            [hiddenStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
            [hiddenStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
            
            [visibleStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
            [visibleStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
            
            [bounceConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeLeft multiplier:1 constant:-20]];
            [bounceConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
            
            [notificationContainer lhs_addConstraints:@"V:|[status]|" views:views];
            [notificationContainer lhs_addConstraints:@"V:|[label]|" views:views];

            [label lhs_matchWidthOfSuperview];
            [statusBarView lhs_matchWidthOfSuperview];
            
            animationDuration = 0.4;
            break;
            
        case PPStatusBarNotificationAnimationSlideToRight:
            [hiddenStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
            [hiddenStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
            
            [visibleStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
            [visibleStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];

            [bounceConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeRight multiplier:1 constant:20]];
            [bounceConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeRight multiplier:1 constant:0]];

            [notificationContainer lhs_addConstraints:@"V:|[status]|" views:views];
            [notificationContainer lhs_addConstraints:@"V:|[label]|" views:views];

            [label lhs_matchWidthOfSuperview];
            [statusBarView lhs_matchWidthOfSuperview];
            
            animationDuration = 0.4;
            break;
    }

    [notificationContainer addConstraints:visibleStatusBarConstraints];
    
    [self.notificationWindow layoutIfNeeded];
    
    self.notificationWindow.windowLevel = UIWindowLevelStatusBar;
    [self.notificationWindow makeKeyAndVisible];
    
    void (^ShowStatusLabelBlock)() = ^{
        [notificationContainer removeConstraints:visibleStatusBarConstraints];
        [notificationContainer addConstraints:hiddenStatusBarConstraints];
        [self.notificationWindow layoutIfNeeded];
    };
    
    void (^HideStatusLabelBlock)() = ^{
        [notificationContainer removeConstraints:hiddenStatusBarConstraints];
        [notificationContainer addConstraints:visibleStatusBarConstraints];
        notificationContainer.backgroundColor = [UIColor clearColor];
        [self.notificationWindow layoutIfNeeded];
    };
    
    void (^BounceBeginBlock)() = ^{
        [notificationContainer removeConstraints:hiddenStatusBarConstraints];
        [notificationContainer addConstraints:bounceConstraints];
        [notificationContainer layoutIfNeeded];
    };
    
    void (^BounceEndBlock)() = ^{
        [notificationContainer removeConstraints:bounceConstraints];
        [notificationContainer addConstraints:visibleStatusBarConstraints];
        notificationContainer.backgroundColor = [UIColor clearColor];
        [notificationContainer layoutIfNeeded];
    };
    
    void (^CompletionBlock)(BOOL finished) = ^(BOOL finished) {
        [self.notificationWindow resignKeyWindow];
        self.notificationWindow.hidden = YES;
        self.notificationWindow = nil;
    };
    
    BOOL bounce = bounceConstraints.count > 0;
    [UIView animateWithDuration:animationDuration
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:1
                        options:0
                     animations:ShowStatusLabelBlock
                     completion:^(BOOL finished) {
                         if (bounce) {
                             [UIView animateWithDuration:0.3
                                                   delay:duration
                                                 options:UIViewAnimationOptionCurveEaseInOut
                                              animations:BounceBeginBlock
                                              completion:^(BOOL finished) {
                                                  [UIView animateWithDuration:0.4
                                                                        delay:0
                                                       usingSpringWithDamping:0.8
                                                        initialSpringVelocity:1
                                                                      options:UIViewAnimationOptionCurveEaseOut
                                                                   animations:BounceEndBlock
                                                                   completion:CompletionBlock];
                                              }];
                         }
                         else {
                             [UIView animateWithDuration:0.4
                                                   delay:duration
                                  usingSpringWithDamping:1
                                   initialSpringVelocity:-100
                                                 options:0
                                              animations:HideStatusLabelBlock
                                              completion:CompletionBlock];
                         }
                     }];
}

@end
