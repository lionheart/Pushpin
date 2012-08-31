//
//  BookmarkList.m
//  ASPinboard
//
//  Created by Daniel Loewenherz on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookmarkList.h"

@implementation BookmarkList

@synthesize username;
@synthesize datetime;
@synthesize bookmarks;

- (void)add:(Bookmark *)bookmark {
    [self.bookmarks addObject:bookmark];
}

@end
