#import <Foundation/Foundation.h>

#import "HSBeaconUserDeviceInfo.h"

@interface HSBeaconKeychainWrapper : NSObject

- (void)setUserDeviceInfo:(HSBeaconUserDeviceInfo *)object;
- (HSBeaconUserDeviceInfo *)userDeviceInfo;
- (void)resetKeychainItem;

@end
