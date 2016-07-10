//
//  UIScreen+LHSAdditions.m
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 12/25/13.
//
//

#import "UIScreen+LHSAdditions.h"

@implementation UIScreen (LHSAdditions)

+ (UIView *)lhs_snapshotContainingStatusBar {
    UIView *view = [[UIScreen mainScreen] snapshotViewAfterScreenUpdates:YES];
    UIScreen *screen = [UIScreen mainScreen];
    return [view resizableSnapshotViewFromRect:CGRectMake(0, 0, screen.bounds.size.width, 20)
                            afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
}

@end
