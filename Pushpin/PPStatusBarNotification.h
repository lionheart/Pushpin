//
//  PPStatusBarNotification.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/25/13.
//
//

@import Foundation;

typedef enum : NSInteger {
    PPStatusBarNotificationAnimationSlideToRight,
    PPStatusBarNotificationAnimationSlideToLeft,
    PPStatusBarNotificationAnimationSlideUp,
    PPStatusBarNotificationAnimationSlideDown,
} PPStatusBarNotificationAnimation;

@interface PPStatusBarNotification : NSObject

+ (id)sharedNotification;
- (void)showWithText:(NSString *)text;
- (void)displayText:(NSString *)text withAnimation:(PPStatusBarNotificationAnimation)animation duration:(CGFloat)duration;

@end
