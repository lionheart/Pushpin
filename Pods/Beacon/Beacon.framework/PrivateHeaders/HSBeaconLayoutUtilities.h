#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, HSBeaconLayoutAttribute) {
    HSBeaconLayoutAttributeTop      = 1 << 0,
    HSBeaconLayoutAttributeBottom   = 1 << 1,
    HSBeaconLayoutAttributeLeft     = 1 << 2,
    HSBeaconLayoutAttributeRight    = 1 << 3,
};

@interface HSBeaconLayoutUtilities : NSObject

+ (NSArray<NSLayoutConstraint *> *)constraintsForView:(UIView *)innerView equalToView:(UIView *)outerView;

+ (NSArray<NSLayoutConstraint *> *)constraintsForView:(UIView *)view sized:(CGSize)size;

+ (NSArray<NSLayoutConstraint *> *)constraintsForView:(UIView *)view containedInView:(UIView *)container distance:(int)distance fromAttributes:(HSBeaconLayoutAttribute)attributes;

@end
