//
//  NSString+URLEncoding.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/20/12.
//
//

#import "NSString+URLEncoding2.h"

@implementation NSString (URLEncoding)

-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding {
    #warning Potential memory leak
	return (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                               (CFStringRef)self,
                                                               NULL,
                                                               (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                               CFStringConvertNSStringEncodingToEncoding(encoding));
}

@end
