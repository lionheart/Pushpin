#import <Foundation/Foundation.h>

/*
 * This is the user info stored in the keychain for non-secure users.
 * It's stored after they send their first message and retrieved when the Beacon is opened
 */
@interface HSBeaconUserDeviceInfo : NSObject

@property (readonly, nonatomic) NSString *deviceId;
@property (readonly, nonatomic) NSString *email;
@property (readonly, nonatomic) NSString *name;

- (instancetype)initWithDeviceId:(NSString *)deviceId;

- (instancetype)initWithEmail:(NSString *)email name:(NSString *)name deviceId:(NSString *)deviceId;

@end
