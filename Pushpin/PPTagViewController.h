//
//  TagViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/1/12.
//
//

@import UIKit;
@import FMDB;

#import "PPTableViewController.h"

@interface PPTagViewController : PPTableViewController <UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>

@property (nonatomic, retain) NSArray *alphabet;
@property (nonatomic, retain) NSArray *filteredTags;
@property (nonatomic, retain) NSMutableArray *tagList;
@property (nonatomic, strong) UISwipeGestureRecognizer *rightSwipeGestureRecognizer;

- (void)popViewController;

@end
