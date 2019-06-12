#import <Foundation/Foundation.h>

@class HSBeaconConfig;
@class HSBeaconSettings;

@interface HSBeaconTintColor : NSObject

- (instancetype _Nonnull)initWithBeaconSettings:(nonnull HSBeaconSettings *)beaconSettings beaconConfig:(nonnull HSBeaconConfig *)beaconConfig;

/*!
 @brief Returns the title color used by the Beacon SDK user interface.
 
 @discussion This will use the `UIAppearance` title text attributes foreground
 color if available, or default to `UIColor.whiteColor`.
 
 @return UIColor The Beacon SDK title color.
 */
- (UIColor * _Nonnull)titleColor;

/*!
 @brief Returns the tint color used by the Beacon SDK user interface.
 
 @discussion This will use the `UIAppearance` tint color if available, or
 default to `UIColor.whiteColor`.
 
 @return UIColor The Beacon SDK tint color.
 */
- (UIColor * _Nonnull)tintColor;

/*!
 @brief Returns the bar tint color used by the Beacon SDK user interface.
 
 @discussion This will use the Beacon configuration color by default, but will
 fall back to the `UIAppearance` color if `useNavigationBarTintColor` is set
 on the provided `HSBeaconSettings` object.
 
 @return UIColor The Beacon SDK bar tint color.
 */
- (UIColor * _Nonnull)barTintColor;

- (UIBarStyle)barStyle;

- (UIStatusBarStyle)statusBarStyle;

- (UIActivityIndicatorViewStyle)indicatorViewStyle;

@end
