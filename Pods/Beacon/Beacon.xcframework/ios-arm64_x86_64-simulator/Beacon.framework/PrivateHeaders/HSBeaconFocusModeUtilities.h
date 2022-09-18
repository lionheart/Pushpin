#import <Foundation/Foundation.h>
#import "HSBeaconFocusMode.h"

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconFocusModeUtilities : NSObject

+ (NSString *)stringFromFocusMode:(HSBeaconFocusMode)focusMode;
+ (HSBeaconFocusMode)focusModeForString:(NSString * _Nullable)string;

@end

NS_ASSUME_NONNULL_END
