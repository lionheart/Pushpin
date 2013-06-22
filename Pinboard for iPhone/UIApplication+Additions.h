//
//  UIApplication+Additions.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/21/13.
//
//

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
 
@end
