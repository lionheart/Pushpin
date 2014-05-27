//
//  UIApplication+LHSAdditions.m
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 12/17/13.
//
//

#import "UIApplication+LHSAdditions.h"

@implementation UIApplication (LHSAdditions)

+ (BOOL)isIPad {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

+ (BOOL)isIOS6OrGreater {
    return [[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0;
}

+ (CGSize)currentSize {
    return [UIApplication sizeInOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation {
    CGSize size = [UIScreen mainScreen].bounds.size;
    
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        size = CGSizeMake(size.height, size.width);
    }
    
    return size;
}

+ (void)lhs_setNetworkActivityIndicatorVisible:(BOOL)setVisible {
    static NSInteger LHSNumberOfCallsToSetVisible = 0;
    if (setVisible) {
        LHSNumberOfCallsToSetVisible++;
    }
    else {
        LHSNumberOfCallsToSetVisible--;
    }

    // Display the indicator as long as our static counter is > 0.
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(LHSNumberOfCallsToSetVisible > 0)];
    });
}

+ (NSString *)lhs_formattedVersionString {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = infoDictionary[@"CFBundleShortVersionString"];
    NSString *bundleVersion = infoDictionary[@"CFBundleVersion"];
    
    return [NSString stringWithFormat:@"%@ (%@)", appVersion, bundleVersion];
}

@end
