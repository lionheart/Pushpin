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
        self.textView = [[UITextView alloc] init];
        self.textView.backgroundColor = [UIColor blackColor];
        [self.contentView addSubview:self.textView];
    }
    return self;
}

- (void)resizeTextView {
    CGRect frame = self.textView.frame;
    frame.size.height = self.textView.contentSize.height;
    self.textView.frame = frame;
}

@end
