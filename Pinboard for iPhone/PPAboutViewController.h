//
//  PPAboutViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/31/13.
//
//

#import "PPTableViewController.h"
#import "PPLoadingView.h"
#import "RDActionSheet.h"

@interface PPAboutViewController : PPTableViewController <RDActionSheetDelegate>

@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSMutableDictionary *heights;
@property (nonatomic, strong) NSMutableArray *expandedIndexPaths;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) PPLoadingView *loadingIndicator;
@property (nonatomic, strong) RDActionSheet *twitterAccountActionSheet;

- (void)followScreenName:(NSString *)screenName;
- (void)copyURL:(id)sender;
- (void)followUserOnTwitter:(id)sender;

@end
