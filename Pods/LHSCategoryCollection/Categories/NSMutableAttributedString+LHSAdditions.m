//
//  NSMutableAttributedString+LHSAdditions.m
//  LHSCategoryCollection
//
//  Created by Daniel Loewenherz on 2/19/15.
//
//

#import "NSMutableAttributedString+LHSAdditions.h"
#import "NSAttributedString+LHSAdditions.h"

@implementation NSMutableAttributedString (LHSAdditions)

- (void)lhs_addAttribute:(NSString *)name value:(id)value {
    [self addAttribute:name value:value range:self.lhs_range];
}

- (void)lhs_addAttributes:(NSDictionary *)attrs {
    [self addAttributes:attrs range:self.lhs_range];
}

- (void)lhs_removeAttribute:(NSString *)name {
    [self removeAttribute:name range:self.lhs_range];
}

@end
