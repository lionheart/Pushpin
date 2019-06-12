#import "HSBeaconCoordinator.h"
#import "HSBeaconContext.h"
#import "HSBeaconMessageEntryContainerController.h"

NS_ASSUME_NONNULL_BEGIN

@class HSContactCoordinator;

#pragma mark - HSContactCoordinatorDelegate

@protocol HSContactCoordinatorDelegate

- (void)contactCoordinatorRequestsDismissal:(HSContactCoordinator *)contactCoordinator;

@end

#pragma mark - HSContactCoordinator

@interface HSContactCoordinator : NSObject <HSBeaconCoordinator, HSBeaconMessageEntryContainerControllerDelegate>

@property (nonatomic, weak) id<HSContactCoordinatorDelegate> delegate;
@property (nonatomic, readonly) UINavigationController *navigationController;
@property (readonly) HSBeaconContext *beaconContext;
@property (nonatomic) BOOL navigateWithAnimation;

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController beaconContext:(HSBeaconContext *)context;

- (void)showAsk;

- (void)resetForm;

@end

NS_ASSUME_NONNULL_END
