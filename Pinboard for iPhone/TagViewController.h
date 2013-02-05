//
//  TagViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/1/12.
//
//

#import <UIKit/UIKit.h>
#import "FMDatabase.h"

@interface TagViewController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, retain) NSArray *alphabet;
@property (nonatomic, retain) NSMutableDictionary *titleToTags;
@property (nonatomic, retain) NSArray *sortedTitles;
@property (nonatomic, retain) NSArray *filteredTags;
@property (nonatomic, retain) NSMutableArray *tagList;
@property (nonatomic, retain) UISearchDisplayController *searchDisplayController;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UINavigationController *navigationController;

@end
