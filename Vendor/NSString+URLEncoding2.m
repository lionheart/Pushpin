//
//  NSString+URLEncoding.m
//  Pushpin
//
//  Created by Dan Loewenherz on 10/20/12.
//
//

#import "NSString+URLEncoding2.h"

@implementation NSString (URLEncoding)

-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding {
    NSString *s = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", CFStringConvertNSStringEncodingToEncoding(encoding));
    return [s autorelease];
}

@end

