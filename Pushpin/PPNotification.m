//
//  PPNotification.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/20/13.
//
//

@import LHSCategoryCollection;

#import "PPNotification.h"
#import "PPTheme.h"

static NSInteger kPPNotificationPadding = 16;
static BOOL kPPNotificationIsVisible = NO;
static PPNotification *shared;

@implementation PPNotification

+ (void)notifyWithMessage:(NSString *)message {
    [self notifyWithMessage:message userInfo:nil];
}

+ (void)notifyWithMessage:(NSString *)message success:(BOOL)success updated:(BOOL)updated {
    [self notifyWithMessage:message userInfo:@{@"success": @(success), @"updated": @(updated)}];
}

+ (void)notifyWithMessage:(NSString *)message success:(BOOL)success updated:(BOOL)updated delay:(CGFloat)seconds {
    [self notifyWithMessage:message userInfo:@{@"success": @(success), @"updated": @(updated)} delay:seconds];
}

+ (void)notifyWithMessage:(NSString *)message userInfo:(id)userInfo {
    [self notifyWithMessage:message userInfo:userInfo delay:0];
}

+ (void)notifyWithMessage:(NSString *)message userInfo:(id)userInfo delay:(CGFloat)seconds {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = message;
        notification.alertAction = NSLocalizedString(@"Open Pushpin", nil);
        
        if (!userInfo) {
            notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
        }

#ifndef APP_EXTENSION_SAFE
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
#endif
    });
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (void)hide {
    [self hide:YES];
}

- (void)hide:(BOOL)animated {
    if (!self.hiding) {
        self.hiding = YES;
        CGRect hiddenFrame = CGRectMake(0, [UIApplication currentSize].height, [UIApplication currentSize].width, CGRectGetHeight(self.notificationView.frame));
        if (animated) {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.notificationView.frame = hiddenFrame;
                             }
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     self.notificationView = nil;
                                     self.hiding = NO;
                                     kPPNotificationIsVisible = NO;
                                 }
                             }];
        } else {
            self.notificationView.frame = hiddenFrame;
            self.notificationView = nil;
            self.hiding = NO;
            kPPNotificationIsVisible = NO;
        }
    }
}

- (void)showInView:(UIView *)view withMessage:(NSString *)message {
    if (!kPPNotificationIsVisible) {
        kPPNotificationIsVisible = YES;

        self.notificationView = [self notificationViewWithMessage:message];
        self.notificationView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        [view addSubview:self.notificationView];
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.notificationView.frame = CGRectMake(0, [UIApplication currentSize].height - CGRectGetHeight(self.notificationView.frame), [UIApplication currentSize].width, CGRectGetHeight(self.notificationView.frame));
                         }
                         completion:^(BOOL finished) {
                             if (finished) {
                                 double delayInSeconds = 2.5;
                                 dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                 dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                     [self hide:YES];
                                 });
                             }
                             }];
    }
}

- (UIView *)notificationViewWithMessage:(NSString *)message {
    if (!_notificationView) {
        UIFont *font = [UIFont fontWithName:[PPTheme fontName] size:15];
        CGRect rect = [message boundingRectWithSize:CGSizeMake([UIApplication currentSize].width - 60, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font} context:nil];
        CGSize size = rect.size;

        _notificationView = [[UIView alloc] initWithFrame:CGRectMake(0, [UIApplication currentSize].height, [UIApplication currentSize].width, size.height + 2 * kPPNotificationPadding)];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIApplication currentSize].width, size.height + 2 * kPPNotificationPadding)];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        imageView.image = [[UIImage imageNamed:@"NotificationBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(4, [UIApplication currentSize].width / 2., 52, [UIApplication currentSize].width / 2.)];
        [_notificationView addSubview:imageView];

        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
        gestureRecognizer.numberOfTapsRequired = 1;
        [_notificationView addGestureRecognizer:gestureRecognizer];

        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 0;
        label.backgroundColor = [UIColor clearColor];
        label.font = font;
        label.textColor = [UIColor whiteColor];
        label.text = message;
        label.frame = CGRectMake(17, kPPNotificationPadding, [UIApplication currentSize].width - 60, size.height);

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [button setImage:[UIImage imageNamed:@"NotificationX"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake([UIApplication currentSize].width - 27, (CGRectGetHeight(_notificationView.frame) - 17) / 2, 17, 17);
        
        [_notificationView addSubview:label];
        [_notificationView addSubview:button];
    }
    return _notificationView;
}

+ (PPNotification *)sharedInstance {
    static dispatch_once_t once;
    dispatch_once(&once, ^ {
        shared = [[PPNotification alloc] init];
    });
    return shared;
}

- (void)didRotate:(NSNotification *)notification {
}

@end
