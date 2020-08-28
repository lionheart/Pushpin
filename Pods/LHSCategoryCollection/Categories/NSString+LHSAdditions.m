//
//  NSString+LHSAdditions.m
//  LHSCategoryCollection
//
//  Created by Daniel Loewenherz on 2/19/15.
//
//

#import "NSString+LHSAdditions.h"

@implementation NSString (LHSAdditions)

- (NSRange)lhs_range {
    return NSMakeRange(0, self.length);
}

- (NSString *)lhs_urlEncode {
    return [self lhs_urlEncodeUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)lhs_urlEncodeUsingEncoding:(NSStringEncoding)encoding {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", CFStringConvertNSStringEncodingToEncoding(encoding)));
}

@end
