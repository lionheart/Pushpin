//
//  NSString+Additions.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/4/15.
//  Copyright (c) 2015 Lionheart Software. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Additions)

- (BOOL)isReadabilityURL {
    return [self hasPrefix:@"http://pushpin-readability.herokuapp.com/v1/parser?url="] && [self hasSuffix:@"&format=json&onerr="];
}

- (NSString *)originalURLString {
    NSString *url = [self copy];
    if ([self isReadabilityURL]) {
        NSRange range = NSMakeRange(0, 55);
        NSRange range2 = NSMakeRange(self.length - 19, 19);

        url = [url stringByReplacingCharactersInRange:range2 withString:@""];
        url = [url stringByReplacingCharactersInRange:range withString:@""];
        url = [url stringByRemovingPercentEncoding];
    }
    return url;
}

@end
