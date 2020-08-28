//
//  UIFont+LHSAdditions.m
//  LHSCategoryCollection
//
//  Created by Dan Loewenherz on 4/6/14.
//
//

#import "UIFont+LHSAdditions.h"

@implementation UIFont (LHSAdditions)

- (NSString *)lhs_displayName {
    NSError *error;
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"([a-z])([A-Z])"
                                                                                options:0
                                                                                  error:&error];
    
    NSMutableString *response = [self.fontName mutableCopy];
    [expression replaceMatchesInString:response
                               options:0
                                 range:NSMakeRange(0, self.fontName.length)
                          withTemplate:@"$1 $2"];
    
    NSArray *components = [response componentsSeparatedByString:@"-"];
    return [components componentsJoinedByString:@" "];
}

@end
