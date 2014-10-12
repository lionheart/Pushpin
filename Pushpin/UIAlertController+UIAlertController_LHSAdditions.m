//
//  UIAlertController+UIAlertController_LHSAdditions.m
//  Pushpin
//
//  Created by Dan Loewenherz on 10/12/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "UIAlertController+UIAlertController_LHSAdditions.h"

@implementation UIAlertController (UIAlertController_LHSAdditions)

+ (UIAlertController *)lhs_actionSheetWithTitle:(NSString *)title {
    return [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
}

+ (UIAlertController *)lhs_alertViewWithTitle:(NSString *)title message:(NSString *)message {
    return [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
}

- (void)lhs_addActionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^)(UIAlertAction *))handler {
    [self addAction:[UIAlertAction actionWithTitle:title
                                             style:style
                                           handler:handler]];
}

@end
