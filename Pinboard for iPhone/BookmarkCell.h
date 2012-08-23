//
//  BookmarkCell.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BookmarkCell : UITableViewCell

@property (nonatomic, retain) UITextView *textView;

- (void)resizeTextView;

@end
