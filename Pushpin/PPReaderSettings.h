//
//  PPReaderSettings.h
//  Pushpin
//
//  Created by Dan Loewenherz on 8/15/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

@import Foundation;

@interface PPReaderSettings : NSObject <NSCoding>

@property (nonatomic, strong) NSString *headerFontName;
@property (nonatomic, strong) NSString *fontName;
@property (nonatomic) CGFloat fontSize;
@property (nonatomic) CGFloat lineSpacing;

// As a percentage
@property (nonatomic) NSInteger margin;
@property (nonatomic) NSTextAlignment textAlignment;
@property (nonatomic) BOOL displayImages;

@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *backgroundColor;

- (instancetype)init;
- (NSString *)imageCSS;
- (void)updateCustomReaderCSSFile;
- (NSString *)readerCSSFilePath;
- (NSString *)readerHTMLForArticle:(NSDictionary *)article;
- (UIFont *)font;

@end
