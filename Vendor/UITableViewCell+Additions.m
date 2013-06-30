//
//  UITableViewCell+Additions.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/30/13.
//
//

#import "UITableViewCell+Additions.h"

@implementation UITableViewCell (Additions)

- (void)removeSubviews {
    NSArray *subviews = self.contentView.subviews;
    for (UIView *subview in subviews) {
        [subview removeFromSuperview];
    }
}

@end
