//
//  UIImage+LHSAdditions.h
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 12/25/13.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (LHSAdditions)

- (UIImage *)lhs_imageWithColor:(UIColor *)color;
- (UIImage *)lhs_imageWithAlpha:(CGFloat)alpha;
- (UIImage *)lhs_imageByCroppingToRect:(CGRect)rect;
+ (UIImage *)lhs_screenshot;

@end
