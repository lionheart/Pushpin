//
//  UIApplication+Additions.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/21/13.
//
//

@interface UIApplication (Additions)

+ (BOOL)isIPad;
+ (BOOL)isIOS6OrGreater;
+ (CGSize)currentSize;
+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation;

@end
