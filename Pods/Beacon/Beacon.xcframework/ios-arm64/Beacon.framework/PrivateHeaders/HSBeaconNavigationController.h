#import <UIKit/UIKit.h>
#import <Beacon/HSNavigationController.h>
@class HSBeaconContext;
@class HSBeaconNavigationController;

@protocol HSBeaconNavigationControllerDelegate

- (void)beaconNavigationControllerDismissed:(HSBeaconNavigationController *)navigationController;

@end

typedef void(^FinishedBlock)(BOOL finished);

@interface HSBeaconNavigationController : HSNavigationController

@property (nonatomic, weak) id<HSBeaconNavigationControllerDelegate> beaconNavigationDelegate;
@property (nonatomic, weak) HSBeaconContext *beaconContext;
@property (copy) void (^postLoadCallback)(void) ;

- (void)updateStatusBar;

- (void)startLoading;
- (void)stopLoading;

- (void)displayControllerInCard:(UIViewController *)details animated:(BOOL)animated completion:(FinishedBlock)completion;

- (void)dismissCards:(void (^)(void))completion;

@end
