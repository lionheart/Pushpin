#import "HSBeacon.h"

NS_ASSUME_NONNULL_BEGIN

@class HSBeaconPushNotificationSupport;
@class HSBeaconUserStore;

@interface HSBeacon (Private)

+ (instancetype)sharedBeacon;

- (HSBeaconPushNotificationSupport *)pushNotificationSupport;

- (HSBeaconUserStore *)userStore;

@end

NS_ASSUME_NONNULL_END
