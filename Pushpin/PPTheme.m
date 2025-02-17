// SPDX-License-Identifier: GPL-3.0-or-later
//
// Pushpin for Pinboard
// Copyright (C) 2025 Lionheart Software LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
    return [UIFont boldSystemFontOfSize:16];
}

+ (UIFont *)textLabelFontAlternate {
    return [UIFont systemFontOfSize:17];
}

+ (UIFont *)textLabelFont {
    return [UIFont systemFontOfSize:16];
}

+ (UIFont *)detailLabelFont {
    return [UIFont systemFontOfSize:15];
}

+ (UIFont *)detailLabelFontAlternate1 {
    return [UIFont systemFontOfSize:13];
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

+ (UIColor *)bookmarkBackgroundColor {
    return [UIColor whiteColor];
}

+ (UIColor *)detailLabelFontColor {
    return [UIColor darkGrayColor];
}

+ (NSInteger)maxNumberOfLinesForCompressedDescriptions {
    return 1;
}

+ (void)customizeNavBarAppearance {
    UIColor *barTintColor = [UIColor colorWithRed:0 green:0.5863 blue:1 alpha:1];
    NSDictionary *titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    NSDictionary *normalAttributes = @{NSFontAttributeName: [PPTheme textLabelFontAlternate],
                                       NSForegroundColorAttributeName: [UIColor whiteColor] };

    // https://developer.apple.com/documentation/technotes/tn3106-customizing-uinavigationbar-appearance
    UINavigationBarAppearance *customAppearance = [[UINavigationBarAppearance alloc] init];
    [customAppearance configureWithOpaqueBackground];
    customAppearance.backgroundColor = barTintColor;
    customAppearance.titleTextAttributes = titleTextAttributes;

    [[UINavigationBar appearance] setBarTintColor:barTintColor];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:titleTextAttributes];

    UIBarButtonItemAppearance *customBarButtonItemAppearance = [[UIBarButtonItemAppearance alloc] initWithStyle:UIBarButtonItemStylePlain];
    customBarButtonItemAppearance.normal.titleTextAttributes = normalAttributes;

    [[UIBarButtonItem appearance] setTitleTextAttributes:normalAttributes
                                                forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];

    // UIToolbar items
    UIColor *barButtonItemColor = [UIColor colorWithRed:40/255.0f green:141/255.0f blue:219/255.0f alpha:1.0f];
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIToolbar class]]] setTintColor:barButtonItemColor];

    [[UINavigationBar appearance] setScrollEdgeAppearance:customAppearance];
    [[UINavigationBar appearance] setCompactAppearance:customAppearance];
    [[UINavigationBar appearance] setStandardAppearance:customAppearance];

    if (@available(iOS 15.0, *)) {
        [[UINavigationBar appearance] setCompactScrollEdgeAppearance:customAppearance];
    }
}

+ (void)customizeUIElements {
    [[UISwitch appearance] setOnTintColor:HEX(0x0096FFFF)];
    [PPTheme customizeNavBarAppearance];

    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [UIColor whiteColor]
    };
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setDefaultTextAttributes:attributes];

    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Search" attributes:attributes];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setAttributedPlaceholder:string];
}

@end
