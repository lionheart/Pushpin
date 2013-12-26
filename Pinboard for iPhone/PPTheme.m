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

+ (UIFont *)extraLargeFont {
    return [UIFont fontWithName:[PPTheme fontName] size:[PPTheme fontSize] + 1];
}

+ (UIFont *)titleFont {
    return [UIFont fontWithName:[PPTheme fontName] size:[PPTheme fontSize] + 1];
}

+ (UIFont *)descriptionFont {
    return [UIFont fontWithName:[PPTheme fontName] size:[PPTheme fontSize] - 3];
}

+ (UIFont *)urlFont {
    return [UIFont fontWithName:[PPTheme fontName] size:[PPTheme fontSize] - 1];
}

+ (UIFont *)tagFont {
    return [UIFont fontWithName:[PPTheme fontName] size:[PPTheme tagFontSize]];
}

+ (CGFloat)fontSize {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize;
}

+ (CGFloat)badgeFontSize {
    return [self tagFontSize];
}

+ (CGFloat)tagFontSize {
    return [PPTheme fontSize] - 4;
}

+ (NSString *)fontName {
    return @"Avenir";
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"io.aurora.pinboard.FontName"];
}

+ (NSString *)boldFontName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"io.aurora.pinboard.BoldFontName"];
}

@end
