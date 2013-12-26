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
//    label.backgroundColor = HEX(0x28A6FEFF);
    label.backgroundColor = HEX(0x0096FFFF);
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [notificationContainer addSubview:label];

    NSLayoutConstraint *statusBarConstraint = [NSLayoutConstraint constraintWithItem:statusBarView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    NSLayoutConstraint *labelConstraint = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:notificationContainer attribute:NSLayoutAttributeTop multiplier:1 constant:-20];

    [notificationContainer addConstraint:statusBarConstraint];
    [notificationContainer addConstraint:labelConstraint];

    [statusBarView lhs_setHeight:20];
    [statusBarView lhs_fillWidthOfSuperview];

    [label lhs_setHeight:20];
    [label lhs_fillWidthOfSuperview];

    [self.notificationWindow layoutIfNeeded];

    self.notificationWindow.windowLevel = UIWindowLevelStatusBar;
    [self.notificationWindow makeKeyAndVisible];

    [UIView animateWithDuration:0.5
                     animations:^{
                         labelConstraint.constant = 0;
                         statusBarConstraint.constant = 20;
                         [self.notificationWindow layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.5
                                               delay:1.5
                                             options:0
                                          animations:^{
                                              labelConstraint.constant = -20;
                                              statusBarConstraint.constant = 0;
                                              [self.notificationWindow layoutIfNeeded];
                                          }
                                          completion:^(BOOL finished) {
                                              [self.notificationWindow resignKeyWindow];
                                              self.notificationWindow.hidden = YES;
                                          }];
                     }];
}

@end
