//
//  PPTheme.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/13/13.
//
//

@import Foundation;

@interface PPTheme : NSObject

+ (instancetype)defaultTheme;

+ (void)customizeUIElements;

+ (UIFont *)extraLargeFont;
+ (UIFont *)titleFont;
+ (UIFont *)descriptionFont;
+ (UIFont *)urlFont;
+ (UIFont *)tagFont;
+ (UIFont *)boldTextLabelFont;
+ (UIFont *)textLabelFontAlternate;
+ (UIFont *)textLabelFont;
+ (UIFont *)detailLabelFont;
+ (UIFont *)detailLabelFontAlternate1;

+ (NSString *)browseFontName;

+ (CGFloat)fontSize;
+ (CGFloat)badgeFontSize;
+ (CGFloat)tagFontSize;

#pragma mark Static Sizes

+ (CGFloat)staticBadgeFontSize;

+ (UIColor *)detailLabelFontColor;
+ (UIColor *)bookmarkBackgroundColor;

+ (NSInteger)maxNumberOfLinesForCompressedDescriptions;

@end
