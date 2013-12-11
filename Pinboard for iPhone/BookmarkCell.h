//
//  BookmarkCell.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"
#import "PPBadgeWrapperView.h"

@interface BookmarkCell : UITableViewCell

@property (nonatomic, retain) TTTAttributedLabel *textView;
@property (nonatomic, retain) PPBadgeWrapperView *badgeView;
@property (nonatomic) BOOL isEditting;
@property (nonatomic, retain) NSIndexPath *currentPath;

@end
