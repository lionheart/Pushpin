#import "HSBeacon.h"

NS_ASSUME_NONNULL_BEGIN

@class HSBeaconPushNotificationSupport;

@interface HSBeacon (Private)

+ (instancetype)sharedBeacon;

- (HSBeaconPushNotificationSupport *)pushNotificationSupport;

@end

NS_ASSUME_NONNULL_END
