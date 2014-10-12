//
//  UIAlertController+UIAlertController_LHSAdditions.h
//  Pushpin
//
//  Created by Dan Loewenherz on 10/12/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (UIAlertController_LHSAdditions)

+ (UIAlertController *)lhs_alertViewWithTitle:(NSString *)title message:(NSString *)message;
+ (UIAlertController *)lhs_actionSheetWithTitle:(NSString *)title;

- (void)lhs_addActionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^)(UIAlertAction *action))handler;

@end
