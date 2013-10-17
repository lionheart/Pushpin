//
//  PPDefaultFeedViewController.h
//  Pushpin
//
//  Created by Andy Muldowney on 10/17/13.
//
//

#import "PPTableViewController.h"

@interface PPDefaultFeedViewController : PPTableViewController

@property (nonatomic, retain) NSMutableArray *savedFeeds;
@property (nonatomic, retain) NSIndexPath *defaultIndexPath;

@end
