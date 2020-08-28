#import <UIKit/UIKit.h>
#import "HSTableViewController.h"
#import "HSBeaconContext.h"

@interface HSBeaconPreviousMessagesController : HSTableViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeButton;

@property (strong, nonatomic) HSBeaconContext *beaconContext;

+ (instancetype)instantiateViewController NS_SWIFT_NAME(instantiate());

- (void)loadPage:(int)page;

@end
