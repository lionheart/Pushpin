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

@synthesize webView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier delegate:(id<UIWebViewDelegate>)delegate {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        /*
        self.webView = [[UIWebView alloc] initWithFrame:self.contentView.frame];
        self.webView.delegate = delegate;
        [self.contentView addSubview:self.webView];
         */
    }
    return self;
}

@end
