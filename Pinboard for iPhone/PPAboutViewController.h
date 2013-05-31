//
//  PPAboutViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/31/13.
//
//

#import "PPTableViewController.h"

@interface PPAboutViewController : PPTableViewController

@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSMutableDictionary *heights;
@property (nonatomic, strong) NSMutableArray *expandedIndexPaths;

@end
