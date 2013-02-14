//
//  ZAActivityBar.h
//
//  Created by Zac Altman on 24/11/12.
//  Copyright (c) 2012 Zac Altman. All rights reserved.
//
//  Heavily influenced by SVProgressHUD by Sam Vermette
//  Pieces of code may have been directly copied.
//  Sam is a legend!
//  https://github.com/samvermette/SVProgressHUD
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

#define BORDER_COLOR [[UIColor blackColor] colorWithAlphaComponent:0.8f]
#define BORDER_WIDTH 1.0f
#define HEIGHT 40.0f
#define XPADDING 10.0f
#define YPADDING 10.0f
#define ANIMATION_DURATION 0.3f
#define SPINNER_SIZE 24.0f
#define ICON_OFFSET (HEIGHT - SPINNER_SIZE) / 2.0f

@interface ZAActivityBar : UIView

+ (void) show;
+ (void) dismiss;

+ (void) showWithStatus:(NSString *)status;
+ (void) showSuccessWithStatus:(NSString *)status;
+ (void) showErrorWithStatus:(NSString *)status;
+ (void) showImage:(UIImage *)image status:(NSString *)status;

@end
