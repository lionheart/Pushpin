//
//  PPTheme.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/13/13.
//
//

#import "PPTheme.h"
#import "PPSettings.h"

@interface PPTheme ()

+ (NSString *)browseFontName;

@end

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
    return [UIFont fontWithName:[PPTheme browseFontName] size:[PPTheme fontSize] + 1];
}

+ (UIFont *)descriptionFont {
    return [UIFont fontWithName:[PPTheme browseFontName] size:[PPTheme fontSize] - 3];
}

+ (UIFont *)urlFont {
    return [UIFont fontWithName:[PPTheme browseFontName] size:[PPTheme fontSize] - 2];
}

+ (UIFont *)tagFont {
    return [UIFont fontWithName:[PPTheme browseFontName] size:[PPTheme tagFontSize]];
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
    PPSettings *settings = [PPSettings sharedSettings];
    CGFloat fontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize;
    switch (settings.fontAdjustment) {
        case PPFontAdjustmentSmallest:
            return fontSize - 3;
            
        case PPFontAdjustmentSmall:
            return fontSize - 1;
            
        case PPFontAdjustmentMedium:
            return fontSize;
            
        case PPFontAdjustmentBig:
            return fontSize + 1;
            
        case PPFontAdjustmentBiggest:
            return fontSize + 3;
    }
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

+ (NSString *)browseFontName {
    PPSettings *settings = [PPSettings sharedSettings];
    return settings.fontName;
}

+ (NSString *)fontName {
    return @"AvenirNext-Regular";
}

+ (NSString *)boldFontName {
    return @"AvenirNext-Medium";
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
