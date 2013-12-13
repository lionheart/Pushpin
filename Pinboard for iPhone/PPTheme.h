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

+ (NSString *)heavyFontName;
+ (NSString *)mediumFontName;
+ (NSString *)bookFontName;
+ (NSString *)blackFontName;

@end
