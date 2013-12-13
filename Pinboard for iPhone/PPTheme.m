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

+ (NSString *)heavyFontName {
    return @"HelveticaNeue-Bold";
}

+ (NSString *)mediumFontName {
    return @"HelveticaNeue-Medium";
}

+ (NSString *)bookFontName {
    return @"HelveticaNeue-Bold";
}

+ (NSString *)blackFontName {
    return @"HelveticaNeue-Bold";
}

@end
