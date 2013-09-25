//
//  PPAboutViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/31/13.
//
//

#import "PPTableViewController.h"
#import "PPLoadingView.h"
#import <StoreKit/StoreKit.h>

@interface PPAboutViewController : PPTableViewController <UIActionSheetDelegate, SKStoreProductViewControllerDelegate>

@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableDictionary *heights;
@property (nonatomic, strong) NSMutableArray *expandedIndexPaths;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) PPLoadingView *loadingIndicator;
@property (nonatomic, strong) UIActionSheet *twitterAccountActionSheet;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic) CGPoint selectedPoint;
@property (nonatomic) NSArray *selectedItem;
@property (nonatomic, strong) UIActionSheet *actionSheet;

- (void)followScreenName:(NSString *)screenName withAccountScreenName:(NSString *)accountScreenName;
- (void)followScreenName:(NSString *)screenName;
- (void)gestureDetected:(UILongPressGestureRecognizer *)recognizer;

@end
