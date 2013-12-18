//
//  PPTheme.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/13/13.
//
//

#import "PPTheme.h"

@implementation PPTheme

+ (instancetype)defaultTheme {
    static PPTheme *theme;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        theme = [[PPTheme alloc] init];
    });
    return theme;
}

+ (UIFont *)titleFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
}

+ (UIFont *)descriptionFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

+ (UIFont *)urlFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
}

+ (CGFloat)fontSize {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize;
}

+ (NSString *)fontName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"io.aurora.pinboard.FontName"];
}

+ (NSString *)boldFontName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"io.aurora.pinboard.BoldFontName"];
}

@end
