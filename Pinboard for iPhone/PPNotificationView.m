//
//  PPNotificationView.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/18/13.
//
//

#import "PPNotificationView.h"

static NSInteger kPPNotificationHeight = 56;

@implementation PPNotificationView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(0, SCREEN.bounds.size.height, 320, kPPNotificationHeight)];
    if (self) {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"NotificationBackground"]];
        self.statusLabel = [[UILabel alloc] initWithFrame:CGRectInset(self.frame, 20, 13)];
        self.statusLabel.backgroundColor = [UIColor clearColor];
        self.statusLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:15];
        self.statusLabel.textColor = [UIColor whiteColor];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage imageNamed:@"NotificationX"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(293, (kPPNotificationHeight - 17) / 2, 17, 17);

        [self addSubview:button];
        [self addSubview:self.statusLabel];
    }
    return self;
}

- (void)hide {
    [self hide:YES];
}

- (void)hide:(BOOL)animated {
    CGRect hiddenFrame = CGRectMake(0, SCREEN.bounds.size.height, 320, kPPNotificationHeight);
    if (animated) {
        double delayInSeconds = 1.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.frame = hiddenFrame;
                             }];
        });
    }
    else {
        self.frame = hiddenFrame;
    }
}

- (void)showWithMessage:(NSString *)message {
    self.statusLabel.text = message;
    self.overlayWindow.hidden = NO;

    [self hide:NO];
    [self.overlayWindow addSubview:self];
    
    self.hiding = NO;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.frame = CGRectMake(0, SCREEN.bounds.size.height - kPPNotificationHeight, 320, kPPNotificationHeight);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             self.hiding = YES;
                             [self hide:YES];
                         }
                     }];
}

+ (PPNotificationView *)sharedInstance {
    static dispatch_once_t once;
    static PPNotificationView *sharedView;
    dispatch_once(&once, ^ {
        sharedView = [[PPNotificationView alloc] initWithFrame:SCREEN.bounds];
    });
    return sharedView;
}

- (UIWindow *)overlayWindow {
    if (!_overlayWindow) {
        _overlayWindow = [[UIWindow alloc] initWithFrame:SCREEN.bounds];
        _overlayWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _overlayWindow.backgroundColor = [UIColor clearColor];
        _overlayWindow.userInteractionEnabled = NO;
    }
    return _overlayWindow;
}

@end
