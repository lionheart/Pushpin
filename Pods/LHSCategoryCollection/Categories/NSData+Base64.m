//
//  NSData+Base64.m
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 12/17/13.
//
//  Credits: http://www.cocoadev.com/index.pl?BaseSixtyFour
//

#import "NSData+Base64.h"

static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@implementation NSData (Base64)

+ (id)dataWithBase64EncodedString:(NSString *)string {
    return [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64Encoding64CharacterLineLength];
}

- (NSString *)base64Encoding {
    return [self base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

@end
