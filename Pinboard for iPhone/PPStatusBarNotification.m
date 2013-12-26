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
    self.notificationWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
//    self.notificationWindow.backgroundColor = [UIColor whiteColor];
    self.notificationWindow.clipsToBounds = YES;
    
    UIView *notificationContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    notificationContainer.clipsToBounds = YES;
//    notificationContainer.backgroundColor = [UIColor whiteColor];
    [self.notificationWindow addSubview:notificationContainer];
    
    UIView *statusBarView = [UIScreen lhs_snapshotContainingStatusBar];
    statusBarView.translatesAutoresizingMaskIntoConstraints = NO;
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
    [hiddenStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [hiddenStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:20]];
    
    NSMutableArray *visibleStatusBarConstraints = [NSMutableArray array];
    [visibleStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:-20]];
    [visibleStatusBarConstraints addObject:[NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:0]];

    [notificationContainer addConstraints:visibleStatusBarConstraints];

    [statusBarView lhs_setHeight:20];
    [statusBarView lhs_fillWidthOfSuperview];

    [label lhs_setHeight:20];
    [label lhs_fillWidthOfSuperview];
    
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
        [self.notificationWindow layoutIfNeeded];
    };

    [UIView animateWithDuration:0.4
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:10
                        options:0
                     animations:ShowStatusLabelBlock
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.5
                                               delay:1.5
                                             options:0
                                          animations:HideStatusLabelBlock
                                          completion:^(BOOL finished) {
                                              [self.notificationWindow resignKeyWindow];
                                              self.notificationWindow.hidden = YES;
                                          }];
                     }];
}

@end
