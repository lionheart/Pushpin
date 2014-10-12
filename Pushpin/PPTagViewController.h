//
//  TagViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/1/12.
//
//

@import UIKit;
#import "FMDatabase.h"
#import "PPTableViewController.h"

@interface PPTagViewController : PPTableViewController <UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, retain) NSArray *alphabet;
@property (nonatomic, retain) NSArray *filteredTags;
@property (nonatomic, retain) NSMutableArray *tagList;
@property (nonatomic, strong) UISwipeGestureRecognizer *rightSwipeGestureRecognizer;

@property (nonatomic, retain) UISearchDisplayController *searchDisplayController;
@property (nonatomic, retain) UISearchBar *searchBar;

- (void)popViewController;

@end
