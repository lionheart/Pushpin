//
//  UIAlertController+LHSAdditions.h
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 10/13/14.
//
//

#import <UIKit/UIKit.h>

@interface UIAlertController (LHSAdditions)

+ (UIAlertController *)lhs_alertViewWithTitle:(NSString *)title message:(NSString *)message;
+ (UIAlertController *)lhs_actionSheetWithTitle:(NSString *)title;

- (void)lhs_addActionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^)(UIAlertAction *action))handler;

@end
