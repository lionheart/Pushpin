#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern const CGFloat HSBeaconSearchBackgroundViewHeight;

@interface HSBeaconSearchBackgroundView : UIView

- (instancetype)initWithBeaconColor:(UIColor *)color andBackground:(UIColor *)background;

- (void)transitionToHeight:(CGFloat)height;

@end

NS_ASSUME_NONNULL_END
