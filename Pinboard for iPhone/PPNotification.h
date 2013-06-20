//
//  PPNotification.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/20/13.
//
//

#import <Foundation/Foundation.h>

@interface PPNotification : NSObject

@property (nonatomic) BOOL hiding;
@property (nonatomic) BOOL visible;
@property (nonatomic, strong) UIView *notificationView;

+ (PPNotification *)sharedInstance;

- (void)showInView:(UIView *)view withMessage:(NSString *)message;
- (UIView *)notificationViewWithMessage:(NSString *)message;
- (void)hide;
- (void)hide:(BOOL)animated;
- (void)didRotate:(NSNotification *)notification;

@end
