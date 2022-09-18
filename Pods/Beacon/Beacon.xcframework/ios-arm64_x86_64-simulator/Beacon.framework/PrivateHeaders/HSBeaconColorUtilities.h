#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, HSBeaconColorShade) {
    HSBeaconColorShadeLight,
    HSBeaconColorShadeDark,
};

@interface HSBeaconColorUtilities : NSObject

FOUNDATION_EXPORT CGFloat const HSShadowOverlayOpacity;

+ (UIColor * _Nonnull)greyColor;

+ (UIColor * _Nonnull)blueGreyColor;

+ (UIColor * _Nonnull)darkColor;

+ (UIColor * _Nonnull)errorRedColor;

+ (UIColor * _Nonnull)blackColorWithAlpha:(CGFloat)alpha;

+ (HSBeaconColorShade)optimalShadeForColor:(nonnull UIColor *)color;

/*!
 @brief Returns a UIColor instance derived from the provided hex string.
 
 @note This assumes an RGB hex format; if the format is not correct, you may
 get an unexpected color or a nil return value.
 */
+ (nullable UIColor *)colorWithHexValue:(NSString * _Nonnull)hexString;

/*!
 @brief returns hex value for a UIColor
 */
+ (uint)hexFromColor:(UIColor * _Nonnull)color;

/*!
 @brief returns a hex string for the UIColor
 */
+ (nonnull NSString*)cssStringFromColor:(UIColor * _Nonnull)color;

+ (UIColor *_Nullable)lighterColorForColor:(nonnull UIColor *)color;

+ (UIColor *_Nullable)darkerColorForColor:(nonnull UIColor *)color;


@end
