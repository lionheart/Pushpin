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
#import <StoreKit/StoreKit.h>

@interface PPAboutViewController : PPTableViewController <RDActionSheetDelegate, SKStoreProductViewControllerDelegate>

@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableDictionary *heights;
@property (nonatomic, strong) NSMutableArray *expandedIndexPaths;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) PPLoadingView *loadingIndicator;
@property (nonatomic, strong) RDActionSheet *twitterAccountActionSheet;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

- (void)followScreenName:(NSString *)screenName;
- (void)followUserOnTwitter:(id)sender;
- (void)gestureDetected:(UILongPressGestureRecognizer *)recognizer;

@end
