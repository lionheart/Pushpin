#import <Foundation/Foundation.h>

@interface HSBeaconBundleUtils : NSObject

+ (NSBundle * _Nonnull)beaconBundle;

+ (UIViewController *)viewControllerInStoryboard:(NSString *_Nonnull)storyboardName viewControllerIdentifier:(NSString *_Nonnull)identifier;

@end
