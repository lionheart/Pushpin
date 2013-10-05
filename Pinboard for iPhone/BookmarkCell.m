//
//  BookmarkCell.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookmarkCell.h"
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>
#import "UIView+LHSAdditions.h"

@implementation BookmarkCell

@synthesize isEditting = _isEditting;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.textView = [[TTTAttributedLabel alloc] initWithFrame:(CGRect){{0, 0}, frame.size}];
        self.textView.font = [UIFont systemFontOfSize:kLargeFontSize];
        self.textView.translatesAutoresizingMaskIntoConstraints = NO;
        self.textView.numberOfLines = 0;
        self.textView.textColor = [UIColor darkGrayColor];
        self.textView.lineBreakMode = kCTLineBreakByWordWrapping;
        self.textView.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        self.textView.linkAttributes = [NSDictionary dictionaryWithObject:@(NO) forKey:(NSString *)kCTUnderlineStyleAttributeName];

        NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
        [mutableActiveLinkAttributes setValue:@(NO) forKey:(NSString *)kCTUnderlineStyleAttributeName];
        [mutableActiveLinkAttributes setValue:(id)[HEX(0xeeddddff) CGColor] forKey:(NSString *)kTTTBackgroundFillColorAttributeName];
        [mutableActiveLinkAttributes setValue:(id)@(5.0f) forKey:(NSString *)kTTTBackgroundCornerRadiusAttributeName];
        self.textView.activeLinkAttributes = mutableActiveLinkAttributes;
        self.textView.backgroundColor = [UIColor clearColor];

        [self.contentView addSubview:self.textView];
        [self.contentView lhs_addConstraints:@"H:|-10-[text]-10-|" views:@{@"text": self.textView}];
        [self.contentView lhs_addConstraints:@"V:|-5-[text]-5-|" views:@{@"text": self.textView}];
    }
    return self;
}

@end
