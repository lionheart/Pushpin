//
//  UITableView+Additions.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/25/13.
//
//

#import "UITableView+Additions.h"

@implementation UITableView (Additions)

- (CGFloat)groupedCellMargin {
    CGFloat marginWidth;
    CGFloat tableViewWidth = CGRectGetWidth(self.frame);
    if (tableViewWidth > 20) {
        if (tableViewWidth < 400) {
            marginWidth = 10;
        } else {
            marginWidth = MAX(31, MIN(45, tableViewWidth*0.06));
        }
    } else {
        marginWidth = tableViewWidth - 10;
    }
    return marginWidth;
}

@end
