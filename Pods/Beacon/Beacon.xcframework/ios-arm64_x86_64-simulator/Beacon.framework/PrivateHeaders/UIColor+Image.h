#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Image)

- (UIImage *)image:(CGSize)size;
- (UIImage *)drawInitialsImage:(NSString *)text inBounds:(CGRect)bounds withContentMode:(UIViewContentMode)contentMode;

@end

NS_ASSUME_NONNULL_END
