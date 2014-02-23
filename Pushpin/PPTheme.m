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
    return [UIFont fontWithName:[PPTheme boldFontName] size:[PPTheme fontSize] + 1];
}

+ (UIFont *)titleFont {
    return [UIFont fontWithName:[PPTheme fontName] size:[PPTheme fontSize] + 1];
}

+ (UIFont *)descriptionFont {
    return [UIFont fontWithName:[PPTheme fontName] size:[PPTheme fontSize] - 3];
}

+ (UIFont *)urlFont {
    return [UIFont fontWithName:[PPTheme fontName] size:[PPTheme fontSize] - 2];
}

+ (UIFont *)tagFont {
    return [UIFont fontWithName:[PPTheme fontName] size:[PPTheme tagFontSize]];
}

+ (UIFont *)boldTextLabelFont {
    return [UIFont fontWithName:[PPTheme boldFontName] size:16];
}

+ (UIFont *)textLabelFont {
    return [UIFont fontWithName:[PPTheme fontName] size:16];
}

+ (UIFont *)detailLabelFont {
    return [UIFont fontWithName:[PPTheme fontName] size:15];
}

+ (UIFont *)detailLabelFontAlternate1 {
    return [UIFont fontWithName:[PPTheme fontName] size:13];
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

+ (CGFloat)staticBadgeFontSize {
    return 13;
}

+ (NSString *)fontName {
    return @"AvenirNext-Regular";
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"io.aurora.pinboard.FontName"];
}

+ (NSString *)boldFontName {
    return @"AvenirNext-Medium";
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"io.aurora.pinboard.BoldFontName"];
}

+ (UIColor *)bookmarkBackgroundColor {
    return [UIColor whiteColor];
}

+ (UIColor *)detailLabelFontColor {
    return [UIColor darkGrayColor];
}

+ (NSInteger)maxNumberOfLinesForCompressedDescriptions {
    return 1;
}

@end
