//
//  NSString+LHSAdditions.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/13/14.
//
//

#import "NSString+LHSAdditions.h"

@implementation NSString (LHSAdditions2)

- (NSInteger)lhs_IntegerIfNotNull {
#warning XXX Does not work, since NSNull must have a category with the same name.
    if ([self isEqual:[NSNull null]]) {
        return 0;
    } else {
        return [self integerValue];
    }
}

- (NSString *)lhs_stringByTrimmingWhitespace {
#warning XXX Does not work, since NSNull must have a category with the same name.
    if ([self isEqual:[NSNull null]]) {
        return @"";
    } else {
        return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
}

@end

