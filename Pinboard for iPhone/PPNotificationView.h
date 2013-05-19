//
//  PPNotificationView.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/18/13.
//
//

#import <UIKit/UIKit.h>

@interface PPNotificationView : UIView

@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic) BOOL hiding;

+ (PPNotificationView *)sharedInstance;
- (void)showWithMessage:(NSString *)message;
- (void)hide;
- (void)hide:(BOOL)animated;
- (void)moveOffscreen;

@end
