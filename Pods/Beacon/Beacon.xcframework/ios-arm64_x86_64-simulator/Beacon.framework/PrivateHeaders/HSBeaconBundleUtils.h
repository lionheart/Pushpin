#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconBundleUtils : NSObject

+ (NSBundle * _Nonnull)beaconBundle;

+ (UIViewController *)viewControllerInStoryboard:(NSString *_Nonnull)storyboardName viewControllerIdentifier:(NSString *_Nonnull)identifier;

@end

NS_ASSUME_NONNULL_END
