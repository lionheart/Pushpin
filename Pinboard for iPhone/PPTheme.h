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
+ (NSString *)fontName;
+ (NSString *)boldFontName;
+ (CGFloat)fontSize;
+ (CGFloat)tagFontSize;

@end
