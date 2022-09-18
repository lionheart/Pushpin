#import "HSBeacon.h"

NS_ASSUME_NONNULL_BEGIN

@class HSBeaconPushNotificationSupport;
@class HSBeaconUserStore;
@class HSBeaconContextFactory;
@class HSBeaconNavigationController;

@interface HSBeacon (Private)

+ (instancetype)sharedBeacon;

- (HSBeaconPushNotificationSupport *)pushNotificationSupport;
- (HSBeaconUserStore *)userStore;
@property (nonatomic, strong) HSBeaconContextFactory *contextFactory;
@property (nonatomic, strong) HSBeaconNavigationController *navigationController;

@end

NS_ASSUME_NONNULL_END
