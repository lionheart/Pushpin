#import <Foundation/Foundation.h>

@class HSBeaconTintColor;

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconNavigationBarAppearanceUpdater : NSObject

- (instancetype)initWithTintColor:(HSBeaconTintColor *)tintColor;

- (void)updateStyles;
- (void)restoreStyles;

@end

NS_ASSUME_NONNULL_END
