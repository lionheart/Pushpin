@import Foundation;
#import <Beacon/HSBeaconContext.h>
#import <Beacon/HSBeaconSettings.h>
#import <Beacon/HSBeaconUser.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconContextFactory : NSObject

- (HSBeaconContext *)contextWithSettings:(HSBeaconSettings *)settings user:(HSBeaconUser * _Nullable)user signature:(NSString * _Nullable)signature;

@end

NS_ASSUME_NONNULL_END
