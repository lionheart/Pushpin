//
//  PPNotificationWindow.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/18/13.
//
//

#import "PPNotificationWindow.h"

static NSInteger kPPNotificationHeight = 56;

@implementation PPNotificationWindow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:SCREEN.bounds];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        self.hiding = NO;
    }
    return self;
}

- (void)hide {
    [self hide:YES];
}

- (void)hide:(BOOL)animated {
    if (!self.hiding) {
        self.hiding = YES;
        CGRect hiddenFrame = CGRectMake(0, SCREEN.bounds.size.height, 320, kPPNotificationHeight);
        if (animated) {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.notificationView.frame = hiddenFrame;
                             }
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     self.notificationView = nil;
                                     self.hidden = YES;
                                     self.hiding = NO;
                                 }
                             }];
        }
        else {
            self.notificationView.frame = hiddenFrame;
            self.notificationView = nil;
            self.hidden = YES;
            self.hiding = NO;
        }
    }
}

- (void)showWithMessage:(NSString *)message {
    self.hidden = NO;
    self.notificationView = [self notificationViewWithMessage:message];

    [self addSubview:self.notificationView];

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.notificationView.frame = CGRectMake(0, SCREEN.bounds.size.height - kPPNotificationHeight, 320, kPPNotificationHeight);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             double delayInSeconds = 2;
                             dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                             dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                 [self hide:YES];
                             });
                         }
                     }];
}

+ (PPNotificationWindow *)sharedInstance {
    static dispatch_once_t once;
    static PPNotificationWindow *sharedView;
    dispatch_once(&once, ^ {
        sharedView = [[PPNotificationWindow alloc] initWithFrame:SCREEN.bounds];
    });
    return sharedView;
}

- (UIView *)notificationViewWithMessage:(NSString *)message {
    if (!_notificationView) {
        _notificationView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN.bounds.size.height, 320, kPPNotificationHeight)];
        _notificationView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"NotificationBackground"]];

        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont fontWithName:@"Avenir-Medium" size:15];
        label.textColor = [UIColor whiteColor];
        label.text = message;
        CGSize size = [message sizeWithFont:label.font constrainedToSize:CGSizeMake(320, CGFLOAT_MAX)];
        label.frame = CGRectMake(20, (kPPNotificationHeight - size.height) / 2, size.width, size.height);
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage imageNamed:@"NotificationX"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(293, (kPPNotificationHeight - 17) / 2, 17, 17);

        [_notificationView addSubview:label];
        [_notificationView addSubview:button];
    }
    return _notificationView;
}

@end
