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
    return [UIFont systemFontOfSize:[PPTheme fontSize] + 1 weight:UIFontWeightBold];
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

+ (UIFont *)textLabelFontAlternate {
    return [UIFont fontWithName:[PPTheme fontName] size:17];
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
    return 15;
}

+ (NSString *)browseFontName {
    PPSettings *settings = [PPSettings sharedSettings];
    return settings.fontName;
}

+ (NSString *)fontName {
    return [UIFont systemFontOfSize:10].fontName;
}

+ (NSString *)boldFontName {
    return [UIFont boldSystemFontOfSize:10].fontName;
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

+ (void)customizeUIElements {
    NSDictionary *normalAttributes = @{NSFontAttributeName: [PPTheme textLabelFontAlternate],
                                       NSForegroundColorAttributeName: [UIColor whiteColor] };
    [[UIBarButtonItem appearance] setTitleTextAttributes:normalAttributes
                                                forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    
    // UIToolbar items
    UIColor *barButtonItemColor = [UIColor colorWithRed:40/255.0f green:141/255.0f blue:219/255.0f alpha:1.0f];
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIToolbar class]]] setTintColor:barButtonItemColor];
    
    [[UISwitch appearance] setOnTintColor:HEX(0x0096FFFF)];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0 green:0.5863 blue:1 alpha:1]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
}

@end
