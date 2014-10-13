//
//  UIAlertController+LHSAdditions.m
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 10/13/14.
//
//

#import "UIAlertController+LHSAdditions.h"

@implementation UIAlertController (LHSAdditions)

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
