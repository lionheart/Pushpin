//
//  BookmarkCell.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

@interface BookmarkCell : UICollectionViewCell

@property (nonatomic, retain) IBOutlet TTTAttributedLabel *textView;
@property (nonatomic, retain) IBOutlet UIButton *deleteButton;
@property (nonatomic) BOOL isEditting;
@property (nonatomic, retain) NSIndexPath *currentPath;

@end
