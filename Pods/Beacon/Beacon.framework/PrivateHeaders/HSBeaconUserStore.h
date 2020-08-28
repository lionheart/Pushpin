#import <Foundation/Foundation.h>
#import "HSBeaconBaseAPIClient.h"

@class HSBeaconUser;
@class HSBeaconSecurityInfo;
@class HSBeaconMessagingAPIClient;

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconUserStore : NSObject

@property (atomic, assign) BOOL synchronizedWithBeaconAPI;

- (instancetype)initWithUser:(HSBeaconUser * _Nullable)user;

- (HSBeaconUser * _Nullable)currentUser;

- (BOOL)isLoggedInWithUser:(HSBeaconUser *)user;
- (void)login:(HSBeaconUser *)user;
- (void)logout;
- (BOOL)requiresIdentification;

- (void)identifyIfRequiredWithAPIClient:(HSBeaconMessagingAPIClient *)client securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(BooleanCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
