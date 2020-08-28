#import <UIKit/UIKit.h>
#import "HSNavigationController.h"
@class HSBeaconContext;
@class HSBeaconNavigationController;

@protocol HSBeaconNavigationControllerDelegate

- (void)beaconNavigationControllerDismissed:(HSBeaconNavigationController *)navigationController;

@end

@interface HSBeaconNavigationController : HSNavigationController

@property (nonatomic, weak) id<HSBeaconNavigationControllerDelegate> beaconNavigationDelegate;
@property (nonatomic, weak) HSBeaconContext *beaconContext;
@property (copy) void (^postLoadCallback)(void) ;

- (void)updateStatusBar;

- (void)displayControllerInCard:(UIViewController *)details;

- (void)dismissCards:(void (^)(void))completion;

@end
