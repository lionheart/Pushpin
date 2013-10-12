//
//  UIImage+Tint.h
//  Pushpin
//
//  Created by Dan Loewenherz on 10/12/13.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (Tint)

- (UIImage *)imageWithColor:(UIColor *)color;
- (UIImage *)imageWithAlpha:(CGFloat)alpha;

@end
