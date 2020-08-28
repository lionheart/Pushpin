//
//  NSAttributedString+LHSAdditions.m
//  LHSCategoryCollection
//
//  Created by Daniel Loewenherz on 2/19/15.
//
//

#import "NSAttributedString+LHSAdditions.h"

@implementation NSAttributedString (LHSAdditions)

- (NSRange)lhs_range {
    return NSMakeRange(0, self.length);
}

@end
