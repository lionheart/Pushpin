//
//  UIApplication+AppDimensions.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/20/13.
//
//

#import <UIKit/UIKit.h>

@interface UIApplication (AppDimensions)

+ (CGSize)currentSize;
+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation;

@end
