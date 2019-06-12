#import <Foundation/Foundation.h>

static NSString *const kHSBeaconFontFamilyName = @ "scouticons";

typedef NS_ENUM (NSInteger, HSIcon) {
    HSActiveChat, HSAttach, HSCaretDown, HSCaretUp, HSChat, HSCheck, HSCheckbox, HSClock, HSClose, HSDoc, HSLink, HSSearch
};

@interface HSBeaconFontIcons: NSObject

+(NSAttributedString *)attributedStringForIcon:(HSIcon)icon;

+(NSAttributedString *)attributedStringForIcon:(HSIcon)icon color:(UIColor *)color;

+(NSAttributedString *)attributedStringForIcon: (HSIcon)icon color: (UIColor *)color size: (CGFloat)size;

+(UIBarButtonItem *)barButtonForIcon:(HSIcon)icon color:(UIColor *)color target:(id)target action:(SEL)action;

+(UIButton *)buttonForIcon:(HSIcon)icon color:(UIColor *)color target:(id)target action:(SEL)action;

+(UIImage *)imageForIcon: (HSIcon)icon color: (UIColor *)color size: (CGFloat)size;

@end
