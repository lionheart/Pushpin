//
//  UIWindow+LHSAdditions.m
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 11/7/14.
//
//

#import "UIWindow+LHSAdditions.h"

@implementation UIWindow (LHSAdditions)

+ (BOOL)lhs_takeScreenshotAndSaveToPath:(NSString *)path {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIGraphicsBeginImageContextWithOptions(keyWindow.bounds.size, NO, 0);
    [keyWindow drawViewHierarchyInRect:keyWindow.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *data = UIImagePNGRepresentation(image);
    return [data writeToFile:path atomically:YES];
}

@end
