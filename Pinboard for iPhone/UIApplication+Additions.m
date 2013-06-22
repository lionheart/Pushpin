//
//  UIApplication+Additions.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/21/13.
//
//

#import <UIKit/UIKit.h>


#import "UIApplication+Additions.h"

@implementation UIApplication (Additions)

+ (BOOL)isIPad {
    __block BOOL isIPad;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    });
    return isIPad;
}

+ (BOOL)isIOS6OrGreater {
    return [[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0;
}
+ (CGSize)currentSize {
    return [UIApplication sizeInOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation {
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIApplication *application = [UIApplication sharedApplication];
    
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        size = CGSizeMake(size.height, size.width);
    }

    return size;
}

@end