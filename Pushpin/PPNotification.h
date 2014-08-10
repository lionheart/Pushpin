//
//  PPNotification.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/20/13.
//
//

@import Foundation;

@interface PPNotification : NSObject

@property (nonatomic) BOOL hiding;
@property (nonatomic) BOOL visible;
@property (nonatomic, strong) UIView *notificationView;

+ (PPNotification *)sharedInstance;
+ (void)notifyWithMessage:(NSString *)message;
+ (void)notifyWithMessage:(NSString *)message success:(BOOL)success updated:(BOOL)updated;
+ (void)notifyWithMessage:(NSString *)message success:(BOOL)success updated:(BOOL)updated delay:(CGFloat)seconds;
+ (void)notifyWithMessage:(NSString *)message userInfo:(id)userInfo;
+ (void)notifyWithMessage:(NSString *)message userInfo:(id)userInfo delay:(CGFloat)seconds;

- (void)showInView:(UIView *)view withMessage:(NSString *)message;
- (UIView *)notificationViewWithMessage:(NSString *)message;
- (void)hide;
- (void)hide:(BOOL)animated;
- (void)didRotate:(NSNotification *)notification;

@end
