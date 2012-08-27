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
        [self.contentView addSubview:self.textView];
    }
    return self;
}

+ (CGFloat)heightForCellWithText:(NSString *)text {
    CGFloat height = 10.0f;
    height += ceilf([text sizeWithFont:[UIFont systemFontOfSize:17] constrainedToSize:CGSizeMake(270.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    return height;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textView.frame = CGRectOffset(CGRectInset(self.bounds, 10.0f, 5.0f), 0.0f, 0.0f);
}

@end
