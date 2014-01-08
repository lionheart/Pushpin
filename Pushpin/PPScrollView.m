//
//  PPScrollView.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/2/14.
//
//

#import "PPScrollView.h"

@implementation PPScrollView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // Find out if the user is actively scrolling the tableView of which this is a member.
    // If they are, return NO, and don't let the gesture recognizers work simultaneously.
    //
    // This works very well in maintaining user expectations while still allowing for the user to
    // scroll the cell sideways when that is their true intent.
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {

        // Find the current scrolling velocity in that view, in the Y direction.
        CGFloat yVelocity = [(UIPanGestureRecognizer*)gestureRecognizer velocityInView:gestureRecognizer.view].y;

        return fabs(yVelocity) > 0.25;
        return fabs(yVelocity) <= 0.25;
    }
    return NO;
}

@end
