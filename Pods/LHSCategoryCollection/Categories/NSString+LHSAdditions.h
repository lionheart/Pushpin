//
//  NSString+LHSAdditions.h
//  LHSCategoryCollection
//
//  Created by Daniel Loewenherz on 2/19/15.
//
//

#import <Foundation/Foundation.h>

@interface NSString (LHSAdditions)

- (NSRange)lhs_range;
- (NSString *)lhs_urlEncode;
- (NSString *)lhs_urlEncodeUsingEncoding:(NSStringEncoding)encoding;

@end
