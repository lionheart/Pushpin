//
//  BookmarkList.h
//  ASPinboard
//
//  Created by Daniel Loewenherz on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Bookmark.h"

@interface BookmarkList : NSObject

@property (nonatomic, retain) NSString *endpoint;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *datetime;
@property (nonatomic, retain) NSMutableArray *bookmarks;

- (void)add:(Bookmark *)bookmark;

@end
