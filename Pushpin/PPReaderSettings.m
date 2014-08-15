//
//  PPReaderSettings.m
//  Pushpin
//
//  Created by Dan Loewenherz on 8/15/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPReaderSettings.h"

@interface PPReaderSettings ()

- (NSString *)customReaderCSSFilePath;
- (NSString *)hexStringFromColor:(UIColor *)color;

@end

@implementation PPReaderSettings

- (instancetype)init {
    self = [super init];
    if (self) {
        self.headerFontName = @"Helvetica-Neue";
        self.fontName = @"Helvetica-Neue";
        self.fontSize = 14;
        self.displayImages = YES;
        self.lineSpacing = 1.1;
        self.textAlignment = NSTextAlignmentLeft;
        self.margin = 95;
        self.backgroundColor = HEX(0xfbfbfbff);
        self.textColor = HEX(0x080000ff);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];

    if (self) {
        NSData *backgroundColorData = [aDecoder decodeObjectForKey:@"backgroundColor"];
        NSData *textColorData = [aDecoder decodeObjectForKey:@"textColor"];

        self.backgroundColor = [NSKeyedUnarchiver unarchiveObjectWithData:backgroundColorData];
        self.textColor = [NSKeyedUnarchiver unarchiveObjectWithData:textColorData];
        self.headerFontName = [aDecoder decodeObjectForKey:@"headerFontName"];
        self.fontName = [aDecoder decodeObjectForKey:@"fontName"];
        self.fontSize = [aDecoder decodeFloatForKey:@"fontSize"];
        self.lineSpacing = [aDecoder decodeFloatForKey:@"lineSpacing"];
        self.margin = [aDecoder decodeIntegerForKey:@"margin"];
        self.textAlignment = [aDecoder decodeIntegerForKey:@"textAlignment"];
        self.displayImages = [aDecoder decodeBoolForKey:@"displayImages"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    NSData *backgroundColorData = [NSKeyedArchiver archivedDataWithRootObject:self.backgroundColor];
    NSData *textColorData = [NSKeyedArchiver archivedDataWithRootObject:self.textColor];

    [aCoder encodeObject:backgroundColorData forKey:@"backgroundColor"];
    [aCoder encodeObject:textColorData forKey:@"textColor"];
    [aCoder encodeObject:self.headerFontName forKey:@"headerFontName"];
    [aCoder encodeObject:self.fontName forKey:@"fontName"];
    [aCoder encodeFloat:self.fontSize forKey:@"fontSize"];
    [aCoder encodeFloat:self.lineSpacing forKey:@"lineSpacing"];
    [aCoder encodeInteger:self.margin forKey:@"margin"];
    [aCoder encodeInteger:self.textAlignment forKey:@"textAlignment"];
    [aCoder encodeBool:self.displayImages forKey:@"displayImages"];
}

- (NSString *)imageCSS {
    if (self.displayImages) {
        return @"display:block;max-width:100% !important;";
    }
    else {
        return @"display:none;";
    }
}

- (NSString *)customReaderCSSFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[paths lastObject] stringByAppendingPathComponent:@"reader.css"];
}

- (void)updateCustomReaderCSSFile {
    NSString *baseReaderCSSFilePath =  [[NSBundle mainBundle] pathForResource:@"reader-base"
                                                                       ofType:@"css"];
    NSString *baseReaderCSS = [NSString stringWithContentsOfFile:baseReaderCSSFilePath
                                                        encoding:NSUTF8StringEncoding
                                                           error:nil];

    NSString *customReaderCSS = [NSString stringWithFormat:baseReaderCSS, [self hexStringFromColor:self.backgroundColor], [self hexStringFromColor:self.textColor], self.fontName, self.lineSpacing, self.fontSize, self.headerFontName, self.headerFontName, self.margin, self.imageCSS];
    [customReaderCSS writeToFile:[self customReaderCSSFilePath]
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:nil];
}

- (NSString *)readerCSSFilePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *customReaderCSSFilePath = [self customReaderCSSFilePath];
    if (![fileManager fileExistsAtPath:customReaderCSSFilePath]) {
        [self updateCustomReaderCSSFile];
    }
    return customReaderCSSFilePath;
}

- (NSString *)hexStringFromColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    NSInteger hexValue = 0xFF0000 * components[0] + 0x00FF00 * components[1] + 0x0000FF * components[2];
    return [NSString stringWithFormat:@"%lX", (long)hexValue];
}

@end
