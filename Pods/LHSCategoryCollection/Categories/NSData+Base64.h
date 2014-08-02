//
//  NSData+Base64.h
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 12/17/13.
//
//

#import <Foundation/Foundation.h>

@interface NSData (Base64)

+ (id)dataWithBase64EncodedString:(NSString *)string;
- (NSString *)base64Encoding;

@end
