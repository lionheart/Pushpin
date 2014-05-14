//
//  NSString+LHSAdditions.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/13/14.
//
//

#import "NSString+LHSAdditions.h"

@implementation NSString (LHSAdditions)

- (NSInteger)lhs_IntegerIfNotNull {
    if ([self isEqual:[NSNull null]]) {
        return 0;
    }
    else {
        return [self integerValue];
    }
}

- (NSString *)lhs_stringByTrimmingWhitespace {
    if ([self isEqual:[NSNull null]]) {
        return @"";
    }
    else {
        return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
}

@end
