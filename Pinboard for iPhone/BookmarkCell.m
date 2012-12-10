//
//  BookmarkCell.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookmarkCell.h"

#import <CoreText/CoreText.h>

@implementation BookmarkCell

@synthesize textView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textView = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        self.textView.font = [UIFont systemFontOfSize:17];
        self.textView.numberOfLines = 0;
        self.textView.textColor = [UIColor darkGrayColor];
        self.textView.lineBreakMode = kCTLineBreakByWordWrapping;
        self.textView.textAlignment = UITextAlignmentLeft;
        self.textView.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        
        NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
        [mutableActiveLinkAttributes setValue:@(NO) forKey:(NSString *)kCTUnderlineStyleAttributeName];
        self.textView.activeLinkAttributes = mutableActiveLinkAttributes;
        self.textView.linkAttributes = mutableActiveLinkAttributes;
        [self.contentView addSubview:self.textView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textView.frame = CGRectOffset(CGRectInset(self.bounds, 10.0f, 5.0f), 0.0f, 0.0f);
}

@end
