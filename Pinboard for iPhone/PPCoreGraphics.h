//
//  PPCoreGraphics.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/11/13.
//
//

#import <Foundation/Foundation.h>

@interface PPCoreGraphics : NSObject

void CGContextAddRoundedRect(CGContextRef context, CGRect rect, CGFloat radius);

@end
