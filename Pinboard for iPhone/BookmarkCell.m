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

- (void)drawRect:(CGRect)rect
{
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = 5.0f;
    /*
    self.clipsToBounds = NO;
    self.layer.shadowOpacity = 0.2f;
    self.layer.shadowRadius = 0.2f;
    self.layer.shadowOffset = CGSizeMake(1, 1);
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    */
}

/*
- (void)layoutSubviews {
    [super layoutSubviews];
    self.textView.frame = CGRectOffset(CGRectInset(self.bounds, 10.0f, 10.0f), 0.0f, 0.0f);
}
*/

@end
