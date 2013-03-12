//
//  PPButton.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/11/13.
//
//

#import "PPButton.h"
#import "PPCoreGraphics.h"

@implementation PPButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGFloat normalStateGradientColors[8] = {
        0.306, 0.329, 0.388, 1,
        0.267, 0.290, 0.333, 1
    };
    CGFloat activeStateGradientColors[8] = {
        0.208, 0.227, 0.271, 1,
        0.255, 0.275, 0.325, 1
    };

    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGRect outerBorderRect = CGRectMake(0, 0, rect.size.width, rect.size.height);
    CGRect innerBorderRect = CGRectInset(outerBorderRect, 1, 1);
    
    CGContextSetRGBStrokeColor(context, 0.035, 0.039, 0.047, 1);
    CGContextSetLineWidth(context, 1);
    CGContextAddRoundedRect(context, outerBorderRect, 8);
    CGContextStrokePath(context);

    CGContextSetLineWidth(context, 1);
    CGContextAddRoundedRect(context, innerBorderRect, 6.f);
    CGContextClip(context);

    size_t colorCount = 2;
    
    CGFloat colorLocations[2] = { 0.0, 1.0 };
    CGGradientRef normalGradient = CGGradientCreateWithColorComponents(colorSpace, normalStateGradientColors, colorLocations, colorCount);
    CGGradientRef activeGradient = CGGradientCreateWithColorComponents(colorSpace, activeStateGradientColors, colorLocations, colorCount);
    CGPoint startPoint = CGPointMake(rect.origin.x, rect.origin.y);
    CGPoint endPoint = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
    CGContextDrawLinearGradient(context, normalGradient, startPoint, endPoint, 0);
    
    CGContextSetRGBStrokeColor(context, 0.447, 0.475, 0.537, 1);
    CGContextSetLineWidth(context, 2);
    CGContextMoveToPoint(context, innerBorderRect.origin.x, innerBorderRect.origin.y);
    CGContextAddLineToPoint(context, innerBorderRect.origin.x + innerBorderRect.size.width, innerBorderRect.origin.y);
    CGContextStrokePath(context);

    UIImage *normalBackground = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Set up highlighted background
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    context = UIGraphicsGetCurrentContext();

    CGContextSetRGBStrokeColor(context, 0.035, 0.039, 0.047, 1);
    CGContextSetLineWidth(context, 1);
    CGContextAddRoundedRect(context, outerBorderRect, 8);
    CGContextStrokePath(context);

    CGContextSetLineWidth(context, 1);
    CGContextAddRoundedRect(context, innerBorderRect, 6.f);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, activeGradient, startPoint, endPoint, 0);
    UIImage *activeBackground = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self setBackgroundImage:normalBackground forState:UIControlStateNormal];
    [self setBackgroundImage:activeBackground forState:UIControlStateHighlighted];
}

@end
