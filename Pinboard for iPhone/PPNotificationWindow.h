//
//  PPNotificationWindow.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/18/13.
//
//

#import <UIKit/UIKit.h>

@interface PPNotificationWindow : UIWindow

@property (nonatomic, strong) UIView *notificationView;
@property (nonatomic) BOOL hiding;

+ (PPNotificationWindow *)sharedInstance;

- (UIView *)notificationViewWithMessage:(NSString *)message;
- (void)showWithMessage:(NSString *)message;
- (void)hide;
- (void)hide:(BOOL)animated;
- (void)moveOffscreen;

@end
