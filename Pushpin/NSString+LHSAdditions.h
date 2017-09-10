//
//  NSString+LHSAdditions.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/13/14.
//
//

@import Foundation;

@interface NSString (LHSAdditions2)

- (NSInteger)lhs_IntegerIfNotNull;
- (NSString *)lhs_stringByTrimmingWhitespace;

@end
