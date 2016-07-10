//
//  PPAboutViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/31/13.
//
//

@import StoreKit;

#import "PPTableViewController.h"
#import "PPLoadingView.h"

@interface PPAboutViewController : PPTableViewController <SKStoreProductViewControllerDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *heights;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) PPLoadingView *loadingIndicator;
@property (nonatomic, strong) UIAlertController *twitterAccountActionSheet;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic) CGPoint selectedPoint;
@property (nonatomic) NSDictionary *selectedItem;
@property (nonatomic, strong) UIAlertController *actionSheet;

- (void)gestureDetected:(UILongPressGestureRecognizer *)recognizer;

@end
