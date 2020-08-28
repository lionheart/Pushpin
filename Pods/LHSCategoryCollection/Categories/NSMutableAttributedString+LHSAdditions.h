//
//  NSMutableAttributedString+LHSAdditions.h
//  LHSCategoryCollection
//
//  Created by Daniel Loewenherz on 2/19/15.
//
//

#import <Foundation/Foundation.h>

@interface NSMutableAttributedString (LHSAdditions)

- (void)lhs_addAttribute:(NSString *)name value:(id)value;
- (void)lhs_addAttributes:(NSDictionary *)attrs;
- (void)lhs_removeAttribute:(NSString *)name;

@end
