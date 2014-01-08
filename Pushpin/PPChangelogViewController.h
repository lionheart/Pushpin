//
//  PPChangelogViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/5/13.
//
//

#import "PPTableViewController.h"

@interface PPChangelogViewController : PPTableViewController

@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableDictionary *heights;

- (void)calculateHeightsForWidth:(CGFloat)w;

@end
