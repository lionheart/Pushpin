//
//  PPTableViewTitleView.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/2/14.
//
//

#import "PPTableViewTitleView.h"
#import "PPTheme.h"
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

@implementation PPTableViewTitleView

- (id)initWithText:(NSString *)text {
    return [self initWithText:text fontSize:18];
}

- (id)initWithText:(NSString *)text fontSize:(CGFloat)fontSize {
    self = [super init];
    self.text = text;
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont fontWithName:[PPTheme boldFontName] size:fontSize];
    label.text = text;
    
    if (text) {
        [self addSubview:label];
        
        [self lhs_addConstraints:@"H:|-12-[label]-12-|" views:NSDictionaryOfVariableBindings(label)];
        [self lhs_addConstraints:@"V:[label]-8-|" views:NSDictionaryOfVariableBindings(label)];
    }
    
    return self;
}

+ (CGFloat)heightWithText:(NSString *)text {
    return [self heightWithText:text fontSize:18];
}

+ (CGFloat)heightWithText:(NSString *)text fontSize:(CGFloat)fontSize {
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:[PPTheme boldFontName] size:fontSize]};
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    return CGRectGetHeight([string boundingRectWithSize:CGSizeMake(320 - 12*2, CGFLOAT_MAX) options:0 context:nil]) + 20;
}

+ (PPTableViewTitleView *)headerWithText:(NSString *)text fontSize:(CGFloat)fontSize {
    return [[PPTableViewTitleView alloc] initWithText:text fontSize:fontSize];
}

+ (PPTableViewTitleView *)headerWithText:(NSString *)text {
    return [[PPTableViewTitleView alloc] initWithText:text];
}

@end
