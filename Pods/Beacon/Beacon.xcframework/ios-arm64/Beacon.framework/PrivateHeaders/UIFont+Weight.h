#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (Beacon)

+ (UIFont *)fontOfStyle:(UIFontTextStyle)fontStyle withWeight:(UIFontWeight)weight;
+ (UIFont *)fontOfStyle:(UIFontTextStyle)fontStyle withWeight:(UIFontWeight)weight andPointSizeOffset:(CGFloat)sizeOffset;

@end

NS_ASSUME_NONNULL_END
