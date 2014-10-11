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

@interface PPAboutViewController : PPTableViewController <UIActionSheetDelegate, SKStoreProductViewControllerDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *heights;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) PPLoadingView *loadingIndicator;
@property (nonatomic, strong) UIActionSheet *twitterAccountActionSheet;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic) CGPoint selectedPoint;
@property (nonatomic) NSDictionary *selectedItem;
@property (nonatomic, strong) UIAlertController *actionSheet;

- (void)gestureDetected:(UILongPressGestureRecognizer *)recognizer;

@end
