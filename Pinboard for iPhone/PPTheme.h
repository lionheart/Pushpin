//
//  PPTheme.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/13/13.
//
//

#import <Foundation/Foundation.h>

@interface PPTheme : NSObject

+ (instancetype)defaultTheme;

+ (UIFont *)extraLargeFont;
+ (UIFont *)titleFont;
+ (UIFont *)descriptionFont;
+ (UIFont *)urlFont;
+ (UIFont *)tagFont;
+ (UIFont *)cellTextLabelFont;
+ (NSString *)fontName;
+ (NSString *)boldFontName;

+ (CGFloat)fontSize;
+ (CGFloat)badgeFontSize;
+ (CGFloat)tagFontSize;

#pragma mark Static Sizes

+ (CGFloat)staticBadgeFontSize;

+ (UIColor *)bookmarkBackgroundColor;
+ (UIColor *)badgeBackgroundColor;
+ (UIColor *)badgeTextColor;

+ (NSInteger)maxNumberOfLinesForCompressedDescriptions;

@end
