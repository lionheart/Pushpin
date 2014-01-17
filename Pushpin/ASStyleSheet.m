//
//  ASStyleSheet.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 12/15/12.
//
//

#import "ASStyleSheet.h"
#import <uservoice-iphone-sdk/UVStyleSheet.h>

@implementation ASStyleSheet

+ (void)applyStyles {
    [UVStyleSheet instance].navigationBarBackgroundColor = [UIColor whiteColor];
    [UVStyleSheet instance].navigationBarTextColor = [UIColor whiteColor];
}

@end
