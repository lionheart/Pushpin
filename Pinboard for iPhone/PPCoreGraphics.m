//
//  PPCoreGraphics.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/11/13.
//
//

#import "PPCoreGraphics.h"

void CGContextAddRoundedRect(CGContextRef context, CGRect rect, CGFloat radius) {
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + radius);
    CGContextAddArcToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x + radius, rect.origin.y, radius);
    CGContextAddArcToPoint(context, rect.origin.x + rect.size.width, rect.origin.y, rect.origin.x + rect.size.width, rect.origin.y + radius, radius);
    CGContextAddArcToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height, rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height, radius);
    CGContextAddArcToPoint(context, rect.origin.x, rect.origin.y + rect.size.height, rect.origin.x, rect.origin.y + rect.size.height - radius, radius);
    CGContextClosePath(context);
}

@implementation PPCoreGraphics

@end
