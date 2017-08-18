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

@interface PPAboutViewController : PPTableViewController <UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *heights;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) PPLoadingView *loadingIndicator;
@property (nonatomic) NSDictionary *selectedItem;
@property (nonatomic, strong) UIAlertController *actionSheet;

@end
